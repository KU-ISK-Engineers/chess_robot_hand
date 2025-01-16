-- Version: Lua 5.3.5

---@generic T, R
---@param tbl T[]               # A table (array) of type T
---@param func fun(value: T): R # A function that transforms T to R
---@return R[]|nil             # Returns a table (array) of type R or nil if the function fails
local function map(tbl, func)
    local result = {}
    for i, v in ipairs(tbl) do
        local value = func(v)
        if not value then
            return nil
        end
        result[i] = value
    end
    return result
end


--------------------------------------------


local TCPServerIP = "192.168.1.6"
local TCPServerPort = 6001


---@param ip string
---@param port integer
---@return Socket|nil socket
local function connectTCP(ip, port)
    local err, socket

    err, socket = TCPCreate(true, ip, port)
    if err ~= 0 then
        print("Failed creating TCP Server " .. TCPServerIP .. ":" .. TCPServerPort)
        return
    end

    err = TCPStart(socket, 0)
    if err ~= 0 then
        print("Failed connecting to TCP Server, error = " .. err)
        TCPDestroy(socket)
        return nil
    end

    print("Connected to TCP Server")
    return socket
end


---@param socket Socket
---@return integer error
---@return string|nil command
local function readNextTCPCommand(socket)
    local err, result = TCPRead(socket, 0, 'string')
    if err ~= 0 or not result then
        return err
    end

    local command = result.buf
    print("Read TCP command = " .. command)
    return err, command
end


---@param socket Socket
---@param response string
local function sendTCPResponse(socket, response)
    -- TODO: Test if it works without raspberry turned off
    local err = TCPWrite(socket, response, 0)
    if err ~= 0 then
        print("Failed sending response to TCP, response = " .. response)
    else
        print("Successfully sent TCP response = " .. response)
    end
end


---@param input string
---@return string operation
---@return string[] args
local function parseArgs(input)
    local command, args = input:match("^(%S+)%s*(.*)$")
    local argsTable = {}

    for arg in string.gmatch(args, "%S+") do
        table.insert(argsTable, arg)
    end

    return command, argsTable
end


---@param args string[]
---@return integer error
---@return integer originSquare
---@return integer offsetX
---@return integer offsetY
---@return integer targetSquare
local function parseMoveArgs(args)
    if #args ~= 4 then
        return 1
    end

    local originSquare = tonumber(args[1])
    local offsetX = tonumber(args[2])
    local offsetY = tonumber(args[3])
    local targetSquare = tonumber(args[4])

    -- TODO: Validate arguments

    return 0
end


---@param square integer
---@return Coordinate coordinate
local function squareToCoord(square)
end


---@param coordinate Coordinate
---@param offsetX integer
---@param offsetY integer
---@return Coordinate coordinate
local function offsetCoord(coordinate, offsetX, offsetY)
end


---@param originCoord Coordinate
---@param targetCoord Coordinate
local function movePiece(originCoord, targetCoord)
end


---@param command string
---@return integer error
local function executeCommand(command)
    -- TODO: Pass context for counting pieces locations

    local operation, args = parseArgs(command)

    if operation == "move" then
        local err, originSquare, offsetX, offsetY, targetSquare = parseMoveArgs(args)
        if err ~= 0 then
            return err
        end

        local originCoord = offsetCoord(squareToCoord(originSquare), offsetX, offsetY)
        local targetCoord = squareToCoord(targetSquare)

        movePiece(originCoord, targetCoord)
    elseif operation == "reset" then

    end

    return 1
end


local function main()
    local socket, err

    socket = connectTCP(TCPServerIP, TCPServerPort)
    if not socket then
        return
    end

    while true do
        local command

        while not command do
            err, command = readNextTCPCommand(socket)
            if err ~= 0 or not command then
                print("Failed reading command assuming socket closed, reconnecting...")
                TCPDestroy(socket)
                socket = connectTCP(TCPServerIP, TCPServerPort)
                if not socket then
                    return
                end
            end
        end

        err = executeCommand(command)
        if err ~= 0 then
            sendTCPResponse(socket, "failure")
        else
            sendTCPResponse(socket, "success")
        end
    end
end


main()
