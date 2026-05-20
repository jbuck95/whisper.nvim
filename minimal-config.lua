-- minimal-config.lua — minimal Neovim config to reproduce whisper.nvim issues
-- Usage: nvim -u minimal-config.lua

-- Add plugin directory to runtimepath
vim.cmd(string.format(
	"set runtimepath+=%s",
	vim.fn.expand("~/.config/nvim/dev/whisper.nvim")
))

-- Plugin setup
require("whisper_nvim").setup({
	whisper_path = "/path/to/whisper-cli",
	model_path = "/path/to/ggml-large-v3-turbo.bin",
	language = "de",
})
