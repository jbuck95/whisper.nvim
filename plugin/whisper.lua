if vim.g.loaded_whisper_nvim then
	return
end
vim.g.loaded_whisper_nvim = true

local function get_whisper()
	return require("whisper_nvim")
end

-- <Plug> mappings -- users map these in their own config
vim.keymap.set("n", "<Plug>(whisper-toggle-rec)", function()
	get_whisper().toggle_recording()
end, { silent = true, desc = "Whisper: Toggle recording" })

vim.keymap.set("n", "<Plug>(whisper-stream)", function()
	local m = get_whisper()
	if m.streaming and m.streaming.active then
		m.stop_streaming()
	else
		m.start_streaming()
	end
end, { silent = true, desc = "Whisper: Toggle streaming" })

vim.keymap.set("n", "<Plug>(whisper-file)", function()
	local path = vim.fn.input("Path to audio file: ", "", "file")
	if path and path ~= "" then
		get_whisper().transcribe_file(path)
	end
end, { silent = true, desc = "Whisper: Transcribe audio file" })

vim.keymap.set("n", "<Plug>(whisper-url)", function()
	local url = vim.fn.input("URL to download and transcribe: ")
	if url and url ~= "" then
		get_whisper().transcribe_url(url)
	end
end, { silent = true, desc = "Whisper: Transcribe URL" })

-- :Whisper {rec|stream|file|url}
vim.api.nvim_create_user_command("Whisper", function(opts)
	local m = get_whisper()
	local args = vim.split(opts.args, "%s+", { plain = true, trimempty = true })
	local sub = args[1]
	if not sub or sub == "" then
		vim.notify("Usage: :Whisper {rec|stream|file|url}", vim.log.levels.WARN)
		return
	end
	if sub == "rec" then
		m.toggle_recording()
	elseif sub == "stream" then
		if m.streaming and m.streaming.active then
			m.stop_streaming()
		else
			m.start_streaming()
		end
	elseif sub == "file" then
		local path = args[2]
		if not path or path == "" then
			path = vim.fn.input("Path to audio file: ", "", "file")
		end
		if path and path ~= "" then
			m.transcribe_file(path)
		end
	elseif sub == "url" then
		local url = args[2]
		if not url or url == "" then
			url = vim.fn.input("URL to download and transcribe: ")
		end
		if url and url ~= "" then
			m.transcribe_url(url)
		end
	else
		vim.notify("Unknown subcommand: " .. sub, vim.log.levels.ERROR)
	end
end, {
	nargs = "*",
	complete = function(arg_lead, cmdline, _)
		local cmd_args = vim.split(cmdline, "%s+", { plain = true, trimempty = true })
		if #cmd_args <= 2 then
			return vim.tbl_filter(function(v)
				return v:match("^" .. vim.pesc(arg_lead))
			end, { "rec", "stream", "file", "url" })
		end
		return {}
	end,
})
