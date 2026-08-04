vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.inccommand = "split"
vim.opt.foldtext = "v:lua.vim.treesitter.foldtext()"
vim.opt.showmode = false

vim.opt.grepprg = "rg --glob '!.git' --no-heading --vimgrep --follow"
vim.opt.grepformat:prepend("%f:%l:%c:%m")

vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚",
      [vim.diagnostic.severity.WARN] = "󰀪",
      [vim.diagnostic.severity.INFO] = "󰋽",
      [vim.diagnostic.severity.HINT] = "󰌶",
    },
  },
})

vim.keymap.set({ "i", "s" }, "<Tab>", function()
  if vim.snippet.active({ direction = 1 }) then
    return "<cmd>lua vim.snippet.jump(1)<cr>"
  end
  return "<Tab>"
end, { expr = true, desc = "Jump to next snippet stop" })

vim.keymap.set("n", "<leader>fs", "1z=", { silent = true, desc = "Fix spelling under cursor" })

vim.g.zenbones = {
  solid_line_nr = true,
  solid_vert_split = true,
}
vim.cmd.colorscheme("zenbones")

require("auto-dark-mode").setup({
  update_interval = 1000,
  set_dark_mode = function()
    vim.opt.background = "dark"
  end,
  set_light_mode = function()
    vim.opt.background = "light"
  end,
})

require("nvim-highlight-colors").setup({
  render = "virtual",
  enable_tailwind = true,
})

require("oil").setup({
  view_options = { show_hidden = true },
})
vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })

require("gitsigns").setup()
require("todo-comments").setup()
require("render-markdown").setup()

vim.keymap.set("n", "<leader>/", require("telescope.builtin").live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>f", function()
  require("telescope.builtin").find_files({
    find_command = { "rg", "--files", "--hidden", "-g", "!.git" },
  })
end, { desc = "Find files" })
vim.keymap.set("n", "<leader>b", require("telescope.builtin").buffers, { desc = "Buffers" })

require("treesitter-modules").setup({
  highlight = { enable = true },
  indent = { enable = true },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<M-o>",
      scope_incremental = "<M-O>",
      node_incremental = "<M-o>",
      node_decremental = "<M-i>",
    },
  },
})

require("mini.ai").setup()
require("mini.align").setup()
require("mini.bracketed").setup()
require("mini.comment").setup()
require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons()
require("mini.jump").setup()
require("mini.pairs").setup()
require("mini.statusline").setup()
require("mini.surround").setup({
  custom_surroundings = {
    l = { output = { left = "[", right = "]()" } },
  },
})

local miniclue = require("mini.clue")
miniclue.setup({
  triggers = {
    { mode = "n", keys = "<Leader>" },
    { mode = "x", keys = "<Leader>" },
    { mode = "i", keys = "<C-x>" },
    { mode = "n", keys = "g" },
    { mode = "x", keys = "g" },
    { mode = "n", keys = "'" },
    { mode = "n", keys = "`" },
    { mode = "x", keys = "'" },
    { mode = "x", keys = "`" },
    { mode = "n", keys = '"' },
    { mode = "x", keys = '"' },
    { mode = "i", keys = "<C-r>" },
    { mode = "c", keys = "<C-r>" },
    { mode = "n", keys = "<C-w>" },
    { mode = "n", keys = "z" },
    { mode = "x", keys = "z" },
    { mode = "n", keys = "[" },
    { mode = "n", keys = "]" },
  },
  clues = {
    miniclue.gen_clues.builtin_completion(),
    miniclue.gen_clues.g(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.z(),
  },
})

function _G.toggle_prose()
  require("zen-mode").toggle({
    window = { backdrop = 1, width = 80 },
    on_open = function()
      if vim.bo.filetype == "markdown" then
        vim.opt_local.scrolloff = 999
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.colorcolumn = "0"
      end
    end,
    on_close = function()
      vim.opt_local.scrolloff = 3
      vim.opt_local.number = true
      vim.opt_local.relativenumber = true
    end,
  })
end
vim.keymap.set("n", "<localleader>m", _G.toggle_prose, { desc = "Toggle writing mode" })

vim.keymap.set("n", "<leader>d", vim.diagnostic.setloclist, { desc = "Buffer diagnostics" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
  callback = function(event)
    local opts = function(description)
      return { buffer = event.buf, desc = description }
    end

    vim.bo[event.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("Declaration"))
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("Definition"))
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts("Implementation"))
    vim.keymap.set({ "n", "i" }, "<M-k>", vim.lsp.buf.signature_help, opts("Signature help"))
    vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts("Type definition"))
    vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts("Rename symbol"))
    vim.keymap.set({ "n", "x" }, "<leader>a", vim.lsp.buf.code_action, opts("Code action"))
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts("References"))
    vim.keymap.set("n", "<localleader>f", function()
      vim.lsp.buf.format({ async = true })
    end, opts("Format buffer"))
  end,
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim", "MiniIcons" } },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
    },
  },
})
vim.lsp.enable({ "lua_ls", "markdown_oxide", "nixd" })

require("herdr-nvim").setup({})
