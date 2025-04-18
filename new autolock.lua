-- LocalScript (Place in StarterPlayerScripts)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local lockedTarget = nil
local lockConnection = nil

-- Configuration
local LOCK_KEY = Enum.UserInputType.MouseButton2
local MAX_LOCK_DISTANCE = 150
local LOCK_FOV = math.rad(25) -- Tighter 25 degree cone
local HEAD_OFFSET = Vector3.new(0, 1.5, 0) -- Head position offset

local function getLocalCharacter()
    return player.Character
end

local function isValidTarget(target)
    return target and target:FindFirstChild("Head")
        and target:FindFirstChild("Humanoid")
        and target.Humanoid.Health > 0
        and (player.Team ~= target.Parent.Team or player.Neutral)
end

local function getHeadPosition(target)
    local head = target:FindFirstChild("Head")
    if head then
        return head.Position + HEAD_OFFSET
    end
    return nil
end

local function findBestTarget()
    local localChar = getLocalCharacter()
    if not localChar then return end
    
    local cameraCFrame = camera.CFrame
    local bestTarget = nil
    local bestScore = 0

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local targetChar = otherPlayer.Character
            if isValidTarget(targetChar) then
                local headPos = getHeadPosition(targetChar)
                if headPos then
                    local toTarget = headPos - cameraCFrame.Position
                    local distance = toTarget.Magnitude
                    
                    if distance <= MAX_LOCK_DISTANCE then
                        local direction = toTarget.Unit
                        local dot = cameraCFrame.LookVector:Dot(direction)
                        local angle = math.acos(dot)
                        
                        if angle < LOCK_FOV then
                            local score = (1 - distance/MAX_LOCK_DISTANCE) * dot
                            if score > bestScore then
                                bestTarget = targetChar
                                bestScore = score
                            end
                        end
                    end
                end
            end
        end
    end
    
    return bestTarget
end

local function updateLock()
    if not isValidTarget(lockedTarget) then
        lockedTarget = nil
        if lockConnection then
            lockConnection:Disconnect()
        end
        return
    end
    
    local headPos = getHeadPosition(lockedTarget)
    if headPos then
        local currentPos = camera.CFrame.Position
        camera.CFrame = CFrame.new(currentPos, headPos)
    end
end

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == LOCK_KEY then
        lockedTarget = findBestTarget()
        if lockedTarget then
            lockConnection = RunService.Heartbeat:Connect(updateLock)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == LOCK_KEY then
        lockedTarget = nil
        if lockConnection then
            lockConnection:Disconnect()
        end
    end
end)

player.CharacterAdded:Connect(function()
    lockedTarget = nil
    if lockConnection then
        lockConnection:Disconnect()
    end
end)
