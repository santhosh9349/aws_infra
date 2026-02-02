import argparse
import json
import logging
import os
import subprocess
import sys
import re
from typing import Dict, List, Optional

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def run_command(command: List[str]) -> Optional[str]:
    """Run a shell command and return stdout."""
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        logger.warning(f"Command failed: {' '.join(command)}\nError: {e.stderr}")
        return None

def get_resource_id_from_state(address: str, working_dir: str) -> Optional[str]:
    """Get resource ID from Terraform state."""
    logger.info(f"Looking up state for {address}...")
    
    cmd = ["terraform", "state", "show", "-no-color", address]
    
    try:
        # Debug: ensure we are where we think we are
        # logger.info(f"CWD: {os.getcwd()}")
        
        # WE TRUST os.chdir() from main. cwd=None uses current process directory.
        result = subprocess.run(cmd, capture_output=True, text=True, cwd=None)
        
        if result.returncode != 0:
            # Handle standard Terraform errors gracefully
            if "No state file was found" in result.stderr:
                logger.warning(f"State lookup failed: No state file found in {os.getcwd()}")
                # Optional: debug listdir
                # logger.info(f"Dir contents: {os.listdir('.')}")
                return None
            elif "Resource instance not found" in result.stderr:
                logger.info(f"Resource {address} not found in state (New resource).")
                return None
            else:
                logger.warning(f"Command failed: {' '.join(cmd)}\nError: {result.stderr.strip()}")
                return None
                
        output = result.stdout.strip()
    except Exception as e:
        logger.warning(f"Execution failed: {e}")
        return None
    
    if output:
        # Look for "id = ..." line
        m = re.search(r'\n\s+id\s+=\s+"([^"]+)"', output)
        if m:
            return m.group(1)
            
        # Fallback: sometimes attributes have different names, but 'id' is standard for resources
        # If simple regex fails, we can try to find the specific AWS resource ID pattern if known,
        # but 'id' attribute is the most reliable cross-resource key in state show output.
        
    return None

def lookup_cloudtrail_event(resource_id: str) -> Dict[str, str]:
    """Query CloudTrail for events related to the resource ID."""
    logger.info(f"Querying CloudTrail for resource ID: {resource_id}")
    
    # Calculate start time (7 days ago)
    # Python equivalent of date -d '7 days ago'
    # But for simplicity, we rely on aws cli default or simple string?
    # AWS CLI expects ISO timestamp or duration. using subprocess/date might be easier or just python datetime.
    import datetime
    start_time = (datetime.datetime.utcnow() - datetime.timedelta(days=7)).strftime('%Y-%m-%dT%H:%M:%SZ')
    
    cmd = [
        "aws", "cloudtrail", "lookup-events",
        "--lookup-attributes", f"AttributeKey=ResourceName,AttributeValue={resource_id}",
        "--start-time", start_time,
        "--max-results", "1",
        "--query", "Events[0].CloudTrailEvent",
        "--output", "text"
    ]
    
    output = run_command(cmd)
    
    if output and output != "None":
        try:
            event = json.loads(output)
            user_identity = event.get("userIdentity", {})
            
            # Extract username
            user_name = user_identity.get("arn") or user_identity.get("userName") or "Unknown"
            if user_identity.get("type") == "Root":
                user_name = "Root Account"
            elif user_identity.get("type") == "IAMUser":
                user_name = user_identity.get("userName")
            elif user_identity.get("type") == "AssumedRole":
                # arn usually has the role and session name
                user_name = user_identity.get("arn")

            event_time = event.get("eventTime")
            event_name = event.get("eventName")
            
            return {
                "user": user_name,
                "time": event_time,
                "action": event_name
            }
        except json.JSONDecodeError:
            logger.error("Failed to parse CloudTrail event JSON")
    
    return {"user": "Not Found", "time": "-", "action": "-"}

def main():
    parser = argparse.ArgumentParser(description="Lookup drift details")
    parser.add_argument("--plan-file", required=True, help="Path to plaintext plan output")
    parser.add_argument("--terraform-dir", required=True, help="Terraform working directory")
    args = parser.parse_args()

    # 1. Parse Plan File for Addresses and Refresh IDs
    addresses = []
    drift_data = {} # Map address -> action
    refresh_ids = {} # Map address -> ID
    
    try:
        with open(args.plan_file, "r") as f:
            content = f.read()
            
            # Find addresses and actions
            # Regex captures: Group 1=Address, Group 2=Action phrase
            matches = re.findall(r'^\s\s#\s([\w\.-]+)\s((?:will be|must be)\s[\w-]+)', content, re.MULTILINE)
            for addr, action in matches:
                drift_data[addr] = action
            
            # Extract IDs from "Refreshing state..." lines
            refresh_matches = re.findall(r'^([\w\.-]+): Refreshing state\.\.\. \[id=([^\]]+)\]', content, re.MULTILINE)
            for addr, rid in refresh_matches:
                refresh_ids[addr] = rid
                
    except Exception as e:
        logger.error(f"Error reading plan file: {e}")
        sys.exit(1)

    logger.info(f"Found {len(drift_data)} drifted resources to investigate.")
    
    results = []
    import os
    
    # Priority list for display
    PRIORITY_TYPES = ["aws_instance", "aws_s3_bucket", "aws_rds_cluster", "aws_db_instance", "aws_security_group"]
    
    if os.path.exists(os.path.join(args.terraform_dir, ".terraform")):
        logger.info(f"Verified .terraform directory exists in {args.terraform_dir}")
    else:
        logger.warning(f".terraform directory NOT found in {args.terraform_dir} - remote state lookup will likely fail!")

    original_cwd = os.getcwd()
    
    try:
        os.chdir(args.terraform_dir)
        
        # For Terraform Cloud remote state, we need to ensure backend is initialized
        # in this process context. Run terraform init to establish connection.
        logger.info("Initializing Terraform backend for state access...")
        init_result = subprocess.run(
            ["terraform", "init", "-backend=true", "-input=false", "-no-color"],
            capture_output=True, text=True
        )
        if init_result.returncode != 0:
            logger.warning(f"Terraform init failed: {init_result.stderr}")
        else:
            logger.info("Terraform backend initialized successfully")
        
        # Verify state is accessible by listing resources
        list_result = subprocess.run(
            ["terraform", "state", "list", "-no-color"],
            capture_output=True, text=True
        )
        if list_result.returncode == 0:
            state_resources = list_result.stdout.strip().split('\n') if list_result.stdout.strip() else []
            logger.info(f"State contains {len(state_resources)} resources")
            # Build a set for quick lookup
            state_resource_set = set(state_resources)
        else:
            logger.warning(f"Could not list state: {list_result.stderr}")
            state_resource_set = set()
        
        for addr, action in drift_data.items():
            # Skip data sources
            if addr.startswith("data.") or ".data." in addr:
                continue
                
            # Filter noise: Skip IAM, Attachments unless critical?
            # User request: "just the deleted EC2 instance"
            # We strictly prioritize EC2 or other major resources.
            is_priority = any(pt in addr for pt in PRIORITY_TYPES)
            
            # Use ID from refresh logs if available (Reliable for drift)
            res_id = refresh_ids.get(addr)
            
            # Fallback to state lookup - only if resource exists in state
            if not res_id and addr in state_resource_set:
               # We are currently IN the directory, so working_dir="." is correct.
               res_id = get_resource_id_from_state(addr, ".")
            elif not res_id:
               logger.info(f"Resource {addr} not in state (Action: {action})")
            
            info = {
                "address": addr,
                "id": res_id or "Unknown",
                "user": "-",
                "time": "-",
                "action": action,
                "priority": is_priority
            }
            
            if res_id:
                ct_data = lookup_cloudtrail_event(res_id)
                info.update(ct_data)
        
            results.append(info)
            
    finally:
        os.chdir(original_cwd)
        
    # Sort: Priority first, then alphabetical
    results.sort(key=lambda x: (not x['priority'], x['address']))

    # Output Markdown Table
    print("\n### Drift Attribution Analysis")
    print("| Resource | ID | Actor | Action | Time |")
    print("|----------|----|-------|--------|------|")
    for r in results:
        # Only show priority items OR items where we found an actor
        show_row = r['priority'] or r['user'] != "-"
        
        if show_row:
            # Highlight priority
            display_addr = f"**{r['address']}**" if r['priority'] else f"`{r['address']}`"
            print(f"| {display_addr} | `{r['id']}` | **{r['user']}** | {r['action']} | {r['time']} |")
            
    if not results:
        print("No drift attribution available.")
    
    print("\n")

if __name__ == "__main__":
    main()
