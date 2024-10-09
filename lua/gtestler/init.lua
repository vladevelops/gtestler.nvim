local gtestler_utils = require("gtestler.utils")
local gtestler_ui = require("gtestler.ui")
local M = {}

local gtestler_autogroup =
    vim.api.nvim_create_augroup("DEVELOPLAND_GTESTLER", { clear = true })

local wd = gtestler_utils.get_working_directory()
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

vim.api.nvim_create_autocmd("VimEnter", {

    callback = function()
        local retore_tabel = gtestler_utils.load_commands_table()

        if retore_tabel ~= nil then
            tests_commands = retore_tabel
        end
    end,

    group = gtestler_autogroup,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = pattern,
    group = gtestler_autogroup,
    callback = function()
        vim.keymap.set("n", "<CR>", function()
            M.run_selected_test()
        end, { buffer = true, desc = "run selected test" })

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
    else
        print("Command not recognized: " .. subcommand)
    end
end, {
    nargs = 1,
    complete = function()
        return { "horizontal", "vertical" }
    end,
    desc = "Run to set prefered split method for this session. horizontal: split, vertical: vsplit",
})

--- opens the list with all the tests to run
function M.open_tests_list()
    local floating_buffer, win_id = gtestler_ui.create_buffer()
    gtestler_win_id = win_id

    vim.api.nvim_buf_set_keymap(
        floating_buffer,
        "n",
        "<leader>tr",
        "<Cmd>lua require('gtestler').run_selected_test()<CR>",
        { silent = true }
    )

    local tests_list = {}

    local count = 1
    if tests_commands[wd] ~= nil then
        for label, _ in pairs(tests_commands[wd]) do
            if label == current_favorite_test then
                table.insert(tests_list, count, "* " .. label)
            else
                table.insert(tests_list, count, label)
            end
            count = count + 1
        end
    end

    vim.api.nvim_buf_set_lines(floating_buffer, 0, -1, false, tests_list)

    -- this option is applied here, so the buffer remains writable when we need to add all the text
    vim.api.nvim_buf_set_option(floating_buffer, "modifiable", false)
end

--- runs selected test under the cursor
function M.run_selected_test()
    local command_alias = gtestler_utils.get_command_alias()
    if command_alias ~= "" then
        local new_cmd = tests_commands[wd][command_alias]
        M.execute_wrap(new_cmd)
    else
        print("No test to run")
    end
end

--- runs a previesly assigned favorite test
function M.execute_favorite_test()
    if current_favorite_test ~= "" then
        local new_cmd = tests_commands[wd][current_favorite_test]
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

    if tests_commands[wd] == nil then
        tests_commands[wd] = {}
    end

    tests_commands[wd][test_name] = new_cmd

    gtestler_utils.save_json_to_file(tests_commands)
    return test_name
end
function M.delete_test()
    local command_alias = gtestler_utils.get_command_alias()

    if command_alias ~= "" then
        if tests_commands[wd] ~= nil then
            tests_commands[wd][command_alias] = nil
        end
    end
    vim.cmd("bd!")
    M.open_tests_list()
end
function M.execute_test()
    local new_cmd = gtestler_utils.get_command_and_test_name()
    M.execute_wrap(new_cmd)
end

--- @param opts {split_method: string} "method: horizontal|vertical"
function M.setup(opts)
    opts = opts or {}
    M.opts = {
        split_method = gtestler_utils.validate_split_method(opts.split_method),
    }

    vim.keymap.set("n", "<leader>tl", function()
        M.open_tests_list()
    end, { desc = "Open avaiable tests list" })

    vim.keymap.set("n", "<leader>tr", function()
        M.execute_test()
    end, { desc = "run go test under the cursor" })

    vim.keymap.set("n", "<leader>ta", function()
        local test_name = M.add_test()
        print("Test: " .. test_name .. " is now added to gtestler list")
    end, { desc = "Add to gtestler list" })

    vim.keymap.set("n", "<leader>td", function()
        M.delete_test()
    end, { desc = "" })

    vim.keymap.set("n", "<leader>taf", function()
        local test_name = M.add_test()
        current_favorite_test = test_name

        print("Test: " .. test_name .. " is now added to fast execute")
    end)

    vim.keymap.set("n", "<leader>tf", function()
        print("Test: favorite test running")
        M.execute_favorite_test()
    end, { desc = "run go favorite tets" })
end

return M
