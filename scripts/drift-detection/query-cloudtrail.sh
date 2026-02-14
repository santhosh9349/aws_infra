#!/bin/bash
# query-cloudtrail.sh
# Queries AWS CloudTrail to find IAM user attribution for drifted resources using ARNs
# Usage: ./query-cloudtrail.sh
# Expects /tmp/drift_resources_raw.txt and /tmp/resource_arns.txt from parse-terraform-plan.sh

set -e

INPUT_FILE="/tmp/drift_resources_raw.txt"
RESOURCE_ARNS_FILE="/tmp/resource_arns.txt"
OUTPUT_FILE="/tmp/drift_resources.txt"

# Start date: 7 days ago (CloudTrail practical limit for recent changes)
START_TIME=$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-7d +%Y-%m-%dT%H:%M:%SZ)

echo "Querying CloudTrail for change attribution using ARNs..."
echo "Start time: $START_TIME"

# Clear output file
> "$OUTPUT_FILE"

# Process each drifted resource
while IFS='|' read -r address action resource_type; do
    echo "Processing: $address"
    
    # Get resource ARN if available
    RESOURCE_ARN=""
    if [ -f "$RESOURCE_ARNS_FILE" ]; then
        RESOURCE_ARN=$(grep "^${address}|" "$RESOURCE_ARNS_FILE" 2>/dev/null | cut -d'|' -f2 || true)
    fi
    
    IAM_USER="*(unavailable)*"
    EVENT_TIME="-"
    
    if [ -n "$RESOURCE_ARN" ] && [ "$RESOURCE_ARN" != "unknown" ]; then
        echo "  Looking up CloudTrail events for resource ARN: $RESOURCE_ARN"
        
        # Query CloudTrail using ARN directly
        CLOUDTRAIL_RESULT=$(aws cloudtrail lookup-events \
            --lookup-attributes AttributeKey=ResourceName,AttributeValue="$RESOURCE_ARN" \
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
            echo "  No CloudTrail events found for this resource ARN"
        fi
        
        # Rate limiting: sleep 0.5s between queries
        sleep 0.5
    else
        echo "  No resource ARN available for CloudTrail lookup"
    fi
    
    # Write to output file
    echo "${address}|${action}|${resource_type}|${IAM_USER}|${EVENT_TIME}" >> "$OUTPUT_FILE"
    
done < "$INPUT_FILE"

echo "CloudTrail attribution complete"
echo "Results written to $OUTPUT_FILE"
cat "$OUTPUT_FILE"
