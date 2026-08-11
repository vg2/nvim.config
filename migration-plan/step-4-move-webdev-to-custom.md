# Step 4 — Move web-dev additions into `lua/custom/webdev.lua`

**Goal**: Extract every personal web-dev customisation out of `kickstart.*` base files and into the
upstream-promised conflict-free zone `lua/custom/`, so future upstream syncs stay clean.

## What's being extracted (and from where)

### From `lua/kickstart/default/lsp.lua:54-70` (to be deleted in Step 1)

**Extra LSP servers** (added to upstream's default `servers` table):

```lua
ts_ls = {},
cssls = {},
html = {},
jsonls = {},
```

**Extra mason `ensure_installed` tools**:

```lua
'typescript-language-server',
'css-lsp',
'html-lsp',
'json-lsp',
'oxlint',
'oxfmt',
'markdownlint',
```

> `lua-language-server` and `stylua` are already in upstream's base `servers`/tools and do **not** need
> re-listing here.

### From `lua/kickstart/default/conform.lua:26-32` (to be deleted in Step 1)

**Formatters by filetype**:

```lua
lua = { 'stylua' },
javascript = { 'oxfmt' },
typescript = { 'oxfmt' },
javascriptreact = { 'oxfmt' },
typescriptreact = { 'oxfmt' },
```

Also: `format_on_save` enabled with `timeout_ms = 500`, `lsp_format = 'fallback'`, skipping c/cpp.

### From `lua/kickstart/plugins/lint.lua:8-14` (upstream-owned — DO NOT EDIT)

**Linters by filetype**:

```lua
markdown = { 'markdownlint' },
javascript = { 'oxlint' },
typescript = { 'oxlint' },
javascriptreact = { 'oxlint' },
typescriptreact = { 'oxlint' },
```

## New file: `lua/custom/webdev.lua`

Exports a single table-based module with four fields and a `setup()` function:

```lua
-- Personal web-dev additions, isolated from upstream kickstart.* to stay merge-friendly.
--  See migration-plan/high-level-plan.md for context.

local M = {}

-- Extra LSP servers to enable (merged into upstream's `servers` table in init.lua SECTION 6).
---@type table<string, vim.lsp.Config>
M.servers = {
  ts_ls = {},
  cssls = {},
  html = {},
  jsonls = {},
}

-- Extra mason tools to auto-install (list-extended into `ensure_installed` in init.lua SECTION 6).
M.tools = {
  'typescript-language-server',
  'css-lsp',
  'html-lsp',
  'json-lsp',
  'oxlint',
  'oxfmt',
  'markdownlint',
}

-- Conform formatters by filetype.
M.formatters_by_ft = {
  lua = { 'stylua' },
  javascript = { 'oxfmt' },
  typescript = { 'oxfmt' },
  javascriptreact = { 'oxfmt' },
  typescriptreact = { 'oxfmt' },
}

-- nvim-lint linters by filetype.
M.linters_by_ft = {
  markdown = { 'markdownlint' },
  javascript = { 'oxlint' },
  typescript = { 'oxlint' },
  javascriptreact = { 'oxlint' },
  typescriptreact = { 'oxlint' },
}

-- Runtime injection of formatters and linters.
-- Called from lua/custom/plugins/init.lua (which init.lua SECTION 10 loads via `require 'custom.plugins'`).
-- Runs AFTER upstream's base conform.setup() and lint setup() (init.lua SECTION 7 and the lint example),
-- so it mutates the already-initialised runtime tables rather than re-calling setup().
function M.setup()
  -- Formatters (conform.nvim)
  local ok_conform, conform = pcall(require, 'conform')
  if ok_conform then
    for ft, formatters in pairs(M.formatters_by_ft) do
      conform.formatters_by_ft[ft] = formatters
    end
  end

  -- Linters (nvim-lint)
  local ok_lint, lint = pcall(require, 'lint')
  if ok_lint then
    for ft, linters in pairs(M.linters_by_ft) do
      lint.linters_by_ft[ft] = linters
    end
  end
end

return M
```

### Why runtime injection works

- `conform.formatters_by_ft` is a plain mutable table on the `conform` module — assigning keys after
  `conform.setup()` runs is supported (conform reads it lazily on format).
- `lint.linters_by_ft` on `require('lint')` is likewise a mutable table; upstream's example `lint.lua`
  already provides the `BufEnter`/`BufWritePost`/`InsertLeave` autocmd that calls `lint.try_lint()`, which
  reads `linters_by_ft` at lint time. No duplicate autocmd is needed.

### Ordering requirement (the one nuance)

`require 'custom.plugins'` (in `init.lua` SECTION 10) executes **after** SECTION 6 (LSP) and SECTION 7
(conform) have run, because `init.lua` is a single file executed top-to-bottom. This guarantees the base
`conform.setup()` and `nvim-lint` setup have already initialised their runtime tables before
`custom.webdev.setup()` mutates them.

The LSP server merge happens **inline in SECTION 6** (see 4.1 below), because that's where
`mason-tool-installer.setup` is called with `ensure_installed`. Calling `mason-tool-installer.setup`
twice would replace the list, not append — so the web-dev servers/tools must be present in the same
table before the one-time `setup` call.

## Edits in `init.lua` (SECTION 6)

Two surgical one-line hooks:

### 4.1 — Merge extra servers

Upstream:

```lua
---@type table<string, vim.lsp.Config>
local servers = {
  -- clangd = {},
  -- gopls = {},
  -- ...
  stylua = {},
  lua_ls = { on_init = ..., settings = ... },
}
```

Change to:

```lua
---@type table<string, vim.lsp.Config>
local servers = vim.tbl_extend('force', {
  -- clangd = {},
  -- gopls = {},
  -- ...
  stylua = {},
  lua_ls = { on_init = ..., settings = ... },
}, require('custom.webdev').servers or {})
```

(i.e. wrap the literal in `vim.tbl_extend('force', { ... }, require('custom.webdev').servers or {})`.)

### 4.2 — Extend `ensure_installed`

Upstream:

```lua
local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
  -- You can add other tools here that you want Mason to install
})
```

Change to:

```lua
local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, require('custom.webdev').tools)
```

## Edit in `lua/custom/plugins/init.lua`

Replace the placeholder `return {}` with:

```lua
-- Personal web-dev additions live in lua/custom/webdev.lua; loaded here so init.lua's
-- `require 'custom.plugins'` (SECTION 10) triggers their runtime injection after
-- upstream's base conform.setup() and lint setup() have run.
require('custom.webdev').setup()

-- You can add further personal plugin specs below; they will be picked up by vim.pack.
return {}
```

`return {}` stays as the last statement so any future personal plugin specs can be appended without
restructuring.

## Verification

```bash
# webdev module present
test -f lua/custom/webdev.lua && echo "OK: webdev.lua created"
grep -c "M.servers" lua/custom/webdev.lua   # expect 1
grep -c "M.setup"    lua/custom/webdev.lua   # expect 2 (definition + comment)
```

Once Neovim is running (Step 6):

```vim
:lua print(vim.inspect(require('conform').formatters_by_ft.javascript))  -- expect { 'oxfmt' }
:lua print(vim.inspect(require('lint').linters_by_ft.typescript))        -- expect { 'oxlint' }
:LspInfo   -- on a .ts file: expect ts_ls attached
:Mason     -- expect typescript-language-server, css-lsp, html-lsp, json-lsp, oxlint, oxfmt, markdownlint listed/installed
```

## What this step does NOT do

- Does not modify `lua/kickstart/plugins/lint.lua` (upstream-owned).
- Does not modify `lua/kickstart/plugins/neo-tree.lua`, `autopairs.lua`, `indent_line.lua`.
- Does not handle `lua/kickstart/health.lua` — that's Step 5.
- Does not run the verification commands (that's Step 6).