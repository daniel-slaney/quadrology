local Vector = require 'src/Vector'
local AABB = require 'src/AABB'

local Viewport = {}
Viewport.__index = Viewport

local function _screen()
	local ww, wh = love.graphics.getDimensions()
	return AABB.new {
		xmin = 0,
		xmax = ww,
		ymin = 0,
		ymax = wh,
	}	
end

function Viewport.new( target )
	local ww, wh = love.graphics.getDimensions()

	if target then
		target = AABB.new(target)
		target:similarise(_screen())
	else
		target = _screen()
	end

	local result = {
		portal = target,
	}

	setmetatable(result, Viewport)

	return result
end

function Viewport:setup()
	local ww, wh = love.graphics.getDimensions()
	local portal = self.portal
	
	local xScale = ww / portal:width()
	local yScale = wh / portal:height()

	love.graphics.scale(xScale, yScale)
	love.graphics.translate(-portal.xmin, -portal.ymin)
end

function Viewport:screenToWorld( point )
	local portal = self.portal

	local windowWidth = love.graphics.getWidth()
	local windowHeight = love.graphics.getHeight()

	local x = lerpf(point.x, 0, windowWidth, portal.xmin, portal.xmax)
	local y = lerpf(point.y, 0, windowHeight, portal.ymin, portal.ymax)

	return Vector.new { x = x, y = y }
end

function Viewport:worldToScreen( point )
	local portal = self.portal

	local windowWidth = love.graphics.getWidth()
	local windowHeight = love.graphics.getHeight()

	local x = lerpf(point.x, portal.xmin, portal.xmax, 0, windowWidth)
	local y = lerpf(point.y, portal.ymin, portal.ymax, 0, windowHeight)

	return Vector.new { x=x, y=y }
end

function Viewport:centreOn( centre )
	self.portal:moveTo(centre)
end

return Viewport
