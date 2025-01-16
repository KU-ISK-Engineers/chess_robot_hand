-- Version: Lua 5.3.5


---@param text string
---@return integer|nil value
local function toInteger(text)
    local number = tonumber(text)
    if number and math.floor(number) == number then
        return number
    end
    return nil
end

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

_MAX_PIECES = {
    [-1] = 2,  -- white rook
    [-2] = 2,  -- white bishop
    [-3] = 2,  -- white knight
    [-4] = 1,  -- white queen
    [-5] = 1,  -- white king
    [-6] = 8,  -- white pawn
    [-7] = 2,  -- black rook
    [-8] = 2,  -- black bishop
    [-9] = 2,  -- black knight
    [-10] = 1, -- black queen
    [-11] = 1, -- black king
    [-12] = 8  -- black pawn
}

_CAPTURED_PIECES_COUNT = {
    [-1] = 0,  -- white rook
    [-2] = 0,  -- white bishop
    [-3] = 0,  -- white knight
    [-4] = 0,  -- white queen
    [-5] = 0,  -- white king
    [-6] = 0,  -- white pawn
    [-7] = 0,  -- black rook
    [-8] = 0,  -- black bishop
    [-9] = 0,  -- black knight
    [-10] = 0, -- black queen
    [-11] = 0, -- black king
    [-12] = 0  -- black pawn
}

-- TODO: Merge both of these functions into one?

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
---@return integer error
local function relocate(originCoord, targetCoord)
end


---@param originSquare integer
---@param offsetX integer
---@param offsetY integer
---@param targetSquare integer
---@return integer error
local function movePiece(originSquare, offsetX, offsetY, targetSquare)
    -- Validation
    if _CAPTURED_PIECES_COUNT[originSquare] ~= nil then
        local count = _CAPTURED_PIECES_COUNT[originSquare]
        if count == 0 then
            return 1
        end
    end

    if _CAPTURED_PIECES_COUNT[targetSquare] ~= nil then
        local count = _CAPTURED_PIECES_COUNT[targetSquare]
        if (count + 1) > _MAX_PIECES[targetSquare] then
            return 2
        end
    end

    -- Movement
    local originCoord = offsetCoord(squareToCoord(originSquare), offsetX, offsetY)
    local targetCoord = squareToCoord(targetSquare)

    local err = relocate(originCoord, targetCoord)
    if err ~= 0 then
        return 3
    end

    -- Update
    if _CAPTURED_PIECES_COUNT[originSquare] ~= nil then
        local count = _CAPTURED_PIECES_COUNT[originSquare]
        _CAPTURED_PIECES_COUNT[originSquare] = count - 1
    end

    if _CAPTURED_PIECES_COUNT[targetSquare] ~= nil then
        local count = _CAPTURED_PIECES_COUNT[targetSquare]
        _CAPTURED_PIECES_COUNT[targetSquare] = count + 1
    end

    return 0
end


local function resetCapturedPieces()
    for key in pairs(_CAPTURED_PIECES_COUNT) do
        _CAPTURED_PIECES_COUNT[key] = 0
    end
end


---@param square integer
---@return boolean validity
local function isValidSquare(square)
    return (square >= 0 and square <= 63) or _MAX_PIECES[square] ~= nil
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
        return 1, 0, 0, 0, 0
    end

    local originSquare = toInteger(args[1])
    local offsetX = toInteger(args[2])
    local offsetY = toInteger(args[3])
    local targetSquare = toInteger(args[4])

    if not (originSquare and offsetX and offsetY and targetSquare) then
        return 1, 0, 0, 0, 0
    end

    if not (isValidSquare(originSquare) and isValidSquare(targetSquare)) then
        return 1, 0, 0, 0, 0
    end

    if not (math.abs(offsetX) <= 100 and math.abs(offsetY) <= 100) then
        return 1, 0, 0, 0, 0
    end

    return 0, originSquare, offsetX, offsetY, targetSquare
end


---@param command string
---@return integer error
local function executeCommand(command)
    local operation, args = parseArgs(command)

    if operation == "move" then
        local err, originSquare, offsetX, offsetY, targetSquare = parseMoveArgs(args)
        if err ~= 0 then
            return err
        end

        return movePiece(originSquare, offsetX, offsetY, targetSquare)
    elseif operation == "reset" then
        resetCapturedPieces()
        return 0
    end

    return 1
end


-------------------------------------------- Main  --------------------------------------------


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
