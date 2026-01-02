-- =========================================
-- AUTO WASD SPIRAL LADDER ASSIST (NO SCAN)
-- Stable & Simple
-- =========================================

-- SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- CHARACTER
local function getChar()
    local c = player.Character or player.CharacterAdded:Wait()
    return c, c:WaitForChild("Humanoid"), c:WaitForChild("HumanoidRootPart")
end

local char, hum, hrp = getChar()

-- CONFIG
local JUMP_DELAY = 0.28
local UP_CHECK = 6

-- STATE
local ENABLE = false
local STATE = "IDLE" -- RUN | PAUSE
local stepIndex = 1
local lastJump = 0

-- PATTERN
local PATTERN = {
    CW  = {"W","D","S","A"},
    CCW = {"W","A","S","D"}
}
local ACTIVE_MODE = "CW"

-- INPUT MAP
local keyMap = {
    W = Enum.KeyCode.W,
    A = Enum.KeyCode.A,
    S = Enum.KeyCode.S,
    D = Enum.KeyCode.D
}

-- UI ======================================
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "SpiralAssistUI_NoScan"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(220, 150)
frame.Position = UDim2.fromScale(0.03, 0.4)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.Text = "Spiral WASD Assist"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local status = Instance.new("TextLabel", frame)
status.Position = UDim2.fromOffset(0,30)
status.Size = UDim2.new(1,0,0,25)
status.Text = "Status: Idle"
status.TextColor3 = Color3.fromRGB(200,200,200)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 12

local modeBtn = Instance.new("TextButton", frame)
modeBtn.Position = UDim2.fromOffset(20,60)
modeBtn.Size = UDim2.fromOffset(180,28)
modeBtn.Text = "Mode: CW"
modeBtn.Font = Enum.Font.Gotham
modeBtn.TextSize = 12
modeBtn.TextColor3 = Color3.new(1,1,1)
modeBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
modeBtn.BorderSizePixel = 0
Instance.new("UICorner", modeBtn)

local toggle = Instance.new("TextButton", frame)
toggle.Position = UDim2.fromOffset(20,95)
toggle.Size = UDim2.fromOffset(180,35)
toggle.Text = "OFF"
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 14
toggle.TextColor3 = Color3.new(1,1,1)
toggle.BackgroundColor3 = Color3.fromRGB(180,60,60)
toggle.BorderSizePixel = 0
Instance.new("UICorner", toggle)

-- MODE SWITCH ==============================
modeBtn.MouseButton1Click:Connect(function()
    ACTIVE_MODE = ACTIVE_MODE == "CW" and "CCW" or "CW"
    modeBtn.Text = "Mode: "..ACTIVE_MODE
end)

-- RAYCAST UP ==============================
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.IgnoreWater = true

local function hasStepAbove()
    rayParams.FilterDescendantsInstances = {char}
    local result = workspace:Raycast(
        hrp.Position,
        Vector3.new(0, UP_CHECK, 0),
        rayParams
    )
    return result ~= nil
end

-- MOVE ====================================
local function stepMove(key)
    local kc = keyMap[key]
    if not kc then return end

    UIS:SendInputBegin(kc)
    task.wait(0.05)
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
    task.wait(0.05)
    UIS:SendInputEnd(kc)
end

-- TOGGLE ==================================
toggle.MouseButton1Click:Connect(function()
    ENABLE = not ENABLE

    if ENABLE then
        STATE = "RUN"
        toggle.Text = "ON"
        toggle.BackgroundColor3 = Color3.fromRGB(60,180,90)
        status.Text = "Status: Running ("..ACTIVE_MODE..")"
    else
        STATE = "IDLE"
        toggle.Text = "OFF"
        toggle.BackgroundColor3 = Color3.fromRGB(180,60,60)
        status.Text = "Status: Idle"
    end
end)

-- MAIN LOOP ===============================
RunService.Heartbeat:Connect(function()
    if not ENABLE then return end
    if hum.Health <= 0 then return end

    if STATE == "RUN" then
        if tick() - lastJump < JUMP_DELAY then return end
        lastJump = tick()

        if not hasStepAbove() then
            STATE = "PAUSE"
            status.Text = "Status: Paused (No Step)"
            return
        end

        local pattern = PATTERN[ACTIVE_MODE]
        stepMove(pattern[stepIndex])
        stepIndex = stepIndex % #pattern + 1
    end

    if STATE == "PAUSE" then
        if hasStepAbove() then
            STATE = "RUN"
            status.Text = "Status: Running ("..ACTIVE_MODE..")"
        end
    end
end)
