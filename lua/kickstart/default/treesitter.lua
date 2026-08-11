return {
  'nvim-treesitter/nvim-treesitter',
  -- nvim-treesitter's `main` branch compiles parsers from source and requires
  -- the `tree-sitter` CLI on $PATH. Install it once with:
  --   npm install -g tree-sitter-cli
  -- (or: cargo install tree-sitter-cli). Without it, parser installs fail with
  -- `ENOENT ... 'tree-sitter'` and highlighting stops working.
  config = function()
    local filetypes = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }
    require('nvim-treesitter').install(filetypes)
    vim.api.nvim_create_autocmd('FileType', {
      pattern = filetypes,
      callback = function() vim.treesitter.start() end,
    })
  end,
}