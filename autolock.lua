-- Client-side LocalScript (place in StarterPlayerScripts)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local lockedTarget = nil
local maxLockDistance = 50 -- Studs
local lockHighlight = nil

local function findNearestEnemy()
    local closest = nil
    local closestDistance = maxLockDistance
    local localRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    
    if not localRoot then return nil end

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Team ~= player.Team then
            local character = otherPlayer.Character
            local enemyRoot = character and character:FindFirstChild("HumanoidRootPart")
            
            if enemyRoot then
                local distance = (enemyRoot.Position - localRoot.Position).Magnitude
                if distance < closestDistance then
                    closest = character
                    closestDistance = distance
                end
            end
        end
    end
    
    return closest
end

local function createLockHighlight(target)
    if lockHighlight then lockHighlight:Destroy() end
    
    lockHighlight = Instance.new("Highlight")
    lockHighlight.Name = "LockOnHighlight"
    lockHighlight.FillColor = Color3.new(1, 0, 0)
    lockHighlight.OutlineColor = Color3.new(1, 1, 0)
    lockHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    lockHighlight.Parent = target
end

local function updateLock()
    if not lockedTarget then return end
    
    local humanoid = lockedTarget:FindFirstChild("Humanoid")
    local rootPart = lockedTarget:FindFirstChild("HumanoidRootPart")
    local localRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or humanoid.Health <= 0 or not rootPart or not localRoot then
        lockedTarget = nil
        if lockHighlight then lockHighlight:Destroy() end
        return
    end

    -- Maintain camera focus
    camera.CFrame = CFrame.new(camera.CFrame.Position, rootPart.Position)
end

mouse.Button2Down:Connect(function()
    lockedTarget = findNearestEnemy()
    
    if lockedTarget then
        createLockHighlight(lockedTarget)
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not lockedTarget then
                connection:Disconnect()
                return
            end
            updateLock()
        end)
    end
end)

mouse.Button2Up:Connect(function()
    lockedTarget = nil
    if lockHighlight then
        lockHighlight:Destroy()
        lockHighlight = nil
    end
end)

-- Cleanup if character changes
player.CharacterAdded:Connect(function()
    lockedTarget = nil
    if lockHighlight then
        lockHighlight:Destroy()
        lockHighlight = nil
    end
end)
