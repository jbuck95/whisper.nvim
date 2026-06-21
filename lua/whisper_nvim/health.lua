local M = {}

function M.check()
	vim.health.start("whisper.nvim")

	-- System dependencies
	if vim.fn.executable("ffmpeg") == 1 then
		vim.health.ok("ffmpeg (audio capture + processing)")
		local result = vim.fn.system({ "ffmpeg", "-hide_banner", "-sources", "alsa" })
		local skip = { null = true, lavrate = true, samplerate = true, speexrate = true, jack = true, oss = true, speex = true, upmix = true, vdownmix = true }
		local devices = {}
		for line in result:gmatch("[^\n]+") do
			local name = line:match("^%s+(%S+)%s+%[")
			if name and not skip[name] then
				table.insert(devices, name)
			end
		end
		if #devices > 0 then
			vim.health.ok("audio capture devices: " .. table.concat(devices, ", "))
		else
			vim.health.warn("no audio capture devices detected (check your ALSA/PulseAudio config)")
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
		vim.health.ok("audio device: " .. cfg.audio_device)
	end

	vim.health.ok("output_dir: " .. cfg.output_dir)
	vim.health.ok("stream_temp_dir: " .. cfg.stream_temp_dir)
	vim.health.ok("save_dir: " .. cfg.save_dir)
end

return M
