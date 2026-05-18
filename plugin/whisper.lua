vim.api.nvim_create_user_command("WhisperStart", function()
  require("whisper_nvim").start_recording()
end, {})

vim.api.nvim_create_user_command("WhisperStop", function()
  require("whisper_nvim").stop_recording()
end, {})

vim.api.nvim_create_user_command("WhisperStream", function()
  local m = require("whisper_nvim")
  if m.streaming and m.streaming.active then
    m.stop_streaming()
  else
    m.start_streaming()
  end
end, {})

vim.api.nvim_create_user_command("WhisperFile", function(opts)
  local path = opts.args
  if path == "" then
    path = vim.fn.input("Path to audio file: ", "", "file")
  end
  if path and path ~= "" then
    require("whisper_nvim").transcribe_file(path)
  end
end, { nargs = "?", complete = "file" })

vim.api.nvim_create_user_command("WhisperURL", function(opts)
  local url = opts.args
  if url == "" then
    url = vim.fn.input("URL to download and transcribe: ")
  end
  if url and url ~= "" then
    require("whisper_nvim").transcribe_url(url)
  end
end, { nargs = "?" })

vim.keymap.set("n", "<leader>ws", function()
  local m = require("whisper_nvim")
  if m.streaming and m.streaming.active then
    m.stop_streaming()
  else
    m.start_streaming()
  end
end, { desc = "Toggle whisper streaming" })

vim.keymap.set("n", "<leader>wf", function()
  local path = vim.fn.input("Path to audio file: ", "", "file")
  if path and path ~= "" then
    require("whisper_nvim").transcribe_file(path)
  end
end, { desc = "Transcribe audio file" })

vim.keymap.set("n", "<leader>wu", function()
  local url = vim.fn.input("URL to download and transcribe: ")
  if url and url ~= "" then
    require("whisper_nvim").transcribe_url(url)
  end
end, { desc = "Transcribe from URL" })
