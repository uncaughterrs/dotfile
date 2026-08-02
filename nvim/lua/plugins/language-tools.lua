local format_on_save_filetypes = {
  python = true,
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
  css = true,
  scss = true,
  go = true,
  rust = true,
  markdown = true,
  ["markdown.mdx"] = true,
  mdx = true,
  dockerfile = true,
}

return {
  {
    "LazyVim/LazyVim",
    init = function()
      vim.g.autoformat = false

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_language_format_on_save", { clear = true }),
        callback = function(event)
          vim.b[event.buf].autoformat = format_on_save_filetypes[vim.bo[event.buf].filetype] or false
        end,
      })

      vim.filetype.add({
        extension = {
          mdx = "markdown.mdx",
        },
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          settings = {
            python = {
              analysis = {
                diagnosticMode = "openFilesOnly",
                typeCheckingMode = "off",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                autoImportCompletions = true,
              },
            },
            basedpyright = {
              analysis = {
                diagnosticMode = "openFilesOnly",
                typeCheckingMode = "off",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                autoImportCompletions = true,
              },
            },
          },
        },
        ruff = {
          init_options = {
            settings = {
              lineLength = 100,
              lint = {
                select = { "E", "F" },
                ignore = {
                  "E501",
                  "E401",
                  "F401",
                  "F811",
                  "F541",
                },
              },
            },
          },
        },
        vtsls = {
          settings = {
            typescript = {
              updateImportsOnFileMove = {
                enabled = "always",
              },
              preferGoToSourceDefinition = true,
            },
            javascript = {
              updateImportsOnFileMove = {
                enabled = "always",
              },
              preferGoToSourceDefinition = true,
            },
          },
        },
        oxlint = {
          settings = {
            configPath = nil,
            run = "onType",
            disableNestedConfig = false,
            fixKind = "safe_fix",
            unusedDisableDirectives = "deny",
          },
        },
        oxfmt = {
          init_options = {
            settings = {
              ["fmt.configPath"] = nil,
              run = "onSave",
            },
          },
        },
        gopls = {
          settings = {
            gopls = {
              staticcheck = true,
              gofumpt = true,
            },
          },
        },
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
              },
              checkOnSave = true,
              check = {
                command = "clippy",
              },
            },
          },
        },
        dockerls = {},
      },
      setup = {
        ruff = function()
          Snacks.util.lsp.on({ name = "ruff" }, function(_, client)
            client.server_capabilities.hoverProvider = false
          end)
        end,
      },
    },
  },

  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- Formatters & Linters
        "oxfmt",
        "oxlint",
        "ruff",
        "stylua",

        -- Language Servers (LSPs)
        "basedpyright",
        "vtsls",
        "gopls",
        "rust-analyzer",
        "dockerfile-language-server",
        "lua-language-server",
      },
    },
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format" },
        javascript = { "oxfmt" },
        javascriptreact = { "oxfmt" },
        typescript = { "oxfmt" },
        typescriptreact = { "oxfmt" },
        css = { "oxfmt" },
        scss = { "oxfmt" },
        markdown = { "oxfmt" },
        ["markdown.mdx"] = { "oxfmt" },
        mdx = { "oxfmt" },
      },
    },
  },
}
