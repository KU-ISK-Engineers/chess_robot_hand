---@alias Point2D {[1]: number, [2]: number}

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

local squareA1 = {224.37, 97.78}
local boardRotRad = -1.5586942024430779
local boardSquareDist = {27.15055965898159, 26.954213572955865}
local transformBoard = transform2d(squareA1, boardSquareDist, boardRotRad)

local boardSquares = {
    transformBoard(0, 0, {0, 0}),
    transformBoard(0, 7, {0, 0}),
    transformBoard(7, 0, {0, 0}),
    transformBoard(7, 7, {0, 0}),
}

local boardCorners = {
    transformBoard(0, 0, {-1, -1}),
    transformBoard(0, 7, {1, -1}),
    transformBoard(7, 0, {-1, 1}),
    transformBoard(7, 7, {1, 1}),
}

print(boardSquares[1][1], boardSquares[1][2])
print(boardSquares[2][1], boardSquares[2][2])
print(boardSquares[3][1], boardSquares[3][2])
print(boardSquares[4][1], boardSquares[4][2])

print("\n---------------------------\n")

print(boardCorners[1][1], boardCorners[1][2])
print(boardCorners[2][1], boardCorners[2][2])
print(boardCorners[3][1], boardCorners[3][2])
print(boardCorners[4][1], boardCorners[4][2])

local reserveSquareA1 = {95.58, -238.95}
local reserveSquareDist = {-25.0, -25.0}
local transformReserve = transform2d(reserveSquareA1, reserveSquareDist, 0)

local benchSquares = {
    transformReserve(0, 0, {0, 0}),
    transformReserve(0, 7, {0, 0}),
    transformReserve(1, 0, {0, 0}),
    transformReserve(1, 7, {0, 0}),
}

print("\n---------------------------\n")

print(benchSquares[1][1], benchSquares[1][2])
print(benchSquares[2][1], benchSquares[2][2])
print(benchSquares[3][1], benchSquares[3][2])
print(benchSquares[4][1], benchSquares[4][2])