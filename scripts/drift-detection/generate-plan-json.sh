#!/bin/bash
# generate-plan-json.sh
# Generates a JSON representation of Terraform plan from text output and state
# This is needed because Terraform Cloud doesn't support the -out flag
# Usage: ./generate-plan-json.sh <plan_text_file> <output_json_file>

set -e

PLAN_TEXT="${1:-/tmp/plan_output.txt}"
OUTPUT_JSON="${2:-/tmp/plan.json}"
TERRAFORM_DIR="${3:-.}"

if [ ! -f "$PLAN_TEXT" ]; then
    echo "Error: Plan text file not found: $PLAN_TEXT" >&2
    exit 1
fi

echo "Generating JSON plan representation from text output..."
echo "Input: $PLAN_TEXT"
echo "Output: $OUTPUT_JSON"

# Pull current state from Terraform Cloud
echo "Pulling Terraform state..."
cd "$TERRAFORM_DIR"
terraform state pull > /tmp/terraform_state.json 2>/dev/null || echo '{"resources":[]}' > /tmp/terraform_state.json

# Helper function to check if a string is an AWS ARN
is_arn() {
    local str="$1"
    [[ "$str" =~ ^arn:(aws|aws-cn|aws-us-gov):[a-z0-9-]+:[a-z0-9-]*:(([0-9]{12})|aws|):.+ ]]
}

# Extract resource addresses and actions from plan text
echo "Extracting resource changes from plan..."

# Start building the JSON structure
cat > "$OUTPUT_JSON" << 'EOF_JSON_START'
{
  "format_version": "1.0",
  "terraform_version": "1.5.7",
  "resource_changes": [
EOF_JSON_START

FIRST_RESOURCE=true

# Parse each resource change from the plan text
while IFS= read -r line; do
    # Match lines like: # module.vpc["dev"].aws_vpc.this will be created
    if [[ "$line" =~ ^[[:space:]]*#[[:space:]]+([^[:space:]]+)[[:space:]]+(will be created|will be destroyed|will be updated|must be replaced) ]]; then
        address="${BASH_REMATCH[1]}"
        action_text="${BASH_REMATCH[2]}"
        
        # Determine action
        if [[ "$action_text" == "will be created" ]]; then
            action="create"
        elif [[ "$action_text" == "will be destroyed" ]]; then
            action="delete"
        elif [[ "$action_text" == "will be updated"* ]]; then
            action="update"
        elif [[ "$action_text" == "must be replaced" ]]; then
            action="replace"
        else
            action="update"
        fi
        
        # Extract resource type from address (e.g., aws_vpc, aws_subnet)
        resource_type=$(echo "$address" | grep -oE 'aws_[a-z0-9_]+' | tail -1)
        if [ -z "$resource_type" ]; then
            resource_type="unknown"
        fi
        
        # Get resource attributes from state
        state_data=$(jq -c --arg addr "$address" '
            .resources[] as $res |
            $res.instances[] as $inst |
            (
                (if $res.module then $res.module + "." else "" end) +
                $res.type + "." + $res.name +
                (if $inst.index_key then "[\"" + ($inst.index_key | tostring) + "\"]" else "" end)
            ) as $full_addr |
            select($full_addr == $addr) |
            $inst.attributes
        ' /tmp/terraform_state.json 2>/dev/null | head -1) || state_data="null"
        
        # For create actions (drift = manual deletion), we don't have 'before' state
        # For update/delete actions, 'before' state exists
        if [ "$action" = "create" ]; then
            before_state="null"
            # Try to extract what the resource should look like (planned state)
            # In practice, for creates we may not have full 'after' state, use what we can from plan
            after_state="$state_data"
        else
            before_state="$state_data"
            after_state="$state_data"
        fi
        
        # Add comma if not first resource
        if [ "$FIRST_RESOURCE" = true ]; then
            FIRST_RESOURCE=false
        else
            echo "," >> "$OUTPUT_JSON"
        fi
        
        # Write resource change JSON
        jq -n \
            --arg addr "$address" \
            --arg type "$resource_type" \
            --arg action "$action" \
            --argjson before "$before_state" \
            --argjson after "$after_state" \
            '{
                address: $addr,
                type: $type,
                change: {
                    actions: [$action],
                    before: $before,
                    after: $after
                }
            }' >> "$OUTPUT_JSON"
    fi
done < "$PLAN_TEXT"

# Close JSON structure
cat >> "$OUTPUT_JSON" << 'EOF_JSON_END'
  ]
}
EOF_JSON_END

echo "JSON plan generated successfully: $OUTPUT_JSON"

# Validate JSON
if jq empty "$OUTPUT_JSON" 2>/dev/null; then
    resource_count=$(jq '.resource_changes | length' "$OUTPUT_JSON")
    echo "✅ Valid JSON with $resource_count resource changes"
else
    echo "❌ Invalid JSON generated" >&2
    exit 1
fi
