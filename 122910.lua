local Players = game:GetService("Players")

local function createHealthBar(character)
    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")

    -- Create health bar GUI
    local healthBar = Instance.new("BillboardGui")
    healthBar.Name = "HealthBar"
    healthBar.Adornee = hrp
    healthBar.Size = UDim2.new(4, 0, 0.4, 0)
    healthBar.StudsOffset = Vector3.new(0, 3, 0)
    healthBar.AlwaysOnTop = true

    -- Background frame
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    background.BorderSizePixel = 0
    background.Size = UDim2.new(1, 0, 1, 0)

    -- Health fill (always red)
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = Color3.new(1, 0, 0)  -- Red color
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
    fill.AnchorPoint = Vector2.new(0, 0.5)
    fill.Position = UDim2.new(0, 0, 0.5, 0)

    -- Assemble GUI
    fill.Parent = background
    background.Parent = healthBar
    healthBar.Parent = character

    -- Update health bar
    humanoid.HealthChanged:Connect(function(currentHealth)
        fill.Size = UDim2.new(currentHealth / humanoid.MaxHealth, 0, 1, 0)
    end)
end

local function applyHighlight(character, player)
    local existingHighlight = character:FindFirstChild("TeamHighlight")
    if existingHighlight then
        existingHighlight:Destroy()
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "TeamHighlight"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 1
    highlight.OutlineColor = player.TeamColor.Color  # Team-based color
    highlight.Parent = character
end

local function onCharacterAdded(character, player)
    if character:WaitForChild("Humanoid") then
        -- Cleanup old elements
        local existingHealthBar = character:FindFirstChild("HealthBar")
        if existingHealthBar then
            existingHealthBar:Destroy()
        end
        
        -- Create new elements
        applyHighlight(character, player)
        createHealthBar(character)
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

-- Initialize players
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
