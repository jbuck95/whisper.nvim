local M = {}

-- Default configuration
M.config = {
	whisper_path = "/home/jan/own/whisperV/whisper.cpp/build/bin/whisper-cli",
	model_path = "/home/jan/own/whisperV/whisper.cpp/models/ggml-large-turbo-v3.bin",
	output_dir = vim.fn.stdpath("data") .. "/whisper_transcriptions",
	output_file = "transcriptions.md",
	recording_file = vim.fn.stdpath("config") .. "/lua/dev/whisper_nvim/whisper_recording.wav",
	audio_device = "default",
	transcription_timeout = 120000, -- 120 seconds
	include_timestamp = false,
	language = "de",
	stream_chunk_duration = 5,
	stream_temp_dir = vim.fn.stdpath("data") .. "/whisper_stream",
	save_dir = vim.fn.expand("~/Documents/transcriptions"),
}

-- Setup function for user configuration
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	vim.fn.mkdir(M.config.output_dir, "p")
	local dir_stat = vim.loop.fs_stat(M.config.output_dir)
	if not dir_stat or dir_stat.type ~= "directory" or not vim.loop.fs_access(M.config.output_dir, "W") then
		vim.notify("Output directory is not writable: " .. M.config.output_dir, vim.log.levels.ERROR)
	end
	local plugin_dir = vim.fn.stdpath("config") .. "/lua/dev/whisper_nvim"
	vim.fn.mkdir(plugin_dir, "p")
	if not vim.loop.fs_access(plugin_dir, "W") then
		vim.notify("Plugin directory is not writable: " .. plugin_dir, vim.log.levels.ERROR)
	end
	if vim.fn.executable("ffmpeg") == 0 then
		vim.notify("ffmpeg is required for WAV file validation. Install it with 'sudo apt install ffmpeg'.", vim.log.levels.WARN)
	end
	vim.fn.mkdir(M.config.save_dir, "p")
	if vim.fn.executable("yt-dlp") == 0 then
		vim.notify("yt-dlp not found. Install it for URL transcription support.", vim.log.levels.WARN)
	end
end

-- Check available audio devices
local function check_audio_devices()
	local handle = io.popen("arecord -l 2>/dev/null")
	local result = handle:read("*a")
	handle:close()
	if result == "" or result:match("no soundcards found") then
		return false, "No audio devices found. Run 'arecord -l' to check."
	end
	return true, result
end

-- Validate WAV file duration using ffmpeg
local function get_wav_duration(file)
	if vim.fn.executable("ffmpeg") == 0 then
		return nil, "ffmpeg not installed"
	end
	local cmd = string.format("ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 %s 2>&1", file)
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()
	local duration = tonumber(result)
	if not duration then
		return nil, "Failed to read WAV duration: " .. result
	end
	return duration, nil
end

-- Fix WAV file using ffmpeg
local function fix_wav_file(input_file)
	if vim.fn.executable("ffmpeg") == 0 then
		return false, "ffmpeg not installed"
	end
	local temp_file = input_file .. ".tmp.wav"
	local cmd = {
		"ffmpeg",
		"-y",
		"-i",
		input_file,
		"-ar",
		"16000",
		"-ac",
		"1",
		"-acodec",
		"pcm_s16le",
		temp_file,
	}
	local job_id = vim.fn.jobstart(cmd, { stderr_buffered = true, stdout_buffered = true })
	local result = vim.fn.jobwait({job_id}, 5000)[1]
	if result ~= 0 then
		return false, "ffmpeg failed to fix WAV file"
	end
	vim.fn.delete(input_file)
	vim.fn.rename(temp_file, input_file)
	return true, nil
end

local function run_whisper(wav_path, output_base, callback)
	local pid = vim.fn.jobstart({
		M.config.whisper_path,
		"-m",
		M.config.model_path,
		"-f",
		wav_path,
		"--output-txt",
		"--output-file",
		output_base,
		"-l",
		M.config.language,
	}, {
		on_exit = function(_, code)
			if code == 0 then
				local txt_file = output_base .. ".txt"
				if vim.fn.filereadable(txt_file) == 0 then
					callback(nil, "Transcription file not found: " .. txt_file)
					return
				end
				local lines = vim.fn.readfile(txt_file)
				callback(lines, nil)
			else
				callback(nil, "Transcription failed with exit code: " .. code)
			end
		end,
	})
	if pid <= 0 then
		callback(nil, "Failed to start whisper-cli")
		return
	end
	vim.defer_fn(function()
		if vim.fn.jobwait({pid}, 0)[1] == -1 then
			vim.fn.jobstop(pid)
			callback(nil, "Transcription timed out after " .. M.config.transcription_timeout .. "ms")
		end
	end, M.config.transcription_timeout)
end

local function convert_to_wav(input_path, output_path, callback)
	if vim.fn.executable("ffmpeg") == 0 then
		callback(false, "ffmpeg not installed")
		return
	end
	vim.fn.jobstart({
		"ffmpeg", "-y", "-i", input_path,
		"-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le",
		output_path,
	}, {
		on_exit = function(_, code)
			if code == 0 then
				callback(true, nil)
			else
				callback(false, "ffmpeg conversion failed with exit code: " .. code)
			end
		end,
	})
end

local function save_transcription(lines, source_name, metadata)
	metadata = metadata or {}
	local dir = M.config.save_dir or M.config.output_dir
	vim.fn.mkdir(dir, "p")
	local ts = os.date("%Y%m%d_%H%M%S")
	local safe_name = source_name:gsub("[\\/:*?\"<>|]", "_"):sub(1, 80)
	local filename_base = ts .. "_" .. safe_name
	local filename = dir .. "/" .. filename_base .. ".md"

	local yaml = {
		"---",
		"id: " .. filename_base,
		"aliases: []",
		"tags: []",
	}
	if metadata.title and metadata.title ~= "" then
		table.insert(yaml, 'title: "' .. metadata.title:gsub('"', '\\"') .. '"')
	else
		table.insert(yaml, 'title: ""')
	end
	if metadata.url then
		table.insert(yaml, "url: " .. metadata.url)
	end
	table.insert(yaml, "---")
	table.insert(yaml, "")

	local full_content = vim.list_extend(yaml, lines)
	vim.fn.writefile(full_content, filename)
	vim.notify("Transcription saved: " .. filename, vim.log.levels.INFO)
	vim.schedule(function()
		vim.cmd("edit " .. vim.fn.fnameescape(filename))
	end)
end

-- Start audio recording
function M.start_recording()
	if M.recording_pid then
		return
	end

	local devices_ok, devices_msg = check_audio_devices()
	if not devices_ok then
		vim.notify(devices_msg, vim.log.levels.ERROR)
		return
	end

	if vim.fn.filereadable(M.config.recording_file) == 1 then
		vim.fn.delete(M.config.recording_file)
	end

	M.recording_pid = vim.fn.jobstart({
		"arecord",
		"-D",
		M.config.audio_device,
		"-f",
		"S16_LE",
		"-r",
		"16000",
		"-c",
		"1",
		M.config.recording_file,
	}, {
		stderr_buffered = true,
		on_stderr = function(_, data)
			if data[1] then
				vim.notify("Recording error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
			end
		end,
		on_exit = function(_, code)
			if code ~= 0 then
				vim.notify("Recording failed with exit code: " .. code, vim.log.levels.ERROR)
			end
			M.recording_pid = nil
		end,
	})

	if M.recording_pid <= 0 then
		vim.notify("Failed to start recording. Check audio device or permissions.", vim.log.levels.ERROR)
		M.recording_pid = nil
		return
	end
end

-- Stop recording and transcribe
function M.stop_recording()
	if not M.recording_pid then
		return
	end

	vim.fn.system({"kill", "-SIGINT", M.recording_pid})
	vim.loop.sleep(2000)
	M.recording_pid = nil

	local file_stat = vim.loop.fs_stat(M.config.recording_file)
	if not file_stat or file_stat.size < 44 then
		vim.notify("Recording file invalid or too small: " .. M.config.recording_file, vim.log.levels.ERROR)
		return
	end

	local duration, err = get_wav_duration(M.config.recording_file)
	if not duration then
		vim.notify("WAV validation failed: " .. err, vim.log.levels.ERROR)
		return
	elseif duration > 300 then
		vim.notify("WAV file duration too long (" .. duration .. "s). Possible corruption.", vim.log.levels.ERROR)
		return
	end

	local success, fix_err = fix_wav_file(M.config.recording_file)
	if not success then
		vim.notify("Failed to fix WAV file: " .. fix_err, vim.log.levels.ERROR)
		return
	end

	local output_path = M.config.output_dir .. "/" .. M.config.output_file
	local output_base = output_path:match("^(.*)%.md$")
	run_whisper(M.config.recording_file, output_base, function(lines, err)
		if err then
			vim.notify(err, vim.log.levels.ERROR)
			return
		end
		local lines_to_insert = vim.tbl_map(function(line)
			return line:gsub("^%s+", "")
		end, lines)
		local buf = vim.api.nvim_get_current_buf()
		local cursor = vim.api.nvim_win_get_cursor(0)
		local row = cursor[1]
		vim.api.nvim_buf_set_lines(buf, row, row, false, lines_to_insert)
	end)
end

function M.transcribe_file(audio_path)
	audio_path = vim.fn.expand(audio_path)
	if vim.fn.filereadable(audio_path) == 0 then
		vim.notify("File not found: " .. audio_path, vim.log.levels.ERROR)
		return
	end

	vim.notify("Converting audio file (" .. vim.fn.fnamemodify(audio_path, ":t") .. ")...", vim.log.levels.INFO)

	local temp_wav = vim.fn.tempname() .. ".wav"
	convert_to_wav(audio_path, temp_wav, function(success, conv_err)
		if not success then
			pcall(vim.fn.delete, temp_wav)
			vim.notify(conv_err, vim.log.levels.ERROR)
			return
		end

		vim.notify("Transcribing...", vim.log.levels.INFO)

		local output_base = temp_wav:gsub("%.wav$", "")
		run_whisper(temp_wav, output_base, function(lines, whisper_err)
			pcall(vim.fn.delete, temp_wav)
			pcall(vim.fn.delete, output_base .. ".txt")
			if whisper_err then
				vim.notify(whisper_err, vim.log.levels.ERROR)
				return
			end

			local source_name = vim.fn.fnamemodify(audio_path, ":t")
			save_transcription(lines, source_name, { title = source_name })
		end)
	end)
end

function M.transcribe_url(url)
	if vim.fn.executable("yt-dlp") == 0 then
		vim.notify("yt-dlp not found. Install it with 'pip install yt-dlp'.", vim.log.levels.ERROR)
		return
	end

	local title = "url_transcription"
	local handle = io.popen("yt-dlp --get-title " .. vim.fn.shellescape(url) .. " 2>/dev/null")
	if handle then
		local result = handle:read("*a"):gsub("%s+$", "")
		handle:close()
		if result ~= "" then
			title = result:gsub("\n", " ")
		end
	end

	local temp_dir = vim.fn.tempname()
	vim.fn.mkdir(temp_dir, "p")

	vim.notify("Downloading: " .. title .. "...", vim.log.levels.INFO)

	vim.fn.jobstart({
		"yt-dlp", "-x", "--audio-format", "wav",
		"-o", temp_dir .. "/audio.%(ext)s",
		"--no-playlist",
		url,
	}, {
		on_exit = function(_, code)
			if code ~= 0 then
				vim.notify("yt-dlp download failed with exit code: " .. code, vim.log.levels.ERROR)
				pcall(vim.fn.delete, temp_dir, "rf")
				return
			end

			local handle = io.popen("find " .. temp_dir .. " -type f 2>/dev/null | head -1")
			local downloaded_file = (handle and handle:read("*a") or ""):gsub("%s+$", "")
			if handle then handle:close() end

			if downloaded_file == "" then
				vim.notify("No audio file downloaded", vim.log.levels.ERROR)
				pcall(vim.fn.delete, temp_dir, "rf")
				return
			end

			vim.notify("Converting audio...", vim.log.levels.INFO)

			local temp_wav = vim.fn.tempname() .. ".wav"
			convert_to_wav(downloaded_file, temp_wav, function(success, conv_err)
				pcall(vim.fn.delete, temp_dir, "rf")

				if not success then
					pcall(vim.fn.delete, temp_wav)
					vim.notify(conv_err, vim.log.levels.ERROR)
					return
				end

				vim.notify("Transcribing...", vim.log.levels.INFO)

				local output_base = temp_wav:gsub("%.wav$", "")
				run_whisper(temp_wav, output_base, function(lines, whisper_err)
					pcall(vim.fn.delete, temp_wav)
					pcall(vim.fn.delete, output_base .. ".txt")
					if whisper_err then
						vim.notify(whisper_err, vim.log.levels.ERROR)
						return
					end

					save_transcription(lines, title, { url = url, title = title })
				end)
			end)
		end,
	})
end

-- Stream state
M.streaming = {}

-- Forward declarations for mutual recursion
local record_chunk
local on_chunk_done
local on_transcription_done

-- Start streaming mode (toggle on)
function M.start_streaming()
	if M.streaming.active then
		return
	end
	if M.recording_pid then
		return
	end

	local devices_ok, devices_msg = check_audio_devices()
	if not devices_ok then
		vim.notify(devices_msg, vim.log.levels.ERROR)
		return
	end

	local temp_dir = M.config.stream_temp_dir
	-- Clean up previous session
	if M.streaming.temp_dir and vim.loop.fs_stat(M.streaming.temp_dir) then
		vim.fn.delete(M.streaming.temp_dir, "rf")
	end
	vim.fn.mkdir(temp_dir, "p")

	M.streaming = {
		active = true,
		chunk_index = 0,
		current_recording = nil,
		temp_dir = temp_dir,
		pending = 0,
	}

	vim.notify("Streaming started (chunk: " .. M.config.stream_chunk_duration .. "s)")
	record_chunk()
end

-- Stop streaming mode (toggle off)
function M.stop_streaming()
	if not M.streaming.active then
		vim.notify("Not streaming!", vim.log.levels.WARN)
		return
	end

	M.streaming.active = false

	if M.streaming.current_recording then
		vim.fn.jobstop(M.streaming.current_recording)
		M.streaming.current_recording = nil
	end

	vim.notify("Streaming stopped")
end

-- Record next audio chunk
record_chunk = function()
	if not M.streaming.active then
		return
	end

	local index = M.streaming.chunk_index
	local chunk_file = M.streaming.temp_dir .. "/chunk_" .. string.format("%04d", index) .. ".wav"
	M.streaming.chunk_index = index + 1

	M.streaming.current_recording = vim.fn.jobstart({
		"arecord",
		"-D", M.config.audio_device,
		"-f", "S16_LE",
		"-r", "16000",
		"-c", "1",
		"-d", tostring(M.config.stream_chunk_duration),
		chunk_file,
	}, {
		on_exit = function(_, code)
			M.streaming.current_recording = nil
			if code == 0 then
				on_chunk_done(chunk_file)
			elseif not M.streaming.active then
				vim.fn.delete(chunk_file)
			end
		end,
	})

	if not M.streaming.current_recording or M.streaming.current_recording <= 0 then
		vim.notify("Failed to start chunk recording", vim.log.levels.ERROR)
		M.streaming.active = false
	end
end

-- Called when a chunk recording finishes
on_chunk_done = function(chunk_file)
	if M.streaming.active then
		record_chunk()
	end

	local file_stat = vim.loop.fs_stat(chunk_file)
	if not file_stat or file_stat.size < 44 then
		return
	end

	M.streaming.pending = (M.streaming.pending or 0) + 1

	vim.fn.jobstart({
		M.config.whisper_path,
		"-m", M.config.model_path,
		"-f", chunk_file,
		"--output-txt",
		"--output-file", chunk_file:gsub("%.wav$", ""),
		"-l", M.config.language,
	}, {
		on_exit = function(_, code)
			M.streaming.pending = M.streaming.pending - 1
			if code == 0 then
				local txt_file = chunk_file:gsub("%.wav$", ".txt")
				on_transcription_done(txt_file, chunk_file)
			else
				vim.fn.delete(chunk_file)
			end
		end,
	})
end

-- Called when transcription of a chunk finishes
on_transcription_done = function(txt_file, chunk_file)
	if vim.fn.filereadable(txt_file) == 0 then
		vim.fn.delete(chunk_file)
		return
	end

	local lines = vim.fn.readfile(txt_file)
	local text = table.concat(lines, " ")
		:gsub("^%s+", "")
		:gsub("%s+$", "")
		:gsub("%s+", " ")

	if #text > 0 then
		local text_with_space = text .. " "
		local buf = vim.api.nvim_get_current_buf()
		local cursor = vim.api.nvim_win_get_cursor(0)
		vim.api.nvim_buf_set_text(buf, cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2], { text_with_space })
		if vim.bo.textwidth > 0 then
			pcall(vim.cmd, "normal! gww")
		end
	end

	pcall(vim.fn.delete, txt_file)
	pcall(vim.fn.delete, chunk_file)
end

return M
