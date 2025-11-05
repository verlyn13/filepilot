# Agentic Development Guide for FilePilot

**Unified Guide for AI-Assisted Development**
**Last Updated:** 2025-11-04
**Workflow Version:** modern-2025
**Status:** ✅ Complete and Operational

---

## 🎯 Purpose

This document is the **master guide** for AI agents (Claude Code, Codex CLI, etc.) working on the FilePilot project. It unifies all agentic development configurations, workflows, and standards into a single coherent resource.

---

## 📚 Quick Navigation

| Section | Purpose | When to Use |
|---------|---------|-------------|
| [Session Start](#-session-start-protocol) | Initialize development environment | **Every session start** |
| [Modern Workflow](#-modern-workflow-overview) | Understand project system | Before making changes |
| [Adding Files](#-adding-new-files) | Add Swift files to project | When creating files |
| [Building & Testing](#-building--testing) | Build and test the app | Before commits |
| [Observability](#-observability-integration) | Query system state | Before/after changes |
| [Decision Recording](#-recording-decisions) | Document architectural choices | After significant changes |
| [Troubleshooting](#-troubleshooting) | Resolve common issues | When problems occur |

---

## 🚀 Session Start Protocol

**CRITICAL:** Follow this every session start.

### Quick Start (30 seconds)

```bash
# 1. Check prerequisites
docker ps && command -v mise && command -v xcodegen

# 2. Initialize context
./scripts/context-init.sh

# 3. Sync Xcode project
mise project:sync

# 4. Start environment
mise dev

# 5. Verify health
mise agent:health
```

✅ **Status Check:** All commands succeed → Ready for development

### Detailed Steps

1. **Pre-Flight Checks**
   ```bash
   # OrbStack/Docker running?
   docker ps > /dev/null 2>&1 || echo "❌ Start OrbStack"

   # mise installed?
   command -v mise || echo "❌ brew install mise"

   # XcodeGen installed?
   command -v xcodegen || echo "❌ mise install xcodegen"
   ```

2. **Context Initialization**
   ```bash
   ./scripts/context-init.sh
   # Loads: ARCHITECTURE_MAP.yaml, project.yml, etc.
   ```

3. **Project Synchronization** (CRITICAL)
   ```bash
   mise project:sync
   # Regenerates FilePilot.xcodeproj from project.yml
   # Auto-discovers all Swift files
   ```

4. **Start Services**
   ```bash
   mise dev
   # Starts: TypeScript backend + 7 observability services
   ```

5. **Health Check**
   ```bash
   mise agent:health
   # Verifies: Docker, mise, services, build status
   ```

6. **Query Initial State**
   ```bash
   # Build status
   curl -s http://localhost:3000/api/swift/build/status | jq -r '.status'

   # Test coverage
   curl -s http://localhost:3000/api/swift/tests/latest | jq -r '.coverage'

   # Complexity
   curl -s http://localhost:3000/api/swift/metrics | jq -r '.complexity.average'
   ```

**Decision Tree:**
```
mise available? NO → Alert user, STOP
Docker running? NO → Alert user, STOP
Project synced? UNKNOWN → Run: mise project:sync
Services healthy? NO → Show logs, STOP
Build failing? YES → Prioritize fixes, PROCEED with caution
Coverage < 70%? YES → Suggest tests, PROCEED
Complexity > 8? YES → Recommend refactoring, PROCEED
All checks pass? → ✅ Full development mode
```

---

## 🏗️ Modern Workflow Overview

### Key Principle: Project as Code

The Xcode project file (`.xcodeproj`) is **generated**, not manually edited.

```
project.yml ───► XcodeGen ───► FilePilot.xcodeproj
(editable)      (tool)         (generated, gitignored)
```

### File Hierarchy

```
FilePilot/
├── project.yml              # ⭐ Single source of truth
├── .mise.toml               # Task automation
├── Makefile                 # Command shortcuts
├── FilePilot/               # Swift source files
│   ├── *.swift              # Auto-discovered by XcodeGen
│   ├── FavoritesManager.swift  # Example: automatically included
│   └── FilePilotTests/      # Tests auto-discovered
├── FilePilot.xcodeproj/     # GENERATED - DO NOT EDIT - DO NOT COMMIT
├── .claude/                 # Agent configuration
│   ├── SESSION_START.md     # Session protocol
│   ├── config.yaml          # Agent behaviors
│   └── AGENTIC_STANDARDS.md # Development standards
└── docs/
    ├── decisions/           # ADRs
    └── MODERN_SWIFT_WORKFLOW.md  # Detailed workflow guide
```

### What Changed (vs Old Workflow)

| Aspect | Old | New |
|--------|-----|-----|
| **Project File** | Manual `.pbxproj` editing | Auto-generated from `project.yml` |
| **Adding Files** | Drag into Xcode GUI | `touch file.swift && mise project:sync` |
| **Agent Autonomy** | ❌ Cannot add files | ✅ Full CLI automation |
| **Git Conflicts** | ❌ Frequent in `.pbxproj` | ✅ None (YAML is readable) |
| **Build Command** | `xcodebuild -project...` | `mise build` |
| **Health Check** | Multiple curl commands | `mise agent:health` |

---

## ➕ Adding New Files

### The Modern Way (2025)

```bash
# 1. Create your Swift file
touch FilePilot/NewFeature.swift

# 2. Write your code
# (edit FilePilot/NewFeature.swift)

# 3. Regenerate project
mise project:sync

# 4. Done! File is automatically in Xcode project
```

### What Happens Behind the Scenes

1. XcodeGen scans `FilePilot/` directory
2. Discovers all `*.swift` files
3. Adds them to `FilePilot` target
4. Generates updated `.xcodeproj`
5. Xcode sees the new file immediately

### For Tests

```bash
# Same process
touch FilePilot/FilePilotTests/NewFeatureTests.swift
mise project:sync
# Auto-added to FilePilotTests target
```

### Important Notes

- ✅ **DO** create `.swift` files anywhere in `FilePilot/`
- ✅ **DO** run `mise project:sync` after creating files
- ❌ **DON'T** manually edit `.xcodeproj` files
- ❌ **DON'T** commit `.xcodeproj` to git (it's gitignored)

---

## 🔨 Building & Testing

### Standard Commands

```bash
# Build (Debug)
mise build

# Build (Release)
mise build:release

# Clean build
mise build:clean

# Run tests
mise test

# Run with coverage
mise test:coverage

# Build and run app
mise run

# Full dev environment
mise dev
```

### Using Makefile Shortcuts

```bash
make build      # Same as: mise build
make test       # Same as: mise test
make run        # Same as: mise run
make clean      # Same as: mise build:clean
make help       # Show all commands
```

### Direct xcodebuild (If Needed)

```bash
# Still works, but prefer mise
xcodebuild -project FilePilot.xcodeproj -scheme FilePilot build
```

---

## 📊 Observability Integration

### Health Checks

```bash
# Quick health check
mise agent:health

# Individual service checks
curl http://localhost:3000/health              # TypeScript backend
curl http://localhost:9090/-/ready             # Prometheus
curl http://localhost:3001/api/health          # Grafana
curl http://localhost:16686                    # Jaeger
```

### Querying State

```bash
# Build status
BUILD_STATUS=$(curl -s http://localhost:3000/api/swift/build/status | jq -r '.status')
echo "Build: $BUILD_STATUS"

# Test results
curl -s http://localhost:3000/api/swift/tests/latest | jq

# Code metrics
curl -s http://localhost:3000/api/swift/metrics | jq

# Recent changes
curl -s http://localhost:3000/api/swift/files/changes | jq
```

### Service URLs

| Service | URL | Purpose |
|---------|-----|---------|
| TypeScript Backend | http://localhost:3000 | API & telemetry |
| Prometheus | http://localhost:9090 | Metrics storage |
| Grafana | http://localhost:3001 | Dashboards |
| Jaeger | http://localhost:16686 | Trace visualization |
| Loki | http://localhost:3100 | Log aggregation |
| AlertManager | http://localhost:9093 | Alerts |

---

## 📝 Recording Decisions

### When to Record

- Added/removed features
- Changed architecture
- Made significant refactorings
- Fixed critical bugs
- Updated dependencies

### How to Record

```bash
# Set context variables
export ACTION="feature_add"
export CONTEXT="Added FavoritesManager with persistence and UI"
export RESULT="success"

# Record decision
mise agent:record

# Or manually
curl -X POST http://localhost:3000/api/agent/decision \
  -H "Content-Type: application/json" \
  -H "x-trace-id: $(uuidgen)" \
  -d '{
    "agent": "claude-code-cli",
    "action": "'$ACTION'",
    "context": "'$CONTEXT'",
    "result": "'$RESULT'",
    "trace_id": "'$(uuidgen)'"
  }'
```

### Creating ADRs

For major architectural decisions:

```bash
# 1. Create ADR file
touch docs/decisions/NNNN-decision-title.md

# 2. Fill in using ADR template
# See: docs/decisions/0008-xcodegen-mise-modern-workflow.md

# 3. Update docs/decisions/README.md
# Add entry to Current ADRs table

# 4. Commit
git add docs/decisions/
git commit -m "docs: add ADR-NNNN for [decision]"
```

---

## 🚨 Troubleshooting

### "Cannot find 'ClassName' in scope"

**Cause:** File exists but not in Xcode project

**Solution:**
```bash
mise project:sync
mise build:clean
mise build
```

### "mise command not found"

**Solution:**
```bash
brew install mise
# or
curl https://mise.run | sh
```

### "xcodegen not found"

**Solution:**
```bash
mise install xcodegen
# or
brew install xcodegen
```

### "Docker not running"

**Solution:**
```bash
open -a OrbStack
sleep 15
docker ps
mise dev
```

### "Port 3000 already in use"

**Solution:**
```bash
lsof -i :3000
kill -9 <PID>
mise observability:start
```

### "Build failing after adding file"

**Solution:**
```bash
# 1. Ensure file is valid Swift
swift FilePilot/NewFile.swift -parse

# 2. Regenerate project
mise project:sync

# 3. Clean and rebuild
mise build:clean
mise build
```

### "Tests not running"

**Solution:**
```bash
# Check test file location
ls FilePilot/FilePilotTests/

# Regenerate project
mise project:sync

# Run tests
mise test
```

---

## 🔐 Guardrails & Rules

### DO NOT EDIT

- `FilePilot.xcodeproj/**` - Generated file
- `.git/**` - Git internals
- `node_modules/**` - Dependencies
- `**/*.lock` - Lock files
- `.build/**` - Build artifacts

### DO EDIT

- `project.yml` - Project configuration
- `.mise.toml` - Task automation
- `Makefile` - Command shortcuts
- `FilePilot/**/*.swift` - Swift source files
- `ARCHITECTURE_MAP.yaml` - Architecture docs

### Workflow Rules

1. **Always** run `mise project:sync` after adding/removing files
2. **Always** verify health before suggesting changes
3. **Always** record decisions with trace correlation
4. **Never** manually edit `.xcodeproj/project.pbxproj`
5. **Never** commit generated files

---

## 📖 Documentation Structure

### Primary Documents

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **This File** | Master agentic guide | Session start |
| [SESSION_START.md](./.claude/SESSION_START.md) | Detailed session protocol | Session start |
| [MODERN_SWIFT_WORKFLOW.md](./MODERN_SWIFT_WORKFLOW.md) | Complete workflow guide | Before changes |
| [ARCHITECTURE_MAP.yaml](./ARCHITECTURE_MAP.yaml) | Architectural truth | Understanding system |
| [config.yaml](./.claude/config.yaml) | Agent configuration | Understanding behaviors |

### Secondary Documents

| Document | Purpose |
|----------|---------|
| [project.yml](./project.yml) | Xcode project config |
| [.mise.toml](./.mise.toml) | Task automation config |
| [Makefile](./Makefile) | Command shortcuts |
| [ADR-0008](./docs/decisions/0008-xcodegen-mise-modern-workflow.md) | Workflow decision record |
| [DOCUMENTATION_INDEX.md](./DOCUMENTATION_INDEX.md) | All documentation navigation |

---

## 🎓 Best Practices

### For File Operations

```bash
# Good: Atomic file creation
touch FilePilot/NewFile.swift
# ... write content ...
mise project:sync

# Bad: Manual Xcode manipulation
open FilePilot.xcodeproj  # ❌ Avoid
```

### For Building

```bash
# Good: Use mise
mise build
mise test

# Acceptable: Direct xcodebuild if needed
xcodebuild -project FilePilot.xcodeproj -scheme FilePilot build
```

### For Commits

```bash
# Good: Commit source only
git add FilePilot/NewFile.swift
git add project.yml  # if modified
git commit -m "feat: add NewFile"

# Bad: Commit generated files
git add FilePilot.xcodeproj/  # ❌ This is gitignored anyway
```

### For Decisions

```bash
# Good: Record with trace correlation
export ACTION="refactor" CONTEXT="Simplified AppState" RESULT="success"
mise agent:record

# Good: Create ADR for major decisions
vim docs/decisions/NNNN-decision-title.md
```

---

## 🔄 Workflow Cycle

### Planning Phase

```bash
# 1. Query current state
mise agent:health

# 2. Check build status
curl -s http://localhost:3000/api/swift/build/status | jq

# 3. Review architecture
cat ARCHITECTURE_MAP.yaml

# 4. Plan changes
# (use TodoWrite tool to track tasks)
```

### Implementation Phase

```bash
# 1. Create files
touch FilePilot/NewFeature.swift

# 2. Sync project
mise project:sync

# 3. Implement
# (write code)

# 4. Build
mise build

# 5. Test
mise test
```

### Verification Phase

```bash
# 1. Run tests with coverage
mise test:coverage

# 2. Check metrics
curl -s http://localhost:3000/api/swift/metrics | jq

# 3. Verify build
mise build:release
```

### Documentation Phase

```bash
# 1. Record decision
mise agent:record

# 2. Update docs if needed
# (edit ARCHITECTURE_MAP.yaml, etc.)

# 3. Create ADR if major change
vim docs/decisions/NNNN-title.md
```

---

## 🌟 Quick Reference Card

### Most Common Commands

```bash
mise project:sync     # Sync Xcode project (after adding files)
mise build            # Build app
mise test             # Run tests
mise run              # Build and run
mise dev              # Start full environment
mise agent:health     # Check system health
mise agent:record     # Record decision
make help             # Show all commands
```

### Most Common Tasks

| Task | Command |
|------|---------|
| Add file | `touch file.swift && mise project:sync` |
| Build | `mise build` |
| Test | `mise test` |
| Run | `mise run` |
| Health check | `mise agent:health` |
| Start dev env | `mise dev` |
| Clean build | `mise build:clean` |

### Most Common Endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /health` | Overall health |
| `GET /api/swift/build/status` | Build status |
| `GET /api/swift/tests/latest` | Test results |
| `GET /api/swift/metrics` | Code metrics |
| `POST /api/agent/decision` | Record decision |

---

## ✅ Session Checklist

At session start, verify:

- [ ] OrbStack/Docker is running (`docker ps`)
- [ ] mise is available (`command -v mise`)
- [ ] XcodeGen is available (`command -v xcodegen`)
- [ ] Context initialized (`./scripts/context-init.sh`)
- [ ] Project synced (`mise project:sync`)
- [ ] Services started (`mise dev`)
- [ ] Health check passed (`mise agent:health`)
- [ ] Build status queried
- [ ] Test coverage checked
- [ ] Complexity verified

---

## 📞 Support & Resources

### Documentation

- **This Guide:** Complete agentic development reference
- **[MODERN_SWIFT_WORKFLOW.md](./MODERN_SWIFT_WORKFLOW.md):** Detailed workflow
- **[ADR-0008](./docs/decisions/0008-xcodegen-mise-modern-workflow.md):** Workflow decision record
- **[SESSION_START.md](./.claude/SESSION_START.md):** Session protocol

### Tools

- **mise:** https://mise.jdx.dev/
- **XcodeGen:** https://github.com/yonaskolb/XcodeGen
- **OrbStack:** https://orbstack.dev/

### Commands

```bash
make help           # Show all available commands
mise --help         # mise documentation
xcodegen --help     # XcodeGen documentation
```

---

## 🎯 Summary

**Key Takeaways:**

1. ✅ **Project is generated** from `project.yml`, not manually edited
2. ✅ **Always run** `mise project:sync` after adding files
3. ✅ **Use mise commands** for all operations
4. ✅ **Verify health** before making changes
5. ✅ **Record decisions** with trace correlation
6. ✅ **Never edit** `.xcodeproj` manually
7. ✅ **Follow session start** protocol every time

**Success Criteria:**

You're doing it right when:
- Files are added without opening Xcode GUI ✓
- Build succeeds on first try ✓
- Tests pass ✓
- All operations are recorded ✓
- No manual `.pbxproj` editing ✓

---

**Last Updated:** 2025-11-04
**Workflow Version:** modern-2025
**Status:** ✅ Active and Complete

This is the definitive guide for agentic development on FilePilot. Follow it, and autonomous development will work seamlessly.
