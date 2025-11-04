#!/usr/bin/env bash
# Maestro Test Runner with Full Observability Integration
# Runs FilePilot UI tests and sends results to observability backend

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
MAESTRO_DIR="${PROJECT_ROOT}/.maestro"
RESULTS_DIR="${PROJECT_ROOT}/.build/maestro-results"
TELEMETRY_ENDPOINT="${TELEMETRY_ENDPOINT:-http://localhost:3000/api/maestro/telemetry}"
TRACE_ID="${TRACE_ID:-$(uuidgen)}"
TEST_SUITE="${1:-all}"

# Ensure directories exist
mkdir -p "$RESULTS_DIR"

# Send telemetry
send_telemetry() {
    local event="$1"
    local metadata="$2"

    local payload=$(cat <<EOF
{
    "event": "$event",
    "metadata": $metadata,
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "trace_id": "$TRACE_ID"
}
EOF
)

    curl -X POST "$TELEMETRY_ENDPOINT" \
        -H "Content-Type: application/json" \
        -H "x-trace-id: $TRACE_ID" \
        -d "$payload" \
        --silent --fail > /dev/null 2>&1 || true
}

echo -e "${BLUE}🧪 Running FilePilot Maestro Tests${NC}"
echo "=============================================="
echo "Suite: $TEST_SUITE"
echo "Trace ID: $TRACE_ID"
echo ""

# Check Maestro is installed
if ! command -v maestro &> /dev/null; then
    echo -e "${RED}❌ Maestro not installed${NC}"
    echo "Run: ./scripts/maestro/install-maestro.sh"
    exit 1
fi

MAESTRO_VERSION=$(maestro --version 2>&1 | head -n 1)
echo -e "${GREEN}✓ Maestro $MAESTRO_VERSION${NC}"
echo ""

# Determine which flows to run
FLOWS=()

case "$TEST_SUITE" in
    smoke)
        FLOWS=("$MAESTRO_DIR/flows/01_smoke_test.yaml")
        ;;
    navigation)
        FLOWS=("$MAESTRO_DIR/flows/02_navigation_test.yaml")
        ;;
    views)
        FLOWS=("$MAESTRO_DIR/flows/03_view_modes_test.yaml")
        ;;
    git)
        FLOWS=("$MAESTRO_DIR/flows/04_git_panel_test.yaml")
        ;;
    inspector)
        FLOWS=("$MAESTRO_DIR/flows/05_inspector_panel_test.yaml")
        ;;
    filter)
        FLOWS=("$MAESTRO_DIR/flows/06_filter_panel_test.yaml")
        ;;
    all)
        FLOWS=("$MAESTRO_DIR/flows/"*.yaml)
        ;;
    *)
        # Custom flow file
        if [ -f "$TEST_SUITE" ]; then
            FLOWS=("$TEST_SUITE")
        else
            echo -e "${RED}❌ Unknown test suite: $TEST_SUITE${NC}"
            echo "Available: smoke, navigation, views, git, inspector, filter, all, or <path-to-flow.yaml>"
            exit 1
        fi
        ;;
esac

echo "Running ${#FLOWS[@]} flow(s)..."
echo ""

# Track results
TOTAL=0
PASSED=0
FAILED=0
FAILED_FLOWS=()

START_TIME=$(date +%s)

send_telemetry "maestro_test_started" "{
    \"suite\": \"$TEST_SUITE\",
    \"flow_count\": ${#FLOWS[@]},
    \"trace_id\": \"$TRACE_ID\"
}"

# Run each flow
for flow in "${FLOWS[@]}"; do
    TOTAL=$((TOTAL + 1))
    FLOW_NAME=$(basename "$flow" .yaml)

    echo -e "${BLUE}Running: $FLOW_NAME${NC}"

    FLOW_START=$(date +%s)
    RESULT_FILE="$RESULTS_DIR/${FLOW_NAME}_result.xml"

    # Run Maestro flow
    if maestro test "$flow" --format junit --output "$RESULT_FILE" > "$RESULTS_DIR/${FLOW_NAME}.log" 2>&1; then
        PASSED=$((PASSED + 1))
        FLOW_END=$(date +%s)
        DURATION=$((FLOW_END - FLOW_START))

        echo -e "${GREEN}✓ $FLOW_NAME passed (${DURATION}s)${NC}"

        send_telemetry "maestro_flow_passed" "{
            \"flow\": \"$FLOW_NAME\",
            \"duration\": $DURATION,
            \"screenshots\": $(find .maestro/screenshots -name \"${FLOW_NAME}_*.png\" | wc -l | tr -d ' ')
        }"
    else
        FAILED=$((FAILED + 1))
        FAILED_FLOWS+=("$FLOW_NAME")
        FLOW_END=$(date +%s)
        DURATION=$((FLOW_END - FLOW_START))

        echo -e "${RED}✗ $FLOW_NAME failed (${DURATION}s)${NC}"
        echo "  Log: $RESULTS_DIR/${FLOW_NAME}.log"

        # Extract error from log
        ERROR_MSG=$(tail -n 5 "$RESULTS_DIR/${FLOW_NAME}.log" | tr '\n' ' ')

        send_telemetry "maestro_flow_failed" "{
            \"flow\": \"$FLOW_NAME\",
            \"duration\": $DURATION,
            \"error\": \"$ERROR_MSG\"
        }"
    fi

    echo ""
done

END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))

# Summary
echo "=============================================="
echo -e "${BLUE}Test Summary${NC}"
echo "Total: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "Duration: ${TOTAL_DURATION}s"
echo ""

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed flows:${NC}"
    for flow in "${FAILED_FLOWS[@]}"; do
        echo "  - $flow"
    done
    echo ""
fi

# Results location
echo "Results: $RESULTS_DIR"
echo "Screenshots: .maestro/screenshots/"
echo "Trace ID: $TRACE_ID"
echo ""

# Send final telemetry
send_telemetry "maestro_test_completed" "{
    \"suite\": \"$TEST_SUITE\",
    \"total\": $TOTAL,
    \"passed\": $PASSED,
    \"failed\": $FAILED,
    \"duration\": $TOTAL_DURATION,
    \"trace_id\": \"$TRACE_ID\"
}"

# Exit with appropriate code
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All tests passed${NC}"
    exit 0
fi
