local robot = require('robot')
local component = require('component')
local craft = require('craft')

local dye = 'minecraft:dye'
local bone = 'minecraft:bone'
local boneBlock = 'minecraft:bone_block'
local fruitBone = 'croparia:fruit_bone'
local currentDyeSlot = 2
local currentSeedSlot = 1

local seed = craft.getItemName(1)

function placeItem(slot)
    print('placeItem', slot)
    local count = robot.count(slot)

    robot.select(slot)
    robot.placeDown()

    if robot.count(slot) < count then
        return true
    else
        return false
    end
end

function placeSeed()
    if craft.isItem(currentSeedSlot, seed) then
        return placeItem(currentSeedSlot)
    end
    local slot = craft.findItem(seed, 1)
    if slot == 0 then
        return false
    end
    currentSeedSlot = slot
    return placeSeed()
end

function placeDye()
    if craft.isItem(currentDyeSlot, dye) then
        if placeItem(currentDyeSlot) then
            return 1
        else
            return 0
        end
    end
    local slot = craft.findItem(dye, 1)
    if slot == 0 then
        return 2
    end
    currentDyeSlot = slot
    return placeDye()
end

function runPlaceDye()
    local ret = placeDye()
    if ret == 2 then
        craft.mergeItems()
        ret = craft.crafting1(bone)
        if ret == 2 then
            return false
        elseif ret == 0 then
            ret = craft.crafting1(fruitBone)
            if ret == 2 then
                return false
            elseif ret == 0 then
                ret = craft.crafting1(boneBlock)
                if ret == 2 then
                    return false
                elseif ret == 0 then
                    return false
                end
            end
        end
    elseif ret == 0 then
        return true
    end
    return runPlaceDye()
end

function main()
    robot.swingDown()
    local running = true
    if seed == '' then
        print('Error: seed not found.')
        return
    end
    while running do
        if not placeSeed() then
            break
        end
        if not runPlaceDye() then
            break
        end
        robot.swingDown()
    end
end

main()
