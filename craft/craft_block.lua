local robot = require('robot')
local component = require('component')

local maxSlot = robot.inventorySize()

function getItemName(slot)
    local item = component.inventory_controller.getStackInInternalSlot(slot)
    if item then
        return item.name
    else
        return ''
    end
end

local src0 = getItemName(1)
local src1 = getItemName(2)

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
    for f = 1, maxSlot - 1, 1 do
        if hasItemAndNotFullSlot(f) then
            local name = getItemName(f)
            for t = f + 1, maxSlot, 1 do
                if hasItemAndNotFullSlot(t) then
                    if isItem(t, name) then
                        transferTo(f, t)
                    end
                end
                if isEmptySlot(f) then
                    break
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
    if not cleanSlot(1) then
        return false
    end
    if not cleanSlot(2) then
        return false
    end
    if not cleanSlot(3) then
        return false
    end
    if not cleanSlot(5) then
        return false
    end
    if not cleanSlot(6) then
        return false
    end
    if not cleanSlot(7) then
        return false
    end
    if not cleanSlot(9) then
        return false
    end
    if not cleanSlot(10) then
        return false
    end
    if not cleanSlot(11) then
        return false
    end
    return true
end

function crafting1(name)
    print('crafting1', name)
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

function crafting9(src1)
    print('crafting9', src1)
    if not makeCraft() then
        return false
    end
    local slot = 0
    local count = 0
    while true do
        slot = findItem(src1, slot + 1)
        if slot == 0 then
            return false
        end
        local count = robot.count(slot)
        if count >= 9 then
            break
        end
    end

    if count < 9 then
        return false
    end

    count = math.floor(count / 9)

    transferTo(slot, 1, count)
    transferTo(slot, 2, count)
    transferTo(slot, 3, count)
    transferTo(slot, 5, count)
    transferTo(slot, 6, count)
    transferTo(slot, 7, count)
    transferTo(slot, 9, count)
    transferTo(slot, 10, count)
    transferTo(slot, 11, count)

    local emptySlot = findEmptySlot()
    if emptySlot == 0 then
        return false
    end
    robot.select(emptySlot)
    component.crafting.craft(count)
    return true
end

function main()
    local running = true
    local slot = 0
    local count = 0
    while running do
        mergeItems()
        if not crafting1(src0) then
            break
        end

        while running do
            mergeItems()
            if not crafting9(src1) then
                break
            end
        end
    end
end

main()
