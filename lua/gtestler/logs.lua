local M = {}
-- Definisci il percorso del file di log
local log_file_path = vim.fn.stdpath("data") .. "/gtestler_logs.txt"

function M.log_message(level, message)
    local json_message = vim.fn.json_encode(message)
    local file = io.open(log_file_path, "a")
    if file then
        file:write(
            string.format(
                "[%s] %s: %s\n",
                os.date("%Y-%m-%d %H:%M:%S"),
                level,
                json_message
            )
        )
        file:close()
    end
end

return M
