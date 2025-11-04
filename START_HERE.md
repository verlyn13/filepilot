# 🎯 START HERE - FilePilot Agentic Development

**For AI Agents & Human Developers**

---

## 📍 You Are Here

This is the **FilePilot + Agentic Workflow** project - a Swift macOS file manager with integrated TypeScript observability for AI-assisted development.

---

## 🚀 Quick Start (30 seconds)

```bash
# 1. Ensure container runtime is running (macOS)
# With OrbStack (recommended):
open -a OrbStack
# OR with Docker Desktop:
# open -a Docker && sleep 30

# 2. Start development environment
./scripts/start-dev-environment.sh

# 3. Verify it worked
curl http://localhost:3000/health
```

✅ If you see `{"status":"healthy"}` → You're ready!
❌ If not → See troubleshooting below

> **Note:** We recommend [OrbStack](https://orbstack.dev) for 10× better performance on macOS. See `ORBSTACK_MIGRATION_PLAN.md` for migration details.

---

## 📚 Essential Reading (in order)

1. **`.claude/SESSION_START.md`** - Read FIRST every session
2. **`.claude/STARTUP_GUIDE.md`** - Detailed startup guide
3. **`DOCUMENTATION_INDEX.md`** - Complete documentation map
4. **`agentic-workflow/docs/OBSERVABILITY.md`** - How to query the system

---

## 🎯 For AI Agents

**CRITICAL REQUIREMENTS:**

1. ✅ Read `.claude/SESSION_START.md` at start of EVERY session
2. ✅ Verify container runtime (OrbStack/Docker) is running BEFORE any development
3. ✅ Start development environment BEFORE suggesting code
4. ✅ Query observability endpoints BEFORE making changes
5. ✅ Check build/test status BEFORE suggesting features

**Configuration:**
- Agent behaviors: `.claude/config.yaml`
- Observability endpoints: `agentic-workflow/docs/OBSERVABILITY.md`
- API reference: `agentic-workflow/docs/API.md`

---

## 🛠️ For Human Developers

**Setup:**
```bash
# Install container runtime (choose one)
brew install --cask orbstack     # Recommended: 10× faster on macOS
# OR
# brew install --cask docker      # Alternative: Docker Desktop

# Install other dependencies
brew install bun  # Or use mise/asdf
xcode-select --install

# Start environment
./scripts/start-dev-environment.sh
```

**Access Points:**
- TypeScript Server: http://localhost:3000
- Grafana Dashboards: http://localhost:3001 (admin/admin)
- Prometheus Metrics: http://localhost:9090
- Jaeger Tracing: http://localhost:16686

---

## 🚨 Troubleshooting

### Container runtime not running
```bash
# With OrbStack:
open -a OrbStack

# OR with Docker Desktop:
open -a Docker && sleep 30

# Then restart environment:
./scripts/start-dev-environment.sh
```

### Port conflicts
```bash
lsof -i :3000
kill -9 <PID>
./scripts/start-dev-environment.sh
```

### Full reset
```bash
# Stop everything
pkill -f "tsx watch"
docker compose -f agentic-workflow/observability/docker-compose.yml down

# Restart
./scripts/start-dev-environment.sh
```

### Performance issues
If using Docker Desktop, consider migrating to OrbStack for significant performance improvements:
```bash
# See full migration guide
cat ORBSTACK_MIGRATION_PLAN.md
```

---

## 📁 Project Structure

```
.
├── FilePilot/              # Swift macOS app
├── agentic-workflow/       # TypeScript observability server
│   ├── src/                # Server source code
│   ├── observability/      # Docker compose stack
│   └── docs/               # Documentation
├── .claude/                # AI agent configuration
│   ├── SESSION_START.md    # READ THIS FIRST
│   ├── STARTUP_GUIDE.md    # Detailed startup guide
│   └── config.yaml         # Agent behaviors
├── scripts/                # Automation scripts
│   ├── start-dev-environment.sh  # Main startup script
│   └── validate-docs.sh    # Documentation validation
└── docs/                   # Project documentation
    └── schemas/            # Validation schemas
```

---

## 🎓 Learning Path

**Day 1:**
1. Read this file
2. Read `.claude/SESSION_START.md`
3. Start the environment
4. Explore Grafana dashboards

**Day 2:**
1. Review `agentic-workflow/docs/OBSERVABILITY.md`
2. Learn API endpoints
3. Query metrics with curl
4. Review code examples

**Day 3:**
1. Study `DEVELOPMENT_PRINCIPLES.md`
2. Review existing code
3. Run tests
4. Make first contribution

---

## 🤖 Agent Status

Current agent configuration ensures:
- ✅ Documentation validated before development
- ✅ Observability queried before code changes  
- ✅ Build status checked before suggestions
- ✅ Test coverage verified before commits
- ✅ Code complexity analyzed for refactoring decisions

**Configured in:** `.claude/config.yaml`

---

## 📞 Help & Support

**Documentation Issues?**
- See `DOCUMENTATION_INDEX.md`
- All docs are cross-referenced and validated

**Build/Test Issues?**
- Query: `curl http://localhost:3000/api/swift/build/status`
- Logs: `curl http://localhost:3000/api/swift/logs`

**Observability Issues?**
- See `agentic-workflow/docs/OBSERVABILITY.md#troubleshooting`
- Check Docker: `docker-compose -f agentic-workflow/observability/docker-compose.yml ps`

---

**Last Updated:** 2025-11-03
**Container Runtime:** OrbStack (default context set)
**Docker Context:** orbstack (permanent)
**Observability Status:** ✅ All 7 services operational and verified
**Maintained By:** Agentic Development Team
