# Scripts Directory - Automation & Development Tools

**Last Updated:** 2025-11-03
**Purpose:** Central repository for all project automation scripts
**For:** AI Agents & Human Developers

---

## 🎯 Quick Reference

| Script | Purpose | Usage | Agent-Safe |
|--------|---------|-------|------------|
| `context-init.sh` | Load architectural context at session start | `./scripts/context-init.sh` | ✅ Yes (Required) |
| `start-dev-environment.sh` | Start complete dev environment | `./scripts/start-dev-environment.sh` | ✅ Yes |
| `validate-docs.sh` | Validate documentation integrity | `./scripts/validate-docs.sh` | ✅ Yes |

---

## 📜 Script Details

### context-init.sh

**Purpose:** Load architectural context for AI agent sessions
**Required:** ✅ **MUST RUN AT SESSION START**
**Generates:** `.claude/context-summary.json`

**What It Does:**
1. Verifies environment (OrbStack running, Docker context correct)
2. Checks service health (TypeScript server, observability stack)
3. Reads required architectural files (ARCHITECTURE_MAP.yaml, ADRs, etc.)
4. Extracts context data (architecture version, service count, freshness)
5. Queries service status endpoints
6. Generates structured context summary JSON
7. Validates architecture freshness (warns if >24h old)

**Usage:**
```bash
# Normal mode - Generate context summary
./scripts/context-init.sh

# Validation mode - Check system health without output
./scripts/context-init.sh --validate
```

**Generated Output:**
- `.claude/context-summary.json` - Structured project context including:
  - Project metadata (name, root, type)
  - Architecture state (version, last_verified, services_count)
  - Runtime status (container runtime, service health)
  - Documentation index (markdown files, ADRs)
  - API endpoints (health, swift, agent, docs)
  - Guardrails (read-only paths, restricted paths)

**Environment Variables:**
- None (auto-detects all configuration)

**Exit Codes:**
- `0` - Success (context loaded)
- `1` - Validation failed (missing required files)
- `2` - Environment error (OrbStack not running, Docker context wrong)

**Health Checks:**
- OrbStack/Docker running: `docker ps`
- Docker context: Must be `orbstack`
- TypeScript server: http://localhost:3000/health
- Observability stack: Prometheus, Grafana, OTEL Collector health endpoints

**Agent Notes:**
- **CRITICAL:** Run this at the start of EVERY session
- Provides architectural context without reading multiple files
- Validates system health before starting work
- Warns if architecture map is stale (>24h old)
- Generated context summary is read-only (managed by script)

**Required Files:**
- `.claude/SESSION_START.md`
- `ARCHITECTURE_MAP.yaml`
- `.claude/AGENTIC_STANDARDS.md`
- `DOCUMENTATION_INDEX.md`
- `START_HERE.md`

**Dependencies:**
- `yq` (optional, for YAML parsing - uses grep fallback if not available)
- `jq` (optional, for JSON formatting)
- `curl` (for health checks)

---

### start-dev-environment.sh

**Purpose:** Comprehensive development environment startup
**Runtime Detection:** Auto-detects OrbStack or Docker Desktop
**Services Started:**
- Observability stack (Prometheus, Grafana, Jaeger, AlertManager, Promtail)
- TypeScript monitoring server
- Documentation validation

**Usage:**
```bash
./scripts/start-dev-environment.sh
```

**Environment Variables:**
- `COMPOSE_CMD` - Override compose command (default: `docker compose`)

**Exit Codes:**
- `0` - Success
- `1` - Failure (runtime not detected, validation failed, or services failed)

**Health Checks:**
- Prometheus: http://localhost:9090/-/ready
- Grafana: http://localhost:3001/api/health
- Jaeger: http://localhost:16686
- TypeScript Server: http://localhost:3000/health

**Stop Script:**
Generated at `/tmp/stop-dev-env.sh` during execution

**Agent Notes:**
- Always run this before suggesting code changes
- Wait for all health checks to pass
- Check TypeScript server is healthy before querying APIs

---

### validate-docs.sh

**Purpose:** Validate documentation structure and cross-references
**Validation Checks:**
- File existence for all referenced documents
- Cross-reference integrity
- Documentation index consistency
- Schema validation (if schemas present)

**Usage:**
```bash
./scripts/validate-docs.sh
```

**Exit Codes:**
- `0` - All validations passed
- `1` - Validation failures detected

**Agent Notes:**
- Run before committing documentation changes
- Use to verify documentation integrity in pre-commit hooks
- Helps maintain single source of truth

---

## 🤖 Agent Discovery & Usage

### When to Use Scripts

**Agent Session Start (REQUIRED):**
1. `context-init.sh` - **ALWAYS RUN FIRST** - Load architectural context
2. Read generated `.claude/context-summary.json`
3. Query `/api/docs/index` for knowledge graph (if server running)

**Startup Workflow:**
1. `context-init.sh` - Load context and verify environment
2. `start-dev-environment.sh` - Start development services (if not already running)
3. `validate-docs.sh` - Verify documentation state

**Before Code Changes:**
- Run `start-dev-environment.sh` to ensure services are running
- Query health endpoints to verify system state

**Before Commits:**
- Run `validate-docs.sh` to ensure documentation integrity

### Script Discovery Pattern

Agents should:
1. **ALWAYS** run `context-init.sh` at session start (non-negotiable)
2. Check `scripts/README.md` for available automation
3. Use scripts instead of manual commands when available
4. Verify script exit codes before proceeding
5. Parse script output for health check results
6. Use generated context summary instead of reading multiple files

### Context Summary Usage

After running `context-init.sh`, agents can access:

```bash
# View complete context
cat .claude/context-summary.json | jq

# Check specific values
jq '.architecture.version' .claude/context-summary.json
jq '.runtime.typescript_server' .claude/context-summary.json
jq '.documentation.markdown_files' .claude/context-summary.json
```

**Key Context Fields:**
- `architecture.last_verified` - When architecture was last updated
- `architecture.age_hours` - How old the architecture map is
- `runtime.typescript_server` - Server health status
- `runtime.observability_stack` - Observability services status
- `documentation.markdown_files` - Total docs count
- `api_endpoints.*` - All available API endpoints
- `guardrails.*` - Read-only and restricted paths

---

## 📋 Script Standards

All scripts in this directory follow these conventions:

**Shebang:** `#!/usr/bin/env bash`
**Error Handling:** `set -euo pipefail`
**Color Coding:**
- 🔵 Blue - Informational
- 🟢 Green - Success
- 🟡 Yellow - Warning
- 🔴 Red - Error

**Documentation:**
- Header comment with purpose
- Usage instructions in comments
- Agent-safe indicators

**Naming:**
- Kebab-case with `.sh` extension
- Descriptive, action-oriented names
- No version numbers in filenames

---

## 🔗 Related Documentation

- **Main Index:** `../DOCUMENTATION_INDEX.md`
- **Observability Guide:** `../agentic-workflow/docs/OBSERVABILITY.md`
- **Development Principles:** `../agentic-workflow/docs/DEVELOPMENT_PRINCIPLES.md`
- **Container Runtime:** `../ORBSTACK_MIGRATION_PLAN.md`

---

## 🆕 Adding New Scripts

When adding new scripts:

1. **Update this README** with script details in the table and details section
2. **Follow naming conventions** (kebab-case, descriptive)
3. **Add header documentation** (purpose, usage, exit codes)
4. **Mark agent-safety** (can agents run this without supervision?)
5. **Cross-reference** in DOCUMENTATION_INDEX.md if it's a major workflow script

---

**Maintained by:** Agentic Development Team
**Index:** Part of DOCUMENTATION_INDEX.md automation section
