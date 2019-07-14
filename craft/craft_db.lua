local craft = require('craft')
local component = require("component")
local db = component.database

function main()
    local items = {}
    local slot
    for slot = 1, 9, 1 do
        items[slot] = db.get(slot).name
    end
    craft.scanItemsOnSides()
    local ret
    local name
    while true do
        craft.mergeItems()

        ret, name = craft.crafting_db(items)
        if not ret then
            if name ~= '' then
                print('lack item:', name)
            end
        end
    end
end

main()
