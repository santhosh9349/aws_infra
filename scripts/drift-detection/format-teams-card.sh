#!/bin/bash
# format-teams-card.sh
# Generates Microsoft Teams Adaptive Card JSON for drift notifications
# Usage: ./format-teams-card.sh
# Expects environment variables: ENVIRONMENT, ISSUE_URL, RUN_URL
# Reads drift summary from /tmp/drift_resources.txt

set -e

# Default values
ENVIRONMENT="${ENVIRONMENT:-dev}"
ISSUE_URL="${ISSUE_URL:-https://github.com}"
RUN_URL="${RUN_URL:-https://github.com}"
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M UTC")

# Count drifted resources
DRIFT_COUNT=0
if [ -f /tmp/drift_resources.txt ]; then
    DRIFT_COUNT=$(wc -l < /tmp/drift_resources.txt)
fi

# Build resource list for card (max 5 items for readability)
RESOURCE_LIST=""
if [ -f /tmp/drift_resources.txt ]; then
    COUNT=0
    while IFS='|' read -r address action resource_type iam_user event_time; do
        if [ $COUNT -lt 5 ]; then
            case "$action" in
                *create*) EMOJI="🆕" ;;
                *update*) EMOJI="📝" ;;
                *delete*) EMOJI="🗑️" ;;
                *) EMOJI="🔄" ;;
            esac
            RESOURCE_LIST="${RESOURCE_LIST}• \`${address}\` - ${EMOJI} ${action}\\n"
        fi
        COUNT=$((COUNT + 1))
    done < /tmp/drift_resources.txt
    
    if [ $DRIFT_COUNT -gt 5 ]; then
        RESOURCE_LIST="${RESOURCE_LIST}• ... and $((DRIFT_COUNT - 5)) more resources"
    fi
fi

# Generate Adaptive Card JSON
cat << EOF
{
  "type": "message",
  "attachments": [
    {
      "contentType": "application/vnd.microsoft.card.adaptive",
      "contentUrl": null,
      "content": {
        "\$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "type": "AdaptiveCard",
        "version": "1.4",
        "body": [
          {
            "type": "TextBlock",
            "text": "🔴 Terraform Drift Detected",
            "weight": "bolder",
            "size": "large",
            "color": "attention"
          },
          {
            "type": "FactSet",
            "facts": [
              {
                "title": "Environment:",
                "value": "${ENVIRONMENT}"
              },
              {
                "title": "Resources Changed:",
                "value": "${DRIFT_COUNT}"
              },
              {
                "title": "Detected At:",
                "value": "${TIMESTAMP}"
              }
            ]
          },
          {
            "type": "TextBlock",
            "text": "**Changed Resources:**",
            "weight": "bolder"
          },
          {
            "type": "TextBlock",
            "text": "${RESOURCE_LIST}",
            "wrap": true
          }
        ],
        "actions": [
          {
            "type": "Action.OpenUrl",
            "title": "📋 View GitHub Issue",
            "url": "${ISSUE_URL}"
          },
          {
            "type": "Action.OpenUrl",
            "title": "🔄 View Workflow Run",
            "url": "${RUN_URL}"
          }
        ]
      }
    }
  ]
}
EOF
