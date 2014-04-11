--
-- src/Vault.lua
--

local Level = require 'src/Level'

local Vault = {}

local tags = {
	['#'] = true,
	['.'] = true,
	['?'] = true
}

function Vault.new( params )
	local extent = params.extent
	local depth = math.log(extent, 2)
	assert(math.isint(depth))

	for y = 1, extent do
		for x = 1, extent do
			local item = params[y][x]
			assert(tags[item])
		end
	end

	local result = {}

	setmetatable(result, Vault)

	return result
end

return Vault
