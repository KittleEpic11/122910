local Players = game:GetService("Players")

local function createHealthBar(character)
    -- Wait for required components
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return end

    -- Create health bar GUI
    local healthBar = Instance.new("BillboardGui")
    healthBar.Name = "PlayerHealthBar"
    healthBar.Adornee = hrp
    healthBar.Size = UDim2.new(4, 0, 0.5, 0)  -- Width: 4 studs, Height: 0.5 studs
    healthBar.StudsOffset = Vector3.new(0, 2.5, 0)  -- Position above head
    healthBar.AlwaysOnTop = true
    healthBar.MaxDistance = 100  -- Visible up to 100 studs away

    -- Background container
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    background.BackgroundTransparency = 0.3
    background.BorderSizePixel = 0
    background.Size = UDim2.new(1, 0, 1, 0)

    -- Health fill
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = Color3.new(1, 0, 0)  -- Red color
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
    fill.AnchorPoint = Vector2.new(0, 0.5)
    fill.Position = UDim2.new(0, 0, 0.5, 0)
    fill.ZIndex = 2

    -- Assemble GUI elements
    fill.Parent = background
    background.Parent = healthBar
    healthBar.Parent = character

    -- Update health bar when health changes
    humanoid.HealthChanged:Connect(function(currentHealth)
        fill.Size = UDim2.new(currentHealth / humanoid.MaxHealth, 0, 1, 0)
    end)
end

local function onCharacterAdded(character, player)
    -- Clean up existing health bar
    local existingBar = character:FindFirstChild("PlayerHealthBar")
    if existingBar then
        existingBar:Destroy()
    end
    
    -- Create new health bar
    if character:WaitForChild("Humanoid") then
        createHealthBar(character)
    end
end

local function onPlayerAdded(player)
    -- Connect character events
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(character, player)
    end)
    
    -- Handle existing character
    if player.Character then
        onCharacterAdded(player.Character, player)
    end
end

-- Initialize for all players
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
