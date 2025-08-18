local autocmd = vim.api.nvim_create_autocmd

-- user event that loads after UIEnter + only if file buf is there
autocmd({ "BufWritePost" }, {
	group = vim.api.nvim_create_augroup("LuaConfigFilePost", { clear = true }),
	pattern = { "flake.nix", "flake.lock" },
	callback = function(args)
		vim.cmd("silent !direnv allow")
		print("Flake setting updated")
	end,
})
