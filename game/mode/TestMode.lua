--
-- mode/TestMode.lua
--

local schema, TestMode, EditMode = require 'src/mode' { 'TestMode', 'EditMode' }
local Level = require 'src/Level'
local Node = require 'src/Node'
local render = require 'src/render'
local Vector = require 'src/Vector'
local terrains = require 'src/terrains'

function TestMode:enter()
	self:_gen()
end

function TestMode:_gen()
	local maxdepth = 9
	local aabb = Node.aabbFromMaxdepth(maxdepth)
	local level = Node.new(nil, aabb, terrains.wall)
	-- local level = Level.new(maxdepth)

	for i = 1, 10 do
		local leaf = level:randomLeaf()
		leaf:split()
	end

	self.level = level
	self.selected = nil
end

function TestMode:exit()
end

function TestMode:update( dt )
	local mx = love.mouse.getX()
	local my = love.mouse.getY()
	local pointer = Vector.new {
		x = mx,
		y = my
	}

	self.selected = nil

	local leaves = self.level:leaves()
	for _, leaf in ipairs(leaves) do
		if leaf.aabb:contains(pointer) then
			self.selected = leaf
		end
	end
end

function TestMode:draw()
	render.level(self.level, {})

	render.shadowf(10, 10, '#%d', #self.level:leaves())
end

function TestMode:keypressed( key, is_repeat )
	if key == '0' then
		self:become(EditMode)
	elseif key == ' ' then
		self:_gen()
	elseif key == 's' then
		local level = self.level
		local leaves = level:leaves()
		for _, leaf in ipairs(leaves) do
			if leaf.depth < 6 then
				leaf:split()
			end
		end
	elseif key == 'r' then
		local level = self.level
		for i = 1, 10 do
			local leaf = level:randomLeaf()
			leaf:split()
		end
	end
end
