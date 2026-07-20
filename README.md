# mmu

Part of the `morphingmachines` hardware design org. This repo is one of the
CI/CD-wired dependencies consumed by [`RedefineIp`].(https://github.com/morphingmachines/RedefineIp)
under `dependencies/`.

## What's in here, CI/CD-wise

Four files make this repo part of the shared pipeline — nothing else in this
repo needed to change to adopt it:

| File | Purpose |
|---|---|
| `Makefile` | Has a `.PHONY: rtl-dispatch` target and `-include cd.config` |
| `cd.config` | One line: `RTL_TARGET=rtl` (or `lazyrtl`, if this repo has that variant) |
| `.github/workflows/RTL-CI.yml` | Calls the shared `Reusable-RTL-CI.yml` on every push/PR |
| `.github/workflows/RTL-CD.yml` | Calls the shared `Reusable-RTL-CD.yml`, manually triggered |

The actual pipeline logic lives centrally in
[`shau-08/CICD`](https://github.com/shau-08/CICD) — this repo just calls it.
If CI or CD behavior needs to change, it almost never needs to change here;
it changes once, centrally.

## Continuous Integration (automatic)

Every push and pull request runs, with no manual step:
- a merge-conflict check against `main`
- `make test`
- a lint/project-auto-detect step (confirms this repo's Mill module is
  correctly identified from `build.sc`)

## Cutting a release (manual)

From this repo's **Actions** tab, run **RTL-CD** manually (`workflow_dispatch`).
One field matters:

**`tag_name`** — leave it blank, or fill it in:

- **Blank** → auto-generates a tag like `<repo>-<branch>-<date>-<sha>` and
  publishes a release. Nothing downstream happens. Use this for routine,
  everyday CD runs.
- **Explicit, e.g. `RTL1p2`** → does the same release publish, **and**
  notifies `RedefineIp`, which bumps its pin on this repo to the exact
  commit that was built, and regenerates its own RTL. RedefineIp's resulting
  release is named `<this-repo>-<branch>-<tag>` (e.g. `mmu-main-RTL1p2`), so
  it's traceable back to this release at a glance.

Only use an explicit tag when this release is actually meant to propagate to
RedefineIp — not for work-in-progress or frequent iteration.

Via `gh` CLI instead of the Actions tab:
```bash
gh workflow run RTL-CD.yml -R morphingmachines/mmu -f tag_name=RTL1p2
```

## Submodule freshness warning

If this repo has its own `dependencies/*` submodules (e.g. `emitrtl`), every
CI/CD run checks whether each pinned commit is behind that dependency's own
tracked branch. If it is, you'll see a `::warning::` annotation in the run —
this is informational only, it does **not** change what gets built. The
pinned commit is always what's used. Bump it deliberately by editing
`.gitmodules`/the submodule commit yourself when you actually want to move
to a newer version.

## One-time local setup: git hooks (optional)

If this repo has a `.githooks/` directory:
```bash
git config core.hooksPath "$(git rev-parse --show-toplevel)/.githooks"
chmod +x .githooks/*
```
This is per-clone — everyone who clones this repo needs to run it once
themselves; it isn't automatic just because the folder exists.

## Requirements to actually run any of this

- The org secret `CI_SUBMODULE_PAT` must exist (org-level, "All repositories"
  access) — used to check out private `dependencies/*` submodules over
  HTTPS. Set up once at the org level, nothing to configure per-repo.
- No other setup needed here. Onboarding a *new* repo into this system is
  documented in the CICD repo's own README.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `ERROR: ...submodules use an SSH URL, but no submodule-token was provided` | `CI_SUBMODULE_PAT` isn't visible to this repo — check its "Repository access" setting at the org level, not just that it exists |
| CD runs but RedefineIp never updates | `tag_name` was left blank — only explicit tags notify RedefineIp |
| Lint step fails with "could not auto-detect project" | `build.sc` doesn't have exactly one module with `override def millSourcePath = os.pwd` |
