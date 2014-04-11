--
-- src/Node.lua
--

local AABB = require 'src/AABB'
local terrains = require 'src/terrains'

local Node  = {}
Node.__index = Node

function Node.aabbFromMaxdepth( maxdepth )
	assert(math.isint(maxdepth))
	assert(1 <= maxdepth and maxdepth <= 24)

	local extent = 2^maxdepth
	return AABB.new {
		xmin = 0,
		ymin = 0,
		xmax = extent,
		ymax = extent,
	}
end

function Node.new( parent, aabb, terrain )
	assert(parent == nil or parent:isLeaf())

	terrain = terrain or terrains.wall

	local result = {
		-- This is to make space for potential future children but because most
		-- nodes will be leaves this might not be a good idea...
		nil, nil, nil, nil,
		parent = parent,
		aabb = aabb,
		depth = parent == nil and 0 or parent.depth + 1,
		terrain = terrain
	}

	setmetatable(result, Node)

	return result
end

function Node:isLeaf()
	return #self == 0
end

function Node:isBranch()
	return #self == 4
end

function Node:split()
	assert(self:isLeaf())

	-- TODO: this is a bit smelly.
	local terrain = self.terrain
	self.terrain = nil

	local aabb = self.aabb
	local xmin, ymin = aabb.xmin, aabb.ymin
	local xmax, ymax = aabb.xmax, aabb.ymax
	local xmid = xmin + (xmax - xmin) * 0.5
	local ymid = ymin + (ymax - ymin) * 0.5

	local tlAABB = AABB.new {
		xmin = xmin,
		ymin = ymin,
		xmax = xmid,
		ymax = ymid
	}

	local trAABB = AABB.new {
		xmin = xmid,
		ymin = ymin,
		xmax = xmax,
		ymax = ymid
	}

	local blAABB = AABB.new {
		xmin = xmin,
		ymin = ymid,
		xmax = xmid,
		ymax = ymax
	}

	local brAABB = AABB.new {
		xmin = xmid,
		ymin = ymid,
		xmax = xmax,
		ymax = ymax
	}

	local tl = Node.new(self, tlAABB, terrain)
	local tr = Node.new(self, trAABB, terrain)
	local bl = Node.new(self, blAABB, terrain)
	local br = Node.new(self, brAABB, terrain)

	self[1] = tl
	self[2] = tr
	self[3] = bl
	self[4] = br

	assert(not self:isLeaf())

	return tl, tr, bl, br
end

function Node:collapse( terrain )
	assert(self:isBranch())

	self.terrain = terrain
	self[1] = nil
	self[2] = nil
	self[3] = nil
	self[4] = nil

	assert(self:isLeaf())
end

function Node:fold( bfunc, lfunc )
	local function aux( node )
		if node:isLeaf() then
			return lfunc(node)
		else
			local tl = aux(node[1])
			local tr = aux(node[2])
			local bl = aux(node[3])
			local br = aux(node[4])

			return bfunc(node, tl, tr, bl, br)
		end
	end

	return aux(self)
end

function Node:clone()
	local depth = self.depth
	local map = {}

	local function branch( node, tl, tr, bl, br )
		local copy = Node.new(nil, node.aabb)
		map[node] = copy
		copy.depth = node.depth - depth
		copy.terrain = nil

		tl.parent = copy
		tr.parent = copy
		bl.parent = copy
		br.parent = copy

		copy[1], copy[2], copy[3], copy[4] = tl, tr, bl, br 

		return copy
	end

	local function leaf( node )
		local copy = Node.new(nil, node.aabb, node.terrain)
		map[node] = copy
		copy.depth = node.depth - depth

		return copy
	end

	return self:fold(branch, leaf), map
end

function Node:leaves()
	local result = {}

	local function aux( node )
		if node:isLeaf() then
			result[#result+1] = node
		else
			aux(node[1])
			aux(node[2])
			aux(node[3])
			aux(node[4])
		end
	end

	aux(self)

	for i, v in ipairs(result) do
		assert(v:isLeaf())
	end

	return result
end

function Node:nodeset()
	local result = {}

	local function aux( node )
		result[node] = true
		if node:isBranch() then
			aux(node[1])
			aux(node[2])
			aux(node[3])
			aux(node[4])
		end
	end

	aux(self)

	return result
end

-- Create a table suitable for table.compile(), i.e. remove cycles.
function Node:export()
	local function branch( node, tl, tr, bl, br )
		return {
			tl, tr, bl, br,
		}
	end

	local function leaf( node )
		return {
			terrain = node.terrain.name
		}
	end

	return self:fold(branch, leaf)
end

function Node.import( data, aabb )
	local function aux( data, node )
		if data.terrain then
			node.terrain = terrains[data.terrain]
			assert(node.terrain)
		else
			assert(#data == 4)
			node:split()
			aux(data[1], node[1])
			aux(data[2], node[2])
			aux(data[3], node[3])
			aux(data[4], node[4])
		end
	end

	local root = Node.new(nil, aabb)
	aux(data, root)

	return root
end

function Node:randomLeaf()
	local leaves = self:leaves()
	return leaves[math.random(1, #leaves)]
end

return Node
