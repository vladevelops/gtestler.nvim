# gtestler.nvim 
==============================================================================

Easy to use go test list system. 

You need to test a function you are constantly changing, so you need to jump
between buffers or keep a split and then run the tests.

With this plugin you can:

- Create a list of tests you constantly using 
- Run that test from any buffer you want
- Add a test to favorite and run it with out opening the list
- Delete the test from the list
- Choose the split option to run the test


The tests you add to the list are saved to a configuration file so when you come back you can just run them


Install using: 
[lazy](https://github.com/folke/lazy.nvim):

```lua
{
 "vladevelops/gtestler.nvim",
 config = function()
 	-- REQUIRED
 	require("gtestler").setup({})
 end,
},

```

## setup.opts

 - split_method = horizontal or vertical
 This option sets the split in which the test will be executed to `split` or `vsplit`. 

## Keymaps

By default gtestler do not assign any mappings.
gtestler exposes a set of APIs for all the functions  to call.
You can copy the suggested key bidings or change to yours.


```lua

local gtestler = require("gtestler").setup({split_method = "horizontal"})

vim.keymap.set("n", "<leader>tl", function()
  gtestler.open_tests_list()
end, { desc = "Open avaiable tests list" })

vim.keymap.set("n", "<leader>tr", function()
  gtestler.execute_test()
end, { desc = "run go test under the cursor" })

vim.keymap.set("n", "<leader>ta", function()
  local test_name = gtestler.add_test()
  print("Test: " .. test_name .. " is now added to gtestler list")
end, { desc = "Add to gtestler list" })

vim.keymap.set("n", "<leader>td", function()
  gtestler.delete_test()
end, { desc = "Deleted selected test" })

vim.keymap.set("n", "<leader>taf", function()
  local test_name = gtestler.add_favorite_test()
  print("Test: " .. test_name .. " is now added to favorite")
end)

vim.keymap.set("n", "<leader>tf", function()
  print("Test: favorite test running")
  gtestler.execute_favorite_test()
end, { desc = "run go favorite tets" })

```


## gtestler help

`:help gtestler`

