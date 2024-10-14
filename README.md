![gtestler_showcase](https://github.com/user-attachments/assets/398f3bfb-cea8-484b-9d8c-58bde8958830)
 gtestler.nvim
==============================================================================

> [!NOTE]  
> The plugin is new and may have some bugs


**Easy-to-use Go test list system.**

If you need to test a function that you are constantly changing, you might find yourself jumping between buffers or keeping a split open to run the tests. With this plugin, you can:

- Create a list of tests you frequently use.
- Run any test from any buffer.
- Add a test to favorites and run it without opening the list.
- Delete tests from the list.
- Choose the split option to run the tests.
- Jump to next and previous test 

The tests you add to the list are saved to a configuration file, so when you come back, you can easily run them.

The plugin works only in .go files.

## Installation

Install using [lazy](https://github.com/folke/lazy.nvim):

```lua

{
  "vladevelops/gtestler.nvim",
  config = function()
    -- REQUIRED
    require("gtestler").setup({})
  end
},

```

## Setup Options

- **split_method**: `horizontal` or `vertical`  
  This option sets the split direction in which the test will be executed. Choose either `split` or `vsplit`.

## Keymaps

By default, `gtestler` does not assign any mappings. It exposes a set of APIs for all functions to call. You can copy the suggested key bindings or change them to your own.

```lua

local gtestler = require("gtestler")
gtestler.setup({ split_method = "horizontal" })

vim.keymap.set("n", "<leader>tl", function()
  gtestler.open_tests_list()
end, { desc = "Open available tests list" })

vim.keymap.set("n", "<leader>tr", function()
  gtestler.execute_test()
end, { desc = "Run Go test under the cursor" })

vim.keymap.set("n", "<leader>ta", function()
  local test_name = gtestler.add_test()
  print("Test: " .. test_name .. " is now added to gtestler list")
end, { desc = "Add to gtestler list" })

vim.keymap.set("n", "<leader>td", function()
  gtestler.delete_test()
end, { desc = "Delete selected test" })

vim.keymap.set("n", "<leader>taf", function()
  local test_name = gtestler.add_favorite_test()
  print("Test: " .. test_name .. " is now added to favorites")
end)

vim.keymap.set("n", "<leader>tf", function()
  print("Running favorite test")
  gtestler.execute_favorite_test()
end, { desc = "Run favorite test" })

```

## Help

For more information, run the command:

```vim
:h gtestler

```




**Version:** 0.1.0  
**Author:** Developland (Vladyslav Topyekha)  
**License:** MIT  
**Description:** Easy to use golang run tests solution.
