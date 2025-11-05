# Modern Swift Development Workflow (November 2025)

**Last Updated:** 2025-11-04
**Status:** ✅ Implemented
**Approach:** XcodeGen + mise + agentic automation

---

## 🎯 Core Philosophy

**Project as Code:** The Xcode project file (`.xcodeproj`) is now **generated** from `project.yml`, not manually edited. This enables:

- ✅ **CLI-driven development** - agents can add files without touching `.pbxproj`
- ✅ **Reproducible builds** - anyone can regenerate the exact same project
- ✅ **No merge conflicts** - `project.yml` is human-readable YAML
- ✅ **Automated workflows** - mise tasks handle common operations

---

## 📁 Project Structure

```
FilePilot/
├── project.yml                 # ⭐ Single source of truth for project
├── .mise.toml                  # Task automation & tool management
├── Makefile                    # Shortcut commands
├── .gitignore                  # Excludes generated .xcodeproj
├── FilePilot/                  # Source code
│   ├── *.swift                 # All Swift files automatically included
│   ├── FilePilotTests/         # Unit tests
│   └── FilePilotUITests/       # UI tests
├── FilePilot.xcodeproj/        # 🚫 GENERATED - DO NOT EDIT - DO NOT COMMIT
└── agentic-workflow/           # TypeScript observability backend
```

---

## 🚀 Quick Start

### First Time Setup

```bash
# Install XcodeGen
brew install xcodegen

# Or use mise
mise install

# Generate Xcode project
mise project:sync
# or
make project

# Open in Xcode
open FilePilot.xcodeproj
```

### Daily Development

```bash
# Start full dev environment (observability + app)
mise dev
# or
make dev

# Just regenerate project
mise project:sync
# or
make project

# Build from CLI
mise build
# or
make build

# Run tests
mise test
# or
make test
```

---

## 🔧 Adding New Files

### The Old Way (Manual - ❌ DON'T DO THIS)
1. Create `NewFile.swift`
2. Open Xcode
3. Drag file into project
4. Check target membership
5. Commit `.pbxproj` changes

### The Modern Way (Automated - ✅ DO THIS)

```bash
# 1. Create your Swift file
touch FilePilot/FavoritesManager.swift

# 2. Regenerate project (automatic file discovery)
mise project:sync

# 3. Done! File is now in Xcode project
```

**That's it!** XcodeGen automatically discovers all `.swift` files in `FilePilot/` and adds them to the target.

---

## ⚠️ Critical: Clean Builds After Project Regeneration

### Why Clean Builds Are Required

**Problem:** When `xcodegen generate` creates a new `.xcodeproj` file, Xcode's incremental build system may reuse **stale build artifacts** from the old project structure in `DerivedData/`. This causes:

- ✗ App builds successfully but **window doesn't appear**
- ✗ Runtime initialization failures (silent crashes)
- ✗ Missing symbols or type mismatches
- ✗ Confusing "build succeeded but app broken" symptoms

**Root Cause:** Xcode's build cache doesn't detect project file regeneration as a reason to invalidate cached object files, Swift modules, and linkage information.

**Solution:** Our `mise project:sync` task **automatically cleans build artifacts** after regeneration.

### Automatic Protection (Built-in)

```bash
mise project:sync
# Internally runs:
# 1. xcodegen generate
# 2. xcodebuild clean
# 3. rm -rf ~/Library/Developer/Xcode/DerivedData/FilePilot-*
```

**You don't need to do anything extra** - the workflow is automated. But understanding why is crucial for agents and developers.

### Manual Clean Build (If Needed)

If you manually run `xcodegen generate` instead of `mise project:sync`:

```bash
# Wrong - will have stale cache:
xcodegen generate
xcodebuild build  # ❌ May fail silently

# Correct - clean then build:
xcodegen generate
xcodebuild clean  # ✅ Remove stale cache
xcodebuild build  # ✅ Fresh build
```

### Lesson Learned (2025-11-04)

During implementation of the Favorites feature, we encountered this exact issue:
- `xcodegen generate` succeeded
- `xcodebuild build` succeeded
- App launched but window was invisible
- **Fix:** `xcodebuild clean` then rebuild
- **Prevention:** Updated `mise project:sync` to always clean

**For AI Agents:** After running `xcodegen generate`, ALWAYS perform a clean build. Our mise task does this automatically.

---

## 📋 Available Commands

### Via mise

| Command | Description |
|---------|-------------|
| `mise project:sync` | Regenerate Xcode project from project.yml |
| `mise project:validate` | Validate project.yml without generating |
| `mise build` | Build app (Debug) |
| `mise build:release` | Build app (Release) |
| `mise build:clean` | Clean build artifacts |
| `mise test` | Run unit + UI tests |
| `mise test:coverage` | Run tests with coverage report |
| `mise run` | Build and launch app |
| `mise dev` | Start full dev environment |
| `mise agent:health` | Check environment health |
| `mise observability:start` | Start observability stack |
| `mise observability:stop` | Stop observability stack |

### Via Make (shortcuts)

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make project` | Regenerate Xcode project |
| `make build` | Build app |
| `make test` | Run tests |
| `make run` | Build and run app |
| `make dev` | Start full dev environment |
| `make clean` | Clean build artifacts |
| `make health` | Check environment health |

---

## 🤖 Agent Workflow Integration

### For AI Agents (Claude Code, Codex CLI)

**Session Start Protocol (Updated):**

```bash
# 1. Load context
./scripts/context-init.sh

# 2. Check environment
mise agent:health

# 3. Ensure project is up-to-date
mise project:sync

# 4. Query observability
curl -s http://localhost:3000/api/swift/build/status | jq
```

**Adding New Files:**

```python
# Agent creates file
create_file("FilePilot/NewFeature.swift", content)

# Agent regenerates project
run_command("mise project:sync")

# Done! No manual Xcode manipulation needed
```

**Recording Decisions:**

```bash
# Agent records architectural decision
export ACTION="feature_implementation"
export CONTEXT="Added NewFeature with telemetry"
export RESULT="success"
mise agent:record
```

---

## 📝 Project Configuration (project.yml)

### Basic Structure

```yaml
name: FilePilot

options:
  bundleIdPrefix: com.jefahnierocks
  deploymentTarget:
    macOS: "14.0"

targets:
  FilePilot:
    type: application
    platform: macOS
    sources:
      - path: FilePilot
        excludes:
          - "FilePilot/**"  # Nested folder
          - "*.bak"
          - ".build"
```

### Auto-Discovery

XcodeGen automatically:
- ✅ Finds all `.swift` files in specified paths
- ✅ Creates proper groups matching folder structure
- ✅ Assigns files to correct targets
- ✅ Links test targets to app target

### Manual Override (if needed)

```yaml
targets:
  FilePilot:
    sources:
      - path: FilePilot/SpecialFile.swift
        buildPhase: sources  # Explicit control
```

---

## 🔄 Git Workflow

### What to Commit

✅ **DO COMMIT:**
- `project.yml` - Project configuration
- `.mise.toml` - Task automation
- `Makefile` - Command shortcuts
- All `.swift` source files
- Tests

❌ **DO NOT COMMIT:**
- `FilePilot.xcodeproj/` - Generated file
- `.build/` - Build artifacts
- `DerivedData/` - Xcode derived data
- `*.bak` - Backup files

### Workflow

```bash
# 1. Add new file
touch FilePilot/NewFile.swift

# 2. Regenerate project
mise project:sync

# 3. Commit source only
git add FilePilot/NewFile.swift
git add project.yml  # if you modified it
git commit -m "feat: add NewFile feature"

# .xcodeproj is gitignored, so it won't be staged
```

### After Pulling Changes

```bash
git pull
mise hooks:post-pull  # Automatically runs project:sync
```

---

## 🧪 Testing

### Run Tests

```bash
# All tests
mise test

# With coverage
mise test:coverage

# Specific test
xcodebuild test -only-testing:FilePilotTests/FavoritesManagerTests
```

### Test Structure

```
FilePilot/FilePilotTests/
├── FavoritesManagerTests.swift   # Auto-discovered
├── AppStateTests.swift
└── ...
```

XcodeGen automatically adds all test files to the `FilePilotTests` target.

---

## 🔍 Troubleshooting

### "Cannot find 'FavoritesManager' in scope"

**Cause:** File exists but not in Xcode project

**Fix:**
```bash
mise project:sync
```

### "Project.yml validation failed"

**Cause:** Syntax error in project.yml

**Fix:**
```bash
mise project:validate  # Shows validation errors
```

### "XcodeGen not found"

**Fix:**
```bash
brew install xcodegen
# or
mise install xcodegen
```

### Project out of sync

**Symptoms:** Files in Xcode but not building

**Fix:**
```bash
mise build:clean
mise project:sync
mise build
```

---

## 📊 Observability Integration

All commands maintain full observability:

```bash
# Health check before development
mise agent:health

# Record decisions with trace correlation
export ACTION="code_change" CONTEXT="Added feature X"
mise agent:record

# View telemetry
curl -s http://localhost:3000/api/agent/stats | jq
```

---

## 🎓 Benefits of This Approach

### For Humans

- ✅ No merge conflicts in `.pbxproj`
- ✅ Easier code review (YAML vs binary-ish format)
- ✅ Faster onboarding (one command to setup)
- ✅ Consistent project structure across team

### For Agents

- ✅ Can add files via CLI without Xcode
- ✅ Declarative configuration is parseable
- ✅ Automated workflows reduce complexity
- ✅ Full observability of operations

### For Projects

- ✅ Reproducible builds
- ✅ Version-controlled configuration
- ✅ Easy to update build settings
- ✅ Simplified CI/CD integration

---

## 🔗 Related Documentation

- [ARCHITECTURE_MAP.yaml](./ARCHITECTURE_MAP.yaml) - System architecture
- [.claude/AGENTIC_STANDARDS.md](./.claude/AGENTIC_STANDARDS.md) - Agent workflows
- [DOCUMENTATION_INDEX.md](./DOCUMENTATION_INDEX.md) - All documentation
- [agentic-workflow/README.md](./agentic-workflow/README.md) - Observability setup

---

## 📞 Support

**Issues with project generation:**
```bash
mise project:validate
```

**Issues with build:**
```bash
mise build:clean
mise project:sync
mise build
```

**Need help:**
```bash
make help
mise --help
```

---

**Last Updated:** 2025-11-04
**Maintained By:** Agentic Development Team
**XcodeGen Version:** latest
**mise Version:** 2025.10.21+
