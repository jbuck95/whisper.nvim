# whisper.nvim

**DEMO**

![Demo](<insert-video-link>)

## Description

Local whisper.cpp voice transcription.

## Requirements

- `arecord` (alsa-utils) -- audio capture
- `ffmpeg` / `ffprobe` -- audio processing
- `whisper-cli` binary + GGML model file (user-configured)
- `yt-dlp` -- optional, for URL transcription

Verify: `:checkhealth whisper_nvim`  |  Help: `:help whisper_nvim`

## Install (lazy)

```lua
return {
    "jbuck95/whisper.nvim",
    config = function()
        require("whisper_nvim").setup({
            whisper_path = "/path/to/whisper-cli",
            model_path = "/path/to/ggml-large-v3-turbo.bin",
        })
    end,
}
```

## Usage

| Command | Action |
|---------|--------|
| `:Whisper start` | Start microphone recording |
| `:Whisper stop` | Stop recording, transcribe, insert at cursor |
| `:Whisper stream` | Toggle continuous streaming mode |
| `:Whisper file [path]` | Transcribe an audio file |
| `:Whisper url <url>` | Download + transcribe from URL (yt-dlp) |

## Keymaps

`<Plug>` mappings are provided. Add to your keymap config:

```lua
vim.keymap.set("n", "<leader>ws", "<Plug>(whisper-start)")
vim.keymap.set("n", "<leader>wx", "<Plug>(whisper-stop)")
vim.keymap.set("n", "<leader>wt", "<Plug>(whisper-stream)")
vim.keymap.set("n", "<leader>wf", "<Plug>(whisper-file)")
vim.keymap.set("n", "<leader>wu", "<Plug>(whisper-url)")
```

## Lua API

```lua
local w = require("whisper_nvim")

-- Setup (required: whisper_path + model_path)
w.setup({
  whisper_path = "/path/to/whisper-cli",
  model_path   = "/path/to/ggml-large-v3-turbo.bin",
})

-- Microphone recording
w.start_recording()   -- begin recording
w.stop_recording()    -- stop and transcribe

-- Streaming mode
w.start_streaming()   -- continuous real-time transcription
w.stop_streaming()    -- stop streaming

-- File / URL transcription
w.transcribe_file("recording.wav")
w.transcribe_url("https://example.com/audio.mp3")
```

## Configuration

All fields can be passed to `setup()`:

| Option | Default | Description |
|--------|---------|-------------|
| `whisper_path` | `""` | Path to `whisper-cli` binary |
| `model_path` | `""` | Path to GGML model file |
| `output_dir` | `stdpath("data")/whisper_transcriptions` | Transcription output |
| `output_file` | `transcriptions.md` | Output filename |
| `recording_file` | `stdpath("data")/whisper_recording.wav` | Temp WAV path |
| `audio_device` | `"default"` | ALSA device name |
| `transcription_timeout` | `120000` | Transcription timeout (ms) |
| `language` | `"de"` | Language code |
| `stream_chunk_duration` | `5` | Seconds per streaming chunk |
| `stream_temp_dir` | `stdpath("data")/whisper_stream` | Streaming temp dir |
| `save_dir` | `~/Documents/transcriptions` | Saved transcriptions dir |

## Credits

Built on [whisper.cpp](https://github.com/ggerganov/whisper.cpp) by Georgi Gerganov.

## License

MIT
