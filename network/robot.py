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

def robot_run(func):
    request('''
local robot = require('robot')
robot.{}()
return '{}'
'''.format(func, func))

def up():
    robot_run('up')

def down():
    robot_run('down')

def forward():
    robot_run('forward')

def back():
    robot_run('back')

def robot_force_run(func):
    Func = func.capitalize()
    if func == 'forward':
        Func = ''

    request('''
local robot = require('robot')
function {func}()
    local can, type = robot.detect{Func}()
    if can then
        robot.swing{Func}()
        {func}()
    else
        robot.{func}()
    end
end
{func}()
return '{func}'
'''.format(func=func, Func=Func))

def force_up():
    robot_force_run('up')

def force_down():
    robot_force_run('down')

def force_forward():
    robot_force_run('forward')

def turn_left():
    robot_run('turnLeft')

def turn_right():
    robot_run('turnLeft')

def use_down():
    robot_run('useDown')

def use():
    robot_run('use')

def robot_place(func):
    request('''
local robot = require("robot")
local component = require("component")

local currentSlot = 1
local maxSlot = robot.inventorySize()

function findItem()
    for s = 1, maxSlot, 1 do
        if robot.count(s) > 0 then
            return s
        end
    end
    return 0
end

function checkSlot()
    if robot.count(currentSlot) > 0 then
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

function place{func}()
    local can, type = robot.detect{func}()
    if can then
        robot.swing{func}()
        place{func}()
    else
        if checkSlot() then
            robot.place{func}()
        end
    end
end
place{func}()
return '{func}'
'''.format(func=func))

def place_down():
    robot_place('Down')

def place_up():
    robot_place('Up')

def place():
    robot_place('')


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

function makeCraftTable1(db, offset)
    local target = getDbItemName(db, 13 + offset)

    if target == '' then
        return
    end

    local slots = {1, 2, 3, 10, 11, 12, 19, 20, 21}
    local craftTable = {}
    local slot
    local s
    for s = 1, 9, 1 do
        slot = slots[s]
        craftTable[s] = getDbItemName(db, slot + offset)
    end
    output = output .. 'craftTables["' .. target .. '"] = {"' .. table.concat(craftTable, '", "') .. '"}\\n'
end

function makeCraftTable2(db, offset)
    local target = getDbItemName(db, 17 + offset)

    if target == '' then
        return
    end

    local slots = {5, 6, 7, 14, 15, 16, 23, 24, 25}
    local craftTable = {}
    local slot
    local s
    for s = 1, 9, 1 do
        slot = slots[s]
        craftTable[s] = getDbItemName(db, slot + offset)
    end
    output = output .. 'craftTables["' .. target .. '"] = {"' .. table.concat(craftTable, '", "') .. '"}\\n'
end

refreshDbs()

for i = 1, #dbs, 1 do
    local db = dbs[i]
    if db.size == 25 then
        makeCraftTable(db.db, 0)
        makeCraftTable(db.db, 10)
    elseif db.size == 81 then
        makeCraftTable1(db.db, 0)
        makeCraftTable2(db.db, 0)
        makeCraftTable1(db.db, 27)
        makeCraftTable2(db.db, 27)
        makeCraftTable1(db.db, 54)
        makeCraftTable2(db.db, 54)
    end
end
return output
''')
