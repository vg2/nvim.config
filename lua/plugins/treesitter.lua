return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local config = require("nvim-treesitter.configs")
    config.setup({
      ensure_installed = { "lua", "javascript", "typescript" },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
      ignore_install = {},
      sync_install = false,
    })
  end,
}
