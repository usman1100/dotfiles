local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local elixir_group = augroup("elixir", { clear = true })

autocmd("FileType", {
  group = elixir_group,
  pattern = { "elixir", "eelixir", "heex", "surface" },
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
    vim.bo.expandtab = true
  end,
})

autocmd("BufWritePre", {
  group = elixir_group,
  pattern = { "*.ex", "*.exs" },
  callback = function()
    vim.lsp.buf.format({ async = false, timeout_ms = 3000 })
  end,
})
