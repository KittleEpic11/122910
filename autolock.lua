-- LocalScript (Place in StarterPlayerScripts)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local lockedTarget = nil
local maxLockDistance = 1000
local lockHighlight = nil
local connection = nil

-- Debug print function
local function debugPrint(message)
    print("[LockSystem] " .. message)
    
 game.StarterGui:SetCore("ChatMakeSystemMessage", {Text = "[LockSystem] "..message})
end

local function findNearestEnemy()
    if not player.Character then
        debugPrint("No character found")
        return nil
    end
    
    local localRoot = player.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then
        debugPrint("No HumanoidRootPart found")
        return nil
    end

    local closest = nil
    local closestDistance = maxLockDistance
    local localPosition = localRoot.Position

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            -- Team check (works with NeutralTeam)
            if player.Neutral or otherPlayer.Neutral or otherPlayer.Team ~= player.Team then
                local character = otherPlayer.Character
                if character then
                    local enemyRoot = character:FindFirstChild("HumanoidRootPart")
                    if enemyRoot then
                        local distance = (enemyRoot.Position - localPosition).Magnitude
                        if distance < closestDistance then
                            closest = character
                            closestDistance = distance
                        end
                    end
                end
            end
        end
    end

    debugPrint("Closest target: " .. (closest and closest.Name or "None"))
    return closest
end

local function createLockHighlight(target)
    if lockHighlight then
        lockHighlight:Destroy()
    end
    
    lockHighlight = Instance.new("Highlight")
    lockHighlight.Name = "LockOnHighlight"
    lockHighlight.FillColor = Color3.new(1, 0, 0)
    lockHighlight.OutlineColor = Color3.new(1, 1, 0)
    lockHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    lockHighlight.Parent = target
    debugPrint("Created highlight on " .. target.Name)
end

local function updateLock()
    if not lockedTarget or not lockedTarget.Parent then
        debugPrint("Lost target (destroyed)")
        lockedTarget = nil
        return
    end
    
    local humanoid = lockedTarget:FindFirstChild("Humanoid")
    local rootPart = lockedTarget:FindFirstChild("HumanoidRootPart")
    local localRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or humanoid.Health <= 0 or not rootPart or not localRoot then
        debugPrint("Lost target (invalid)")
        lockedTarget = nil
        return
    end

    -- Smooth camera tracking
    camera.CFrame = CFrame.new(camera.CFrame.Position, rootPart.Position)
end

mouse.Button2Down:Connect(function()
    debugPrint("Right mouse down")
    lockedTarget = findNearestEnemy()
    
    if lockedTarget then
        createLockHighlight(lockedTarget)
        connection = RunService.Heartbeat:Connect(function()
            if not lockedTarget then
                connection:Disconnect()
                debugPrint("Disconnected heartbeat")
                return
            end
            updateLock()
        end)
    end
end)

mouse.Button2Up:Connect(function()
    debugPrint("Right mouse up")
    lockedTarget = nil
    if lockHighlight then
        lockHighlight:Destroy()
        lockHighlight = nil
    end
    if connection then
        connection:Disconnect()
    end
end)

-- Reset on character change
player.CharacterAdded:Connect(function()
    debugPrint("Character reset")
    lockedTarget = nil
    if lockHighlight then
        lockHighlight:Destroy()
        lockHighlight = nil
    end
end)

debugPrint("Lock system initialized")
