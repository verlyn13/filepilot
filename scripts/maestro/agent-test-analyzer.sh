#!/usr/bin/env bash
# Agent Test Analyzer for Maestro Results
# Analyzes test failures and provides agent-actionable recommendations

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

RESULTS_DIR="${1:-.build/maestro-results}"
TELEMETRY_ENDPOINT="${TELEMETRY_ENDPOINT:-http://localhost:3000/api/agent/decision}"
TRACE_ID="${TRACE_ID:-$(uuidgen)}"

echo -e "${BLUE}🤖 Agent Test Analyzer${NC}"
echo "Analyzing results in: $RESULTS_DIR"
echo "Trace ID: $TRACE_ID"
echo ""

if [ ! -d "$RESULTS_DIR" ]; then
    echo -e "${RED}❌ Results directory not found: $RESULTS_DIR${NC}"
    exit 1
fi

# Analyze test results
TOTAL_FLOWS=0
FAILED_FLOWS=0
declare -a FAILURES

# Find all log files
for log_file in "$RESULTS_DIR"/*.log; do
    if [ ! -f "$log_file" ]; then
        continue
    fi

    TOTAL_FLOWS=$((TOTAL_FLOWS + 1))
    FLOW_NAME=$(basename "$log_file" .log)

    # Check if flow failed
    if grep -q "failed\|error\|Error" "$log_file"; then
        FAILED_FLOWS=$((FAILED_FLOWS + 1))

        # Extract error message
        ERROR_MSG=$(grep -i "error\|failed\|exception" "$log_file" | head -1 || echo "Unknown error")

        FAILURES+=("$FLOW_NAME:$ERROR_MSG")

        echo -e "${RED}✗ $FLOW_NAME${NC}"
        echo "  Error: $ERROR_MSG"
        echo ""
    fi
done

# Generate agent recommendations
if [ $FAILED_FLOWS -gt 0 ]; then
    echo -e "${BLUE}Agent Recommendations:${NC}"
    echo ""

    for failure in "${FAILURES[@]}"; do
        FLOW_NAME="${failure%%:*}"
        ERROR="${failure#*:}"

        echo -e "${YELLOW}Flow: $FLOW_NAME${NC}"

        # Pattern matching for common failures
        if echo "$ERROR" | grep -qi "element not found\|assertVisible failed"; then
            echo "  → Issue: UI element not found"
            echo "  → Action: Update flow YAML with correct element IDs/text"
            echo "  → Tool: Run 'maestro studio' to inspect current UI"
            echo "  → Agent Task: Update .maestro/flows/${FLOW_NAME}.yaml"

        elif echo "$ERROR" | grep -qi "timeout\|timed out"; then
            echo "  → Issue: Operation timed out"
            echo "  → Action: Increase timeout or add wait conditions"
            echo "  → Agent Task: Add 'wait' command or optimize app performance"

        elif echo "$ERROR" | grep -qi "app not found\|bundle"; then
            echo "  → Issue: App bundle not accessible"
            echo "  → Action: Verify app build and bundle ID"
            echo "  → Agent Task: Check xcodebuild output and bundle identifier"

        elif echo "$ERROR" | grep -qi "screenshot\|visual"; then
            echo "  → Issue: Visual regression detected"
            echo "  → Action: Review screenshot diff and update baseline"
            echo "  → Agent Task: Update .maestro/baselines/ if change is intentional"

        else
            echo "  → Issue: Unknown failure"
            echo "  → Action: Review full log at: $RESULTS_DIR/${FLOW_NAME}.log"
            echo "  → Agent Task: Manual investigation required"
        fi

        echo ""

        # Record decision to telemetry
        DECISION_PAYLOAD=$(cat <<EOF
{
    "agent": "maestro-analyzer",
    "action": "test_failure_analysis",
    "context": "Analyzed failed Maestro test: $FLOW_NAME",
    "result": "failure",
    "trace_id": "$TRACE_ID",
    "metadata": {
        "flow": "$FLOW_NAME",
        "error": "$ERROR",
        "total_failures": $FAILED_FLOWS
    }
}
EOF
)

        curl -X POST "$TELEMETRY_ENDPOINT" \
            -H "Content-Type: application/json" \
            -H "x-trace-id: $TRACE_ID" \
            -d "$DECISION_PAYLOAD" \
            --silent --fail > /dev/null 2>&1 || true
    done

    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Review failure patterns above"
    echo "2. Run 'maestro studio' to inspect UI elements"
    echo "3. Update flow YAML files as recommended"
    echo "4. Re-run tests: ./scripts/maestro/run-maestro-tests.sh"
    echo "5. Check trace in Jaeger: http://localhost:16686 (search: $TRACE_ID)"
    echo ""

    # Generate agent-actionable report
    REPORT_FILE="$RESULTS_DIR/agent-analysis.json"
    cat > "$REPORT_FILE" <<EOF
{
    "trace_id": "$TRACE_ID",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "total_flows": $TOTAL_FLOWS,
    "failed_flows": $FAILED_FLOWS,
    "pass_rate": $(awk "BEGIN {printf \"%.2f\", (($TOTAL_FLOWS - $FAILED_FLOWS) / $TOTAL_FLOWS) * 100}"),
    "failures": [
EOF

    FIRST=true
    for failure in "${FAILURES[@]}"; do
        FLOW_NAME="${failure%%:*}"
        ERROR="${failure#*:}"

        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            echo "," >> "$REPORT_FILE"
        fi

        cat >> "$REPORT_FILE" <<EOF
        {
            "flow": "$FLOW_NAME",
            "error": $(echo "$ERROR" | jq -R .),
            "log_file": "$RESULTS_DIR/${FLOW_NAME}.log",
            "screenshot": ".maestro/screenshots/${FLOW_NAME}_*.png"
        }
EOF
    done

    cat >> "$REPORT_FILE" <<EOF

    ],
    "recommendations": [
        "Review flow YAML files for element selector accuracy",
        "Use 'maestro studio' for interactive UI inspection",
        "Update baselines if UI changes are intentional",
        "Check app build and bundle ID configuration"
    ]
}
EOF

    echo -e "${GREEN}✓ Agent analysis saved to: $REPORT_FILE${NC}"

else
    echo -e "${GREEN}✅ All tests passed - no failures to analyze${NC}"

    # Record success
    DECISION_PAYLOAD=$(cat <<EOF
{
    "agent": "maestro-analyzer",
    "action": "test_analysis",
    "context": "All Maestro tests passed",
    "result": "success",
    "trace_id": "$TRACE_ID",
    "metadata": {
        "total_flows": $TOTAL_FLOWS,
        "pass_rate": 100
    }
}
EOF
)

    curl -X POST "$TELEMETRY_ENDPOINT" \
        -H "Content-Type: application/json" \
        -H "x-trace-id: $TRACE_ID" \
        -d "$DECISION_PAYLOAD" \
        --silent --fail > /dev/null 2>&1 || true
fi
