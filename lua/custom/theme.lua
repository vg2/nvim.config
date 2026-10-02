-- Automatic light/dark colorscheme switching.
--
-- Neovim's TUI detects the terminal's background color (OSC 11) and, when the
-- terminal supports DEC mode 2031, re-detects it whenever the terminal/OS
-- changes between light and dark. Neovim reflects this in the 'background'
-- option, which is what this module maps to a colorscheme.
--
-- Ghostty supports both OSC 11 and mode 2031, so switching is fully live there.
-- Windows Terminal does not support mode 2031 (yet) and, depending on the ConPTY
-- version, may not deliver OSC 11 responses to WSL at all. In that case we fall
-- back to the Windows light/dark setting, which is what Windows Terminal follows
-- when it is configured with a light/dark theme pair.
--
--     themes.dark   -> used when 'background' is "dark"
--     themes.light  -> used when 'background' is "light"
--
-- `:ToggleTheme` (or <leader>tt) manually overrides the choice for the session;
-- the next real terminal color-scheme change takes over again.
local M = {}

M.themes = {
  dark = 'tokyonight-night',
  light = 'catppuccin-latte',
}

local augroup = vim.api.nvim_create_augroup('custom-theme', { clear = true })

-- True while we are the ones changing 'background' (so we don't react to
-- our own change).
local applying = false
-- True once the terminal (or 'background' itself) has told us the real
-- background color. Disables the Windows registry fallback.
local terminal_reported = false
-- True after a manual :ToggleTheme, until the terminal reports a change again.
local manual_override = false

---@return 'dark'|'light'
local function current_variant() return vim.o.background == 'light' and 'light' or 'dark' end

---Load the colorscheme for `variant`, setting 'background' to match.
---@param variant 'dark'|'light'|nil
---@param opts? { silent?: boolean }
function M.apply(variant, opts)
  opts = opts or {}
  if variant ~= 'dark' and variant ~= 'light' then return end

  local scheme = M.themes[variant]
  if not scheme then
    vim.notify(('No %s theme configured'):format(variant), vim.log.levels.ERROR)
    return
  end

  -- Nothing to do if this exact scheme is already active for this background.
  if vim.g.colors_name == scheme and vim.o.background == variant then return end

  applying = true
  vim.o.background = variant
  vim.cmd.colorscheme(scheme)
  applying = false

  if not opts.silent then vim.notify(('Theme: %s'):format(scheme), vim.log.levels.INFO) end
end

---Manually switch to the opposite variant for this session.
function M.toggle()
  manual_override = true
  M.apply(current_variant() == 'light' and 'dark' or 'light')
end

-- Terminal response handling ------------------------------------------------

---Parse an OSC 11 response and classify it as dark or light.
---@param resp string
---@return 'dark'|'light'|nil
local function variant_from_osc11(resp)
  local r, g, b = resp:match('^\027%]11;rgb:(%x+)/(%x+)/(%x+)$')
  if not r then r, g, b = resp:match('^\027%]11;rgba:(%x+)/(%x+)/(%x+)/%x+$') end
  if not r then return nil end

  ---@param c string
  local function channel(c)
    local value = tonumber(c, 16)
    if not value then return nil end
    return value / (16 ^ #c - 1)
  end

  local rr, gg, bb = channel(r), channel(g), channel(b)
  if not (rr and gg and bb) then return nil end

  -- Relative luminance, same formula Neovim itself uses.
  local luminance = 0.299 * rr + 0.587 * gg + 0.114 * bb
  return luminance < 0.5 and 'dark' or 'light'
end

---Extract a variant from any terminal response we care about.
---@param resp string
---@return 'dark'|'light'|nil
local function variant_from_response(resp)
  local from_osc11 = variant_from_osc11(resp)
  if from_osc11 then return from_osc11 end

  -- DEC mode 2031 notification: CSI ? 997 ; Ps n  (Ps=1 dark, Ps=2 light)
  local ps = resp:match('^\027%[%?997;(%d)n$')
  if ps == '1' then return 'dark' end
  if ps == '2' then return 'light' end
  return nil
end

-- Windows Terminal fallback --------------------------------------------------

---Read the Windows "apps use light theme" value.
---Works both in WSL (via interop) and under native Windows Neovim.
---@return 'dark'|'light'|nil
local function windows_system_variant()
  local reg = vim.fn.has 'win32' == 1 and 'reg.exe' or '/mnt/c/Windows/System32/reg.exe'
  if vim.fn.executable(reg) ~= 1 then return nil end

  local out = vim.fn.system {
    reg,
    'query',
    [[HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize]],
    '/v',
    'AppsUseLightTheme',
  }
  if vim.v.shell_error ~= 0 then return nil end

  local value = out:match('AppsUseLightTheme%s+REG_DWORD%s+0x(%x+)')
  if not value then return nil end
  return tonumber(value, 16) == 1 and 'light' or 'dark'
end

local last_windows_check = 0
local function refresh_from_windows()
  if terminal_reported or manual_override then return end

  -- Don't shell out on every focus event.
  local now = vim.uv.now()
  if now - last_windows_check < 2000 then return end
  last_windows_check = now

  local variant = windows_system_variant()
  if variant and variant ~= current_variant() then M.apply(variant, { silent = true }) end
end

-- Setup ----------------------------------------------------------------------

---@param opts? { auto?: boolean, default?: 'dark'|'light', keymap?: string|false }
function M.setup(opts)
  opts = opts or {}

  vim.api.nvim_create_user_command('ToggleTheme', M.toggle, {
    desc = 'Toggle between the configured light and dark colorschemes',
  })

  if opts.keymap ~= false then
    vim.keymap.set('n', opts.keymap or '<leader>tt', M.toggle, { desc = '[T]oggle [T]heme' })
  end

  -- Detection may already have completed during startup (before this autocmd
  -- existed); 'background' being set at this point means it did.
  if vim.api.nvim_get_option_info2('background', {}).was_set then terminal_reported = true end

  if opts.auto == false then
    M.apply(opts.default or current_variant(), { silent = true })
    return
  end

  -- Primary: Neovim's TUI asks the terminal for its background color (OSC 11)
  -- and forwards the answer here. Mode 2031 notifications arrive here too.
  vim.api.nvim_create_autocmd('TermResponse', {
    group = augroup,
    nested = true,
    desc = 'Follow the terminal background color',
    callback = function(ev)
      local variant = variant_from_response(ev.data.sequence)
      if variant then
        terminal_reported = true
        manual_override = false
        M.apply(variant, { silent = true })
      end
    end,
  })

  -- Secondary: cover any path that changes 'background' without us seeing the
  -- raw terminal response. Runs after Nvim's own colorscheme reload.
  vim.api.nvim_create_autocmd('OptionSet', {
    group = augroup,
    pattern = 'background',
    desc = 'Follow changes to the background option',
    callback = function()
      if applying then return end
      terminal_reported = true
      manual_override = false
      M.apply(current_variant(), { silent = true })
    end,
  })

  M.apply(current_variant(), { silent = true })

  -- Windows Terminal (and native Windows, where Neovim cannot query OSC 11): if
  -- Nvim never got an OSC 11 response, follow the Windows light/dark setting
  -- instead, and re-check when the terminal regains focus (Windows Terminal
  -- cannot notify us of theme changes).
  if vim.env.WT_SESSION or vim.fn.has 'win32' == 1 then
    vim.defer_fn(function()
      if not terminal_reported then refresh_from_windows() end
    end, 300)

    vim.api.nvim_create_autocmd('FocusGained', {
      group = augroup,
      desc = 'Re-check the Windows theme when Windows Terminal regains focus',
      callback = function() vim.schedule(refresh_from_windows) end,
    })
  end
end

return M
