import requests
from urllib.parse import urlencode

uuid = 'you-uuid'

def api(cmd, query = None):
    url = 'http://example.com/api/{}/{}/'.format(cmd, uuid)
    if query:
        url = '{}?{}'.format(url, urlencode(query))

    return url

def run(data, show=True):
    rsp = requests.post(api('run'), data=data)

    if show:
        print(rsp.text)
    else:
        return rsp.text

def upload(data, filename, show=True):
    rsp = requests.put(api('upload', {'fileName': filename}), data=data)
    if show:
        print(rsp.text)
    else:
        return rsp.text

def download(filename, show=True):
    rsp = requests.get(api('download', {'fileName': filename}))
    if show:
        print(rsp.text)
    else:
        return rsp.text

def get_uptime():
    return run('''
local computer = require('computer')
local serialization = require('serialization')
return serialization.serialize(computer.uptime())
''')

def robot_run(func):
    run('''
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

    run('''
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

def robot_place(func = ''):
    run('''
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
    robot_place()

def make_craft_table():
    data = open('../craft/make_craft_table.lua', 'r').read()
    data = data.replace('print(output)', 'return output')
    run(data)
