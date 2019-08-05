local robot = require("robot")
local args = {...}
local component = require("component")
local os = require('os')

local side = 0
local maxSlot = robot.inventorySize()

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

function suck()
    component.tractor_beam.suck()
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
            suck()
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

function isEmptySideSlot(slot)
    return component.inventory_controller.getSlotStackSize(side, slot) == 0
end

function findEmptySideSlot()
    local max = component.inventory_controller.getInventorySize(side)
    for slot = 1, max, 1 do
        if isEmptySideSlot(slot) then
            return slot
        end
    end
    return 0
end


function dropIntoSlot(slot)
    robot.select(slot)
    local newSlot = findEmptySideSlot()
    if newSlot > 0 then
        component.inventory_controller.dropIntoSlot(side, newSlot)
        return true
    end
end

function dropItems()
    for slot = 1, maxSlot, 1 do
        if robot.count(slot) > 0 then
            dropIntoSlot(slot)
        end
    end
end

function main()
    component.chunkloader.setActive(true)
    while true do
        runPrint(args[1])
        dropItems()
        os.sleep(10)
    end
end

main()
