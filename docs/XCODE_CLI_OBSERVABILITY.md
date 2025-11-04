# Xcode CLI Observability Integration

**For AI Agents & Human Developers**
**Last Updated:** 2025-11-04
**Status:** Operational

---

## 🎯 Overview

This document describes the complete integration of Xcode CLI commands with the agentic development observability system. All Xcode development activities are tracked, traced, and made queryable for AI-assisted development.

---

## 📋 Table of Contents

1. [Architecture](#architecture)
2. [Available Commands](#available-commands)
3. [Telemetry Integration](#telemetry-integration)
4. [API Endpoints](#api-endpoints)
5. [Usage Examples](#usage-examples)
6. [Agentic Workflows](#agentic-workflows)
7. [Troubleshooting](#troubleshooting)

---

## Architecture

### Components

```
┌─────────────────┐
│  Xcode CLI      │
│  xcodebuild     │
└────────┬────────┘
         │
         │ wrapped by
         ▼
┌─────────────────────────┐
│ xcodebuild-wrapper.sh   │
│ - Captures all output   │
│ - Sends telemetry       │
│ - Creates result bundles│
└──────────┬──────────────┘
           │
           │ HTTP POST
           ▼
┌──────────────────────────┐
│ TypeScript Backend       │
│ /api/swift/telemetry     │
│ SwiftMonitorService      │
└──────────┬───────────────┘
           │
           │ OpenTelemetry
           ▼
┌──────────────────────────┐
│ Observability Stack      │
│ - Prometheus             │
│ - Grafana                │
│ - Jaeger                 │
│ - Loki                   │
└──────────────────────────┘
```

### Data Flow

1. **Xcode CLI Command** → Wrapped script captures all output
2. **Build/Test Execution** → Logs saved to `logs/xcode/`
3. **Result Bundles** → Saved to `.build/results/*.xcresult`
4. **Telemetry Events** → Sent to TypeScript backend
5. **OpenTelemetry** → Traces/metrics exported to observability stack
6. **Agent Queries** → Can query build status via API

---

## Available Commands

### Xcodebuild Wrapper Script

Location: `scripts/xcodebuild-wrapper.sh`

#### Check Xcode Installation

```bash
./scripts/xcodebuild-wrapper.sh check
```

Checks:
- Xcode version
- Xcode installation path
- Available SDK versions
- Sends version info to telemetry

#### List Project Information

```bash
./scripts/xcodebuild-wrapper.sh list [project]
```

Shows:
- Available schemes
- Available targets
- Build configurations

Default project: `FilePilot.xcodeproj`

#### Show Build Settings

```bash
./scripts/xcodebuild-wrapper.sh settings [project] [scheme]
```

Captures all build settings to log file and sends key settings to telemetry:
- Product name
- Bundle identifier
- Deployment target
- Complete settings saved to `logs/xcode/build-settings-*.txt`

#### Build Project

```bash
./scripts/xcodebuild-wrapper.sh build [project] [scheme] [configuration] [clean]
```

Parameters:
- `project`: Xcode project file (default: `FilePilot.xcodeproj`)
- `scheme`: Build scheme (default: `FilePilot`)
- `configuration`: Build configuration (default: `Debug`)
- `clean`: Clean before build (default: `false`)

Captures:
- Build output to `logs/xcode/build-*.log`
- Result bundle to `.build/results/build-*.xcresult`
- Warnings count
- Errors count
- Build duration
- Success/failure status

Sends telemetry:
- `build_started` - When build begins
- `build_completed` - When build finishes (success or failure)

#### Run Tests

```bash
./scripts/xcodebuild-wrapper.sh test [project] [scheme] [destination]
```

Parameters:
- `project`: Xcode project file (default: `FilePilot.xcodeproj`)
- `scheme`: Test scheme (default: `FilePilot`)
- `destination`: Test destination (default: `platform=macOS`)

Captures:
- Test output to `logs/xcode/test-*.log`
- Result bundle to `.build/results/test-*.xcresult`
- Tests run count
- Tests passed count
- Tests failed count
- Test duration

Sends telemetry:
- `test_started` - When tests begin
- `test_completed` - When tests finish

#### Show Test Destinations

```bash
./scripts/xcodebuild-wrapper.sh destinations [scheme]
```

Lists all available test destinations (simulators, devices).

#### Archive Project

```bash
./scripts/xcodebuild-wrapper.sh archive [project] [scheme] [path]
```

Creates an archive for distribution.

---

## Telemetry Integration

### Telemetry Events

All Xcode CLI operations send structured telemetry events to `http://localhost:3000/api/swift/telemetry`.

#### Event Structure

```json
{
  "event": "build_started|build_completed|test_started|test_completed|...",
  "metadata": {
    "scheme": "FilePilot",
    "configuration": "Debug",
    "duration": 45,
    "warnings": 2,
    "errors": 0,
    "log_file": "/path/to/log",
    "result_bundle": "/path/to/bundle.xcresult"
  },
  "timestamp": "2025-11-04T12:00:00Z",
  "trace_id": "UUID"
}
```

#### Trace Correlation

Every command execution generates a unique `TRACE_ID` (UUID) that:
- Links all related telemetry events
- Appears in all log files
- Can be traced through the entire observability stack
- Enables end-to-end debugging

Set custom trace ID:
```bash
TRACE_ID=my-custom-trace ./scripts/xcodebuild-wrapper.sh build
```

Query trace in Jaeger: http://localhost:16686 (search for `trace.correlation_id`)

---

## API Endpoints

The TypeScript backend (`agentic-workflow`) provides these endpoints for querying Xcode/Swift development status:

### GET /api/swift/health

Check Swift development environment health.

**Response:**
```json
{
  "healthy": true,
  "checks": {
    "xcode": true,
    "swift": true,
    "project": true,
    "swiftlint": false
  },
  "timestamp": "2025-11-04T12:00:00Z"
}
```

### GET /api/swift/build/status

Get current build status.

**Response:**
```json
{
  "status": "success|failed|building|idle",
  "target": "FilePilot",
  "configuration": "Debug",
  "duration": 45,
  "warnings": ["warning messages"],
  "errors": ["error messages"],
  "timestamp": "2025-11-04T12:00:00Z"
}
```

### POST /api/swift/build

Trigger a build programmatically.

**Request:**
```json
{
  "configuration": "Debug",
  "clean": false
}
```

**Response:**
```json
{
  "buildId": "build_1699123456789",
  "status": "started",
  "configuration": "Debug",
  "timestamp": "2025-11-04T12:00:00Z"
}
```

### GET /api/swift/tests/latest

Get latest test results.

**Response:**
```json
{
  "suite": "FilePilotTests",
  "total": 50,
  "passed": 48,
  "failed": 2,
  "skipped": 0,
  "coverage": 82.5,
  "duration": 12,
  "failures": [
    {
      "test": "testFileOperations",
      "message": "Assertion failed",
      "file": "FileTests.swift",
      "line": 42
    }
  ],
  "timestamp": "2025-11-04T12:00:00Z"
}
```

### POST /api/swift/tests/run

Run tests programmatically.

**Request:**
```json
{
  "target": "FilePilotTests"
}
```

### GET /api/swift/metrics

Get code metrics.

**Response:**
```json
{
  "files": 25,
  "lines": 5000,
  "classes": 30,
  "functions": 150,
  "complexity": {
    "average": 4.2,
    "max": 12,
    "distribution": {
      "low": 120,
      "medium": 25,
      "high": 4,
      "critical": 1
    }
  },
  "coverage": 82.5
}
```

### GET /api/swift/logs

Get Xcode build/test logs.

**Query Parameters:**
- `lines`: Number of lines to return (default: 100)
- `filter`: Filter pattern

**Response:**
```json
{
  "logs": [
    "Build status: success",
    "warning: Unused variable 'foo'",
    "..."
  ]
}
```

### POST /api/swift/analyze

Analyze a specific Swift file.

**Request:**
```json
{
  "filePath": "FilePilot/ContentView.swift"
}
```

**Response:**
```json
{
  "path": "FilePilot/ContentView.swift",
  "lines": 150,
  "classes": 2,
  "functions": 8,
  "complexity": 5,
  "hasTests": false,
  "imports": ["SwiftUI", "Foundation"],
  "todos": ["// TODO: Add error handling"]
}
```

### GET /api/swift/files/changes

Get recent file changes.

**Response:**
```json
{
  "changes": [
    {
      "path": "/path/to/file.swift",
      "type": "modified|added|deleted",
      "timestamp": "2025-11-04T12:00:00Z"
    }
  ],
  "count": 5,
  "timestamp": "2025-11-04T12:00:00Z"
}
```

---

## Usage Examples

### For Human Developers

#### Standard Build

```bash
# Debug build
./scripts/xcodebuild-wrapper.sh build

# Release build
./scripts/xcodebuild-wrapper.sh build FilePilot.xcodeproj FilePilot Release

# Clean build
./scripts/xcodebuild-wrapper.sh build FilePilot.xcodeproj FilePilot Debug true
```

#### Running Tests

```bash
# Run all tests
./scripts/xcodebuild-wrapper.sh test

# Run tests with specific destination
./scripts/xcodebuild-wrapper.sh test FilePilot.xcodeproj FilePilot "platform=macOS"
```

#### Checking Status

```bash
# Check Xcode installation
./scripts/xcodebuild-wrapper.sh check

# List project info
./scripts/xcodebuild-wrapper.sh list

# Show build settings
./scripts/xcodebuild-wrapper.sh settings
```

### For AI Agents

#### Pre-Change Checks

```bash
# Check build status before making changes
curl -s http://localhost:3000/api/swift/build/status | jq '.status'

# Check test coverage
curl -s http://localhost:3000/api/swift/tests/latest | jq '.coverage'

# Check code complexity
curl -s http://localhost:3000/api/swift/metrics | jq '.complexity.average'
```

#### Triggering Builds

```bash
# Trigger build via API
curl -X POST http://localhost:3000/api/swift/build \
  -H "Content-Type: application/json" \
  -d '{"configuration": "Debug", "clean": false}'

# Or use wrapper script with trace correlation
TRACE_ID=$(uuidgen)
./scripts/xcodebuild-wrapper.sh build

# Query trace
curl -s "http://localhost:16686/api/traces?traceID=$TRACE_ID"
```

#### Analyzing Code

```bash
# Analyze specific file
curl -X POST http://localhost:3000/api/swift/analyze \
  -H "Content-Type: application/json" \
  -d '{"filePath": "FilePilot/ContentView.swift"}' | jq
```

---

## Agentic Workflows

### Session Start Protocol

Per `.claude/AGENTIC_STANDARDS.md`, agents must:

1. **Check Xcode Environment**
   ```bash
   ./scripts/xcodebuild-wrapper.sh check
   curl -s http://localhost:3000/api/swift/health | jq
   ```

2. **Query Build Status**
   ```bash
   BUILD_STATUS=$(curl -s http://localhost:3000/api/swift/build/status | jq -r '.status')
   if [ "$BUILD_STATUS" = "failed" ]; then
     echo "⚠️ Build is failing - prioritize fixing build before new features"
   fi
   ```

3. **Check Test Coverage**
   ```bash
   COVERAGE=$(curl -s http://localhost:3000/api/swift/tests/latest | jq -r '.coverage')
   if [ $(echo "$COVERAGE < 70" | bc) -eq 1 ]; then
     echo "⚠️ Coverage below 70% - suggest adding tests"
   fi
   ```

### Before Making Code Changes

```bash
# Run full pre-change checks
./scripts/xcode-pre-change-check.sh

# Or manually:
curl -s http://localhost:3000/api/swift/build/status | jq
curl -s http://localhost:3000/api/swift/tests/latest | jq
curl -s http://localhost:3000/api/swift/metrics | jq
```

### After Making Code Changes

```bash
# Trigger build with trace correlation
TRACE_ID=$(uuidgen)
./scripts/xcodebuild-wrapper.sh build

# Record decision
curl -X POST http://localhost:3000/api/agent/decision \
  -H "Content-Type: application/json" \
  -H "x-trace-id: $TRACE_ID" \
  -d '{
    "agent": "claude-code-cli",
    "action": "code_change",
    "context": "Updated ContentView.swift to fix layout issue",
    "result": "success",
    "trace_id": "'$TRACE_ID'",
    "metadata": {"file": "ContentView.swift"}
  }'
```

### Decision Tree

```
Is Xcode installed?
  NO → Alert user, provide installation command
  YES → Continue

Is build passing?
  NO → Prioritize fixing build errors
  YES → Continue

Is test coverage >= 70%?
  NO → Suggest adding tests before new features
  YES → Continue

Is average complexity < 8?
  NO → Recommend refactoring before adding features
  YES → ✅ Ready for development
```

---

## Troubleshooting

### Wrapper Script Issues

#### xcodebuild not found

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Verify installation
xcodebuild -version
```

#### Permission denied

```bash
# Make script executable
chmod +x scripts/xcodebuild-wrapper.sh
```

#### Telemetry endpoint unreachable

```bash
# Check if TypeScript server is running
curl http://localhost:3000/health

# Start server if needed
cd agentic-workflow
bun run dev
```

### Build Issues

#### Build failing with errors

```bash
# Check latest build log
ls -lt logs/xcode/build-*.log | head -1
cat $(ls -t logs/xcode/build-*.log | head -1)

# Check build status via API
curl -s http://localhost:3000/api/swift/build/status | jq
```

#### Result bundles not being created

```bash
# Ensure directory exists
mkdir -p .build/results

# Check permissions
ls -la .build/results
```

### Test Issues

#### Tests not running

```bash
# Check available destinations
./scripts/xcodebuild-wrapper.sh destinations FilePilot

# Try specific destination
./scripts/xcodebuild-wrapper.sh test FilePilot.xcodeproj FilePilot "platform=macOS"
```

#### Test logs not accessible

```bash
# Check log directory
ls -la logs/xcode/

# View latest test log
cat $(ls -t logs/xcode/test-*.log | head -1)
```

### API Issues

#### Endpoints returning errors

```bash
# Check server health
curl -s http://localhost:3000/health | jq

# Check all services
docker ps

# Restart observability stack
cd agentic-workflow/observability
docker compose restart
```

#### Telemetry not being received

```bash
# Test telemetry endpoint directly
curl -X POST http://localhost:3000/api/swift/telemetry \
  -H "Content-Type: application/json" \
  -d '{
    "event": "test",
    "metadata": {"test": true},
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
    "trace_id": "'$(uuidgen)'"
  }'

# Check server logs
tail -f /tmp/agentic-server.log
```

---

## Environment Variables

The xcodebuild wrapper script supports these environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `PROJECT_ROOT` | Project root directory | Auto-detected |
| `TELEMETRY_ENDPOINT` | Telemetry API endpoint | `http://localhost:3000/api/swift/telemetry` |
| `TRACE_ID` | Trace correlation ID | Auto-generated UUID |
| `LOG_DIR` | Log directory | `$PROJECT_ROOT/logs/xcode` |
| `RESULT_BUNDLE_DIR` | Result bundle directory | `$PROJECT_ROOT/.build/results` |

Example:
```bash
export TELEMETRY_ENDPOINT=http://custom:3000/api/telemetry
export LOG_DIR=/custom/logs
./scripts/xcodebuild-wrapper.sh build
```

---

## Integration with Other Systems

### CI/CD Integration

```yaml
# .github/workflows/build.yml
- name: Build with observability
  run: |
    export TRACE_ID=${{ github.run_id }}
    ./scripts/xcodebuild-wrapper.sh build FilePilot.xcodeproj FilePilot Release

- name: Run tests with observability
  run: |
    export TRACE_ID=${{ github.run_id }}
    ./scripts/xcodebuild-wrapper.sh test
```

### Pre-commit Hooks

```bash
# .git/hooks/pre-commit
#!/bin/bash
./scripts/xcodebuild-wrapper.sh build
if [ $? -ne 0 ]; then
  echo "Build failed - fix errors before committing"
  exit 1
fi
```

---

## Related Documentation

- **Architecture Map**: `ARCHITECTURE_MAP.yaml` - System architecture
- **Agentic Standards**: `.claude/AGENTIC_STANDARDS.md` - Agent workflows
- **Session Start**: `.claude/SESSION_START.md` - Session protocol
- **API Documentation**: `agentic-workflow/docs/API.md` - All API endpoints
- **Observability**: `agentic-workflow/docs/OBSERVABILITY.md` - Observability stack

---

## Support

For issues or questions:
1. Check this documentation
2. Review related docs above
3. Check API endpoint health: `curl http://localhost:3000/health`
4. Review logs in `logs/xcode/`
5. Query traces in Jaeger: http://localhost:16686

---

**Last Updated:** 2025-11-04
**Maintained By:** Agentic Development Team
**Version:** 1.0.0
