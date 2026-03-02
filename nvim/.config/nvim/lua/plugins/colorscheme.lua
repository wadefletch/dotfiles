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

  { "Shatur/neovim-ayu" },

  -- Configure LazyVim to load tokyonight
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "tokyonight",
      colorscheme = "ayu",
    },
  },
}
