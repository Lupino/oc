local robot = require('robot')
local component = require('component')
local craft = require('craft')
local os = require('os')

local dye = 'Bone Meal'
local bone = 'Bone'
local boneBlock = 'Bone Block'
local fruitBone = 'Boneus Fruit'
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
        if not placeItem(currentSeedSlot) then
            robot.swingDown()
            robot.useDown()
            return placeSeed()
        else
            return true
        end
    end
    local slot = craft.findItem(seed, 1)
    if slot == 0 then
        slot = craft.findItemOnSides(seed)
        if slot == 0 then
            return false
        end
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
        slot = craft.findItemOnSides(dye)
        if slot == 0 then
            return 2
        end
    end
    currentDyeSlot = slot
    return placeDye()
end

function runPlaceDye()
    local ret = placeDye()
    if ret == 2 then
        craft.mergeItems()
        if not craft.crafting1(boneBlock) then
            if not craft.crafting1(bone) then
                if not craft.crafting1(fruitBone) then
                    return false
                end
            end
        end
    elseif ret == 0 then
        return true
    end
    return runPlaceDye()
end

function run_main()
    craft.scanItemsOnSides()
    robot.swingDown()
    if seed == '' then
        print('Error: seed not found.')
        return
    end
    while true do
        if not placeSeed() then
            break
        end
        if not runPlaceDye() then
            craft.scanItemsOnSides()
            if not runPlaceDye() then
                break
            end
        end
        robot.swingDown()
    end
end

function main()
    while true do
        run_main()
        print('wait 60')
        os.sleep(60)
    end
end

main()
