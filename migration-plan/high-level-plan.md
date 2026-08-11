# Migration Plan: kickstart.nvim lazy.nvim → vim.pack single-file

## Context

This repo (`vg2/nvim.config`) is a fork of [`nvim-lua/kickstart.nvim`](https://github.com/nvim-lua/kickstart.nvim)
that originally adopted the **lazy.nvim + modular `lua/kickstart/default/*.lua`** split. Since then, upstream
kickstart.nvim has fundamentally changed architecture:

- **Plugin manager**: upstream switched from `lazy.nvim` to the built-in **`vim.pack`** (Neovim 0.12+).
- **Layout**: upstream collapsed the modular `lua/kickstart/default/*.lua` files back into a **single-file
  `init.lua`** organized as ~10 `do … end` sections.
- **Lock file**: `lazy-lock.json` → `nvim-pack-lock.json`.
- **LSP keymaps**: upstream adopted the new Neovim 0.11+ defaults (`grr`, `gri`, `grd`, `grt`, `gO`, `gW`)
  wired through Telescope, replacing the older `grn`/`gra`/`grD`-only set.
- **Diagnostic jump**: upstream uses `jump.on_jump` (cursor-scoped, non-focusing float) instead of
  `jump = { float = true }`.

Because both the plugin manager and the file layout diverged, a plain `git merge upstream/master` is not
viable — it would conflict on essentially every line of `init.lua`, and upstream no longer ships the
`lua/kickstart/default/*.lua` files this fork depends on. A deliberate, surgical migration is required.

## The core problem this solves

Personal web-dev customisations (extra LSP servers, `oxlint`/`oxfmt`/`markdownlint` tooling, JS/TS
formatters and linters) currently live **inside** `kickstart.*` base files — specifically
`lua/kickstart/default/lsp.lua` and `lua/kickstart/plugins/lint.lua`. These are exactly the files that
conflict with upstream. Kickstart's own promised non-conflict zone is `lua/custom/plugins/*.lua`
(*"I promise not to create any merge conflicts in this directory"*), which this fork has left empty.

The migration moves all personal customisations **out** of `kickstart.*` and **into** `lua/custom/`, so
future upstream syncs become trivial.

## Target end state

```
~/.config/nvim/
├── init.lua                  # upstream's single-file vim.pack version (~8 surgical one-line edits)
├── nvim-pack-lock.json        # NEW (generated on first nvim run; track in git per upstream README)
├── lua/
│   ├── custom/
│   │   ├── webdev.lua         # NEW: web-dev servers + tools + formatters + linters tables
│   │   └── plugins/
│   │       └── init.lua       # upstream escape-hatch (kept; `require 'custom.plugins'` stays the loader)
│   └── kickstart/
│       └── plugins/           # upstream's OPTIONAL example files (kept as-is from upstream)
│           ├── autopairs.lua, debug.lua, gitsigns.lua,
│           ├── indent_line.lua, lint.lua, neo-tree.lua
├── doc/                       # NEW from upstream (kickstart docs)
└── (README, LICENSE, .stylua.toml, .github/ refreshed from upstream)
```

- `lua/kickstart/default/` (this fork's 11 files) is **deleted** — its content folded upstream.
- `lazy-lock.json` is **deleted** — replaced by `nvim-pack-lock.json`.
- `lua/kickstart/plugins/*.lua` is **kept** — these are upstream's optional example files, not personal files.
- `lua/custom/plugins/init.lua` stays untouched (identical upstream).

## Confirmed decisions

| Decision | Choice | Rationale |
|---|---|---|
| Sync direction | Migrate to upstream `vim.pack` single-file | Highest fidelity to upstream; future merges stay clean. Locks Neovim floor at 0.12 (currently on 0.12.4). |
| Upstream remote | None added permanently | Use throwaway fetch ref `upstream-master` only. |
| Gitsigns hunk keymaps | Enable (`require 'kickstart.plugins.gitsigns'`) | Dormant file was never loaded before; user wants the `<leader>h*` + `]c`/`[c` keymaps now. |
| Diagnostic jump | Adopt upstream's `on_jump` | Newer pattern; cursor-scoped non-focusing float. |
| Webdev module shape | Single `lua/custom/webdev.lua` | Fewest files, exports `servers`/`tools`/`formatters_by_ft`/`linters_by_ft` + a `setup()` for runtime injection. |
| Diagnostic underline severity | Keep `ERROR` (this fork's value) | Less noisy than upstream's `WARN`. Not asked explicitly; flagged for confirmation before execution. |

## Touched-line inventory in `init.lua`

~8 lines total — all trivially re-resolvable on future upstream merges:

- SECTION 1: `vim.g.have_nerd_font = true` (upstream: `false`)
- SECTION 1: uncomment `vim.o.relativenumber = true`
- SECTION 2: `underline = { severity = vim.diagnostic.severity.ERROR }` (upstream: `WARN`)
- SECTION 2: keep upstream's `jump.on_jump` (adopt upstream — no edit needed beyond taking upstream's version)
- SECTION 6: wrap `local servers = …` with
  `vim.tbl_extend('force', {<upstream defaults>}, require('custom.webdev').servers or {})`
- SECTION 6: after `local ensure_installed = vim.tbl_keys(servers)` add
  `vim.list_extend(ensure_installed, require('custom.webdev').tools)`
- SECTION 10: uncomment `require 'kickstart.plugins.gitsigns'`, `indent_line`, `lint`, `autopairs`,
  `neo-tree`, and `require 'custom.plugins'`

## Execution order (high level)

1. **Step 0 — Safety**: fetch upstream into a throwaway ref; create backup branch; create migration branch.
2. **Step 1 — Bring in upstream base**: checkout upstream's `init.lua`, `lua/kickstart/plugins/`, `doc/`,
   README/LICENSE/.stylua.toml/.github/.gitignore; delete `lua/kickstart/default/` and `lazy-lock.json`.
3. **Step 2 — Enable example plugins**: uncomment the upstream `kickstart.plugins.*` lines in SECTION 10
   matching previous behaviour (indent_line, lint, autopairs, neo-tree, gitsigns).
4. **Step 3 — Apply inline preferences**: ~4 one-line tweaks to `init.lua` (nerd font, relativenumber,
   underline severity; on_jump adopted from upstream).
5. **Step 4 — Move webdev to custom**: create `lua/custom/webdev.lua`; apply the 2 surgical SECTION 6 hooks
   in `init.lua`; wire `require 'custom.plugins'` to call the webdev `setup()` at the bottom.
6. **Step 5 — Reapply other deltas**: confirm neo-tree/indent_line/autopairs example files match previous
   behaviour; optionally relocate `lua/kickstart/health.lua` → `lua/custom/health.lua`; preserve a copy of
   the personalised README web-dev tool list.
7. **Step 6 — Verify**: headless bootstrap; LSP/lint/format/tree checks on real files; commit
   `nvim-pack-lock.json`.

## Open items to confirm before execution - CLOSED with decisions

- **Diagnostic underline severity**: defaulted to keep `ERROR` (less noisy).
- **`lua/kickstart/health.lua`**: this fork's custom health check. Remove the health check if its not in upstream.

## Cancellation / rollback

- Backup branch `backup-pre-vimpack-migration` at current HEAD (`c2a73c6`) preserves the pre-migration state.
- At any point during execution: `git checkout main && git branch -D migrate-to-vimpack` to discard work.
- After execution, if verification fails: `git reset --hard backup-pre-vimpack-migration` on the migration
  branch, or `git checkout main` to abandon.

## Per-step detail

Each step has its own markdown file in this directory:

- [`step-0-safety-backup.md`](step-0-safety-backup.md)
- [`step-1-bring-in-upstream-base.md`](step-1-bring-in-upstream-base.md)
- [`step-2-enable-example-plugins.md`](step-2-enable-example-plugins.md)
- [`step-3-apply-inline-preferences.md`](step-3-apply-inline-preferences.md)
- [`step-4-move-webdev-to-custom.md`](step-4-move-webdev-to-custom.md)
- [`step-5-reapply-other-deltas.md`](step-5-reapply-other-deltas.md)
- [`step-6-verify.md`](step-6-verify.md)

## Source references (current fork, pre-migration)

- `init.lua:1-212` — lazy.nvim bootstrap + lazy.setup
- `lua/kickstart/default/lsp.lua:54-70` — web-dev servers + ensure_installed list (to be extracted)
- `lua/kickstart/default/conform.lua:26-32` — oxfmt + stylua formatters (to be extracted)
- `lua/kickstart/plugins/lint.lua:8-14` — oxlint + markdownlint linters (to be extracted)
- `lua/kickstart/plugins/gitsigns.lua:1-56` — dormant hunk keymaps (to be enabled)
- `lua/custom/plugins/init.lua:1-6` — empty escape-hatch (kept)

## Upstream references

- Upstream `init.lua` master: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
- Upstream `lua/custom/plugins/`: https://github.com/nvim-lua/kickstart.nvim/tree/master/lua/custom/plugins
- `:help vim.pack` and `:help vim.pack-examples` (Neovim 0.12+)
- Blog: https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack
