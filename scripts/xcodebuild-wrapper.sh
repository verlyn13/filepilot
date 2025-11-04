#!/usr/bin/env bash
# Xcodebuild Wrapper with Full Observability
# Integrates all Xcode CLI commands with telemetry system for agentic development
# Based on official Apple xcodebuild documentation

set -euo pipefail

# Configuration
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TELEMETRY_ENDPOINT="${TELEMETRY_ENDPOINT:-http://localhost:3000/api/swift/telemetry}"
LOG_DIR="${PROJECT_ROOT}/logs/xcode"
RESULT_BUNDLE_DIR="${PROJECT_ROOT}/.build/results"
TRACE_ID="${TRACE_ID:-$(uuidgen)}"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure directories exist
mkdir -p "$LOG_DIR" "$RESULT_BUNDLE_DIR"

# Functions for telemetry
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

# Check Xcode installation
check_xcode() {
    echo -e "${BLUE}Checking Xcode installation...${NC}"

    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}❌ xcodebuild not found${NC}"
        echo "Install with: xcode-select --install"
        exit 1
    fi

    local xcode_version=$(xcodebuild -version | head -n 1)
    local xcode_path=$(xcode-select --print-path)
    local sdk_version=$(xcodebuild -showsdks | grep macosx | tail -n 1)

    echo -e "${GREEN}✓ $xcode_version${NC}"
    echo -e "${GREEN}✓ Path: $xcode_path${NC}"
    echo -e "${GREEN}✓ SDK: $sdk_version${NC}"

    send_telemetry "xcode_version_check" "{
        \"xcode_version\": \"$xcode_version\",
        \"xcode_path\": \"$xcode_path\",
        \"sdk_version\": \"$sdk_version\"
    }"
}

# List project information
list_project_info() {
    local project_file="$1"

    echo -e "${BLUE}Listing project information...${NC}"

    # List schemes
    echo "Available Schemes:"
    xcodebuild -list -project "$project_file" | grep -A 100 "Schemes:" | tail -n +2

    # List targets
    echo ""
    echo "Available Targets:"
    xcodebuild -list -project "$project_file" | grep -A 100 "Targets:" | tail -n +2

    # List build configurations
    echo ""
    echo "Build Configurations:"
    xcodebuild -list -project "$project_file" | grep -A 100 "Build Configurations:" | tail -n +2
}

# Show build settings
show_build_settings() {
    local project_file="$1"
    local scheme="$2"
    local output_file="$LOG_DIR/build-settings-$(date +%Y%m%d-%H%M%S).txt"

    echo -e "${BLUE}Capturing build settings...${NC}"

    xcodebuild -showBuildSettings \
        -project "$project_file" \
        -scheme "$scheme" > "$output_file"

    echo -e "${GREEN}✓ Build settings saved to: $output_file${NC}"

    # Extract key settings for telemetry
    local product_name=$(grep "PRODUCT_NAME =" "$output_file" | head -1 | awk '{print $3}')
    local bundle_id=$(grep "PRODUCT_BUNDLE_IDENTIFIER =" "$output_file" | head -1 | awk '{print $3}')
    local deployment_target=$(grep "MACOSX_DEPLOYMENT_TARGET =" "$output_file" | head -1 | awk '{print $3}')

    send_telemetry "build_settings_captured" "{
        \"product_name\": \"$product_name\",
        \"bundle_id\": \"$bundle_id\",
        \"deployment_target\": \"$deployment_target\",
        \"settings_file\": \"$output_file\"
    }"
}

# Build project
build_project() {
    local project_file="$1"
    local scheme="$2"
    local configuration="${3:-Debug}"
    local clean="${4:-false}"

    echo -e "${BLUE}Building project...${NC}"
    echo "Project: $project_file"
    echo "Scheme: $scheme"
    echo "Configuration: $configuration"
    echo "Clean build: $clean"
    echo ""

    local start_time=$(date +%s)
    local log_file="$LOG_DIR/build-$(date +%Y%m%d-%H%M%S).log"
    local result_bundle="$RESULT_BUNDLE_DIR/build-$(date +%Y%m%d-%H%M%S).xcresult"

    # Build command
    local build_cmd="xcodebuild"

    if [ "$clean" = "true" ]; then
        build_cmd="$build_cmd clean"
    fi

    build_cmd="$build_cmd build -project \"$project_file\" -scheme \"$scheme\" -configuration \"$configuration\" -resultBundlePath \"$result_bundle\""

    send_telemetry "build_started" "{
        \"scheme\": \"$scheme\",
        \"configuration\": \"$configuration\",
        \"clean\": $clean,
        \"log_file\": \"$log_file\",
        \"result_bundle\": \"$result_bundle\"
    }"

    # Execute build
    if eval "$build_cmd" 2>&1 | tee "$log_file"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        # Parse build output
        local warnings=$(grep -c "warning:" "$log_file" || echo "0")
        local errors=$(grep -c "error:" "$log_file" || echo "0")

        echo ""
        echo -e "${GREEN}✓ Build succeeded in ${duration}s${NC}"
        echo -e "${YELLOW}  Warnings: $warnings${NC}"
        echo -e "  Errors: $errors"

        send_telemetry "build_completed" "{
            \"status\": \"success\",
            \"duration\": $duration,
            \"warnings\": $warnings,
            \"errors\": $errors,
            \"log_file\": \"$log_file\",
            \"result_bundle\": \"$result_bundle\"
        }"

        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local errors=$(grep -c "error:" "$log_file" || echo "0")

        echo ""
        echo -e "${RED}❌ Build failed after ${duration}s${NC}"
        echo -e "${RED}  Errors: $errors${NC}"
        echo "See log: $log_file"

        send_telemetry "build_completed" "{
            \"status\": \"failed\",
            \"duration\": $duration,
            \"errors\": $errors,
            \"log_file\": \"$log_file\",
            \"result_bundle\": \"$result_bundle\"
        }"

        return 1
    fi
}

# Run tests
run_tests() {
    local project_file="$1"
    local scheme="$2"
    local destination="${3:-platform=macOS}"

    echo -e "${BLUE}Running tests...${NC}"
    echo "Project: $project_file"
    echo "Scheme: $scheme"
    echo "Destination: $destination"
    echo ""

    local start_time=$(date +%s)
    local log_file="$LOG_DIR/test-$(date +%Y%m%d-%H%M%S).log"
    local result_bundle="$RESULT_BUNDLE_DIR/test-$(date +%Y%m%d-%H%M%S).xcresult"

    send_telemetry "test_started" "{
        \"scheme\": \"$scheme\",
        \"destination\": \"$destination\",
        \"log_file\": \"$log_file\",
        \"result_bundle\": \"$result_bundle\"
    }"

    # Run tests
    if xcodebuild test \
        -project "$project_file" \
        -scheme "$scheme" \
        -destination "$destination" \
        -resultBundlePath "$result_bundle" \
        2>&1 | tee "$log_file"; then

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        # Parse test results
        local tests_run=$(grep "Test Suite" "$log_file" | grep -c "passed\|failed" || echo "0")
        local tests_passed=$(grep "Test Suite" "$log_file" | grep -c "passed" || echo "0")
        local tests_failed=$(grep "Test Suite" "$log_file" | grep -c "failed" || echo "0")

        echo ""
        echo -e "${GREEN}✓ Tests completed in ${duration}s${NC}"
        echo -e "  Total: $tests_run"
        echo -e "${GREEN}  Passed: $tests_passed${NC}"
        echo -e "${RED}  Failed: $tests_failed${NC}"

        send_telemetry "test_completed" "{
            \"status\": \"success\",
            \"duration\": $duration,
            \"tests_run\": $tests_run,
            \"tests_passed\": $tests_passed,
            \"tests_failed\": $tests_failed,
            \"log_file\": \"$log_file\",
            \"result_bundle\": \"$result_bundle\"
        }"

        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        echo ""
        echo -e "${RED}❌ Tests failed after ${duration}s${NC}"
        echo "See log: $log_file"

        send_telemetry "test_completed" "{
            \"status\": \"failed\",
            \"duration\": $duration,
            \"log_file\": \"$log_file\",
            \"result_bundle\": \"$result_bundle\"
        }"

        return 1
    fi
}

# Show available destinations (simulators/devices)
show_destinations() {
    local scheme="$1"

    echo -e "${BLUE}Available destinations for scheme: $scheme${NC}"
    xcodebuild -showdestinations -scheme "$scheme" 2>/dev/null || echo "No destinations found"
}

# Archive project
archive_project() {
    local project_file="$1"
    local scheme="$2"
    local archive_path="$3"

    echo -e "${BLUE}Archiving project...${NC}"

    local start_time=$(date +%s)

    xcodebuild archive \
        -project "$project_file" \
        -scheme "$scheme" \
        -archivePath "$archive_path"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo -e "${GREEN}✓ Archive created in ${duration}s${NC}"
    echo "Archive: $archive_path"

    send_telemetry "archive_completed" "{
        \"scheme\": \"$scheme\",
        \"duration\": $duration,
        \"archive_path\": \"$archive_path\"
    }"
}

# Main command dispatcher
main() {
    local command="${1:-help}"

    case "$command" in
        check)
            check_xcode
            ;;
        list)
            list_project_info "${2:-FilePilot.xcodeproj}"
            ;;
        settings)
            show_build_settings "${2:-FilePilot.xcodeproj}" "${3:-FilePilot}"
            ;;
        build)
            build_project "${2:-FilePilot.xcodeproj}" "${3:-FilePilot}" "${4:-Debug}" "${5:-false}"
            ;;
        test)
            run_tests "${2:-FilePilot.xcodeproj}" "${3:-FilePilot}" "${4:-platform=macOS}"
            ;;
        destinations)
            show_destinations "${2:-FilePilot}"
            ;;
        archive)
            archive_project "${2:-FilePilot.xcodeproj}" "${3:-FilePilot}" "${4:-FilePilot.xcarchive}"
            ;;
        help|*)
            cat <<EOF
Xcodebuild Wrapper with Full Observability

Usage: $0 <command> [arguments]

Commands:
  check                              - Check Xcode installation and version
  list [project]                     - List project schemes, targets, and configurations
  settings [project] [scheme]        - Show build settings
  build [project] [scheme] [config] [clean] - Build project
  test [project] [scheme] [dest]     - Run tests
  destinations [scheme]              - Show available test destinations
  archive [project] [scheme] [path]  - Archive project
  help                               - Show this help message

Examples:
  $0 check
  $0 list FilePilot.xcodeproj
  $0 build FilePilot.xcodeproj FilePilot Debug false
  $0 test FilePilot.xcodeproj FilePilot "platform=macOS"
  $0 settings FilePilot.xcodeproj FilePilot

Environment Variables:
  PROJECT_ROOT          - Project root directory (default: auto-detect)
  TELEMETRY_ENDPOINT    - Telemetry API endpoint (default: http://localhost:3000/api/swift/telemetry)
  TRACE_ID              - Trace correlation ID (default: auto-generated UUID)
  LOG_DIR               - Log directory (default: \$PROJECT_ROOT/logs/xcode)
  RESULT_BUNDLE_DIR     - Result bundle directory (default: \$PROJECT_ROOT/.build/results)

All commands send telemetry to the observability backend for agentic development tracking.
EOF
            ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
