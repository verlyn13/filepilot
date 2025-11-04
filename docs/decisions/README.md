# Architectural Decision Records (ADRs)

This directory contains Architectural Decision Records (ADRs) for the FilePilot + Agentic Workflow project.

## Purpose

ADRs document significant architectural decisions made throughout the project lifecycle. They provide:

- **Context**: Why a decision was needed
- **Decision**: What was decided
- **Consequences**: What are the implications (positive and negative)
- **Status**: Current state of the decision (Proposed, Accepted, Deprecated, Superseded)

## ADR Numbering

ADRs are numbered sequentially using the format `NNNN-title-in-kebab-case.md`:

- `0001-adopt-orbstack-as-container-runtime.md`
- `0002-implement-architecture-map-as-single-source-of-truth.md`
- `0003-...`

## ADR Template

See `0000-template.md` for the standard template to use when creating new ADRs.

## Creating a New ADR

1. Copy the template: `cp 0000-template.md NNNN-your-decision-title.md`
2. Fill in all sections
3. Update the status (usually starts as "Proposed")
4. Commit with message: `docs: add ADR-NNNN for [decision title]`
5. Reference the ADR in related code changes

## Current ADRs

| Number | Title | Status | Date |
|--------|-------|--------|------|
| 0001 | Adopt OrbStack as Container Runtime | Accepted | 2025-11-03 |
| 0002 | Implement Architecture Map as Single Source of Truth | Accepted | 2025-11-03 |
| 0003 | Implement Trace Correlation with x-trace-id | Accepted | 2025-11-03 |

## References

- [ADR GitHub Organization](https://adr.github.io/)
- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
