local craft = require('craft')

function main()
    local src0 = craft.getItemName(1)
    local src1 = craft.getItemName(2)
    craft.scanItemsOnSides()
    while true do
        craft.mergeItems()
        if not craft.crafting1(src0) then
            break
        end

        while true do
            craft.mergeItems()
            if not craft.crafting9(src1) then
                break
            end
        end
    end
end

main()
