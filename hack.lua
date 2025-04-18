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
