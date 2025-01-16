-- Version: Lua 5.3.5


-------------------------------------------- TCP  --------------------------------------------


local TCPServerIP = "192.168.1.6"
local TCPServerPort = 6001

---@type Socket|nil
_SOCKET = nil


local function connectTCP()
    if _SOCKET then
        TCPDestroy(_SOCKET)
        _SOCKET = nil
    end

    while not _SOCKET do
        local err
        err, _SOCKET = TCPCreate(true, TCPServerIP, TCPServerPort)
        if err ~= 0 then
            print("Failed creating TCP Server " .. TCPServerIP .. ":" .. TCPServerPort)
        else
            err = TCPStart(_SOCKET, 0)
            if err ~= 0 then
                print("Failed connecting to TCP Server, error = " .. err)
                TCPDestroy(_SOCKET)
                _SOCKET = nil
            end
        end
    end

    print("Connected to TCP Server " .. TCPServerIP .. ":" .. TCPServerPort)
end


---@return integer error
---@return string|nil command
local function readNextTCPCommand()
    if not _SOCKET then
        return 1, nil
    end

    local err, result = TCPRead(_SOCKET, 0, 'string')
    if err ~= 0 or not result or not result.buf then
        return 1, nil
    end

    local command = result.buf
    print("Read TCP command = " .. command)
    return err, command
end


---@param response string
---@return integer error
local function sendTCPResponse(response)
    if not _SOCKET then
        return 1
    end

    local err = TCPWrite(_SOCKET, response, 0)
    if err ~= 0 then
        print("Failed sending response to TCP, response = " .. response)
    else
        print("Successfully sent TCP response = " .. response)
    end
    return err
end


-------------------------------------------- Movement  --------------------------------------------


-- TODO: Shelved pieces counter

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


-------------------------------------------- Command  --------------------------------------------


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
    connectTCP()

    while true do
        local command, err

        while not command do
            err, command = readNextTCPCommand()
            if err ~= 0 or not command then
                print("Failed reading command assuming socket closed, reconnecting...")
                connectTCP()
            end
        end

        err = executeCommand(command)
        if err ~= 0 then
            sendTCPResponse("failure")
        else
            sendTCPResponse("success")
        end
    end
end


main()
