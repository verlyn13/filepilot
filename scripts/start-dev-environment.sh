#!/usr/bin/env bash
# Integrated Development Environment Startup Script
# Starts TypeScript observability server, observability stack, and monitors Swift development
# Supports: Docker Desktop, OrbStack
# Usage: ./scripts/start-dev-environment.sh

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Integrated Development Environment${NC}"
echo "=============================================="
echo ""

# Detect container runtime
RUNTIME_NAME="Unknown"
if docker info 2>/dev/null | grep -q "OrbStack"; then
  RUNTIME_NAME="OrbStack"
  echo -e "${GREEN}✨ Detected OrbStack runtime (optimized performance)${NC}"
elif docker info 2>/dev/null | grep -q "Docker Desktop"; then
  RUNTIME_NAME="Docker Desktop"
  echo -e "${BLUE}📦 Detected Docker Desktop${NC}"
else
  echo -e "${RED}❌ No container runtime detected${NC}"
  echo -e "${YELLOW}Please install OrbStack: brew install --cask orbstack${NC}"
  echo -e "${YELLOW}Or Docker Desktop: brew install --cask docker${NC}"
  exit 1
fi
echo ""

# Step 1: Validate Documentation
echo -e "${BLUE}1. Validating documentation...${NC}"
./scripts/validate-docs.sh || {
  echo -e "${RED}❌ Documentation validation failed${NC}"
  exit 1
}
echo ""

# Step 2: Start Observability Stack
echo -e "${BLUE}2. Starting observability stack with ${RUNTIME_NAME}...${NC}"
cd agentic-workflow/observability

# Use modern docker compose (no hyphen)
COMPOSE_CMD="${COMPOSE_CMD:-docker compose}"

if ${COMPOSE_CMD} ps 2>/dev/null | grep -q "Up"; then
  echo -e "${YELLOW}⚠️  Stack already running, restarting...${NC}"
  ${COMPOSE_CMD} restart
else
  echo -e "${GREEN}Starting fresh stack...${NC}"
  ${COMPOSE_CMD} up -d
fi

cd ../..
echo ""

# Step 3: Wait for Stack to be Ready
echo -e "${BLUE}3. Waiting for observability stack...${NC}"
echo -n "Checking Prometheus..."
timeout=30
while [ $timeout -gt 0 ]; do
  if curl -sf http://localhost:9090/-/ready > /dev/null 2>&1; then
    echo -e " ${GREEN}✓${NC}"
    break
  fi
  sleep 1
  ((timeout--))
  echo -n "."
done

if [ $timeout -eq 0 ]; then
  echo -e " ${RED}✗${NC}"
  echo -e "${RED}❌ Prometheus not ready${NC}"
fi

echo -n "Checking Grafana..."
timeout=30
while [ $timeout -gt 0 ]; do
  if curl -sf http://localhost:3001/api/health > /dev/null 2>&1; then
    echo -e " ${GREEN}✓${NC}"
    break
  fi
  sleep 1
  ((timeout--))
  echo -n "."
done

if [ $timeout -eq 0 ]; then
  echo -e " ${RED}✗${NC}"
  echo -e "${YELLOW}⚠️  Grafana may still be starting${NC}"
fi

echo -n "Checking Jaeger..."
timeout=15
while [ $timeout -gt 0 ]; do
  if curl -sf http://localhost:16686 > /dev/null 2>&1; then
    echo -e " ${GREEN}✓${NC}"
    break
  fi
  sleep 1
  ((timeout--))
  echo -n "."
done

if [ $timeout -eq 0 ]; then
  echo -e " ${RED}✗${NC}"
fi
echo ""

# Step 4: Start TypeScript Monitoring Server
echo -e "${BLUE}4. Starting TypeScript monitoring server...${NC}"
cd agentic-workflow

# Check if Biome is installed
if [ ! -d "node_modules/@biomejs/biome" ]; then
  echo -e "${YELLOW}⚠️  Installing dependencies...${NC}"
  bun install --no-frozen-lockfile || npm install
fi

# Start server in background
echo "Starting development server..."
bun run dev > ../logs/ts-server.log 2>&1 &
TS_PID=$!
echo "TypeScript server PID: $TS_PID"

cd ..
echo ""

# Step 5: Wait for TypeScript Server
echo -e "${BLUE}5. Waiting for TypeScript server...${NC}"
timeout=30
while [ $timeout -gt 0 ]; do
  if curl -sf http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Server is healthy${NC}"
    break
  fi
  sleep 1
  ((timeout--))
  echo -n "."
done

if [ $timeout -eq 0 ]; then
  echo -e "${RED}✗ Server not responding${NC}"
  echo -e "${YELLOW}Check logs/ts-server.log for details${NC}"
fi
echo ""

# Step 6: Display Status
echo ""
echo -e "${GREEN}✅ Development Environment Ready!${NC}"
echo "=============================================="
echo ""
echo -e "${BLUE}🎯 Runtime Information:${NC}"
echo "  Container Runtime: ${RUNTIME_NAME}"
if [ "$RUNTIME_NAME" == "OrbStack" ]; then
  echo "  Performance:       ✨ Optimized (native macOS integration)"
  echo "  File I/O:          ⚡ Near-native APFS speed"
else
  echo "  Performance:       📦 Standard"
  echo "  Migration Guide:   ORBSTACK_MIGRATION_PLAN.md (10× faster)"
fi
echo ""
echo -e "${BLUE}📊 Observability URLs:${NC}"
echo "  TypeScript Server:"
echo "    - Health:        http://localhost:3000/health"
echo "    - API Root:      http://localhost:3000/"
echo "    - Build Status:  http://localhost:3000/api/swift/build/status"
echo "    - Test Results:  http://localhost:3000/api/swift/tests/latest"
echo "    - Code Metrics:  http://localhost:3000/api/swift/metrics"
echo ""
echo "  Observability Stack:"
echo "    - Prometheus:    http://localhost:9090"
echo "    - Grafana:       http://localhost:3001 (admin/admin)"
echo "    - Jaeger:        http://localhost:16686"
echo "    - Loki:          http://localhost:3100"
echo "    - AlertManager:  http://localhost:9093"
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo "    - Index:         DOCUMENTATION_INDEX.md"
echo "    - Observability: agentic-workflow/docs/OBSERVABILITY.md"
echo "    - API Reference: agentic-workflow/docs/API.md"
echo "    - Scripts Guide: scripts/README.md"
echo "    - Agent Config:  .claude/config.yaml"
echo ""
echo -e "${BLUE}🛠️  Quick Commands:${NC}"
echo "    # Swift Development"
echo "    make swift-build       # Build Swift project"
echo "    make swift-test        # Run Swift tests"
echo ""
echo "    # TypeScript Development"
echo "    cd agentic-workflow"
echo "    bun run format         # Format code with Biome"
echo "    bun run lint           # Lint code with Biome"
echo "    bun run check          # Format + lint + organize imports"
echo ""
echo "    # Monitoring"
echo "    curl http://localhost:3000/health | jq"
echo "    curl http://localhost:3000/api/swift/build/status | jq"
echo "    curl http://localhost:3000/api/swift/tests/latest | jq"
echo ""
echo -e "${BLUE}📝 Agent Behavior:${NC}"
echo "  Agents will automatically:"
echo "  - Query build status before suggesting changes"
echo "  - Verify test coverage before commits"
echo "  - Analyze code complexity for refactoring decisions"
echo "  - Monitor telemetry for performance insights"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"
echo ""

# Create stop script
cat > /tmp/stop-dev-env.sh <<'EOF'
#!/bin/bash
echo "🛑 Stopping development environment..."

# Stop TypeScript server
pkill -f "tsx watch src/index.ts"

# Stop observability stack
cd agentic-workflow/observability
docker compose down

echo "✅ Stopped"
EOF

chmod +x /tmp/stop-dev-env.sh

echo "To stop all services: /tmp/stop-dev-env.sh"
echo ""

# Wait for interrupt
trap "bash /tmp/stop-dev-env.sh; exit" INT TERM

# Keep script running
wait $TS_PID
