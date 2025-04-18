local Tool = script.Parent
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuration
local BULLET_SPEED = 150
local BULLET_LIFETIME = 3
local DAMAGE = 500
local BULLET_RADIUS = 10  -- Large area of effect

local function fireFromTool()
    local character = Tool.Parent
    local player = Players:GetPlayerFromCharacter(character)
    if not character or not player then return end

    -- Auto-detect firing position (uses tool position)
    local firePosition = Tool.Handle.Position  -- Uses the tool's Handle part
    local lookDirection = character:GetPivot().LookVector

    -- Create bullet effect
    local bullet = Instance.new("Part")
    bullet.Name = "AOE_Bullet"
    bullet.Size = Vector3.new(1, 1, 1)
    bullet.Shape = Enum.PartType.Ball
    bullet.Color = Color3.new(1, 0, 0)
    bullet.Material = Enum.Material.Neon
    bullet.CanCollide = false
    bullet.Anchored = true
    bullet.CFrame = CFrame.new(firePosition, firePosition + lookDirection)
    bullet.Parent = workspace

    local startTime = os.clock()

    -- Damage function
    local function dealAOEDamage()
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= player then
                local character = targetPlayer.Character
                if character then
                    local humanoid = character:FindFirstChild("Humanoid")
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    
                    if humanoid and hrp then
                        local distance = (hrp.Position - bullet.Position).Magnitude
                        if distance < BULLET_RADIUS then
                            humanoid:TakeDamage(DAMAGE)
                        end
                    end
                end
            end
        end
    end

    -- Movement loop
    local connection
    connection = RunService.Heartbeat:Connect(function(delta)
        if not bullet.Parent or os.clock() - startTime >= BULLET_LIFETIME then
            bullet:Destroy()
            connection:Disconnect()
            return
        end

        -- Move bullet
        bullet.Position += lookDirection * BULLET_SPEED * delta
        
        -- Constant area damage
        dealAOEDamage()
    end)
end

Tool.Activated:Connect(fireFromTool)
