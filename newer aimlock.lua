-- LocalScript (Must be in StarterPlayerScripts)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local lockedTarget = nil

-- Debug configuration
local DEBUG_MODE = true
local MAX_DEBUG_DISTANCE = 10000

-- Configuration
local LOCK_KEY = Enum.UserInputType.MouseButton2
local LOCK_DISTANCE = 10000
local LOCK_FOV = math.rad(30)
local HEAD_OFFSET = Vector3.new(0, 1.5, 0)

-- Debug functions
local function debugPrint(message)
    if DEBUG_MODE then
        print("[Aimlock] " .. message)
    end
end

local function createDebugMarker(position)
    if not DEBUG_MODE then return end
    
    local marker = Instance.new("Part")
    marker.Shape = Enum.PartType.Ball
    marker.Size = Vector3.new(0.5, 0.5, 0.5)
    marker.Color = Color3.new(1, 0, 0)
    marker.Position = position
    marker.Anchored = true
    marker.CanCollide = false
    marker.Parent = workspace
    game.Debris:AddItem(marker, 2)
end

-- Core functions
local function validateTarget(target)
    if not target then
        debugPrint("Invalid target: nil")
        return false
    end
    
    local humanoid = target:FindFirstChild("Humanoid")
    local head = target:FindFirstChild("Head")
    
    local valid = humanoid 
        and humanoid.Health > 0
        and head
        and (player.Team ~= target.Parent.Team or player.Neutral)
    
    debugPrint("Target validation: " .. tostring(valid))
    return valid
end

local function findHeadPosition(target)
    local head = target:FindFirstChild("Head")
    return head and (head.Position + HEAD_OFFSET) or nil
end

local function getBestTarget()
    local localRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then
        debugPrint("No local root part")
        return nil
    end

    local bestTarget = nil
    local bestScore = 0
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer == player then continue end
        
        local character = otherPlayer.Character
        if not validateTarget(character) then continue end
        
        local headPos = findHeadPosition(character)
        if not headPos then continue end
        
        local distance = (headPos - localRoot.Position).Magnitude
        if distance > LOCK_DISTANCE then
            debugPrint("Target out of range: " .. distance)
            continue
        end

        local viewVector = (headPos - camera.CFrame.Position).Unit
        local dot = camera.CFrame.LookVector:Dot(viewVector)
        local angle = math.deg(math.acos(dot))
        
        if DEBUG_MODE then
            createDebugMarker(headPos)
            debugPrint(("Checking %s | Distance: %.1f | Angle: %.1f°"):format(
                otherPlayer.Name, distance, angle
            ))
        end

        if angle < LOCK_FOV then
            local score = (1 - distance/LOCK_DISTANCE) * dot
            if score > bestScore then
                bestScore = score
                bestTarget = character
            end
        end
    end

    debugPrint("Best target: " .. (bestTarget and bestTarget.Parent.Name or "None"))
    return bestTarget
end

-- Input handling
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == LOCK_KEY then
        debugPrint("Lock key pressed")
        lockedTarget = getBestTarget()
        
        if lockedTarget then
            debugPrint("Locking onto: " .. lockedTarget.Parent.Name)
            camera.CameraType = Enum.CameraType.Scriptable
            RunService:BindToRenderStep("Aimlock", Enum.RenderPriority.Camera.Value, function()
                local headPos = findHeadPosition(lockedTarget)
                if headPos then
                    camera.CFrame = CFrame.new(camera.CFrame.Position, headPos)
                end
            end)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == LOCK_KEY then
        debugPrint("Lock key released")
        RunService:UnbindFromRenderStep("Aimlock")
        lockedTarget = nil
        camera.CameraType = Enum.CameraType.Custom
    end
end)

-- Initialization
debugPrint("Aimlock system initialized")
