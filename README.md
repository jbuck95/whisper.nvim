# whisper.nvim

Local whisper.cpp voice transcription.

## Install (lazy)

```lua
return {
    "jbuck95/whisper.nvim",
    config = function()
        require("whisper_nvim").setup({
            whisper_path = "/path/to/whisper-cli",
            model_path = "/path/to/ggml-large-v3-turbo.bin",
            output_dir = vim.fn.stdpath("data") .. "/whisper_transcriptions",
            output_file = "transcriptions.md",
        })
    end,
}
```
