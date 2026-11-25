-- [[ Rust development ]]
--
-- Adds two plugins:
--  1. mrcjkb/rustaceanvim — runs and configures rust-analyzer itself (do NOT
--     also enable `rust_analyzer` through vim.lsp.enable / mason-lspconfig, or
--     you get two clients). Adds :RustLsp commands: runnables, debuggables,
--     testables, expand macro, explain error, open Cargo.toml, etc.
--     Auto-registers codelldb with nvim-dap for debugging.
--  2. saecki/crates.nvim — inline crate versions, completion and update actions
--     inside Cargo.toml (completion via its in-process LSP, picked up by blink.cmp).
--
-- Requirements:
--  * Rust toolchain via rustup, with components:
--      rustup component add rust-analyzer rustfmt clippy
--    (install-prereqs.sh does this). Using rustup's rust-analyzer keeps it in
--    sync with your toolchain, which is why it is not installed via mason.
--  * codelldb debug adapter — auto-installed by mason (see M.tools below).
--
-- Keymaps (buffer-local, Rust buffers only; <leader>r group):
--  <leader>rr  runnables          <leader>rd  debuggables
--  <leader>rt  testables          <leader>rR  re-run last runnable
--  <leader>re  explain error      <leader>rD  render diagnostic
--  <leader>rm  expand macro       <leader>rc  open Cargo.toml
--  <leader>rp  parent module      <leader>rj  join lines
--  <leader>ra  code action (grouped, rust-analyzer)
--  K           hover actions (rust-analyzer)
-- Cargo.toml (<leader>c group):
--  <leader>cu  update crate       <leader>cU  upgrade crate
--  <leader>cA  upgrade all        <leader>ci  crate info popup
--
-- Called from lua/custom/plugins/init.lua.
local M = {}

-- Extra mason tools to auto-install (list-extended into `ensure_installed` in init.lua SECTION 6).
M.tools = { 'codelldb' }

function M.setup()
  -- Must be set before rustaceanvim's ftplugin runs on the first Rust buffer.
  ---@type rustaceanvim.Opts
  vim.g.rustaceanvim = {
    server = {
      on_attach = function(_, bufnr)
        local map = function(keys, func, desc) vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Rust: ' .. desc }) end
        local rust = function(...)
          local args = { ... }
          return function() vim.cmd.RustLsp(args) end
        end

        map('<leader>rr', rust 'runnables', '[R]unnables')
        map('<leader>rR', rust('runnables', 'last'), '[R]e-run last runnable')
        map('<leader>rd', rust 'debuggables', '[D]ebuggables')
        map('<leader>rt', rust 'testables', '[T]estables')
        map('<leader>re', rust 'explainError', '[E]xplain error')
        map('<leader>rD', rust 'renderDiagnostic', 'Render [D]iagnostic')
        map('<leader>rm', rust 'expandMacro', 'Expand [M]acro')
        map('<leader>rc', rust 'openCargo', 'Open [C]argo.toml')
        map('<leader>rp', rust 'parentModule', '[P]arent module')
        map('<leader>rj', rust 'joinLines', '[J]oin lines')
        map('<leader>ra', rust 'codeAction', 'Code [A]ction (grouped)')
        map('K', rust('hover', 'actions'), 'Hover actions')
      end,
      default_settings = {
        ['rust-analyzer'] = {
          cargo = { allFeatures = true },
          -- Run clippy instead of `cargo check` on save for richer diagnostics.
          check = { command = 'clippy' },
          procMacro = { enable = true },
          inlayHints = {
            lifetimeElisionHints = { enable = 'skip_trivial' },
          },
        },
      },
    },
  }

  vim.pack.add {
    'https://github.com/mrcjkb/rustaceanvim',
    'https://github.com/saecki/crates.nvim',
  }

  local crates = require 'crates'
  crates.setup {
    lsp = {
      enabled = true,
      actions = true,
      completion = true,
      hover = true,
    },
  }

  vim.api.nvim_create_autocmd('BufRead', {
    group = vim.api.nvim_create_augroup('custom-crates-keymaps', { clear = true }),
    pattern = 'Cargo.toml',
    callback = function(event)
      local map = function(keys, func, desc) vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'Crates: ' .. desc }) end
      map('<leader>cu', crates.update_crate, '[U]pdate crate')
      map('<leader>cU', crates.upgrade_crate, '[U]pgrade crate')
      map('<leader>cA', crates.upgrade_all_crates, 'Upgrade [A]ll crates')
      map('<leader>ci', crates.show_popup, 'Crate [I]nfo')
    end,
  })

  -- Format Rust with rustfmt via conform (injected after init.lua's conform.setup()).
  local ok_conform, conform = pcall(require, 'conform')
  if ok_conform then conform.formatters_by_ft.rust = { 'rustfmt', lsp_format = 'fallback' } end

  local ok_wk, wk = pcall(require, 'which-key')
  if ok_wk then wk.add {
    { '<leader>r', group = '[R]ust' },
    { '<leader>c', group = '[C]rates' },
  } end
end

return M
