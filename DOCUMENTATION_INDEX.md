# Documentation Index - Single Source of Truth

> **Version**: 1.3.0
> **Last Updated**: 2025-11-04
> **Validation**: ✅ Spec-compliant
> **Agent-Aware**: ✅ Claude Code CLI configured
> **Knowledge Graph**: ✅ Available via `/api/docs/index`

## 📚 Documentation Structure

This index serves as the single source of truth for all project documentation. All documents are cross-referenced, validated, and integrated into the development cycle.

## 🎯 Quick Navigation

| Category | Primary Document | Purpose | Validation Schema |
|----------|------------------|---------|-------------------|
| **Architecture Map** | [ARCHITECTURE_MAP.yaml](./ARCHITECTURE_MAP.yaml) | **Single source of architectural truth** | `architecture.schema.json` |
| **ADR Index** | [docs/decisions/README.md](./docs/decisions/README.md) | Architectural Decision Records (7 ADRs) | N/A |
| **Context Initialization** | [scripts/context-init.sh](./scripts/context-init.sh) | Agent session context loading | N/A |
| **Project Overview** | [plan.md](./plan.md) | Original project specification | `project.schema.json` |
| **Integration Plan** | [INTEGRATED_PLAN.md](./INTEGRATED_PLAN.md) | Swift + TypeScript integration | `integration.schema.json` |
| **Development Guide** | [agentic-workflow/README.md](./agentic-workflow/README.md) | Main development documentation | `development.schema.json` |
| **API Reference** | [agentic-workflow/docs/API.md](./agentic-workflow/docs/API.md) | API specifications | `api.schema.json` |
| **Observability Guide** | [agentic-workflow/docs/OBSERVABILITY.md](./agentic-workflow/docs/OBSERVABILITY.md) | Agent & Human observability guide | `observability.schema.json` |
| **Development Principles** | [agentic-workflow/docs/DEVELOPMENT_PRINCIPLES.md](./agentic-workflow/docs/DEVELOPMENT_PRINCIPLES.md) | Coding standards & practices | `principles.schema.json` |
| **Quick Start** | [agentic-workflow/docs/QUICKSTART.md](./agentic-workflow/docs/QUICKSTART.md) | Getting started guide | `quickstart.schema.json` |
| **Contributing** | [agentic-workflow/CONTRIBUTING.md](./agentic-workflow/CONTRIBUTING.md) | Contribution guidelines | `contributing.schema.json` |
| **OrbStack Migration** | [ORBSTACK_MIGRATION_PLAN.md](./ORBSTACK_MIGRATION_PLAN.md) | Docker Desktop → OrbStack migration guide | N/A |
| **OrbStack Status** | [.claude/ORBSTACK_STATUS.md](./.claude/ORBSTACK_STATUS.md) | Agent quick reference for OrbStack ✅ Complete | N/A |
| **Xcode CLI Observability** | [docs/XCODE_CLI_OBSERVABILITY.md](./docs/XCODE_CLI_OBSERVABILITY.md) | Complete Xcode/Swift CLI integration with observability | N/A |
| **Maestro UI Testing** | [docs/MAESTRO_UI_TESTING.md](./docs/MAESTRO_UI_TESTING.md) | Maestro mobile UI testing integration with agentic workflow | N/A |

## 🔄 Development Cycle Integration

### Phase 1: Planning
- **Documents**: [`plan.md`](./plan.md), [`INTEGRATED_PLAN.md`](./INTEGRATED_PLAN.md)
- **Tools**: Task management, TodoWrite
- **Scripts**: None
- **Validation**: Project requirements checklist

### Phase 2: Implementation
- **Documents**: [`DEVELOPMENT_PRINCIPLES.md`](./agentic-workflow/docs/DEVELOPMENT_PRINCIPLES.md)
- **Tools**: Code editors, version control
- **Scripts**: [`start-dev-environment.sh`](./scripts/start-dev-environment.sh)
- **Validation**: Code quality checks, type safety

### Phase 3: Testing
- **Documents**: [`API.md`](./agentic-workflow/docs/API.md)
- **Tools**: Test runners, coverage tools
- **Scripts**: None
- **Validation**: Test coverage thresholds

### Phase 4: Monitoring
- **Documents**: [`OBSERVABILITY.md`](./agentic-workflow/docs/OBSERVABILITY.md)
- **Tools**: Observability stack (Prometheus, Grafana, Jaeger, Loki, OTEL Collector)
- **Scripts**: [`start-dev-environment.sh`](./scripts/start-dev-environment.sh)
- **Validation**: Performance metrics

### Scripts & Automation
- **Index**: [`scripts/README.md`](./scripts/README.md)
- **Available Scripts**: startup, validation, migration tools
- **Runtime Support**: OrbStack (recommended), Docker Desktop

## 🔍 Cross-Reference Map

```yaml
# Document relationships and dependencies
plan.md:
  implements: []
  references: ["INTEGRATED_PLAN.md"]
  validates_against: "project.schema.json"

INTEGRATED_PLAN.md:
  implements: ["plan.md"]
  references: ["agentic-workflow/README.md", "FilePilot/README.md"]
  validates_against: "integration.schema.json"

agentic-workflow/README.md:
  implements: ["INTEGRATED_PLAN.md"]
  references: ["API.md", "QUICKSTART.md", "DEVELOPMENT_PRINCIPLES.md"]
  validates_against: "development.schema.json"

agentic-workflow/docs/API.md:
  implements: ["agentic-workflow/README.md"]
  references: ["swift-monitor/routes.ts", "health/routes.ts"]
  validates_against: "api.schema.json"
```

## 🧠 Knowledge Graph & Architecture

### Architecture Map (Single Source of Truth)

**Primary Document**: [`ARCHITECTURE_MAP.yaml`](./ARCHITECTURE_MAP.yaml)
- **Version**: 1.0.0
- **Last Verified**: 2025-11-04T05:35:00Z
- **Purpose**: Authoritative architectural truth source
- **Contents**:
  - All 9 services defined (FilePilot, TypeScript backend, 7 observability services)
  - Service interfaces (inbound/outbound, protocols, endpoints)
  - Data flows (telemetry, traces, metrics, logs)
  - Agent rules and guardrails
  - Singleton ownership patterns (see ADR-0004)
  - Agent rules (guardrails, session start protocol, read-only paths)
  - Validation requirements

### Knowledge Graph API

**Endpoint**: `GET http://localhost:3000/api/docs/index`

Returns complete documentation knowledge graph with:
- Service architecture (service count, last verified, ADRs)
- Documentation index (primary docs, API docs, agent-specific docs)
- Service definitions (FilePilot, Agentic Workflow, Observability Stack)
- API endpoints (health, swift, agent, docs)
- Context summary (from `context-init.sh`)

**Search Endpoint**: `GET http://localhost:3000/api/docs/search?q=<query>`

### Agent Decision Telemetry

**Record Decision**: `POST http://localhost:3000/api/agent/decision`
- Track agent decisions for governance
- Correlate decisions with code changes via `x-trace-id`
- Query decision statistics
- Support reflexive governance loops

**Decision Stats**: `GET http://localhost:3000/api/agent/stats`
**Session Start**: `POST http://localhost:3000/api/agent/session-start`

### Context Initialization

**Script**: `./scripts/context-init.sh`
- Verifies environment (OrbStack, services)
- Reads architectural files (ARCHITECTURE_MAP.yaml, ADRs)
- Generates `.claude/context-summary.json`
- Validates architecture freshness (warns if >24h old)

**Validation Mode**: `./scripts/context-init.sh --validate`

### Architectural Decision Records (ADRs)

**Directory**: [`docs/decisions/`](./docs/decisions/)
**Template**: [`docs/decisions/0000-template.md`](./docs/decisions/0000-template.md)

**Current ADRs**:
- [ADR-0001: Adopt OrbStack as Container Runtime](./docs/decisions/0001-adopt-orbstack-as-container-runtime.md) - Migration complete
- [ADR-0002: Implement Architecture Map as Single Source of Truth](./docs/decisions/0002-implement-architecture-map-as-single-source-of-truth.md) - Implemented
- [ADR-0003: Implement Trace Correlation with x-trace-id](./docs/decisions/0003-implement-trace-correlation-with-x-trace-id.md) - Active

## 📊 Observability Documentation

**Complete Guide**: [`OBSERVABILITY.md`](./agentic-workflow/docs/OBSERVABILITY.md)

### TypeScript Monitoring Server
- **Endpoint**: `http://localhost:3000`
- **API Docs**: [`API.md`](./agentic-workflow/docs/API.md)
- **Observability Guide**: [`OBSERVABILITY.md`](./agentic-workflow/docs/OBSERVABILITY.md)
- **Metrics**: `/metrics` (Prometheus format)
- **Health**: `/health` (JSON status)

### Swift Application Telemetry
- **Build Status**: `/api/swift/build/status`
- **Test Results**: `/api/swift/tests`
- **Code Metrics**: `/api/swift/metrics`
- **Real-time Events**: `/api/telemetry`

### Agent Decision Telemetry
- **Record Decision**: `POST /api/agent/decision` - Track agent decisions with trace correlation
- **Decision Stats**: `GET /api/agent/stats` - Query decision statistics
- **Session Start**: `POST /api/agent/session-start` - Record agent session initialization

### Documentation & Knowledge Graph
- **Knowledge Graph**: `GET /api/docs/index` - Complete documentation manifest
- **Search Docs**: `GET /api/docs/search?q=<query>` - Search documentation

### Observability Stack (Docker Compose)
- **Prometheus**: `http://localhost:9090` - Metrics storage & queries
- **Grafana**: `http://localhost:3001` - Visual dashboards (admin/admin)
- **Jaeger**: `http://localhost:16686` - Distributed tracing
- **Loki**: `http://localhost:3100` - Log aggregation
- **AlertManager**: `http://localhost:9093` - Alert management

### Agent Integration

**Session Start Protocol**:
1. Run `./scripts/context-init.sh` to load architectural context
2. Read generated `.claude/context-summary.json` for project state
3. Query `/api/docs/index` for knowledge graph
4. Verify services healthy via `/health` endpoint
5. Record session start: `POST /api/agent/session-start`

**During Development**:
- Check build status before suggesting changes: `GET /api/swift/build/status`
- Verify test coverage and failures: `GET /api/swift/tests`
- Analyze code complexity for refactoring: `GET /api/swift/metrics`
- Monitor performance metrics: `GET /metrics`
- Review telemetry for user behavior insights: `GET /api/telemetry`
- Record decisions with trace correlation: `POST /api/agent/decision`
- Search documentation: `GET /api/docs/search?q=<term>`

**Trace Correlation**:
- All requests include `x-trace-id` header for end-to-end tracing
- Correlate agent decisions → code changes → runtime events
- Query traces in Jaeger: `http://localhost:16686` (search by `trace.correlation_id`)

See [`OBSERVABILITY.md`](./agentic-workflow/docs/OBSERVABILITY.md) for complete agent usage patterns.

## ✅ Validation Status

| Document | Last Validated | Schema Version | Status |
|----------|----------------|----------------|--------|
| plan.md | 2025-11-02 | v1.0 | ✅ Valid |
| INTEGRATED_PLAN.md | 2025-11-02 | v1.0 | ✅ Valid |
| README.md | 2025-11-02 | v1.0 | ✅ Valid |
| API.md | 2025-11-02 | v1.0 | ✅ Valid |
| DEVELOPMENT_PRINCIPLES.md | 2025-11-02 | v1.0 | ✅ Valid |
| QUICKSTART.md | 2025-11-02 | v1.0 | ✅ Valid |
| CONTRIBUTING.md | 2025-11-02 | v1.0 | ✅ Valid |

## 🤖 AI Agent Configuration

### Claude Code CLI & Codex CLI

**Required Reading (Session Start)**:
1. [`.claude/SESSION_START.md`](./.claude/SESSION_START.md) - **READ FIRST EVERY SESSION**
2. [`ARCHITECTURE_MAP.yaml`](./ARCHITECTURE_MAP.yaml) - Architectural truth source
3. [`.claude/AGENTIC_STANDARDS.md`](./.claude/AGENTIC_STANDARDS.md) - Agent workflows & discovery patterns
4. [`DOCUMENTATION_INDEX.md`](./DOCUMENTATION_INDEX.md) - This document

**Configuration Files**:
- **Config**: [`.claude/config.yaml`](./.claude/config.yaml) - Agent configuration with guardrails
- **Context Script**: [`scripts/context-init.sh`](./scripts/context-init.sh) - Load architectural context
- **Agent Context**: [`.claude/agent-context.md`](./.claude/agent-context.md) - Project overview
- **OrbStack Status**: [`.claude/ORBSTACK_STATUS.md`](./.claude/ORBSTACK_STATUS.md) - Container runtime quick reference

**Guardrails**:
- **Read-only paths**: `FilePilot.xcodeproj/project.pbxproj`, `.git/**`, `node_modules/**`, `*.lock`
- **Restricted paths**: Swift files only in `FilePilot/`, observability code must use OpenTelemetry
- **Mandatory patterns**: Swift files must import SwiftUI, routes must use Express Router
- **Pre-commit validations**: Architecture map timestamp, cross-references, formatting

**Container Runtime**: OrbStack (permanent default context)

**Capabilities**:
- Structured information discovery via knowledge graph API
- Proactive monitoring via observability endpoints
- Auto-fix simple issues with verification
- Documentation maintenance with cross-references
- Cross-reference validation
- Full observability integration
- Decision telemetry with trace correlation
- Architectural compliance enforcement

### Development Cycle Automation
```bash
# Agent-aware commands
claude-code review --thorough      # AI code review
claude-code optimize --target all  # Performance optimization
claude-code docs update            # Documentation sync
claude-code test generate          # Test generation
```

## 📝 Documentation Standards

All documentation must:
1. **Have a clear header** with version and last updated date
2. **Be cross-referenced** in this index
3. **Validate against schema** (JSON Schema v7)
4. **Include examples** where applicable
5. **Maintain consistent formatting** (Markdown, max depth 4)
6. **Be agent-accessible** (indexed for AI context)

## 🔗 Quick Links

### Architecture & Context
- [Initialize Context](./scripts/README.md#context-initsh) - `./scripts/context-init.sh`
- [View Knowledge Graph](http://localhost:3000/api/docs/index) - Complete documentation manifest
- [Architecture Map](./ARCHITECTURE_MAP.yaml) - Single source of architectural truth
- [ADR Index](./docs/decisions/README.md) - Architectural Decision Records

### Development
- [Start Development Environment](./scripts/README.md#start-dev-environmentsh)
- [Build Swift App](./agentic-workflow/docs/QUICKSTART.md#swift-app)
- [Run Full Test Suite](./agentic-workflow/docs/QUICKSTART.md#testing)
- [Validate Documentation](./scripts/README.md#validate-docssh)

### Monitoring
- [View Metrics Dashboard](http://localhost:3001) - Grafana
- [Check API Health](http://localhost:3000/health) - TypeScript Server
- [Trace Requests](http://localhost:16686) - Jaeger (search by `trace.correlation_id`)
- [Query Logs](http://localhost:3100) - Loki
- [View Alerts](http://localhost:9093) - AlertManager
- [Agent Decision Stats](http://localhost:3000/api/agent/stats) - Decision telemetry

### Container Runtime
- [OrbStack Migration Guide](./ORBSTACK_MIGRATION_PLAN.md) - Migration plan & details
- [OrbStack Status](./.claude/ORBSTACK_STATUS.md) - **Agent quick reference** ✅ Complete
- [ADR-0001: OrbStack Adoption](./docs/decisions/0001-adopt-orbstack-as-container-runtime.md) - Decision rationale
- [Scripts Documentation](./scripts/README.md) - Automation scripts

### Documentation
- [Update Documentation](./agentic-workflow/CONTRIBUTING.md#documentation)
- [Validate Schemas](./docs/schemas/README.md)
- [Check Cross-References](./docs/CROSS_REFERENCE_INDEX.json)
- [Search Documentation](http://localhost:3000/api/docs/search) - API endpoint

## 🔄 Auto-Update Status

This documentation index is:
- **Automatically validated** on every commit
- **Cross-reference checked** daily
- **Schema validated** on changes
- **Agent-synchronized** in real-time

---

## 📐 Architectural Governance

### Architectural Map Maintenance

**Update triggers**:
- Adding/removing services
- Changing service interfaces or protocols
- Modifying data flows
- Updating agent rules or guardrails
- Architectural refactoring

**Update process**:
1. Edit `ARCHITECTURE_MAP.yaml`
2. Update `last_verified` timestamp (UTC)
3. Set `verified_by` to agent or human making change
4. Run `./scripts/context-init.sh --validate`
5. Commit: `docs: update architecture map - [description]`

### Creating New ADRs

1. Copy template: `cp docs/decisions/0000-template.md docs/decisions/NNNN-title.md`
2. Fill in all sections (context, decision, consequences, implementation)
3. Update `docs/decisions/README.md` with new ADR
4. Commit: `docs: add ADR-NNNN for [decision title]`
5. Reference ADR in related code changes

### Trace Correlation Workflow

**Agent decision workflow**:
1. Agent generates correlation ID (or receives from caller)
2. Agent makes decision (code change, refactor, etc.)
3. Agent POSTs to `/api/agent/decision` with `trace_id`
4. Backend records decision with correlation ID
5. Agent includes correlation ID in commit metadata
6. Swift build triggered, telemetry includes trace ID
7. Runtime events tagged with trace ID
8. Full trace viewable in Jaeger by correlation ID

---

*This is a living document maintained by both human developers and AI agents. Last AI review: 2025-11-03*