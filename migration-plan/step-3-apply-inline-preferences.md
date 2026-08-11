# Step 3 — Apply inline preferences to `init.lua`

**Goal**: Apply the ~4 personal one-line preferences directly inside `init.lua`. These stay inline because
they're trivial one-liners and re-resolvable in seconds on any future upstream merge.

## The 4 personal preferences

All live in SECTION 1 (options) and SECTION 2 (keymaps/diagnostics) of upstream's `init.lua`.

### 3.1 — Enable Nerd Font (SECTION 1)

Upstream:

```lua
vim.g.have_nerd_font = false
```

Change to:

```lua
vim.g.have_nerd_font = true
```

**File location**: upstream `init.lua`, SECTION 1, near the top (after `maplocalleader`).

**Effect**: toggles icon rendering across plugins (telescope, neo-tree, which-key, mini.icons mocks
`nvim-web-devicons` when this is true).

### 3.2 — Enable relative line numbers (SECTION 1)

Upstream ships this commented:

```lua
-- vim.o.relativenumber = true
```

Change to:

```lua
vim.o.relativenumber = true
```

**File location**: SECTION 1, right after `vim.o.number = true`.

### 3.3 — Diagnostic underline severity (SECTION 2)

Upstream:

```lua
underline = { severity = { min = vim.diagnostic.severity.WARN } },
```

Change to:

```lua
underline = { severity = { min = vim.diagnostic.severity.ERROR } },
```

**Effect**: only ERROR-severity diagnostics get underlined (less visual noise than upstream's WARN).

> **Note**: This is the one item not explicitly confirmed in the question round. Defaulted to keep the
> fork's previous value (ERROR). Swap to upstream's `WARN` if preferred — single-line edit.

### 3.4 — Diagnostic jump behaviour (SECTION 2)

**No edit needed** — adopt upstream's `on_jump` pattern directly. Upstream ships:

```lua
jump = {
  on_jump = function(_, bufnr)
    vim.diagnostic.open_float {
      bufnr = bufnr,
      scope = 'cursor',
      focus = false,
    }
  end,
},
```

This replaces the fork's previous `jump = { float = true }`. Taking upstream's version verbatim means a
future merge will not conflict here. Confirmed by user decision ("Adopt upstream's on_jump").

## Summary table

| # | Section | Edit | Source line | New line | Confirmed? |
|---|---|---|---|---|---|
| 3.1 | 1 | Nerd font | `vim.g.have_nerd_font = false` | `= true` | yes |
| 3.2 | 1 | Relative numbers | `-- vim.o.relativenumber = true` | `vim.o.relativenumber = true` (uncomment) | yes |
| 3.3 | 2 | Underline severity | `min = vim.diagnostic.severity.WARN` | `min = vim.diagnostic.severity.ERROR` | defaulted (flagged) |
| 3.4 | 2 | Diagnostic jump | upstream's `on_jump` block | keep as-is (adopt upstream) | yes |

## Verification

```bash
grep -n "have_nerd_font = true" init.lua && echo "3.1 OK"
grep -nE "^vim.o.relativenumber = true" init.lua && echo "3.2 OK"
grep -n "severity.ERROR" init.lua && echo "3.3 OK"
grep -n "on_jump" init.lua && echo "3.4 OK"
```

## What this step does NOT do

- Does not touch SECTION 6 (LSP servers / mason tools) — that's Step 4.
- Does not create `lua/custom/webdev.lua` — that's Step 4.
- Does not modify any `lua/kickstart/plugins/*.lua` file.