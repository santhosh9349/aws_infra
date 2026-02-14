# Drift Detection Refactoring - Summary

## Problem Statement
The drift detection workflow failed to:
1. **Attribute manual deletions**: Resources showing as "creates" (because deleted from AWS) couldn't be attributed to responsible actors
2. **Pass actor data to notifications**: CloudTrail attribution wasn't flowing to Python models and Telegram notifications

## Solution Overview
Completely refactored the drift detection system with:
- JSON-based plan parsing instead of text parsing
- Dual-strategy CloudTrail queries (ARN-based and EventName-based)
- Actor attribution fields in Python models
- Modular, testable scripts replacing ~350 lines of inline bash

## Implementation Details

### 1. New Script Architecture

```
Terraform Plan (text) 
    ↓
generate-plan-json.sh → plan.json
    ↓
parse-terraform-plan.sh → drift_resources.txt (address|action|type|identifier)
    ↓
query-cloudtrail.sh → drift_resources_attributed.txt (+actor_name|actor_arn|event_time)
    ↓
generate-drift-report.sh → drift_report.json
    ↓
Python models → Telegram notification
```

### 2. CloudTrail Query Strategies

**Strategy A: Query by ARN** (for update/delete actions)
- Used when identifier is an AWS ARN
- Queries: `AttributeKey=ResourceName,AttributeValue=<ARN>`
- Example: `arn:aws:ec2:us-east-1:123456789012:vpc/vpc-xxx`

**Strategy B: Query by EventName** (for create actions = manual deletions)
- Used when action is "create" (indicates manual deletion)
- Maps resource type to delete event (e.g., `aws_subnet` → `DeleteSubnet`)
- Queries: `AttributeKey=EventName,AttributeValue=<DeleteEvent>`

### 3. Actor Attribution Flow

```
CloudTrail Event JSON
    ↓
Extract userIdentity
    ↓
Determine actor type (IAMUser, AssumedRole, Root, AWSService)
    ↓
Extract actor_name, actor_arn, event_time
    ↓
Add to drift_resources_attributed.txt
    ↓
Include in drift_report.json
    ↓
Parse in Python ResourceChange model
    ↓
Display in change_summary
    ↓
Show in Telegram notification
```

## Code Changes Summary

### Scripts Created/Modified
- ✅ `generate-plan-json.sh` (NEW, 126 lines)
- ✅ `parse-terraform-plan.sh` (REFACTORED, 80 lines)
- ✅ `query-cloudtrail.sh` (REFACTORED, 155 lines)
- ✅ `generate-drift-report.sh` (NEW, 95 lines)

### Python Changes
- ✅ `models.py`: Added 3 fields + 1 property to ResourceChange
- ✅ `notify_telegram.py`: Updated parse_drift_report function

### Workflow Changes
- ✅ Removed "Extract Drifted Resource ARNs" step (~195 lines)
- ✅ Removed inline CloudTrail query logic (~254 lines)
- ✅ Added "Generate Plan JSON" step (10 lines)
- ✅ Updated "Parse Terraform Plan" step (20 lines)
- ✅ Updated "Query CloudTrail" step (40 lines)
- ✅ Updated "Generate Drift Report" step (15 lines)

**Net Result**: ~350 lines removed, cleaner modular architecture

## Testing

### Unit Tests (Manual)
All components tested with sample data:

**Test 1: parse-terraform-plan.sh**
- Input: JSON plan with update/create/delete actions
- Output: Correctly extracted ARNs, IDs, and Names
- Result: ✅ PASS

**Test 2: query-cloudtrail.sh**
- Input: Parsed resources with identifiers
- Strategy A: Queried by ARN for update/delete
- Strategy B: Queried by EventName for creates
- Output: Successfully extracted actor_name, actor_arn, event_time
- Result: ✅ PASS

**Test 3: generate-drift-report.sh**
- Input: Attributed resources
- Output: Valid JSON with all attribution fields
- Result: ✅ PASS

**Test 4: Python models**
- Input: Generated drift report JSON
- Parsing: Successfully created ResourceChange objects with actor fields
- Display: change_summary includes actor information
- Result: ✅ PASS

### Security Scan
- CodeQL: ✅ No alerts (actions, python)
- Code Review: ✅ All issues addressed

## Example Output

### Before Refactoring
```
Resource: module.subnet["pub_sub1"].aws_subnet.this
Action: create
Attribution: *(unavailable)*  ❌ No actor information
```

### After Refactoring
```
Resource: module.subnet["pub_sub1"].aws_subnet.this
Action: create
Actor: john.doe  ✅
Actor ARN: arn:aws:iam::123456789012:user/john.doe  ✅
Event Time: 2024-01-15T10:30:00Z  ✅
CloudTrail Query: EventName=DeleteSubnet (manual deletion detected)
```

## Benefits

1. **Accurate Attribution**: Correctly identifies actors for manual deletions
2. **Complete Data Flow**: Actor info reaches both GitHub Issues and Telegram
3. **Maintainable**: Modular scripts, ~350 lines less code
4. **Testable**: Each component can be tested independently
5. **Extensible**: Easy to add new resource types or query strategies
6. **Reliable**: Handles edge cases (Root, AssumedRole, AWSService actors)

## Manual Deletion Example

**Scenario**: DevOps engineer manually deletes a subnet from AWS Console

**Before Refactoring**:
- Terraform plan shows: `# module.subnet["pub_sub1"] will be created`
- Attribution: `*(unavailable)*`
- Result: ❌ No way to know who deleted it

**After Refactoring**:
1. Parse step: Detects `action=create`, identifier=`pub_sub1`
2. CloudTrail step: Queries `EventName=DeleteSubnet`
3. Finds: `john.doe` deleted subnet at `2024-01-15T10:30:00Z`
4. Result: ✅ Complete attribution in notifications

## Files Changed
- `.github/workflows/drift-detection.yml` (~350 lines reduced)
- `scripts/drift-detection/parse-terraform-plan.sh` (refactored)
- `scripts/drift-detection/query-cloudtrail.sh` (refactored)
- `scripts/drift-detection/generate-plan-json.sh` (new)
- `scripts/drift-detection/generate-drift-report.sh` (new)
- `scripts/drift-detection/models.py` (+4 lines)
- `scripts/drift-detection/notify_telegram.py` (+3 lines)
- `scripts/drift-detection/REFACTORING_README.md` (new)

## Future Enhancements
1. Add more resource type → EventName mappings
2. Implement CloudTrail query result caching
3. Add metrics for attribution success rate
4. Support custom identifier extraction rules
5. Add retry logic for CloudTrail rate limits

## Security Considerations
- ✅ No secrets hardcoded
- ✅ CloudTrail queries use AWS credentials from OIDC
- ✅ No sensitive data in logs (ARNs are sanitized)
- ✅ CodeQL security scan passed
- ✅ All variables properly quoted in bash scripts

## Deployment Notes
1. All changes are backward compatible
2. No new dependencies required (uses existing AWS CLI, jq, etc.)
3. Scripts are executable and properly permissioned
4. Workflow continues on CloudTrail failures (graceful degradation)
5. Attribution shown as "unavailable" if CloudTrail data missing

## Validation Checklist
- [x] All scripts tested with sample data
- [x] Python models tested with attributed JSON
- [x] Workflow YAML validated
- [x] Code review issues addressed
- [x] Security scan passed (CodeQL)
- [x] Documentation created
- [x] Changes committed to feature branch
- [x] Ready for merge to dev4 branch

## Conclusion
Successfully implemented a robust, modular drift detection system that accurately attributes infrastructure changes to responsible actors, including manual deletions. The refactored architecture is cleaner, more maintainable, and provides complete visibility into infrastructure drift.
