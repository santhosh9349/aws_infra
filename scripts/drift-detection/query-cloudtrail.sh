#!/bin/bash
# query-cloudtrail.sh
# Queries AWS CloudTrail to find IAM user attribution for drifted resources
# Usage: ./query-cloudtrail.sh
# Expects /tmp/drift_resources_raw.txt and /tmp/resource_ids.txt from parse-terraform-plan.sh

set -e

INPUT_FILE="/tmp/drift_resources_raw.txt"
RESOURCE_IDS_FILE="/tmp/resource_ids.txt"
OUTPUT_FILE="/tmp/drift_resources.txt"

# Start date: 7 days ago (CloudTrail practical limit for recent changes)
START_TIME=$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-7d +%Y-%m-%dT%H:%M:%SZ)

echo "Querying CloudTrail for change attribution..."
echo "Start time: $START_TIME"

# Clear output file
> "$OUTPUT_FILE"

# Process each drifted resource
while IFS='|' read -r address action resource_type; do
    echo "Processing: $address"
    
    # Get resource ID if available
    RESOURCE_ID=""
    if [ -f "$RESOURCE_IDS_FILE" ]; then
        RESOURCE_ID=$(grep "^${address}|" "$RESOURCE_IDS_FILE" 2>/dev/null | cut -d'|' -f2 || true)
    fi
    
    IAM_USER="*(unavailable)*"
    EVENT_TIME="-"
    
    if [ -n "$RESOURCE_ID" ] && [ "$RESOURCE_ID" != "unknown" ]; then
        echo "  Looking up CloudTrail events for resource: $RESOURCE_ID"
        
        # Query CloudTrail
        CLOUDTRAIL_RESULT=$(aws cloudtrail lookup-events \
            --lookup-attributes AttributeKey=ResourceName,AttributeValue="$RESOURCE_ID" \
            --start-time "$START_TIME" \
            --max-results 1 \
            --query 'Events[0].CloudTrailEvent' \
            --output text 2>/dev/null || echo "")
        
        if [ -n "$CLOUDTRAIL_RESULT" ] && [ "$CLOUDTRAIL_RESULT" != "None" ] && [ "$CLOUDTRAIL_RESULT" != "null" ]; then
            # Parse user identity from CloudTrail event JSON
            IAM_USER=$(echo "$CLOUDTRAIL_RESULT" | jq -r '.userIdentity.arn // .userIdentity.userName // "*(unavailable)*"' 2>/dev/null || echo "*(unavailable)*")
            EVENT_TIME=$(echo "$CLOUDTRAIL_RESULT" | jq -r '.eventTime // "-"' 2>/dev/null || echo "-")
            
            # Handle AWS service principals
            USER_TYPE=$(echo "$CLOUDTRAIL_RESULT" | jq -r '.userIdentity.type // "Unknown"' 2>/dev/null || echo "Unknown")
            if [ "$USER_TYPE" = "AWSService" ]; then
                IAM_USER="AWS Service: $(echo "$CLOUDTRAIL_RESULT" | jq -r '.userIdentity.invokedBy // "unknown"' 2>/dev/null)"
            fi
            
            echo "  Found: $IAM_USER at $EVENT_TIME"
        else
            echo "  No CloudTrail events found for this resource"
        fi
        
        # Rate limiting: sleep 0.5s between queries
        sleep 0.5
    else
        echo "  No resource ID available for CloudTrail lookup"
    fi
    
    # Write to output file
    echo "${address}|${action}|${resource_type}|${IAM_USER}|${EVENT_TIME}" >> "$OUTPUT_FILE"
    
done < "$INPUT_FILE"

echo "CloudTrail attribution complete"
echo "Results written to $OUTPUT_FILE"
cat "$OUTPUT_FILE"
