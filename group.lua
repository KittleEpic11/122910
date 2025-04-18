
-- LocalScript (Place in StarterPlayerScripts)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local lockedTarget = nil

-- 1. REQUIRED INITIALIZATION
camera.CameraType = Enum.CameraType.Scriptable

-- 2. CONFIGURATION
local LOCK_ANGLE = math.cos(math.rad(15)) -- 15 degree cone
local HEAD_OFFSET = Vector3.new(0, 1.5, 0)

-- 3. VALIDATION FUNCTIONS
local function isEnemy(otherPlayer)
    -- Team check logic
    return player.Neutral 
        or otherPlayer.Neutral 
        or otherPlayer.Team ~= player.Team
end

local function isValidTarget(targetChar, otherPlayer)
    if not targetChar then return false end
    local humanoid = targetChar:FindFirstChild("Humanoid")
    return humanoid 
        and humanoid.Health > 0
        and isEnemy(otherPlayer)
end

-- 4. TARGET ACQUISITION
local function getHeadPosition(targetChar)
    local head = targetChar:FindFirstChild("Head")
    return head and (head.Position + HEAD_OFFSET)
end

local function findTarget()
    if not player.Character then return end
    local localHead = player.Character:FindFirstChild("Head")
    if not localHead then return end

    local cameraPos = camera.CFrame.Position
    local cameraLook = camera.CFrame.LookVector

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and isEnemy(otherPlayer) then
            local targetChar = otherPlayer.Character
            if isValidTarget(targetChar, otherPlayer) then
                local headPos = getHeadPosition(targetChar)
                if headPos then
                    local toTarget = (headPos - cameraPos).Unit
                    local dot = cameraLook:Dot(toTarget)
                    
                    -- 15 degree cone check
                    if dot > LOCK_ANGLE then
                        return targetChar
                    end
                end
            end
        end
    end
end

-- 5. LOCKING SYSTEM
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        lockedTarget = findTarget()
        
        if lockedTarget then
            RunService:BindToRenderStep("AimLock", Enum.RenderPriority.Camera.Value, function()
                if not isValidTarget(lockedTarget, Players:GetPlayerFromCharacter(lockedTarget)) then
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
-- 2
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local function applyHighlight(character, player)
    -- Create Highlight object
    local highlight = Instance.new("Highlight")
    highlight.Name = "TeamHighlight"
    
    -- Configure highlight properties
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 1  -- Transparent fill (only outline visible)
    highlight.OutlineColor = player.TeamColor.Color
    
    -- Parent highlight to character
    highlight.Parent = character
end

local function onCharacterAdded(character, player)
    -- Wait for Humanoid to ensure character is fully loaded
    if character:WaitForChild("Humanoid") then
        -- Remove existing highlight if exists
        local existingHighlight = character:FindFirstChild("TeamHighlight")
        if existingHighlight then
            existingHighlight:Destroy()
        end
        
        -- Apply new highlight
        applyHighlight(character, player)
    end
end

local function onPlayerAdded(player)
    -- Handle character added event
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(character, player)
    end)
    
    -- Handle existing character
    if player.Character then
        onCharacterAdded(player.Character, player)
    end
end

-- Initialize for all current players
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

-- Connect for future players
Players.PlayerAdded:Connect(onPlayerAdded)
-- 3
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
