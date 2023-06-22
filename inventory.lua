Item = require "lib.item"

local chest_names = {}
local buffer_chest = "minecraft:chest_11"
for i, name in ipairs(peripheral.getNames()) do
    if peripheral.hasType(name, "inventory") and name ~= buffer_chest then
        table.insert(chest_names, name)
    end
end
local inventory = {}


local function scan_chests()
    local items = {}
    for i, name in ipairs(chest_names) do
        local chest = peripheral.wrap(name)
        print(peripheral.getName(chest))
        for slot, item in pairs(chest.list()) do
        
            local itemDetail = chest.getItemDetail(slot)
            itemDetail.count = nil
            local itemstr = textutils.serialise(itemDetail)
            if not items[itemstr] then
                items[itemstr] = item.count
            else
                items[itemstr] =  items[itemstr] + item.count
            end
    

        end
    end
    return items
end
inventory = scan_chests()
Monitor = peripheral.find("monitor")


local function storeBuffer()
    local chest = peripheral.wrap(buffer_chest)
    for slot,itemDetail in pairs(chest.list()) do
        local count = itemDetail.count
        for _, name  in pairs(chest_names) do
            if count <= 0 then
                break
            end
            local pushedcount = 1
            while pushedcount ~= 0 do
                pushedcount = chest.pushItems(name, slot)
                count = count - pushedcount
            end
        end
    end
end

local function invShell()
    while true do
        io.write("inv>>")
        local command = read()
        if command == "store" then
            storeBuffer()
        end
        if command == "exit" then
            break
        end
    end        
end

invShell()

