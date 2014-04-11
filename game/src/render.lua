--
-- src/render.lua
--

local function shadowf( x, y, ... )
	love.graphics.setColor(0, 0, 0, 255)

	local font = love.graphics.getFont()
	local text = string.format(...)

	local tx, ty = x, y

	love.graphics.print(text, tx-1, ty-1)
	love.graphics.print(text, tx-1, ty+1)
	love.graphics.print(text, tx+1, ty-1)
	love.graphics.print(text, tx+1, ty+1)

	love.graphics.setColor(192, 192, 192, 255)

	love.graphics.print(text, tx, ty)
end

local function level( level, selection )
	local leaves = level:leaves()

	for i = 1, #leaves do
		local leaf = leaves[i]

		local colour = leaf.terrain.colour
		love.graphics.setColor(colour[1], colour[2], colour[3], colour[4])

		local aabb = leaf.aabb
		love.graphics.rectangle('fill', aabb.xmin, aabb.ymin, aabb:width(), aabb:height())
	end

	love.graphics.setColor(0, 0, 0, 255)
	for i = 1, #leaves do
		local leaf = leaves[i]
		local aabb = leaf.aabb
		love.graphics.rectangle('line', aabb.xmin, aabb.ymin, aabb:width(), aabb:height())
	end

	love.graphics.setColor(255, 255, 255, 255)
	for i = 1, #leaves do
		local leaf = leaves[i]
		if selection[leaf] then
			local aabb = leaf.aabb
			love.graphics.rectangle('line', aabb.xmin, aabb.ymin, aabb:width(), aabb:height())
		end
	end
end

local function levelViewport( level, selection, viewport )
	viewport:setup()

	local leaves = level:leaves()

	for i = 1, #leaves do
		local leaf = leaves[i]

		local colour = leaf.terrain.colour
		love.graphics.setColor(colour[1], colour[2], colour[3], colour[4])

		local aabb = leaf.aabb
		love.graphics.rectangle('fill', aabb.xmin, aabb.ymin, aabb:width(), aabb:height())
	end

	love.graphics.setColor(0, 0, 0, 255)
	for i = 1, #leaves do
		local leaf = leaves[i]
		local aabb = leaf.aabb
		love.graphics.rectangle('line', aabb.xmin, aabb.ymin, aabb:width(), aabb:height())
	end

	love.graphics.setColor(255, 255, 255, 255)
	for i = 1, #leaves do
		local leaf = leaves[i]
		if selection[leaf] then
			local aabb = leaf.aabb
			love.graphics.rectangle('line', aabb.xmin, aabb.ymin, aabb:width(), aabb:height())
		end
	end
end

return {
	shadowf = shadowf,
	level = level,
	levelViewport = levelViewport
}
