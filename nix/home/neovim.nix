{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      nvim-web-devicons
      lualine-nvim
      bufferline-nvim
      neo-tree-nvim
      neogit
      diffview-nvim
      nvim-cmp
      plenary-nvim
      nui-nvim
      nvim-treesitter.withAllGrammars
    ];
    extraLuaConfig = ''
      vim.opt.termguicolors = true
      vim.opt.autoread = true
      local ok_lualine, lualine = pcall(require, "lualine")
      if ok_lualine then
        lualine.setup()
      end
      local ok_bufferline, bufferline = pcall(require, "bufferline")
      if ok_bufferline then
        bufferline.setup()
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
    '';
  };
}
