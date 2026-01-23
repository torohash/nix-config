local servers = {
  { name = "nixd", bin = "nixd" },
  { name = "marksman", bin = "marksman" },
  { name = "basedpyright", bin = "basedpyright" },
  { name = "lua_ls", bin = "lua-language-server" },
}

if type(vim.lsp) == "table" and type(vim.lsp.enable) == "function" then
  for _, server in ipairs(servers) do
    if vim.fn.executable(server.bin) == 1 then
      pcall(vim.lsp.enable, server.name)
    end
  end
  return
end

local ok_lspconfig, lspconfig = pcall(require, "lspconfig")
if not ok_lspconfig then
  return
end

for _, server in ipairs(servers) do
  if vim.fn.executable(server.bin) == 1 and lspconfig[server.name] then
    lspconfig[server.name].setup({})
  end
end
