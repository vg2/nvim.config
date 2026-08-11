# Step 6 — Verify and commit

**Goal**: Confirm the migrated config boots cleanly, plugins install via `vim.pack`, and web-dev
behaviours (LSP, lint, format, tree) work end-to-end. Then commit.

## 6.1 — Headless bootstrap (vim.pack clones plugins on first run)

```bash
cd /home/vishengounden/.config/nvim
nvim --headless "+qa"
```

- First run will print `vim.pack` install messages; ignore transient errors about missing modules on the
  very first pass (the second run should be clean).
- Repeat once to confirm idempotency:

  ```bash
  nvim --headless "+qa"
  ```

- A lock file should now exist:

  ```bash
  test -f nvim-pack-lock.json && echo "OK: lock file generated"
  ```

## 6.2 — Inspect plugin state

```bash
nvim --headless "+lua vim.pack.update(nil, { offline = true })" "+qa"
```

Or interactively inside `nvim`:

```vim
:lua vim.pack.update(nil, { offline = true })   " inspect state
:lua vim.pack.update()                            " fetch updates (write to apply, quit to cancel)
```

Confirm the plugin roster (expected ~12-15 plugins):

| Plugin | Purpose |
|---|---|
| `guess-indent.nvim` | Auto-detect indent (upstream base) |
| `gitsigns.nvim` | Git gutter signs + hunk keymaps (Step 2) |
| `which-key.nvim` | Pending-key hints (upstream base) |
| `tokyonight.nvim` | Colorscheme (upstream base) |
| `todo-comments.nvim` | Highlight TODO/FIXME (upstream base) |
| `mini.nvim` | statusline + ai + surround + icons (upstream base) |
| `telescope.nvim` + `plenary` + `ui-select` (+ fzf-native) | Fuzzy finder (upstream base) |
| `fidget.nvim` | LSP status (upstream base) |
| `nvim-lspconfig` + `mason.nvim` + `mason-lspconfig` + `mason-tool-installer` | LSP (upstream base) |
| `conform.nvim` | Formatting (upstream base) |
| `LuaSnip` | Snippets (upstream base) |
| `blink.cmp` | Autocomplete (upstream base) |
| `nvim-treesitter` | Treesitter (upstream base) |
| `indent-blankline.nvim` | Indent guides (Step 2) |
| `nvim-autopairs` | Autopairs (Step 2) |
| `nvim-lint` | Linting (Step 2) |
| `neo-tree.nvim` + `plenary` + `nvim-web-devicons` + `nui.nvim` | File tree (Step 2) |

## 6.3 — LSP verification

Open representative files and check `:LspInfo`:

```bash
nvim --headless "+edit test.ts"  "+LspInfo" "+qa"  2>&1 | grep -i ts_ls || true
nvim --headless "+edit test.lua" "+LspInfo" "+qa"  2>&1 | grep -i lua_ls || true
```

Or interactively:

```vim
:e test.ts
:LspInfo          " expect ts_ls attached
:lua =vim.lsp.get_clients()[1].name   " sanity check
```

Repeat for `.css`, `.html`, `.json` → expect `cssls`, `html`, `jsonls` respectively.

## 6.4 — Linter verification (custom webdev injection)

```bash
# Create throwaway test files
mkdir -p /tmp/nvim-migration-verify && cd /tmp/nvim-migration-verify
printf "const x: number = 'wrong';\n" > bad.ts
printf "<!-- TODO: fix -->\n# Title\n" > note.md
nvim --headless "+edit bad.ts"  "+lua vim.diagnostic.open_float()" "+qa" 2>&1 | grep -i oxlint || true
nvim --headless "+edit note.md" "+lua vim.diagnostic.open_float()" "+qa" 2>&1 | grep -i markdownlint || true
```

Or interactively, confirm `lint.linters_by_ft` was mutated:

```vim
:lua print(vim.inspect(require('lint').linters_by_ft))
" expect javascript/typescript/*react -> { 'oxlint' }, markdown -> { 'markdownlint' }
```

## 6.5 — Formatter verification (custom webdev injection)

```vim
:lua print(vim.inspect(require('conform').formatters_by_ft))
" expect lua -> { 'stylua' }, javascript/typescript/*react -> { 'oxfmt' }
```

Try formatting a JS file (with `oxfmt` installed via mason):

```vim
:e /tmp/test.js
:<leader>f
```

## 6.6 — Telescope LSP pickers

Open a TS file with a working ts_ls, then:

```vim
:lua vim.lsp.get_clients()[1].name   " confirm attached
grd   " goto definition (telescope lsp_definitions)
grr   " references
gri   " implementation
grt   " type definition
gO    " document symbols
gW    " workspace symbols
```

These are upstream's new LSP defaults wired through Telescope (SECTION 5 of upstream `init.lua`).

## 6.7 — Gitsigns keymap verification (Step 2)

Inside a git repo file with hunks:

```vim
:Gitsigns                            " or just edit a tracked file
]c   " next hunk
[c   " prev hunk
<leader>hp   " preview hunk
<leader>hs   " stage hunk
<leader>hr   " reset hunk
```

## 6.8 — Other upstream sanity

```vim
:checkhealth                    " general health
:checkhealth kickstart          " if health.lua kept in kickstart namespace
:checkhealth custom             " if relocated per Step 5.2
:Telescope find_files           " fuzzy finder
\<leader>   " neo-tree reveal (or \ per mapping)
```

## 6.9 — Commit

If all green:

```bash
cd /home/vishengounden/.config/nvim
git status

# Stage everything (including the generated lock file)
git add init.lua nvim-pack-lock.json lua/custom/webdev.lua \
        lua/custom/plugins/init.lua \
        lua/kickstart/plugins/ doc/ README.md .gitignore
# Plus any deletions from Step 1 (git rm already staged them)

# Suggested commit message (matches repo style; recent commits use lowercase verbs):
git commit -m "migrate to upstream kickstart vim.pack single-file architecture

- replace lazy.nvim bootstrap with vim.pack (Neovim 0.12+)
- fold lua/kickstart/default/*.lua back into single-file init.lua
- extract web-dev servers/tools/formatters/linters into lua/custom/webdev.lua
- enable gitsigns recommended hunk keymaps (kickstart.plugins.gitsigns)
- adopt upstream diagnostic jump.on_jump; keep ERROR underline severity
- delete lazy-lock.json; track nvim-pack-lock.json
- preserve personalised README section after upstream content"
```

Smaller logical commits are also fine (e.g. one commit for the upstream checkout, one for the webdev
extraction). The repo's existing style (see `git log --oneline`) is single-line lowercase verbs; the
above uses a longer body because the change is significant.

## 6.10 — Post-commit

```bash
git log --oneline -3
git status                                # expect clean
git -C /home/vishengounden/.config/nvim branch -v   # confirm migrate-to-vimpack advanced
```

When ready to promote:

```bash
git checkout main
git merge --ff-only migrate-to-vimpack    # if linear
git push origin main
# Optionally: git branch -D migrate-to-vimpack
# Keep backup-pre-vimpack-migration for a while.
```

## 6.11 — Rollback if verification fails

If any step's verification fails and you want to recover the pre-migration state:

```bash
git -C /home/vishengounden/.config/nvim checkout backup-pre-vimpack-migration
# To make this branch the new main:
git -C /home/vishengounden/.config/nvim branch -M main
# Discard the migration branch:
git -C /home/vishengounden/.config/nvim branch -D migrate-to-vimpack
# Optional: drop the throwaway upstream ref:
git -C /home/vishengounden/.config/nvim update-ref -d upstream-master
```

Also remove `nvim-pack-lock.json` and any `vim.pack`-managed plugin data to avoid confusing lazy.nvim on
rollback:

```bash
rm -f /home/vishengounden/.config/nvim/nvim-pack-lock.json
# Plugin data lives under stdpath('data'); rollback to lazy.nvim will re-clone to lazy.nvim's path.
```

If `~/.local/share/nvim` was polluted by `vim.pack` installs and you want a clean slate:

```bash
rm -rf ~/.local/share/nvim/lazy   ~/.local/share/nvim/site
# lazy.nvim will re-bootstrap on next nvim launch from the rollback branch.
```