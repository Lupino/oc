local craft = require('craft')

function main()
    local running = true
    local src0 = getItemName(1)
    local src1 = getItemName(2)
    craft.scanItemsOnSides()
    while running do
        mergeItems()
        if not craft.crafting1(src0) then
            break
        end

        while running do
            mergeItems()
            if not craft.crafting9(src1) then
                break
            end
        end
    end
end

main()
