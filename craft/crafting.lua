local craft = require('craft')
local craftTables = require('craftTables')
local component = require('component')
local args = {...}
local os = require('os')

local needItems = {}

local dbs
function refreshDbs()
  dbs = {}
  local i = 0
  for addr, dummy in component.list("database") do
    i = i + 1
    local temp = component.proxy(addr)
    local x1 = pcall(function() temp.get(10) end)
    local x2 = pcall(function() temp.get(26) end)
    local dbsize = 9
    if (x1 and x2) then
      dbsize = 81
    elseif x1 then
      dbsize = 25
    end
    dbs[i] = {db=temp, size=dbsize}
  end
end

function getDbItemName(db, slot)
    local item = db.get(slot)
    if item then
        return item.label
    else
        return ''
    end
end

function makeNeedItems(db)
    for slot = 1, 9, 1 do
        local name = getDbItemName(db, slot)
        if name ~= '' then
            table.insert(needItems, name)
        end
    end
end

function makeCraftTable(db, offset)
    local target = getDbItemName(db, 10 + offset)

    if target == '' then
        return
    end

    local craftTable = {}
    local slot
    for slot = 1, 9, 1 do
        craftTable[slot] = getDbItemName(db, slot + offset)
    end
    craftTables[target] = craftTable
end

function makeCraftTable1(db, offset)
    local target = getDbItemName(db, 13 + offset)

    if target == '' then
        return
    end

    local slots = {1, 2, 3, 10, 11, 12, 19, 20, 21}
    local craftTable = {}
    local slot
    local s
    for s = 1, 9, 1 do
        slot = slots[s]
        craftTable[s] = getDbItemName(db, slot + offset)
    end
    craftTables[target] = craftTable
end

function makeCraftTable2(db, offset)
    local target = getDbItemName(db, 17 + offset)

    if target == '' then
        return
    end

    local slots = {5, 6, 7, 14, 15, 16, 23, 24, 25}
    local craftTable = {}
    local slot
    local s
    for s = 1, 9, 1 do
        slot = slots[s]
        craftTable[s] = getDbItemName(db, slot + offset)
    end
    craftTables[target] = craftTable
end

refreshDbs()

for i = 1, #dbs, 1 do
    local db = dbs[i]
    if db.size == 25 then
        makeCraftTable(db.db, 0)
        makeCraftTable(db.db, 10)
    elseif db.size == 81 then
        makeCraftTable1(db.db, 0)
        makeCraftTable2(db.db, 0)
        makeCraftTable1(db.db, 27)
        makeCraftTable2(db.db, 27)
        makeCraftTable1(db.db, 54)
        makeCraftTable2(db.db, 54)
    elseif db.size == 9 then
        makeNeedItems(db.db)
    end
end

function run_craft(name, count)
    if count > 64 then
        count = 64
    end

    print('run_craft', name, count)
    if not craftTables[name] then
        print('not fount craftable:', name)
        return false
    end

    craft.mergeItems()
    local ret, needName, needCount = craft.crafting(craftTables[name], count)
    if ret then
        return true
    end

    if needName ~= '' then
        ret = run_craft(needName, needCount)
        if ret then
            return run_craft(name, count)
        end
    end
    return false
end

function main()
    local target
    local count = 1
    if #args == 2 then
        target = args[1]
        count = tonumber(args[2])
    elseif #args == 1 then
        target = craft.getItemName(1)
        count = tonumber(args[1])
    else
        target = craft.getItemName(1)
    end

    if target == '' then
        if #needItems == 0 then
            return
        end
    end

    craft.cleanAll()

    craft.scanItemsOnSides()

    if #needItems > 0 then
        for i=1,#needItems,1 do
            craft_main(needItems[i], count)
        end
    else
        craft_main(target, count)
    end
end

function craft_main(target, count)
    local size = 64
    local running = true
    local total = craft.countItems(target)

    count = count + total

    while true do
        size = count - total
        if size > 64 then
            size = 64
        end

        while true do
            running = run_craft(target, size)
            if not running then
                craft.cleanAll()
                running = run_craft(target, size)
                if not running then
                    print('need resources')
                    print('wait 10s')
                    os.sleep(10)
                end
            else
                break
            end
        end

        total = craft.countItems(target)

        if total >= count then
            break
        end
    end
end

main()
