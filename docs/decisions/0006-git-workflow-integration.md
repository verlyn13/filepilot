# ADR-0006: Git Workflow Integration into Agentic Development

**Status**: Accepted  
**Date**: 2025-11-04  
**Deciders**: claude-code-cli, development team  
**Trace ID**: git-workflow-$(date +%s)

## Context

FilePilot + Agentic Workflow repository had no defined Git workflow integrated with our agentic development process. This led to:

- No remote repository configured
- Inconsistent commit practices
- No version control integration in agent sessions
- Unclear branching strategy
- No commit message standards

### Goals

- Integrate Git into every agent development session
- Define clear commit and branching standards
- Enable automated telemetry of Git operations
- Support both AI agents and human developers
- Maintain clean, semantic commit history

### Requirements

From ARCHITECTURE_MAP.yaml and AGENTIC_STANDARDS.md:
- Observable by default (all Git operations logged)
- Agent-first development (agents must handle Git)
- Documentation as code (all decisions recorded)
- Traceability (commits linked to trace IDs)

## Decision

**Adopt Trunk-Based Development with Agentic Git Integration**

### Core Principles

1. **Main Branch**: Always stable, protected, deployable
2. **Feature Branches**: For complex/experimental work only
3. **Conventional Commits**: Semantic commit messages
4. **AI Attribution**: All agent commits clearly marked
5. **Observability**: All Git operations recorded via telemetry

### Workflow Components

#### 1. Session Start Protocol

```bash
# Added to context-init.sh
git_checks() {
  echo "🔍 Checking Git status..."
  
  # Check remote connectivity
  if ! git ls-remote origin > /dev/null 2>&1; then
    echo "⚠️  Cannot reach remote repository"
  fi
  
  # Check for uncommitted changes
  if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  Uncommitted changes detected"
    git status --short | head -10
  fi
  
  # Show current branch
  echo "📍 Branch: $(git branch --show-current)"
}
```

#### 2. Commit Message Format

```
<type>[optional scope]: <description>

[optional body with details]

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

**Types**: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert

#### 3. Git Integration Points

**Before Changes**:
- Check git status
- Verify clean state or explicit continuation
- Pull latest from remote

**During Changes**:
- Stage files incrementally
- Review diffs before committing

**After Changes**:
- Create semantic commit
- Record via telemetry API
- Push to remote

## Consequences

### Positive

- ✅ Version control integrated into agent workflow
- ✅ Clear commit history with semantic messages
- ✅ AI-generated commits clearly attributed
- ✅ Traceability through telemetry
- ✅ Remote repository backup
- ✅ Collaboration-ready (PR process defined)
- ✅ Supports both agents and humans

### Negative

- Requires agents to handle Git operations
- Additional session startup checks
- Commit message overhead (attribution, formatting)

### Neutral

- Learning curve for commit conventions
- Requires documentation maintenance

## Implementation

### Files Created

1. **docs/GIT_WORKFLOW.md**: Comprehensive workflow guide
2. **ADR-0006**: This decision record
3. **.gitignore**: Comprehensive ignore patterns

### Git Configuration

```bash
# Remote configured
git remote add origin git@github.com:verlyn13/myfiles.git

# User configuration (already set)
git config user.name "Verlyn"
git config user.email "verlyn13@gmail.com"
```

### context-init.sh Updates

Added git status checks:
- Remote connectivity
- Uncommitted changes warning
- Current branch display
- Ahead/behind tracking

### Integration with Observability

```typescript
// Example telemetry for Git operations
POST /api/agent/decision
{
  "agent": "claude-code-cli",
  "action": "git_commit",
  "context": "Committed documentation and workflow updates",
  "result": "success",
  "trace_id": "git-workflow-1730742000",
  "metadata": {
    "commit_hash": "abc123",
    "files_changed": 10,
    "branch": "main",
    "commit_type": "docs"
  }
}
```

## Validation

### Checklist

- [x] Remote repository configured
- [x] .gitignore comprehensive
- [x] Documentation complete
- [x] Commit standards defined
- [x] Branch strategy documented
- [x] PR process defined
- [x] Integration with observability
- [x] Security guidelines included

### Testing

```bash
# Test remote connectivity
git ls-remote origin

# Test commit format
git log --oneline -1

# Verify .gitignore works
git status --ignored
```

## Migration Guide

### For Existing Work

1. Stage all current work: `git add -A`
2. Create comprehensive commit following new standards
3. Push to remote: `git push -u origin main`
4. Verify on GitHub

### For Future Work

1. Follow session start protocol (context-init.sh)
2. Use conventional commit format
3. Record Git operations via telemetry
4. Keep commits atomic and focused

## References

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Trunk-Based Development](https://trunkbaseddevelopment.com/)
- docs/GIT_WORKFLOW.md: Detailed workflow guide
- ARCHITECTURE_MAP.yaml: Git integration specifications
- .claude/AGENTIC_STANDARDS.md: Agent workflows

## Related Decisions

- ADR-0001: Architecture Map as Single Source of Truth
- ADR-0002: OrbStack Container Runtime
- ADR-0003: Agentic Development Standards

## Notes

This decision establishes Git as a first-class citizen in our agentic development workflow. All agents working on this project must:

1. Check Git status at session start
2. Follow commit message conventions
3. Record Git operations via telemetry
4. Maintain clean commit history
5. Handle merge conflicts appropriately

**Review Date**: 2025-12-04 (monthly review)

---

**Updated**: 2025-11-04  
**Author**: claude-code-cli  
**Status**: Active, implemented
