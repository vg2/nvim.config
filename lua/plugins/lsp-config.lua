return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
      -- [[ Configure LSP ]]
      --  This function gets run when an LSP connects to a particular buffer.
      local on_attach = function(_, bufnr)
        local nmap = function(keys, func, desc)
          if desc then
            desc = "LSP: " .. desc
          end

          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
        end

        nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

        nmap("<leader>gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
        nmap("<leader>gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
        nmap("<leader>gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
        nmap("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
        nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
        nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

        -- See `:help K` for why this keymap
        nmap("K", vim.lsp.buf.hover, "Hover Documentation")
        nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

        -- Lesser used LSP functionality
        nmap("<leader>gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
        nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
        nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
        nmap("<leader>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, "[W]orkspace [L]ist Folders")

        -- Create a command `:Format` local to the LSP buffer
        vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
          vim.lsp.buf.format()
        end, { desc = "Format current buffer with LSP" })
      end

      local servers = {
        rust_analyzer = {},
        tsserver = {},
        html = { filetypes = { "html", "twig", "hbs" } },
        omnisharp = {},
        lua_ls = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      }

      local mason_lspconfig = require("mason-lspconfig")

      mason_lspconfig.setup({
        ensure_installed = vim.tbl_keys(servers),
      })

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      mason_lspconfig.setup_handlers({
        function(server_name)
          require("lspconfig")[server_name].setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = servers[server_name],
            filetypes = (servers[server_name] or {}).filetypes,
          })
        end,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
  },
  {
    {
      "nvimtools/none-ls.nvim",
      config = function()
        local null_ls = require("null-ls")
        null_ls.setup({
          sources = {
            null_ls.builtins.formatting.stylua,
            null_ls.builtins.formatting.prettierd,
            null_ls.builtins.formatting.eslint_d,
          },
        })
        vim.keymap.set("n", "<leader>fd", vim.lsp.buf.format, { desc = "[F]ormat [D]ocument" })

        -- Switch for controlling whether you want autoformatting.
        --  Use :AutoFormatToggle to toggle autoformatting on or off
        local format_is_enabled = true
        vim.api.nvim_create_user_command("AutoFormatToggle", function()
          format_is_enabled = not format_is_enabled
          print("Setting autoformatting to: " .. tostring(format_is_enabled))
        end, {})

        -- Create an augroup that is used for managing our formatting autocmds.
        --      We need one augroup per client to make sure that multiple clients
        --      can attach to the same buffer without interfering with each other.
        local _augroups = {}
        local get_augroup = function(client)
          if not _augroups[client.id] then
            local group_name = "auto-lsp-format-" .. client.name
            local id = vim.api.nvim_create_augroup(group_name, { clear = true })
            _augroups[client.id] = id
          end

          return _augroups[client.id]
        end

        -- Whenever an LSP attaches to a buffer, we will run this function.
        --
        -- See `:help LspAttach` for more information about this autocmd event.
        vim.api.nvim_create_autocmd("LspAttach", {
          group = vim.api.nvim_create_augroup("auto-lsp-attach-format", { clear = true }),
          -- This is where we attach the autoformatting for reasonable clients
          callback = function(args)
            local client_id = args.data.client_id
            local client = vim.lsp.get_client_by_id(client_id)
            local bufnr = args.buf

            -- Only attach to clients that support document formatting
            if not client.server_capabilities.documentFormattingProvider then
              return
            end

            -- Tsserver usually works poorly. Sorry you work with bad languages
            -- You can remove this line if you know what you're doing :)
            if client.name == "tsserver" then
              return
            end

            -- Create an autocmd that will run *before* we save the buffer.
            --  Run the formatting command for the LSP that has just attached.
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = get_augroup(client),
              buffer = bufnr,
              callback = function()
                if not format_is_enabled then
                  return
                end

                vim.lsp.buf.format({
                  async = false,
                  filter = function(c)
                    return c.id == client.id
                  end,
                })
              end,
            })
          end,
        })
      end,
    },
  },
  {
    "jay-babu/mason-null-ls.nvim",
    config = function()
      local mason_null_ls = require("mason-null-ls")
      mason_null_ls.setup({
        ensure_installed = nil,
        automatic_installation = true,
      })
    end,
  },
}
