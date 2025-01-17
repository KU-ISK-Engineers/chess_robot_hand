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

---@param square integer
---@param offsetX integer
---@param offsetY integer
---@return Coordinate coordinate
local function squareToCoord(square, offsetX, offsetY)
end


---@param originCoord Coordinate
---@param targetCoord Coordinate
---@return integer error
local function relocate(originCoord, targetCoord)
    return 1
end


---@param originSquare integer
---@param offsetX integer
---@param offsetY integer
---@param targetSquare integer
---@return integer error
local function movePiece(originSquare, offsetX, offsetY, targetSquare)
    -- TODO: Return to initial pose

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
    local originCoord = squareToCoord(originSquare, offsetX, offsetY)
    local targetCoord = squareToCoord(targetSquare, 0, 0)

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
        return movePiece(originSquare, offsetX, offsetY, targetSquare)
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


--main()

--[[
main_coord = {coordinate = {415, -90, -105, 0}}
other_coord = {coordinate = {92, -261, -113, 0}}
Option = {CP=100}

MovJ({coordinate = main_coord}, Option)
Sync()
MovJ({coordinate = other_coord}, Option)
Sync()

Wait(1000)

MovJ({coordinate = main_coord}, Option)
Sync()
MovJ({coordinate = other_coord}, Option)
Sync()
]]

--[[
first_jump = {coordinate = {226, -94, -110, 0}}
second_jump = {coordinate = {417, -94, -110, 0}}

Jump(first_jump, {ZLimit=10})
Jump(second_jump, {ZLimit=10})
Sync()

]]

initial_pose = { 219.13, -155.64, 0, 0 }

a1_real = { 224.37, 97.78, -90, 0 }
h1_real = { 226.67, -92.26, -90, 0 }
a8_real = { 413.05, 98.88, -90, 0 }
rotation_angle = -89.31
offsetX = -(h1_real[2] - a1_real[2]) / 7 -- board X is robot Y
offsetY = (a8_real[1] - a1_real[1]) / 7  -- board Y is robot X

captured_bottom_left = { 95.58, -238.95, -109.85, 0 }
captured_bottom_right = { -80.28, -238.94, -109.85, 0 }
captured_top_left = { 95.58, -264.26, -109.85, 0 }

print(string.format("OffsetX: %.2f, OffsetY: %.2f", offsetX, offsetY))

MovJ({ coordinate = a1_real })

function calculate_coordinates(row, col)
    -- Extract a1_real coordinates
    local x0, y0 = a1_real[1], a1_real[2]

    -- Convert rotation angle to radians
    local theta = math.rad(rotation_angle)

    -- Calculate the unrotated offsets
    local dx = col * offsetX
    local dy = row * offsetY

    -- Apply the rotation transformation
    local x = x0 + (dx * math.cos(theta)) - (dy * math.sin(theta))
    local y = y0 + (dx * math.sin(theta)) + (dy * math.cos(theta))

    return { x, y, a1_real[3], 0 }
end

for row = 0, 7 do
    for col = 0, 7 do
        -- Print the current row and column
        print(string.format("Moving to Row: %d, Column: %d", row, col))

        -- Calculate the coordinates for the current square
        local coord = calculate_coordinates(row, col)

        -- Move the robot to the calculated coordinates
        MovJ({ coordinate = coord })
        Sync()
    end
end
