--
-- mode/init.lua
--

local state = require 'src/state'
require 'mode/TestMode'
require 'mode/EditMode'
require 'mode/EditTextMode'
local schema, init = require 'src/mode' { 'TestMode' }

local function export( ... )
	return state.machine(schema, init, ...)
end

return export
