local craft = require('craft')
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

function main()
    local item1Name = getDbItemName(10)
    local item2Name = getDbItemName(20)

    local items1 = {}
    local items2 = {}
    local slot
    for slot = 1, 9, 1 do
        items1[slot] = getDbItemName(slot)
    end
    for slot = 1, 9, 1 do
        items2[slot] = getDbItemName(slot + 10)
    end
    craft.scanItemsOnSides()
    local ret
    local name
    local running = true
    while running do
        craft.mergeItems()

        ret, name = craft.crafting_db(items1)
        if not ret then
            if name ~= '' then
                print('lack item:', name)
            end
            break
        end
        while running do
            craft.mergeItems()
            ret, name = craft.crafting_db(items2)
            if not ret then
                if name ~= '' then
                    print('lack item:', name)
                    if name ~= item1Name then
                        running = false
                    else
                        break
                    end
                else
                    running = false
                end
            end
        end
    end
end

main()
