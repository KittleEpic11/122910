local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

-- Feature toggle states with initialization
local features = {
    aimLock = false,
    teamHighlight = false,
    healthBars = false
}

--[[ Feature 1: Aim Lock System ]]--
local aimLockSystem = {
    debugPart = nil,
    lockedTarget = nil,
    active = false
}

function aimLockSystem:initialize()
    self.debugPart = Instance.new("Part")
    self.debugPart.Size = Vector3.new(0.5, 0.5, 0.5)
    self.debugPart.Shape = Enum.PartType.Ball
    self.debugPart.Color = Color3.new(1, 0, 0)
    self.debugPart.Anchored = true
    self.debugPart.CanCollide = false
    self.debugPart.Parent = workspace

    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
end

function aimLockSystem:enable()
    if not self.debugPart then
        self:initialize()
    end
    self.active = true
    print("Aim Lock: Enabled")
end

function aimLockSystem:disable()
    self.active = false
    RunService:UnbindFromRenderStep("AimLock")
    self.lockedTarget = nil
    print("Aim Lock: Disabled")
end

--[[ Feature 2: Team Highlight System ]]--
local highlightSystem = {
    highlights = {}
}

function highlightSystem:enable()
    local function applyHighlight(character, player)
        if self.highlights[character] then
            self.highlights[character]:Destroy()
        end
        
        local highlight = Instance.new("Highlight")
        highlight.Name = "TeamHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 1
        highlight.OutlineColor = player.TeamColor.Color
        highlight.Parent = character
        self.highlights[character] = highlight
    end

    -- Immediate application to existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            applyHighlight(player.Character, player)
        end
        player.CharacterAdded:Connect(function(character)
            applyHighlight(character, player)
        end)
    end
    
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            applyHighlight(character, player)
        end)
    end)
    
    print("Team Highlights: Enabled")
end

function highlightSystem:disable()
    for _, highlight in pairs(self.highlights) do
        highlight:Destroy()
    end
    self.highlights = {}
    print("Team Highlights: Disabled")
end

--[[ Feature 3: Health Bar System ]]--
local healthBarSystem = {
    healthBars = {}
}

function healthBarSystem:enable()
    local function createHealthBar(character)
        if self.healthBars[character] then
            self.healthBars[character]:Destroy()
        end

        local humanoid = character:WaitForChild("Humanoid")
        local hrp = character:WaitForChild("HumanoidRootPart")

        local healthBar = Instance.new("BillboardGui")
        healthBar.Name = "PlayerHealthBar"
        healthBar.Adornee = hrp
        healthBar.Size = UDim2.new(4, 0, 0.5, 0)
        healthBar.StudsOffset = Vector3.new(0, 2.5, 0)
        healthBar.AlwaysOnTop = true
        healthBar.MaxDistance = 100

        local background = Instance.new("Frame")
        background.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
        background.BackgroundTransparency = 0.3
        background.Size = UDim2.new(1, 0, 1, 0)

        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = Color3.new(1, 0, 0)
        fill.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
        fill.AnchorPoint = Vector2.new(0, 0.5)
        fill.Position = UDim2.new(0, 0, 0.5, 0)
        fill.ZIndex = 2

        fill.Parent = background
        background.Parent = healthBar
        healthBar.Parent = character
        self.healthBars[character] = healthBar

        humanoid.HealthChanged:Connect(function(currentHealth)
            fill.Size = UDim2.new(currentHealth / humanoid.MaxHealth, 0, 1, 0)
        end)
    end

    -- Immediate application to existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            createHealthBar(player.Character)
        end
        player.CharacterAdded:Connect(function(character)
            createHealthBar(character)
        end)
    end
    
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            createHealthBar(character)
        end)
    end)
    
    print("Health Bars: Enabled")
end

function healthBarSystem:disable()
    for _, healthBar in pairs(self.healthBars) do
        healthBar:Destroy()
    end
    self.healthBars = {}
    print("Health Bars: Disabled")
end

-- Input Handling with Debug Prints
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local keyNumber = tonumber(string.match(tostring(input.KeyCode), "F(%d+)"))
        if not keyNumber or keyNumber < 1 or keyNumber > 3 then return end

        -- Toggle features with immediate visual feedback
        if keyNumber == 1 then
            features.aimLock = not features.aimLock
            if features.aimLock then
                aimLockSystem:enable()
                
                -- MouseButton2 connection for active system
                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton2 and aimLockSystem.active then
                        aimLockSystem.lockedTarget = findTarget()
                        
                        if aimLockSystem.lockedTarget then
                            RunService:BindToRenderStep("AimLock", Enum.RenderPriority.Camera.Value, function()
                                if not isTargetValid(aimLockSystem.lockedTarget) then
                                    RunService:UnbindFromRenderStep("AimLock")
                                    aimLockSystem.lockedTarget = nil
                                    return
                                end
                                
                                local headPos = getHeadPosition(aimLockSystem.lockedTarget)
                                if headPos then
                                    workspace.CurrentCamera.CFrame = CFrame.new(
                                        workspace.CurrentCamera.CFrame.Position,
                                        headPos
                                    )
                                end
                            end)
                        end
                    end
                end)
            else
                aimLockSystem:disable()
            end
            
        elseif keyNumber == 2 then
            features.teamHighlight = not features.teamHighlight
            if features.teamHighlight then
                highlightSystem:enable()
            else
                highlightSystem:disable()
            end
            
        elseif keyNumber == 3 then
            features.healthBars = not features.healthBars
            if features.healthBars then
                healthBarSystem:enable()
            else
                healthBarSystem:disable()
            end
        end
    end
end)

-- Helper functions for Aim Lock
local function isTargetValid(target)
    return target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0
end

local function getHeadPosition(target)
    return target:FindFirstChild("Head") and target.Head.Position
end

local function findTarget()
    local myHead = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Head")
    if not myHead then return end
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= Players.LocalPlayer then
            local char = otherPlayer.Character
            if not char or not isTargetValid(char) then continue end
            
            local head = getHeadPosition(char)
            if aimLockSystem.debugPart then
                aimLockSystem.debugPart.Position = head or Vector3.new(0, 100, 0)
            end
            
            if head then
                local direction = (head - workspace.CurrentCamera.CFrame.Position).Unit
                if workspace.CurrentCamera.CFrame.LookVector:Dot(direction) > 0.9 then
                    return char
                end
            end
        end
    end
end
