local gtestler_utils = require("gtestler.utils")
local gtestler_ui = require("gtestler.ui")
local gtestler_log = require("gtestler.logs")

local M = {}

local gtestler_autogroup =
    vim.api.nvim_create_augroup("DEVELOPLAND_GTESTLER", { clear = true })

local wd = gtestler_utils.get_working_directory()

--- pk_name
--- |-> test_label
---    |->command_name: command_string
---    |->file_name: string
---    |->file_path: string
local tests_commands = {}

local current_favorite_test = ""
local gtestler_win_id = nil

local pattern = "gtestler"
local test_buffer_pattern = pattern .. "_test_buffer"

vim.api.nvim_create_autocmd({ "BufLeave" }, {
    callback = function()
        if gtestler_win_id ~= nil then
            vim.api.nvim_win_close(gtestler_win_id, true)
            gtestler_win_id = nil
        end
    end,
    group = gtestler_autogroup,
})

vim.api.nvim_create_autocmd({ "BufEnter" }, {
    pattern = "*_test.go",

    callback = function()
        gtestler_utils.find_all_tests_lines_in_buffer()
    end,
    group = gtestler_autogroup,
})

vim.api.nvim_create_autocmd("VimEnter", {

    callback = function()
        local retsore_tabel = gtestler_utils.load_commands_table()

        if retsore_tabel ~= nil then
            tests_commands = retsore_tabel
            if tests_commands[wd].current_favorite_test ~= nil then
                current_favorite_test = tests_commands[wd].current_favorite_test
            end
        end
    end,

    group = gtestler_autogroup,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = pattern,
    group = gtestler_autogroup,
    callback = function()
        vim.keymap.set("n", "g", function()
            M.go_to_test_file()
        end, {
            buffer = true,
            desc = "jump to test file and func line",
            noremap = true,
        })

        vim.keymap.set("n", "f", function()
            M.toggle_favorite()
        end, {
            buffer = true,
            desc = "test is now favorite",
            noremap = true,
        })

        vim.keymap.set("n", "<leader>tr", function()
            M.run_selected_test()
        end, {
            buffer = true,
            desc = "run current test in the list",
            noremap = true,
        })

        vim.keymap.set("n", "<CR>", function()
            M.run_selected_test()
        end, { buffer = true, desc = "run selected test" })

        vim.keymap.set("v", "d", function()
            M.delete_selected_tests()
        end, { buffer = true, desc = "delete selected tests" })

        vim.keymap.set("n", "d", function()
            M.delete_test()
        end, { buffer = true, desc = "delete test" })

        vim.keymap.set(
            "n",
            "v",
            "V",
            { buffer = true, desc = "run selected test", noremap = true }
        )

        vim.keymap.set(
            "n",
            "<Esc>",
            ":bd!<CR>",
            { buffer = true, noremap = true, silent = true }
        )
    end,
})

vim.api.nvim_create_user_command("Gtestler", function(opts)
    local subcommand = opts.args

    if subcommand == "horizontal" then
        M.opts = {
            split_method = gtestler_utils.validate_split_method(subcommand),
        }
        print("Session split set to `horizontal`")
    elseif subcommand == "vertical" then
        M.opts = {
            split_method = gtestler_utils.validate_split_method(subcommand),
        }
        print("Session split set to `vertical`")
    elseif subcommand == "delete_all" then
        M.delete_all_tests()
        print("All test for this project deleted")
    else
        print("Command not recognized: " .. subcommand)
    end
end, {
    nargs = 1,
    complete = function()
        return { "horizontal", "vertical", "delete_all" }
    end,
    desc = "User callable commands",
})

function M.go_to_test_file()
    local command_alias = gtestler_utils.get_command_alias()
    command_alias = gtestler_utils.remove_star_if_exists(command_alias)
    local file_path = tests_commands[wd][command_alias].file_path

    vim.api.nvim_command("wincmd w")
    vim.cmd("e " .. file_path)

    vim.defer_fn(function()
        local line = gtestler_utils.find_specific_function(command_alias)
        vim.api.nvim_win_set_cursor(0, { line, 0 })
    end, 1)
end

function M.jump_to_next_test()
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))

    local test_lines = gtestler_utils.find_all_tests_lines_in_buffer()
    -- local test_lines = { 5, 7 }

    if test_lines ~= nil then
        -- search test forward
        for _, line_value in pairs(test_lines) do
            if line_value > row then
                -- gtestler_log.log_message("jump to line: ", line_value)
                vim.api.nvim_win_set_cursor(0, { line_value, 0 })
                return
            end
        end

        -- search tests backwards

        for i = #test_lines, 1, -1 do
            gtestler_log.log_message("lines backwards: ", test_lines[i])

            if row > test_lines[i] then
                -- gtestler_log.log_message("jump to line: ", line_value)
                vim.api.nvim_win_set_cursor(0, { test_lines[i], 0 })
                return
            end
        end
    else
        print("No test found")
    end
end

function M.jump_to_previous_test()
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))

    local test_lines = gtestler_utils.find_all_tests_lines_in_buffer()
    -- local test_lines = { 5, 7 }

    if test_lines ~= nil then
        -- search tests backwards
        for i = #test_lines, 1, -1 do
            gtestler_log.log_message("lines backwards: ", test_lines[i])

            if row > test_lines[i] then
                -- gtestler_log.log_message("jump to line: ", line_value)
                vim.api.nvim_win_set_cursor(0, { test_lines[i], 0 })
                return
            end
        end

        -- search test forward
        for _, line_value in pairs(test_lines) do
            if line_value > row then
                -- gtestler_log.log_message("jump to line: ", line_value)
                vim.api.nvim_win_set_cursor(0, { line_value, 0 })
                return
            end
        end
    else
        print("No test found")
    end
end

--- opens the list with all the tests to run
---
function M.open_tests_list()
    local floating_buffer, win_id = gtestler_ui.create_buffer()
    gtestler_win_id = win_id
    local tests_list = {}

    local count = 1
    if tests_commands[wd] ~= nil then
        for label, _ in pairs(tests_commands[wd]) do
            if label ~= "current_favorite_test" then
                if label == current_favorite_test then
                    table.insert(tests_list, count, "* " .. label)
                else
                    table.insert(tests_list, count, label)
                end
                count = count + 1
            end
        end
    end

    vim.api.nvim_buf_set_lines(floating_buffer, 0, -1, false, tests_list)
    vim.api.nvim_buf_set_option(floating_buffer, "modifiable", false)
end

--- runs selected test under the cursor
function M.run_selected_test()
    local command_alias = gtestler_utils.get_command_alias()
    if command_alias ~= "" then
        command_alias = gtestler_utils.remove_star_if_exists(command_alias)
        local new_cmd = tests_commands[wd][command_alias].command_name
        M.execute_wrap(new_cmd)
    else
        print("No test to run")
    end
end

--- runs a previesly assigned favorite test
function M.execute_favorite_test()
    if current_favorite_test ~= "" then
        local new_cmd = tests_commands[wd][current_favorite_test].command_name
        M.execute_wrap(new_cmd)
    else
        print("No favorite test founded")
    end
end

---@param command string
function M.execute_wrap(command)
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if
            vim.api.nvim_buf_get_option(bufnr, "filetype")
            == test_buffer_pattern
        then
            vim.api.nvim_buf_call(bufnr, function()
                vim.cmd("bd!")
            end)
            vim.cmd(": " .. M.opts.split_method .. " term:// " .. command)

            local current_test_buffer = vim.api.nvim_get_current_buf()

            vim.api.nvim_buf_set_option(
                current_test_buffer,
                "filetype",
                test_buffer_pattern
            )
            return
        end
    end

    vim.cmd(": " .. M.opts.split_method .. " term:// " .. command)
    local current_test_buffer = vim.api.nvim_get_current_buf()

    vim.api.nvim_buf_set_option(
        current_test_buffer,
        "filetype",
        test_buffer_pattern
    )
end

---@return string
function M.add_test()
    local new_cmd, test_name = gtestler_utils.get_command_and_test_name()

    if test_name ~= nil then
        if tests_commands[wd] == nil then
            tests_commands[wd] = {}
        end

        local file_path = vim.fn.expand("%:p")
        -- Create the new entry
        tests_commands[wd][test_name] = {
            command_name = new_cmd,
            file_name = "",
            file_path = file_path,
        }

        gtestler_utils.save_json_to_file(tests_commands)
        return test_name
    end
    return ""
end

--- makes current test favorite
function M.toggle_favorite()
    local command_alias = gtestler_utils.get_command_alias()
    if command_alias ~= "" then
        command_alias = command_alias:gsub("^%s+", ""):gsub("%s+$", "")
        current_favorite_test = command_alias
        print(current_favorite_test)
        vim.cmd("bd!")
        M.open_tests_list()

        if string.sub(current_favorite_test, 1, string.len("*")) == "*" then
            tests_commands[wd]["current_favorite_test"] = nil
        else
            tests_commands[wd]["current_favorite_test"] = current_favorite_test
        end
        gtestler_utils.save_json_to_file(tests_commands)
    end
end

--- @return string
function M.add_favorite_test()
    current_favorite_test = M.add_test()

    tests_commands[wd].current_favorite_test = current_favorite_test
    return current_favorite_test
end

--- delete test under the cursor
function M.delete_test()
    local command_alias = gtestler_utils.get_command_alias()

    if command_alias ~= "" then
        if tests_commands[wd] ~= nil then
            tests_commands[wd][command_alias] = nil
        end
    end
    vim.cmd("bd!")
    M.open_tests_list()

    gtestler_utils.save_json_to_file(tests_commands)
end

function M.delete_all_tests()
    if tests_commands[wd] ~= nil then
        tests_commands[wd] = {}
    end

    if gtestler_win_id ~= nil then
        vim.cmd("bd!")
        M.open_tests_list()
    end

    gtestler_utils.save_json_to_file(tests_commands)
end

--- thanks to adoyle-h on https://github.com/nvim-telescope/telescope.nvim/issues/1923#issuecomment-1122642431
--- for easy visul selection hint
local function get_visual_selection()
    vim.cmd('noau normal! "vy"')
    local text = vim.fn.getreg("v")
    vim.fn.setreg("v", {})
    text = string.gsub(text, "\n", " ")
    local result = vim.split(text, " ")
    for _, command_alias in pairs(result) do
        if command_alias ~= "" then
            if tests_commands[wd] ~= nil then
                tests_commands[wd][command_alias] = nil
            end
        end
    end

    vim.cmd("bd!")
    M.open_tests_list()

    gtestler_utils.save_json_to_file(tests_commands)
end

function M.delete_selected_tests()
    get_visual_selection()
end

function M.execute_test()
    local new_cmd = gtestler_utils.get_command_and_test_name()
    if new_cmd ~= nil then
        M.execute_wrap(new_cmd)
    end
end

--- @param opts {split_method: string} "method: horizontal|vertical"
function M.setup(opts)
    opts = opts or {}
    M.opts = {
        split_method = gtestler_utils.validate_split_method(opts.split_method),
    }
end

return M
