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
    print('isItem', slot, name)
    return getItemName(slot) == name
end

function findItem(itemName)
    print('findItem', itemName)
    for slot = 1, maxSlot, 1 do
        if getItemName(slot) == itemName then
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
    print('isEmptySlot', slot)
    local count = robot.count(slot)
    if count == 0 then
        return true
    else
        return false
    end
end

function isFullSlot(slot)
    print('isFullSlot', slot)
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
    if not makeCraft() then
        return false
    end

    local slot = findItem(name)
    if slot == 0 then
        return false
    end

    transferTo(slot, 6)

    local emptySlot = findEmptySlot()
    if emptySlot == 0 then
        return false
    end
    robot.select(emptySlot)
    component.crafting.craft(18)
    return true
end

function crafting9(name)
    if not makeCraft() then
        return false
    end

    local slot = findItem(name)
    if slot == 0 then
        return false
    end

    transferTo(slot, 1, 2)
    transferTo(slot, 2, 2)
    transferTo(slot, 3, 2)
    transferTo(slot, 5, 2)
    transferTo(slot, 6, 2)
    transferTo(slot, 7, 2)
    transferTo(slot, 9, 2)
    transferTo(slot, 10, 2)
    transferTo(slot, 11, 2)

    local emptySlot = findEmptySlot()
    if emptySlot == 0 then
        return false
    end
    robot.select(emptySlot)
    component.crafting.craft(2)
    return true
end

function main()
    local running = true
    local slot = 0
    local count = 0
    while running do
        if not crafting1(src0) then
            break
        end

        mergeItems()

        slot = findItem(src1)
        if slot > 0 then
            count = robot.count(slot)
            while count >= 18 do
                crafting9(src1)
            end
        end
    end
end

main()
