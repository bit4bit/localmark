# BDD Test Migration Plan

## Overview

Migrate existing tests to Test::BDD::Cucumber framework with proper carton-based dependency management.

## Progress

| Commit | Description | Status |
|--------|-------------|--------|
| 1 | Setup dependencies & infrastructure | **IN PROGRESS** |
| 2 | Resource view feature | PENDING |
| 3 | Site browse feature | PENDING |
| 4 | Resource annotate feature | PENDING |
| 5 | Diagramer create feature | PENDING |
| 6 | Download state feature | PENDING |
| 7 | Integration smoke tests | PENDING |
| 8 | Unit tests | PENDING |

## Commit Details

### Commit 1: Setup Dependencies & Infrastructure

**Files to Create:**
- [x] `cpanfile` - Add Test::BDD::Cucumber, Test::BDD::Cucumber::Definitions
- [x] `t/run_bdd.t` - BDD test runner
- [x] `t/lib/Test/Factory.pm` - Test data factories
- [x] `t/features/step_definitions/common_steps.pl` - Shared setup steps
- [x] `t/features/` directory structure
- [x] `t/integration/` directory
- [x] `t/unit/` directory

**Files to Update:**
- [x] `AGENTS.md` - Add testing section
- [x] `spec.md` - Add testing section

### Commit 2: Resource View Feature

**Files to Create:**
- [ ] `t/features/resource_view.feature`
- [ ] `t/features/step_definitions/resource_steps.pl`

**Files to Remove:**
- [ ] `t/web.t`

### Commit 3: Site Browse Feature

**Files to Create:**
- [ ] `t/features/site_browse.feature`
- [ ] `t/features/step_definitions/site_steps.pl`

**Files to Remove:**
- [ ] `t/localmark.t`

### Commit 4: Resource Annotate Feature

**Files to Create:**
- [ ] `t/features/resource_annotate.feature`
- [ ] `t/features/step_definitions/comment_steps.pl`

### Commit 5: Diagramer Create Feature

**Files to Create:**
- [ ] `t/features/diagramer_create.feature`
- [ ] `t/features/step_definitions/diagramer_steps.pl`

**Files to Remove:**
- [ ] `t/markdown.t`

### Commit 6: Download State Feature

**Files to Create:**
- [ ] `t/features/download_state.feature`
- [ ] `t/features/step_definitions/download_steps.pl`

**Files to Remove:**
- [ ] `t/download_state.t`

### Commit 7: Integration Smoke Tests

**Files to Create:**
- [ ] `t/integration/smoke.t`
- [ ] `t/features/download_smoke.feature`
- [ ] `t/features/step_definitions/mock_download_steps.pl`

**Files to Remove:**
- [ ] `t/download.t`

### Commit 8: Unit Tests

**Files to Create:**
- [ ] `t/unit/mime_type.t`

**Files to Remove:**
- [ ] `t/util.t`

## Test Organization

```
t/
├── 0lint.t                        # Code quality (unchanged)
├── run_bdd.t                      # BDD test runner
├── lib/Test/Factory.pm           # Test factories
├── features/
│   ├── step_definitions/
│   │   ├── common_steps.pl        # Shared steps
│   │   ├── resource_steps.pl      # Resource steps
│   │   ├── site_steps.pl          # Site steps
│   │   ├── comment_steps.pl       # Comment steps
│   │   ├── diagramer_steps.pl     # Diagramer steps
│   │   ├── download_steps.pl      # Download steps
│   │   └── mock_download_steps.pl # Mock download steps
│   ├── resource_view.feature
│   ├── site_browse.feature
│   ├── resource_annotate.feature
│   ├── diagramer_create.feature
│   ├── download_state.feature
│   └── download_smoke.feature
├── integration/
│   └── smoke.t
└── unit/
    └── mime_type.t
```

## Run Commands

```bash
# Install dependencies
carton install

# Run all tests
carton exec prove -l t/

# Run BDD tests
carton exec prove -l t/run_bdd.t

# Run lint
carton exec prove -l t/0lint.t
```