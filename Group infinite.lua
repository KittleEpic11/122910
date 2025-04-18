local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

-- Feature toggle states
local features = {
    aimLock = false,
    teamHighlight = false,
    healthBars = false
}

--[[ Feature 1: Aim Lock System ]]--
local function initializeAimLock()
    local camera = workspace.CurrentCamera
    local lockedTarget = nil

    camera.CameraType = Enum.CameraType.Scriptable

    local debugPart = Instance.new("Part")
    debugPart.Size = Vector3.new(0.5, 0.5, 0.5)
    debugPart.Shape = Enum.PartType.Ball
    debugPart.Color = Color3.new(1, 0, 0)
    debugPart.Anchored = true
    debugPart.CanCollide = false
    debugPart.Parent = workspace

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
                debugPart.Position = head or Vector3.new(0, 100, 0)
                
                if head then
                    local direction = (head - camera.CFrame.Position).Unit
                    if camera.CFrame.LookVector:Dot(direction) > 0.9 then
                        return char
                    end
                end
            end
        end
    end

    UserInputService.InputBegan:Connect(function(input)
        if features.aimLock and input.UserInputType == Enum.UserInputType.MouseButton2 then
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
end

--[[ Feature 2: Team Highlight System ]]--
local highlightHandler do
    local highlights = {}

    function highlightHandler.enable()
        local function applyHighlight(character, player)
            local highlight = Instance.new("Highlight")
            highlight.Name = "TeamHighlight"
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.FillTransparency = 1
            highlight.OutlineColor = player.TeamColor.Color
            highlight.Parent = character
            highlights[character] = highlight
        end

        local function onCharacterAdded(character, player)
            if character:WaitForChild("Humanoid") then
                if highlights[character] then
                    highlights[character]:Destroy()
                end
                applyHighlight(character, player)
            end
        end

        local function onPlayerAdded(player)
            player.CharacterAdded:Connect(function(character)
                onCharacterAdded(character, player)
            end)
            if player.Character then
                onCharacterAdded(player.Character, player)
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            onPlayerAdded(player)
        end
        Players.PlayerAdded:Connect(onPlayerAdded)
    end

    function highlightHandler.disable()
        for character, highlight in pairs(highlights) do
            highlight:Destroy()
        end
        highlights = {}
    end
end

--[[ Feature 3: Health Bar System ]]--
local healthBarHandler do
    local healthBars = {}

    function healthBarHandler.enable()
        local function createHealthBar(character)
            local humanoid = character:FindFirstChild("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not humanoid or not hrp then return end

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
            healthBars[character] = healthBar

            humanoid.HealthChanged:Connect(function(currentHealth)
                fill.Size = UDim2.new(currentHealth / humanoid.MaxHealth, 0, 1, 0)
            end)
        end

        local function onCharacterAdded(character)
            if healthBars[character] then
                healthBars[character]:Destroy()
            end
            if character:WaitForChild("Humanoid") then
                createHealthBar(character)
            end
        end

        local function onPlayerAdded(player)
            player.CharacterAdded:Connect(onCharacterAdded)
            if player.Character then
                onCharacterAdded(player.Character)
            end
        end

        Players.PlayerAdded:Connect(onPlayerAdded)
        for _, player in ipairs(Players:GetPlayers()) do
            onPlayerAdded(player)
        end
    end

    function healthBarHandler.disable()
        for character, healthBar in pairs(healthBars) do
            healthBar:Destroy()
        end
        healthBars = {}
    end
end

-- Toggle System
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local keyNumber = tonumber(string.match(tostring(input.KeyCode), "F(%d+)"))
        if not keyNumber or keyNumber < 1 or keyNumber > 3 then return end

        -- Toggle features
        if keyNumber == 1 then
            features.aimLock = not features.aimLock
            if features.aimLock then
                initializeAimLock()
            end
        elseif keyNumber == 2 then
            features.teamHighlight = not features.teamHighlight
            if features.teamHighlight then
                highlightHandler.enable()
            else
                highlightHandler.disable()
            end
        elseif keyNumber == 3 then
            features.healthBars = not features.healthBars
            if features.healthBars then
                healthBarHandler.enable()
            else
                healthBarHandler.disable()
            end
        end
    end
end)
