#!/bin/bash
# parse-terraform-plan.sh
# Extracts changed resources from Terraform plan JSON output
# Usage: ./parse-terraform-plan.sh plan.json

set -e

PLAN_FILE="${1:-plan.json}"

if [ ! -f "$PLAN_FILE" ]; then
    echo "Error: Plan file not found: $PLAN_FILE" >&2
    exit 1
fi

# Extract resources with changes (not no-op)
# Output format: address|action|resource_type
jq -r '
  .resource_changes[] | 
  select(.change.actions != ["no-op"]) | 
  "\(.address)|\(.change.actions | join(","))|\(.type)"
' "$PLAN_FILE" > /tmp/drift_resources_raw.txt

# Count total changes
TOTAL=$(wc -l < /tmp/drift_resources_raw.txt)
echo "Found $TOTAL resource(s) with drift"

# Export for use by other scripts
export DRIFT_COUNT="$TOTAL"
echo "drift_count=$TOTAL" >> $GITHUB_OUTPUT 2>/dev/null || true

# Create output file for CloudTrail lookup
# Will be enhanced with IAM user and timestamp by query-cloudtrail.sh
cp /tmp/drift_resources_raw.txt /tmp/drift_resources.txt

# Also extract resource IDs where available for CloudTrail lookup
jq -r '
  .resource_changes[] | 
  select(.change.actions != ["no-op"]) |
  select(.change.before != null) |
  "\(.address)|\(.change.before | if type == "object" then (.id // .arn // .name // "unknown") else "unknown" end)"
' "$PLAN_FILE" > /tmp/resource_ids.txt 2>/dev/null || true

echo "Resource parsing complete"
cat /tmp/drift_resources_raw.txt
