#!/bin/bash
# generate-plan-json.sh
# Parses native JSON stream from terraform plan -json and creates a structured plan JSON
# Usage: ./generate-plan-json.sh <plan_jsonl_stream> <output_json_file>

set -e

PLAN_JSONL="${1:-/tmp/plan_stream.jsonl}"
OUTPUT_JSON="${2:-/tmp/plan.json}"

if [ ! -f "$PLAN_JSONL" ]; then
    echo "Error: Plan JSON stream file not found: $PLAN_JSONL" >&2
    exit 1
fi

echo "Parsing native JSON stream from terraform plan -json..."
echo "Input: $PLAN_JSONL"
echo "Output: $OUTPUT_JSON"

# Extract the planned_change messages from the JSON stream
# These contain the resource changes with before/after states
echo "Extracting resource changes from JSON stream..."

# Initialize the output JSON structure
cat > "$OUTPUT_JSON" << 'EOF'
{
  "format_version": "1.0",
  "terraform_version": "1.5.7",
  "resource_changes": []
}
EOF

# Process the JSONL stream and extract resource changes
# The terraform plan -json output is JSONL format (one JSON object per line)
# We need to find lines with type="planned_change" which contain resource change info
TEMP_CHANGES="/tmp/resource_changes.json"
echo "[]" > "$TEMP_CHANGES"

while IFS= read -r line; do
    # Check if this line is a planned_change or resource_drift event
    msg_type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
    
    if [ "$msg_type" = "planned_change" ] || [ "$msg_type" = "resource_drift" ]; then
        # Extract the change information
        change_data=$(echo "$line" | jq -c '.change // empty' 2>/dev/null)
        
        if [ -n "$change_data" ] && [ "$change_data" != "null" ]; then
            # Extract resource information
            address=$(echo "$change_data" | jq -r '.resource.addr // "unknown"')
            resource_type=$(echo "$change_data" | jq -r '.resource.resource_type // "unknown"')
            
            # Extract action - handle both single action and array of actions
            action=$(echo "$change_data" | jq -r '.action // empty')
            if [ -z "$action" ] || [ "$action" = "null" ]; then
                # Some formats use .actions array
                action=$(echo "$change_data" | jq -r '(.actions // []) | if length > 0 then .[0] else "update" end')
            fi
            
            # Extract before and after states, ensuring they're valid JSON (null if missing)
            before=$(echo "$change_data" | jq -c '.before // null')
            after=$(echo "$change_data" | jq -c '.after // null')
            
            # Ensure before and after are valid JSON, default to null if empty/invalid
            if [ -z "$before" ] || [ "$before" = "" ]; then
                before="null"
            fi
            if [ -z "$after" ] || [ "$after" = "" ]; then
                after="null"
            fi
            
            # Build resource change object with validated JSON
            change_obj=$(jq -n \
                --arg addr "$address" \
                --arg type "$resource_type" \
                --arg action "$action" \
                --argjson before "$before" \
                --argjson after "$after" \
                '{
                    address: $addr,
                    type: $type,
                    change: {
                        actions: [$action],
                        before: $before,
                        after: $after
                    }
                }')
            
            # Append to the changes array
            jq --argjson obj "$change_obj" '. += [$obj]' "$TEMP_CHANGES" > "${TEMP_CHANGES}.tmp"
            mv "${TEMP_CHANGES}.tmp" "$TEMP_CHANGES"
        fi
    fi
done < "$PLAN_JSONL"

# Insert the collected changes into the output JSON
jq --slurpfile changes "$TEMP_CHANGES" '.resource_changes = $changes[0]' "$OUTPUT_JSON" > "${OUTPUT_JSON}.tmp"
mv "${OUTPUT_JSON}.tmp" "$OUTPUT_JSON"

# Clean up temp file
rm -f "$TEMP_CHANGES"

echo "JSON plan generated successfully: $OUTPUT_JSON"

# Validate JSON
if jq empty "$OUTPUT_JSON" 2>/dev/null; then
    resource_count=$(jq '.resource_changes | length' "$OUTPUT_JSON")
    echo "✅ Valid JSON with $resource_count resource changes"
else
    echo "❌ Invalid JSON generated" >&2
    exit 1
fi
