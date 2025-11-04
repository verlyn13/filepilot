#!/usr/bin/env bash
# Maestro & IDB Installation Script for FilePilot Agentic Development
# Installs Maestro CLI and Facebook IDB for iOS/macOS UI testing with full observability

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TELEMETRY_ENDPOINT="${TELEMETRY_ENDPOINT:-http://localhost:3000/api/maestro/telemetry}"
TRACE_ID="${TRACE_ID:-$(uuidgen)}"

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

echo -e "${BLUE}🚀 Installing Maestro & IDB for FilePilot UI Testing${NC}"
echo "=============================================="
echo ""

# Check prerequisites
echo -e "${BLUE}1. Checking prerequisites...${NC}"

if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode not found${NC}"
    echo "Install Xcode from App Store and run: xcode-select --install"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n 1)
echo -e "${GREEN}✓ $XCODE_VERSION${NC}"

if ! command -v brew &> /dev/null; then
    echo -e "${RED}❌ Homebrew not found${NC}"
    echo "Install from: https://brew.sh"
    exit 1
fi

echo -e "${GREEN}✓ Homebrew installed${NC}"
echo ""

# Install Maestro
echo -e "${BLUE}2. Installing Maestro CLI...${NC}"

if command -v maestro &> /dev/null; then
    MAESTRO_VERSION=$(maestro --version 2>&1 | head -n 1)
    echo -e "${YELLOW}⚠️  Maestro already installed: $MAESTRO_VERSION${NC}"
    read -p "Reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping Maestro installation"
    else
        echo "Reinstalling Maestro..."
        curl -Ls "https://get.maestro.mobile.dev" | bash
    fi
else
    echo "Installing Maestro..."
    curl -Ls "https://get.maestro.mobile.dev" | bash
fi

# Verify Maestro installation
if command -v maestro &> /dev/null; then
    MAESTRO_VERSION=$(maestro --version 2>&1 | head -n 1)
    echo -e "${GREEN}✓ Maestro installed: $MAESTRO_VERSION${NC}"

    send_telemetry "maestro_installed" "{
        \"version\": \"$MAESTRO_VERSION\",
        \"platform\": \"$(uname -s)\",
        \"arch\": \"$(uname -m)\"
    }"
else
    echo -e "${RED}❌ Maestro installation failed${NC}"
    exit 1
fi
echo ""

# Install Facebook IDB (for iOS simulator control)
echo -e "${BLUE}3. Installing Facebook IDB (optional but recommended)...${NC}"

if command -v idb_companion &> /dev/null; then
    IDB_VERSION=$(idb_companion --version 2>&1 | head -n 1)
    echo -e "${YELLOW}⚠️  IDB already installed: $IDB_VERSION${NC}"
else
    echo "Installing IDB via Homebrew..."
    brew tap facebook/fb
    brew install facebook/fb/idb-companion
fi

# Verify IDB installation
if command -v idb_companion &> /dev/null; then
    IDB_VERSION=$(idb_companion --version 2>&1 | head -n 1)
    echo -e "${GREEN}✓ IDB installed: $IDB_VERSION${NC}"

    send_telemetry "idb_installed" "{
        \"version\": \"$IDB_VERSION\"
    }"
else
    echo -e "${YELLOW}⚠️  IDB installation failed (optional - continuing)${NC}"
fi
echo ""

# Verify setup
echo -e "${BLUE}4. Verifying installation...${NC}"

echo "Testing Maestro CLI:"
maestro --help > /dev/null 2>&1 && echo -e "${GREEN}✓ Maestro CLI working${NC}" || echo -e "${RED}❌ Maestro CLI not working${NC}"

echo ""
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Run smoke test: ./scripts/maestro/run-maestro-tests.sh smoke"
echo "2. View available flows: ls .maestro/flows/"
echo "3. Run all tests: ./scripts/maestro/run-maestro-tests.sh all"
echo ""
echo "Maestro Studio (interactive): maestro studio"
echo "Documentation: https://maestro.mobile.dev"

send_telemetry "maestro_setup_complete" "{
    \"maestro_installed\": true,
    \"idb_installed\": $(command -v idb_companion &> /dev/null && echo "true" || echo "false")
}"
