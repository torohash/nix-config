{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      nvim-web-devicons
      lualine-nvim
      bufferline-nvim
      bufdelete-nvim
      nvim-scrollbar
      neo-tree-nvim
      neogit
      diffview-nvim
      nvim-cmp
      nvim-lspconfig
      plenary-nvim
      nui-nvim
      nvim-treesitter.withAllGrammars
    ];
    extraLuaConfig = ''
      vim.opt.termguicolors = true
      vim.opt.autoread = true
      vim.opt.grepprg = "rg --vimgrep --smart-case"
      vim.opt.grepformat = "%f:%l:%c:%m"
      pcall(require, "lsp")
      local ok_lualine, lualine = pcall(require, "lualine")
      if ok_lualine then
        lualine.setup()
      end
      local ok_bufferline, bufferline = pcall(require, "bufferline")
      if ok_bufferline then
        bufferline.setup()
      end
      local ok_scrollbar, scrollbar = pcall(require, "scrollbar")
      if ok_scrollbar then
        scrollbar.setup()
      end
      vim.keymap.set("n", "H", "<Cmd>BufferLineCyclePrev<CR>", {})
      vim.keymap.set("n", "L", "<Cmd>BufferLineCycleNext<CR>", {})
      local function map_diffview_q(bufnr)
        if vim.b[bufnr].diffview_q_mapped then
          return
        end
        vim.b[bufnr].diffview_q_mapped = true
        local cmd = vim.fn.exists(":DiffviewClose") == 2 and "<Cmd>DiffviewClose<CR>" or "<Cmd>q<CR>"
        vim.keymap.set("n", "q", cmd, { buffer = bufnr, silent = true })
      end
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "Diffview*",
        callback = function(event)
          map_diffview_q(event.buf)
        end,
      })
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "diffview://*",
        callback = function(event)
          map_diffview_q(event.buf)
        end,
      })
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          local ok_neotree, neotree = pcall(require, "neo-tree.command")
          if ok_neotree then
            neotree.execute({ action = "show", source = "filesystem" })
          end
        end,
      })
      vim.cmd([[cnoreabbrev <expr> bd (getcmdtype() == ':' ? (getcmdline() ==# 'bd' ? 'Bdelete' : (getcmdline() =~# '^bd[! ]' ? substitute(getcmdline(), '^bd', 'Bdelete', "") : 'bd')) : 'bd')]])
      vim.cmd([[cnoreabbrev <expr> bdelete (getcmdtype() == ':' ? (getcmdline() ==# 'bdelete' ? 'Bdelete' : (getcmdline() =~# '^bdelete[! ]' ? substitute(getcmdline(), '^bdelete', 'Bdelete', "") : 'bdelete')) : 'bdelete')]])
      vim.api.nvim_create_user_command("Bonly", function()
        local ok_bufdelete, bufdelete = pcall(require, "bufdelete")
        if not ok_bufdelete then
          return
        end
        local current = vim.api.nvim_get_current_buf()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if buf ~= current and vim.api.nvim_buf_is_loaded(buf) and vim.fn.buflisted(buf) == 1 then
            bufdelete.bufdelete(buf)
          end
        end
      end, {})
    '';
  };

  xdg.configFile."nvim/lua/lsp.lua".source = ./neovim/lsp.lua;
}
