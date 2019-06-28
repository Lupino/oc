local robot = require("robot")
local shell = require("shell")
local args, opts = shell.parse(...)
local component = require("component")

local currentSlot = 1
local maxSlot = robot.inventorySize()

local enableIC = component.isAvailable("inventory_controller")

local itemName = ''

function getItemName(slot)
    if not enableIC then
        return ''
    end

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
    local newItemName = getItemName(currentSlot)
    if newItemName == itemName then
        robot.select(currentSlot)
        return true
    else
        currentSlot = findItem()
        if currentSlot ~= 0 then
            robot.select(currentSlot)
            return true
        end
        return false
    end
end

function placeDown()
    local can, type = robot.detectDown()
    if can then
        robot.swingDown()
        placeDown()
    else
        if not opts.noplace and itemName ~= '' then
            if checkSlot() then
                robot.placeDown()
            end
        end
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
            placeDown()
        elseif byte == 85 then -- U
            up()
        elseif byte == 68 then -- D
            down()
        end
    end
end

function runPrint(filename)
    local file = io.open(filename)
    for line in file:lines() do
        runLine(line)
    end
    file:close()
end

function main()
    if opts.dig then
        while true do
            runPrint(args[1])
            down()
        end
    else
        itemName = getItemName(1)
        runPrint(args[1])
    end
end

main()
