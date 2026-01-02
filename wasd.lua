-- =========================================
-- AUTO WASD SPIRAL LADDER ASSIST (FINAL)
-- Single File - Stable Version
-- =========================================

-- SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- CHARACTER
local function getChar()
    local c = player.Character or player.CharacterAdded:Wait()
    return c, c:WaitForChild("Humanoid"), c:WaitForChild("HumanoidRootPart")
end

local char, hum, hrp = getChar()

-- STATE
local ENABLE = false
local STATE = "DISABLED" -- SCAN | READY | JUMP | PAUSED
local stepIndex = 1
local spiralDir = nil
local lastJump = 0

-- CONFIG
local JUMP_DELAY = 0.28
local SCAN_DISTANCE = 6
local UP_CHECK = 7

-- WASD PATTERN
local PATTERN_CW  = {"W","D","S","A"}
local PATTERN_CCW = {"W","A","S","D"}
local activePattern = nil

-- INPUT MAP
local keyMap = {
    W = Enum.KeyCode.W,
    A = Enum.KeyCode.A,
    S = Enum.KeyCode.S,
    D = Enum.KeyCode.D
}

-- UI ======================================
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "SpiralAssistUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(220, 120)
frame.Position = UDim2.fromScale(0.03, 0.4)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0,12)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.Text = "Spiral WASD Assist"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local status = Instance.new("TextLabel", frame)
status.Position = UDim2.fromOffset(0,30)
status.Size = UDim2.new(1,0,0,30)
status.Text = "Status: Idle"
status.TextColor3 = Color3.fromRGB(200,200,200)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 12

local toggle = Instance.new("TextButton", frame)
toggle.Position = UDim2.fromOffset(20,70)
toggle.Size = UDim2.fromOffset(180,35)
toggle.Text = "OFF"
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 14
toggle.TextColor3 = Color3.new(1,1,1)
toggle.BackgroundColor3 = Color3.fromRGB(180,60,60)
toggle.BorderSizePixel = 0
Instance.new("UICorner", toggle)

-- RAYCAST =================================
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.IgnoreWater = true

local function cast(dir, dist)
    rayParams.FilterDescendantsInstances = {char}
    return workspace:Raycast(hrp.Position, dir.Unit * dist, rayParams)
end

-- DETECT SPIRAL DIRECTION ==================
local function detectSpiral()
    local right = cam.CFrame.RightVector
    local left  = -right

    local hitR = cast(right, SCAN_DISTANCE)
    local hitL = cast(left, SCAN_DISTANCE)

    if hitR and not hitL then return "CW" end
    if hitL and not hitR then return "CCW" end
    return nil
end

-- CHECK STEP ABOVE =========================
local function hasStepAbove()
    local up = Vector3.new(0, UP_CHECK, 0)
    return cast(up, UP_CHECK) ~= nil
end

-- PRESS KEY + JUMP =========================
local function stepMove(key)
    local kc = keyMap[key]
    if not kc then return end

    UIS:SendInputBegin(kc)
    task.wait(0.05)
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
    task.wait(0.05)
    UIS:SendInputEnd(kc)
end

-- TOGGLE ===================================
toggle.MouseButton1Click:Connect(function()
    ENABLE = not ENABLE

    if ENABLE then
        STATE = "SCAN"
        toggle.Text = "ON"
        toggle.BackgroundColor3 = Color3.fromRGB(60,180,90)
        status.Text = "Status: Scanning..."
    else
        STATE = "DISABLED"
        toggle.Text = "OFF"
        toggle.BackgroundColor3 = Color3.fromRGB(180,60,60)
        status.Text = "Status: Idle"
    end
end)

-- MAIN LOOP ================================
RunService.Heartbeat:Connect(function()
    if not ENABLE then return end
    if not char or hum.Health <= 0 then return end

    -- SCAN MODE
    if STATE == "SCAN" then
        spiralDir = detectSpiral()
        if spiralDir then
            activePattern = spiralDir == "CW" and PATTERN_CW or PATTERN_CCW
            stepIndex = 1
            STATE = "READY"
            status.Text = "Status: Ready ("..spiralDir..")"
        end
        return
    end

    -- READY → JUMP
    if STATE == "READY" then
        if hasStepAbove() then
            STATE = "JUMP"
        else
            STATE = "PAUSED"
            status.Text = "Status: Waiting Step"
        end
        return
    end

    -- PAUSED → AUTO RESCAN
    if STATE == "PAUSED" then
        if hasStepAbove() then
            STATE = "JUMP"
            status.Text = "Status: Resume"
        else
            STATE = "SCAN"
            status.Text = "Status: Re-Scan"
        end
        return
    end

    -- JUMP LOOP
    if STATE == "JUMP" then
        if tick() - lastJump < JUMP_DELAY then return end
        lastJump = tick()

        if not hasStepAbove() then
            STATE = "PAUSED"
            status.Text = "Status: No Step"
            return
        end

        stepMove(activePattern[stepIndex])
        stepIndex = stepIndex % #activePattern + 1
    end
end)
