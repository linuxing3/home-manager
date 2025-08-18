-- require("nvchad.mappings")
local map = vim.keymap.set

map("n", "<C-g>", "<ESC><ESC>", { desc = "global escape to normal" })
map("i", "<C-g>", "<ESC><ESC>", { desc = "global escape to normal" })
map("v", "<C-g>", "<ESC><ESC>", { desc = "global escape to normal" })

-- emacs like move
map("i", "<C-a>", "<ESC>^i", { desc = "move beginning of line" })
map("i", "<C-e>", "<End>", { desc = "move end of line" })
map("i", "<C-b>", "<Left>", { desc = "move left" })
map("i", "<C-f>", "<Right>", { desc = "move right" })
map("i", "<C-n>", "<Down>", { desc = "move down" })
map("i", "<C-p>", "<Up>", { desc = "move up" })

map("n", "<C-m>", "<C-w>h", { desc = "switch window left" })
map("n", "<C-l>", "<C-w>l", { desc = "switch window right" })
map("n", "<C-j>", "<C-w>j", { desc = "switch window down" })
map("n", "<C-k>", "<C-w>k", { desc = "switch window up" })
map("n", "<C-q>", "<C-w>c", { desc = "switch window up" })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })

map("n", "<leader>z", "<cmd>wa!<CR>", { desc = "general save file" })
map("n", "<A-S-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })

map("n", "<leader>N", "<cmd>set nu!<CR>", { desc = "toggle line number" })
map("n", "<leader>R", "<cmd>set rnu!<CR>", { desc = "toggle relative number" })
map("n", "<leader>ch", "<cmd>NvCheatsheet<CR>", { desc = "toggle nvcheatsheet" })

map("n", "<f1>", function()
	require("conform").format({ lsp_fallback = true })
end, { desc = "general format file" })

-- global lsp mappings
map("n", "<leader>d", vim.diagnostic.setloclist, { desc = "LSP diagnostic loclist" })

-- tabufline
map("n", "<leader>n", "<cmd>enew<CR>", { desc = "buffer new" })
map("n", "<leader>x", "<cmd>q<CR>", { desc = "buffer new" })
map("n", "<leader>v", "<cmd>vsp<CR>", { desc = "buffer vsplit" })
map("n", "<leader>h", "<cmd>sp<CR>", { desc = "buffer split" })

map("n", "<A-S-H>", "<cmd>bp<CR>", { desc = "buffer go prev" })
map("n", "<A-S-L>", "<cmd>bn<CR>", { desc = "buffer go next" })

map("n", "<tab>", function()
	require("nvchad.tabufline").next()
end, { desc = "buffer goto next" })

map("n", "<S-tab>", function()
	require("nvchad.tabufline").prev()
end, { desc = "buffer goto prev" })

map("n", "<leader>q", function()
	require("nvchad.tabufline").close_buffer()
end, { desc = "buffer close" })

map("n", "A-q", function()
	require("nvchad.tabufline").close_buffer()
end, { desc = "buffer close" })

-- Comment
map("i", "<C-c>", "<ESC>gcc", { desc = "toggle comment", remap = true })
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "<ESC>gcc", { desc = "toggle comment", remap = true })

-- nvimtree
map("n", "<f4>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })

map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "telescope find files" })
map(
	"n",
	"<leader>fa",
	"<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
	{ desc = "telescope find all files" }
)
-- telescope
map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "telescope live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "telescope help page" })
map("n", "<leader>fm", "<cmd>Telescope marks<CR>", { desc = "telescope find marks" })
map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", { desc = "telescope find oldfiles" })
map("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "telescope find in current buffer" })
map("n", "<leader>gm", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
map("n", "<leader>gt", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })
map("n", "<leader>pt", "<cmd>Telescope terms<CR>", { desc = "telescope pick hidden term" })

map("n", "+", function()
	require("nvchad.themes").open()
end, { desc = "telescope nvchad themes" })

-- terminal
map("t", "<C-x>", "<C-\\><C-N>", { desc = "terminal escape terminal mode" })

-- toggleable terminals
map({ "n", "t" }, "<A-S-V>", function()
	require("nvchad.term").toggle({ pos = "vsp", id = "vtoggleTerm" })
end, { desc = "terminal toggleable vertical term" })

map({ "n", "t" }, "<A-S-B>", function()
	require("nvchad.term").toggle({ pos = "sp", id = "htoggleTerm" })
end, { desc = "terminal toggleable horizontal term" })

map({ "n", "t" }, "<A-S-N>", function()
	require("nvchad.term").toggle({ pos = "float", id = "floatTerm" })
end, { desc = "terminal toggle floating term" })

-- whichkey
map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "whichkey all keymaps" })

map("n", "<leader>wk", function()
	vim.cmd("WhichKey " .. vim.fn.input("WhichKey: "))
end, { desc = "whichkey query lookup" })

map("i", "jj", "<ESC>")
