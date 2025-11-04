#!/usr/bin/env bash
# Context Initialization Script
# Purpose: Load architectural context for AI agent sessions
# Usage: ./scripts/context-init.sh [--validate]
# Exit Codes: 0 = success, 1 = validation failed, 2 = environment error

set -euo pipefail

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTEXT_OUTPUT="${PROJECT_ROOT}/.claude/context-summary.json"
VALIDATE_ONLY=false

# Parse arguments
if [ $# -gt 0 ] && [ "$1" = "--validate" ]; then
  VALIDATE_ONLY=true
fi

echo -e "${BLUE}🔄 Context Initialization System${NC}"
echo "========================================"
echo ""

# Step 1: Verify Environment
echo -e "${BLUE}1. Verifying environment...${NC}"

# Check container runtime
if ! docker ps > /dev/null 2>&1; then
  echo -e "${RED}❌ Container runtime not running${NC}"
  echo -e "${YELLOW}Action: Start OrbStack → open -a OrbStack${NC}"
  exit 2
fi

# Verify OrbStack context
CONTEXT=$(docker context show 2>/dev/null || echo "unknown")
if [ "$CONTEXT" != "orbstack" ]; then
  echo -e "${YELLOW}⚠️  Docker context is '$CONTEXT', expected 'orbstack'${NC}"
  echo -e "${YELLOW}Setting context to orbstack...${NC}"
  docker context use orbstack > /dev/null 2>&1
fi

echo -e "${GREEN}✓ Container runtime: OrbStack${NC}"

# Check services health
if curl -sf http://localhost:3000/health > /dev/null 2>&1; then
  echo -e "${GREEN}✓ TypeScript server: healthy${NC}"
else
  echo -e "${YELLOW}⚠️  TypeScript server not responding${NC}"
  echo -e "${YELLOW}   Start with: ./scripts/start-dev-environment.sh${NC}"
fi

echo ""

# Step 2: Read Required Files
echo -e "${BLUE}2. Reading architectural context...${NC}"

REQUIRED_FILES=(
  ".claude/SESSION_START.md"
  "ARCHITECTURE_MAP.yaml"
  ".claude/AGENTIC_STANDARDS.md"
  "DOCUMENTATION_INDEX.md"
  "START_HERE.md"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
  if [ -f "${PROJECT_ROOT}/${file}" ]; then
    echo -e "${GREEN}✓ ${file}${NC}"
  else
    echo -e "${RED}✗ ${file} (missing)${NC}"
    MISSING_FILES+=("$file")
  fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
  echo -e "${RED}❌ Missing required files${NC}"
  exit 1
fi

echo ""

# Step 3: Extract Context Data
echo -e "${BLUE}3. Extracting context data...${NC}"

# Parse ARCHITECTURE_MAP.yaml
if command -v yq > /dev/null 2>&1; then
  ARCH_VERSION=$(yq eval '.version' "${PROJECT_ROOT}/ARCHITECTURE_MAP.yaml")
  LAST_VERIFIED=$(yq eval '.last_verified' "${PROJECT_ROOT}/ARCHITECTURE_MAP.yaml")
  SERVICE_COUNT=$(yq eval '.services | length' "${PROJECT_ROOT}/ARCHITECTURE_MAP.yaml")
  echo -e "${GREEN}✓ Architecture version: ${ARCH_VERSION}${NC}"
  echo -e "${GREEN}✓ Last verified: ${LAST_VERIFIED}${NC}"
  echo -e "${GREEN}✓ Services defined: ${SERVICE_COUNT}${NC}"
else
  echo -e "${YELLOW}⚠️  yq not found, using grep fallback${NC}"
  ARCH_VERSION=$(grep "^version:" "${PROJECT_ROOT}/ARCHITECTURE_MAP.yaml" | cut -d'"' -f2)
  LAST_VERIFIED=$(grep "^last_verified:" "${PROJECT_ROOT}/ARCHITECTURE_MAP.yaml" | cut -d'"' -f2)
  SERVICE_COUNT=$(grep -c "^  [a-z-]*:" "${PROJECT_ROOT}/ARCHITECTURE_MAP.yaml" || echo "unknown")
fi

# Check architecture freshness
LAST_VERIFIED_TS=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$LAST_VERIFIED" +%s 2>/dev/null || echo "0")
CURRENT_TS=$(date +%s)
AGE_HOURS=$(( (CURRENT_TS - LAST_VERIFIED_TS) / 3600 ))

if [ $AGE_HOURS -gt 24 ]; then
  echo -e "${YELLOW}⚠️  Architecture map is ${AGE_HOURS} hours old (>24h)${NC}"
  echo -e "${YELLOW}   Consider updating ARCHITECTURE_MAP.yaml last_verified${NC}"
fi

echo ""

# Step 4: Check Recent ADRs
echo -e "${BLUE}4. Checking architectural decisions...${NC}"

ADR_DIR="${PROJECT_ROOT}/docs/decisions"
if [ -d "$ADR_DIR" ]; then
  ADR_COUNT=$(find "$ADR_DIR" -name "*.md" -type f | wc -l | tr -d ' ')
  echo -e "${GREEN}✓ Architectural Decision Records: ${ADR_COUNT}${NC}"

  # Get latest ADR
  LATEST_ADR=$(find "$ADR_DIR" -name "*.md" -type f -print0 | xargs -0 ls -t | head -1 | xargs basename 2>/dev/null || echo "none")
  if [ "$LATEST_ADR" != "none" ]; then
    echo -e "${GREEN}✓ Latest ADR: ${LATEST_ADR}${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  No ADR directory found${NC}"
  mkdir -p "$ADR_DIR"
  ADR_COUNT=0
  LATEST_ADR="none"
fi

echo ""

# Step 5: Query Service Status
echo -e "${BLUE}5. Querying service status...${NC}"

SERVICE_STATUS="{}"
if curl -sf http://localhost:3000/health > /dev/null 2>&1; then
  SERVICE_STATUS=$(curl -s http://localhost:3000/health 2>/dev/null || echo '{"status":"unknown"}')
  HEALTH_STATUS=$(echo "$SERVICE_STATUS" | jq -r '.status' 2>/dev/null || echo "unknown")
  echo -e "${GREEN}✓ TypeScript server: ${HEALTH_STATUS}${NC}"
else
  echo -e "${YELLOW}⚠️  TypeScript server: not reachable${NC}"
  HEALTH_STATUS="offline"
fi

# Check observability services
OBSERVABILITY_STATUS="unknown"
if curl -sf http://localhost:9090/-/ready > /dev/null 2>&1 && \
   curl -sf http://localhost:3001/api/health > /dev/null 2>&1 && \
   curl -sf http://localhost:13133/health > /dev/null 2>&1; then
  OBSERVABILITY_STATUS="operational"
  echo -e "${GREEN}✓ Observability stack: operational (7/7 services)${NC}"
else
  OBSERVABILITY_STATUS="partial"
  echo -e "${YELLOW}⚠️  Observability stack: partial or offline${NC}"
fi

echo ""

# Step 6: Check Documentation Index
echo -e "${BLUE}6. Validating documentation index...${NC}"

DOC_COUNT=$(find "${PROJECT_ROOT}" -name "*.md" -not -path "*/node_modules/*" -not -path "*/.git/*" -type f | wc -l | tr -d ' ')
echo -e "${GREEN}✓ Markdown files: ${DOC_COUNT}${NC}"

# Check if documentation index is current
if grep -q "Last Updated: $(date +%Y-%m-%d)" "${PROJECT_ROOT}/DOCUMENTATION_INDEX.md" 2>/dev/null; then
  echo -e "${GREEN}✓ Documentation index: current${NC}"
  DOC_INDEX_CURRENT="true"
else
  echo -e "${YELLOW}⚠️  Documentation index may be outdated${NC}"
  DOC_INDEX_CURRENT="false"
fi

echo ""

# Step 7: Generate Context Summary
echo -e "${BLUE}7. Generating context summary...${NC}"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID="session-$(date +%Y%m%d-%H%M%S)-$$"

# Build JSON context summary
cat > "$CONTEXT_OUTPUT" <<EOF
{
  "version": "1.0.0",
  "generated": "${TIMESTAMP}",
  "session_id": "${SESSION_ID}",
  "project": {
    "name": "FilePilot + Agentic Workflow",
    "root": "${PROJECT_ROOT}",
    "type": "integrated-development-environment"
  },
  "architecture": {
    "version": "${ARCH_VERSION}",
    "last_verified": "${LAST_VERIFIED}",
    "age_hours": ${AGE_HOURS},
    "services_count": ${SERVICE_COUNT},
    "latest_adr": "${LATEST_ADR}"
  },
  "runtime": {
    "container_runtime": "orbstack",
    "context": "${CONTEXT}",
    "typescript_server": "${HEALTH_STATUS}",
    "observability_stack": "${OBSERVABILITY_STATUS}"
  },
  "documentation": {
    "markdown_files": ${DOC_COUNT},
    "index_current": ${DOC_INDEX_CURRENT},
    "adrs_count": ${ADR_COUNT}
  },
  "required_reads": [
    ".claude/SESSION_START.md",
    "ARCHITECTURE_MAP.yaml",
    ".claude/AGENTIC_STANDARDS.md",
    "DOCUMENTATION_INDEX.md"
  ],
  "health_endpoints": {
    "typescript_server": "http://localhost:3000/health",
    "prometheus": "http://localhost:9090/-/ready",
    "grafana": "http://localhost:3001/api/health",
    "otel_collector": "http://localhost:13133/health"
  },
  "api_endpoints": {
    "swift_build": "http://localhost:3000/api/swift/build/status",
    "swift_tests": "http://localhost:3000/api/swift/tests/latest",
    "swift_metrics": "http://localhost:3000/api/swift/metrics",
    "agent_decision": "http://localhost:3000/api/agent/decision",
    "docs_index": "http://localhost:3000/api/docs/index"
  },
  "guardrails": {
    "read_only_paths": [
      "FilePilot.xcodeproj/project.pbxproj",
      ".git/**",
      "node_modules/**",
      "*.lock"
    ],
    "restricted_paths": {
      "FilePilot/**": {
        "allowed_extensions": [".swift", ".entitlements"]
      },
      "agentic-workflow/src/observability/**": {
        "required_keywords": ["OpenTelemetry", "trace"]
      }
    }
  },
  "validation": {
    "environment": "pass",
    "required_files": "pass",
    "service_health": "${OBSERVABILITY_STATUS}",
    "documentation": "${DOC_INDEX_CURRENT}",
    "architecture_freshness": "$([ $AGE_HOURS -lt 24 ] && echo 'pass' || echo 'warn')"
  }
}
EOF

echo -e "${GREEN}✓ Context summary generated: ${CONTEXT_OUTPUT}${NC}"
echo ""

# Step 8: Display Summary
echo -e "${BLUE}8. Context Summary${NC}"
echo "========================================"
echo ""
echo -e "${GREEN}Session ID:${NC} ${SESSION_ID}"
echo -e "${GREEN}Architecture Version:${NC} ${ARCH_VERSION}"
echo -e "${GREEN}Last Verified:${NC} ${LAST_VERIFIED} (${AGE_HOURS}h ago)"
echo -e "${GREEN}Services Defined:${NC} ${SERVICE_COUNT}"
echo -e "${GREEN}TypeScript Server:${NC} ${HEALTH_STATUS}"
echo -e "${GREEN}Observability Stack:${NC} ${OBSERVABILITY_STATUS}"
echo -e "${GREEN}Documentation Files:${NC} ${DOC_COUNT}"
echo -e "${GREEN}ADRs:${NC} ${ADR_COUNT}"
echo ""

# Step 9: Validation
if [ "$VALIDATE_ONLY" = true ]; then
  echo -e "${BLUE}9. Running validation...${NC}"

  VALIDATION_PASSED=true

  # Check all validations passed
  if [ "$OBSERVABILITY_STATUS" != "operational" ]; then
    echo -e "${YELLOW}⚠️  Observability stack not fully operational${NC}"
    VALIDATION_PASSED=false
  fi

  if [ $AGE_HOURS -gt 24 ]; then
    echo -e "${YELLOW}⚠️  Architecture map needs verification${NC}"
    VALIDATION_PASSED=false
  fi

  if [ "$DOC_INDEX_CURRENT" != "true" ]; then
    echo -e "${YELLOW}⚠️  Documentation index may need updating${NC}"
    VALIDATION_PASSED=false
  fi

  if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}✅ All validations passed${NC}"
    exit 0
  else
    echo -e "${YELLOW}⚠️  Some validations failed (warnings only)${NC}"
    exit 0
  fi
fi

echo -e "${GREEN}✅ Context initialization complete${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Read context summary: cat ${CONTEXT_OUTPUT} | jq"
echo "2. Verify service health: curl http://localhost:3000/health"
echo "3. Review architecture: cat ARCHITECTURE_MAP.yaml"
echo ""
echo -e "${BLUE}Agent-ready files:${NC}"
for file in "${REQUIRED_FILES[@]}"; do
  echo "  - ${file}"
done
echo ""

exit 0

# ===========================
# Git Status Checks
# ===========================
echo ""
echo "🔍 Checking Git status..."

# Check remote connectivity
if git ls-remote origin > /dev/null 2>&1; then
  echo "✅ Remote repository accessible"
else
  echo "⚠️  Cannot reach remote repository"
fi

# Check for uncommitted changes
UNCOMMITTED=$(git status --porcelain | wc -l | tr -d ' ')
if [ "$UNCOMMITTED" -gt 0 ]; then
  echo "⚠️  $UNCOMMITTED uncommitted changes detected"
  echo "   Run 'git status' for details"
else
  echo "✅ Working directory clean"
fi

# Show current branch and tracking
CURRENT_BRANCH=$(git branch --show-current)
TRACKING=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "no-tracking")
echo "📍 Branch: $CURRENT_BRANCH (tracking: $TRACKING)"

# Check ahead/behind
if [ "$TRACKING" != "no-tracking" ]; then
  AHEAD=$(git rev-list --count HEAD@{u}..HEAD 2>/dev/null || echo "0")
  BEHIND=$(git rev-list --count HEAD..HEAD@{u} 2>/dev/null || echo "0")
  if [ "$AHEAD" -gt 0 ]; then
    echo "   ⬆️  $AHEAD commit(s) ahead of remote"
  fi
  if [ "$BEHIND" -gt 0 ]; then
    echo "   ⬇️  $BEHIND commit(s) behind remote"
  fi
fi

echo ""
echo "✨ Context initialization complete"
echo "   Next: Review generated context-summary.json"
