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

def upload(data, filename, append=False, show=True):
    cmd = 'append' if append else 'upload'
    rsp = requests.put(api(cmd, {'fileName': filename}), data=data)
    if show:
        print(rsp.text)
    else:
        return rsp.text

def uploadWith(fn, filename, show=True):
    data = open(fn, 'r').read()
    batch_size = 10240     # 10k
    ret = upload(data[:batch_size], filename, False, show)
    while True:
        data = data[batch_size:]
        if not data:
            break
        upload(data[:batch_size], filename, True, True)

    return ret

def download(filename, show=True):
    rsp = requests.get(api('download', {'fileName': filename}))
    if show:
        print(rsp.text)
    else:
        return rsp.text

def end(show=True):
    rsp = requests.post(api('end'))
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

def robot_run(func, count = 1):
    run('''
local robot = require('robot')
for i = 1, {count}, 1 do
    robot.{func}()
end
return '{func}'
'''.format(func=func, count=count))

def up(count=1):
    robot_run('up', count)

def down(count=1):
    robot_run('down', count)

def forward(count=1):
    robot_run('forward', count)

def back(count=1):
    robot_run('back', count)

def robot_force_run(func, count = 1):
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
for i = 1, {count}, 1 do
    {func}()
end
return '{func}'
'''.format(func=func, Func=Func, count=count))

def force_up(count=1):
    robot_force_run('up', count)

def force_down(count=1):
    robot_force_run('down', count)

def force_forward(count=1):
    robot_force_run('forward', count)

def turn_left():
    robot_run('turnLeft')

def turn_right():
    robot_run('turnRight')

def use_down():
    robot_run('useDown')

def use():
    robot_run('use')

def robot_place(func = '', forward_count = 0):
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
forward_count = {forward_count}

if forward_count > 0 then
    for i = 1, forward_count, 1 do
        place{func}()
        robot.forward()
    end
else
    place{func}()
end
return '{func}'
'''.format(func=func, forward_count=forward_count))

def place_down(forward_count = 0):
    robot_place('Down', forward_count)

def place_up():
    robot_place('Up')

def place():
    robot_place()

def make_craft_table():
    data = open('../craft/make_craft_table.lua', 'r').read()
    data = data.replace('print(output)', 'return output')
    run(data)

def crafting(itemName, count=1):
    run('''
local crafting = loadfile('/usr/bin/crafting.lua')
crafting('{}', {})
return 'crafted'
    '''.format(itemName, count))

def crafting_scan():
    run('''
local craft = require('craft')
craft.scanItemsOnSides()
return 'scanItemsOnSides'
    ''')


def consume():
    run('''
local robot = require('robot')
local component = require('component')
local exp = component.experience

for i = 1, 16, 1 do
    robot.select(i)
    for j = 1, 64, 1 do
        exp.consume()
    end
end
return 'consumed'
    ''')
