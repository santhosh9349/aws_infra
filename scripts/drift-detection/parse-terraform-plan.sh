#!/bin/bash
# parse-terraform-plan.sh
# Extracts changed resources from Terraform plan JSON output
# Usage: ./parse-terraform-plan.sh plan.json
#
# Output format: address|action|resource_type|identifier
# - address: Terraform resource address (e.g., module.vpc["dev"].aws_vpc.this)
# - action: Terraform action (create, update, delete, replace)
# - resource_type: AWS resource type (e.g., aws_vpc, aws_subnet)
# - identifier: ARN, ID, or Name extracted from the resource

set -e

PLAN_FILE="${1:-plan.json}"
OUTPUT_FILE="${2:-/tmp/drift_resources.txt}"

if [ ! -f "$PLAN_FILE" ]; then
    echo "Error: Plan file not found: $PLAN_FILE" >&2
    exit 1
fi

echo "Parsing Terraform plan JSON: $PLAN_FILE"

# Helper function to extract identifier from resource attributes
# Priority: arn > id > name > tags.Name
extract_identifier() {
    local before="$1"
    local after="$2"
    local action="$3"
    
    # For update/delete: use 'before' state (resource exists in state)
    # For create: use 'after' state (resource doesn't exist in state)
    # For replace: prefer 'before' (old resource being replaced)
    
    local source="$before"
    if [ "$action" = "create" ]; then
        source="$after"
    fi
    
    # Extract identifier with priority: arn > id > tags.Name > name
    echo "$source" | jq -r '
        if . == null or . == "" then
            "unknown"
        else
            .arn // .id // .tags.Name // .name // "unknown"
        end
    ' 2>/dev/null || echo "unknown"
}

# Parse resource changes and extract structured data
# Output: address|action|resource_type|identifier
jq -c '
  .resource_changes[] | 
  select(.change.actions != ["no-op"])
' "$PLAN_FILE" | while read -r change; do
    # Extract basic fields
    address=$(echo "$change" | jq -r '.address // "unknown"')
    resource_type=$(echo "$change" | jq -r '.type // "unknown"')
    actions=$(echo "$change" | jq -r '.change.actions | join(",")')
    
    # Normalize action (handle comma-separated like "delete,create" for replace)
    action="$actions"
    if [[ "$actions" == *"delete"* ]] && [[ "$actions" == *"create"* ]]; then
        action="replace"
    elif [[ "$actions" == *"create"* ]]; then
        action="create"
    elif [[ "$actions" == *"delete"* ]]; then
        action="delete"
    elif [[ "$actions" == *"update"* ]]; then
        action="update"
    fi
    
    # Extract before and after states
    before=$(echo "$change" | jq -c '.change.before // null')
    after=$(echo "$change" | jq -c '.change.after // null')
    
    # Extract identifier based on action
    identifier=$(extract_identifier "$before" "$after" "$action")
    
    # Output structured data
    echo "${address}|${action}|${resource_type}|${identifier}"
    
done > "$OUTPUT_FILE"

# Count total changes
TOTAL=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
echo "Found $TOTAL resource(s) with drift"

# Export for use by other scripts
export DRIFT_COUNT="$TOTAL"
echo "drift_count=$TOTAL" >> $GITHUB_OUTPUT 2>/dev/null || true

echo "Resource parsing complete"
echo "Output written to: $OUTPUT_FILE"
echo ""
echo "Parsed resources:"
cat "$OUTPUT_FILE"
