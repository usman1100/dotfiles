vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true

opt.termguicolors = true
opt.background = "dark"

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.cursorlineopt = "number"

opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true
opt.wrap = false

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

opt.scrolloff = 8
opt.sidescrolloff = 8
opt.signcolumn = "yes"
opt.updatetime = 50
opt.timeoutlen = 300

opt.splitbelow = true
opt.splitright = true

opt.completeopt = "menu,menuone,noselect"

opt.mouse = "a"
