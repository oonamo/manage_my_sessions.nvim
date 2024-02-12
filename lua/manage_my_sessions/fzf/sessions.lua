local config = require("manage_my_sessions.config")
local command = vim.api.nvim_create_user_command
---@class Fzf
---@field fzf_exec function()

---@return boolean, Fzf
local function hasFZF()
	local ok, fzf = pcall(require, "fzf-lua")

	return ok, fzf
end

---@class FzFSessions
---@field fzf Fzf
---@field command string
local M = {}

function M:create_command()
	local session = config.values.sessions
	local has_fzf, fzf = hasFZF()
	local command = ""
	local dirs = ""
	for _, v in pairs(session) do
		local last_char = string.sub(v[1], -1)
		if last_char ~= "/" or last_char ~= "\\" then
			v[1] = v[1] .. "/"
		end
		dirs = string.format("%s%s %s", dirs, command, v[1])
	end
	command = string.format("rg --files --max-depth 2 --null%s | xargs -0 dirname | uniq", dirs)
	M.command = command
end
function M:run()
	-- coroutine.wrap(function()
	local has_fzf, fzf = hasFZF()
	if not has_fzf then
		print("fzf not found")
		return
	end
	if not M.command then
		M:create_command()
	end
	fzf.fzf_exec(M.command, {
		actions = {
			---@param selected string
			["default"] = function(selected)
				if selected == nil then
					return
				end
				local actions
				for _, v in pairs(config.values.sessions) do
					local expanded = vim.fn.fnamemodify(v[1], ":p")
					local first_expanded = vim.fn.fnamemodify(selected[1], ":p:h")
					local second_expanded = vim.fn.fnamemodify(selected[1], ":p:h:h")
					expanded = string.gsub(expanded, "\\", "/")
					first_expanded = string.gsub(first_expanded, "\\", "/") .. "/"
					second_expanded = string.gsub(second_expanded, "\\", "/") .. "/"
					if expanded == first_expanded then
						actions = v
						break
					end
					if expanded == second_expanded then
						actions = v
						break
					end
				end
				actions.before()
				---@diagnostic disable-next-line: param-type-mismatch
				local is_ok, _ = pcall(actions.select, selected[1])
				if not is_ok then
					print("invalid path: " .. selected[1])
					return
				end
				if config.values.term_cd then
					vim.cmd("!cd " .. vim.fn.expand(selected[1]))
				end
				actions.after(selected[1])
			end,
		},
	})
	-- end)()
end
return M
