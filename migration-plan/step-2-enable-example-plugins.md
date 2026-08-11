# Step 2 — Enable upstream example plugins

**Goal**: Uncomment the `kickstart.plugins.*` example requires in `init.lua` SECTION 10 so behaviour
matches the previous fork setup (plus the newly-enabled gitsigns keymaps).

## Background

Upstream's `init.lua` ends with a SECTION 10 block ("OPTIONAL EXAMPLES / NEXT STEPS") where these lines ship
**commented out**:

```lua
-- require 'kickstart.plugins.debug'
-- require 'kickstart.plugins.indent_line'
-- require 'kickstart.plugins.lint'
-- require 'kickstart.plugins.autopairs'
-- require 'kickstart.plugins.neo-tree'
-- require 'kickstart.plugins.gitsigns' -- adds gitsigns recommended keymaps
```

The fork previously had four of these enabled (`indent_line`, `lint`, `autopairs`, `neo-tree`) and the
`debug` plugin dormant. `gitsigns` (the recommended-hunk-keymaps example) was physically present on disk
but **never wired into `init.lua`** — so the fork shipped gitsigns gutter signs with no hunk keymaps.

## Confirmed decisions

| Plugin | Previous state | New state | Reason |
|---|---|---|---|
| `indent_line` | enabled | enabled | Match previous behaviour |
| `lint` | enabled | enabled | Match previous behaviour (oxlint/markdownlint config migrated in Step 4) |
| `autopairs` | enabled | enabled | Match previous behaviour |
| `neo-tree` | enabled | enabled | Match previous behaviour (`\` reveal mapping) |
| `gitsigns` keymaps | dormant (file on disk, not loaded) | **enabled** | User decision: take upstream's recommended `<leader>h*`/`]c`/`[c` keymaps |
| `debug` | dormant | dormant | Leave commented (was dormant before) |

## Edits in `init.lua` (SECTION 10)

Remove the `--` comment prefix from the chosen lines. Final SECTION 10 block should read:

```lua
do
  -- ... upstream's surrounding comments ...
  require 'kickstart.plugins.indent_line'
  require 'kickstart.plugins.lint'
  require 'kickstart.plugins.autopairs'
  require 'kickstart.plugins.neo-tree'
  require 'kickstart.plugins.gitsigns' -- adds gitsigns recommended keymaps

  -- require 'kickstart.plugins.debug'  -- leave commented

  -- NOTE: You can add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  require 'custom.plugins'
end
```

The last line (`require 'custom.plugins'`) is also uncommented — this is what loads
`lua/custom/plugins/init.lua`, which `require 'custom.webdev'` will be wired into in Step 4.

## Important nuance about `lua/kickstart/plugins/lint.lua`

Upstream's example `lint.lua` ships a generic scaffold with `lint.linters_by_ft` mostly commented out
plus a `BufEnter`/`BufWritePost`/`InsertLeave` autocmd calling `lint.try_lint()`. Your fork's
`lint.lua` hard-coded `markdown = {'markdownlint'}` and the JS/TS family → `oxlint`.

**Do not modify `lua/kickstart/plugins/lint.lua` here.** That file is upstream-owned and would conflict
on future syncs. Instead, the JS/TS/markdown `linters_by_ft` additions live in `lua/custom/webdev.lua`
and are injected at runtime in Step 4 (calling `lint.try_lint()` reuses upstream's autocmd — no duplicate
autocmd needed).

## Verification

After the edits, `init.lua` SECTION 10 should reference exactly these plugin modules:

```
kickstart.plugins.indent_line
kickstart.plugins.lint
kickstart.plugins.autopairs
kickstart.plugins.neo-tree
kickstart.plugins.gitsigns
custom.plugins
```

Quick check:

```bash
grep -nE "require 'kickstart.plugins.(debug|indent_line|lint|autopairs|neo-tree|gitsigns)'" init.lua
# expect 5 matches (all but debug)
grep -nE "require 'custom.plugins'" init.lua
# expect 1 match
```

## What this step does NOT do

- Does not yet touch the web-dev LSP/linter/formatter config — that's Step 4.
- Does not apply personal option preferences — that's Step 3.
- Does not modify the example plugin files themselves.