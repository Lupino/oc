local robot = require("robot")
local shell = require("shell")
local args = shell.parse(...)
local slot = 1
local maxSlot = 64

function up()
    local can, type = robot.detectUp()
    if (can)
    then
        robot.swingUp()
    end
    robot.up()
end

function forward()
    local can, type = robot.detect()
    if (can)
    then
        robot.swing()
    end
    robot.forward()
end

function checkSlot()
    local count = robot.count(slot)
    if (count == 0) then
        slot = slot + 1
        if (slot > maxSlot) then
			slot = 1
		end
        checkSlot()
    end
    robot.select(slot)
end

function placeDown()
    local can, type = robot.detectDown()
    if (can)
    then
        robot.swingDown()
    end
    checkSlot()
    robot.placeDown()
end

function runLine(line)
    local len = string.len(line)
    for i = 1, len, 1 do
        local byte = string.byte(line, i)
        if (byte == 76) then -- L
            robot.turnLeft()
        elseif (byte == 82) then -- R
            robot.turnRight()
        elseif (byte == 70) then -- F
            forward()
        elseif (byte == 80) then -- P
            placeDown()
        elseif (byte == 85) then -- U
            up()
        end
    end
end

function main()
    local file = io.open(args[1])
    for line in file:lines() do
        runLine(line)
    end
    file:close()
end

main()
