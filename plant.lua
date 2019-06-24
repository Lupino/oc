local robot = require('robot')
local component = require('component')

local dye = 'minecraft:dye'
local bone = 'minecraft:bone'
local fruitBone = 'croparia:fruit_bone'
local currentDyeSlot = 2
local currentSeedSlot = 1

local maxSlot = robot.inventorySize()

function getItemName(slot)
    local item = component.inventory_controller.getStackInInternalSlot(slot)
    if item then
        return item.name
    else
        return ''
    end
end

function isItem(slot, name)
    print('isItem', slot, name)
    return getItemName(slot) == name
end

local seed = getItemName(1)

function findItem(itemName)
    print('findItem', itemName)
    for slot = 1, maxSlot, 1 do
        if getItemName(slot) == itemName then
            return slot
        end
    end
    return 0
end

function placeItem(slot)
    print('placeItem', slot)
    local count = robot.count(slot)

    robot.select(slot)
    robot.placeDown()

    if robot.count(slot) < count then
        return true
    else
        return false
    end
end

function placeSeed()
    if isItem(currentSeedSlot, seed) then
        return placeItem(currentSeedSlot)
    end
    local slot = findItem(seed)
    if slot == 0 then
        return false
    end
    currentSeedSlot = slot
    return placeSeed()
end

function placeDye()
    if isItem(currentDyeSlot, dye) then
        if placeItem(currentDyeSlot) then
            return 1
        else
            return 0
        end
    end
    local slot = findItem(dye)
    if slot == 0 then
        return 2
    end
    currentDyeSlot = slot
    return placeDye()
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

function transferTo(from, to)
    robot.select(from)
    robot.transferTo(to)
end

function hasItemAndNotFullSlot(slot)
    if isEmptySlot(f) then
        return false
    end
    if isFullSlot(f) then
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

    transforTo(emptySlot, slot)
    return cleanSlot(slot)
end

function makeCraft()
    mergeItems()
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

function crafting(name, count)
    if not makeCraft() then
        return 2
    end

    local slot = findItem(name)
    if slot == 0 then
        return 0
    end

    transferTo(slot, 6)

    local emptySlot = findEmptySlot()
    if emptySlot == 0 then
        return 2
    end
    robot.select(emptySlot)
    component.crafting.craft(count)
    return 1
end

function runPlaceDye()
    local ret = placeDye()
    if ret == 2 then
        ret = crafting(bone, 63)
        if ret == 2 then
            return false
        elseif ret == 0 then
            ret = crafting(fruitBone, 64)
            if ret == 2 then
                return false
            elseif ret == 0 then
                return false
            end
        end
    elseif ret == 0 then
        return true
    end
    return runPlaceDye()
end

function main()
    robot.swingDown()
    local running = true
    local ret = 1
    while running do
        if not placeSeed() then
            break
        end
        if not runPlaceDye() then
            break
        end
        robot.swingDown()
    end
end

main()
