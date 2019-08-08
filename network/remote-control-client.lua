local internet = require("internet")
local handle = internet.open("example.com", 18090)
local computer = require("computer")

local maxMsgid = 65536
local maxLength = 32767

local RUN = 1
local UPLOAD = 2
local DOWNLOAD = 3
local DATA = 4
local APPEND = 5
local END = 6

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

-- msgid + cmd + data
function unpackHeader(msg)
    local msgid = string.byte(msg, 1) * 256 + string.byte(msg, 2)
    local cmd = string.byte(msg, 3)
    return msgid, cmd
end

function getLength(msg)
    return string.byte(msg, 1) * 256 + string.byte(msg, 2)
end

-- register computer address
handle:write(pack(0, computer.address()))

function chunkRead(length)
    local code = ''
    local chunk = ''
    while true do
        size = length
        if size > 256 then
            size = 256
        end
        if size <= 0 then
            break
        end
        chunk = handle:read(size)
        code = code .. chunk
        length = length - #chunk
    end
    return code
end

function chunkReadAndSave(file, length)
    local chunk = ''
    while true do
        size = length
        if size > 256 then
            size = 256
        end
        if size <= 0 then
            break
        end

        chunk = handle:read(size)

        file:write(chunk)

        length = length - #chunk
    end
end

local running = true

while running do
    local h = handle:read(2)
    if #h == 2 then
        local length = getLength(h)
        if length >= 3 and length < maxLength then
            local msg = handle:read(3)
            if #msg == 3 then
                local msgid, cmd = unpackHeader(msg)
                length = length - 3
                local result, reason = pcall(function()
                    if cmd == RUN then
                        local code = chunkRead(length)
                        local result, reason = load(code)
                        if result then
                            handle:write(pack(msgid, result()))
                        else
                            handle:write(pack(msgid, reason))
                        end
                    elseif cmd == UPLOAD then
                        local fnL = string.byte(handle:read(1), 1)
                        local fn = chunkRead(fnL)
                        length = length - 1 - fnL
                        local file, reason = io.open(fn, 'w')
                        if file then
                            chunkReadAndSave(file, length)
                            file:close()
                            handle:write(pack(msgid, 'OK'))
                        else
                            handle:write(pack(msgid, 'Error: ' .. reason))
                        end
                    elseif cmd == DOWNLOAD then
                        local fn = chunkRead(length)
                        local file, reason = io.open(fn, 'r')
                        if file then
                            data = file:read('*a')
                            file:close()
                            handle:write(pack(msgid, data))
                        else
                            handle:write(pack(msgid, "Error: " .. reason))
                        end
                    elseif cmd == APPEND then
                        local fnL = string.byte(handle:read(1), 1)
                        local fn = chunkRead(fnL)
                        length = length - 1 - fnL
                        local file, reason = io.open(fn, 'a')
                        if file then
                            chunkReadAndSave(file, length)
                            file:close()
                            handle:write(pack(msgid, 'OK'))
                        else
                            handle:write(pack(msgid, 'Error: ' .. reason))
                        end
                    elseif cmd == END then
                        handle:write(pack(msgid, "Shutdown ..."))
                        running = false
                    end
                end)
                if not result then
                    handle:write(pack(msgid, reason))
                end
            end
        end
    end
end

handle:close()
