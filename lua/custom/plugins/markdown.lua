-- [[ Personal markdown plugins ]]
--
-- Adds two complementary markdown plugins:
--  1. tadmccorkle/markdown.nvim  — markdown EDITING toolkit (inline surround,
--     TOC, list/task editing, links, heading navigation)
--  2. MeanderingProgrammer/render-markdown.nvim — markdown VIEWING (renders
--     headings, code blocks, tables, checkboxes, callouts in-place)
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
end

return M
