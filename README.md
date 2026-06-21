# whisper.nvim

## Description

Fully local whisper.cpp voice + audio transcription.

**transbribe:** 

- input from your mic (chunk / streaming)
- local audio files
- from url 

## Requirements

- `ffmpeg` / `ffprobe` -- audio capture + processing
- `whisper.cpp` binary (e.g. `build/bin/whisper-cli` after `make`) + GGML model file
- `yt-dlp` -- optional, for URL transcription

Verify: `:checkhealth whisper_nvim`  |  Help: `:help whisper_nvim`

## Install (lazy)

```lua
return {
    "jbuck95/whisper.nvim",
    config = function()
        require("whisper_nvim").setup({
            whisper_path = "YOUR_PATH_TO/whisper.cpp/build/bin/whisper-cli",
            model_path   = "YOUR_PATH_TO/ggml-large-v3-turbo.bin",
        })
    end,
}
```

> `whisper_path` is optional — if empty, the plugin auto-detects `whisper-cli` or
> `main` from `$PATH`.

## Whisper.cpp

Check [whisper.cpp](https://github.com/ggerganov/whisper.cpp) to install
whisper.cpp and or download models. Highly recommend you build for gpu.


## Usage

| Command | Action |
|---------|--------|
| `:Whisper start` | Start microphone recording |
| `:Whisper stop` | Stop recording, transcribe, insert at cursor |
| `:Whisper stream` | Toggle continuous streaming mode |
| `:Whisper file [path]` | Transcribe an audio file |
| `:Whisper url <url>` | Download + transcribe from URL (yt-dlp) |

## Keymaps

`<Plug>` mappings:

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

-- Setup (whisper_path optional, model_path required)
w.setup({
  whisper_path = "YOUR_PATH_TO/whisper.cpp/build/bin/whisper-cli",
  model_path   = "YOUR_PATH_TO/ggml-large-v3-turbo.bin",
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
| `whisper_path` | `""` | Path to whisper.cpp binary (empty = auto-detect `whisper-cli`/`main` from `$PATH`). After `make`: `build/bin/whisper-cli` |
| `model_path` | `""` | Path to GGML model file |
| `audio_driver` | `""` | Audio capture driver (empty = auto: `alsa` on Linux, `avfoundation` on macOS, `dshow` on Windows) |
| `audio_device` | `"default"` | Audio device name (auto-wrapped for the active driver) |
| `output_dir` | `stdpath("data")/whisper_transcriptions` | Transcription output |
| `output_file` | `transcriptions.md` | Output filename |
| `recording_file` | `stdpath("data")/whisper_recording.wav` | Temp WAV path |
| `transcription_timeout` | `120000` | Transcription timeout (ms) |
| `language` | `"de"` | Language code |
| `stream_chunk_duration` | `5` | Seconds per streaming chunk |
| `stream_temp_dir` | `stdpath("data")/whisper_stream` | Streaming temp dir |
| `save_dir` | `~/Documents/transcriptions` | Saved transcriptions dir |

## Credits

Built on [whisper.cpp](https://github.com/ggerganov/whisper.cpp) by Georgi Gerganov.

## Disclaimer

Built for my personal master's thesis workflow. AI was used extensively in
development.

## License

MIT
