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
    local items = {}
    local slot
    for slot = 1, 9, 1 do
        items[slot] = getDbItemName(slot)
    end
    craft.scanItemsOnSides()
    local ret
    local name
    local needCount
    while true do
        craft.mergeItems()

        ret, name, needCount = craft.crafting(items)
        if not ret then
            if name ~= '' then
                print('lack item:', name)
            end
            break
        end
    end
end

main()
