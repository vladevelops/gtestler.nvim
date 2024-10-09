local M = {}

local pattern = "gtestler"
local gtestler_buffer = -1
function M.create_buffer()
    local width = 80
    local height = 20
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local opts = {
        style = "minimal",
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        border = "rounded", -- Puoi cambiare lo stile del bordo
        title = pattern,
    }

    gtestler_buffer = vim.api.nvim_create_buf(true, true)

    local gtestler_win_id = vim.api.nvim_open_win(gtestler_buffer, true, opts)

    vim.api.nvim_win_set_option(gtestler_win_id, "number", true)
    vim.api.nvim_buf_set_name(gtestler_buffer, "gtestler-tests-list")
    vim.api.nvim_buf_set_option(gtestler_buffer, "filetype", pattern)
    vim.api.nvim_buf_set_option(gtestler_buffer, "bufhidden", "delete")
    return gtestler_buffer, gtestler_win_id
end

return M
