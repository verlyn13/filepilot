# Integrated Development Plan: FilePilot + Agentic Workflow

## Overview

We're building **FilePilot** (the SwiftUI file manager) using **agentic-workflow** as our intelligent development environment. The TypeScript infrastructure provides observability, metrics, automation, and AI assistance throughout the Swift development process.

## Architecture

```
myfiles/
├── FilePilot.xcodeproj/        # Swift/SwiftUI file manager project
├── FilePilot/                  # Swift source code
│   ├── FilePilotApp.swift
│   ├── Features/
│   ├── Services/
│   └── UIComponents/
├── agentic-workflow/           # TypeScript development infrastructure
│   ├── src/
│   │   ├── features/
│   │   │   ├── swift-monitor/  # Swift build monitoring
│   │   │   ├── xcode-metrics/  # Xcode performance tracking
│   │   │   └── test-tracking/  # Swift test result analysis
│   │   └── workflows/
│   │       ├── swift-build.yaml
│   │       └── swift-test.yaml
│   └── observability/          # Monitoring stack for both projects
└── plan.md                     # Original SwiftUI plan

```

## Development Workflow Integration

### 1. Swift Development Monitoring

The TypeScript app monitors Swift development in real-time:

- **File changes**: FSEvents watches Swift files
- **Build status**: Parse Xcode build logs
- **Test results**: Track XCTest output
- **Performance**: Monitor app performance metrics
- **Git activity**: Track commits and branches

### 2. Metrics Collection

```typescript
// agentic-workflow/src/features/swift-monitor/metrics.ts
export class SwiftMetrics {
  // Track build times
  recordBuildTime(target: string, duration: number)

  // Track test results
  recordTestRun(suite: string, passed: number, failed: number)

  // Track app performance
  recordAppMetrics(cpu: number, memory: number, fps: number)

  // Track code complexity
  recordSwiftComplexity(file: string, complexity: number)
}
```

### 3. Automated Workflows

**Build Automation**:
- Trigger builds on file changes
- Run tests automatically
- Generate documentation
- Create build artifacts

**Quality Checks**:
- SwiftLint integration
- SwiftFormat automation
- Code coverage tracking
- Performance profiling

### 4. AI Assistance

The TypeScript backend provides AI-powered assistance:

```typescript
// API endpoints for Swift development
POST /api/swift/review     // Review Swift code
POST /api/swift/suggest    // Suggest improvements
POST /api/swift/generate   // Generate boilerplate
POST /api/swift/test       // Generate test cases
```

## Implementation Phases

### Phase 1: Foundation (Current)
1. ✅ TypeScript infrastructure ready
2. ⏳ Create Swift project structure
3. ⏳ Connect monitoring systems

### Phase 2: Core Integration
1. Swift build monitoring API
2. Xcode log parsing
3. Real-time metrics dashboard
4. File watcher integration

### Phase 3: Swift App Development
1. FilePilot core features
2. Quick Look integration
3. File operations
4. Git integration

### Phase 4: Advanced Features
1. AI-assisted Swift development
2. Performance optimization
3. Automated testing
4. Documentation generation

## API Design for Swift Monitoring

### Build Status Endpoint
```typescript
GET /api/swift/build/status
{
  "status": "building" | "success" | "failed",
  "target": "FilePilot",
  "duration": 1234,
  "warnings": [],
  "errors": [],
  "timestamp": "2024-11-02T..."
}
```

### Test Results Endpoint
```typescript
GET /api/swift/tests/latest
{
  "suite": "FilePilotTests",
  "total": 50,
  "passed": 48,
  "failed": 2,
  "coverage": 85.3,
  "failures": [...]
}
```

### Code Metrics Endpoint
```typescript
GET /api/swift/metrics
{
  "files": 25,
  "lines": 3500,
  "complexity": {
    "average": 3.2,
    "max": 12
  },
  "coverage": 85.3
}
```

## Observability Stack Adaptation

### Grafana Dashboards
1. **Swift Development Dashboard**:
   - Build success rate
   - Average build time
   - Test pass rate
   - Code coverage trend

2. **App Performance Dashboard**:
   - CPU usage
   - Memory consumption
   - Disk I/O
   - UI responsiveness

### Prometheus Metrics
```yaml
# Swift-specific metrics
swift_build_duration_seconds
swift_test_execution_time_seconds
swift_code_coverage_percent
swift_app_memory_bytes
swift_app_cpu_percent
```

### Logging
- Xcode build logs → Loki
- App runtime logs → Loki
- Test output → Structured logs
- Crash reports → Alert system

## Development Commands

### Makefile Additions
```makefile
# Swift development
swift-build:        # Build Swift project
swift-test:         # Run Swift tests
swift-clean:        # Clean Swift build
swift-lint:         # Run SwiftLint
swift-format:       # Format Swift code
swift-docs:         # Generate Swift docs
swift-monitor:      # Start monitoring

# Integrated commands
dev-swift:          # Start full dev environment
watch-swift:        # Watch and rebuild
profile-swift:      # Performance profiling
```

## File Watching Strategy

```typescript
// Watch Swift files and trigger actions
class SwiftWatcher {
  constructor() {
    this.watchPaths = [
      '../FilePilot/**/*.swift',
      '../FilePilot/**/*.storyboard',
      '../FilePilot/Assets.xcassets/**/*'
    ];
  }

  onFileChange(path: string) {
    // Trigger appropriate action
    if (path.endsWith('.swift')) {
      this.triggerBuild();
      this.runLinter(path);
      this.updateMetrics();
    }
  }
}
```

## Benefits of Integration

1. **Real-time Observability**: See exactly what's happening during Swift development
2. **Automated Workflows**: No manual build/test triggering
3. **Performance Tracking**: Catch performance regressions early
4. **AI Assistance**: Get code suggestions and reviews
5. **Unified Dashboard**: Single place to monitor everything
6. **Historical Data**: Track progress over time
7. **Error Prevention**: Catch issues before they become problems

## Next Steps

1. Create Swift project structure in myfiles root
2. Add Swift monitoring endpoints to TypeScript app
3. Create file watchers for Swift code
4. Set up Xcode build log parsing
5. Create Grafana dashboard for Swift metrics
6. Implement AI code review for Swift
7. Start building FilePilot features

This integrated approach gives us the best of both worlds: a powerful native macOS app with enterprise-grade development tooling and observability.