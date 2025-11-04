# Agent Context - Agentic Development Environment

**Last Updated:** 2025-11-03
**Container Runtime:** OrbStack (default context)
**Observability Status:** ✅ All 7 services operational

## 🎯 Project Overview
You are working on **FilePilot**, a Swift macOS file manager with an integrated TypeScript observability and development infrastructure. This is an AI-assisted development environment with full observability running on OrbStack for optimal macOS performance.

## 📚 Documentation System
- **Single Source of Truth**: [`DOCUMENTATION_INDEX.md`](../DOCUMENTATION_INDEX.md)
- **Configuration**: [`.claude/config.yaml`](./config.yaml)
- **Cross-References**: [`docs/CROSS_REFERENCE_INDEX.json`](../docs/CROSS_REFERENCE_INDEX.json)
- **Validation**: All docs are schema-validated and cross-referenced

## 🏗️ Architecture
```
myfiles/
├── FilePilot/                    # Swift macOS app
│   ├── FilePilotApp.swift        # Main app with telemetry
│   ├── ContentView.swift         # UI components
│   └── AppState.swift            # State management
├── agentic-workflow/             # TypeScript monitoring
│   ├── src/
│   │   ├── index.ts              # Express server
│   │   └── features/
│   │       └── swift-monitor/    # Swift build monitoring
│   └── observability/            # OpenTelemetry, Prometheus
└── .claude/                      # Agent configuration
    ├── config.yaml               # Main config
    └── agent-context.md          # This file
```

## 🔄 Development Cycle
1. **Planning**: Review `plan.md` and `INTEGRATED_PLAN.md`
2. **Implementation**: Follow `DEVELOPMENT_PRINCIPLES.md`
3. **Testing**: Use API endpoints documented in `API.md`
4. **Monitoring**: Check observability stack

## 📊 Observability Endpoints

### TypeScript Monitoring Server
- Base URL: `http://localhost:3000`
- Health: `/health`
- Metrics: `/metrics`
- Swift Build Status: `/api/swift/build/status`
- Swift Tests: `/api/swift/tests`
- Swift Metrics: `/api/swift/metrics`
- Telemetry: `/api/telemetry`

### Observability Stack (OrbStack)
- **Prometheus:** `http://localhost:9090` - Metrics & queries
- **Grafana:** `http://localhost:3001` - Dashboards (admin/admin)
- **Jaeger:** `http://localhost:16686` - Distributed tracing
- **Loki:** `http://localhost:3100` - Log aggregation
- **OTEL Collector:** `http://localhost:13133/health` - Telemetry collection
- **AlertManager:** `http://localhost:9093` - Alert management
- **Promtail:** Running - Log shipping

**All services verified operational as of 2025-11-03**

## 🛠️ Key Commands
```bash
# Swift Development
make swift-build      # Build Swift project
make swift-test       # Run Swift tests
make swift-monitor    # Monitor Swift metrics

# TypeScript Development
make dev             # Start dev server
make test            # Run all tests
make build           # Build for production

# Integrated Development
make dev-swift       # Full environment with monitoring
```

## ✅ Agent Responsibilities
1. **Maintain Documentation**: Keep all docs updated and cross-referenced
2. **Validate Changes**: Ensure schema compliance
3. **Monitor Build Health**: Track Swift builds and tests
4. **Suggest Improvements**: Proactively identify issues
5. **Track Technical Debt**: Document and prioritize

## 🔍 Current Status Checks
Before making changes:
1. Check `docs/CROSS_REFERENCE_INDEX.json` for document relationships
2. Verify schema validation in `docs/schemas/`
3. Review recent telemetry at `/api/swift/metrics`
4. Check build status at `/api/swift/build/status`

## 📝 Documentation Standards
- All docs must validate against schemas
- Cross-references must be maintained
- Examples required for complex topics
- Maximum heading depth: 4
- Conventional commits required

## 🤖 AI Development Features
- **Code Review**: Automatic security and performance checks
- **Test Generation**: Coverage target 80%
- **Documentation Updates**: Auto-sync with code changes
- **Observability**: Full telemetry integration

## 🚨 Important Notes
- **Container Runtime:** OrbStack is now the default (context: `orbstack`)
  - 10× faster than Docker Desktop on macOS
  - Near-native APFS file I/O performance
  - All `docker` commands automatically use OrbStack
- Swift app sends telemetry to TypeScript backend
- All changes must maintain documentation consistency
- Schema validation runs on every commit
- Cross-references auto-update daily
- **Migration Complete:** See `.backups/orbstack-validation-complete-2025-11-03.md` for details

## 📞 Support Channels
- Documentation Issues: Update `DOCUMENTATION_INDEX.md`
- Build Problems: Check `/api/swift/build/status`
- Test Failures: Review `/api/swift/tests`
- Performance: Monitor at `http://localhost:3001` (Grafana)

---
*This context is automatically loaded for all AI agents working on this project.*