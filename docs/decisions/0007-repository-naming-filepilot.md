# ADR-0007: Repository Naming - `filepilot`

**Status**: Accepted  
**Date**: 2025-11-04  
**Deciders**: claude-code-cli, verlyn13  
**Repository**: git@github.com:verlyn13/filepilot.git

## Context

The project was initially in a directory named `myfiles` with the repository configured as `git@github.com:verlyn13/myfiles.git`. However:

1. The primary application is named **FilePilot** (Swift macOS file manager)
2. The repository name `myfiles` is generic and doesn't reflect the project identity
3. GitHub repository naming best practices favor descriptive, lowercase names
4. The architecture defines this as "FilePilot + Agentic Workflow" integrated system

### Naming Considerations

**Discussed Options:**
- `myfiles` - Generic, current directory name
- `FilePilot` - Exact app name, mixed case
- `filepilot` - Lowercase variant, GitHub convention
- Split repos - Separate FilePilot and agentic-workflow

### Goals

- Clear project identity in repository name
- Follow GitHub naming conventions
- Maintain monorepo structure (critical for architecture)
- Professional and searchable repository name

## Decision

**Rename repository to `filepilot` (lowercase)**

### Rationale

1. **Clear Identity**: "FilePilot" is the primary user-facing product
2. **GitHub Convention**: Lowercase repository names are standard practice
3. **Professional**: More descriptive than generic "myfiles"
4. **Monorepo Maintained**: Keep integrated structure (Swift app + observability infrastructure)
5. **Searchability**: Easy to find and reference

### Why Monorepo (Not Split)

**Keep integrated because:**
- ✅ Architecture defines this as a unified system
- ✅ Agentic workflow is essential infrastructure, not standalone product
- ✅ Observability tightly coupled to FilePilot
- ✅ Single source of truth (ARCHITECTURE_MAP.yaml)
- ✅ Unified versioning and releases
- ✅ Atomic commits across full stack
- ✅ Agentic sessions work on both components
- ✅ Integrated testing and deployment

**Repository Structure** (no changes to files):
```
filepilot/                     ← Repository name
├── FilePilot/                 ← Swift app source (name unchanged)
├── FilePilot.xcodeproj/       ← Xcode project
├── agentic-workflow/          ← TypeScript observability backend
├── docs/                      ← Documentation
├── scripts/                   ← Automation
├── .claude/                   ← Agent configuration
└── ARCHITECTURE_MAP.yaml      ← Single source of truth
```

## Consequences

### Positive

- ✅ Repository name clearly identifies the project
- ✅ Follows GitHub naming conventions (lowercase)
- ✅ Professional and searchable
- ✅ Maintains architectural integrity (monorepo)
- ✅ Simple one-word name
- ✅ Aligns with project identity

### Negative

- Repository name doesn't exactly match folder casing (`filepilot` vs `FilePilot/`)
- One-time migration effort (minimal)

### Neutral

- No impact on file structure
- No impact on development workflow
- No impact on architecture

## Implementation

### Changes Made

1. **Remote URL Updated**:
   ```bash
   git remote set-url origin git@github.com:verlyn13/filepilot.git
   ```

2. **ARCHITECTURE_MAP.yaml Updated**:
   ```yaml
   repository: "git@github.com:verlyn13/filepilot.git"
   ```

3. **Commit Amended**:
   ```bash
   git commit --amend --no-edit
   ```

4. **Repository Created on GitHub**:
   - Name: `filepilot`
   - URL: https://github.com/verlyn13/filepilot
   - Description: "A project idea for a sane proper file manager in MacOS"

5. **Pushed Successfully**:
   ```bash
   git push -u origin main
   # Result: 03e702b..main
   ```

### Files Modified

- `ARCHITECTURE_MAP.yaml` line 15: Repository URL updated

### Verification

```bash
# Verify remote
git remote -v
# origin  git@github.com:verlyn13/filepilot.git (fetch)
# origin  git@github.com:verlyn13/filepilot.git (push)

# Verify repository
gh repo view verlyn13/filepilot
# ✓ Repository accessible
```

## Migration Notes

### For Future Clones

```bash
git clone git@github.com:verlyn13/filepilot.git
cd filepilot  # Directory will be named "filepilot"
```

### For Existing Clones

If anyone has existing clones of `myfiles`:
```bash
git remote set-url origin git@github.com:verlyn13/filepilot.git
git fetch origin
git branch --set-upstream-to=origin/main main
```

## References

- ARCHITECTURE_MAP.yaml: Project metadata and repository URL
- docs/GIT_WORKFLOW.md: Git workflow standards
- GitHub naming conventions: https://docs.github.com/en/repositories
- Repository: https://github.com/verlyn13/filepilot

## Related Decisions

- ADR-0002: Architecture Map as Single Source of Truth
- ADR-0006: Git Workflow Integration
- Monorepo pattern: Maintaining integrated system architecture

## Notes

**Repository Naming Philosophy:**
- **Primary identifier**: `filepilot` (repository name)
- **Application name**: FilePilot (user-facing brand)
- **Directory structure**: Flexible, focused on organization

The repository name is the public identifier for the project, while internal directory structure serves organizational purposes. This separation allows for clarity in both contexts.

**No file structure changes required** - only repository metadata updated.

---

**Updated**: 2025-11-04  
**Author**: claude-code-cli  
**Status**: Implemented and active  
**Repository**: https://github.com/verlyn13/filepilot
