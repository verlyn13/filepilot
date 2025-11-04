# Maestro UI Testing Integration

**For AI Agents & Human Developers**
**Last Updated:** 2025-11-04
**Status:** Fully Integrated with Observability

---

## 🎯 Overview

This document describes the complete integration of Maestro mobile UI testing framework into the FilePilot agentic development workflow. All test executions are tracked, analyzed, and made queryable for AI-assisted development.

---

## 📋 Table of Contents

1. [Architecture](#architecture)
2. [Setup & Installation](#setup--installation)
3. [Test Flows](#test-flows)
4. [Running Tests](#running-tests)
5. [Observability Integration](#observability-integration)
6. [CI/CD Integration](#cicd-integration)
7. [Agent Workflows](#agent-workflows)
8. [Troubleshooting](#troubleshooting)

---

## Architecture

### Components

```
┌──────────────────┐
│  FilePilot App   │
│   (macOS)        │
└────────┬─────────┘
         │
         │ UI Testing
         ▼
┌──────────────────────────┐
│  Maestro CLI             │
│  - Executes flows        │
│  - Captures screenshots  │
│  - Generates results     │
└──────────┬───────────────┘
           │
           │ Telemetry
           ▼
┌──────────────────────────┐
│ TypeScript Backend       │
│ /api/maestro/*           │
│ MaestroRouter            │
└──────────┬───────────────┘
           │
           │ OpenTelemetry
           ▼
┌──────────────────────────┐
│ Observability Stack      │
│ - Prometheus             │
│ - Grafana                │
│ - Jaeger                 │
└──────────────────────────┘
```

### Data Flow

1. **Test Execution** → Maestro runs UI flows on FilePilot app
2. **Screenshot Capture** → Visual artifacts saved to `.maestro/screenshots/`
3. **Results Generation** → JUnit XML results in `.build/maestro-results/`
4. **Telemetry Events** → Sent to TypeScript backend
5. **Metrics Export** → OpenTelemetry → Prometheus/Jaeger
6. **Agent Analysis** → AI analyzes failures and recommends fixes

---

## Setup & Installation

### Prerequisites

- macOS with Xcode installed
- Homebrew package manager
- FilePilot app built and ready to test

### Installation

#### Option 1: Automated Setup

```bash
./scripts/maestro/install-maestro.sh
```

This script:
- Installs Maestro CLI
- Installs Facebook IDB (optional, for iOS simulator control)
- Verifies installation
- Sends telemetry to observability backend

#### Option 2: Manual Setup

```bash
# Install Maestro
curl -Ls "https://get.maestro.mobile.dev" | bash

# Install IDB (optional)
brew tap facebook/fb
brew install facebook/fb/idb-companion

# Verify
maestro --version
```

### Directory Structure

```
.maestro/
├── flows/                    # Test flow definitions
│   ├── 01_smoke_test.yaml
│   ├── 02_navigation_test.yaml
│   ├── 03_view_modes_test.yaml
│   ├── 04_git_panel_test.yaml
│   ├── 05_inspector_panel_test.yaml
│   └── 06_filter_panel_test.yaml
├── subflows/                 # Reusable subflows
│   └── common_actions.yaml
├── screenshots/              # Test screenshots (generated)
└── baselines/                # Baseline screenshots for comparison

.build/maestro-results/       # Test results (generated)
├── *_result.xml              # JUnit XML results
├── *.log                     # Test execution logs
└── agent-analysis.json       # Agent analysis results
```

---

## Test Flows

### Available Flows

#### 01_smoke_test.yaml
**Purpose:** Verify app launches and basic UI elements are present
**Duration:** ~10 seconds
**Agent Note:** First test to run - if this fails, investigate app bundle or simulator issues

**Coverage:**
- App launches successfully
- Main window visible
- Navigation controls present
- Toolbar visible

#### 02_navigation_test.yaml
**Purpose:** Test back/forward/up navigation functionality
**Duration:** ~30 seconds
**Agent Note:** If this fails, check navigation history implementation

**Coverage:**
- Navigate into folders
- Back navigation
- Forward navigation
- Up navigation

#### 03_view_modes_test.yaml
**Purpose:** Test switching between list, grid, and column views
**Duration:** ~40 seconds
**Agent Note:** Tests both UI and keyboard shortcuts (Cmd+1/2/3)

**Coverage:**
- List view mode
- Grid view mode
- Column view mode
- Keyboard shortcut switching

#### 04_git_panel_test.yaml
**Purpose:** Test Git status panel toggle and visibility
**Duration:** ~20 seconds
**Agent Note:** Requires test directory to be a git repository

**Coverage:**
- Git panel toggle
- Git status display
- Panel visibility states

#### 05_inspector_panel_test.yaml
**Purpose:** Test inspector panel toggle and file info display
**Duration:** ~25 seconds
**Agent Note:** Checks file metadata retrieval

**Coverage:**
- File selection
- Inspector panel toggle
- File metadata display (size, dates)

#### 06_filter_panel_test.yaml
**Purpose:** Test filter panel functionality
**Duration:** ~30 seconds
**Agent Note:** Validates file filtering logic

**Coverage:**
- Filter panel toggle
- Text filtering
- Filter clearing

---

## Running Tests

### Local Execution

#### Run Specific Test Suite

```bash
# Smoke test only
./scripts/maestro/run-maestro-tests.sh smoke

# Navigation tests
./scripts/maestro/run-maestro-tests.sh navigation

# All tests
./scripts/maestro/run-maestro-tests.sh all
```

#### Run Single Flow

```bash
maestro test .maestro/flows/01_smoke_test.yaml
```

#### Interactive Mode (Maestro Studio)

```bash
maestro studio
```

This opens an interactive UI inspector where you can:
- Inspect element IDs and text
- Build flows interactively
- Test element selectors
- Debug flow issues

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PROJECT_ROOT` | Project root directory | Auto-detected |
| `TELEMETRY_ENDPOINT` | Telemetry API endpoint | `http://localhost:3000/api/maestro/telemetry` |
| `TRACE_ID` | Trace correlation ID | Auto-generated UUID |

Example:
```bash
export TRACE_ID=my-custom-trace
./scripts/maestro/run-maestro-tests.sh all
```

---

## Observability Integration

### Telemetry Events

All test executions send structured telemetry events to the TypeScript backend.

#### Event Types

1. **maestro_test_started**
```json
{
  "event": "maestro_test_started",
  "metadata": {
    "suite": "smoke",
    "flow_count": 6,
    "trace_id": "UUID"
  },
  "timestamp": "2025-11-04T12:00:00Z"
}
```

2. **maestro_flow_passed**
```json
{
  "event": "maestro_flow_passed",
  "metadata": {
    "flow": "01_smoke_test",
    "duration": 12,
    "screenshots": 3
  },
  "timestamp": "2025-11-04T12:00:15Z"
}
```

3. **maestro_flow_failed**
```json
{
  "event": "maestro_flow_failed",
  "metadata": {
    "flow": "02_navigation_test",
    "duration": 8,
    "error": "Element not found: navigation-back-button"
  },
  "timestamp": "2025-11-04T12:00:25Z"
}
```

4. **maestro_test_completed**
```json
{
  "event": "maestro_test_completed",
  "metadata": {
    "suite": "all",
    "total": 6,
    "passed": 5,
    "failed": 1,
    "duration": 180
  },
  "timestamp": "2025-11-04T12:03:00Z"
}
```

### API Endpoints

#### GET /api/maestro/health
Check Maestro integration health.

```bash
curl -s http://localhost:3000/api/maestro/health | jq
```

**Response:**
```json
{
  "healthy": true,
  "maestro_integration": "operational",
  "recent_test_count": 10,
  "has_recent_tests": true,
  "timestamp": "2025-11-04T12:00:00Z"
}
```

#### GET /api/maestro/tests/latest
Get latest test results.

```bash
curl -s "http://localhost:3000/api/maestro/tests/latest?limit=5" | jq
```

**Response:**
```json
{
  "results": [
    {
      "trace_id": "UUID",
      "suite": "smoke",
      "event": "maestro_test_completed",
      "metadata": {
        "total": 6,
        "passed": 6,
        "failed": 0
      },
      "timestamp": "2025-11-04T12:00:00Z"
    }
  ],
  "count": 1,
  "timestamp": "2025-11-04T12:00:00Z"
}
```

#### GET /api/maestro/stats
Get test statistics.

```bash
curl -s http://localhost:3000/api/maestro/stats | jq
```

**Response:**
```json
{
  "summary": {
    "total_runs": 25,
    "passed_runs": 23,
    "failed_runs": 2,
    "pass_rate": "92.00"
  },
  "flows": {
    "total": 150,
    "passed": 145,
    "failed": 5,
    "pass_rate": "96.67"
  },
  "flow_details": {
    "01_smoke_test": {
      "passed": 25,
      "failed": 0,
      "avgDuration": 11.5
    }
  },
  "timestamp": "2025-11-04T12:00:00Z"
}
```

#### GET /api/maestro/trace/:traceId
Get all test events for a trace.

```bash
curl -s http://localhost:3000/api/maestro/trace/UUID | jq
```

---

## CI/CD Integration

### GitHub Actions Workflow

The `.github/workflows/maestro-ui-tests.yml` workflow runs automatically on:
- Pull requests to `main`
- Pushes to `main`
- Manual workflow dispatch

**What it does:**
1. Sets up macOS runner with Xcode
2. Installs Maestro CLI
3. Builds FilePilot app
4. Starts observability backend (optional)
5. Runs Maestro tests
6. Uploads test results and screenshots as artifacts
7. Comments on PR with test results
8. Fails build if tests fail

**Triggering manually:**
```bash
# Via GitHub UI: Actions → Maestro UI Tests → Run workflow
# Select test suite (smoke, all, etc.)
```

**Viewing results:**
- Check "Actions" tab in GitHub
- Download artifacts (test results, screenshots, logs)
- View PR comment with summary

### Maestro Cloud (Optional)

For testing on real devices:

```bash
# Upload flows to Maestro Cloud
maestro cloud --apiKey=$MAESTRO_CLOUD_API_KEY .maestro/flows/
```

Requires `MAESTRO_CLOUD_API_KEY` secret in GitHub.

---

## Agent Workflows

### Pre-Test Checks

Agents should verify environment before running tests:

```bash
# Check Maestro installed
which maestro && maestro --version

# Check app built
ls FilePilot/.build/Debug/FilePilot.app

# Check observability backend running
curl -sf http://localhost:3000/health
```

### Running Tests

```bash
# Generate trace ID for correlation
TRACE_ID=$(uuidgen)

# Run tests
TRACE_ID=$TRACE_ID ./scripts/maestro/run-maestro-tests.sh smoke

# Analyze results
./scripts/maestro/agent-test-analyzer.sh
```

### Analyzing Failures

When tests fail, the agent analyzer provides recommendations:

```bash
./scripts/maestro/agent-test-analyzer.sh .build/maestro-results
```

**Output:**
- Identifies failure patterns (element not found, timeout, etc.)
- Provides actionable recommendations
- Generates `agent-analysis.json` with structured data
- Records decision to telemetry

**Agent Decision Tree:**
```
Test failed?
  YES → Run agent-test-analyzer.sh
    → Element not found?
        → Use maestro studio to inspect UI
        → Update flow YAML with correct selectors
    → Timeout?
        → Add wait conditions or optimize app
    → Visual regression?
        → Review screenshots, update baselines if intentional
    → Unknown?
        → Manual investigation required
  NO → All passed, record success
```

### Recording Decisions

```bash
# Record test analysis decision
curl -X POST http://localhost:3000/api/agent/decision \
  -H "x-trace-id: $TRACE_ID" \
  -d '{
    "agent": "claude-code-cli",
    "action": "maestro_test_analysis",
    "context": "Analyzed UI test failures",
    "result": "success",
    "metadata": {"flows_analyzed": 6}
  }'
```

---

## Troubleshooting

### Maestro not installed

```bash
./scripts/maestro/install-maestro.sh
```

### App bundle not found

```bash
# Build FilePilot
cd FilePilot
xcodebuild -scheme FilePilot -configuration Debug build
```

### Element not found errors

```bash
# Use interactive mode to inspect UI
maestro studio

# Update flow YAML with correct element IDs
```

### Tests timing out

```bash
# Add wait conditions in flow YAML
- wait:
    timeout: 10000
- tapOn: "button"
```

### Screenshots not generated

```bash
# Ensure screenshots directory exists
mkdir -p .maestro/screenshots

# Check permissions
ls -la .maestro/screenshots
```

### Telemetry not working

```bash
# Check TypeScript server running
curl http://localhost:3000/health

# Start if needed
cd agentic-workflow
bun run dev
```

---

## Best Practices

### For Test Flows

1. **Use descriptive names** - `01_smoke_test.yaml`, not `test1.yaml`
2. **Add comments** - Explain what each flow tests and why
3. **Use `optional: true`** - For elements that might not always be present
4. **Take screenshots** - Capture visual state for debugging
5. **Keep flows focused** - One feature per flow

### For Agents

1. **Always run smoke test first** - Catch basic issues early
2. **Use trace correlation** - Track test runs end-to-end
3. **Analyze failures immediately** - Use agent-test-analyzer.sh
4. **Update baselines** - When UI changes are intentional
5. **Record decisions** - Track all analysis in telemetry

### For CI/CD

1. **Run smoke tests on every PR** - Fast feedback
2. **Run full suite on merge** - Comprehensive coverage
3. **Upload artifacts** - Screenshots and logs for debugging
4. **Comment on PRs** - Auto-report results to developers
5. **Fail fast** - Block merge if critical tests fail

---

## Integration with Other Systems

### Xcode CLI Integration

Maestro tests run after Xcode builds:

```bash
# Build → Test workflow
./scripts/xcodebuild-wrapper.sh build
./scripts/maestro/run-maestro-tests.sh smoke
```

### Swift Monitoring Integration

Test results feed into Swift metrics:

```bash
# Query combined metrics
curl http://localhost:3000/api/swift/metrics
curl http://localhost:3000/api/maestro/stats
```

### Trace Correlation

All tests share trace IDs with build/test operations:

```bash
# Use same trace ID across systems
TRACE_ID=$(uuidgen)
TRACE_ID=$TRACE_ID ./scripts/xcodebuild-wrapper.sh build
TRACE_ID=$TRACE_ID ./scripts/maestro/run-maestro-tests.sh all

# Query entire workflow in Jaeger
# http://localhost:16686 → search for $TRACE_ID
```

---

## Related Documentation

- **Xcode CLI Integration**: `docs/XCODE_CLI_OBSERVABILITY.md`
- **Architecture Map**: `ARCHITECTURE_MAP.yaml`
- **Agentic Standards**: `.claude/AGENTIC_STANDARDS.md`
- **API Documentation**: `agentic-workflow/docs/API.md`
- **Observability Guide**: `agentic-workflow/docs/OBSERVABILITY.md`

---

## Support

For issues or questions:
1. Check this documentation
2. Review test logs in `.build/maestro-results/`
3. Run `maestro studio` for interactive debugging
4. Check API health: `curl http://localhost:3000/api/maestro/health`
5. Review traces in Jaeger: http://localhost:16686

---

**Last Updated:** 2025-11-04
**Maintained By:** Agentic Development Team
**Version:** 1.0.0
