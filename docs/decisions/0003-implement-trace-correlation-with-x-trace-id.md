# ADR-0003: Implement Trace Correlation with x-trace-id

## Status

Accepted

## Date

2025-11-03

## Context

The FilePilot + Agentic Workflow project involves multiple actors (AI agents, human developers, Swift app) making changes that propagate through the system (code changes → builds → runtime → telemetry). Without trace correlation, it's impossible to connect an agent decision to its downstream effects.

### Problem Statement

- No way to correlate agent decisions with code changes
- Cannot trace code changes to build/test results
- Runtime telemetry not linked to originating decisions
- Difficult to debug agent actions after the fact
- No visibility into decision → outcome pipeline

### Goals

- Correlate agent decisions → code changes → runtime events
- Provide end-to-end traceability across the stack
- Enable debugging of agent decisions via trace lookup
- Support reflexive governance (agents analyze their own decisions)
- Integrate with existing OpenTelemetry infrastructure

### Non-Goals

- Replacing OpenTelemetry trace IDs (complement, not replace)
- User-facing tracing (internal observability only)
- Real-time trace streaming (batch analysis acceptable)

## Decision

Implement trace correlation using `x-trace-id` HTTP header that propagates through all layers of the system, from agent decision to runtime telemetry.

### Chosen Approach

**Middleware implementation**:
- `src/lib/trace-correlation.ts` provides middleware and helpers
- `traceCorrelationMiddleware()` extracts or generates correlation ID
- Correlation ID added to all requests via `x-trace-id` header
- OpenTelemetry spans tagged with `trace.correlation_id` attribute

**Integration points**:
1. **Agent decisions**: POST to `/api/agent/decision` includes `trace_id`
2. **Code changes**: Git commits reference trace ID in metadata
3. **Build/test**: Swift build telemetry includes trace ID
4. **Runtime**: Swift app includes trace ID in all telemetry
5. **Observability**: Jaeger/Grafana queries support correlation ID lookup

**Data flow**:
```
Agent Decision → x-trace-id → Code Change → Build → Runtime → Telemetry
     │                                         │         │
     └─────── Recorded via /api/agent/decision │         │
                                                │         │
                            OpenTelemetry spans ┴─────────┴
```

### Alternatives Considered

#### Alternative 1: Use only OpenTelemetry trace IDs

- **Pros**:
  - Already implemented
  - Standard approach
  - No additional infrastructure
- **Cons**:
  - Trace IDs generated per-request, not per-decision
  - No way to link agent decision made before HTTP request
  - Difficult to query across agent → code → runtime boundary
  - Trace context lost between sessions
- **Why rejected**: Doesn't solve cross-session correlation problem

#### Alternative 2: Custom event correlation service

- **Pros**:
  - Full control over correlation logic
  - Could add ML-based correlation
  - Centralized correlation database
- **Cons**:
  - Significant implementation effort
  - Another service to maintain
  - Duplicate of OpenTelemetry functionality
  - Overkill for current needs
- **Why rejected**: Over-engineering; header propagation simpler

#### Alternative 3: Git commit SHAs as correlation IDs

- **Pros**:
  - Natural linkage to code changes
  - No additional ID generation
  - Built-in versioning
- **Cons**:
  - Commits happen after decision (temporal gap)
  - Multiple decisions per commit
  - Doesn't work for failed/abandoned decisions
  - No correlation for non-code decisions
- **Why rejected**: Not all decisions result in commits

## Consequences

### Positive

- End-to-end traceability from decision to runtime
- Debugging agent decisions via Jaeger UI
- Correlation across service boundaries
- Automatic propagation via middleware
- Integration with existing OpenTelemetry stack
- Enables reflexive governance loops
- Support for "what caused this?" queries

### Negative

- Another header to track and propagate
- Requires discipline to include trace ID in all telemetry
- Correlation IDs must be generated and managed
- Risk of correlation ID leakage if not careful
- Additional log/span storage overhead (minor)

### Neutral

- Uses standard HTTP header approach
- Compatible with OpenTelemetry W3C Trace Context
- Correlation ID is UUID v4 (standard format)

## Implementation

### Required Changes

1. ✅ Create `src/lib/trace-correlation.ts` with middleware and helpers
2. ✅ Add `traceCorrelationMiddleware()` to Express app
3. ✅ Update `/api/agent/decision` to accept and return `trace_id`
4. ✅ Add correlation ID to all OpenTelemetry spans
5. ✅ Update agent routes to use `getCurrentTraceId(req)`
6. ⏳ Update Swift app to include `x-trace-id` in telemetry requests
7. ⏳ Add trace ID to git commit metadata (git notes)
8. ⏳ Create Grafana dashboard for correlation ID lookup
9. ⏳ Document trace correlation workflow in AGENTIC_STANDARDS.md

### Migration Path

No migration required (new capability). Rollout:

1. Backend middleware active (generates IDs for all requests)
2. Agent decision endpoint accepts trace IDs
3. Swift app updated to propagate trace IDs
4. Documentation updated with trace correlation workflow
5. Grafana dashboards created for trace lookup

### Validation

Success metrics:
- ✅ All HTTP requests have `x-trace-id` response header
- ✅ Agent decisions include correlation ID in response
- ✅ OpenTelemetry spans tagged with `trace.correlation_id`
- ⏳ Swift telemetry includes trace ID
- ⏳ Can query Jaeger for traces by correlation ID
- ⏳ End-to-end trace from decision → runtime demonstrated

## References

- `src/lib/trace-correlation.ts` - Middleware implementation
- `src/features/agent/routes.ts` - Agent decision endpoint
- [W3C Trace Context](https://www.w3.org/TR/trace-context/)
- [OpenTelemetry Semantic Conventions](https://opentelemetry.io/docs/reference/specification/trace/semantic_conventions/)

## Notes

### Trace ID Format

Using UUID v4 for correlation IDs:
- Format: `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`
- Generated via Node.js `crypto.randomUUID()`
- Stored in `x-trace-id` HTTP header
- Tagged in OpenTelemetry spans as `trace.correlation_id`

### Related Decisions

- ADR-0002: Architecture Map (data flows include trace correlation)
- Future ADR: Reflexive Governance (will use trace correlation for analysis)

### Trace Correlation Workflow

**Agent decision workflow**:
1. Agent generates correlation ID (or receives from caller)
2. Agent makes decision (code change, refactor, etc.)
3. Agent POSTs to `/api/agent/decision` with `trace_id`
4. Backend records decision with correlation ID
5. Agent includes correlation ID in git commit metadata
6. Swift build triggered, telemetry includes trace ID
7. Runtime events tagged with trace ID
8. Full trace viewable in Jaeger by correlation ID

**Query workflow**:
1. Open Jaeger UI: `http://localhost:16686`
2. Search for tag: `trace.correlation_id = <uuid>`
3. View all spans related to that decision
4. Trace decision → code → build → runtime

### Future Reviews

This decision should be reviewed if:
- Trace correlation overhead becomes significant
- Need for more sophisticated correlation (ML-based)
- OpenTelemetry adds native decision correlation
- Scale requires distributed tracing service

**Review date**: 2026-05-03 (6 months)
