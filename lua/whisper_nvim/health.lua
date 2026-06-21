local M = {}

function M.check()
	vim.health.start("whisper.nvim")

	-- System dependencies
	if vim.fn.executable("arecord") == 1 then
		vim.health.ok("arecord (ALSA recording)")
	else
		vim.health.error("arecord not found (required; install alsa-utils)")
	end

	local handle = io.popen("arecord -l 2>/dev/null")
	local result = handle and handle:read("*a") or ""
	if handle then handle:close() end
	if result == "" or result:match("no soundcards found") then
		vim.health.warn("no audio capture devices found")
	else
		vim.health.ok("audio capture device detected")
	end

	if vim.fn.executable("ffmpeg") == 1 then
		vim.health.ok("ffmpeg (WAV fix/resample/convert)")
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
