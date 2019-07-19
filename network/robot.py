import requests

uuid = 'you-robot-uuid'
def request(data):
    rsp = requests.post('http://example.com/api/request/{}/'.format(uuid), data=data)

    print(rsp.text)

def get_uptime():
    return request('''
local computer = require('computer')
local serialization = require('serialization')
return serialization.serialize(computer.uptime())
''')

def up():
    request('''
local robot = require('robot')
robot.up()
return 'true'
''')

def down():
    request('''
local robot = require('robot')
robot.down()
return 'true'
''')

def forward():
    request('''
local robot = require('robot')
robot.forward()
return 'true'
''')

def back():
    request('''
local robot = require('robot')
robot.back()
return 'true'
''')

def force_up():
    request('''
local robot = require('robot')
function up()
    local can, type = robot.detectUp()
    if can then
        robot.swingUp()
        up()
    else
        robot.up()
    end
end
up()
return 'true'
''')

def force_down():
    request('''
local robot = require('robot')
function down()
    local can, type = robot.detectDown()
    if can then
        robot.swingDown()
        down()
    else
        robot.down()
    end
end
down()
return 'true'
''')

def force_forward():
    request('''
local robot = require('robot')
function forward()
    local can, type = robot.detect()
    if can then
        robot.swing()
        forward()
    else
        robot.forward()
    end
end
forward()
return 'true'
''')

def turn_left():
    return request('''
local robot = require('robot')
robot.turnLeft()
return 'true'
''')


def turn_right():
    request('''
local robot = require('robot')
robot.turnRight()
return 'true'
''')

def use_down():
    request('''
local robot = require('robot')
robot.useDown()
return 'true'
''')

def place_down():
    place('placeDown')

def place_up():
    place('placeUp')

def place(func='place'):
    request('''
local robot = require("robot")
local component = require("component")

local currentSlot = 1
local maxSlot = robot.inventorySize()

local enableIC = component.isAvailable("inventory_controller")

local itemName = ''
local ignorePlace = false

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

function findItem()
    for s = 1, maxSlot, 1 do
        if getItemName(s) ~= '' then
            return s
        end
    end
    return 0
end

function checkSlot()
    local newItemName = getItemName(currentSlot)
    if newItemName ~= '' then
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
        if checkSlot() then
            robot.placeDown()
        end
    end
end

function placeUp()
    local can, type = robot.detectUp()
    if can then
        robot.swingUp()
        placeUp()
    else
        if checkSlot() then
            robot.placeUp()
        end
    end
end

function place()
    local can, type = robot.detect()
    if can then
        robot.swing()
        place()
    else
        if checkSlot() then
            robot.place()
        end
    end
end
{}()
return '{}'
'''.format(func, func))

def upload(data, filename='test.lua'):
    data = ['file:write("{}\\n")'.format(line.replace('"', '\\"')) for line in data.split('\n')]
    request('''
local io = require('io')
file = io.open('{}', 'w')
{}
file:close()
return 'true'
'''.format(filename, '\n'.join(data)))

def make_craft_table():
    request('''
local component = require('component')
local dbs
local output = ''
function refreshDbs()
  dbs = {}
  local i = 0
  for addr, dummy in component.list("database") do
    i = i + 1
    local temp = component.proxy(addr)
    local x1 = pcall(function() temp.get(10) end)
    local x2 = pcall(function() temp.get(26) end)
    local dbsize = 9
    if (x1 and x2) then
      dbsize = 81
    elseif x1 then
      dbsize = 25
    end
    dbs[i] = {db=temp, size=dbsize}
  end
end

function getDbItemName(db, slot)
    local item = db.get(slot)
    if item then
        return item.label
    else
        return ''
    end
end

function makeCraftTable(db, offset)
    local target = getDbItemName(db, 10 + offset)

    if target == '' then
        return
    end

    local craftTable = {}
    local slot
    for slot = 1, 9, 1 do
        craftTable[slot] = getDbItemName(db, slot + offset)
    end
    output = output .. 'craftTables["' .. target .. '"] = {"' .. table.concat(craftTable, '", "') .. '"}\\n'
end

refreshDbs()

for i = 1, #dbs, 1 do
    local db = dbs[i]
    if db.size == 25 then
        makeCraftTable(db.db, 0)
        makeCraftTable(db.db, 10)
    end
end
return output
''')
