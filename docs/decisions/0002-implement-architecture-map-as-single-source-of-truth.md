# ADR-0002: Implement Architecture Map as Single Source of Truth

## Status

Accepted

## Date

2025-11-03

## Context

The FilePilot + Agentic Workflow project involves multiple services (Swift app, TypeScript backend, 7 observability services), multiple development environments (human developers, AI agents), and complex interactions. Without a single source of architectural truth, drift occurs, documentation becomes stale, and agents make decisions based on incomplete information.

### Problem Statement

- Architecture documentation scattered across multiple files
- No authoritative source for service definitions and interfaces
- Agents lack structured project context at session start
- Risk of architectural drift as project evolves
- Difficult to validate architectural compliance

### Goals

- Create single source of architectural truth
- Enable agent context initialization at session start
- Define clear service boundaries and interfaces
- Establish data flow documentation
- Provide machine-readable and human-readable format
- Support architectural validation and compliance

### Non-Goals

- Replacing all documentation (complements existing docs)
- Auto-generating code from architecture map
- Runtime service discovery (static configuration only)

## Decision

Implement `ARCHITECTURE_MAP.yaml` as the authoritative source of architectural truth, with `scripts/context-init.sh` to load context at session start.

### Chosen Approach

**ARCHITECTURE_MAP.yaml structure**:
- Project metadata (version, last_verified, verified_by)
- Service definitions (9 services: FilePilot, TypeScript backend, 7 observability services)
- Interface contracts (inbound/outbound, protocols, endpoints)
- Data flows (trace through system)
- Agent rules (guardrails, required files, session start protocol)
- Validation requirements

**context-init.sh script**:
- Verifies environment (OrbStack running, services healthy)
- Reads required architectural files
- Extracts context data from ARCHITECTURE_MAP.yaml
- Queries service health endpoints
- Generates context-summary.json
- Validates architecture freshness (warns if >24h old)

### Alternatives Considered

#### Alternative 1: README-based documentation

- **Pros**:
  - Simple to implement
  - Human-readable
  - No tooling required
- **Cons**:
  - Not machine-readable
  - No structured validation
  - Difficult to parse programmatically
  - No version tracking
- **Why rejected**: Agents cannot efficiently parse unstructured markdown

#### Alternative 2: OpenAPI/Swagger for all services

- **Pros**:
  - Industry standard
  - Good tooling support
  - Auto-generates documentation
- **Cons**:
  - API-focused, doesn't cover architecture
  - Requires separate file per service
  - No support for non-HTTP interfaces
  - Doesn't define data flows or agent rules
- **Why rejected**: Too narrow in scope, missing architectural concerns

#### Alternative 3: C4 Model with PlantUML

- **Pros**:
  - Standardized modeling approach
  - Visual diagrams
  - Multiple levels of abstraction
- **Cons**:
  - Requires learning C4 notation
  - PlantUML not easily parsed by agents
  - Diagram-focused, not data-focused
  - No runtime validation
- **Why rejected**: More complexity than needed, not agent-friendly

#### Alternative 4: Service mesh configuration (Istio/Linkerd)

- **Pros**:
  - Runtime enforcement
  - Automatic service discovery
  - Traffic management
- **Cons**:
  - Massive infrastructure overhead for development
  - Production-focused, not dev-focused
  - Kubernetes dependency
  - Overkill for 9-service monorepo
- **Why rejected**: Far too heavyweight for project scale

## Consequences

### Positive

- Single authoritative source for architecture
- Machine-readable format (YAML) parseable by agents
- Structured validation (schema, timestamps, freshness checks)
- Agent context loading automated via context-init.sh
- Architectural drift detected via last_verified timestamp
- Service interfaces explicitly documented
- Data flows traceable end-to-end
- Guardrails prevent architectural violations

### Negative

- Must manually update last_verified timestamp
- YAML formatting can be error-prone
- Requires discipline to keep synchronized with code
- Another file to maintain
- Risk of becoming stale if not validated regularly

### Neutral

- Complements existing documentation (not a replacement)
- Both human and agent readable
- Requires agent session start integration

## Implementation

### Required Changes

1. ✅ Create `ARCHITECTURE_MAP.yaml` with complete service definitions
2. ✅ Define all 9 services with interfaces, responsibilities, constraints
3. ✅ Document data flows (telemetry, traces, metrics, logs)
4. ✅ Add agent rules section (guardrails, session start protocol)
5. ✅ Create `scripts/context-init.sh` for context loading
6. ✅ Update `.claude/config.yaml` to reference ARCHITECTURE_MAP.yaml
7. ✅ Add guardrails enforcement in config.yaml
8. ⏳ Update DOCUMENTATION_INDEX.md to reference architecture map
9. ⏳ Create validation script for YAML schema
10. ⏳ Add pre-commit hook to check last_verified timestamp

### Migration Path

No migration required (new capability). Integration steps:

1. Agents run `./scripts/context-init.sh` at session start
2. Script reads ARCHITECTURE_MAP.yaml
3. Generates `.claude/context-summary.json`
4. Agents use context for decision-making
5. Agents update last_verified when making architectural changes

### Validation

Success metrics:
- ✅ ARCHITECTURE_MAP.yaml contains all 9 services
- ✅ context-init.sh successfully generates context-summary.json
- ✅ Architecture freshness check warns if >24h old
- ✅ All required files readable by context-init.sh
- ⏳ Agents respect guardrails defined in architecture map
- ⏳ Pre-commit hooks validate architecture map changes

## References

- `ARCHITECTURE_MAP.yaml` - The architecture map itself
- `scripts/context-init.sh` - Context loading script
- `.claude/config.yaml` - Agent configuration with guardrails
- `.claude/SESSION_START.md` - Agent session start protocol
- `.claude/AGENTIC_STANDARDS.md` - Agent workflow standards

## Notes

### Related Decisions

- ADR-0001: OrbStack adoption (runtime configuration documented in map)
- ADR-0003: Trace correlation (data flows documented in map)

### Architecture Map Maintenance

**Update triggers**:
- Adding/removing services
- Changing service interfaces or protocols
- Modifying data flows
- Updating agent rules or guardrails
- Architectural refactoring

**Update process**:
1. Edit ARCHITECTURE_MAP.yaml
2. Update `last_verified` timestamp with current UTC time
3. Set `verified_by` to agent or human making change
4. Run `./scripts/context-init.sh --validate` to verify
5. Commit with message: `docs: update architecture map - [change description]`

### Future Reviews

This decision should be reviewed if:
- Service count exceeds 20 (may need more structure)
- YAML becomes unmanageable (consider splitting or tooling)
- Need for runtime service discovery emerges
- Architecture visualization becomes critical need

**Review date**: 2026-05-03 (6 months)
