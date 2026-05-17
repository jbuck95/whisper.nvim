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

vim.keymap.set("n", "<leader>ws", function()
  local m = require("whisper_nvim")
  if m.streaming and m.streaming.active then
    m.stop_streaming()
  else
    m.start_streaming()
  end
end, { desc = "Toggle whisper streaming" })
