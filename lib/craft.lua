local robot = require('robot')
local component = require('component')

local maxSlot = robot.inventorySize()

local craftTable = {1, 2, 3, 5, 6, 7, 9, 10, 11}
local enableIC = component.isAvailable("inventory_controller")

local craft = {}

function getItemName(slot)
    if not enableIC then
        return ''
    end

    local item = component.inventory_controller.getStackInInternalSlot(slot)
    if item then
        return item.name
    else
        return ''
    end
end

function isItem(slot, name)
    return getItemName(slot) == name
end

function findItem(itemName, slot)
    print('findItem', itemName)
    for slot = slot, maxSlot, 1 do
        if isItem(slot, itemName) then
            return slot
        end
    end
    return 0
end

function findEmptySlot()
    if isEmptySlot(4) then
        return 4
    end
    if isEmptySlot(8) then
        return 8
    end
    for slot = 12, maxSlot, 1 do
        if isEmptySlot(slot) then
            return slot
        end
    end
    return 0
end

function isEmptySlot(slot)
    local count = robot.count(slot)
    if count == 0 then
        return true
    else
        return false
    end
end

function isFullSlot(slot)
    local count = robot.count(slot)
    if count == 64 then
        return true
    else
        return false
    end
end

function transferTo(from, to, ...)
    robot.select(from)
    robot.transferTo(to, ...)
end

function hasItemAndNotFullSlot(slot)
    if isEmptySlot(slot) then
        return false
    end
    if isFullSlot(slot) then
        return false
    end
    return true
end

function mergeItems()
    local slots = {}
    for slot = 1, maxSlot, 1 do
        if hasItemAndNotFullSlot(slot) then
            local name = getItemName(slot)
            if slots[name] then
                table.insert(slots[name], slot)
            else
                slots[name] = {slot}
            end
        end
    end

    for name, ss in pairs(slots) do
        print('mergeItems:', name)
        for f = 1, #ss - 1, 1 do
            if hasItemAndNotFullSlot(ss[f]) then
                for t = f + 1, #ss, 1 do
                    if hasItemAndNotFullSlot(ss[t]) then
                        transferTo(ss[f], ss[t])
                    end
                    if isEmptySlot(ss[f]) then
                        break
                    end
                end
            end
        end
    end
end

function cleanSlot(slot)
    if isEmptySlot(slot) then
        return true
    end

    local emptySlot = findEmptySlot()

    if emptySlot == 0 then
        return false
    end

    transferTo(slot, emptySlot)
    return cleanSlot(slot)
end

function makeCraft()
    for k, slot in pairs(craftTable) do
        if not cleanSlot(slot) then
            return false
        end
    end
    return true
end

function crafting1(name)
    print('crafting1', name)
    if name == '' then
        return false
    end
    if not makeCraft() then
        return false
    end

    local slot = findItem(name, 1)
    if slot == 0 then
        return false
    end

    transferTo(slot, 6)

    local emptySlot = findEmptySlot()
    if emptySlot == 0 then
        return false
    end
    robot.select(emptySlot)
    component.crafting.craft(64)
    return true
end

function crafting9(name)
    print('crafting9', name)
    if name == '' then
        return false
    end
    if not makeCraft() then
        return false
    end
    local slot = 0
    local count = 0
    while true do
        slot = findItem(name, slot + 1)
        if slot == 0 then
            return false
        end
        count = robot.count(slot)
        if count >= 9 then
            break
        end
    end

    if count < 9 then
        return false
    end

    count = math.floor(count / 9)

    for k, t in pairs(craftTable) do
        transferTo(slot, t, count)
    end

    local emptySlot = findEmptySlot()
    if emptySlot == 0 then
        return false
    end
    robot.select(emptySlot)
    component.crafting.craft(count)
    return true
end

craft.getItemName = getItemName
craft.findItem = findItem
craft.isItem = isItem
craft.mergeItems = mergeItems
craft.crafting1 = crafting1
craft.crafting9 = crafting9

return craft
