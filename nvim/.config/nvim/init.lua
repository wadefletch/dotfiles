-- Wade Fletcher
-- Neovim 0.9 config

-- ========================= LAZY (PLUGIN MANAGER) ========================= --
-- install lazy.nvim as plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)
-- ========================================================================= --

-- ============================= CONFIGURATION ============================= --
-- set <space> as the leader key
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- use 4 spaces instead of tabs
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- color column at 80 and 120
vim.opt.colorcolumn = "80,120"

-- sync clipboard between os and neovim
vim.opt.clipboard = "unnamedplus"

-- enable highlight groups
vim.opt.termguicolors = true

-- disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- disable mode (lualine instead)
vim.opt.showmode = false
-- ========================================================================= --

-- ================================ PLUGINS ================================ --
-- configure plugins
require("lazy").setup({
    -- autopairs
    {
        "echasnovski/mini.pairs",
        version = "*",
        config = function()
            require("mini.pairs").setup({
                disable_filetype = { "TelescopePrompt" },
            })
        end,
    },

    -- terminal
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        config = true,
    },

    -- git
    { "tpope/vim-fugitive" },
    { "tpope/vim-rhubarb" },

    -- github copilot
    {
        "github/copilot.vim",
        init = function()
            vim.g.copilot_filetypes = { markdown = true }
        end,
    },
    { "ofseed/copilot-status.nvim" },

    -- diagnostics
    {
        "folke/trouble.nvim",
        opts = { icons = false },
    },

    -- folding
    { -- UFO
        "kevinhwang91/nvim-ufo",
        dependencies = "kevinhwang91/promise-async",
        event = "BufReadPost", -- needed for folds to load in time
        keys = {
            {
                "zr",
                function()
                    require("ufo").openAllFolds()
                end,
                desc = "Open All Folds",
            },
            {
                "zm",
                function()
                    require("ufo").closeAllFolds()
                end,
                desc = "Close All Folds",
            },
        },
        init = function()
            vim.opt.foldlevel = 99
            vim.opt.foldlevelstart = 99
        end,
        opts = {
            provider_selector = function(_, ft, _)
                local lspWithOutFolding = { "markdown", "sh", "css", "html", "python" }
                if vim.tbl_contains(lspWithOutFolding, ft) then
                    return { "treesitter", "indent" }
                end
                return { "lsp", "indent" }
            end,
        },
    },

    -- colorscheme
    {
        "oxfist/night-owl.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("night-owl").setup()
            vim.cmd.colorscheme("night-owl")
        end,
    },

    -- nvim-tree
    {
        "nvim-tree/nvim-tree.lua",
        opts = {
            renderer = {
                icons = {
                    show = {
                        git = false,
                        file = false,
                        folder = false,
                    },
                },
            },
            git = {
                ignore = false,
            },
        },
    },

    -- lualine
    {
        "nvim-lualine/lualine.nvim",
        opts = {
            options = {
                disabled_filetypes = { "NvimTree", "Trouble" },
                icons_enabled = false,
                component_separators = "|",
                section_separators = "",
            },
            sections = {
                lualine_x = {
                    {
                        "copilot",
                        show_running = true,
                        symbols = {
                            status = {
                                enabled = "copilot on ",
                                disabled = "copilot off",
                            },
                        },
                    },
                    "filetype",
                    "fileformat",
                    "encoding",
                },
            },
        },
    },

    -- formatter
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                javascript = { { "prettierd", "prettier" } },
                javascriptreact = { { "prettierd", "prettier" } },
                typescript = { { "prettierd", "prettier" } },
                typescriptreact = { { "prettierd", "prettier" } },
                terraform = { "terraform_fmt" },
                python = { "isort", "black" },
            },
            format_on_save = function(bufnr)
                if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                    return
                end
                return { timeout_ms = 500, lsp_fallback = true }
            end,
            notify_on_error = false,
        },
        init = function()
            -- Format the current buffer with :Format
            vim.api.nvim_create_user_command("Format", function(args)
                local range = nil
                if args.count ~= -1 then
                    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
                    range = {
                        start = { args.line1, 0 },
                        ["end"] = { args.line2, end_line:len() },
                    }
                end
                require("conform").format({ async = true, lsp_fallback = true, range = range })
            end, { range = true })

            -- Disable format_on_save in the current buffer with :FormatDisable
            -- or globally with :FormatDisable!
            vim.api.nvim_create_user_command("FormatDisable", function(args)
                if args.bang then
                    vim.g.disable_autoformat = true
                else
                    vim.b.disable_autoformat = true
                end
            end, {
                desc = "Disable autoformat-on-save",
                bang = true,
            })

            -- Enable format_on_save in the current buffer with :FormatEnable
            vim.api.nvim_create_user_command("FormatEnable", function()
                vim.b.disable_autoformat = false
                vim.g.disable_autoformat = false
            end, {
                desc = "Enable autoformat-on-save",
            })
        end,
    },

    -- linter
    {
        "mfussenegger/nvim-lint",
        config = function()
            require("lint").linters_by_ft = {
                javascript = { "eslint" },
                javascriptreact = { "eslint" },
                typescript = { "eslint" },
                typescriptreact = { "eslint" },
                terraform = { "tflint" },
            }

            -- lint on open, save
            vim.api.nvim_create_autocmd("BufReadPre", {
                callback = function()
                    require("lint").try_lint()
                end,
            })

            -- prevent layout shift with new error
            vim.opt.signcolumn = "yes"
        end,
    },

    -- keymapping hints
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
        end,
        opts = {
            plugins = {
                presets = {
                    f = true,
                },
            },
        },
    },

    -- telescope (fuzzy finder)
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.3",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            -- enable twilight behind telescope previewer
            vim.cmd("autocmd! User TelescopePreviewerLoaded TwilightEnable")
            vim.cmd("autocmd! BufLeave * TwilightDisable")
        end,
    },

    -- treesitter (AST syntax highlighting)
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            local configs = require("nvim-treesitter.configs")

            configs.setup({
                ensure_installed = { "lua", "javascript", "typescript", "html", "comment", "python" },
                sync_install = false,
                auto_install = true,
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                indent = { enable = true },
            })
        end,
    },

    -- bufferline
    {
        "akinsho/bufferline.nvim",
        opts = {
            options = {
                buffer_close_icon = "",
                close_icon = "",
                show_buffer_icons = false,
            },
            highlights = {
                buffer_selected = {
                    italic = false,
                },
            },
        },
    },

    -- twilight
    {
        "folke/twilight.nvim",
        opts = {
            context = 0,
        },
    },

    -- lsp
    {
        "neovim/nvim-lspconfig",
        config = function() end,
    },

    -- mason
    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        config = true,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        opts = {
            ensure_installed = {
                "lua_ls",
                "tsserver",
                "html",
                "cssls",
                "jsonls",
                "terraformls",
                "tflint",
                "ruff_lsp",
            },
            handlers = {
                function(server)
                    require("lspconfig")[server].setup({})
                end,
                lua_ls = function(server)
                    require("lspconfig")[server].setup({
                        settings = {
                            Lua = {
                                diagnostics = {
                                    globals = { "vim" },
                                },
                            },
                        },
                    })
                end,
            },
        },
    },

    -- gitsigns
    {
        "lewis6991/gitsigns.nvim",
        config = true,
    },
}, {
    -- lazy.nvim opts
})
-- ========================================================================= --

-- ============================== KEYMAPPINGS ============================== --
-- telescope
local telescope = require("telescope.builtin")

vim.keymap.set("n", "<leader>ff", telescope.find_files, { desc = "[F]ind [F]iles" })
vim.keymap.set("n", "<leader>fg", telescope.git_files, { desc = "[F]ind [G]it Files" })
vim.keymap.set("n", "<leader>fh", telescope.help_tags, { desc = "[F]ind [H]elp Tags" })
-- the following line causes an error
-- vim.keymap.set("n", "<leader>fd", builtin.diagnotics, { desc = "[F]ind [D]iagnostics" })
vim.keymap.set("n", "<leader>fb", telescope.buffers, { desc = "[F]ind [B]uffers" })
vim.keymap.set("n", "<leader>fl", telescope.live_grep, { desc = "[F]ind [L]ive" })

-- nvim-tree
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "[E]xplorer", silent = true })

-- twilight
vim.keymap.set("n", "<leader>w", ":Twilight<CR>", { desc = "T[w]ilight" })

-- terminal
vim.keymap.set("n", "<leader>t", ":ToggleTerm<CR>", { desc = "[T]erminal" })

-- fast jk to escape
vim.keymap.set("i", "jk", "<Esc>", { silent = true })
vim.keymap.set("t", "jk", "<C-\\><C-n>", { silent = true })

-- move lines around with J or K
vim.keymap.set("x", "J", ":move '>+1<CR>gv-gv", { silent = true })
vim.keymap.set("x", "K", ":move '<-2<CR>gv-gv", { silent = true })

-- move left and right between buffers with shift + h/l
vim.keymap.set("n", "<S-l>", ":bnext<CR>", { silent = true })
vim.keymap.set("n", "<S-h>", ":bprevious<CR>", { silent = true })

-- toggle between last two buffers with <leader><leader>
vim.keymap.set("n", "<leader><leader>", "<C-^>", { silent = true, desc = "Swap Buffers" })

-- close buffer with <leader>q
vim.keymap.set("n", "<leader>q", ":bdelete<CR>:bnext<CR>", { silent = true, desc = "[Q]uit Buffer" })

-- close all buffers but current with <leader>qo
vim.keymap.set("n", "<leader>qo", ":%bd|e#|bd#<cr>|'\"", { silent = true, desc = "[Q]uit [O]ther Buffers" })

-- escape to normal mode in terminal
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { silent = true })

-- close terminal with <leader>q
vim.keymap.set("t", "<leader>q", "<C-\\><C-n><C-W>", { silent = true, desc = "[Q]uit Terminal" })

-- toggle trouble with <leader>d
vim.keymap.set("n", "<leader>d", ":TroubleToggle<CR>", { silent = true, desc = "[D]iagnostics" })

-- format with <leader>f
vim.keymap.set("n", "<leader>f", ":Format<CR>", { silent = true, desc = "[F]ormat" })

-- lsp
function LSP_Keymapping_Callback(event)
    -- see kind (type, function, etc) under cursor with K
    vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "[K]ind", buffer = event.buf })

    -- go to definition, declaration, implementation, references, signature, type definition
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "[G]o to [d]efinition", buffer = event.buf })
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "[G]o to [D]eclaration", buffer = event.buf })
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "[G]o to [I]mplementation", buffer = event.buf })
    vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "[G]o to [R]eferences", buffer = event.buf })
    vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, { desc = "[G]o to [S]ignature", buffer = event.buf })
    vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, { desc = "[G]o to [T]ype Definition", buffer = event.buf })

    -- show code actions with <leader>ca
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "[C]ode [A]ction", buffer = event.buf })

    -- rename with <leader>rn
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "[R]ename", buffer = event.buf })
end

-- ========================================================================= --

-- ================================== LSP ================================== --
vim.api.nvim_create_autocmd("LspAttach", {
    desc = "LSP Actions",
    callback = LSP_Keymapping_Callback,
})
-- ========================================================================= --
