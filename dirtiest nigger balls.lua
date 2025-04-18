-- LocalScript (Place in StarterPlayerScripts)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local lockedTarget = nil

-- 1. REQUIRED INITIALIZATION
camera.CameraType = Enum.CameraType.Scriptable

-- 2. CONFIGURATION
local LOCK_ANGLE = math.cos(math.rad(15)) -- 15 degree cone
local HEAD_OFFSET = Vector3.new(0, 1.5, 0)

-- 3. VALIDATION FUNCTIONS
local function isEnemy(otherPlayer)
    -- Team check logic
    return player.Neutral 
        or otherPlayer.Neutral 
        or otherPlayer.Team ~= player.Team
end

local function isValidTarget(targetChar, otherPlayer)
    if not targetChar then return false end
    local humanoid = targetChar:FindFirstChild("Humanoid")
    return humanoid 
        and humanoid.Health > 0
        and isEnemy(otherPlayer)
end

-- 4. TARGET ACQUISITION
local function getHeadPosition(targetChar)
    local head = targetChar:FindFirstChild("Head")
    return head and (head.Position + HEAD_OFFSET)
end

local function findTarget()
    if not player.Character then return end
    local localHead = player.Character:FindFirstChild("Head")
    if not localHead then return end

    local cameraPos = camera.CFrame.Position
    local cameraLook = camera.CFrame.LookVector

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and isEnemy(otherPlayer) then
            local targetChar = otherPlayer.Character
            if isValidTarget(targetChar, otherPlayer) then
                local headPos = getHeadPosition(targetChar)
                if headPos then
                    local toTarget = (headPos - cameraPos).Unit
                    local dot = cameraLook:Dot(toTarget)
                    
                    -- 15 degree cone check
                    if dot > LOCK_ANGLE then
                        return targetChar
                    end
                end
            end
        end
    end
end

-- 5. LOCKING SYSTEM
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        lockedTarget = findTarget()
        
        if lockedTarget then
            RunService:BindToRenderStep("AimLock", Enum.RenderPriority.Camera.Value, function()
                if not isValidTarget(lockedTarget, Players:GetPlayerFromCharacter(lockedTarget)) then
                    RunService:UnbindFromRenderStep("AimLock")
                    lockedTarget = nil
                    return
                end
                
                local headPos = getHeadPosition(lockedTarget)
                if headPos then
                    camera.CFrame = CFrame.new(camera.CFrame.Position, headPos)
                end
            end)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        RunService:UnbindFromRenderStep("AimLock")
        lockedTarget = nil
    end
end)
