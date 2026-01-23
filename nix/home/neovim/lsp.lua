local servers = {
  { name = "nixd", bin = "nixd" },
  { name = "marksman", bin = "marksman" },
  { name = "basedpyright", bin = "basedpyright" },
  { name = "lua_ls", bin = "lua-language-server" },
}

local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
local capabilities = vim.lsp.protocol.make_client_capabilities()
if ok_cmp then
  capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end

local function build_config(config)
  local merged = vim.tbl_deep_extend("force", {}, config or {})
  merged.capabilities = vim.tbl_deep_extend(
    "force",
    {},
    capabilities,
    merged.capabilities or {}
  )
  return merged
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local ok_telescope, telescope_builtin = pcall(require, "telescope.builtin")
    local opts = { buffer = event.buf }
    if ok_telescope then
      vim.keymap.set("n", "gd", telescope_builtin.lsp_definitions, opts)
      vim.keymap.set("n", "gi", telescope_builtin.lsp_implementations, opts)
      vim.keymap.set("n", "gr", telescope_builtin.lsp_references, opts)
    else
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
      vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    end
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  end,
})

local use_lspconfig = {}
local can_use_new_api = type(vim.lsp) == "table"
  and type(vim.lsp.enable) == "function"
  and type(vim.lsp.config) == "function"

if can_use_new_api then
  for _, server in ipairs(servers) do
    if vim.fn.executable(server.bin) == 1 then
      local ok_config = pcall(vim.lsp.config, server.name, build_config(server.config))
      local ok_enable = ok_config and pcall(vim.lsp.enable, server.name)
      use_lspconfig[server.name] = not ok_enable
    else
      use_lspconfig[server.name] = true
    end
  end
else
  for _, server in ipairs(servers) do
    use_lspconfig[server.name] = true
  end
end

local need_lspconfig = false
for _, server in ipairs(servers) do
  if use_lspconfig[server.name] and vim.fn.executable(server.bin) == 1 then
    need_lspconfig = true
    break
  end
end

if not need_lspconfig then
  return
end

local ok_lspconfig, lspconfig = pcall(require, "lspconfig")
if not ok_lspconfig then
  return
end

for _, server in ipairs(servers) do
  if use_lspconfig[server.name]
    and vim.fn.executable(server.bin) == 1
    and lspconfig[server.name]
  then
    lspconfig[server.name].setup(build_config(server.config))
  end
end
