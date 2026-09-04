-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- Personal web-dev additions live in lua/custom/webdev.lua; loaded here so init.lua's
-- `require 'custom.plugins'` (SECTION 10) triggers their runtime injection after
-- upstream's base conform.setup() and lint setup() have run.
require('custom.webdev').setup()

-- Personal markdown plugins (editing tools + in-place rendering), installed
-- and configured via vim.pack from lua/custom/plugins/markdown.lua.
require('custom.plugins.markdown').setup()

-- .NET development plugin (Roslyn LSP, debugger, test runner, etc.)
require('custom.plugins.dotnet').setup()

-- You can add further personal plugin specs below; they will be picked up by vim.pack.
return {}