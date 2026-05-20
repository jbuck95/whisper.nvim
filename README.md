# whisper.nvim

Local whisper.cpp voice transcription.

## Verify

`:checkhealth whisper_nvim`

## Docs

`:help whisper_nvim`

## Dependencies

- `arecord` (alsa-utils) — audio capture
- `ffmpeg` / `ffprobe` — audio processing
- `whisper-cli` binary + GGML model file (user-configured)
- `yt-dlp` — optional, for URL transcription

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
```
