# Plan: whisper.nvim auf Neovim Lua Best Practices bringen

## Phase 0 — Stale Files löschen

- [ ] `lua/whisper_nvim/init_cursorv1.lua` löschen
- [ ] `lua/whisper_nvim/init_buffer.lua` löschen
- [ ] `READMEwhispercpp.md` löschen
- [ ] `whisper_recording.wav` löschen

## Phase 1 — Scoped Command (`plugin/whisper.lua` rewrite)

- [ ] `:Whisper start/stop/stream/file/url` mit Subcommand-Completion
- [ ] `<Plug>(whisper-start)`, `<Plug>(whisper-stop)`, `<Plug>(whisper-stream)` bereitstellen
- [ ] Keine automatischen Keymaps mehr
- [ ] `vim.g.loaded_whisper_nvim`-Guard

## Phase 2 — Config-Separation + `vim.validate`

- [ ] `lua/whisper_nvim/config/defaults.lua` erstellen (keine persönlichen Pfade)
- [ ] `init.lua` lädt Defaults daraus
- [ ] `vim.validate` in `M.setup()` mit `pcall`
- [ ] Prüfung: whisper-cli executable, model_path existent

## Phase 3 — Async-Refactor (`io.popen` → `vim.fn.jobstart`)

- [ ] `check_audio_devices()` async mit jobstart
- [ ] `get_wav_duration()` async mit jobstart
- [ ] `transcribe_url()` Titel-Fetch async mit jobstart
- [ ] `vim.loop.sleep(2000)` in stop_recording ersetzen

## Phase 4 — Healthcheck erweitern

- [ ] `whisper_path`-Existenz prüfen
- [ ] `model_path`-Existenz prüfen

## Phase 5 — LuaCATS + `.luarc.json`

- [ ] `.luarc.json` erstellen
- [ ] `---@class whisper_nvim.Config` mit allen Feldern
- [ ] `---@class whisper_nvim` für M
- [ ] `---@param`/`---@return` auf allen Public-APIs

## Phase 6 — Vimdoc

- [ ] `doc/whisper_nvim.txt` erstellen
- [ ] Sections: Intro, Install, Setup, Commands, Mappings, Config, Health

## Phase 7 — Minimal-Config-Template

- [ ] `minimal-config.lua` für Issue-Reproduktion

## Phase 8 — Testing

- [ ] `spec/init_spec.lua` für busted
- [ ] Tests für setup(), Config-Merging, Validation
