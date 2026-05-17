local M = {}

-- Default configuration
M.config = {
  whisper_path = "/home/jan/own/whisper/whisper.cpp/build/bin/whisper-cli",
  model_path = "/home/jan/own/whisper/whisper.cpp/models/ggml-base.bin",
  output_dir = vim.fn.stdpath("data") .. "/whisper_transcriptions",
  output_file = "transcriptions.md",
  recording_file = vim.fn.stdpath("config") .. "/lua/dev/whisper_nvim/whisper_recording.wav",
  audio_device = "default",
  transcription_timeout = 120000, -- Increased to 120 seconds
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
  -- Check if ffmpeg is installed
  if vim.fn.executable("ffmpeg") == 0 then
    vim.notify("ffmpeg is required for WAV file validation. Install it with 'sudo apt install ffmpeg'.", vim.log.levels.WARN)
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

-- Start audio recording
function M.start_recording()
  if M.recording_pid then
    vim.notify("Already recording!", vim.log.levels.WARN)
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
  vim.notify("Recording started using device: " .. M.config.audio_device)
end

-- Stop recording and transcribe
function M.stop_recording()
  if not M.recording_pid then
    vim.notify("Not recording!", vim.log.levels.WARN)
    return
  end

  vim.fn.system({"kill", "-SIGINT", M.recording_pid})
  vim.loop.sleep(2000)
  M.recording_pid = nil
  vim.notify("Recording stopped, checking file...")

  local file_stat = vim.loop.fs_stat(M.config.recording_file)
  if not file_stat or file_stat.size < 44 then
    vim.notify("Recording file invalid or too small: " .. M.config.recording_file, vim.log.levels.ERROR)
    return
  end

  -- Validate WAV duration
  local duration, err = get_wav_duration(M.config.recording_file)
  if not duration then
    vim.notify("WAV validation failed: " .. err, vim.log.levels.ERROR)
  elseif duration > 300 then -- Arbitrary limit of 5 minutes
    vim.notify("WAV file duration too long (" .. duration .. "s). Possible corruption.", vim.log.levels.ERROR)
    return
  else
    vim.notify("WAV file duration: " .. duration .. " seconds", vim.log.levels.INFO)
  end

  -- Fix WAV file with ffmpeg
  vim.notify("Fixing WAV file with ffmpeg...")
  local success, fix_err = fix_wav_file(M.config.recording_file)
  if not success then
    vim.notify("Failed to fix WAV file: " .. fix_err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Starting transcription...")
  local output_path = M.config.output_dir .. "/" .. M.config.output_file
  local transcription_pid = vim.fn.jobstart({
    M.config.whisper_path,
    "-m",
    M.config.model_path,
    "-f",
    M.config.recording_file,
    "--output-txt",
    "--output-file",
    output_path:match("^(.*)%.md$"),
  }, {
    stderr_buffered = true,
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data[1] then
        vim.notify("Transcription output: " .. table.concat(data, "\n"), vim.log.levels.INFO)
      end
    end,
    on_stderr = function(_, data)
      if data[1] then
        vim.notify("Whisper error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        local txt_file = output_path:match("^(.*)%.md$") .. ".txt"
        if vim.fn.filereadable(txt_file) == 0 then
          vim.notify("Transcription file not found: " .. txt_file, vim.log.levels.ERROR)
          return
        end
        local transcription = vim.fn.readfile(txt_file)
        local markdown_lines = {
          "# Transcription " .. os.date("%Y-%m-%d %H:%M:%S"),
          "",
          table.concat(transcription, "\n"),
          "",
          "---",
          "",
        }
        local existing_content = vim.fn.filereadable(output_path) == 1 and vim.fn.readfile(output_path) or {}
        vim.fn.writefile(markdown_lines, output_path)
        vim.fn.writefile(existing_content, output_path, "a")
        vim.cmd("vsplit " .. output_path)
        vim.notify("Transcription completed")
      else
        vim.notify("Transcription failed with exit code: " .. code, vim.log.levels.ERROR)
      end
    end,
  })

  -- Timeout for transcription
  vim.defer_fn(function()
    if vim.fn.jobwait({transcription_pid}, 0)[1] == -1 then
      vim.fn.jobstop(transcription_pid)
      vim.notify("Transcription timed out after " .. M.config.transcription_timeout .. "ms", vim.log.levels.ERROR)
    end
  end, M.config.transcription_timeout)
end

return M
