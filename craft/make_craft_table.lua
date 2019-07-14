local component = require("component")
local db = component.database

function getDbItemName(slot)
    local item = db.get(slot)
    if item then
        return item.name
    else
        return ''
    end
end

function makeCraftTable(offset)
    local target = getDbItemName(10 + offset)

    local craftTable = {}
    local slot
    for slot = 1, 9, 1 do
        craftTable[slot] = getDbItemName(slot + offset)
    end
    print('craftTables["' .. target .. '"] = {"' .. table.concat(craftTable, '", "') .. '"}')
end

function main()
    makeCraftTable(0)
    makeCraftTable(10)
end

main()
