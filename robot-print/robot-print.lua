local robot = require("robot")
local shell = require("shell")
local args, opts = shell.parse(...)
local component = require("component")

local slot = 1
local maxSlot = robot.inventorySize()

local itemName = ''

function getItemName(slot)
    local item = component.inventory_controller.getStackInInternalSlot(slot)
    if item then
        return item.name
    else
        return ''
    end
end

function up()
    local can, type = robot.detectUp()
    if can then
        robot.swingUp()
        up()
    else
        robot.up()
    end
end

function down()
    local can, type = robot.detectDown()
    if can then
        robot.swingDown()
        down()
    else
        robot.down()
    end
end

function forward()
    local can, type = robot.detect()
    if can then
        robot.swing()
        forward()
    else
        robot.forward()
    end
end

function findItem()
    for s = 1, maxSlot, 1 do
        if getItemName(s) == itemName then
            return s
        end
    end
    return 0
end

function checkSlot()
    local newItemName = getItemName(slot)
    if newItemName == itemName then
        robot.select(slot)
    else
        slot = findItem()
        if slot == 0 then
            return
        end
        checkSlot()
    end
end

function placeDown()
    local can, type = robot.detectDown()
    if (can) then
        robot.swingDown()
        placeDown()
    else
        checkSlot()
        robot.placeDown()
    end
end

function runLine(line)
    local len = string.len(line)
    for i = 1, len, 1 do
        local byte = string.byte(line, i)
        if byte == 76 then -- L
            robot.turnLeft()
        elseif byte == 82 then -- R
            robot.turnRight()
        elseif byte == 70 then -- F
            forward()
        elseif byte == 80 then -- P
            if not opts.noplace then
                placeDown()
            end
        elseif byte == 85 then -- U
            up()
        elseif byte == 68 then -- D
            down()
        end
    end
end

function main()
    local file = io.open(args[1])
    itemName = getItemName(1)
    for line in file:lines() do
        runLine(line)
    end
    file:close()
end

main()
