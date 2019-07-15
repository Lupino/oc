local craft = require('craft')
local craftTables = require('craftTables')
local shell = require('shell')
local args, opts = shell.parse(...)

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
    local total = 1
    local size = 64
    local running = true
    if #args == 2 then
        target = args[1]
        count = tonumber(args[2])
        total = 0
    elseif #args == 1 then
        target = craft.getItemName(1)
        count = tonumber(args[1])
    else
        target = craft.getItemName(1)
    end

    craft.cleanAll()

    count = count + total

    craft.scanItemsOnSides()

    while running do
        size = count - total
        if (count - total) > 64 then
            size = 64
        end

        running = run_craft(target, size)
        if not running then
            craft.cleanAll()
            running = run_craft(target, size)
        end

        total = craft.countItems(target)

        if total >= count then
            break
        end
    end
end

main()
