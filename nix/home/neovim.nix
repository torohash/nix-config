{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      catppuccin-nvim
      nvim-web-devicons
      vim-tmux-navigator
      lualine-nvim
      nvim-scrollbar
      indent-blankline-nvim
      telescope-nvim
      diffview-nvim
      nvim-cmp
      cmp-nvim-lsp
      nvim-lspconfig
      plenary-nvim
      nvim-treesitter.withAllGrammars
    ];
    extraLuaConfig = ''
      vim.g.mapleader = " "
      vim.opt.termguicolors = true
      vim.opt.autoread = true
      vim.opt.clipboard = "unnamedplus"
      vim.opt.grepprg = "rg --vimgrep --smart-case"
      vim.opt.grepformat = "%f:%l:%c:%m"
      vim.opt.number = true
      vim.opt.relativenumber = true
      local ok_catppuccin, catppuccin = pcall(require, "catppuccin")
      if ok_catppuccin then
        catppuccin.setup({
          flavour = "mocha",
          integrations = {
            diffview = false,
          },
        })
        vim.cmd.colorscheme("catppuccin")
        local colors = require("catppuccin.utils.colors")
        local palette = require("catppuccin.palettes").get_palette("mocha")
        local bg_base = colors.blend(palette.base, palette.mantle, 0.80)
        local add_bg = colors.blend(palette.green, bg_base, 0.50)
        local del_bg = colors.blend(palette.red, bg_base, 0.40)
        vim.api.nvim_set_hl(0, "DiffviewDiffAdd", { fg = palette.text, bg = add_bg })
        vim.api.nvim_set_hl(0, "DiffviewDiffDelete", { fg = palette.text, bg = del_bg })
        vim.api.nvim_set_hl(0, "DiffviewDiffChange", { link = "DiffChange" })
        vim.api.nvim_set_hl(0, "DiffviewDiffText", { link = "DiffText" })
      end
      pcall(require, "lsp")
      local ok_cmp, cmp = pcall(require, "cmp")
      if ok_cmp then
        local has_snippet = vim.snippet and type(vim.snippet.expand) == "function"
        local setup = {
          sources = {
            { name = "nvim_lsp" },
          },
        }
        if has_snippet then
          setup.snippet = {
            expand = function(args)
              vim.snippet.expand(args.body)
            end,
          }
        end
        cmp.setup(setup)
      end
      local ok_devicons, devicons = pcall(require, "nvim-web-devicons")
      if ok_devicons then
        devicons.setup({ default = true })
      end
      local ok_lualine, lualine = pcall(require, "lualine")
      if ok_lualine then
        lualine.setup()
      end
      local ok_scrollbar, scrollbar = pcall(require, "scrollbar")
      if ok_scrollbar then
        scrollbar.setup()
      end
      vim.g.tmux_navigator_no_mappings = 1
      local ok_telescope, telescope_builtin = pcall(require, "telescope.builtin")
      if ok_telescope then
        vim.keymap.set("n", "<leader>ff", telescope_builtin.find_files, { desc = "Find files" })
        vim.keymap.set("n", "<leader>fg", telescope_builtin.live_grep, { desc = "Live grep" })
        vim.keymap.set("n", "<leader>fb", telescope_builtin.buffers, { desc = "Buffers" })
        vim.keymap.set("n", "<leader>fo", telescope_builtin.oldfiles, { desc = "Old files" })
        vim.keymap.set("n", "<leader>fh", telescope_builtin.help_tags, { desc = "Help tags" })
      end
      vim.keymap.set("n", "<C-h>", "<Cmd>TmuxNavigateLeft<CR>", { silent = true })
      vim.keymap.set("n", "<C-j>", "<Cmd>TmuxNavigateDown<CR>", { silent = true })
      vim.keymap.set("n", "<C-k>", "<Cmd>TmuxNavigateUp<CR>", { silent = true })
      vim.keymap.set("n", "<C-l>", "<Cmd>TmuxNavigateRight<CR>", { silent = true })
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
    '';
  };

  xdg.configFile."nvim/lua/lsp.lua".source = ./neovim/lsp.lua;
}
