local craft = require('craft')
local craftTables = require('craftTables')
local component = require('component')
local args = {..}

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

refreshDbs()

for i = 1, #dbs, 1 do
    local db = dbs[i]
    if db.size == 25 then
        makeCraftTable(db.db, 0)
        makeCraftTable(db.db, 10)
    end
end

function run_craft(name, count)
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
    local size = 64
    local running = true
    if #args == 2 then
        target = args[1]
        count = tonumber(args[2])
    elseif #args == 1 then
        target = craft.getItemName(1)
        count = tonumber(args[1])
    else
        target = craft.getItemName(1)
    end

    craft.cleanAll()

    craft.scanItemsOnSides()

    local total = craft.countItems(target)

    count = count + total

    while running do
        size = count - total
        if size > 64 then
            size = 64
        end

        running = run_craft(target, size)
        if not running then
            craft.cleanAll()
            running = run_craft(target, size)
            if not running then
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
