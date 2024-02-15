return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>tf", builtin.find_files, { desc = "[T]elescope [F]ind files" })
      vim.keymap.set("n", "<leader>tl", builtin.live_grep, { desc = "[T]elescope [L]ive grep" })
      vim.keymap.set("n", "<leader>tg", builtin.git_files, { desc = "[T]elescope [G]it files" })
    end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    config = function()
      require("telescope").setup({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })
      require("telescope").load_extension("ui-select")
    end,
  },
}
