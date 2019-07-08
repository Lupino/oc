local redstone = component.proxy(component.list("redstone")())

local brew_tick = 1
local collect_tick = 0

local brew_state = true
local collect_state = false

local brew_delay = 24
local collect_delay = 22

local collect_pin = 5

redstone.setOutput(brew_pin, 15)
redstone.setOutput(collect_pin, 0)

while true do
    computer.pullSignal(1)
    if brew_tick > brew_delay then
        if brew_state then
            redstone.setOutput(brew_pin, 0)
            brew_state = false
            brew_delay = 6
        else
            redstone.setOutput(brew_pin, 15)
            brew_state = true
            brew_delay = 24
        end
        brew_tick = 0
    end
    if collect_tick > collect_delay then
        if collect_state then
            redstone.setOutput(collect_pin, 0)
            collect_state = false
            collect_delay = 22
        else
            redstone.setOutput(collect_pin, 15)
            collect_state = true
            collect_delay = 8
        end
        collect_tick = 0
    end
    brew_tick = brew_tick + 1
    collect_tick = collect_tick + 1
end
