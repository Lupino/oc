local component = require('component')
local dbs
local output = ''
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
    output = output .. 'craftTables["' .. target .. '"] = {"' .. table.concat(craftTable, '", "') .. '"}\n'
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
    output = output .. 'craftTables["' .. target .. '"] = {"' .. table.concat(craftTable, '", "') .. '"}\n'
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
    output = output .. 'craftTables["' .. target .. '"] = {"' .. table.concat(craftTable, '", "') .. '"}\n'
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
    end
end
print(output)
