describe("whisper_nvim", function()
	local whisper_nvim

	before_each(function()
		-- Reload module fresh for each test
		package.loaded["whisper_nvim"] = nil
		package.loaded["whisper_nvim.config.defaults"] = nil
		whisper_nvim = require("whisper_nvim")
	end)

	it("loads without setup()", function()
		assert.is_not_nil(whisper_nvim)
		assert.is_not_nil(whisper_nvim.config)
	end)

	it("has complete default config", function()
		local cfg = whisper_nvim.config
		assert.is_string(cfg.whisper_path)
		assert.is_string(cfg.model_path)
		assert.is_string(cfg.output_dir)
		assert.is_string(cfg.recording_file)
		assert.is_string(cfg.audio_device)
		assert.is_number(cfg.transcription_timeout)
		assert.is_boolean(cfg.include_timestamp)
		assert.is_string(cfg.language)
		assert.is_number(cfg.stream_chunk_duration)
		assert.is_string(cfg.stream_temp_dir)
		assert.is_string(cfg.save_dir)
	end)

	it("setup() merges user config", function()
		whisper_nvim.setup({ language = "en", transcription_timeout = 60000 })
		assert.equals("en", whisper_nvim.config.language)
		assert.equals(60000, whisper_nvim.config.transcription_timeout)
		-- Unchanged defaults remain
		assert.is_string(whisper_nvim.config.output_dir)
	end)

	it("setup() partial merge preserves other defaults", function()
		local orig_device = whisper_nvim.config.audio_device
		whisper_nvim.setup({ language = "en" })
		assert.equals(orig_device, whisper_nvim.config.audio_device)
	end)

	it("start_recording() guard prevents double recording", function()
		whisper_nvim.recording_pid = 1234
		whisper_nvim.start_recording()
		-- Should still be 1234 (mock prevents actual job start)
		assert.equals(1234, whisper_nvim.recording_pid)
		whisper_nvim.recording_pid = nil
	end)

	it("stop_recording() returns early when not recording", function()
		whisper_nvim.recording_pid = nil
		whisper_nvim._recording_on_exit = nil
		-- Should not error, just return
		pcall(whisper_nvim.stop_recording)
		assert.is_nil(whisper_nvim._recording_on_exit)
	end)

	it("start_streaming() guard prevents double stream", function()
		whisper_nvim.streaming = { active = true }
		whisper_nvim.start_streaming()
		assert.is_true(whisper_nvim.streaming.active)
	end)

	it("stop_streaming() returns early when not streaming", function()
		whisper_nvim.streaming = { active = false }
		whisper_nvim.stop_streaming()
		assert.is_false(whisper_nvim.streaming.active)
	end)
end)
