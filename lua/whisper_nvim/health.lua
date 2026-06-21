local M = {}

function M.check()
	vim.health.start("whisper.nvim")

	-- System dependencies
	if vim.fn.executable("ffmpeg") == 1 then
		local os_name = vim.loop.os_uname().sysname
		if os_name == "Darwin" then os_name = "macos"
		elseif os_name == "Windows_NT" then os_name = "windows"
		else os_name = "linux" end
		local name_map = { linux = "alsa", macos = "avfoundation", windows = "dshow" }
		vim.health.ok("ffmpeg (audio capture + processing) — driver: " .. name_map[os_name])

		local list_cmd, skip
		if os_name == "macos" then
			list_cmd = { "ffmpeg", "-hide_banner", "-list_devices", "true", "-f", "avfoundation", "-i", "''" }
			skip = {}
		elseif os_name == "windows" then
			list_cmd = { "ffmpeg", "-hide_banner", "-list_devices", "true", "-f", "dshow", "-i", "dummy" }
			skip = {}
		else
			list_cmd = { "ffmpeg", "-hide_banner", "-sources", "alsa" }
			skip = { null = true, lavrate = true, samplerate = true, speexrate = true, jack = true, oss = true, speex = true, upmix = true, vdownmix = true }
		end
		local result = vim.fn.system(list_cmd)
		local devices = {}
		for line in result:gmatch("[^\n]+") do
			local name = line:match("^%s+(%S+)%s+%[")
			if name and not (skip and skip[name]) then
				table.insert(devices, name)
			end
		end
		if #devices > 0 then
			vim.health.ok("audio capture devices: " .. table.concat(devices, ", "))
		else
			vim.health.warn("no audio capture devices detected (check your audio config)")
		end
	else
		vim.health.error("ffmpeg not found (required; install with 'sudo apt install ffmpeg')")
	end

	if vim.fn.executable("ffprobe") == 1 then
		vim.health.ok("ffprobe (WAV duration check)")
	else
		vim.health.warn("ffprobe not found (part of ffmpeg)")
	end

	if vim.fn.executable("yt-dlp") == 1 then
		vim.health.ok("yt-dlp (URL audio download)")
	else
		vim.health.warn("yt-dlp not found (required for WhisperURL; install with 'pip install yt-dlp')")
	end

	-- User-configured paths
	local ok, m = pcall(require, "whisper_nvim")
	if not ok then
		vim.health.info("whisper.nvim not loaded (run setup() first)")
		return
	end
	local cfg = m.config

	if cfg.whisper_path and cfg.whisper_path ~= "" then
		if vim.fn.executable(cfg.whisper_path) == 1 then
			vim.health.ok("whisper binary: " .. cfg.whisper_path)
		else
			vim.health.error("whisper binary not executable: " .. cfg.whisper_path)
		end
	else
		vim.health.warn("whisper binary not found (auto-detect tried whisper-cli, main)")
	end

	if cfg.model_path and cfg.model_path ~= "" then
		if vim.fn.filereadable(cfg.model_path) == 1 then
			local size = vim.fn.getfsize(cfg.model_path)
			vim.health.ok(string.format("model file: %s (%.1f MiB)", cfg.model_path, size / 1024 / 1024))
		else
			vim.health.error("model file not found: " .. cfg.model_path)
		end
	else
		vim.health.warn("model_path is not configured")
	end

	if cfg.language then
		vim.health.ok("language: " .. cfg.language)
	end

	if cfg.audio_device then
		local drv = m._driver
		local drv_name = (drv and drv.name) or "?"
		vim.health.ok("audio device: " .. cfg.audio_device .. " (driver: " .. drv_name .. ")")
	end

	vim.health.ok("output_dir: " .. cfg.output_dir)
	vim.health.ok("stream_temp_dir: " .. cfg.stream_temp_dir)
	vim.health.ok("save_dir: " .. cfg.save_dir)
end

return M
