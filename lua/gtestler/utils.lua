local gtestler_log = require("gtestler.logs")
local M = {}
local function get_package_name()
    local test_dir = vim.fn.fnamemodify(vim.fn.expand("%:.:h"), ":r")
    return "./" .. test_dir
end

local function get_lines_from_cursor_up()
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local lines = vim.api.nvim_buf_get_lines(0, 0, row, false)
    return lines
end

local function startsWith(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

local function iterateLines()
    local lines = get_lines_from_cursor_up()
    for i = #lines, 1, -1 do
        if startsWith(lines[i], "func") then
            local functionName = string.match(lines[i], "func%s+([%w_]+)")
            return functionName
        end
    end
end

function M.goto_line(line)
    line = tostring(line)
    vim.api.nvim_command("buffer " .. vim.fn.expand("%")) -- Make sure we're on the current buffer
    vim.api.nvim_command(line) -- Go to line 100 (replace with your desired line number)

    gtestler_log.log_message("line: ", line)
    vim.api.nvim_command("normal! g" .. line) -- Move the cursor to the specified line
end

--- @param func_label  string
--- @return integer
function M.find_specific_function(func_label)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    local regex = "func%s+" .. func_label .. "%s*%b()"

    -- gtestler_log.log_message("lines", lines)

    for i, line in ipairs(lines) do
        -- print("the line:", line)
        if startsWith(line, "func") then
            gtestler_log.log_message("test: ", line)
            local function_name_match = string.match(line, regex)
            if function_name_match then
                return i
            end
        end
    end

    return -1
end

--- @param method string
--- @return string -- default: "split"
function M.validate_split_method(method)
    local cases = {
        ["vertical"] = function()
            return "vsplit"
        end,
        ["horizontal"] = function()
            return "split"
        end,
        -- TODO: implement float
        -- ["float"] = function()
        -- 	return "float"
        -- end,
        default = function()
            return "split"
        end,
    }

    -- Execute the case corresponding to 'value', or fall back to 'default'
    local case = cases[method] or cases["default"]
    return case()
end

function M.get_command_and_test_name()
    local pkg_name = get_package_name()
    local ft = vim.api.nvim_buf_get_option(0, "filetype")

    if ft ~= "go" then
        print("can only run test in a .go file, not " .. ft)
        return
    end

    local test_name = iterateLines()

    local new_cmd = "go clean -testcache && go test -v "
        .. pkg_name
        .. " -run "
        .. test_name
    return new_cmd, test_name
end

-- Scrivere la stringa JSON nel file
function M.save_json_to_file(commands_table)
    local current_commands = vim.fn.json_encode(commands_table)
    local state_dir = vim.fn.stdpath("state")
    local file = io.open(state_dir .. "/gtestler.json", "w")
    if file then
        file:write(current_commands)
        file:close()
    else
        print("Cannot open file for writing")
    end
end

-- Funzione per caricare il file JSON
function M.load_commands_table()
    -- Apri il file in modalità lettura

    local state_dir = vim.fn.stdpath("state")
    local file = io.open(state_dir .. "/gtestler.json", "r")
    if not file then
        print("No test founded")
        return nil
    end

    -- Leggi il contenuto del file
    local content = file:read("*all")
    file:close()

    return vim.fn.json_decode(content)
end

function M.get_working_directory()
    local cwd = vim.fn.getcwd()

    local t = {}
    for str in string.gmatch(cwd, "([^/]+)") do
        table.insert(t, str)
    end

    return t[#t]
end

function M.remove_star_if_exists(str)
    if str:match("^%* ") then
        return str:gsub("^%* ", "")
    end
    return str
end

--- in context of gtestler list gets the test name
--- checks the cursor current location line
---@return string
function M.get_command_alias()
    local buf = vim.api.nvim_get_current_buf()
    local line_number = vim.api.nvim_win_get_cursor(0)[1]
    local line_text =
        vim.api.nvim_buf_get_lines(buf, line_number - 1, line_number, false)[1]
    return line_text
end

--- @param file_path string
local function jump_to_file_dev(file_path)
    -- code
    --
    -- local buf = vim.api.nvim_get_current_buf()
    local cwd = vim.fn.getcwd()
    --  need to save full path to file
    local filename = cwd .. "/lua/gtestler/test/simple_test.go" -- replace with desired filename
    vim.api.nvim_command("wincmd w")
    vim.cmd("e " .. filename)
end
return M
