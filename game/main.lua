require 'jit'
print('jit.version', jit.version)
print('_VERSION', _VERSION)

math.randomseed(os.time())

-- All other lua files assume this is required before they are.
require 'prelude'

local newMachine = require 'mode'

local time = 0
local frames = 0
local machine

function love.load()
	gFont30 = love.graphics.newFont('resources/inconsolata.otf', 30)
	gFont15 = love.graphics.newFont('resources/inconsolata.otf', 15)
	love.graphics.setFont(gFont30)

	machine = newMachine()
end

function love.update( dt )
	time = time + dt
	frames = frames + 1

	machine:update(dt)
end

function love.draw()
	machine:draw()
end

function love.mousepressed( x, y, button )
	print('love.mousepressed', x, y, button)
	machine:mousepressed(x, y, button)
end

function love.mousereleased( x, y, button )
	print('love.mousereleased', x, y, button)
	machine:mousereleased(x, y, button)
end

function love.keypressed( key, isrepeat )
	printf('love.keypressed %s %s', key, tostring(isrepeat))

	if key == 'escape' then
		love.event.push('quit')
	elseif machine then
		machine:keypressed(key, isrepeat)
	end
end

function love.keyreleased( key )
	print('love.keyreleased', key)
	machine:keyreleased(key)
end

function love.textinput( text )
	print('love.textinput', text)
	machine:textinput(text)
end

function love.focus( f )
	print('love.focus', f)
	machine:focus(f)
end

function love.mousefocus( f )
	print('love.mousefocus', f)
	machine:mousefocus(f)
end

function love.visible( v )
	print('love.visible', v)
	machine:visible(v)
end

-- TODO: add joystick and gamepad callbacks



