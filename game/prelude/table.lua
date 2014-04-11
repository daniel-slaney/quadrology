--
-- misc/table.lua
--
-- Utility functions for working with tables.
--
-- TODO: random functions need optional generator argument.
-- TODO: luafun might be a better option for a lot of these.
--

function table.keys( tbl )
	local result = {}

	for k, _ in pairs(tbl) do
		result[#result+1] = k
	end

	return result
end

function table.values( tbl )
	local result = {}

	for _, v in pairs(tbl) do
		result[#result+1] = v
	end

	return result
end

function table.keyset( tbl )
	local result = {}

	for k, _ in pairs(tbl) do
		result[k] = true
	end

	return result
end

function table.valueset( tbl )
	local result = {}

	for _, v in pairs(tbl) do
		result[v] = true
	end

	return result
end

-- Really just a shallow copy.
function table.copy( tbl )
	local result = {}

	for k, v in pairs(tbl) do
		result[k] = v
	end

	return result
end

function table.count( tbl )
	local result = 0

	for _ in pairs(tbl) do
		result = result + 1
	end

	return result
end

function table.append( tbl1, tbl2 )
	local offset = #tbl1
	for i = 1, #tbl2 do
		tbl1[offset+i] = tbl2[i]
	end

	return tbl1
end

function table.random( tbl )
	assert(next(tbl))
	local count = table.count(tbl)

	local index = math.random(1, count)
	local k = nil

	for i = 1, index do
		k = next(tbl, k)
	end

	return k, tbl[k]
end

function table.shuffle( tbl )
	for i = 1, #tbl-1 do
		local index = math.random(i, #tbl)
		tbl[i], tbl[index] = tbl[index], tbl[i]
	end
end

function table.reverse( tbl )
	local size = #tbl

	for index = 1, math.ceil(size * 0.5) do
		local mirrorIndex = size - (index - 1)
		tbl[index], tbl[mirrorIndex] = tbl[mirrorIndex], tbl[index]
	end

	return tbl
end

function table.inverse( tbl )
	local result = {}

	for k, v in pairs(tbl) do
		result[v] = k
	end

	return result
end

function table.collect( tbl, func )
	local result = {}

	for k, v in pairs(tbl) do
		result[k] = func(v)
	end

	return result
end

local _literals = {
	boolean =
		function ( value )
			if value then
				return 'true'
			else
				return 'false'
			end
		end,
	number =
		function ( value )
			if math.floor(value) == value then
				return string.format("%d", value)
			else
				-- TODO: can output hex doubles for better accuracy.
				return string.format("%.4f", value)
			end
		end,
	string =
		function ( value )
			return string.format("%q", value)
		end
}

-- TODO: maybe move to its own file.
-- - Can handle tables of booleans, strings and numbers
-- - Cannot handle self reference in tables but will detect when this happens.
function table.compile( tbl, option )
	local parts = { 'return ' }
	local pads = {}
	local function pad( indent )
		local result = pads[indent]
		if not result then
			result = string.rep(' ', indent)
			-- result = string.rep(' ', indent*2)
			-- result = string.rep('\t', indent)
			pads[indent] = result
		end
		return result
	end

	local next = next
	local type = type
	local _literals = _literals

	local function aux( tbl, indent, context )
		if next(tbl) == nil then
			parts[#parts+1] = '{}'
			return
		end

		if context[tbl] then
			error('loop detected in table.compile')
		end

		context[tbl] = true

		parts[#parts+1] = '{\n'

		local padding = pad(indent+1)

		local size = #tbl

		-- First off let's do the array part.
		for index = 1, size do
			local v = tbl[index]

			parts[#parts+1] = padding

			local vt = type(v)

			if vt ~= 'table' then
				parts[#parts+1] = _literals[vt](v)
			else
				aux(v, indent+1, context)
			end

			parts[#parts+1] = ',\n'
		end

		-- Now non-array parts. This uses secret knowledge of how lua works, the
		-- next() function will iterate over array parts first so we can skip them.
		local k = next(tbl, (size ~= 0) and size or nil)

		while k ~= nil do
			parts[#parts+1] = padding
			parts[#parts+1] = '['

			local kt = type(k)

			if kt ~= 'table' then
				parts[#parts+1] = _literals[kt](k)
			else
				aux(k, indent+1, context)
			end

			parts[#parts+1] = '] = '

			local v = tbl[k]
			local vt = type(v)

			if vt ~= 'table' then
				parts[#parts+1] = _literals[vt](v)
			else
				aux(v, indent+1, context)
			end

			parts[#parts+1] = ',\n'

			k = next(tbl, k)
		end

		-- Closing braces are dedented.
		indent = indent
		padding = pad(indent)
		parts[#parts+1] = padding
		parts[#parts+1] = '}'

		context[tbl] = nil
	end

	aux(tbl, 0, {})

	-- This is to stop complaints about files not ending in a newline.
	parts[#parts+1] = '\n'

	local result = table.concat(parts)

	return result
end

if false then
    printf = function ( ... ) print(string.format(...)) end

	print(table.compile {{{}}})
	print(table.compile {1,2,3,{4}})
	print(table.compile {a={b={c={}}}})
	print(table.compile {[{}]={},[{}]={}})

	-- This should not trigger the loop detection code.
	local status, result = pcall(function()
		local t = {}
		print(table.compile { t, t })
	end)
	assert(status == true)

	-- This should fire off the loop detection code.
	local status, result = pcall(function()
		local t = {}
		t.t = t
		print(table.compile(t))
	end)
	assert(status == false and result:find('loop detected'))
end
