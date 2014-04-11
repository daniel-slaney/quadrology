--
-- mode/EditMode.lua
--

local schema, EditMode, TestMode, EditTextMode = require 'src/mode' { 'EditMode', 'TestMode', 'EditTextMode' }
local Node = require 'src/Node'
local render = require 'src/render'
local Vector = require 'src/Vector'
local terrains = require 'src/terrains'
local Viewport = require 'src/Viewport'
local AABB = require 'src/AABB'

local loveMapsPath = 'resources/maps'
local ioMapsPath = 'game/' .. loveMapsPath

local function _defaultAABB()
	local maxdepth = 9
	return Node.aabbFromMaxdepth(maxdepth)
end

-- self.maps = { [name] = map }

function EditMode:enter()
	local maps = self:_loadAllMaps(loveMapsPath)

	if next(maps) == nil then
		maps.default = self:_genMap('default')
	end

	assert(table.count(maps) > 0)

	self.maps = maps
	self:_changeMap('next')
	self.pointer = nil

	local portal = AABB.new(self:frame().root.aabb)
	portal:scale(1.1)

	self.viewport = Viewport.new(portal)
end

function EditMode:frame()
	local map = self.map
	local stack = map.stack
	return stack[stack.index]
end

function EditMode:_changeMap( option )
	assert(option == 'prev' or option == 'next')

	local ordered = table.values(self.maps)
	assert(#ordered > 0)
	table.sort(ordered, function ( lhs, rhs)
		return lhs.name < rhs.name
	end)

	local current = self.map

	if not current then
		self.map = ordered[1]
		return
	end

	for i = 1, #ordered do
		if ordered[i] == current then
			if option == 'next' then
				self.map = ordered[i+1] or ordered[1]
			else
				self.map = ordered[i-1] or ordered[#ordered]
			end
			break
		end
	end
end

function EditMode:_loadAllMaps( mapspath )
	local maps = {}
	local files = love.filesystem.getDirectoryItems(mapspath)
	for _, filename in ipairs(files) do
		local filepath = string.format('%s/%s', mapspath, filename)
		local isFile = love.filesystem.isFile(filepath)
		local isMap = filename:find('^.+%.map$') ~= nil

		printf('%s file:%s map:%s', filepath, isFile, isMap)

		if isFile and isMap then
			local mapname = filename:match('^(.+)%.map$')
			local root = self:_loadMap(filepath)

			maps[mapname] = {
				name = mapname,
				hover = nil,
				stack = {
					{
						root = root,
						selection = {}
					},
					index = 1,
					saved = 1
				}
			}
		end		
	end

	return maps
end

function EditMode:_loadMap( filepath )
	local f, err = io.open('game/' ..filepath, 'r')
	if f then
		local src = f:read('*a')
		print(src)
		local func, err = loadstring(src)

		if func then
			local data = func()
			local root = Node.import(data, _defaultAABB())

			return root
		else
			error(err)
		end
	else
		error(err)
	end
end

function EditMode:_genMap( name )
	local aabb = _defaultAABB()
	local root = Node.new(nil, aabb, terrains.wall)

	return {
		name = name,
		hover = nil,
		pointer = nil,
		stack = {
			{
				root = root,
				selection = {}
			},
			index = 1,
			saved = nil
		}
	}
end

function EditMode:edit( func )
	-- Copy the root and fixup the selection.
	local oldFrame = self:frame()
	local newRoot, nodeMap = oldFrame.root:clone()
	local newSelection = {}
	for oldLeaf in pairs(oldFrame.selection) do
		local newLeaves = nodeMap[oldLeaf]:leaves()
		for i = 1, #newLeaves do
			newSelection[newLeaves[i]] = true
		end
	end
	
	-- Push the new frame.
	local map = self.map
	local stack = map.stack
	stack[#stack+1] = {
		root = newRoot,
		selection = newSelection
	}
	stack.index = stack.index + 1

	-- Fixup the hover.
	map.hover = nil
	self:_pick()

	local result = func(newRoot, map.hover, newSelection)

	if result == 'undo' then
		self:_undo()
	else
		self:_fixSelection()

		-- We've made an edit so if there's any nodes on the stack after us
		-- they are now out of date and can be removed.
		if #stack > stack.index then
			for i = stack.index+1, #stack do
				stack[i] = nil
			end
		end

		if stack.saved > stack.index then
			stack.saved = nil
		end
	end
end

function EditMode:_undo()
	local stack = self.map.stack
	printf('undo #stack:%d index:%d', #stack, stack.index)
	if #stack > 1 and stack.index > 1 then
		staxk.index = stack.index - 1
		self.map.hover = nil
		printf('-> #stack:%d index:%d', #stack, stack.index)
	end
end

function EditMode:_redo()
	local stack = self.stack
	printf('redo #stack:%d index:%d', #stack, stack.index)
	if stack.index < #stack then
		stack.index = stack.index + 1
		self.map.hover = nil
		printf('-> #stack:%d index:%d', #stack, stack.index)
	end
end

function EditMode:_save()
	local exported = self:frame().root:export()
	local src = table.compile(exported)

	local filepath = ioMapsPath .. self.map.name .. '.map'

	local f, err = io.open(filepath, 'w')
	if f then
		f:write(src)
		f:close()

		local stack = self.map.stack
		stack.saved = stack.index
	else
		error(err)
	end
end

function EditMode:exit()
end

function EditMode:_pick()
	local leaves = self:frame().root:leaves()
	
	local pointer = self.pointer
	if pointer then
		for i = 1, #leaves do
			local leaf = leaves[i]
			if leaf.aabb:contains(pointer) then
				self.map.hover = leaf
				break
			end
		end
	end
end

function EditMode:_fixSelection()
	local frame = self:frame()
	local leafset = table.valueset(frame.root:leaves())
	local oldSelection = frame.selection
	local newSelection = {}
	for oldSelected in pairs(oldSelection) do
		if leafset[oldSelected] then
			-- Leaf still exists so keep it.
			newSelection[oldSelected] = true
		elseif oldSelected:isBranch() then
			-- Was a leaf now a branch so replace it with the leaves.
			local newLeaves = oldSelected:leaves()
			for i = 1, #newLeaves do
				local newLeaf = newLeaves[i]
				newSelection[newLeaf] = true
			end
		else
			-- Leaf not in the selection so must have been pruned
			-- by a collapse. Iterate through parents until we find where the
			-- collapse happened.
			local node = oldSelected
			repeat
				node = node.parent
			until node == nil or leafset[node]
			
			if node then
				newSelection[node] = true
			end
		end
	end

	frame.selection = newSelection
end

function EditMode:update( dt )
	local map = self.map
	map.hover = nil
	self.pointer = nil

	if love.window.hasMouseFocus() then
		local mx = love.mouse.getX()
		local my = love.mouse.getY()
		local pointer = Vector.new {
			x = mx,
			y = my
		}

		self.pointer = self.viewport:screenToWorld(pointer)

		self:_pick()

		if map.hover and love.keyboard.isDown('lshift', 'rshift') then
			self:frame().selection[map.hover] = true
		end
	end
end

function EditMode:draw()
	local frame = self:frame()
	love.graphics.push()
	render.levelViewport(frame.root, frame.selection, self.viewport)
	love.graphics.pop()

	local stack = self.map.stack
	local saved = stack.saved == stack.index 
	render.shadowf(10, 10, 'Edit - #%d %s', #frame.root:leaves(), saved and '' or '*')
end

local _terrainKeys = {
	q = terrains.wall,
	w = terrains.floor,
	e = terrains.marker
}

function EditMode:keypressed( key, is_repeat )
	if key == '0' then
		self:become(TestMode)
	elseif _terrainKeys[key] then
		self:edit(function ( root, hover, selection )
			local terrain = _terrainKeys[key]
			for selected in pairs(selection) do
				selected.terrain = terrain
			end
		end)
	elseif key == 'c' then
		self:edit(function ( root, hover, selection )
			local parents = {}
			for selected in pairs(selection) do
				if hover.depth > 0 then
					parents[selected.parent] = selected.terrain
				end
			end

			for parent, terrain in pairs(parents) do
				parent:collapse(terrain)
			end
		end)
	elseif key == 's' then
		if love.keyboard.isDown('lctrl', 'rctrl') then
			self:_save()
		else
			self:edit(function ( root, hover, selection )
				for leaf in pairs(selection) do
					leaf:split()
				end
			end)
		end
	elseif key == 'l' then
		local map = self.map
		local maps = self.maps
		maps[map.name] = self:_loadMap(map.name)
	elseif key == 'r' then
		self:edit(function ( root, hover, selection )
			for i = 1, 10 do
				local leaf = root:randomLeaf()
				leaf:split()
			end
		end)
	elseif key == 'n' then
		local map = self.map
		local maps = self.maps
		self:push(EditTextMode, self, map.name, function ( text )
			if text ~= nil and #text > 0 and not maps[text] then
				maps[map.name] = nil
				map.name = text
				maps[map.name] = map
			end
		end)
	elseif key == 'u' then
		if love.keyboard.isDown('lshift', 'rshift') then
			self:_redo()
		else
			self:_undo()
		end
	end
end

-- click       : select hover or clear selection if no hover 

function EditMode:mousepressed( x, y, button )
	local hover = self.map.hover
	local frame = self:frame()
	local selection = frame.selection
	if hover then
		print('add')
		if love.keyboard.isDown('lctrl', 'rctrl') then
			if selection[hover] then
				selection[hover] = nil
			else
				selection[hover] = true
			end
		else
			if selection[hover] then
				frame.selection = {}
			else
				frame.selection = { [hover] = true }
			end
		end
	else
		print('clear')
		frame.selection = {}
	end
end
