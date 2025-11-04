# FilePilot Maestro UI Tests

This directory contains Maestro UI test flows for the FilePilot macOS file manager application, fully integrated with the agentic development observability stack.

## Quick Start

```bash
# Install Maestro (one-time setup)
./scripts/maestro/install-maestro.sh

# Run smoke tests
./scripts/maestro/run-maestro-tests.sh smoke

# Run all tests
./scripts/maestro/run-maestro-tests.sh all

# Analyze failures (if any)
./scripts/maestro/agent-test-analyzer.sh
```

## Directory Structure

```
.maestro/
├── flows/                    # Test flow definitions
│   ├── 01_smoke_test.yaml    # Basic app launch and UI verification
│   ├── 02_navigation_test.yaml    # Back/forward/up navigation
│   ├── 03_view_modes_test.yaml    # List/grid/column view switching
│   ├── 04_git_panel_test.yaml     # Git status panel toggle
│   ├── 05_inspector_panel_test.yaml    # Inspector panel and file info
│   └── 06_filter_panel_test.yaml   # File filtering functionality
├── subflows/                 # Reusable subflows
│   └── common_actions.yaml   # Common test actions
├── screenshots/              # Test screenshots (generated)
└── baselines/                # Baseline screenshots for comparison
```

## Test Flows

### 01_smoke_test.yaml
**What it tests:** Basic app launch and UI presence
**Duration:** ~10 seconds
**Run:** `./scripts/maestro/run-maestro-tests.sh smoke`

### 02_navigation_test.yaml
**What it tests:** Navigation controls (back, forward, up)
**Duration:** ~30 seconds
**Run:** `./scripts/maestro/run-maestro-tests.sh navigation`

### 03_view_modes_test.yaml
**What it tests:** View mode switching (list, grid, column) and keyboard shortcuts
**Duration:** ~40 seconds
**Run:** `./scripts/maestro/run-maestro-tests.sh views`

### 04_git_panel_test.yaml
**What it tests:** Git status panel toggle and visibility
**Duration:** ~20 seconds
**Run:** `./scripts/maestro/run-maestro-tests.sh git`

### 05_inspector_panel_test.yaml
**What it tests:** Inspector panel toggle and file metadata display
**Duration:** ~25 seconds
**Run:** `./scripts/maestro/run-maestro-tests.sh inspector`

### 06_filter_panel_test.yaml
**What it tests:** Filter panel functionality and file filtering
**Duration:** ~30 seconds
**Run:** `./scripts/maestro/run-maestro-tests.sh filter`

## Observability Integration

All test executions send telemetry to the observability backend:

```bash
# View test results via API
curl http://localhost:3000/api/maestro/tests/latest | jq

# View statistics
curl http://localhost:3000/api/maestro/stats | jq

# Check health
curl http://localhost:3000/api/maestro/health | jq

# Query by trace ID
curl http://localhost:3000/api/maestro/trace/YOUR_TRACE_ID | jq
```

## CI/CD Integration

Tests run automatically in GitHub Actions:
- On every pull request
- On pushes to main branch
- Can be triggered manually

Results are uploaded as artifacts and commented on PRs.

## Agent Workflows

### For AI Agents

```bash
# 1. Verify environment
which maestro && maestro --version

# 2. Run tests with trace correlation
TRACE_ID=$(uuidgen)
TRACE_ID=$TRACE_ID ./scripts/maestro/run-maestro-tests.sh smoke

# 3. Analyze failures (if any)
./scripts/maestro/agent-test-analyzer.sh

# 4. Record decision
curl -X POST http://localhost:3000/api/agent/decision \
  -H "x-trace-id: $TRACE_ID" \
  -d '{"agent":"claude-code-cli","action":"maestro_test_run"}'
```

### Agent Decision Tree

```
Tests passed?
  YES → Record success, continue development
  NO → Run agent-test-analyzer.sh
    → Element not found?
        → Use 'maestro studio' to inspect UI
        → Update flow YAML
    → Timeout?
        → Add wait conditions
        → Optimize app performance
    → Visual regression?
        → Review screenshots
        → Update baselines if intentional
```

## Interactive Debugging

Use Maestro Studio for interactive UI inspection:

```bash
maestro studio
```

This opens an interactive mode where you can:
- Inspect element IDs and text
- Build flows interactively
- Test element selectors
- Debug flow issues

## Documentation

**Comprehensive Guide:** [`docs/MAESTRO_UI_TESTING.md`](../docs/MAESTRO_UI_TESTING.md)

Covers:
- Complete setup instructions
- Detailed flow documentation
- Observability integration
- CI/CD configuration
- Agent workflows
- Troubleshooting

**API Documentation:** [`agentic-workflow/docs/API.md`](../agentic-workflow/docs/API.md#maestro-ui-testing)

## Support

For issues:
1. Check logs in `.build/maestro-results/`
2. View screenshots in `.maestro/screenshots/`
3. Run `maestro studio` for interactive debugging
4. Review documentation: `docs/MAESTRO_UI_TESTING.md`
5. Check API health: `curl http://localhost:3000/api/maestro/health`

---

**Last Updated:** 2025-11-04
**Integration Status:** ✅ Fully integrated with agentic observability stack
