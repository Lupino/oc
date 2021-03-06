local robot = require('robot')
local component = require('component')
local sides = require('sides')

local maxSlot = robot.inventorySize()

local craftTable = {1, 2, 3, 5, 6, 7, 9, 10, 11}
local valid_sides = {sides.bottom, sides.top, sides.front}

-- local innerItems = {}
local sideItems = {}
local sideEmptySlots = {}

local useSideItems = false

local ic = nil
if component.isAvailable("inventory_controller") then
    ic = component.inventory_controller
end

local craft = {}

function normal(label)
    local idx = string.find(label, 'Planks')
    if idx then
        label = 'Planks'
    end
    local idx = string.find(label, 'Wood')
    if idx then
        label = 'Wood'
    end
    return label
end

function getLabel(item)
    if item then
        local label = item.label
        if label == 'Clay' then
            label = item.name
        end
        return normal(label)
    else
        return ''
    end
end

function getItemName(slot)
    if ic then
        return getLabel(ic.getStackInInternalSlot(slot))
    end
    return ''
end

function isItem(slot, name)
    return getItemName(slot) == normal(name)
end

function getSideItemName(side, slot)
    print('getSideItemName', side, slot)
    if ic then
        return getLabel(ic.getStackInSlot(side, slot))
    end
    return ''
end

function isSideItem(side, slot, name)
    return getSideItemName(side, slot) == normal(name)
end

function findSideItem(side, itemName)
    print('findSideItem', side, itemName)
    if ic then
        local max = ic.getInventorySize(side)
        if max then
            for slot = 1, max, 1 do
                if isSideItem(side, slot, itemName) then
                    return slot
                end
            end
        end
    end
    return 0
end

function findItemOnSides(itemName)
    for k, side in pairs(valid_sides) do
        if useSideItems then
            local slot = popSideItems(side, itemName)
            if slot then
                if isSideItem(side, slot, itemName) then
                    return suckFromSlot(side, slot)
                end
            end
        else
            local slot = findSideItem(side, itemName)
            if slot > 0 then
                return suckFromSlot(side, slot)
            end
        end
    end
    return 0
end

function suckFromSlot(side, slot)
    if ic then
        local newSlot = findEmptySlot()
        if newSlot == 0 then
            newSlot = cleanASlot()
        end

        if newSlot > 0 then
            robot.select(newSlot)
            ic.suckFromSlot(side, slot)
            if isEmptySideSlot(side, slot) then
                insertSideEmptySlots(side, slot)
            else
                local name = getSideItemName(side, slot)
                insertSideItems(side, slot, name)
            end
            return newSlot
        end
    end
    return 0
end


function dropIntoSlot(slot)
    print('dropIntoSlot', slot)
    if ic then
        robot.select(slot)
        local name = getItemName(slot)
        local side, newSlot = findEmptySlotOnSides()
        if newSlot > 0 then
            ic.dropIntoSlot(side, newSlot)
            insertSideItems(side, newSlot, name)
            return true
        end
    end
    return false
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
    print('findEmptySlot')
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

function findEmptySideSlot(side)
    print('findEmptySideSlot', side)
    if ic then
        local max = ic.getInventorySize(side)
        if max then
            for slot = 1, max, 1 do
                if isEmptySideSlot(side, slot) then
                    return slot
                end
            end
        end
    end
    return 0
end

function isEmptySideSlot(side, slot)
    if ic then
        return ic.getSlotStackSize(side, slot) == 0
    end
    return false
end

function isFullSideSlot(side, slot)
    if ic then
        return ic.getSlotStackSize(side, slot) == 64
    end
    return false
end

function findEmptySlotOnSides()
    for k, side in pairs(valid_sides) do
        if useSideItems then
            local slot = popSideEmptySlot(side)
            if slot then
                if isEmptySideSlot(side, slot) then
                    return side, slot
                end
            end
        else
            local slot = findEmptySideSlot(side)
            if slot > 0 then
                return side, slot
            end
        end
    end
    return 0, 0
end

function cleanASlot()
    print('cleanASlot')
    for slot = 12, maxSlot, 1 do
        if isFullSlot(slot) then
            if dropIntoSlot(slot) then
                return slot
            end
            break
        end
    end
    return 0
end

function cleanAll()
    print('cleanAll')
    mergeItems()
    for slot = 1, maxSlot, 1 do
        if not isEmptySlot(slot) then
            if not dropIntoSlot(slot) then
                break
            end
        end
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
    print('transferTo', from, to, ...)
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
        emptySlot = cleanASlot()
        if emptySlot == 0 then
            return false
        end
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
        slot = findItemOnSides(name)
        if slot == 0 then
            return false
        end
    end

    transferTo(slot, 6)

    local emptySlot = findEmptySlot()
    if emptySlot == 0 then
        emptySlot = cleanASlot()
        if emptySlot == 0 then
            return false
        end
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
    local total = 0

    while true do
        slot = findItem(name, slot + 1)
        if slot == 0 then
            break
        end
        count = robot.count(slot)
        total = total + count
        if count >= 9 then
            break
        end
    end

    if slot == 0 then
        while true do
            slot = findItemOnSides(name)
            if slot == 0 then
                if total >= 9 then
                    mergeItems()
                    return crafting9(name)
                else
                    return false
                end
            end
            count = robot.count(slot)
            total = total + count
            if count >= 9 then
                break
            end
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
        emptySlot = cleanASlot()
        if emptySlot == 0 then
            return false
        end
    end
    robot.select(emptySlot)
    component.crafting.craft(count)
    return true
end

function crafting(items, ...)
    print('crafting')
    if #items ~= 9 then
        print('crafting failed', #items)
        return false, '', 0
    end

    if not makeCraft() then
        return false, '', 0
    end

    local args = {...}
    local requiredCount = 1
    if #args > 0 then
        requiredCount = args[1]
    end
    local itemSlots = {}
    local slot
    for slot = 1, 9, 1 do
        if itemSlots[items[slot]] then
            table.insert(itemSlots[items[slot]], slot)
        else
            if items[slot] ~= '' then
                itemSlots[items[slot]] = {slot}
            end
        end
    end

    local name
    local ss
    local s
    local slot = 0
    local count = 0
    local total = 0
    local minCount = 64
    for name, ss in pairs(itemSlots) do
        slot = 0
        total = 0
        while true do
            slot = findItem(name, slot + 1)
            if slot == 0 then
                break
            end
            count = robot.count(slot)
            total = total + count
            if count >= #ss then
                break
            end
        end

        if slot == 0 then
            while true do
                slot = findItemOnSides(name)
                if slot == 0 then
                    if total >= #ss then
                        break
                        -- mergeItems()
                        -- return crafting(items, ...)
                    else
                        return false, name, (#ss - total) * requiredCount
                    end
                end
                count = robot.count(slot)
                total = total + count
                if count >= #ss then
                    break
                end
            end
        end

        if count < #ss then
            if total >= #ss then
                count = math.floor(total / #ss)
                for s = 1, #ss, 1 do
                    if isItem(4, name) then
                        slot = 4
                    elseif isItem(8, name) then
                        slot = 8
                    elseif isItem(12, name) then
                        slot = 12
                    else
                        slot = findItem(name, 12)
                    end
                    transferTo(slot, craftTable[ss[s]], count)
                end
            else
                return false, name, (#ss - total) * requiredCount
            end
        else
            count = math.floor(count / #ss)

            for s = 1, #ss, 1 do
                transferTo(slot, craftTable[ss[s]], count)
            end
        end

        if minCount > count then
            minCount = count
        end
    end

    local emptySlot = findEmptySlot()
    if emptySlot == 0 then
        emptySlot = cleanASlot()
        if emptySlot == 0 then
            return false, '', 0
        end
    end

    robot.select(emptySlot)

    if #args > 0 then
        minCount = args[1]
    end
    component.crafting.craft(minCount)
    return true, '', 0
end

-- function scanInnerItems()
--     for slot = 1, maxSlot, 1 do
--         if not isEmptySlot(slot) then
--             local name = getItemName(slot)
--             if innerItems[name] then
--                 table.insert(innerItems[name], slot)
--             else
--                 innerItems[name] = {slot}
--             end
--         end
--     end
-- end

function insertSideItems(side, slot, name)
    print('insertSideItems', side, slot, name)
    if sideItems[side] then
        if sideItems[side][name] then
            table.insert(sideItems[side][name], slot)
        else
            sideItems[side][name] = {slot}
        end
    end
end

function insertSideEmptySlots(side, slot)
    print('insertSideEmptySlots', side, slot)
    if sideEmptySlots[side] then
        table.insert(sideEmptySlots[side], slot)
    end
end

function popSideItems(side, name)
    print('popSideItems', side, name)
    if sideItems[side] then
        if sideItems[side][name] then
            return table.remove(sideItems[side][name])
        end
    end
    return nil
end

function popSideEmptySlot(side)
    print('popSideEmptySlot')
    if (sideEmptySlots[side]) then
        return table.remove(sideEmptySlots[side])
    end
    return nil
end

function scanSideItems(side)
    sideItems[side] = {}
    sideEmptySlots[side] = {}
    if ic then
        local max = ic.getInventorySize(side)
        if max then
            for slot = 1, max, 1 do
                if isEmptySideSlot(side, slot) then
                    insertSideEmptySlots(side, slot)
                else
                    local name = getSideItemName(side, slot)
                    insertSideItems(side, slot, name)
                end
            end
        end
    end
end

function scanItemsOnSides()
    for k, side in pairs(valid_sides) do
        scanSideItems(side)
    end
    useSideItems = true
end

function countItems(name)
    local slot
    local total = 0
    for slot = 1, maxSlot, 1 do
        if isItem(slot, name) then
            total = total + robot.count(slot)
        end
    end
    if useSideItems then
        for side, item in pairs(sideItems) do
            if item[name] then
                local ss = item[name]
                for k = 1, #ss, 1 do
                    total = total + ic.getSlotStackSize(side, ss[k])
                end
            end
        end
    else
        for k, side in pairs(valid_sides) do
            if ic then
                local max = ic.getInventorySize(side)
                if max then
                    for slot = 1, max, 1 do
                        if isSideItem(side, slot, name) then
                            total = total + ic.getSlotStackSize(side, slot)
                        end
                    end
                end
            end
        end
    end
    return total
end

craft.getItemName = getItemName
craft.findItem = findItem
craft.findItemOnSides = findItemOnSides
craft.isItem = isItem
craft.mergeItems = mergeItems
craft.cleanAll = cleanAll
craft.crafting1 = crafting1
craft.crafting9 = crafting9
craft.crafting = crafting
craft.scanItemsOnSides = scanItemsOnSides
craft.countItems = countItems

return craft
