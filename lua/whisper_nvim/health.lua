local M = {}

function M.check()
	vim.health.start("whisper.nvim")

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

	vim.health.info("whisper-cli and model path are user-configured — verify after setup()")
end

return M
