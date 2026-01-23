local ok_lspconfig, lspconfig = pcall(require, "lspconfig")
if not ok_lspconfig then
  return
end

if vim.fn.executable("nixd") == 1 and lspconfig.nixd then
  lspconfig.nixd.setup({})
end

if vim.fn.executable("marksman") == 1 and lspconfig.marksman then
  lspconfig.marksman.setup({})
end

if vim.fn.executable("basedpyright") == 1 and lspconfig.basedpyright then
  lspconfig.basedpyright.setup({})
end

if vim.fn.executable("lua-language-server") == 1 and lspconfig.lua_ls then
  lspconfig.lua_ls.setup({})
end
