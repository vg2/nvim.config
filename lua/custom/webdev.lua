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
  'prettierd',
}

-- Conform formatters by filetype.
M.formatters_by_ft = {
  lua = { 'stylua' },
  javascript = { 'oxfmt' },
  typescript = { 'oxfmt' },
  javascriptreact = { 'oxfmt' },
  typescriptreact = { 'oxfmt' },
  markdown = { 'prettierd', 'prettier', stop_after_first = true },
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