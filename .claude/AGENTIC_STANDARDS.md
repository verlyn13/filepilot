# Agentic Programming Standards - Agent Discovery & Workflows

**For:** AI Agents (Claude Code CLI, Codex CLI)
**Purpose:** Define how agents discover information and operate in this project
**Last Updated:** 2025-11-03

---

## 🎯 Core Principle: Information Discovery

Agents working in this project must discover information through **structured documentation pathways**, not through random file exploration or assumptions.

---

## 📚 Agent Discovery Hierarchy

### Level 0: Context Initialization (CRITICAL - RUN FIRST)
**When:** Beginning of EVERY development session (BEFORE reading files)
**Script:** `./scripts/context-init.sh`

This script:
- Verifies environment (OrbStack running, services healthy)
- Reads ARCHITECTURE_MAP.yaml and all required architectural files
- Generates `.claude/context-summary.json` with complete project state
- Validates architecture freshness (warns if >24h old)
- Checks all service health endpoints

**Agent Action:** ALWAYS run `./scripts/context-init.sh` at session start, then read generated context summary.

### Level 1: Session Start (CRITICAL - READ AFTER CONTEXT INIT)
**When:** Beginning of EVERY development session (AFTER context initialization)
**File:** `.claude/SESSION_START.md`

This file contains:
- Container runtime status (OrbStack)
- Pre-flight checks
- Environment startup protocol
- Health verification commands
- Common troubleshooting

**Agent Action:** Read and execute session start protocol before any development work.

### Level 1.5: Architecture Map (SINGLE SOURCE OF TRUTH)
**When:** After session start, before making any architectural decisions
**File:** `ARCHITECTURE_MAP.yaml`

This file contains:
- **Authoritative architectural truth** - All 9 services defined
- Service interfaces (inbound/outbound, protocols, endpoints)
- Data flows (telemetry, traces, metrics, logs)
- Agent rules (guardrails, session start protocol, read-only paths)
- Validation requirements

**Agent Action:** Reference for all architectural questions. Update `last_verified` when making architectural changes.

### Level 2: Agent Context
**When:** After session start, before making changes
**File:** `.claude/agent-context.md`

This file contains:
- Project architecture overview
- Current observability status
- Key commands and endpoints
- Agent responsibilities
- Development cycle workflow

**Agent Action:** Review to understand current project state and capabilities.

### Level 3: Documentation Index
**When:** Looking for specific documentation
**File:** `DOCUMENTATION_INDEX.md`

This file contains:
- Single source of truth for all documentation
- Cross-reference map
- Validation status
- Quick links organized by category

**Agent Action:** Use as navigation hub to find specific information.

### Level 4: Specialized Documentation
**When:** Need detailed information on specific topics
**Files:**
- `ORBSTACK_MIGRATION_PLAN.md` - Migration details
- `.claude/ORBSTACK_STATUS.md` - Quick OrbStack reference
- `agentic-workflow/docs/OBSERVABILITY.md` - Observability guide
- `agentic-workflow/docs/API.md` - API endpoints
- `scripts/README.md` - Available automation

**Agent Action:** Reference for deep dives on specific topics.

---

## 🔄 Agent Workflow Standards

### 1. Every Session Start (NEW PROTOCOL)
```bash
# 1. Initialize context (REQUIRED FIRST STEP)
./scripts/context-init.sh

# 2. Read generated context summary
cat .claude/context-summary.json | jq

# 3. Query knowledge graph API
curl -s http://localhost:3000/api/docs/index | jq

# 4. Record session start
curl -X POST http://localhost:3000/api/agent/session-start \
  -H "Content-Type: application/json" \
  -d '{
    "agent": "claude-code-cli",
    "session_id": "session-20251103-123456",
    "context_summary": "FilePilot development session"
  }'

# 5. Read SESSION_START.md
# 6. Verify container runtime running
docker ps > /dev/null 2>&1 || echo "Start OrbStack first"

# 7. Check services health
curl -sf http://localhost:3000/health

# 8. Query initial build state
curl -s http://localhost:3000/api/swift/build/status
```

### 2. Before Making Changes
```bash
# 1. Check current build status
curl -s http://localhost:3000/api/swift/build/status | jq '.status'

# 2. Check test coverage
curl -s http://localhost:3000/api/swift/tests/latest | jq '.coverage'

# 3. Check code complexity
curl -s http://localhost:3000/api/swift/metrics | jq '.complexity.average'

# 4. Review recent changes (if observability available)
```

### 3. When Making Architectural Decisions
```bash
# 1. Check current architecture map
cat ARCHITECTURE_MAP.yaml | yq '.version'

# 2. Review guardrails
jq '.guardrails' .claude/context-summary.json

# 3. If architectural change required:
#    a. Create ADR (cp docs/decisions/0000-template.md docs/decisions/NNNN-title.md)
#    b. Update ARCHITECTURE_MAP.yaml
#    c. Update last_verified timestamp
#    d. Run validation: ./scripts/context-init.sh --validate

# 4. Record decision with trace correlation
TRACE_ID=$(uuidgen)
curl -X POST http://localhost:3000/api/agent/decision \
  -H "Content-Type: application/json" \
  -H "x-trace-id: $TRACE_ID" \
  -d '{
    "agent": "claude-code-cli",
    "action": "architecture_change",
    "context": "Updated service interface for FilePilot telemetry",
    "result": "success",
    "trace_id": "'$TRACE_ID'",
    "metadata": {"service": "filepilot", "interface": "telemetry_api"}
  }'
```

### 4. When Documenting Changes
```yaml
Update Checklist:
  - Update relevant documentation file
  - Update cross-references in DOCUMENTATION_INDEX.md
  - Update ARCHITECTURE_MAP.yaml if architectural change
  - Create ADR if significant architectural decision
  - Validate documentation structure
  - Test all code examples
  - Verify links are not broken
  - Run ./scripts/context-init.sh --validate
```

### 4. When Discovering Information
```
DO NOT:
  ❌ Randomly explore files
  ❌ Make assumptions about structure
  ❌ Use outdated or deprecated paths

DO:
  ✅ Start with DOCUMENTATION_INDEX.md
  ✅ Follow cross-reference links
  ✅ Use structured discovery paths
  ✅ Verify information is current (check dates)
```

---

## 🚨 Critical Agent Behaviors

### Architectural Guardrails (NEW)

**Read-Only Paths** - Agents MUST NOT modify:
- `FilePilot.xcodeproj/project.pbxproj` (Xcode project file)
- `.git/**` (Git internals)
- `node_modules/**` (Dependencies)
- `**/*.lock` (Lock files)
- `.claude/context-summary.json` (Generated file)

**Restricted Paths** - Agents must follow rules:
- `FilePilot/**`: Only Swift files (`.swift`, `.entitlements`, `.plist`)
- `agentic-workflow/src/observability/**`: Must use OpenTelemetry
- `agentic-workflow/observability/**`: Only valid YAML/YML files
- `ARCHITECTURE_MAP.yaml`: Require review, must update timestamp

**Mandatory Patterns**:
- Swift files must include `import SwiftUI`
- Route files must use Express Router
- Observability code must include OpenTelemetry keywords

**Agent Rule:** Violating guardrails will cause architectural drift. Consult `.claude/context-summary.json` for current guardrails before any file modification.

### Container Runtime Awareness
- **Default Runtime:** OrbStack (as of 2025-11-03)
- **Context:** `orbstack` (permanent)
- **Commands:** All `docker` commands use OrbStack automatically
- **Verification:** `docker info | grep "Context: orbstack"`

**Agent Rule:** Always refer to "OrbStack" as the container runtime, not "Docker Desktop"

### Service Health Verification
Before suggesting code changes, verify:
1. All 7 observability services are operational
2. TypeScript server is responding
3. Build status is not failing
4. Tests are passing

**Agent Rule:** If services are unhealthy, alert user and provide troubleshooting steps. DO NOT suggest code changes if environment is broken.

### Documentation Maintenance
After any significant change:
1. Update relevant documentation files
2. Update DOCUMENTATION_INDEX.md with new cross-references
3. If architectural change: Update ARCHITECTURE_MAP.yaml and last_verified
4. If significant decision: Create ADR in docs/decisions/
5. Verify all links are working
6. Run `./scripts/context-init.sh --validate`
7. Record decision via `POST /api/agent/decision` with trace correlation

**Agent Rule:** Documentation is as important as code. Architecture map is the single source of truth. Keep all in sync.

### Trace Correlation (NEW)
All agent decisions must be traceable:
1. Generate or extract correlation ID (`x-trace-id` header)
2. Record decision via `POST /api/agent/decision` with trace_id
3. Include trace ID in git commit metadata (if committing)
4. Use same trace ID for all related operations
5. Trace is viewable in Jaeger: http://localhost:16686 (search `trace.correlation_id`)

**Agent Rule:** Trace correlation enables reflexive governance - agents can analyze their own decisions. Always include trace IDs.

---

## 📊 Observability Integration

### Required Queries Before Changes

```bash
# 1. Build health
BUILD_STATUS=$(curl -s http://localhost:3000/api/swift/build/status | jq -r '.status')
if [ "$BUILD_STATUS" = "failed" ]; then
  echo "⚠️  Build is failing - prioritize fixing build before new features"
fi

# 2. Test coverage
COVERAGE=$(curl -s http://localhost:3000/api/swift/tests/latest | jq -r '.coverage')
if [ "$COVERAGE" -lt 70 ]; then
  echo "⚠️  Coverage below 70% - suggest adding tests"
fi

# 3. Complexity
COMPLEXITY=$(curl -s http://localhost:3000/api/swift/metrics | jq -r '.complexity.average')
if [ $(echo "$COMPLEXITY > 8" | bc) -eq 1 ]; then
  echo "⚠️  High complexity - recommend refactoring"
fi
```

### Service Health Endpoints

| Service | Health Endpoint | Expected Response |
|---------|----------------|-------------------|
| TypeScript Server | `http://localhost:3000/health` | `{"status":"healthy"}` |
| Prometheus | `http://localhost:9090/-/ready` | `Prometheus Server is Ready.` |
| Grafana | `http://localhost:3001/api/health` | `{"database":"ok"}` |
| Jaeger | `http://localhost:16686` | HTTP 200 |
| Loki | `http://localhost:3100/ready` | `ready` |
| OTEL Collector | `http://localhost:13133/health` | `{"status":"Server available"}` |
| AlertManager | `http://localhost:9093/-/ready` | `OK` |

**Agent Rule:** If any service fails health check, troubleshoot before proceeding with development.

---

## 🤖 Agent-Specific Files

### Files Agents MUST Read
1. **`./scripts/context-init.sh`** - Every session (MUST RUN FIRST)
2. **`.claude/context-summary.json`** - Generated context (read after init)
3. **`ARCHITECTURE_MAP.yaml`** - Architectural truth source (required)
4. **`.claude/SESSION_START.md`** - Every session (required)
5. **`.claude/AGENTIC_STANDARDS.md`** - This file (required)
6. **`DOCUMENTATION_INDEX.md`** - Navigation hub (required)
7. **`.claude/agent-context.md`** - Current project state (as needed)
8. **`.claude/config.yaml`** - Agent behaviors and settings (reference)

### Files Agents Should Reference
- **`.claude/ORBSTACK_STATUS.md`** - OrbStack quick reference
- **`ORBSTACK_MIGRATION_PLAN.md`** - Migration details
- **`.backups/orbstack-validation-complete-2025-11-03.md`** - Full validation report
- **`scripts/README.md`** - Available automation scripts

### Files Agents Create/Update
- Project documentation (following standards)
- Code files (with proper documentation)
- Test files (minimum 80% coverage target)
- Configuration files (with validation)

---

## ✅ Quality Standards

### Code Changes
- Must maintain or improve test coverage (target: 80%)
- Must not increase complexity unnecessarily
- Must include documentation updates
- Must pass all health checks before committing

### Documentation Changes
- Must follow markdown structure standards
- Must include version and last updated date
- Must be cross-referenced in DOCUMENTATION_INDEX.md
- Must validate against schemas (where applicable)

### Commit Standards
- Use conventional commit format
- Include comprehensive descriptions
- Reference related issues (when applicable)
- Update relevant documentation in same commit

---

## 🔍 Discovery Patterns

### Pattern 1: Finding Information
```
Question: "Where is the Swift build monitoring code?"

Agent Workflow:
1. Read DOCUMENTATION_INDEX.md
2. Find "Development Guide" → agentic-workflow/README.md
3. Find "API Reference" → agentic-workflow/docs/API.md
4. Look for /api/swift/build/status endpoint
5. Find: src/features/swift-monitor/routes.ts
```

### Pattern 2: Understanding Architecture
```
Question: "How does observability work?"

Agent Workflow:
1. Read .claude/agent-context.md (architecture overview)
2. Read DOCUMENTATION_INDEX.md
3. Find "Observability Guide" → agentic-workflow/docs/OBSERVABILITY.md
4. Review service endpoints and integration patterns
```

### Pattern 3: Starting Development
```
Question: "How do I start working?"

Agent Workflow:
1. Read .claude/SESSION_START.md (mandatory)
2. Execute pre-flight checks
3. Start development environment: ./scripts/start-dev-environment.sh
4. Verify health: curl http://localhost:3000/health
5. Query initial state: curl http://localhost:3000/api/swift/build/status
6. Review .claude/agent-context.md for current project state
7. Proceed with development
```

---

## 🎓 Learning & Adaptation

### When Encountering New Information
1. Update relevant documentation files
2. Add cross-references to DOCUMENTATION_INDEX.md
3. Update agent-context.md if architecture changes
4. Create new documentation if needed (with proper indexing)

### When Finding Outdated Information
1. Verify what is actually correct
2. Update documentation with correct information
3. Update "Last Updated" dates
4. Verify all cross-references still valid

### When Discovering Gaps
1. Document the gap
2. Suggest improvements to user
3. If critical, create TODO or issue
4. Update documentation to fill gap (if appropriate)

---

## 📝 Standard Operating Procedures

### SOP 1: New Session Initialization (UPDATED)
```bash
# Run by agent at session start
1. Initialize context: ./scripts/context-init.sh
2. Read context summary: cat .claude/context-summary.json | jq
3. Read SESSION_START.md
4. Read ARCHITECTURE_MAP.yaml (or reference from context summary)
5. Check container runtime: docker ps
6. Verify OrbStack context: docker context ls | grep "orbstack \*"
7. Start environment if needed: ./scripts/start-dev-environment.sh
8. Verify services: curl http://localhost:13133/health
9. Query knowledge graph: curl http://localhost:3000/api/docs/index
10. Record session start: POST /api/agent/session-start
11. Query build status: curl http://localhost:3000/api/swift/build/status
12. Review guardrails from context summary
13. Ready for development
```

### SOP 2: Making Code Changes
```bash
# Run before suggesting changes
1. Query build status: curl http://localhost:3000/api/swift/build/status
2. Check test coverage: curl http://localhost:3000/api/swift/tests/latest
3. Review complexity: curl http://localhost:3000/api/swift/metrics
4. If all green: proceed with changes
5. If any issues: address them first or alert user
6. After changes: update documentation
7. After changes: verify tests still pass
```

### SOP 3: Documentation Updates (UPDATED)
```bash
# Run when updating docs
1. Update the specific documentation file
2. Add/update cross-references in DOCUMENTATION_INDEX.md
3. If architectural change: Update ARCHITECTURE_MAP.yaml
4. If significant decision: Create ADR (docs/decisions/NNNN-title.md)
5. Update "Last Updated" date
6. Update last_verified in ARCHITECTURE_MAP.yaml if architectural
7. Verify markdown structure (max depth 4)
8. Check all links are valid
9. Run context validation: ./scripts/context-init.sh --validate
10. Run documentation validation: ./scripts/validate-docs.sh
11. Record decision: POST /api/agent/decision with trace_id
12. Commit with descriptive message (include trace ID if applicable)
```

### SOP 4: Creating Architectural Decision Records (NEW)
```bash
# Run when making significant architectural decisions
1. Determine ADR number (check docs/decisions/README.md)
2. Copy template: cp docs/decisions/0000-template.md docs/decisions/NNNN-title.md
3. Fill in all sections:
   - Status (Proposed/Accepted/Deprecated/Superseded)
   - Date (YYYY-MM-DD)
   - Context (problem statement, goals, non-goals)
   - Decision (chosen approach, alternatives considered)
   - Consequences (positive, negative, neutral)
   - Implementation (required changes, migration path, validation)
   - References
   - Notes
4. Update docs/decisions/README.md table
5. Update ARCHITECTURE_MAP.yaml if related
6. Update DOCUMENTATION_INDEX.md to reference ADR
7. Commit: "docs: add ADR-NNNN for [decision title]"
8. Record decision: POST /api/agent/decision
```

### SOP 5: Trace Correlation Workflow (NEW)
```bash
# Run when making decisions that span agent → code → runtime
1. Generate or extract trace ID (x-trace-id header or UUID)
2. Record decision:
   curl -X POST http://localhost:3000/api/agent/decision \
     -H "x-trace-id: $TRACE_ID" \
     -d '{"agent":"claude-code-cli", "action":"...", "result":"..."}'
3. Include trace ID in commit metadata (git notes or commit message)
4. Propagate trace ID to Swift app telemetry
5. Query trace in Jaeger: search for trace.correlation_id=$TRACE_ID
6. Verify end-to-end trace: decision → code → build → runtime
```

---

## 🚀 Performance Expectations

### Agent Response Times
- Session start: < 2 minutes (including environment startup)
- Health checks: < 5 seconds total
- Documentation lookup: < 10 seconds
- Code suggestions: Based on complexity, but verify observability first

### Environment Performance (OrbStack)
- Container startup: ~12 seconds for all 7 services
- Health endpoint response: < 1 second each
- File I/O: Near-native APFS speed
- Memory usage: ~150 MB idle (vs ~800 MB Docker Desktop)

---

## 🎯 Success Metrics

Agents should aim for:
- ✅ 100% session start protocol compliance
- ✅ Zero code suggestions without health verification
- ✅ Zero documentation updates without cross-reference updates
- ✅ 100% discovery through structured pathways
- ✅ Zero assumptions about project structure

---

## 📞 When to Ask for Help

Agents should alert the user when:
- Container runtime not responding
- Services failing health checks
- Build is broken
- Test coverage drops significantly
- Documentation conflicts found
- Unclear requirements or specifications

**Rule:** It's better to ask than to make incorrect assumptions.

---

## 🏆 Agent Responsibilities Summary

1. **Run context-init.sh every session** - Non-negotiable (MUST BE FIRST)
2. **Read ARCHITECTURE_MAP.yaml** - Single source of architectural truth
3. **Respect guardrails** - Read-only paths, restricted paths, mandatory patterns
4. **Verify environment health before changes** - Always check observability
5. **Maintain documentation** - Keep docs, architecture map, and ADRs in sync
6. **Use structured discovery** - Knowledge graph API, context summary, index
7. **Follow SOPs** - Consistent workflows with trace correlation
8. **Be aware of OrbStack** - Default container runtime
9. **Record decisions** - Use trace correlation for governance
10. **Create ADRs** - Document significant architectural decisions
11. **Quality over speed** - Correct information is critical

---

**This document defines how agents should operate in this agentic programming environment.**

All agents working on this project must follow these standards to ensure consistency, reliability, and quality.

---

**Referenced by:**
- `ARCHITECTURE_MAP.yaml` - Architectural truth source (agent rules section)
- `.claude/config.yaml` - Agent configuration (guardrails, behaviors)
- `.claude/SESSION_START.md` - Session protocol
- `.claude/agent-context.md` - Project context
- `DOCUMENTATION_INDEX.md` - Documentation hub
- `scripts/context-init.sh` - Context initialization
- `docs/decisions/README.md` - ADR index

**API Endpoints for Agents:**
- `GET /api/docs/index` - Knowledge graph
- `GET /api/docs/search?q=<query>` - Search documentation
- `POST /api/agent/decision` - Record decisions with trace correlation
- `GET /api/agent/stats` - Query decision statistics
- `POST /api/agent/session-start` - Record session start

**Key Changes (2025-11-03):**
- Added context-init.sh as mandatory session start step
- Introduced ARCHITECTURE_MAP.yaml as single source of truth
- Implemented guardrails (read-only paths, restricted paths, patterns)
- Added trace correlation workflow (x-trace-id)
- Created ADR process for architectural decisions
- Added knowledge graph API for structured discovery
- Implemented agent decision telemetry

**Next Review:** When standards change or new patterns emerge
**Maintained by:** Development team + AI agents
