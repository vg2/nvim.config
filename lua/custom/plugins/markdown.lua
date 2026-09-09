-- [[ Personal markdown plugins ]]
--
-- Adds three complementary markdown plugins:
--  1. tadmccorkle/markdown.nvim  — markdown EDITING toolkit (inline surround,
--     TOC, list/task editing, links, heading navigation)
--  2. MeanderingProgrammer/render-markdown.nvim — markdown VIEWING (renders
--     headings, code blocks, tables, checkboxes, callouts in-place)
--  3. cavanaug/render-markdown-mermaid.nvim — mermaid diagram rendering
--     (renders ```mermaid code blocks as Unicode diagrams via the `bm` CLI)
--
-- Requirements (already satisfied by this config):
--  * Neovim >= 0.10
--  * treesitter parsers 'markdown' and 'markdown_inline' (kickstart
--    auto-installs these per-filetype)
--  * icon provider for render-markdown code-block icons: mini.icons, which
--    comes from the mini.nvim suite already installed in init.lua SECTION 4
--
-- Called from lua/custom/plugins/init.lua (which init.lua SECTION 10 loads
-- via `require 'custom.plugins'`).
local M = {}

function M.setup()
  -- ============================================================
  -- markdown.nvim — editing tools
  -- ============================================================
  -- See `:help markdown.nvim` and `:help markdown.configuration` for details.
  --
  -- Default keymaps worth knowing:
  --   gs{motion}{style} / gss{style}  toggle emphasis over motion/line
  --                                     styles: i=italic, b=bold,
  --                                             s=strikethrough, c=code
  --   ds{style} / cs{from}{to}        delete / change surrounding style
  --   gl{motion}                      add link over motion/selection
  --   gx                              follow link under cursor
  --   ]] / [[                         next / previous heading
  --   ]h / ]H                         (remapped) current / parent heading
  --
  -- Commands worth knowing:
  --   :MDInsertToc  insert a table of contents as a list
  --   :MDToc        show TOC in the location list
  vim.pack.add { 'https://github.com/tadmccorkle/markdown.nvim' }
  require('markdown').setup {
    mappings = {
      -- Defaults ']'c' and ']p' are remapped to avoid shadowing, in markdown
      -- buffers:
      --   ']'c — gitsigns "next hunk" (kickstart/plugins/gitsigns.lua)
      --   ']'p — built-in "paste below with indent"
      go_curr_heading = ']h',
      go_parent_heading = ']H',
      -- ']]', '[[', 'gs', 'ds', 'cs', 'gl', 'gx' defaults are conflict-free.
    },
    on_attach = function(bufnr)
      -- Extra buffer-local keymaps for list/task editing (these commands are
      -- not mapped by default).
      local map = vim.keymap.set
      local opts = { buffer = bufnr }
      map({ 'n', 'i' }, '<M-l><M-o>', '<Cmd>MDListItemBelow<CR>', opts)
      map({ 'n', 'i' }, '<M-L><M-O>', '<Cmd>MDListItemAbove<CR>', opts)
      map('n', '<leader>mt', '<Cmd>MDTaskToggle<CR>', opts)
      map('x', '<leader>mt', ':MDTaskToggle<CR>', opts)
    end,
  }

  -- ============================================================
  -- render-markdown.nvim — viewing / in-place rendering
  -- ============================================================
  -- Renders markdown in the buffer itself: styled headings, code-block
  -- background + language icons (via mini.icons), tables, checkboxes,
  -- callouts, block quotes. No configuration needed for a good default
  -- experience; see `:help render-markdown` for the many options.
  --
  -- Useful commands:
  --   :RenderMarkdown toggle   toggle rendering on/off
  --   :RenderMarkdown expand   widen anti-conceal margin on cursor line
  --   :RenderMarkdown preview  rendered buffer in a split
  vim.pack.add { 'https://github.com/MeanderingProgrammer/render-markdown.nvim' }
  require('render-markdown').setup {}

  -- ============================================================
  -- render-markdown-mermaid.nvim — mermaid diagrams
  -- ============================================================
  -- Renders fenced ```mermaid code blocks as Unicode box-drawing diagrams,
  -- drawn as virtual lines above the block. When the cursor enters the block
  -- the diagram is hidden and the raw Mermaid source is revealed for editing
  -- — the same behavior render-markdown applies to tables. Re-renders
  -- (debounced) as the source changes.
  --
  -- Works in any terminal (plain text, no image protocol needed).
  --
  -- Requirements:
  --  * `bm` (Beautiful Mermaid) on PATH: `npm i -g beautiful-mermaid-cli`
  --    (also installed by install-prereqs.sh)
  --  * treesitter 'markdown' parser (already required by render-markdown)
  --
  -- Useful commands:
  --   :checkhealth render-markdown-mermaid
  vim.pack.add { 'https://github.com/cavanaug/render-markdown-mermaid.nvim' }
  require('render-markdown-mermaid').setup {
    -- We already called render-markdown.setup() above; don't let this
    -- plugin re-configure it.
    auto_setup_render_markdown = false,
    -- 'above' draws the diagram above the fence (README default). Use
    -- 'below' to draw it underneath instead.
    placement = 'above',
  }
end

return M
