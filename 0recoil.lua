-- LocalScript (Place in StarterPlayerScripts)
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Method 1: Camera manipulation
local function zeroCameraRecoil()
    local originalCFrame = workspace.CurrentCamera.CFrame
    
    RunService:BindToRenderStep("NoRecoil", Enum.RenderPriority.Camera.Value, function()
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            workspace.CurrentCamera.CFrame = originalCFrame
        end
    end)
end

-- Method 2: Recoil function hook (for module-based games)
local function disableRecoilModule()
    local recoilController
    local oldNewIndex
    
    oldNewIndex = hookmetamethod(game, "__newindex", function(t, index, value)
        if tostring(t) == "RecoilController" and index == "RecoilAmount" then
            return
        end
        return oldNewIndex(t, index, value)
    end)
end

-- Method 3: Weapon property manipulation
local function modifyWeaponProperties()
    game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(char)
        char.ChildAdded:Connect(function(child)
            if child:FindFirstChild("Recoil") then
                child.Recoil.Value = 0
            end
            
            if child:FindFirstChild("Fire") then
                child.Fire:Connect(function()
                    -- Reset camera shake
                    workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position)
                end)
            end
        end)
    end)
end

-- Choose one method based on game's recoil system
disableRecoilModule()
