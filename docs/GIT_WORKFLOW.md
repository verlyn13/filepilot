# Git Workflow - Agentic Development

**Status**: Active  
**Last Updated**: 2025-11-04  
**Owner**: Development Team + AI Agents

## Overview

This document defines the Git workflow integrated into our agentic development process. Git operations are part of every development session and must follow these standards.

## Repository Configuration

**Remote**: `git@github.com:verlyn13/myfiles.git`  
**Default Branch**: `main`  
**Strategy**: Trunk-based development with feature branches for complex work

## Agentic Git Integration

### Session Start Git Checks

Every agent session MUST verify:

```bash
# 1. Check git status
git status --porcelain | wc -l  # Should be 0 for clean state

# 2. Check remote connectivity  
git ls-remote origin > /dev/null 2>&1

# 3. Check for uncommitted work
if [ -n "$(git status --porcelain)" ]; then
  echo "⚠️  Uncommitted changes detected"
fi

# 4. Verify on correct branch
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"

# 5. Check if ahead/behind remote
git fetch origin --dry-run
```

### Before Code Changes

```bash
# 1. Ensure clean state or explicit continuation
git status

# 2. Create feature branch if needed (for complex work)
git checkout -b feature/descriptive-name

# 3. Pull latest changes
git pull origin main
```

### After Code Changes

```bash
# 1. Review changes
git status
git diff

# 2. Stage relevant files
git add <files>

# 3. Create descriptive commit (see Commit Standards below)
git commit -m "feat: descriptive message

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# 4. Push to remote
git push origin HEAD
```

## Commit Standards

### Conventional Commits

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Commit Types

| Type | Usage | Example |
|------|-------|---------|
| `feat` | New feature | `feat: add git repository collapsible section` |
| `fix` | Bug fix | `fix: resolve singleton recursive lock crash` |
| `docs` | Documentation only | `docs: add ADR-0004 for singleton pattern` |
| `style` | Code style (formatting, no logic change) | `style: format ContentView.swift` |
| `refactor` | Code refactoring | `refactor: extract view components` |
| `test` | Adding/updating tests | `test: add TelemetryService tests` |
| `chore` | Maintenance tasks | `chore: update dependencies` |
| `perf` | Performance improvement | `perf: optimize file list rendering` |
| `ci` | CI/CD changes | `ci: add GitHub Actions workflow` |
| `build` | Build system changes | `build: update Xcode project settings` |
| `revert` | Revert previous commit | `revert: revert commit abc123` |

### AI-Generated Commits

All commits made by AI agents MUST include:

```
🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Commit Message Examples

**Good**:
```
feat: add collapsible git repository section

- Changed Section to DisclosureGroup
- Added @State for isExpanded
- Collapsed by default per UX requirements

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

**Bad**:
```
update files
```

## Branch Strategy

### Main Branch

- **Protection**: Protected, requires review for direct pushes
- **Quality**: All tests must pass
- **Stability**: Always deployable

### Feature Branches

**Naming**: `feature/descriptive-name`

**Usage**:
- Complex features requiring multiple commits
- Experimental work
- Major refactoring

**Lifecycle**:
1. Create from `main`: `git checkout -b feature/name`
2. Work and commit locally
3. Push to remote: `git push -u origin feature/name`
4. Create pull request when ready
5. Merge to `main` after review
6. Delete branch: `git branch -d feature/name`

### Hotfix Branches

**Naming**: `hotfix/issue-description`

**Usage**:
- Critical production bugs
- Security fixes

**Lifecycle**:
1. Create from `main`: `git checkout -b hotfix/name`
2. Fix and test
3. Commit with `fix:` type
4. Push and create PR
5. Fast-track review and merge
6. Tag release if needed

## Pull Request Process

### Creating PRs (AI Agents)

When AI agent creates a PR:

```bash
# 1. Push feature branch
git push -u origin feature/name

# 2. Use GitHub CLI to create PR
gh pr create --title "feat: descriptive title" --body "$(cat <<'PREOF'
## Summary
- Key change 1
- Key change 2

## Test Plan
- [ ] Tests pass
- [ ] App launches successfully
- [ ] Feature works as expected

## Related
- Closes #123
- Related to ADR-0004

🤖 Generated with Claude Code
PREOF
)"

# 3. Record PR creation
curl -X POST http://localhost:3000/api/agent/decision \
  -H "Content-Type: application/json" \
  -d '{
    "agent": "claude-code-cli",
    "action": "pr_created",
    "context": "Created PR for feature/name",
    "result": "success",
    "metadata": {"pr_number": 123}
  }'
```

### PR Requirements

- [ ] Descriptive title following conventional commits
- [ ] Summary of changes
- [ ] Test plan with checkboxes
- [ ] All tests passing
- [ ] Documentation updated
- [ ] ADR created if architectural change
- [ ] Trace IDs included for observability

## .gitignore Strategy

**Philosophy**: Ignore generated artifacts, commit source truth

**Always Ignore**:
- Build artifacts (`.build/`, `DerivedData/`)
- Dependencies (`node_modules/`, `.swiftpm/`)
- User-specific files (`*.xcuserstate`, `.DS_Store`)
- Secrets (`.env`, `*.pem`, `credentials.json`)
- Logs (`logs/`, `*.log`)
- Temporary files (`tmp/`, `*.tmp`)

**Always Commit**:
- Source code (`.swift`, `.ts`)
- Configuration (`.yaml`, `.json`, `.plist`)
- Documentation (`.md`)
- Tests
- Build configuration (`Package.swift`, `project.pbxproj`)

## Git Hooks (Future)

Planned git hooks for quality:

**Pre-commit**:
- Run SwiftLint
- Run prettier/biome
- Check for secrets
- Validate commit message format

**Pre-push**:
- Run tests
- Check build succeeds
- Verify documentation updates

## Troubleshooting

### Merge Conflicts

```bash
# 1. Pull latest
git pull origin main

# 2. Resolve conflicts in files
# Edit conflicted files, remove markers

# 3. Stage resolved files
git add <resolved-files>

# 4. Complete merge
git commit

# 5. Verify build and tests
xcodebuild build && xcodebuild test
```

### Uncommitted Changes

```bash
# Option 1: Commit them
git add -A
git commit -m "wip: work in progress"

# Option 2: Stash them
git stash push -m "descriptive message"
# ... do other work ...
git stash pop

# Option 3: Discard them (DANGEROUS)
git restore .
```

### Wrong Branch

```bash
# If you committed to wrong branch
git log -1  # Note the commit hash
git reset --hard HEAD~1  # Undo commit
git checkout correct-branch
git cherry-pick <commit-hash>
```

## Integration with Observability

All git operations should be recorded via telemetry:

```typescript
// Record commit
POST /api/agent/decision
{
  "agent": "claude-code-cli",
  "action": "git_commit",
  "context": "Committed fixes for singleton pattern",
  "result": "success",
  "metadata": {
    "commit_hash": "abc123",
    "files_changed": 5,
    "branch": "main"
  }
}
```

## Security Guidelines

### Never Commit

- API keys or tokens
- Private keys (`.pem`, `.key`)
- Passwords or credentials
- `.env` files with secrets
- Personal access tokens
- SSH keys
- Certificates (`.cert`, `.p12`)

### If Secrets Committed

1. **Immediately rotate the secret**
2. Remove from history: `git filter-branch` or `BFG Repo-Cleaner`
3. Force push (with team coordination)
4. Verify secret is invalid
5. Document incident

## References

- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Git Best Practices](https://git-scm.com/book/en/v2)
- ARCHITECTURE_MAP.yaml: Git workflow integration
- ADR-0006: Git Workflow Decision Record

## Agent Responsibilities

### Claude Code CLI

- Follow commit message standards
- Include AI-generated footer
- Create ADRs for architectural changes
- Record decisions via telemetry
- Check git status at session start
- Clean commits (no build artifacts)

### Human Developers

- Review AI-generated commits
- Approve pull requests
- Handle sensitive operations
- Resolve complex merge conflicts
- Manage release tagging

---

**Maintained by**: Development Team  
**Last Review**: 2025-11-04  
**Next Review**: 2025-12-04
