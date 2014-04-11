--
-- mode/EditTextMode.lua
--

local schema, EditTextMode = require 'src/mode' { 'EditTextMode' }
local render = require 'src/render'

function EditTextMode:enter( super, text, doneFunc )
	self.super = super
	self.doneFunc = doneFunc
	self.text = text or ''
end

function EditTextMode:exit()
end

function EditTextMode:update( dt )
end

function EditTextMode:draw()
	love.graphics.push()
	self.super:draw()
	love.graphics.pop()

	local ww, wh = love.graphics.getDimensions()
	local cx, cy = ww * 0.5, wh * 0.5

	local text = self.text

	local font = love.graphics.getFont()
	local hh = font:getHeight() * 0.5
	local hw = font:getWidth(text) * 0.5

	local tx, ty = cx - hw, cy - hh

	-- Make the text safe for puttiing through  string.format.
	render.shadowf(tx, ty, text:gsub('%%', '%%%%'))

	return 'break'
end

function EditTextMode:keypressed( key, is_repeat )
	if key == 'backspace' then
		self.text = self.text:sub(1, -2)
	elseif key == 'return' then
		self.doneFunc(self.text)
		return self:kill()
	end

	return 'break'
end

function EditTextMode:textinput( text )
	self.text = self.text .. text
	print('text:', self.text)

	return 'break'
end


function EditTextMode:mousepressed( x, y, button )
	return 'break'
end
