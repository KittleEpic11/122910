-- LocalScript (MUST be in StarterPlayerScripts)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local lockedTarget = nil
local lockHighlight = nil

-- Configuration
local MAX_LOCK_DISTANCE = 10000
local LOCK_ANGLE_THRESHOLD = math.cos(math.rad(30)) -- 30 degree cone

-- Set camera to be controllable
camera.CameraType = Enum.CameraType.Scriptable

local function getLocalRoot()
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function isValidTarget(target)
    return target and target:IsDescendantOf(workspace) 
        and target:FindFirstChild("HumanoidRootPart")
        and target.Humanoid.Health > 0
end

local function findNearestEnemy()
    local localRoot = getLocalRoot()
    if not localRoot then return end

    local bestTarget = nil
    local bestScore = 0
    local localPosition = localRoot.Position
    local localCFrame = localRoot.CFrame

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and (player.Neutral or otherPlayer.Neutral or otherPlayer.Team ~= player.Team) then
            local character = otherPlayer.Character
            if isValidTarget(character) then
                local targetRoot = character.HumanoidRootPart
                local toTarget = targetRoot.Position - localPosition
                local distance = toTarget.Magnitude
                
                if distance <= MAX_LOCK_DISTANCE then
                    local direction = toTarget.Unit
                    local viewAngle = localCFrame.LookVector:Dot(direction)
                    
                    -- Prioritize targets in view direction
                    local score = viewAngle * (1 - distance/MAX_LOCK_DISTANCE)
                    
                    if viewAngle > LOCK_ANGLE_THRESHOLD and score > bestScore then
                        bestTarget = character
                        bestScore = score
                    end
                end
            end
        end
    end
    
    return bestTarget
end

local function updateLock()
    if not lockedTarget or not isValidTarget(lockedTarget) then
        if lockHighlight then
            lockHighlight:Destroy()
            lockHighlight = nil
        end
        lockedTarget = nil
        return
    end

    -- Smooth camera follow
    local targetPosition = lockedTarget.HumanoidRootPart.Position
    local currentPosition = camera.CFrame.Position
    camera.CFrame = CFrame.new(currentPosition, targetPosition)
    
    -- Update highlight
    if not lockHighlight then
        lockHighlight = Instance.new("Highlight")
        lockHighlight.FillColor = Color3.new(1, 0, 0)
        lockHighlight.OutlineColor = Color3.new(1, 1, 0)
        lockHighlight.Parent = lockedTarget
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and not gameProcessed then
        lockedTarget = findNearestEnemy()
        if lockedTarget then
            RunService:BindToRenderStep("LockOnUpdate", Enum.RenderPriority.Camera.Value, updateLock)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        RunService:UnbindFromRenderStep("LockOnUpdate")
        if lockHighlight then
            lockHighlight:Destroy()
            lockHighlight = nil
        end
        lockedTarget = nil
    end
end)

-- Reset when character changes
player.CharacterAdded:Connect(function()
    lockedTarget = nil
    if lockHighlight then
        lockHighlight:Destroy()
        lockHighlight = nil
    end
end)
