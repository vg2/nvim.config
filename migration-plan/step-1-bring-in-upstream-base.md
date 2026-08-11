# Step 1 — Bring in upstream base

**Goal**: Replace the fork's lazy.nvim + modular base with upstream's vim.pack single-file base, while
preserving the empty `lua/custom/plugins/` escape-hatch.

## Paths to take from upstream (`upstream-master` ref)

| Path (upstream) | Current state in fork | Action |
|---|---|---|
| `init.lua` | fork's lazy.nvim bootstrap version | **Replace** |
| `lua/kickstart/plugins/` | fork has same 6 files + `gitsigns.lua` | **Replace** (upstream versions may differ slightly) |
| `lua/custom/plugins/` | fork has identical empty placeholder | **Keep** (no conflict; skip checkout) |
| `doc/` | does not exist in fork | **Add** (new) |
| `README.md` | fork's personalised version | **Replace** (pre-merge; preserve a copy first — see Step 5) |
| `LICENSE.md` | identical MIT license | **Replace** (harmless) |
| `.stylua.toml` | identical | **Replace** (harmless) |
| `.github/` | fork has same structure | **Replace** (refresh workflows/templates) |
| `.gitignore` | fork's version ignores `lazy-lock.json`-style entries | **Replace** with upstream's (which ignores `nvim-pack-lock.json`-style entries) |

## Paths to delete from the fork

| Path | Reason |
|---|---|
| `lua/kickstart/default/` (11 files) | Content folded into upstream's single `init.lua` |
| `lua/kickstart/health.lua` | Custom health check; relocate to `lua/custom/health.lua` in Step 5 (decision pending) |
| `lazy-lock.json` | Lock file for the outgoing `lazy.nvim`; `vim.pack` uses `nvim-pack-lock.json` instead |

## Commands

```bash
# 1. Preserve the personalised README before it's overwritten (Step 5 will decide what to do with it)
cp README.md /tmp/README.fork.bak.md

# 2. Pull upstream files onto the migration branch (stages them for commit)
git checkout upstream-master -- \
  init.lua \
  lua/kickstart/plugins/ \
  doc/ \
  README.md \
  LICENSE.md \
  .stylua.toml \
  .github/ \
  .gitignore

# 3. Delete the modular default directory and the lazy lock file
git rm -r lua/kickstart/default
git rm lazy-lock.json

# 4. Inspect the staging area
git status
git diff --cached --stat
```

## What the working tree looks like after this step

- `init.lua` is now upstream's vim.pack single-file version (pristine, example plugins still commented).
- `lua/kickstart/plugins/*.lua` are upstream's example files.
- `lua/kickstart/default/` is gone.
- `lua/custom/plugins/init.lua` unchanged (still the empty `return {}`).
- `lua/kickstart/health.lua` still present (fork-only file) — dealt with in Step 5.
- `lazy-lock.json` gone; `nvim-pack-lock.json` will be generated on first `nvim` run in Step 6.

## Verification

```bash
# Confirm no stragglers from the modular layout
ls lua/kickstart/default 2>/dev/null && echo "ERROR: default dir still present" || echo "OK: default dir removed"
ls lazy-lock.json 2>/dev/null && echo "ERROR: lazy-lock.json still present" || echo "OK: lazy-lock.json removed"

# Confirm upstream's init.lua structure landed
grep -c "vim.pack.add" init.lua   # expect several matches
grep -c "lazy.nvim" init.lua       # expect 0 (lazy no longer referenced)
```

## What this step does NOT do

- Does not enable any example plugins (Step 2).
- Does not apply personal preferences (Step 3).
- Does not migrate web-dev additions (Step 4).
- Does not touch `lua/custom/plugins/init.lua` (intentionally — upstream uses the same file).

## Note on the staged commit

The `git checkout upstream-master -- …` command stages the upstream content. Do **not** commit yet — the
remaining steps (2-5) will further modify `init.lua` and create `lua/custom/webdev.lua`. Committing once at
the end of Step 5 (or as small logical commits per step) is cleaner. The plan collects everything into one
or a few commits in Step 6.