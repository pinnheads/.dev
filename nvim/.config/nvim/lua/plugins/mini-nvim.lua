-- nvim mini
-- Library of 45+ independent Lua modules improving Neovim experience with minimal effort
-- Source: https://github.com/nvim-mini/mini.nvim

---@module 'lazy'
---@type LazySpec

return {
  'nvim-mini/mini.nvim',
  version = false,
  config = function()

    -- Mini Starter: Fast and Flexible Start Screen
    require('mini.starter').setup {
      header = table.concat({
        [[  /\ \▔\___  ___/\   /(●)_ __ ___  ]],
        [[ /  \/ / _ \/ _ \ \ / / | '_ ` _ \ ]],
        [[/ /\  /  __/ (_) \ V /| | | | | | |]],
        [[\_\ \/ \___|\___/ \_/ |_|_| |_| |_|]],
        [[───────────────────────────────────]],
      }, '\n'),
      footer = function() return os.date ' %A, %B %d, %Y' end,
    }

    -- Mini Statusline:
    require('mini.statusline').setup {}

    -- Mini Cmdline: Command line tweaks like autocomplete
    require('mini.cmdline').setup {}
  end,
}
