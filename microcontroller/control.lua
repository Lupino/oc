local redstone = component.proxy(component.list("redstone")())
local internet = component.proxy(component.list("internet")())

local uuid = '12839855-d8e4-4149-891d-8dfafed21731'
local token = '9e899f11-1560-458b-8492-2723a2374d8a'
local url = 'http://superapp.huabot.com/api/devices/' .. uuid .. '/rpc/'
local id = '1'

function relaySwitch(onoff)
    local command = '%7B%22method%22%3A%22relay_' .. onoff .. '%22%2C%22index%22%3A' .. id .. '%7D'
    local data = 'data=' .. command .. '&token=' .. token .. '&format=json'
    local ret, res = pcall(internet.request, url, data)
    return ret
end

local switch = 4
local state = true

while true do
    computer.pullSignal(1)
    if (redstone.getInput(switch) > 2) then
        if not state then
            state = relaySwitch('on')
        end
    else
        if state then
            state = relaySwitch('off')
        end
    end
end
