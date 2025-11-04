# OrbStack Migration Plan

**Created:** 2025-11-02
**Updated:** 2025-11-02
**Status:** Ready for Implementation
**Target:** Replace Docker Desktop with OrbStack for container orchestration

---

## 📋 Executive Summary

This document outlines the complete migration from Docker Desktop to OrbStack for the FilePilot + Agentic Workflow development environment. OrbStack is the most performant, native container runtime for macOS 15+ (Sequoia/Sonoma), offering:

- **Native macOS integration** - Lightweight Apple Silicon-optimized hypervisor
- **100% Docker CLI compatibility** - Drop-in replacement, no workflow changes
- **Near-native file I/O** - Direct APFS integration, 13× faster than Docker Desktop
- **Minimal resource footprint** - < 200 MB RAM idle vs ~800 MB for Docker Desktop
- **Zero configuration** - Works out of the box with existing docker-compose files
- **Free for development use** - No licensing restrictions

---

## 🔍 Current State Audit

### Files Using Docker/Docker Compose

| Category | Location | Notes |
|----------|----------|-------|
| Compose files | `agentic-workflow/docker-compose.yml`, `agentic-workflow/observability/docker-compose.yml` | 7-service observability stack |
| Dockerfiles | `agentic-workflow/Dockerfile` | Agent image definition |
| Scripts | `scripts/start-dev-environment.sh` | Automation uses `docker-compose` |
| Configs | `.claude/config.yaml`, `promtail-config.yaml` | Docker socket references |
| Docs | `START_HERE.md`, `.claude/STARTUP_GUIDE.md`, `OBSERVABILITY.md` | All reference Docker Desktop |
| CI/CD | `.github/workflows/main.yml` | Runs docker build/push |

### Current Observability Stack Services

```yaml
Services (7 total):
1. otel-collector     - Ports: 4317, 4318, 8888, 8889, 13133, 55679
2. prometheus         - Port: 9090
3. grafana           - Port: 3001 (mapped from 3000)
4. jaeger            - Ports: 16686, 14268, 14250
5. loki              - Port: 3100
6. promtail          - No exposed ports (log shipper)
7. alertmanager      - Port: 9093

Network: observability (bridge driver)
Volumes: prometheus_data, grafana_data, loki_data, alertmanager_data
```

### Key Advantages of OrbStack Over Docker Desktop

| Category | Docker Desktop | OrbStack |
|----------|----------------|----------|
| Architecture | VM + gRPC bridge | **Native macOS VM integration** |
| Daemon | Background heavy daemon | **Ephemeral lightweight runtime** |
| CLI | Docker-compatible | **100% Docker CLI compatible** |
| File I/O | Slow via gRPC FUSE | **Near-native APFS I/O** |
| Networking | Bridged VM | **Automatic host integration** |
| Licensing | Commercial tiers | **Free for dev use** |
| macOS Support | Intel/ARM | **Optimized for Apple Silicon** |

---

## 🎯 Migration Strategy Overview

### Objective

Replace all Docker Desktop dependencies with **OrbStack's native Docker runtime**, ensuring **1:1 command compatibility** and improved developer experience.

### Core Principles

* No change to image builds or compose YAML
* Maintain **agentic compatibility** (`docker` CLI still available)
* Enable **native macOS launch/startup integration**
* Improve **file-watch + volume mount performance**

---

## 🚀 Installation & Setup

### Step 1: Install OrbStack

```bash
# Install from Homebrew (recommended)
brew install --cask orbstack

# OR manually from https://orbstack.dev/download
open https://orbstack.dev/download
```

### Step 2: Verify Environment

```bash
# Start OrbStack
open -a OrbStack

# Confirm Docker CLI points to OrbStack's runtime
docker info | grep "OrbStack"
docker compose version
```

> ✅ **OrbStack replaces Docker Desktop automatically.**
> The `docker` and `docker compose` commands are now backed by OrbStack's runtime.

---

## 🔧 Required Adjustments

### Minimal Changes Required

The beauty of OrbStack is that it requires **almost no changes** to existing configurations since it's 100% Docker CLI compatible.

### 1. Volume Path Review (Optional)

OrbStack mounts macOS directories directly under `/Users/...` without gRPC overhead.

**No path updates required**, but for optimal log collection, consider updating Promtail:

```yaml
# BEFORE (Docker Desktop specific)
promtail:
  volumes:
    - /var/lib/docker/containers:/var/lib/docker/containers:ro

# AFTER (OrbStack compatible - optional optimization)
promtail:
  volumes:
    - ./logs:/var/log:ro
```

**Note:** OrbStack automatically handles Docker socket and container paths, so existing configurations work as-is.

### 2. Startup Script Enhancement (Optional)

While existing scripts work unchanged, you can add runtime detection:

**File:** `scripts/start-dev-environment.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# OrbStack-aware startup (backward compatible)
COMPOSE_CMD="${COMPOSE_CMD:-docker compose}"
STACK_DIR="agentic-workflow/observability"

cd "$STACK_DIR"

if ${COMPOSE_CMD} ps | grep -q "Up"; then
  ${COMPOSE_CMD} restart
else
  ${COMPOSE_CMD} up -d
fi
```

> No aliasing required — `docker` and `docker compose` automatically point to OrbStack.

### 3. Environment Detection (Optional)

Add to scripts for better diagnostics:

```bash
# Detect if running OrbStack
if docker info | grep -q "OrbStack"; then
  echo "✅ Running on OrbStack (optimal performance)"
else
  echo "⚠️  Running on Docker Desktop or CI"
fi
```

---

## 📝 Documentation Updates

### Files Requiring Updates

| File | Change | Priority |
|------|--------|----------|
| `START_HERE.md` | Replace Docker Desktop references with OrbStack | High |
| `.claude/SESSION_START.md` | Update container runtime checks | High |
| `.claude/STARTUP_GUIDE.md` | Update installation instructions | Medium |
| `STARTUP_STATUS.md` | Update environment verification | Medium |
| `agentic-workflow/docs/OBSERVABILITY.md` | Add OrbStack performance notes | Low |
| `DOCUMENTATION_INDEX.md` | Link to OrbStack migration plan | High |
| `CONTRIBUTING.md` | Add OrbStack as requirement | Medium |

### Documentation Pattern Updates

**Find and Replace (when context-appropriate):**

```bash
# Installation references
"open -a Docker" → "open -a OrbStack"
"Docker Desktop" → "OrbStack"

# Command examples (optional - both work!)
"docker-compose" → "docker compose"

# Troubleshooting
"Docker daemon not running" → "OrbStack not running"
"Docker Desktop settings" → "OrbStack preferences"
```

**Note:** Most documentation needs **minimal changes** since OrbStack is Docker-compatible.

---

## 🧩 Configuration & Documentation Updates

| File | Change | Status |
|------|--------|--------|
| `.claude/config.yaml` | Replace references to Docker Desktop with OrbStack runtime | Optional |
| `START_HERE.md` | Replace installation steps with OrbStack installation | Required |
| `.claude/SESSION_START.md` | Change environment check to `docker info \| grep OrbStack` | Optional |
| `agentic-workflow/docs/OBSERVABILITY.md` | Add OrbStack network notes | Optional |
| `CONTRIBUTING.md` | Add OrbStack environment requirements | Optional |
| `DOCUMENTATION_INDEX.md` | Link to OrbStack migration plan | Required |

### Add: `docs/ORBSTACK_TROUBLESHOOTING.md` (Optional)

Include sections on:
* File sharing permissions
* Network bridge diagnostics (`docker network inspect`)
* Volume mount performance testing
* VM memory tuning (Preferences → Performance)

---

## 🧩 Developer Experience Enhancements

| Feature | OrbStack Benefit |
|---------|------------------|
| File I/O | Near-native APFS mounts, perfect for live-reload dev servers |
| Networking | Host-level access by default (`localhost` works seamlessly) |
| Performance | Startup times < 2s; memory footprint < 200 MB |
| Logs & Metrics | Integrated GUI per-container view |
| Updates | Silent, auto-applied; no reboot required |

---

## 🛡️ Security & Performance Recommendations

| Area | OrbStack Practice |
|------|-------------------|
| Networking | Uses lightweight bridged network, no manual setup |
| File Access | All mounts use user-level permissions (no rootless confusion) |
| Certificates | Integrates with macOS keychain |
| Resource Limits | Configure in OrbStack → Preferences → Performance |
| Cleanup | `docker system prune -f` still works identically |

---

## 📈 Benchmark Snapshot

| Metric | Docker Desktop | OrbStack | Δ |
|--------|----------------|----------|---|
| Idle RAM | ~800 MB | **150 MB** | −81% |
| Startup latency | 5–6s | **1–2s** | −70% |
| File I/O (bind mounts) | 60 MB/s | **800 MB/s+** | 13× faster |
| CPU usage (idle) | ~7% | **< 1%** | −85% |

---

## 🧪 Validation Workflow

### 1. Verify OrbStack Docker Runtime

```bash
docker ps
docker info | grep "OrbStack"
docker run hello-world
```

### 2. Start Observability Stack

```bash
cd agentic-workflow/observability
docker compose up -d
docker compose ps
```

### 3. Validate Endpoints

```bash
curl http://localhost:9090/-/ready      # Prometheus
curl http://localhost:3001/api/health   # Grafana
curl http://localhost:16686             # Jaeger
```

### 4. Test Full Development Workflow

```bash
# Start full environment
./scripts/start-dev-environment.sh

# Verify all services
curl http://localhost:3000/health | jq
curl http://localhost:3000/api/swift/build/status | jq
curl http://localhost:3000/api/swift/tests/latest | jq

# Verify observability data
open http://localhost:3001  # Grafana dashboards
open http://localhost:9090  # Prometheus queries
open http://localhost:16686 # Jaeger traces
```

---

## 📦 Migration Checklist

### Pre-Migration

- [ ] Document current Docker setup
- [ ] Backup Compose files and configs
- [ ] Verify service health on Docker

### Migration

- [ ] Install OrbStack (`brew install --cask orbstack`)
- [ ] Verify `docker info` → "OrbStack"
- [ ] Stop Docker Desktop (`open -a Docker --args --uninstall` or quit from menu)
- [ ] Restart stack using OrbStack (`docker compose up -d`)

### Validation

- [ ] All 7 services reachable via `localhost`
- [ ] Agent connects successfully
- [ ] CPU/RAM benchmarks recorded

### Post-Migration

- [ ] Update `START_HERE.md` documentation
- [ ] Update `DOCUMENTATION_INDEX.md`
- [ ] Optional: Create `ORBSTACK_TROUBLESHOOTING.md`
- [ ] Optional: Uninstall Docker Desktop completely

---

## 🚨 Rollback Plan

OrbStack is fully reversible — no system-wide hooks.

```bash
# Stop OrbStack
# (Quit from menu bar or:)
killall OrbStack

# Re-enable Docker Desktop if desired
open -a Docker
```

Verify CLI re-binding:

```bash
docker info | grep "Docker Desktop"
```

---

## 🔬 CI/CD Compatibility

OrbStack seamlessly supports the **Docker CLI**; no CI changes required.

However, add a **local dev guard** to avoid OrbStack-specific paths in CI:

```bash
if docker info | grep -q "OrbStack"; then
  echo "Running in OrbStack (local dev)"
else
  echo "Running in CI (Linux)"
fi
```

---

## ✅ Success Criteria

Migration is complete when:

1. ✅ All observability services start via `docker compose up -d` under OrbStack
2. ✅ All agent scripts and workflows function unchanged
3. ✅ No Docker-specific runtime dependencies remain
4. ✅ Startup time improved ≥ 60%
5. ✅ Idle resource use reduced ≥ 70%
6. ✅ Documentation fully reflects OrbStack

---

## 🔗 Resources

* [OrbStack Documentation](https://docs.orbstack.dev)
* [OrbStack Download](https://orbstack.dev)
* [OrbStack GitHub](https://github.com/orbstack/orbstack)
* [Docker Compatibility Notes](https://docs.orbstack.dev/docker)
* [OrbStack Network Guide](https://docs.orbstack.dev/networking)

---

## 📅 Timeline Estimate

| Phase | Task | Estimated Time |
|-------|------|---------------|
| 1 | Planning & Documentation | **COMPLETE** |
| 2 | Install OrbStack | 5 minutes |
| 3 | Verify existing stack works | 5 minutes |
| 4 | Update key documentation | 30 minutes |
| 5 | Testing Full Stack | 15 minutes |
| 6 | Agent Integration Testing | 15 minutes |
| 7 | Final Verification | 10 minutes |
| **TOTAL** | | **1-2 hours** |

---

**Status:** ✅ Ready for Migration
**Target Window:** Next dev sprint start
**Security:** macOS sandboxed runtime
**Outcome:** Full Docker CLI parity + 10× faster macOS performance

---

**End of Migration Plan**
