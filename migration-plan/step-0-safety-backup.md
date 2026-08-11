# Step 0 — Safety backup

**Goal**: Establish safe rollback points and a dedicated migration branch before any destructive operation.

## Preconditions

- Working tree clean of *tracked* changes (`main` at `c2a73c6`, nothing staged/modified).
  - The new `migration-plan/` folder is untracked here and is committed on `main` in step 1 below,
    so the backup branch captures the plan alongside the pre-migration code (not just `c2a73c6`).
- No `upstream` remote configured (only `origin` → `vg2/nvim.config`).
- Neovim 0.12.4 confirmed (required for `vim.pack`).

> Note: this step's backup branch lands at the *post*-plan-commit `HEAD`, one commit ahead of
> the `c2a73c6` referenced in the high-level plan. The per-step doc is authoritative for execution;
> the high-level figure was written before the decision to commit the plan first.

## Commands

### 1. Commit the migration plan on `main`

```bash
git -C /home/vishengounden/.config/nvim add migration-plan/
git -C /home/vishengounden/.config/nvim commit -m "docs: add vim.pack migration plan"
```

- Persists this migration plan so the backup branch (step 3) includes it. Without this, the
  rolled-back state would be bare `c2a73c6` minus the plan docs.
- After this commit `HEAD` advances past `c2a73c6`; every subsequent command uses `HEAD` rather
  than a hardcoded SHA, so it stays correct regardless of the new commit hash.

### 2. Fetch upstream into a throwaway ref (no permanent remote)

```bash
git -C /home/vishengounden/.config/nvim fetch https://github.com/nvim-lua/kickstart.nvim.git master:upstream-master
```

- Creates a local ref `upstream-master` that mirrors upstream's `master`.
- Does **not** modify `.git/config` — no `upstream` entry appears in `git remote -v`.
- The ref can be deleted later with `git update-ref -d upstream-master` if cleanup is desired.

### 3. Tag the current state as a backup branch

```bash
git -C /home/vishengounden/.config/nvim branch backup-pre-vimpack-migration HEAD
```

- `backup-pre-vimpack-migration` is a permanent safety branch pointing at the current `HEAD`
  (i.e. the post-plan-commit tip of `main`, which includes the migration plan).
- Keep it indefinitely (or until you're confident the migration is stable). It costs nothing.

### 4. Create and switch to the migration work branch

```bash
git -C /home/vishengounden/.config/nvim checkout -b migrate-to-vimpack
```

- All subsequent edits happen on `migrate-to-vimpack`. `main` stays untouched at the same tip
  as the backup branch.
- On completion, `migrate-to-vimpack` becomes the new `main` (fast-forward or merge — your call).

## Verification

```bash
git -C /home/vishengounden/.config/nvim branch -v
# Expected: main / backup-pre-vimpack-migration / migrate-to-vimpack all at the SAME SHA
# (= the "docs: add vim.pack migration plan" commit), with migrate-to-vimpack current (*).
# upstream-master is a ref, not a branch, so it won't appear in `git branch -v`.
```

Also confirm the throwaway ref landed and no `upstream` remote was added:

```bash
git -C /home/vishengounden/.config/nvim rev-parse --verify upstream-master >/dev/null && echo "upstream-master: OK"
git -C /home/vishengounden/.config/nvim remote -v   # should still list only origin
```

## Rollback

If anything later goes wrong:

```bash
git -C /home/vishengounden/.config/nvim checkout main                  # return to pre-migration tip
git -C /home/vishengounden/.config/nvim branch -D migrate-to-vimpack   # discard migration branch
git -C /home/vishengounden/.config/nvim update-ref -d upstream-master  # optional: drop throwaway ref
```

If commits were already made on `migrate-to-vimpack` but you want to start over:

```bash
git -C /home/vishengounden/.config/nvim reset --hard backup-pre-vimpack-migration
```