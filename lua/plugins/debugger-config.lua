return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
    },
    config = function()
      local dap = require("dap")

      vim.keymap.set("n", "<F5>", dap.continue, {})
      vim.keymap.set("n", "<F10>", dap.step_over, {})
      vim.keymap.set("n", "<F11>", dap.step_into, {})
      vim.keymap.set("n", "<F12>", dap.step_out, {})
      vim.keymap.set("n", "<leader>dt", dap.toggle_breakpoint, {})

      local dapui = require("dapui")

      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end

      dap.adapters.coreclr = {
        type = "executable",
        command = "C:/Users/g994441/netcoredbg/netcoredbg.exe",
        args = { "--interpreter=vscode" },
      }

      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "launch - netcoredbg",
          request = "launch",
          program = function()
            local absPathToProj =
                vim.fn.input("Path to folder containing project: ", vim.fn.getcwd(), "file")

            local netruntime = vim.fn.input("netruntime: ", "net6.0")

            local debugPath = "/bin/Debug/"

            local dll = vim.fn.input("dll: ")

            return absPathToProj .. debugPath .. netruntime .. "/" .. dll
          end,
        },
      }
    end,
  },
}
