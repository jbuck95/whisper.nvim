---@class whisper_nvim.Config
---@field whisper_path string Path to whisper-cli binary
---@field model_path string Path to GGML model file
---@field output_dir string Directory for transcription output files
---@field output_file string Filename for markdown transcriptions
---@field recording_file string Path for temporary WAV recording
---@field audio_device? string ALSA audio device name (default: "default")
---@field transcription_timeout? number Timeout in ms for transcription jobs
---@field include_timestamp? boolean Include timestamps in transcription output
---@field language? string Language code (e.g. "de", "en")
---@field stream_chunk_duration? number Duration in seconds per streaming audio chunk
---@field stream_temp_dir string Directory for streaming chunk files
---@field save_dir string Directory for saved transcriptions from file/URL
return {
	whisper_path = "",
	model_path = "",
	output_dir = vim.fn.stdpath("data") .. "/whisper_transcriptions",
	output_file = "transcriptions.md",
	recording_file = vim.fn.stdpath("data") .. "/whisper_recording.wav",
	audio_device = "default",
	transcription_timeout = 120000,
	include_timestamp = false,
	language = "de",
	stream_chunk_duration = 5,
	stream_temp_dir = vim.fn.stdpath("data") .. "/whisper_stream",
	save_dir = vim.fn.expand("~/Documents/transcriptions"),
}
