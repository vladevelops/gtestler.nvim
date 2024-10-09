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

```
	{
		"vladevelops/gtestler.nvim",
		config = function()
		-- REQUIRED
		-- in opts: split_method = horizontal or vertical 
		require("gtestler").setup({})
		end,
	},

```


