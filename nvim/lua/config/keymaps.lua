local map = vim.keymap.set
local opts = { noremap = true, silent = true }

map("n", "<Esc>", "<cmd>nohlsearch<CR>", opts)

map("n", "<leader>w", "<cmd>write<CR>", opts)
map("n", "<leader>q", "<cmd>quit<CR>", opts)
map("n", "<leader>Q", "<cmd>qa!<CR>", opts)

map("n", "<leader>e", vim.diagnostic.open_float, opts)
map("n", "[d", vim.diagnostic.goto_prev, opts)
map("n", "]d", vim.diagnostic.goto_next, opts)

map("n", "<leader>h", "<cmd>nohlsearch<CR>", opts)

map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

map("n", "<leader>sv", "<C-w>v", opts)
map("n", "<leader>sh", "<C-w>s", opts)
map("n", "<leader>sx", "<cmd>close<CR>", opts)

map("n", "<leader>tn", "<cmd>tabnext<CR>", opts)
map("n", "<leader>tp", "<cmd>tabprev<CR>", opts)
map("n", "<leader>tf", "<cmd>tabnew %<CR>", opts)

map("n", "<leader>bp", "<cmd>BufferLineCyclePrev<CR>", opts)
map("n", "<leader>bn", "<cmd>BufferLineCycleNext<CR>", opts)
map("n", "<leader>bd", "<cmd>bdelete<CR>", opts)

map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", opts)
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", opts)
map("n", "<leader>cs", "<cmd>Trouble symbols toggle<CR>", opts)
map("n", "<leader>cl", "<cmd>LspLog<CR>", opts)
