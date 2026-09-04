-- [[ easy-dotnet.nvim — .NET development in Neovim ]]
--
-- Brings common .NET IDE workflows into Neovim: run, debug, test,
-- manage packages, work with solutions, Roslyn LSP, and project files.
--
-- Requirements:
--  * Neovim 0.11+ built with LuaJIT (already satisfied)
--  * EasyDotnet global tool: `dotnet tool install -g EasyDotnet`
--  * telescope.nvim (already installed in init.lua SECTION 5)
--
-- Useful commands (run `:Dotnet` to see all):
--  :Dotnet run                    — run project (picker)
--  :Dotnet run default            — run default project
--  :Dotnet run profile            — run with launch profile
--  :Dotnet debug                  — debug project (picker)
--  :Dotnet build                  — build project
--  :Dotnet build solution         — build entire solution
--  :Dotnet test                   — run tests
--  :Dotnet testrunner             — toggle test runner UI
--  :Dotnet restore                — restore packages
--  :Dotnet clean                  — clean build artefacts
--  :Dotnet add package            — add NuGet package
--  :Dotnet outdated               — show outdated packages (in .csproj)
--  :Dotnet secrets                — manage user secrets
--  :Dotnet new                    — create from dotnet template
--  :Dotnet ef migrations add      — add EF migration
--  :Dotnet ef database update     — apply EF migrations
--
-- Called from lua/custom/plugins/init.lua.
local M = {}

function M.setup()
  -- Install the plugin
  vim.pack.add { 'https://github.com/GustavEikaas/easy-dotnet.nvim' }

  local dotnet = require('easy-dotnet')

  dotnet.setup {
    -- Use telescope since it's already installed
    picker = 'telescope',

    -- Terminal behaviour for build/run output
    managed_terminal = {
      auto_hide = true,
      auto_hide_delay = 1000,
    },

    -- Built-in Roslyn LSP (auto-starts for C# / Razor / CSHTML)
    lsp = {
      enabled = true,
      preload_roslyn = true,
      roslynator_enabled = true,
      easy_dotnet_analyzer_enabled = true,
      auto_refresh_codelens = true,
      suggest_updates = true,
      razor = {
        enabled = true,
        html = { enabled = true },
      },
    },

    -- Debugger (netcoredbg) — auto-registers with nvim-dap if present
    debugger = {
      engine = 'netcoredbg',
      console = 'integratedTerminal',
      auto_register_dap = true,
      apply_value_converters = true,
    },

    -- Test runner (Rider-like UI)
    test_runner = {
      auto_start_testrunner = true,
      viewmode = 'float',
      neotest_integration = false,
    },

    -- Auto-insert namespace + class when opening new .cs files
    auto_bootstrap_namespace = {
      type = 'block_scoped',
      enabled = true,
    },

    -- Enable keymaps inside .csproj / .fsproj files
    csproj_mappings = true,
    fsproj_mappings = true,

    -- Workspace diagnostics
    diagnostics = {
      default_severity = 'error',
      setqflist = false,
    },
  }

  -- ============================================================
  -- Keymaps
  -- ============================================================
  local map = vim.keymap.set
  local opts = { noremap = true, silent = true }

  -- Run / Debug
  map('n', '<leader>dr', dotnet.run, vim.tbl_extend('force', opts, { desc = '[D]otnet [R]un (picker)' }))
  map('n', '<leader>dR', dotnet.run_default, vim.tbl_extend('force', opts, { desc = '[D]otnet [R]un default' }))
  map('n', '<leader>dd', dotnet.debug, vim.tbl_extend('force', opts, { desc = '[D]otnet [D]ebug (picker)' }))
  map('n', '<leader>dD', dotnet.debug_default, vim.tbl_extend('force', opts, { desc = '[D]otnet [D]ebug default' }))

  -- Build
  map('n', '<leader>db', dotnet.build, vim.tbl_extend('force', opts, { desc = '[D]otnet [B]uild (picker)' }))
  map('n', '<leader>dB', dotnet.build_solution, vim.tbl_extend('force', opts, { desc = '[D]otnet [B]uild solution' }))
  map('n', '<leader>dq', dotnet.build_quickfix, vim.tbl_extend('force', opts, { desc = '[D]otnet build [Q]uickfix' }))

  -- Test
  map('n', '<leader>dt', dotnet.test, vim.tbl_extend('force', opts, { desc = '[D]otnet [T]est (picker)' }))
  map('n', '<leader>dT', dotnet.test_solution, vim.tbl_extend('force', opts, { desc = '[D]otnet [T]est solution' }))
  map('n', '<leader>dtr', dotnet.testrunner, vim.tbl_extend('force', opts, { desc = '[D]otnet [T]est [R]unner toggle' }))

  -- Package / Solution management
  map('n', '<leader>dp', dotnet.add_package, vim.tbl_extend('force', opts, { desc = '[D]otnet add [P]ackage' }))
  map('n', '<leader>do', dotnet.outdated, vim.tbl_extend('force', opts, { desc = '[D]otnet [O]utdated packages' }))
  map('n', '<leader>ds', dotnet.secrets, vim.tbl_extend('force', opts, { desc = '[D]otnet [S]ecrets' }))
  map('n', '<leader>dn', dotnet.new, vim.tbl_extend('force', opts, { desc = '[D]otnet [N]ew template' }))

  -- Restore / Clean
  map('n', '<leader>drr', dotnet.restore, vim.tbl_extend('force', opts, { desc = '[D]otnet [R]esto[r]e' }))
  map('n', '<leader>dc', dotnet.clean, vim.tbl_extend('force', opts, { desc = '[D]otnet [C]lean' }))

  -- Entity Framework
  map('n', '<leader>dem', function() dotnet.ef_migrations_add(vim.fn.input 'Migration name: ') end,
    vim.tbl_extend('force', opts, { desc = '[D]otnet [E]F [M]igrations add' }))
  map('n', '<leader>deu', dotnet.ef_database_update,
    vim.tbl_extend('force', opts, { desc = '[D]otnet [E]F database [U]pdate' }))

  -- Watch
  map('n', '<leader>dw', dotnet.watch, vim.tbl_extend('force', opts, { desc = '[D]otnet [W]atch' }))

  -- Reset persisted selections
  map('n', '<leader>dX', dotnet.reset, vim.tbl_extend('force', opts, { desc = '[D]otnet reset persisted state' }))

  -- Which-key group
  local ok_wk, wk = pcall(require, 'which-key')
  if ok_wk then
    wk.add { { '<leader>d', group = '[D]otnet', mode = { 'n' } } }
  end
end

return M
