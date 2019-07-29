local internet = require("internet")
local handle = internet.open("example.com", 18090)
local computer = require("computer")

local maxMsgid = 65536
local maxLength = 32767

local RUN = 1
local UPLOAD = 2
local DOWNLOAD = 3
local DATA = 4

function pack(msgid, data)
    print('pack', msgid, data)
    msgid = msgid % maxMsgid
    local length = #data + 3
    if length > maxLength then
        print('payload is to large ignore.')
        return
    end

    local msg = ''

    msg = msg .. string.char(math.floor(length / 256))
    msg = msg .. string.char(length % 256)
    msg = msg .. string.char(math.floor(msgid / 256))
    msg = msg .. string.char(msgid % 256)
    msg = msg .. string.char(DATA)
    msg = msg .. data

    return msg
end

function unpack(msg)
    print('unpack', #msg)
    local length = string.byte(msg, 1) * 256 + string.byte(msg, 2)
    local msgid = string.byte(msg, 3) * 256 + string.byte(msg, 4)
    local cmd = string.byte(msg, 5)
    local data = msg:sub(6)

    return length, msgid, cmd, data
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
        if length > 3 and length < maxLength then
            local msg = handle:read(length)
            if #msg == length then
                local _, msgid, cmd, data = unpack(h .. msg)
                local result, reason = pcall(function()
                    if cmd == RUN then
                        local result, reason = load(data)
                        if result then
                            handle:write(pack(msgid, result()))
                        else
                            handle:write(pack(msgid, reason))
                        end
                    elseif cmd == UPLOAD then
                        length = string.byte(data, 1)
                        local fn = data:sub(2, 1 + length)
                        data = data:sub(2 + length)
                        local file, reason = io.open(fn, 'w')
                        if file then
                            file:write(data)
                            file:close()
                            handle:write(pack(msgid, 'OK'))
                        else
                            handle:write(pack(msgid, 'Error: ' .. reason))
                        end
                    elseif cmd == DOWNLOAD then
                        local file, reason = io.open(data, 'r')
                        if file then
                            data = file:read('*a')
                            file:close()
                            handle:write(pack(msgid, data))
                        else
                            handle:write(pack(msgid, "Error: " .. reason))
                        end
                    end
                end)
                if not result then
                    handle:write(pack(msgid, reason))
                end
            end
        end
    end
end
