# 🚀 Session Start Protocol for AI Agents

**CRITICAL:** This protocol MUST be followed at the start of EVERY development session.

**Container Runtime:** OrbStack (permanent default context)
**Last Updated:** 2025-11-03
**Migration Status:** ✅ Complete - All 7 services operational

---

## ⚡ Quick Start Checklist

```bash
# 1. Verify OrbStack/Docker is running
docker ps > /dev/null 2>&1 || echo "❌ START ORBSTACK FIRST!"
# Note: OrbStack is now the default container runtime (10× faster than Docker Desktop)

# 2. Start development environment
./scripts/start-dev-environment.sh

# 3. Verify health
curl -f http://localhost:3000/health
```

If all succeed → ✅ Ready for development
If any fail → ❌ See troubleshooting below

---

## 📋 Detailed Steps

### Step 1: Pre-Flight Checks ✈️

```bash
# Check OrbStack/Docker
if ! docker ps > /dev/null 2>&1; then
  echo "❌ Container runtime not running"
  echo "Action Required: Start OrbStack (recommended) or Docker Desktop"
  echo "  macOS with OrbStack: open -a OrbStack"
  echo "  macOS with Docker Desktop: open -a Docker"
  echo "  Wait 10-30 seconds for runtime to fully start"
  exit 1
fi

# Verify we're using OrbStack for optimal performance
RUNTIME=$(docker info 2>/dev/null | grep -i "Operating System" | grep -i "OrbStack" && echo "OrbStack" || echo "Docker Desktop")
echo "✓ Container Runtime: $RUNTIME"
if [ "$RUNTIME" != "OrbStack" ]; then
  echo "⚠️  Consider switching to OrbStack for 10× better performance"
  echo "   See: ORBSTACK_MIGRATION_PLAN.md"
fi

# Check required commands
command -v bun >/dev/null 2>&1 || echo "⚠️  Bun not found (optional)"
command -v xcodebuild >/dev/null 2>&1 || echo "⚠️  Xcode not found (for Swift dev)"
```

### Step 2: Start Environment 🚀

```bash
cd /path/to/project/root
./scripts/start-dev-environment.sh
```

**This script:**
1. Validates all documentation
2. Starts Docker observability stack
3. Starts TypeScript server
4. Displays status URLs

**Expected Duration:** 30-60 seconds

### Step 3: Verify Health ❤️

```bash
# TypeScript server (CRITICAL)
curl -f http://localhost:3000/health | jq '.status'
# Must return: "healthy"

# Prometheus (CRITICAL)
curl -f http://localhost:9090/-/ready
# Must return: HTTP 200

# Grafana (Important)
curl -f http://localhost:3001/api/health
# Should return: {"database":"ok"}

# Jaeger (Important)
curl -f http://localhost:16686
# Should return: HTTP 200
```

### Step 4: Query Initial State 📊

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
```

### Step 5: Agent Decision Tree 🤖

```
BUILD_STATUS == "failed"?
  → Prioritize fixing build errors
  → DO NOT suggest new features until build passes

COVERAGE < 70%?
  → Suggest adding tests before new features
  → Focus on critical path coverage

COMPLEXITY > 8?
  → Recommend refactoring before adding complexity
  → Suggest breaking down large functions

All checks pass?
  → ✅ Ready for normal development
```

---

## 🚨 Common Issues

### Issue: Container runtime not running

**Symptom:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Solution:**
```bash
# macOS with OrbStack (recommended - 10× faster)
open -a OrbStack

# Wait for OrbStack to start (10-20 seconds)
sleep 15

# Verify context
docker context ls  # Should show "orbstack *"

# Verify running
docker ps

# Retry startup
./scripts/start-dev-environment.sh
```

**Note:** OrbStack is now the default runtime for this project. Context is set to `orbstack` permanently.
All Docker commands automatically use OrbStack. See `.backups/orbstack-validation-complete-2025-11-03.md` for migration details.

### Issue: Port 3000 already in use

**Symptom:**
```
Error: listen EADDRINUSE: address already in use :::3000
```

**Solution:**
```bash
# Find the process
lsof -i :3000

# Kill it
kill -9 <PID>

# Retry startup
./scripts/start-dev-environment.sh
```

### Issue: npm install needed

**Symptom:**
```
Cannot find module 'express'
```

**Solution:**
```bash
cd agentic-workflow
bun install  # or npm install
cd ..
./scripts/start-dev-environment.sh
```

---

## 🎯 Agent Behavior Matrix

| Scenario | Agent Action |
|----------|-------------|
| Docker not running | Alert user, provide start command, STOP |
| Services not healthy | Show failed service, provide logs command, STOP |
| Build failing | Query error details, suggest fixes, PROCEED with caution |
| Tests failing | Review failures, suggest fixes, PROCEED |
| Coverage < 70% | Suggest test additions, PROCEED |
| Complexity > 8 | Recommend refactoring, PROCEED |
| All systems green | ✅ Full development mode |

---

## 📚 Read Before Coding

1. **This File** - Session start protocol
2. **STARTUP_GUIDE.md** - Detailed startup documentation
3. **OBSERVABILITY.md** - How to query the system
4. **DOCUMENTATION_INDEX.md** - Where everything is
5. **config.yaml** - Your agent behaviors

---

## ✅ Session Start Complete

Once you've completed all steps and verified health:

```markdown
✅ Development Environment Status:
- Docker: Running
- TypeScript Server: http://localhost:3000 (healthy)
- Prometheus: http://localhost:9090 (ready)
- Grafana: http://localhost:3001 (ok)
- Jaeger: http://localhost:16686 (ok)

📊 Initial Metrics:
- Build Status: success
- Test Coverage: 82%
- Code Complexity: 4.2

🎯 Ready for Development!
```

**You may now proceed with code review, suggestions, and development.**

---

**REMEMBER:** If environment is not started and healthy, **DO NOT** suggest code changes. Always verify observability first.
