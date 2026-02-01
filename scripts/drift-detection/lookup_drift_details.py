import argparse
import json
import logging
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
    # usage: terraform state show -json address
    cmd = ["terraform", "state", "show", "-no-color", "-json", address]
    output = run_command(cmd) # Executing inside the terraform dir
    
    if output:
        try:
            data = json.loads(output)
            # Try common ID fields
            res_id = data.get("values", {}).get("id")
            if not res_id:
                res_id = data.get("values", {}).get("attributes", {}).get("id")
            return res_id
        except json.JSONDecodeError:
            logger.error(f"Failed to parse state JSON for {address}")
    
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

    # 1. Parse Plan File for Addresses
    addresses = []
    try:
        with open(args.plan_file, "r") as f:
            content = f.read()
            # Regex to find: # module.x.y will be created
            # Matches: # <address> will be created
            # Also: # <address> must be replaced
            # Also: # <address> will be updated in-place
            # We mostly care about "will be created" (deletion) or "replaced"
            
            # Pattern: ^  # ([\w\.-]+) will be (created|updated in-place|destroyed|read)
            matches = re.findall(r'^\s\s#\s([\w\.-]+)\s(?:will be|must be)', content, re.MULTILINE)
            addresses = list(set(matches)) # Unique
    except Exception as e:
        logger.error(f"Error reading plan file: {e}")
        sys.exit(1)

    logger.info(f"Found {len(addresses)} drifted resources to investigate.")
    
    results = []
    
    import os
    original_cwd = os.getcwd()
    
    try:
        os.chdir(args.terraform_dir)
        
        for addr in addresses:
            # Skip data sources
            if addr.startswith("data.") or ".data." in addr:
                continue
                
            res_id = get_resource_id_from_state(addr, args.terraform_dir)
            
            info = {
                "address": addr,
                "id": res_id or "Unknown",
                "user": "-",
                "time": "-",
                "action": "-"
            }
            
            if res_id:
                ct_data = lookup_cloudtrail_event(res_id)
                info.update(ct_data)
        
            results.append(info)
            
    finally:
        os.chdir(original_cwd)

    # Output Markdown Table
    print("\n### Drift Attribution Analysis")
    print("| Resource | ID | Actor | Action | Time |")
    print("|----------|----|-------|--------|------|")
    for r in results:
        print(f"| `{r['address']}` | `{r['id']}` | **{r['user']}** | {r['action']} | {r['time']} |")
    print("\n")

if __name__ == "__main__":
    main()
