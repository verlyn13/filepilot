# 🚀 Session Start Protocol for AI Agents

**CRITICAL:** This protocol MUST be followed at the start of EVERY development session.

**Container Runtime:** OrbStack (permanent default context)
**Project System:** XcodeGen + mise (November 2025 workflow)
**Last Updated:** 2025-11-04
**Migration Status:** ✅ Complete - Modern workflow operational

---

## ⚡ Quick Start Checklist (Updated for Modern Workflow)

```bash
# 1. Verify OrbStack/Docker is running
docker ps > /dev/null 2>&1 || echo "❌ START ORBSTACK FIRST!"

# 2. Ensure mise is available
command -v mise || echo "❌ Install mise first"

# 3. Sync Xcode project (if needed)
mise project:sync

# 4. Start development environment
mise dev

# 5. Verify health
mise agent:health
```

If all succeed → ✅ Ready for development
If any fail → ❌ See troubleshooting below

---

## 📋 Detailed Session Start Steps

### Step 1: Pre-Flight Checks ✈️

```bash
# Check OrbStack/Docker
if ! docker ps > /dev/null 2>&1; then
  echo "❌ Container runtime not running"
  echo "Action Required: Start OrbStack (recommended)"
  echo "  macOS: open -a OrbStack"
  echo "  Wait 10-30 seconds for runtime to fully start"
  exit 1
fi

# Check mise installation
if ! command -v mise &> /dev/null; then
  echo "❌ mise not found"
  echo "Install: brew install mise"
  exit 1
fi

# Check XcodeGen installation
if ! command -v xcodegen &> /dev/null; then
  echo "⚠️  XcodeGen not found"
  echo "Install: mise install  # or brew install xcodegen"
fi

# Check required tools
command -v bun >/dev/null 2>&1 || echo "⚠️  Bun not found (optional)"
command -v xcodebuild >/dev/null 2>&1 || echo "⚠️  Xcode not found (for Swift dev)"
```

### Step 2: Initialize Context 🧠

**IMPORTANT:** This loads architectural context from configuration files.

```bash
# Initialize project context (reads ARCHITECTURE_MAP.yaml, etc.)
./scripts/context-init.sh

# Verify context was loaded
[ -f .claude/context-summary.json ] && echo "✓ Context loaded" || echo "❌ Context init failed"
```

### Step 3: Sync Xcode Project 🔄

**CRITICAL FOR MODERN WORKFLOW:** Regenerate Xcode project from project.yml

```bash
# Regenerate Xcode project (auto-discovers all .swift files)
mise project:sync

# This ensures:
# - All Swift files are in the project
# - FavoritesManager.swift is included
# - Tests are properly configured
# - No manual .pbxproj editing needed
```

**When to run:**
- After git pull
- After creating new .swift files
- After modifying project structure
- At session start (to ensure sync)

### Step 4: Start Environment 🚀

```bash
# Option A: Full development environment (observability + app)
mise dev

# Option B: Just start observability stack
mise observability:start

# Option C: Manual start (traditional)
./scripts/start-dev-environment.sh
```

**Services Started:**
1. TypeScript observability backend (port 3000)
2. Prometheus (port 9090)
3. Grafana (port 3001)
4. Jaeger (port 16686)
5. Loki (port 3100)
6. AlertManager (port 9093)
7. OTEL Collector (port 4317)

**Expected Duration:** 30-60 seconds

### Step 5: Verify Health ❤️

```bash
# Quick health check (all services)
mise agent:health

# Individual service checks
curl -sf http://localhost:3000/health | jq '.status'        # TypeScript backend
curl -sf http://localhost:9090/-/ready                       # Prometheus
curl -sf http://localhost:3001/api/health | jq              # Grafana
curl -sf http://localhost:16686 > /dev/null && echo "OK"    # Jaeger
```

### Step 6: Query Initial State 📊

```bash
# Build status
BUILD_STATUS=$(curl -s http://localhost:3000/api/swift/build/status | jq -r '.status')
echo "Build Status: $BUILD_STATUS"

# Test coverage
COVERAGE=$(curl -s http://localhost:3000/api/swift/tests/latest | jq -r '.coverage')
echo "Test Coverage: $COVERAGE%"

# Code complexity
COMPLEXITY=$(curl -s http://localhost:3000/api/swift/metrics | jq -r '.complexity.average')
echo "Average Complexity: $COMPLEXITY"

# Knowledge graph
curl -s http://localhost:3000/api/docs/index | jq '.metadata'
```

### Step 7: Record Session Start 📝

```bash
# Record that agent session has started
curl -X POST http://localhost:3000/api/agent/session-start \
  -H "Content-Type: application/json" \
  -d '{
    "agent": "claude-code-cli",
    "session_id": "'$(date +%Y%m%d-%H%M%S)'",
    "context_summary": "FilePilot development session",
    "workflow_version": "modern-2025"
  }'
```

---

## 🤖 Agent Decision Tree

```
mise available?
  NO → Alert user, request mise installation
  YES → Continue

OrbStack/Docker running?
  NO → Alert user, provide start command, STOP
  YES → Continue

Xcode project in sync?
  UNKNOWN → Run: mise project:sync
  YES → Continue

Services healthy?
  NO → Show failed service, provide logs command, STOP
  YES → Continue

BUILD_STATUS == "failed"?
  YES → Prioritize fixing build errors, DO NOT suggest new features
  NO → Continue

COVERAGE < 70%?
  YES → Suggest adding tests before new features
  NO → Continue

COMPLEXITY > 8?
  YES → Recommend refactoring before adding complexity
  NO → Continue

All checks pass?
  → ✅ Full development mode enabled
```

---

## 🔧 Modern Workflow Commands

### For Adding New Files

```bash
# 1. Create Swift file
touch FilePilot/NewFeature.swift

# 2. Regenerate project (auto-includes file)
mise project:sync

# 3. Done! File is now in Xcode project
```

**No manual Xcode manipulation needed!**

### For Building & Testing

```bash
# Build app
mise build

# Run tests
mise test

# Run with coverage
mise test:coverage

# Build and run
mise run
```

### For Development

```bash
# Full dev environment
mise dev

# Just observability
mise observability:start

# Health check
mise agent:health

# Record decision
export ACTION="code_change" CONTEXT="Added feature X"
mise agent:record
```

---

## 🚨 Common Issues (Updated)

### Issue: mise not found

**Solution:**
```bash
brew install mise
# or
curl https://mise.run | sh
```

### Issue: XcodeGen not found

**Solution:**
```bash
mise install xcodegen
# or
brew install xcodegen
```

### Issue: "Cannot find 'ClassName' in scope"

**Cause:** File exists but not in Xcode project

**Solution:**
```bash
# Regenerate project to auto-discover all files
mise project:sync

# Clean and rebuild (mise project:sync already does this)
mise build
```

### Issue: App builds but window doesn't appear ⚠️ CRITICAL

**Symptoms:**
- `** BUILD SUCCEEDED **` message
- App process launches (visible in Activity Monitor)
- No window appears, app seems frozen
- No crash logs generated

**Root Cause:** Stale build cache in `DerivedData/` after project regeneration. Xcode's incremental build reused old object files that don't match the new project structure.

**Why This Happens:** When `xcodegen generate` creates a new `.xcodeproj`, the existing compiled Swift modules, object files, and linkage info in `~/Library/Developer/Xcode/DerivedData/FilePilot-*/` are based on the OLD project structure. Xcode doesn't detect this mismatch.

**Solution:**
```bash
# The CORRECT way (automatic clean):
mise project:sync  # Already includes clean build!

# Manual fix if needed:
xcodebuild clean
rm -rf ~/Library/Developer/Xcode/DerivedData/FilePilot-*
mise build
```

**Prevention:** Our `mise project:sync` task **automatically cleans build artifacts** after regeneration. You don't need to do anything extra.

**For AI Agents:** NEVER run `xcodegen generate` directly. ALWAYS use `mise project:sync` which handles the clean build requirement automatically.

**Lesson Learned (2025-11-04):** This exact issue occurred during Favorites feature implementation. See `MODERN_SWIFT_WORKFLOW.md` section "Critical: Clean Builds After Project Regeneration" for full details.

### Issue: Container runtime not running

**Solution:**
```bash
# Start OrbStack
open -a OrbStack

# Wait for startup
sleep 15

# Verify
docker ps

# Restart environment
mise dev
```

### Issue: Port 3000 already in use

**Solution:**
```bash
# Find and kill process
lsof -i :3000
kill -9 <PID>

# Restart
mise observability:start
```

### Issue: Project out of sync

**Symptoms:** Files in Xcode but not building

**Solution:**
```bash
mise build:clean
mise project:sync
mise build
```

---

## 📚 Required Reading (In Order)

**Session Start:**
1. **This File** - Session start protocol ✓
2. **MODERN_SWIFT_WORKFLOW.md** - New workflow guide
3. **ARCHITECTURE_MAP.yaml** - Architectural truth source
4. **AGENTIC_STANDARDS.md** - Agent workflows

**Before Making Changes:**
5. **project.yml** - Project configuration (if modifying structure)
6. **.mise.toml** - Available commands
7. **DOCUMENTATION_INDEX.md** - Navigation hub

---

## 🎯 Agent Behavior Matrix (Updated)

| Scenario | Agent Action |
|----------|-------------|
| mise not available | Alert user, provide install command, STOP |
| Docker not running | Alert user, provide start command, STOP |
| Project not synced | Run `mise project:sync`, verify success |
| Services not healthy | Show failed service, provide logs, STOP |
| Build failing | Query error details, suggest fixes, PROCEED with caution |
| Tests failing | Review failures, suggest fixes, PROCEED |
| Coverage < 70% | Suggest test additions, PROCEED |
| Complexity > 8 | Recommend refactoring, PROCEED |
| All systems green | ✅ Full development mode |

---

## ✅ Session Start Complete Checklist

Once you've completed all steps:

```markdown
✅ Pre-Flight Checks:
- [x] OrbStack/Docker running
- [x] mise installed and functional
- [x] XcodeGen available

✅ Context Initialization:
- [x] ./scripts/context-init.sh executed
- [x] .claude/context-summary.json exists
- [x] ARCHITECTURE_MAP.yaml read

✅ Project Synchronization:
- [x] mise project:sync completed
- [x] FilePilot.xcodeproj generated
- [x] All Swift files auto-discovered

✅ Environment Status:
- [x] TypeScript Server: http://localhost:3000 (healthy)
- [x] Prometheus: http://localhost:9090 (ready)
- [x] Grafana: http://localhost:3001 (ok)
- [x] Jaeger: http://localhost:16686 (ok)

✅ Initial Metrics:
- Build Status: success
- Test Coverage: ≥70%
- Code Complexity: <8

✅ Session Recorded:
- POST /api/agent/session-start completed
- Trace ID generated

🎯 Status: Ready for Development!
```

---

## 📖 Key Differences from Old Workflow

### Old Workflow (❌ Deprecated)
- Manual `.pbxproj` editing via Xcode GUI
- Files had to be dragged into Xcode
- Merge conflicts in project file
- Agents couldn't add files via CLI

### New Workflow (✅ Current)
- `project.yml` is single source of truth
- Files auto-discovered by XcodeGen
- No merge conflicts
- Full CLI automation via mise
- Agents can add files programmatically

### Commands Comparison

| Task | Old | New |
|------|-----|-----|
| Add file | Manual in Xcode | `touch file.swift && mise project:sync` |
| Build | `xcodebuild ...` | `mise build` |
| Test | `xcodebuild test ...` | `mise test` |
| Health | Multiple curl commands | `mise agent:health` |
| Start dev | `./scripts/start-dev-environment.sh` | `mise dev` |

---

## 🔍 Quick Reference Card

**Most Important Commands:**
```bash
mise project:sync     # Sync Xcode project
mise dev              # Start everything
mise agent:health     # Check environment
mise build            # Build app
mise test             # Run tests
mise agent:record     # Record decision
make help             # Show all commands
```

**Files to Know:**
- `project.yml` - Project configuration
- `.mise.toml` - Task automation
- `Makefile` - Command shortcuts
- `MODERN_SWIFT_WORKFLOW.md` - Workflow guide

---

**REMEMBER:**
1. **Always** run `mise project:sync` after adding/removing Swift files
2. **Always** verify environment health before suggesting changes
3. **Always** record architectural decisions with trace correlation
4. **Never** manually edit `.xcodeproj/project.pbxproj`

---

**Last Updated:** 2025-11-04
**Workflow Version:** modern-2025
**Container Runtime:** OrbStack
**Project System:** XcodeGen + mise
