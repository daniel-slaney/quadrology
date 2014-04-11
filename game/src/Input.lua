--
-- src/Input.lua
--

local Input = {}

--
-- params = {
--     { key = 'a', modifiers = { 'alt' }, desc = 'print a', func =  function ( key, is_repear ) print('a') end }	
--     { text = '', modifiers = '', desc = '...', func }	
-- }
--
-- - key or text required
-- - modifier optional
-- - desc required
-- - func required
--

function Input.new( params )
end

function Input:textinput( text )
end

function Input:keypressed( key, is_repeat )
end

return Input
