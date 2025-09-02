-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- set <space> as the leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- vertical bars at 80 and 120 chars
vim.opt.colorcolumn = "80,120"

-- sync clipboard between os and neovim
vim.opt.clipboard = "unnamedplus"
