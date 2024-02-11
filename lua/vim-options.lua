vim.o.expandtab = true
vim.o.smartindent = true
vim.o.softtabstop = 4
vim.o.shiftwidth = 4

vim.g.mapleader = " "

-- Navigate vim panes better
vim.keymap.set("n", "<c-k>", ":wincmd k<CR>")
vim.keymap.set("n", "<c-j>", ":wincmd j<CR>")
vim.keymap.set("n", "<c-h>", ":wincmd h<CR>")
vim.keymap.set("n", "<c-l>", ":wincmd l<CR>")

vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>")

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

vim.wo.number = true
vim.o.relativenumber = true

vim.o.clipboard = "unnamedplus"

vim.o.undofile = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.wo.signcolumn = "yes"

vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.o.completeopt = "menuone,noselect"

vim.o.termguicolors = true
