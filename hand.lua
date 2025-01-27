-- Version: Lua 5.3.5


-------------------------------------------- Coordinate  --------------------------------------------


--- Converts robot coordinate system to a 2D grid, based on origin point,
-- cell distances and rotation angle based on X axis
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

        return { robot_x, robot_y }
    end
end

local InitialCoord = { 219.13, -155.64, 0, 0 }

local BoardSquareA1 = { 227.27, 97.78 }
local BoardSquareDist = { 27.15055965898159, 26.80912151364939 }
local BoardRotRad = -1.5586942024430779
local TransformBoardCoord = transform2d(BoardSquareA1, BoardSquareDist, BoardRotRad)
local BoardLiftHeight = -107.0 -- Height required to take/put piece on a board

local ReserveSquareA1 = { 319.53, -237.25 }
local ReserveSquareDist = { -25.0, -25.0 }
local TransformReserveCoord = transform2d(ReserveSquareA1, ReserveSquareDist, 0)
local ReserveLiftHeight = -115.0 -- Height required to take/put piece of on reserve


-------------------------------------------- Square  --------------------------------------------


local _RESERVE_COUNT_MAX = {
    [-1] = 2, -- white rook
    [-2] = 2, -- white knight
    [-3] = 2, -- white bishop
    [-4] = 1, -- white queen
    [-5] = 1, -- white king
    [-6] = 8, -- white pawn
}

local _RESERVE_COUNT = {
    [-1] = 0, -- white rook
    [-2] = 0, -- white knight
    [-3] = 0, -- white bishop
    [-4] = 0, -- white queen
    [-5] = 0, -- white king
    [-6] = 0, -- white pawn
}


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


local function clearReserve()
    for key in pairs(_RESERVE_COUNT) do
        _RESERVE_COUNT[key] = 0
    end
    print("Cleared pieces reserve memory")
end


---@param square integer
---@param offset Point2D
---@param reserve_index integer
---@return Coordinate|nil coordinate
local function squareToCoord(square, offset, reserve_index)
    if isReserveSquare(square) then
        -- Maps to one reserve box
        -- 0 rook, 1 knight, 2 bishop, 3 queen, 4 king, 5 pawn
        local piece = (math.abs(square) - 1) % 6
        local row, col
        if piece == 5 then
            row = 0
            col = reserve_index
        else
            row = 1
            -- Flip X axis if we want the second piece
            col = piece
            if reserve_index == 1 then
                col = 7 - piece
            end
        end
        local coord2d = TransformReserveCoord(row, col, offset)
        return { coord2d[1], coord2d[2], ReserveLiftHeight, 0 }
    elseif isValidSquare(square) then
        local row = square // 8
        local col = square % 8
        local coord2d = TransformBoardCoord(row, col, offset)
        return { coord2d[1], coord2d[2], BoardLiftHeight, 0 }
    end
    return nil
end


-------------------------------------------- Movement  --------------------------------------------


local LiftHeight = 40 -- Extra height for moving pieces across the board
local PinOutVacuum = 8


---@param originCoord Coordinate
---@param targetCoord Coordinate
---@param useMidPoint boolean
local function executeMove(originCoord, targetCoord, useMidPoint)
    print(string.format("Move: Moving piece from (%f,%f) to (%f,%f)", originCoord[1], originCoord[2], targetCoord[1],
        targetCoord[2]))
    local lowerOriginCoord = RelPoint({ coordinate = originCoord }, { 0, 0, LiftHeight, 0 })
    local lowerTargetCoord = RelPoint({ coordinate = targetCoord }, { 0, 0, LiftHeight, 0 })

    MovJ(lowerOriginCoord)
    RelMovJ({ 0, 0, -LiftHeight, 0 })

    DO(PinOutVacuum, ON)

    RelMovJ({ 0, 0, LiftHeight, 0 })

    if useMidPoint then
        MovL({ coordinate = InitialCoord })
    end

    MovJ(lowerTargetCoord)
    RelMovJ({ 0, 0, -LiftHeight, 0 })

    DO(PinOutVacuum, OFF)

    RelMovJ({ 0, 0, LiftHeight, 0 })

    MovL({ coordinate = InitialCoord })
    Sync()
end


local function xor(a, b)
    return (a ~= nil) ~= (b ~= nil)
end


---@param originSquare integer
---@param offset Point2D offsets in range [-1..1]
---@param targetSquare integer
---@return string|nil error
local function movePiece(originSquare, offset, targetSquare)
    if _RESERVE_COUNT[originSquare] ~= nil then
        local count = _RESERVE_COUNT[originSquare]
        if count == 0 then
            return "Cannot move: origin square not enough pieces " .. originSquare
        end
    end

    if _RESERVE_COUNT[targetSquare] ~= nil then
        local count = _RESERVE_COUNT[targetSquare]
        if (count + 1) > _RESERVE_COUNT_MAX[targetSquare] then
            return "Cannot move: Target square cannot exceed maximum pieces " .. targetSquare
        end
    end

    local originCount = _RESERVE_COUNT[originSquare] or 0
    local targetCount = _RESERVE_COUNT[targetSquare] or 0

    -- Take from previous square in reserve, index = count-1
    local originCoord = squareToCoord(originSquare, offset, originCount - 1)

    -- Take from next square in reserve, index = count
    local targetCoord = squareToCoord(targetSquare, { 0, 0 }, targetCount)

    if not originCoord or not targetCoord then
        return "Cannot move: Invalid coordinate"
    end

    print(string.format("Move: Moving piece from %d to %d", originSquare, targetSquare))
    local useMidPoint = xor(_RESERVE_COUNT[originSquare], _RESERVE_COUNT[targetSquare])

    executeMove(originCoord, targetCoord, useMidPoint)

    if _RESERVE_COUNT[originSquare] ~= nil then
        local count = _RESERVE_COUNT[originSquare]
        _RESERVE_COUNT[originSquare] = count - 1
    end

    if _RESERVE_COUNT[targetSquare] ~= nil then
        local count = _RESERVE_COUNT[targetSquare]
        _RESERVE_COUNT[targetSquare] = count + 1
    end

    return nil
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
---@return string|nil error
---@return integer originSquare
---@return number offsetX offset X in range of [-1,1]
---@return number offsetY offset Y in range of [-1,1]
---@return integer targetSquare
local function parseMoveArgs(args)
    if #args ~= 4 then
        local err = "Command move: Argument mismatch: <origin square> <offset X> <offset Y> <target square>"
        return err, 0, 0, 0, 0
    end

    local originSquare = toInteger(args[1])
    local offsetX = toInteger(args[2])
    local offsetY = toInteger(args[3])
    local targetSquare = toInteger(args[4])

    if not (originSquare and offsetX and offsetY and targetSquare) then
        local err = "Command move: Arguments are not integers"
        return err, 0, 0, 0, 0
    end

    if not (isValidSquare(originSquare) and isValidSquare(targetSquare)) then
        local err = "Command move: Invalid square"
        return err, 0, 0, 0, 0
    end

    if not (math.abs(offsetX) <= 100 and math.abs(offsetY) <= 100) then
        local err = "Command move: Invalid offset range, must be in [-100,100]"
        return err, 0, 0, 0, 0
    end

    return nil, originSquare, offsetX / 100, offsetY / 100, targetSquare
end


---@param command string
---@return string|nil error
local function executeCommand(command)
    local operation, args = parseArgs(command)

    if operation == "move" then
        local err, originSquare, offsetX, offsetY, targetSquare = parseMoveArgs(args)
        if err ~= nil then
            return err
        end
        return movePiece(originSquare, { offsetX, offsetY }, targetSquare)
    elseif operation == "reset" then
        clearReserve()
        return nil
    elseif operation == "ping" then
        return nil
    end

    if not operation then
        return "No operation specified"
    else
        return "Unknown operation = " .. operation
    end
end


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


---@return string|nil command
local function readNextTCPCommand()
    if not _SOCKET then
        return nil
    end

    local err, result = TCPRead(_SOCKET, 0, 'string')
    if err ~= 0 or not result or not result.buf then
        return nil
    end

    local command = result.buf
    print("Read TCP command = " .. command)
    return command
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
        print("Sent TCP response = " .. response)
    end
    return err
end


-------------------------------------------- Main  --------------------------------------------


local function main()
    -- Initial state
    MovJ({ coordinate = InitialCoord })
    DO(PinOutVacuum, OFF)

    connectTCP()

    while true do
        local command, err

        while not command do
            command = readNextTCPCommand()
            if not command then
                print("Failed reading command assuming socket closed, reconnecting...")
                connectTCP()
            end
        end

        err = executeCommand(command)
        if err then
            print("Failed executing command: " .. err)
            sendTCPResponse("failure " .. err)
        else
            sendTCPResponse("success")
        end
    end
end

main()
