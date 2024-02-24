return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    vim.keymap.set("n", "<C-n>", ":Neotree toggle filesystem left<cr>", { desc = "Neotree toggle left" })
    vim.keymap.set("n", "<leader>fb", ":Neotree toggle buffers float<cr>", { desc = "Toggle [f]loating [b]uffers" })
    vim.keymap.set("n", "<leader>ff", ":Neotree show filesystem left reveal_file=<cfile> reveal_force_cwd<cr>",
      { desc = "[F]ocus current [f]ile in file tree" })
  end,
}
