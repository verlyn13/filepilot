# ADR-0001: Adopt OrbStack as Container Runtime

## Status

Accepted

## Date

2025-11-03

## Context

The development environment requires a container runtime for running the observability stack (Prometheus, Grafana, Jaeger, Loki, OTEL Collector, AlertManager, Promtail). Docker Desktop has been traditionally used but presents performance challenges on macOS.

### Problem Statement

Docker Desktop on macOS has significant performance overhead:
- High RAM usage (multiple GB)
- Slow startup times
- Slower I/O operations compared to native Linux
- Resource-intensive background processes

### Goals

- Reduce development environment resource consumption
- Improve container startup and I/O performance
- Maintain Docker CLI compatibility
- Support Docker Compose workflows
- Minimize migration effort

### Non-Goals

- Supporting multiple container runtimes simultaneously
- Maintaining Docker Desktop as a fallback option

## Decision

Adopt OrbStack as the default container runtime for the FilePilot + Agentic Workflow development environment, replacing Docker Desktop entirely.

### Chosen Approach

- Install OrbStack as the primary container runtime
- Set Docker context permanently to `orbstack`
- Update all documentation to reference OrbStack
- Configure agent awareness systems to verify OrbStack is running
- Add validation to context-init.sh to ensure OrbStack context

### Alternatives Considered

#### Alternative 1: Continue with Docker Desktop

- **Pros**:
  - Already installed
  - Official Docker solution
  - No migration required
- **Cons**:
  - High resource usage (81% more RAM than OrbStack)
  - 70% slower startup times
  - 13× slower I/O operations
  - Licensing costs for teams
- **Why rejected**: Performance overhead unacceptable for development workflow

#### Alternative 2: Podman

- **Pros**:
  - Daemonless architecture
  - Rootless containers
  - Open source
- **Cons**:
  - Docker Compose compatibility issues
  - Different CLI syntax for some commands
  - Less macOS optimization than OrbStack
  - Previous migration attempt was abandoned
- **Why rejected**: Compatibility issues and incomplete previous migration

#### Alternative 3: Colima

- **Pros**:
  - Open source
  - Docker Desktop alternative
  - Lightweight
- **Cons**:
  - Less polished than OrbStack
  - Requires more manual configuration
  - Not macOS-native
- **Why rejected**: OrbStack provides better macOS integration and performance

## Consequences

### Positive

- 81% reduction in RAM usage (OrbStack uses ~500MB vs Docker Desktop ~2.7GB)
- 70% faster container startup times
- 13× faster I/O operations
- Native macOS integration with better performance
- Free for individuals and small teams
- Automatic Docker CLI compatibility

### Negative

- Team members must install OrbStack (one-time setup)
- Slight learning curve for OrbStack-specific features
- Dependency on third-party commercial product (though free tier sufficient)
- Migration required for existing Docker Desktop users

### Neutral

- Docker CLI commands remain unchanged
- Docker Compose files require no modifications
- Existing container workflows work identically

## Implementation

### Required Changes

1. ✅ Install OrbStack on development machines
2. ✅ Set Docker context to `orbstack`: `docker context use orbstack`
3. ✅ Update `.claude/SESSION_START.md` to reference OrbStack
4. ✅ Create `.claude/ORBSTACK_STATUS.md` for agent reference
5. ✅ Update `scripts/context-init.sh` to verify OrbStack context
6. ✅ Update `.claude/config.yaml` with `container_runtime: "orbstack"`
7. ✅ Fix OTEL Collector configuration for OrbStack compatibility
8. ✅ Clean up orphaned Podman files
9. ✅ Update all documentation to reference OrbStack

### Migration Path

1. Install OrbStack: `brew install orbstack`
2. Stop Docker Desktop
3. Set Docker context: `docker context use orbstack`
4. Restart observability stack: `cd agentic-workflow/observability && docker compose up -d`
5. Verify all services healthy: `docker ps`
6. Uninstall Docker Desktop (optional but recommended)

### Validation

- Success metrics:
  - All 7 observability services running: ✅
  - Docker context permanently set to `orbstack`: ✅
  - RAM usage under 1GB for container runtime: ✅
  - Container startup time under 5 seconds: ✅
  - Agent awareness systems detect OrbStack: ✅

## References

- [OrbStack Official Site](https://orbstack.dev/)
- [OrbStack Performance Comparison](https://orbstack.dev/compare)
- `.claude/ORBSTACK_STATUS.md` - Quick reference guide
- `ARCHITECTURE_MAP.yaml` - Runtime configuration
- `scripts/context-init.sh` - Validation script

## Notes

### Related Decisions

- Migration completed 2025-11-03
- Podman migration attempt abandoned (files cleaned up)
- Permanent default context set in project configuration

### Future Reviews

This decision should be reviewed if:
- OrbStack discontinues free tier
- Docker Desktop significantly improves macOS performance
- Native macOS container runtime becomes available
- Team size exceeds OrbStack free tier limits

**Review date**: 2026-11-03 (1 year)
