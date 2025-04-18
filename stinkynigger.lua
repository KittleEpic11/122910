-- LocalScript (Place in StarterPlayerScripts)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local lockedTarget = nil

-- 1. REQUIRED INITIALIZATION
camera.CameraType = Enum.CameraType.Scriptable

-- 2. DEBUG VISUALS
local debugPart = Instance.new("Part")
debugPart.Size = Vector3.new(0.5, 0.5, 0.5)
debugPart.Shape = Enum.PartType.Ball
debugPart.Color = Color3.new(1, 0, 0)
debugPart.Anchored = true
debugPart.CanCollide = false
debugPart.Parent = workspace

-- 3. HEALTH CHECK FUNCTION
local function isTargetValid(target)
    if not target then return false end
    local humanoid = target:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

-- 4. MODIFIED LOCK SYSTEM
local function getHeadPosition(target)
    return target:FindFirstChild("Head") and target.Head.Position + Vector3.new(0, 0, 0)
end

local function findTarget()
    local myHead = player.Character and player.Character:FindFirstChild("Head")
    if not myHead then return end
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local char = otherPlayer.Character
            if not char or not isTargetValid(char) then continue end
            
            local head = getHeadPosition(char)
            
            -- Visual debug
            debugPart.Position = head or Vector3.new(0, 100, 0)
            
            if head then
                local distance = (head - myHead.Position).Magnitude
                local direction = (head - camera.CFrame.Position).Unit
                local dot = camera.CFrame.LookVector:Dot(direction)
                
                -- Force lock when facing target
                if dot > 0.9 then -- 25 degree cone
                    return char
                end
            end
        end
    end
end

-- 5. LOCKING MECHANISM
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        lockedTarget = findTarget()
        
        if lockedTarget then
            RunService:BindToRenderStep("AimLock", Enum.RenderPriority.Camera.Value, function()
                if not isTargetValid(lockedTarget) then
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
