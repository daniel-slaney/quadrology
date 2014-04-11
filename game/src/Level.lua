--
-- src/Level.lua
--

local AABB = require 'src/AABB'
local terrains = require 'src/terrains'

local Level = {}
Level.__index = Level

local function _isleaf( node )
	return #node == 0
end

local function _node( parent, aabb )
	assert(parent == nil or _isleaf(parent))

	return {
		nil, nil, nil, nil,
		parent = parent,
		aabb = aabb,
		depth = parent == nil and 0 or parent.depth + 1,
		terrain = math.random(1,3) == 1 and terrains.wall or terrains.floor
	}
end

function Level.new( maxdepth )
	assert(math.isint(maxdepth))
	assert(1 < maxdepth and maxdepth <= 24)

	local extent = 2^maxdepth
	local aabb = AABB.new {
		xmin = 0,
		ymin = 0,
		xmax = extent,
		ymax = extent,
	}

	local root = _node(nil, aabb)

	local result = {
		maxdepth = maxdepth,
		root = root,
		nodes = { root }
	}
	setmetatable(result, Level)

	return result
end

function Level:isLeaf( node )
	return _isleaf(node)
end

function Level:split( node )
	assert(self:isLeaf(node))

	node.terrain = nil

	local aabb = node.aabb
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

	local tl = _node(node, tlAABB)
	local tr = _node(node, trAABB)
	local bl = _node(node, blAABB)
	local br = _node(node, brAABB)

	node[1] = tl
	node[2] = tr
	node[3] = bl
	node[4] = br

	local nodes = self.nodes
	nodes[#nodes+1] = tl
	nodes[#nodes+1] = tr
	nodes[#nodes+1] = bl
	nodes[#nodes+1] = br

	assert(not self:isLeaf(node))

	return tl, tr, bl, br
end

function Level:fold( bf, lf, init )
end

function Level:leaves()
	local result = {}
	local nodes = self.nodes

	for i = 1, #nodes do
		local node = nodes[i]
		if _isleaf(node) then
			result[#result+1] = node
		end
	end

	assert(#result > 0)

	return result
end

function Level:randomLeaf()
	local leaves = self:leaves()
	return leaves[math.random(1, #leaves)]
end

return Level
