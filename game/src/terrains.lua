local terrains = {}

terrains.wall = {
	colour = { 64, 64, 64, 255 },
	symbol = '#',
}

terrains.floor = {
	colour = { 184, 118, 61, 255 },
	symbol = '.'
}

terrains.marker = {
	colour = { 255, 0, 255, 255 },
	symbol = '?'
}

for name, def in pairs(terrains) do
	def.name = name
end

return terrains
