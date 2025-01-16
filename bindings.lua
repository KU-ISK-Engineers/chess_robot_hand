ON = true
OFF = false

--- Represents the Cartesian coordinate system values for a specific point.
-- The coordinate includes X, Y, and Z axes for position and an R axis for rotation.
---@class Coordinate
---@field x number X-axis coordinate, representing the horizontal position of the point.
---@field y number Y-axis coordinate, representing the vertical position of the point.
---@field z number Z-axis coordinate, representing the depth position of the point.
---@field r number Rotation axis value, defining the orientation or angle of the point.


--- Represents the joint positions of a robot.
-- The joint positions define the specific configuration of the robot's joints.
---@class JointPoint
---@field joint JointCoordinates The joint positions, specified as angles or positions for J1 through J4.


--- Represents a Cartesian point in 3D space with associated tool and user coordinate systems.
-- The Cartesian point includes a `coordinate` field for position and orientation, 
-- and indices for the tool and user coordinate systems.
---@class CartesianPoint
---@field coordinate Coordinate The Cartesian coordinates of the point, consisting of X, Y, Z, and R axes values.
---@field tool number|nil Optional. Tool coordinate system index. Value range: 0-9. Specifies which tool coordinate system to use. Default: 0.
---@field user number|nil Optional. User coordinate system index. Value range: 0-9. Specifies which user-defined coordinate system to use. Default: 0.


--- Represents the coordinates of the robot's joints.
-- Each value corresponds to a specific joint in the robot's kinematic chain.
---@class JointCoordinates
---@field j1 number The position or angle of Joint 1.
---@field j2 number The position or angle of Joint 2.
---@field j3 number The position or angle of Joint 3.
---@field j4 number The position or angle of Joint 4.


--- Settings for point-to-point motion parameters such as speed, acceleration, and path continuity.
---@class MovementSettings
---@field CP number Continuous path rate. Controls motion smoothness. Value range: 0-100. Default: 1.
---| 0: Precise stopping at the target point.
---| 100: Smoothest motion without intermediate stops.
---@field SpeedJ number Velocity rate. Controls the motion speed. Value range: 1-100. Default: 50.
---@field AccJ number Acceleration rate. Controls the motion acceleration. Value range: 1-100. Default: 20.


--- Settings for linear motion parameters such as speed, acceleration, and path continuity.
---@class LinearMovementSettings
---@field CP number Continuous path rate. Controls motion smoothness. Value range: 0-100. Default: 1.
---| 0: Precise stopping at the target point.
---| 100: Smoothest motion without intermediate stops.
---@field SpeedL number Linear velocity rate. Controls the motion speed. Value range: 1-100. Default: 50.
---@field AccL number Linear acceleration rate. Controls the motion acceleration. Value range: 1-100. Default: 20.


--- Settings for jump motion parameters such as speed, acceleration, and height constraints.
---@class JumpSettings
---@field SpeedL number Velocity rate. Controls the motion speed. Value range: 1-100. Default: 50.
---@field AccL number Acceleration rate. Controls the motion acceleration. Value range: 1-100. Default: 20.
---@field Start number Lifting height (h1). The height at which the jump starts. Default: 10.
---@field ZLimit number Maximum lifting height (z_limit). The highest point of the jump. Default: 100.
---@field End number Dropping height (h2). The height at which the jump ends. Default: 20.


--- Performs a point-to-point movement to a specified Cartesian target point.
-- Moves the robot to the defined target point with optional motion parameters for speed, acceleration, and path continuity.
---@param P CartesianPoint The target Cartesian point. Must be user-defined or selected from a predefined points list.
---@param Option MovementSettings|nil Optional motion parameters. Defaults will be used if not provided.
function MovJ(P, Option)
end


--- Performs a linear movement to a specified Cartesian target point.
-- Moves the robot linearly to the defined target point with optional motion parameters for speed, acceleration, and path continuity.
---@param P CartesianPoint The target Cartesian point. Must be user-defined or selected from a predefined points list.
---@param Option LinearMovementSettings|nil Optional motion parameters. Defaults will be used if not provided.
function MovL(P, Option)
end


--- Performs a point-to-point movement to a specified joint target point.
-- Moves the robot to the defined joint point with optional motion parameters for speed, acceleration, and path continuity.
---@param P JointPoint The target joint point. Must be user-defined or selected from a predefined points list.
---@param Option MovementSettings|nil Optional motion parameters. Defaults will be used if not provided.
function JointMovJ(P, Option)
end


--- Performs a jump movement to a specified Cartesian target point.
-- Moves the robot with a jumping motion, allowing customization of speed, acceleration, and height parameters.
---@param P CartesianPoint The target Cartesian point. Must be user-defined or selected from a predefined points list.
---@param Option JumpSettings|nil Optional jump motion parameters. Defaults will be used if not provided.
function Jump(P, Option)
end


--- Performs a point-to-point movement to a specified Cartesian offset position.
-- Moves the robot relative to its current position using the specified Cartesian offsets and optional motion parameters.
---@param Offset Coordinate The Cartesian offset for the movement, defined as {OffsetX, OffsetY, OffsetZ, OffsetR}.
---@param Option MovementSettings|nil Optional motion parameters. Defaults will be used if not provided.
function RelMovJ(Offset, Option)
end


--- Performs a linear movement to a specified Cartesian offset position.
-- Moves the robot relative to its current position in a straight line using the specified Cartesian offsets and optional motion parameters.
---@param Offset Coordinate The Cartesian offset for the movement, defined as {OffsetX, OffsetY, OffsetZ, OffsetR}.
---@param Option LinearMovementSettings|nil Optional motion parameters. Defaults will be used if not provided.
function RelMovL(Offset, Option)
end


--- Performs an arc movement through a specified middle point and ending at a specified endpoint.
-- Moves the robot in an arc trajectory, combining with other commands to determine the starting point.
---@param P1 Coordinate The middle point of the arc. Must be user-defined or selected from a predefined points list.
---@param P2 Coordinate The endpoint of the arc. Must be user-defined or selected from a predefined points list.
---@param Option LinearMovementSettings|nil Optional motion parameters. Defaults will be used if not provided.
function Arc(P1, P2, Option)
end


--- Performs a circular movement based on the specified middle points and the number of circles.
-- Moves the robot in a circular trajectory through two middle points, combining with other commands to determine the starting point.
---@param P1 Coordinate The first middle point of the circle. Must be user-defined or selected from a predefined points list.
---@param P2 Coordinate The second middle point of the circle. Must be user-defined or selected from a predefined points list.
---@param Count number The number of circles to complete.
---@param Option LinearMovementSettings|nil Optional motion parameters. Defaults will be used if not provided.
function Circle(P1, P2, Count, Option)
end


--- Determines whether to stop at the current point in the robot's motion.
-- This function controls synchronization behavior during motion commands.
---@return boolean Returns `true` if synchronization is applied, otherwise `false`.
function Sync()
end


--- Gets the status of the digital input port(s).
-- Retrieves the ON/OFF status of a specified input port or all input ports in a table.
---@param Index number|nil (Optional) The digital input port to query.
--- - For MG400: Valid range is 1-18.
--- - For M1Pro: Valid range is 1-20.
---@return boolean|table Returns
-- - If `Index` is provided: Returns a boolean indicating the status (`true` for ON, `false` for OFF) of the specified input port.
-- - If `Index` is not provided: Returns a table containing the status of all input ports in the format:
--   `{num = number, value = {number}}`, where:
--     - `num`: Total number of ports.
--     - `value`: Table with status values for each port.
function DI(Index)
end


--- Sets the status of a digital output port (Queue command).
-- Enqueues a command to set the specified digital output port to the desired ON/OFF status.
---@param Index number The digital output port to set.
--- - For MG400: Valid range is 1-18.
--- - For M1Pro: Valid range is 1-20.
---@param Status boolean The desired status for the digital output port.
--- - `true`: Turn the port ON.
--- - `false`: Turn the port OFF.
function DO(Index, Status)
end


--- Sets the status of a digital output port (Immediate command).
-- Immediately sets the specified digital output port to the desired ON/OFF status, bypassing the command queue.
---@param Index number The digital output port to set.
--- - For MG400: Valid range is 1-18.
--- - For M1Pro: Valid range is 1-20.
---@param Status boolean The desired status for the digital output port.
--- - `true`: Turn the port ON.
--- - `false`: Turn the port OFF.
function DOInstant(Index, Status)
end


--- Gets the current pose of the robot in the Cartesian coordinate system.
-- Retrieves the Cartesian coordinates of the robot's current pose. If a User or Tool coordinate system is set, the pose is provided relative to the current User or Tool coordinate system.
---@return CartesianPoint Point The Cartesian coordinates of the robot's current pose.
function GetPose()
end


--- Gets the current pose of the robot in the Joint coordinate system.
-- Retrieves the joint angles or positions of the robot's current configuration.
---@return JointPoint Point The joint coordinates of the robot's current pose.
function GetAngle()
end


--- Sets the X, Y, Z, R axes offset in the Cartesian coordinate system and returns a new Cartesian coordinate point.
-- This function calculates a new Cartesian point by applying the specified offsets to the given Cartesian point.
-- The resulting point can be used in all motion commands except JointMovJ.
---@param P CartesianPoint The current Cartesian point, which is user-defined or obtained from the points list.
---@param Offset Coordinate The X, Y, Z, R axes offset in the Cartesian coordinate system.
---@return CartesianPoint Point The new Cartesian point after applying the offset.
function RelPoint(P, Offset)
end


--- Calculates a new joint point by applying offsets to the current joint point.
-- This function computes a new joint point by adding specified offsets to the J1, J2, J3, and J4 axes of a given joint point.
-- The resulting point can only be used in the JointMovJ command.
---@param P JointPoint The current joint point, which is user-defined or obtained from a predefined points list.
---@param Offset JointCoordinates The offset values for the J1, J2, J3, and J4 axes in the joint coordinate system.
---@return JointPoint Point The new joint point after applying the offsets.
function RelJoint(P, Offset)
end


---@class Socket


--- Creates a TCP network, supporting only a single connection.
-- This function establishes a TCP network as either a client or a server.
---@param IsServer boolean Specifies whether to create a server.
--- - `false`: Create a client.
--- - `true`: Create a server.
---@param IP string The IP address of the server. Must be in the same network segment as the client and must not conflict with other devices.
---@param Port number The port number for the server.
--- - If the robot is set as a server, the port cannot be `502` or `8080` to avoid conflicts with Modbus or conveyor tracking applications.
---@return number Err Error code indicating the result of the operation.
--- - `0`: TCP network created successfully.
--- - `1`: TCP network creation failed.
---@return Socket Socket The created socket object, which can be used for communication.
function TCPCreate(IsServer, IP, Port)
end


--- Establishes a TCP connection.
-- This function starts a TCP connection using the specified socket object and timeout settings.
---@param Socket Socket The socket object used to establish the connection.
---@param Timeout number The timeout duration in seconds.
--- - `0`: Wait indefinitely until the connection is established.
--- - `>0`: Exit the connection attempt after the specified timeout if unsuccessful.
---@return number Err Error code indicating the result of the operation.
--- - `0`: TCP connection is successful.
--- - `1`: Input parameters are incorrect.
--- - `2`: Socket object is not found.
--- - `3`: Timeout setting is incorrect.
--- - `4`: Connection or data error. For a client, indicates a connection error. For a server, indicates a data reception error.
function TCPStart(Socket, Timeout)
end


--- Reads data from a TCP connection.
-- The robot can receive data as a client from a server or as a server from a client.
---@param Socket Socket The socket object used for the TCP connection.
---@param Timeout number|nil The timeout duration for receiving data, in seconds.
--- - `0` or `nil`: Blocking read (program will wait indefinitely until data is received).
--- - `>0`: Non-blocking read. If the timeout is exceeded, the program continues regardless of receiving data.
---@param Type string|nil The buffer type for the received data.
--- - `nil`: The buffer format of `RecBuf` is a table.
--- - `"string"`: The buffer format of `RecBuf` is a string.
---@return number Err Error code indicating the result of the operation.
--- - `0`: Receiving data is successful.
--- - `1`: Receiving data failed.
---@return table|string|nil RecBuf The received data buffer.
--- - If `Type` is `nil`: Returns a table.
--- - If `Type` is `"string"`: Returns a string.
--- - Returns `nil` if an error occurs.
function TCPRead(Socket, Timeout, Type)
end


--- Sends data over a TCP connection.
-- The robot can send data as a client to a server or as a server to a client.
---@param Socket Socket The socket object used for the TCP connection.
---@param Buf string|table The data to send. Can be a string or a table containing the data to transmit.
---@param Timeout number|nil The timeout duration for sending data, in seconds.
--- - `0` or `nil`: Blocking mode. The program waits indefinitely until data is sent.
--- - `>0`: Non-blocking mode. The program continues after the timeout if data is not sent.
---@return number Err Error code indicating the result of the operation.
--- - `0`: Sending data is successful.
--- - `1`: Sending data failed.
function TCPWrite(Socket, Buf, Timeout)
end


--- Releases a TCP network.
-- This function closes and releases the specified TCP socket.
---@param Socket Socket The socket object to release.
---@return number Err Error code indicating the result of the operation.
--- - `0`: Releasing TCP is successful.
--- - `1`: Releasing TCP is failed.
function TCPDestroy(Socket)
end


--- Sets a delay for robot motion commands.
-- Pauses the execution of robot motion commands for the specified delay time.
---@param time number The delay duration in milliseconds.
function Wait(time)
end


--- Sets a delay for all commands.
-- Pauses the execution of all commands for the specified delay time.
---@param time number The delay duration in milliseconds.
---@return nil This function does not return a value.
function Sleep(time)
end
