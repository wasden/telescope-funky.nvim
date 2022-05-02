# telescope-funky.nvim
A simple function navigator for telescope.nvim  
![image](https://github.com/wasden/telescope-funky.nvim/blob/main/img/screenshot.png)
## Description
  symbols-outline is good, but it can't be searched and added text that is not symbols. I want something between navigator and outline  
  Similar to ctrlp-funky and LeaderF-funky
## Features
* support lua regex and treesitter
## Requirements
* neovim
* telescope
* nvim-treesitter(optional)
## Installation
```lua
-- packer
use {
  'wasden/telescope-funky.nvim',
  after = "telescope.nvim",
  
  -- config example
  config = function ()
    require('telescope').load_extension('funky')
    require('funky').setup {
      selected_prefix = "",
      lua = {
        {
          sortable = true,
          selectable = true,
          treesitter_kind = "function",
        },
      },
      diff = {
        {
          regex = "^--- a(.*)",
          sortable = true,
          selectable = true,
        }
      },
      c = {
        {
          regex = '^#if FOS_PART%("(.*)"%)',
          sortable = true,
          selectable = false,
          -- fixed_width = 20,
        },
        {
          sortable = true,
          selectable = true,
          treesitter_kind = "function",
        }
      },
    }
  end
}


```
