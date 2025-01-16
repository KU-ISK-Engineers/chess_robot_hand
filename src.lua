-- Version: Lua 5.3.5
-- Dobot MG400 lua code for receiving chess piece cordinates via tcp protocol and moving it from given
-- coordinate to next palce where it has to go 
X=415.23
Y=-90.82
Z=-109.5
R=0

cords_offset = 27

Y1_storage = -242.45
Y2_storage = -267.0
R_storage = -90
Z_storage = -112.7

main_pose = {297,-70,-50,R}
main_pose2 = {200,-235,-50,R}

original_pieces = {
    [-6] = {name = "friendly pawn", var = 0, max_count = 8, 
            cords = {
            {97.60, Y1_storage, Z_storage, R_storage},
            {71.33, Y1_storage, Z_storage, R_storage},
            {46.16, Y1_storage, Z_storage, R_storage},
            {20.31, Y1_storage, Z_storage, R_storage},
            {-5.62, Y1_storage, Z_storage, R_storage},
            {-31.25, Y1_storage, Z_storage, R_storage},
            {-54.06, Y1_storage, Z_storage, R_storage},
            {-79.89, Y1_storage, Z_storage, R_storage}}},
    [-1] = {name = "friendly rook", var = 0, max_count = 2, 
            cords = {
            {97.60, Y2_storage, Z_storage, R_storage},
            {-79.89, Y2_storage, Z_storage, R_storage}}},
    [-3] = {name = "friendly knight", var = 0, max_count = 2, 
            cords = {
            {71.33, Y2_storage, Z_storage, R_storage},
            {-52.06, Y2_storage, Z_storage, R_storage}}},
    [-2] = {name = "friendly bishop", var = 0, max_count = 2, 
            cords = {
            {46.16, Y2_storage, Z_storage, R_storage},
            {-31.25, Y2_storage, Z_storage, R_storage}}},
    [-4] = {name = "friendly queen", var = 0, max_count = 1, 
            cords = {
            {20.31, Y2_storage, Z_storage, R_storage}}},
    [-5] = {name = "friendly king", var = 0, max_count = 1, 
            cords = {
            {-5.62, Y2_storage, Z_storage, R_storage}}},
    [-12] = {name = "enemy pawn", var = 0, max_count = 8, 
            cords = {
            {328.40, Y1_storage, Z_storage, R_storage},
            {303.40, Y1_storage, Z_storage, R_storage},
            {278.40, Y1_storage, Z_storage, R_storage},
            {253.40, Y1_storage, Z_storage, R_storage},
            {228.40, Y1_storage, Z_storage, R_storage},
            {203.40, Y1_storage, Z_storage, R_storage},
            {178.40, Y1_storage, Z_storage, R_storage},
            {153.40, Y1_storage, Z_storage, R_storage}}},
    [-7] = {name = "enemy rook", var = 0, max_count = 2, 
            cords = {
            {328.40, Y2_storage, Z_storage, R_storage},
            {153.40, Y2_storage, Z_storage, R_storage}}},
    [-9] = {name = "enemy knight", var = 0, max_count = 2, 
            cords = {
            {303.40, Y2_storage, Z_storage, R_storage},
            {178.40, Y2_storage, Z_storage, R_storage}}},
    [-8] = {name = "enemy bishop", var = 0, max_count = 2, 
            cords = {
            {278.40, Y2_storage, Z_storage, R_storage},
            {203.40, Y2_storage, Z_storage, R_storage}}},
    [-10] = {name = "enemy queen", var = 0, max_count = 1, 
            cords = {
            {253.40, Y2_storage, Z_storage, R_storage}}},
    [-11] = {name = "enemy king", var = 0, max_count = 1, 
            cords = {
            {228.40, Y2_storage, Z_storage, R_storage}}}}

-- Make a deep copy of the original pieces to allow for resetting
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

pieces = deepcopy(original_pieces)

function splitString(inputstr, sep)
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

-- Function to parse the input string into integers
function parseInput(input)
    local numbers = splitString(input, " ")
    local int1, int2, int3, int4 = tonumber(numbers[1]), tonumber(numbers[2]), tonumber(numbers[3]), tonumber(numbers[4])
    return int1, int2, int3, int4
end

function read_tcp_command(socket1)
    resultCreate1 = TCPStart(socket1, 0)
    if resultCreate1 == 0 then
      print("Listen TCP Client Success!")
    else
      print("Listen TCP Client failed, code:", resultCreate1)
    end
    
    local feedback = "Klaipedos_Universitetas"
    
    --TCPWrite(socket1, feedback, 0)
    --turn tcp on
    Sync()
    print('created')
    Sync()
    print((resultCreate1))
    Sync()
    
    local command = nil  
    while (command == nil) do
        resultRead1,command = TCPRead(socket1, 0,'string')
    end
    command = command.buf
    return command, socket1
end

function send_tcp_command(socket1)
    Sync()
    print('created')
    Sync()
    print((resultCreate1))
    Sync()
    command = "success"
    err = TCPWrite(socket1, command, 0)
    if err == 0 then
        print("TCP command sent success!")
    else
        print("TCP command failed to send, code:", err)
    end
end
-- kordiantes skaiciavimas
local function find_cordinate(n,way, off_x, off_y)
    local n1=0
    local x_temp=0
    local y_temp=0
    if (n>=0) then  --skaiciuoja kordinate lentoje
        while(n1<n)
        do
        y_temp=y_temp+1
        --print(y_temp)
        if (y_temp==8)
        then
            x_temp=x_temp+1
            y_temp=0
            --print(x_temp)
        end
        n1=n1+1
        end
        print("off_x:", off_x)
        print("off_y:", off_y)
        
        local off_X = (((off_x / 100) * 10))
        local off_Y = (((off_y / 100) * 10) * (-1))
        
        print("OFF_X:", off_X)
        print("OFF_Y:", off_Y)
        
        local x=(X - (x_temp * cords_offset) + off_X)
        local y=(Y + (y_temp * cords_offset) + off_Y)
        
        --print(string.format("y: %d , x: %d", y_temp, x_temp))
        cordinates = {x,y,Z,R}
    end
    if (n<0) then  -- skaiciuoja kodrinate storage srityje
        local piece = "null"
        function update_piece(piece_info)
          local piece_var = piece_info.var
          print("piece_var: ", piece_var)
          Sync()
          if (way == 1 and piece_var > 0) then
            piece_info.var = piece_var - 1
            print("to")
            -- coordinates to it
            return piece_info.cords[piece_info.var]
          elseif (way == 2 and piece_var < piece_info.max_count) then 
            piece_info.var = piece_var + 1
            print("from")
            -- coordinates to pick up
            return piece_info.cords[piece_info.var]
          else
            print("Invalid Move")
            return  nil
          end
        end
        -- Check if the piece type exists in the table and update accordingly
        local piece_info = pieces[n]
        --print("piece info: ", piece_info)
        if piece_info then
        cordinates = update_piece(piece_info)
        piece = piece_info.name
        end
    end
    return cordinates
end

local function move_ptp(from,to)
    local Option={SpeedL=50, AccL=20, Start=10, ZLimit=30, End=50}
    Jump({coordinate = from, sync = true}, Option)
    Sync()
    DO(8,ON)
    Sync()
    Jump({coordinate = main_pose, sync = true}, Option)
    Sync()
    Jump({coordinate = to, sync = true}, Option)
    Sync()
    DO(8,OFF)
    print("move done")
end
local function reset_pieces()
    pieces = deepcopy(original_pieces)
    print("Pieces table has been reset to original configuration.")
end

-- main program function
local function main()
  resultCreate1, socket1 = TCPCreate(true, "192.168.1.6", 6001)
  if resultCreate1 == 0 then
    print("Create TCP Server Success!")
  else
      print("Create TCP Server failed, code:", resultCreate1)
  end  
  while (true) do
    ::continue::
    local Option={SpeedL=50, AccL=20, Start=10, ZLimit=30, End=50}
    Jump({coordinate = main_pose2, sync = true}, Option)
    local input, socket1 = read_tcp_command(socket1);
    print("input: ", input)
    if input == "99 99 99 99" then
        reset_pieces()
        send_tcp_command(socket1)
        goto continue
    end
    local from, off_y, off_x, to = parseInput(input)
    if (from ~= nil and to ~= nil) then
        print(string.format("From: %d, off_x: %d, off_y: %d, to: %d", from, off_x, off_y, to))
        local cords1 = find_cordinate(from, 1, off_x, off_y)
        Sync()
        local cords2 = find_cordinate(to, 2, 0, 0)
        if (cords1 == nil) then
          local command_err = "invalid"
          err = TCPWrite(socket1, command_err, 0)
          if err == 0 then
            print("TCP command sent success!")
          else
            print("TCP command failed to send, code:", err)
          end
          goto continue
        end
        if (cords2 == nil) then
          local command_err = "invalid"
          err = TCPWrite(socket1, command_err, 0)
          if err == 0 then
            print("TCP command sent success!")
          else
            print("TCP command failed to send, code:", err)
          end
          goto continue
        end
        Sync()
        print(cords2)
        move_ptp(cords1,cords2)
        Sleep(500)
        send_tcp_command(socket1)
    end
  end
  TCPDestroy(socket1)
end

main()