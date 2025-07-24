-- Load Rayfield UI
loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Settings
local TargetPart = "Head"
local selectedPlayer = nil
local Settings = {
    SilentAim = false,
    TriggerBot = false,
    ESP = false,
    SpinBot = false,
    Fly = false,
    WalkSpeed = false,
    JumpPower = false,
    FlySpeed = 50,
    WalkSpeedValue = 16,
    JumpPowerValue = 50,
    Fling = false
}

-- Create UI
local Window = Rayfield:CreateWindow({
    Name = "Universal Aimbot GUI",
    LoadingTitle = "Universal Aimbot",
    LoadingSubtitle = "by You",
    ConfigurationSaving = { Enabled = true, FolderName = "AimbotConfig", FileName = "settings" },
    Discord = { Enabled = false },
    KeySystem = false,
})
local MainTab = Window:CreateTab("Main", 4483362458)

-- Core Features
MainTab:CreateDropdown({Name="Target Part",Options={"Head","HumanoidRootPart","Random"},CurrentOption="Head",
    Callback=function(opt) TargetPart=opt end})
MainTab:CreateToggle({Name="Silent Aim",CurrentValue=false,Callback=function(v) Settings.SilentAim=v end})
MainTab:CreateToggle({Name="Trigger Bot",CurrentValue=false,Callback=function(v) Settings.TriggerBot=v end})
MainTab:CreateToggle({Name="ESP",CurrentValue=false,Callback=function(v) Settings.ESP=v end})
MainTab:CreateToggle({Name="Spin Bot",CurrentValue=false,Callback=function(v) Settings.SpinBot=v end})
MainTab:CreateToggle({Name="Fly Mode",CurrentValue=false,Callback=function(v) Settings.Fly=v end})
MainTab:CreateSlider({Name="Fly Speed",Range={1,200},Increment=1,CurrentValue=50,
    Callback=function(v) Settings.FlySpeed=v end})
MainTab:CreateToggle({Name="Walk Speed",CurrentValue=false,Callback=function(v) Settings.WalkSpeed=v end})
MainTab:CreateSlider({Name="Walk Speed Value",Range={1,100},Increment=1,CurrentValue=16,
    Callback=function(v) Settings.WalkSpeedValue=v end})
MainTab:CreateToggle({Name="Jump Power",CurrentValue=false,Callback=function(v) Settings.JumpPower=v end})
MainTab:CreateSlider({Name="Jump Power Value",Range={1,100},Increment=1,CurrentValue=50,
    Callback=function(v) Settings.JumpPowerValue=v end})

-- Spectate Dropdown
MainTab:CreateDropdown({Name="Spectate Player",Options={},CurrentOption=nil,
    Callback=function(name) selectedPlayer=Players:FindFirstChild(name) end})
task.spawn(function()
    while true do
        task.wait(5)
        local names={}
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LocalPlayer then table.insert(names,plr.Name) end
        end
        MainTab:UpdateDropdown("Spectate Player", {Options=names})
    end
end)

-- Fling Toggle
MainTab:CreateToggle({Name="Fling on Touch",CurrentValue=false,Callback=function(v) Settings.Fling=v end})

-- ESP Highlight
function UpdateESP()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer and plr.Character then
            local highlight = plr.Character:FindFirstChildOfClass("Highlight")
            if Settings.ESP then
                if not highlight then
                    highlight = Instance.new("Highlight",plr.Character)
                    highlight.FillColor = Color3.fromRGB(255,0,0)
                    highlight.OutlineColor = Color3.fromRGB(0,255,0)
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                end
            else
                if highlight then highlight:Destroy() end
            end
        end
    end
end

-- Targeting
local function GetClosestTarget()
    local closest, distMin = nil, math.huge
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer and plr.Character then
            local part = plr.Character:FindFirstChild(TargetPart) or plr.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local p2d, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist2d = (Vector2.new(p2d.X,p2d.Y)-Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)).Magnitude
                    if dist2d < distMin then
                        closest, distMin = part, dist2d
                    end
                end
            end
        end
    end
    return closest
end

-- Silent Aim Hook
local mt = getrawmetatable(game)
setreadonly(mt,false)
local oldNamecall = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    if Settings.SilentAim and getnamecallmethod()=="FindPartOnRayWithIgnoreList" then
        local target = GetClosestTarget()
        if target then
            args[2] = Ray.new(args[2].Origin, (target.Position-args[2].Origin).Unit * 1000)
        end
        return oldNamecall(self, unpack(args))
    end
    return oldNamecall(self,...)
end)
setreadonly(mt,true)

-- Trigger Bot Logic
RunService.RenderStepped:Connect(function()
    if Settings.TriggerBot then
        local ray = Ray.new(Camera.CFrame.Position, Camera.CFrame.LookVector*5000)
        local hit = workspace:FindPartOnRay(ray, LocalPlayer.Character)
        if hit and hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
            mouse1press()
        else
            mouse1release()
        end
    end
end)

-- Spectate Camera
RunService.RenderStepped:Connect(function()
    if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("Humanoid") then
        Camera.CameraSubject = selectedPlayer.Character.Humanoid
    else
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then Camera.CameraSubject = hum end
    end
    UpdateESP()
end)

-- Movement & Spin & Fling & Fly
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end

    -- Walk & Jump
    hum.WalkSpeed = (Settings.WalkSpeed and Settings.WalkSpeedValue) or 16
    hum.JumpPower = (Settings.JumpPower and Settings.JumpPowerValue) or 50

    -- Spin Bot
    if Settings.SpinBot and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame *= CFrame.Angles(0, math.rad(15), 0)
    end

    -- Fling on touch
    if Settings.Fling and char:FindFirstChild("HumanoidRootPart") then
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (char.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                if dist < 5 then
                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity = Vector3.new(9999,9999,9999)
                    bv.MaxForce = Vector3.new(1e9,1e9,1e9)
                    bv.Parent = plr.Character.HumanoidRootPart
                    Debris:AddItem(bv, 0.2)
                end
            end
        end
    end
end)

-- Fly Logic
local BodyGyro, BodyVelocity
RunService.RenderStepped:Connect(function()
    if not Settings.Fly then
        if BodyGyro then BodyGyro:Destroy() BodyGyro = nil end
        if BodyVelocity then BodyVelocity:Destroy() BodyVelocity = nil end
        return
    end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if not BodyGyro then
        BodyGyro = Instance.new("BodyGyro", root)
        BodyGyro.P = 9e4
        BodyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
    end
    if not BodyVelocity then
        BodyVelocity = Instance.new("BodyVelocity", root)
        BodyVelocity.MaxForce = Vector3.new(9e9,9e9,9e9)
    end

    BodyGyro.CFrame = Camera.CFrame

    local move = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Camera.CFrame.UpVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Camera.CFrame.UpVector end

    BodyVelocity.Velocity = move.Unit * Settings.FlySpeed
end)
