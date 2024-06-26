-- nbt2table.lua

local nbtReader = {}  -- Define a table to hold our module functions
local m = {}
DEBUG = false
TAG_END = 0
TAG_BYTE = 1
TAG_SHORT = 2
TAG_INT = 3
TAG_LONG = 4
TAG_FLOAT = 5
TAG_DOUBLE = 6
TAG_BYTE_ARRAY = 7
TAG_STRING = 8
TAG_LIST = 9
TAG_COMPOUND = 10
TAG_INT_ARRAY = 11
TAG_LONG_ARRAY = 12

local logger
local function log(message)
	if DEBUG then
		if logger == nil then
			if fs.exists(shell.resolve "log") then
				logger = assert(io.open(shell.resolve "log", "a"))
			else
				logger = assert(io.open(shell.resolve "log", "w+"))
			end
		end
		logger:write(message .."\n")
		logger:flush()
	end
end
function m.parseEnd(buffer, context)
	log("parsing end")
	return nil
end

function m.parseByte(buffer, context)
	log("parsing byte")
	return {tagType = TAG_BYTE, name = nil, content = string.unpack(">b", buffer:read(1))}
end

function m.parseShort(buffer, context)
    local value = string.unpack(">h", buffer:read(2))
    log("parsing short ".. value)
    return {tagType = TAG_SHORT, name = nil, content = value}
end

function m.parseInt(buffer, context)
    local value = string.unpack(">i", buffer:read(4))
    log("parsing int ".. value)
    return {tagType = TAG_INT, name = nil, content = value}
end

function m.parseLong(buffer, context)
    local value = string.unpack(">l", buffer:read(8))
    log("parsing long ".. value)
    return {tagType = TAG_LONG, name = nil, content = value}
end

function m.parseFloat(buffer, context)
    local value = string.unpack(">f", buffer:read(4))
    log("parsing float ".. value)
    return {tagType = TAG_FLOAT, name = nil, content = value}
end

function m.parseDouble(buffer, context)
    local value = string.unpack(">d", buffer:read(8))
    log("parsed Double ".. value)
    return {tagType = TAG_DOUBLE, name = nil, content = value}
end

function m.parseByteArray(buffer, context)
    local length = string.unpack(">i", buffer:read(4))
    local content = buffer:read(length)
    log("parsing ByteArray \""..content.."\"")
    return {tagType = TAG_BYTE_ARRAY, name = nil, content = content}
end

function m.parseString(buffer, context)
    local length = string.unpack(">H", buffer:read(2))
    log("length : ".. length)
    local value = buffer:read(length)
    log("parsing String \""..value.."\"")
    return {tagType = TAG_STRING, name = nil, content = value}
end

function m.parseList(buffer, context)
    local innerTagType = string.byte(buffer:read(1))
    local length = string.unpack(">i", buffer:read(4))
    local list = {}
    for i = 1, length do
        table.insert(list, tagTable[innerTagType](buffer, TAG_LIST))  -- Recursively parse inner tags
    end
    log("parsing List "..textutils.serialise(list))
    return {tagType = TAG_LIST, name = nil, content = list, innerTagType = innerTagType}
end

function m.parseCompound(buffer, context)
    local name
    if context ~= TAG_LIST then
        name = m.parseString(buffer).content
    end
    local compound = {}
    -- parse name of compound
    while true do
        local tagType = string.byte(buffer:read(1))
        log("type = ".. tagType)
        if tagType == TAG_END then
            break
        end

        if tagTable[tagType] == nil then
            error("Unrecognised tag type ".. tagType)
        end
        local name = m.parseString(buffer).content  -- Read tag name
        local tag = tagTable[tagType](buffer, context) -- Recursively parse inner tags
		tag.name = name
        compound[name] = tag
    end
    log("parsing Compound ".. textutils.serialise(compound))
    return {tagType = TAG_COMPOUND, name = name, content = compound}
end

function m.parseIntList(buffer, context)
    log("parsing IntList")
    local length = string.unpack(">i", buffer:read(4))
    local array = {}
    for i = 1, length do
        table.insert(array, string.unpack(">i", buffer:read(4)))
    end
    return {tagType = TAG_INT_ARRAY, name = nil, content = array}
end

function m.parseLongList(buffer, context)
    log("parsing LongList")
    local length = string.unpack(">i", buffer:read(4))
    local array = {}
    for i = 1, length do
        table.insert(array, string.unpack(">l", buffer:read(8)))
    end
    return {tagType = TAG_LONG_ARRAY, name = nil, content = array}
end
function m.parseNBT(buffer, context)
	local tagType = buffer:read(1)  -- Read tag type byte
	
	if not tagType then
		error("Unexpected end of file")
	end
	
	local tagID = string.byte(tagType)  -- Convert tag type byte to numeric ID
	
	log("tagid :" .. tagID)
	
    if tagTable[tagID] == nil then
        error("Unsupported tag type: " .. tagID)
	else
		return tagTable[tagID](buffer, context)
	end

end

-- Function to read an NBT file and convert it to a Lua table
function nbtReader.read(buffer)
    if io.type(buffer) ~= "file" then
        error("expected a valid file")
    end
    local success, result = pcall(m.parseNBT, buffer)  -- Call the parseNBT function in protected mode
    if not success then
        error("Failed to parse NBT data: " .. textutils.serialise(result))  -- Propagate any parsing errors
    end
    return result  -- Return the parsed Lua table
end


tagTable = {
	[TAG_END] = m.parseByte,
	[TAG_BYTE] = m.parseByte,
	[TAG_SHORT] = m.parseShort,
	[TAG_INT] = m.parseInt,
	[TAG_LONG] = m.parseLong,
	[TAG_FLOAT] = m.parseFloat,
	[TAG_DOUBLE] = m.parseDouble,
	[TAG_BYTE_ARRAY] = m.parseByteArray,
	[TAG_STRING] = m.parseString,
	[TAG_LIST] = m.parseList,
	[TAG_COMPOUND] = m.parseCompound,
	[TAG_INT_ARRAY] = m.parseIntList,
	[TAG_LONG_ARRAY] = m.parseLongList,
}

return nbtReader
