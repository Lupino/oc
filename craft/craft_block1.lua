local craft = require('craft')

function main()
    local running = true
    local src0 = getItemName(1)
    local src1 = getItemName(2)
    local src2 = getItemName(3)
    while running do
        mergeItems()
        if not craft.crafting1(src0) then
            break
        end
        while running do
            mergeItems()
            if not craft.crafting1(src1) then
                break
            end

            while running do
                mergeItems()
                if not craft.crafting9(src2) then
                    break
                end
            end
        end
    end
end

main()
