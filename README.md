# Neovim Configuration

A personalized Neovim configuration based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). This setup provides a robust Personal Development Environment (PDE) with sane defaults and an organized structure for easy customization.

## 📂 Project Structure

The configuration is modularized to separate core "kickstart" features from user custom settings:

```text
lua/
├── custom/           # User-specific configuration
│   └── plugins/      # Place your custom plugin specs here
├── kickstart/        # Core configuration modules
│   ├── default/      # Default plugins (LSP, Telesope, etc.)
│   └── plugins/      # Modular plugins (Linting, Neo-tree, etc.)
└── init.lua          # Bootstrap and core options
```

## 🔌 Plugin Management

Plugins are managed via [lazy.nvim](https://github.com/folke/lazy.nvim).

### Core Plugins
- **LSP**: Native LSP with [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig).
- **Completion**: [blink.cmp](https://github.com/Saghen/blink.cmp) for fast, reliable completion.
- **Formatting**: [conform.nvim](https://github.com/stevearc/conform.nvim) for auto-formatting.
- **Linting**: [nvim-lint](https://github.com/mfussenegger/nvim-lint) for asynchronous linting.
- **File Explorer**: [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim).
- **Fuzzy Finder**: [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim).
- **Highlighting**: [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter).
- **Theme**: [tokyonight.nvim](https://github.com/folke/tokyonight.nvim).

## 🛠️ Tool Installation (Mason)

External tools (LSP servers, linters, formatters) are managed by [mason.nvim](https://github.com/williamboman/mason.nvim).

**Note on Installation:**
While plugins are configured in their respective files (e.g., `lua/kickstart/plugins/lint.lua`), the actual installation of tools is centralized in `lua/kickstart/default/lsp.lua`. This ensures all binary dependencies are installed automatically without conflicts.

### Installed Tools

**LSP Servers:**
- `lua-language-server` (Lua)
- `ts_ls` (TypeScript/JavaScript) - requires typescript-language-server installed
- `cssls` (CSS)
- `html` (HTML)
- `jsonls` (JSON)

**Linters:**
- `markdownlint` (Markdown)
- `oxlint` (JavaScript/TypeScript - High performance)

**Formatters:**
- `stylua` (Lua)
- `oxfmt` (JavaScript/TypeScript - Experimental/Manual install may be required if not in Mason)

## 🚀 Getting Started

1. **Prerequisites**:
   - Neovim >= 0.9.0
   - A [Nerd Font](https://www.nerdfonts.com/) (recommended for icons)
   - `ripgrep` (required for Telescope live grep)
   - A C compiler (gcc/clang) for Treesitter parsers
   - Node.js & npm (required for many web formatters/LSPs)
   - **Note:** `oxfmt` might need manual installation (e.g., `npm install -g oxfmt` or `cargo install oxfmt`) if not available via Mason.

2. **Installation**:
   Clone this repository to your config location:
   ```bash
   git clone <your-repo-url> ~/.config/nvim
   ```

3. **First Launch**:
   Open Neovim (`nvim`). `lazy.nvim` will automatically bootstrap and install all defined plugins. Mason will then install the configured servers and tools.

## ⌨️ Keymaps

The leader key is set to `<Space>`.

- `<Space>f`: Format buffer
- `<Space>sk`: Search keymaps
- `grn`: Rename symbol
- `gra`: Code action
- `grD`: Goto declaration
- `<C-h/j/k/l>`: Navigate splits

See `lua/kickstart/default/which_key.lua` and `init.lua` for more definitions.
