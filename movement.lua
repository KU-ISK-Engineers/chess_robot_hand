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