local craft = require('craft')
local craftTables = require('craftTables')
local args, opts = shell.parse(...)

function run_craft(name, count)
    print('run_craft', name, count)
    if not craftTables[name] then
        print('not fount craftable:', name)
        return false
    end
    local ret, needName, needCount = craft.crafting(craftTables[name], count)
    if ret then
        return true
    end

    if needName ~= '' then
        ret = run_craft(needName, needCount)
        if ret then
            return run_craft(name, count)
        else
            craft.cleanAll()
            ret = run_craft(needName, needCount)
            if ret then
                return run_craft(name, count)
            end
        end
    end
    return false
end

function main()
    craft.scanItemsOnSides()
    local target
    local count = 1
    local k
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

    while running do
        if count > 64 then
            running = run_craft(target, 64)
            count = count - 64
        else
            run_craft(target, count)
            break
        end
    end
end

main()
