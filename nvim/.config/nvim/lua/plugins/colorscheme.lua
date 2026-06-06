return {
  -- add tokyonight
  -- {
  --   "folke/tokyonight.nvim",
  --   opts = {
  --     style = "storm",
  --     transparent = true,
  --     styles = {
  --       sidebars = "transparent",
  --       floats = "transparent",
  --     },
  --   },
  -- },

  -- { "Shatur/neovim-ayu" },

  { "EdenEast/nightfox.nvim" },

  -- Xcode 11's dark/light colorschemes; xcodedarkhc is the high-contrast dark variant.
  { "lunacookies/vim-colors-xcode" },

  {
    "LazyVim/LazyVim",
    -- Transparent background: vim-colors-xcode has no transparency flag, so
    -- clear Normal's bg on each ColorScheme load.
    init = function()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("transparent_background", { clear = true }),
        callback = function()
          vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
        end,
      })
    end,
    opts = {
      -- colorscheme = "tokyonight",
      -- colorscheme = "ayu",
      -- colorscheme = "nightfox",
      colorscheme = "xcodedarkhc",
    },
  },
}
