# Development Cycle Command

Start the complete agentic development environment with full observability and documentation validation.

## What this does:

1. **Validates Documentation**
   - Checks all documentation is up to date
   - Validates cross-references
   - Ensures schema compliance

2. **Starts TypeScript Monitoring Server**
   - Express server on port 3000
   - API endpoints for Swift monitoring
   - OpenTelemetry integration

3. **Monitors Swift Development**
   - File watching for auto-rebuild
   - Build status tracking
   - Test result collection
   - Performance metrics

4. **Maintains Observability**
   - Prometheus metrics export
   - Grafana dashboards
   - Jaeger tracing
   - Real-time telemetry

## Implementation:

```bash
#!/bin/bash
set -e

echo "🚀 Starting Agentic Development Environment"

# Validate documentation
echo "📚 Validating documentation..."
./scripts/validate-docs.sh || exit 1

# Start TypeScript monitoring in background
echo "🔧 Starting TypeScript monitoring server..."
cd agentic-workflow && npm run dev &
TS_PID=$!

# Wait for server to be ready
echo "⏳ Waiting for server..."
sleep 5

# Check health
echo "❤️ Checking server health..."
curl -f http://localhost:3000/health || echo "Server not ready yet"

# Start Swift file watcher
echo "👁️ Starting Swift file watcher..."
make watch-swift &
SWIFT_PID=$!

# Show status
echo ""
echo "✅ Agentic Development Environment Ready!"
echo ""
echo "📊 Monitoring URLs:"
echo "  - Health: http://localhost:3000/health"
echo "  - Metrics: http://localhost:3000/metrics"
echo "  - Swift Build: http://localhost:3000/api/swift/build/status"
echo "  - Swift Tests: http://localhost:3000/api/swift/tests"
echo "  - Grafana: http://localhost:3001"
echo ""
echo "📚 Documentation:"
echo "  - Index: DOCUMENTATION_INDEX.md"
echo "  - API: agentic-workflow/docs/API.md"
echo ""
echo "Press Ctrl+C to stop all services"

# Wait for interrupt
trap "kill $TS_PID $SWIFT_PID; exit" INT
wait
```

## Agent Behavior:

When this command is run, the agent should:
1. Monitor all active processes
2. Keep documentation synchronized
3. Suggest improvements based on telemetry
4. Alert on build failures or test regressions
5. Maintain cross-references automatically