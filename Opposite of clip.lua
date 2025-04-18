local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")

-- Create collision groups
PhysicsService:CreateCollisionGroup("GhostPlayer")
PhysicsService:CreateCollisionGroup("GhostWalls")
PhysicsService:CollisionGroupSetCollidable("GhostPlayer", "GhostWalls", false)

-- Configure local player
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local function isWall(part)
    -- Auto-detect walls using surface normal check
    local position = part.Position
    local ray = Ray.new(position, Vector3.new(0, 0, 0.1))
    local hit, _, normal = workspace:FindPartOnRay(ray, part)
    
    return normal and math.abs(normal.Y) < 0.3 -- Vertical surface check
end

local function handlePart(part)
    if part:IsA("BasePart") then
        if isWall(part) then
            PhysicsService:SetPartCollisionGroup(part, "GhostWalls")
        else
            -- Maintain collision with floors and non-walls
            PhysicsService:SetPartCollisionGroup(part, "Default")
        end
    end
end

-- Make player walk through walls
local function ghostify()
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(part, "GhostPlayer")
        end
    end
    
    -- Auto-detect new walls when touched
    character.HumanoidRootPart.Touched:Connect(function(part)
        handlePart(part)
    end)
end

-- Initialize
ghostify()
player.CharacterAdded:Connect(ghostify)

-- Maintain floor collision
RunService.Heartbeat:Connect(function()
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.PlatformStand = false
    end
end)
