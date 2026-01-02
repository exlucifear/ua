--[[ 
WASD Spiral Assist (Single File)
Semi-auto movement assist for spiral ladder obby
Author: ChatGPT
--]]

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- PLAYER
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

-- =========================
-- UI (SIMPLE)
-- =========================
local gui = Instance.new("ScreenGui")
gui.Name = "WASD_Assist_UI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 110)
frame.Position = UDim2.new(0, 20, 0.5, -55)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,28)
title.Text = "WASD Assist"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1

local toggle = Instance.new("TextButton", frame)
toggle.Size = UDim2.new(1,-20,0,30)
toggle.Position = UDim2.new(0,10,0,36)
toggle.Text = "OFF"
toggle.TextColor3 = Color3.new(1,1,1)
toggle.BackgroundColor3 = Color3.fromRGB(180,60,60)

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1,-20,0,24)
status.Position = UDim2.new(0,10,0,74)
status.Text = "Status: Idle"
status.Font = Enum.Font.SourceSans
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(220,220,220)
status.BackgroundTransparency = 1
status.TextXAlignment = Enum.TextXAlignment.Left

-- =========================
-- STATE
-- =========================
local ENABLE = false
local STATE = "DISABLED" -- DISABLED | SCAN | READY | JUMP | LAND | PAUSED

local pattern = nil
local index = 1
local lastPos = nil

-- =========================
-- HELPERS
-- =========================
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function isLanded()
	return humanoid.FloorMaterial ~= Enum.Material.Air
end

local function isFalling()
	return root.Velocity.Y < -5
end

local function ray(params, origin, dir)
	return workspace:Raycast(origin, dir, params)
end

local function hasGroundBelow()
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Blacklist
	return ray(params, root.Position, Vector3.new(0,-4,0))
end

-- align character to camera (shiftlock-style)
local function alignToCamera()
	local look = flat(cam.CFrame.LookVector)
	if look.Magnitude > 0 then
		root.CFrame = CFrame.new(root.Position, root.Position + look.Unit)
	end
end

-- camera-relative WASD vectors
local function getMoveVector(key)
	local f = flat(cam.CFrame.LookVector).Unit
	local r = flat(cam.CFrame.RightVector).Unit
	if key == "W" then return f end
	if key == "S" then return -f end
	if key == "A" then return -r end
	if key == "D" then return r end
end

-- check next step exists (diagonal up)
local function hasNextStep(moveVec)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Blacklist
	local dir = moveVec.Unit * 3 + Vector3.new(0,3,0)
	return ray(params, root.Position, dir)
end

-- detect spiral direction (LEFT / RIGHT)
local function detectSpiral()
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Blacklist

	local f = flat(cam.CFrame.LookVector).Unit
	local r = flat(cam.CFrame.RightVector).Unit

	local leftDir  = (f*2) - (r*1) + Vector3.new(0,3,0)
	local rightDir = (f*2) + (r*1) + Vector3.new(0,3,0)

	local lh = ray(params, root.Position, leftDir)
	local rh = ray(params, root.Position, rightDir)

	if lh and not rh then return "LEFT" end
	if rh and not lh then return "RIGHT" end
	if lh and rh then
		if (lh.Position-root.Position).Magnitude < (rh.Position-root.Position).Magnitude then
			return "LEFT"
		else
			return "RIGHT"
		end
	end
	return nil
end

local function patternFromSpiral(dir)
	if dir == "LEFT" then
		return {"W","A","S","D"}
	elseif dir == "RIGHT" then
		return {"W","D","S","A"}
	end
end

-- adaptive correction
local function adaptiveFix()
	if not lastPos then return nil end
	local delta = root.Position - lastPos
	local r = flat(cam.CFrame.RightVector).Unit
	local lateral = delta:Dot(r)
	if lateral > 0.6 then return "A" end   -- terlalu kanan, koreksi kiri
	if lateral < -0.6 then return "D" end  -- terlalu kiri, koreksi kanan
	return nil
end

-- =========================
-- UI EVENTS
-- =========================
toggle.MouseButton1Click:Connect(function()
	ENABLE = not ENABLE
	toggle.Text = ENABLE and "ON" or "OFF"
	toggle.BackgroundColor3 = ENABLE and Color3.fromRGB(60,180,90) or Color3.fromRGB(180,60,60)
	STATE = ENABLE and "SCAN" or "DISABLED"
	status.Text = ENABLE and "Status: Scan" or "Status: Idle"
end)

-- =========================
-- MAIN LOOP
-- =========================
RunService.Heartbeat:Connect(function()
	if STATE == "DISABLED" then return end

	if STATE == "SCAN" then
		local dir = detectSpiral()
		if not dir then
			ENABLE = false
			STATE = "DISABLED"
			status.Text = "Status: Scan Failed"
			return
		end
		pattern = patternFromSpiral(dir)
		index = 1
		STATE = "READY"
		status.Text = "Status: Ready ("..dir..")"
		return
	end

	if STATE == "PAUSED" then
		if isLanded() and hasGroundBelow() then
			STATE = "READY"
			status.Text = "Status: Ready"
		end
		return
	end

	if STATE == "READY" then
		if isFalling() or not hasGroundBelow() then
			STATE = "PAUSED"
			status.Text = "Status: Paused"
			return
		end
		if not isLanded() then return end
		STATE = "JUMP"
	end

	if STATE == "JUMP" then
		alignToCamera()

		local key = adaptiveFix() or pattern[index]
		if not adaptiveFix() then
			index = index % #pattern + 1
		end

		local mv = getMoveVector(key)
		if not mv or not hasNextStep(mv) then
			ENABLE = false
			STATE = "DISABLED"
			status.Text = "Status: Stopped"
			return
		end

		lastPos = root.Position
		humanoid.Jump = true
		humanoid:Move(mv, false)
		STATE = "LAND"
	end

	if STATE == "LAND" then
		if isFalling() then
			STATE = "PAUSED"
			status.Text = "Status: Paused"
			return
		end
		if isLanded() then
			STATE = "READY"
			status.Text = "Status: Ready"
		end
	end
end)
