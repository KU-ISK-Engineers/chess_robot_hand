-- Version: Lua 5.3.5

-------------------------------------------- TCP  --------------------------------------------


local TCPServerIP = "192.168.1.6"
local TCPServerPort = 6001

---@type Socket|nil
local _SOCKET = nil


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

-------------------------------------------- Coordinates  --------------------------------------------

---@param origin Point2D
---@param square_distance Point2D
---@param angle_rad number
local function transform2d(origin, square_distance, angle_rad)
    local angle_sin = math.sin(angle_rad)
    local angle_cos = math.cos(angle_rad)

    ---@param row integer
    ---@param col integer
    ---@param center_offset Point2D
    ---@return Point2D coord
    return function(row, col, center_offset)
        local local_x = col * square_distance[1]
        local local_y = row * square_distance[2]

        local_x = local_x + center_offset[1] * (square_distance[1] / 2)
        local_y = local_y + center_offset[2] * (square_distance[2] / 2)

        local rotated_x = local_x * angle_cos - local_y * angle_sin
        local rotated_y = local_x * angle_sin + local_y * angle_cos

        local robot_x = origin[1] + rotated_x
        local robot_y = origin[2] + rotated_y

        return {robot_x, robot_y}
    end
end

local InitialCoord = {219.13, -155.64, 0, 0}

local BoardSquareA1 = {224.37, 97.78}
local BoardSquareDist = {27.15055965898159, 26.954213572955865}
local BoardRotRad = -1.5586942024430779
local TransformBoardCoord = transform2d(BoardSquareA1, BoardSquareDist, BoardRotRad)
local BoardHeight = -90.0

local ReserveSquareA1 = {95.58, -238.95}
local ReserveSquareDist = {-25.0, -25.0}
local TransformReserveCoord = transform2d(ReserveSquareA1, ReserveSquareDist, 0)
local ReserveHeight = -110


-------------------------------------------- Movement  --------------------------------------------


local _RESERVE_COUNT_MAX = {
    [-1] = 2,  -- white rook
    [-2] = 2,  -- white knight
    [-3] = 2,  -- white bishop
    [-4] = 1,  -- white queen
    [-5] = 1,  -- white king
    [-6] = 8,  -- white pawn
    [-7] = 2,  -- black rook
    [-8] = 2,  -- black knight
    [-9] = 2,  -- black bishop
    [-10] = 1, -- black queen
    [-11] = 1, -- black king
    [-12] = 8  -- black pawn
}

local _RESERVE_COUNT = {
    [-1] = 0,  -- white rook
    [-2] = 0,  -- white knight
    [-3] = 0,  -- white bishop
    [-4] = 0,  -- white queen
    [-5] = 0,  -- white king
    [-6] = 0,  -- white pawn
    [-7] = 0,  -- black rook
    [-8] = 0,  -- black knight
    [-9] = 0,  -- black bishop
    [-10] = 0, -- black queen
    [-11] = 0, -- black king
    [-12] = 0  -- black pawn
}

-- From board/reserve height 
local LiftHeight = 30
local PinVacuum = 8

---@param square integer
---@return boolean validity
local function isValidSquare(square)
    return (square >= 0 and square <= 63) or _RESERVE_COUNT[square] ~= nil
end


---@param square integer
---@return boolean validity
local function isReserveSquare(square)
    return _RESERVE_COUNT[square] ~= nil
end


local function resetCapturedPieces()
    for key in pairs(_RESERVE_COUNT) do
        _RESERVE_COUNT[key] = 0
    end
end


---@param square integer
---@param offset Point2D
---@param reserve_index integer
---@return Coordinate|nil coordinate
local function squareToCoord(square, offset, reserve_index)
    if isReserveSquare(square) then
        -- Maps to one reserve box
        -- 0 rook, 1 bishop, 2 knight, 3 queen, 4 king, 5 pawn
        local piece = (math.abs(square)-1) % 6
        local row, col
        if piece == 5 then
            row = 0
            col = reserve_index
        else
            row = 1
            -- Flip X axis if we want the second piece
            col = 7 * reserve_index - piece
        end
        local coord2d = TransformReserveCoord(row, col, offset)
        return {coord2d[1], coord2d[2], ReserveHeight, 0}
    elseif isValidSquare(square) then
        local row = square // 8
        local col = square % 8
        local coord2d = TransformBoardCoord(row, col, offset)
        return {coord2d[1], coord2d[2], BoardHeight, 0}
    end
    return nil
end


---@param originCoord Coordinate
---@param targetCoord Coordinate
---@param liftHeight number
local function executeMove(originCoord, targetCoord, liftHeight)
    MovJ({coordinate = originCoord})

    DO(PinVacuum, ON)
    Wait(100)
    Jump({coordinate = targetCoord}, {ZLimit=liftHeight})
    DO(PinVacuum, OFF)
    Wait(100)

    Jump({coordinate = InitialCoord}, {ZLimit=liftHeight})
    Sync()
end


---@param originSquare integer
---@param offset Point2D
---@param targetSquare integer
---@return integer error
local function movePiece(originSquare, offset, targetSquare)
    -- Validation
    if _RESERVE_COUNT[originSquare] ~= nil then
        local count = _RESERVE_COUNT[originSquare]
        if count == 0 then
            print("Move - Origin square not enough pieces " .. originSquare)
            return 1
        end
    end

    if _RESERVE_COUNT[targetSquare] ~= nil then
        local count = _RESERVE_COUNT[targetSquare]
        if (count + 1) > _RESERVE_COUNT_MAX[targetSquare] then
            print("Move - Target square cannot exceed maximum pieces " .. targetSquare)
            return 2
        end
    end

    -- Movement
    local originCount = _RESERVE_COUNT[originSquare] or 0
    local targetCount = _RESERVE_COUNT[targetSquare] or 0

    -- Take from previous square in reserve, index = count-1
    local originCoord = squareToCoord(originSquare, offset, originCount-1)

    -- Take from next square in reserve, index = count
    local targetCoord = squareToCoord(targetSquare, {0, 0}, targetCount)

    if not originCoord or not targetCoord then
        print("Move - Invalid coordinate")
        return 3
    end

    executeMove(originCoord, targetCoord, LiftHeight)

    -- Update
    if _RESERVE_COUNT[originSquare] ~= nil then
        local count = _RESERVE_COUNT[originSquare]
        _RESERVE_COUNT[originSquare] = count - 1
    end

    if _RESERVE_COUNT[targetSquare] ~= nil then
        local count = _RESERVE_COUNT[targetSquare]
        _RESERVE_COUNT[targetSquare] = count + 1
    end

    return 0
end


-------------------------------------------- Command  --------------------------------------------


---@param text string
---@return integer|nil value
local function toInteger(text)
    local number = tonumber(text)
    if number and math.floor(number) == number then
        return number
    end
    return nil
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
        print("Command move - argument mismatch: <origin square> <offset X> <offset Y> <target square>")
        return 1, 0, 0, 0, 0
    end

    local originSquare = toInteger(args[1])
    local offsetX = toInteger(args[2])
    local offsetY = toInteger(args[3])
    local targetSquare = toInteger(args[4])

    if not (originSquare and offsetX and offsetY and targetSquare) then
        print("Command move - arguments are not integers")
        return 1, 0, 0, 0, 0
    end

    if not (isValidSquare(originSquare) and isValidSquare(targetSquare)) then
        print("Command move - invalid square")
        return 1, 0, 0, 0, 0
    end

    if not (math.abs(offsetX) <= 100 and math.abs(offsetY) <= 100) then
        print("Command move - invalid offset range")
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
        return movePiece(originSquare, {offsetX, offsetY}, targetSquare)
    elseif operation == "reset" then
        resetCapturedPieces()
        return 0
    elseif operation == "ping" then
        return 0
    end

    if not operation then
        print("No operation specified")
    else
        print("Unknown operation = " .. operation)
    end
    return 1
end


-------------------------------------------- Main  --------------------------------------------


local function main()
    MovJ({coordinate = InitialCoord})
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