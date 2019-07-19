local internet = require("internet")
local handle = internet.open("example.com", 18090)
local computer = require("computer")
-- local serialization = require('serialization')

local maxMsgid = 65536
local maxLength = 32767

function pack(msgid, data)
    print('pack', msgid, data)
    msgid = msgid % maxMsgid
    -- data = serialization.serialize(data)
    local length = #data + 2
    if length > maxLength then
        print('payload is to large ignore.')
        return
    end

    local msg = ''

    msg = msg .. string.char(math.floor(length / 256))
    msg = msg .. string.char(length % 256)
    msg = msg .. string.char(math.floor(msgid / 256))
    msg = msg .. string.char(msgid % 256)
    msg = msg .. data

    return msg
end

function unpack(msg)
    print('unpack', #msg)
    local length = string.byte(msg, 1) * 256 + string.byte(msg, 2)
    local msgid = string.byte(msg, 3) * 256 + string.byte(msg, 4)
    local data = msg:sub(5)

    return length, msgid, data
end

function getLength(msg)
    return string.byte(msg, 1) * 256 + string.byte(msg, 2)
end

-- register computer address
handle:write(pack(0, computer.address()))

while true do
    local h = handle:read(2)
    if #h == 2 then
        local length = getLength(h)
        if length > 2 and length < maxLength then
            local msg = handle:read(length)
            if #msg == length then
                local _, msgid, data = unpack(h .. msg)
                local result, reason = pcall(function()
                    local result, reason = load(data)
                    if result then
                        handle:write(pack(msgid, result()))
                    else
                        handle:write(pack(msgid, reason))
                    end
                end)
                if not result then
                    handle:write(pack(msgid, reason))
                end
            end
        end
    end
end
