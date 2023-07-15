---@class diff
---@field start  integer # The number of bytes at the beginning of the replacement
---@field finish integer # The number of bytes at the end of the replacement
---@field text   string  # What to replace

---@param  uri  string # The uri of file
---@param  text string # The content of file
---@return nil|diff[]
function OnSetText(uri, text)
	if text:sub(1, 4) ~= '--##' then
		return nil
	end
	local diffs = {}
	-- Remove $ marker
	for pos in text:gmatch '()%$' do
		diffs[#diffs+1] = {
			start  = pos,
			finish = pos,
			text   = "",
		}
	end

	return diffs
end

