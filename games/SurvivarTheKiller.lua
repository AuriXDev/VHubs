-- VuaN | Survive the Killer V1

local lp = game:FindService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local function notif(str, dur)
    StarterGui:SetCore("SendNotification", {
        Title = "VSTK V1",
        Text = str,
        Duration = dur or 3
    })
end

local settings = {
    Speed = 16, speedEnabled = false,
    Fly = false, flySpeed = 50,
    Noclip = false,
    NoFog = false,
    Fullbright = false,
    ESP = true,
    AutoLoot = false,
    KillAura = false,
    AutoReviveOthers = false,
    killAuraRadius = 10,
    returnHomeAfterLoot = true
}

local flyConnection = nil
local noclipConnection = nil
local brightLoop = nil
local lootConnection = nil
local killAuraConnection = nil
local reviveOthersConnection = nil
local espObjects = {}
local savedHomePosition = nil
local isReviving = false

local function CreateToggle(parent, text, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent; frame.BackgroundTransparency = 1; frame.Size = UDim2.new(1, 0, 0, 28)

    local label = Instance.new("TextLabel")
    label.Parent = frame; label.BackgroundTransparency = 1; label.Position = UDim2.new(0, 5, 0, 0)
    label.Size = UDim2.new(0.7, 0, 0, 28); label.Font = Enum.Font.Gotham
    label.Text = text; label.TextColor3 = Color3.fromRGB(220, 220, 235); label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggle = Instance.new("TextButton")
    toggle.Parent = frame; toggle.BorderSizePixel = 0; toggle.Position = UDim2.new(1, -45, 0, 4)
    toggle.Size = UDim2.new(0, 40, 0, 20); toggle.Font = Enum.Font.GothamBold
    toggle.BackgroundColor3 = defaultValue and Color3.fromRGB(224, 58, 58) or Color3.fromRGB(50, 50, 65)
    toggle.Text = defaultValue and "ON" or "OFF"; toggle.TextColor3 = Color3.fromRGB(255, 255, 255); toggle.TextSize = 10

    local toggleCorner = Instance.new("UICorner"); toggleCorner.CornerRadius = UDim.new(0, 4); toggleCorner.Parent = toggle

    local state = defaultValue
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and Color3.fromRGB(224, 58, 58) or Color3.fromRGB(50, 50, 65)
        toggle.Text = state and "ON" or "OFF"
        callback(state)
    end)
    return frame
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent; btn.BorderSizePixel = 0; btn.Size = UDim2.new(1, 0, 0, 32)
    btn.Font = Enum.Font.GothamBold; btn.Text = text; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.TextSize = 12
    btn.BackgroundColor3 = Color3.fromRGB(224, 58, 58)
    local btnCorner = Instance.new("UICorner"); btnCorner.CornerRadius = UDim.new(0, 7); btnCorner.Parent = btn
    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(224, 58, 58) end)
    return btn
end

local function CreateSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent; frame.BackgroundTransparency = 1; frame.Size = UDim2.new(1, 0, 0, 45)

    local label = Instance.new("TextLabel")
    label.Parent = frame; label.BackgroundTransparency = 1; label.Position = UDim2.new(0, 5, 0, 0)
    label.Size = UDim2.new(0.6, 0, 0, 20); label.Font = Enum.Font.Gotham
    label.Text = text; label.TextColor3 = Color3.fromRGB(220, 220, 235); label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame; valueLabel.BackgroundTransparency = 1; valueLabel.Position = UDim2.new(1, -50, 0, 0)
    valueLabel.Size = UDim2.new(0, 45, 0, 20); valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = tostring(default); valueLabel.TextColor3 = Color3.fromRGB(224, 58, 58); valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Parent = frame; sliderFrame.BorderSizePixel = 0; sliderFrame.Position = UDim2.new(0, 5, 0, 25)
    sliderFrame.Size = UDim2.new(1, -10, 0, 5); sliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    local sliderCorner = Instance.new("UICorner"); sliderCorner.CornerRadius = UDim.new(0, 3); sliderCorner.Parent = sliderFrame

    local fill = Instance.new("Frame")
    fill.Parent = sliderFrame; fill.BorderSizePixel = 0; fill.BackgroundColor3 = Color3.fromRGB(224, 58, 58)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    local fillCorner = Instance.new("UICorner"); fillCorner.CornerRadius = UDim.new(0, 3); fillCorner.Parent = fill

    local knob = Instance.new("TextButton")
    knob.Parent = sliderFrame; knob.BorderSizePixel = 0; knob.BackgroundColor3 = Color3.fromRGB(224, 58, 58)
    knob.Position = UDim2.new((default - min) / (max - min), -7.5, 0, -5)
    knob.Size = UDim2.new(0, 15, 0, 15); knob.Text = ""
    local knobCorner = Instance.new("UICorner"); knobCorner.CornerRadius = UDim.new(0, 8); knobCorner.Parent = knob

    local dragging = false; local currentValue = default
    knob.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local sliderPos = sliderFrame.AbsolutePosition.X
            local sliderWidth = sliderFrame.AbsoluteSize.X
            local t = math.clamp((mousePos.X - sliderPos) / sliderWidth, 0, 1)
            currentValue = min + (max - min) * t
            currentValue = math.floor(currentValue * 10) / 10
            valueLabel.Text = tostring(currentValue)
            fill.Size = UDim2.new(t, 0, 1, 0)
            knob.Position = UDim2.new(t, -7.5, 0, -5)
            callback(currentValue)
        end
    end)
    return frame
end

local function CreateLabel(parent, text, color)
    local label = Instance.new("TextLabel")
    label.Parent = parent; label.BackgroundTransparency = 1; label.Size = UDim2.new(1, 0, 0, 25)
    label.Font = Enum.Font.GothamBold; label.Text = text
    label.TextColor3 = color or Color3.fromRGB(220, 220, 235); label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

local function CreateTextBox(parent, placeholder)
    local box = Instance.new("TextBox")
    box.Parent = parent; box.BorderSizePixel = 0; box.Size = UDim2.new(1, 0, 0, 35)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 45); box.BackgroundTransparency = 0.3
    box.Font = Enum.Font.Gotham; box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(150, 150, 170); box.Text = ""
    box.TextColor3 = Color3.fromRGB(255, 255, 255); box.TextSize = 12
    local boxCorner = Instance.new("UICorner"); boxCorner.CornerRadius = UDim.new(0, 7); boxCorner.Parent = box
    return box
end

local h = Instance.new("ScreenGui")
h.Name = "VuaN_STK_V1"
h.Parent = game:GetService("CoreGui")
h.ResetOnSpawn = false

local Main = Instance.new("ImageLabel")
Main.Parent = h
Main.Active = true
Main.Draggable = true
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Main.BackgroundTransparency = 0.1
Main.BorderSizePixel = 0
Main.Position = UDim2.new(0.5, -250, 0.3, 0)
Main.Size = UDim2.new(0, 380, 0, 520)

local MainCorner = Instance.new("UICorner"); MainCorner.CornerRadius = UDim.new(0, 10); MainCorner.Parent = Main

local Top = Instance.new("Frame")
Top.Parent = Main
Top.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Top.Size = UDim2.new(1, 0, 0, 30)

local Title = Instance.new("TextLabel")
Title.Parent = Top
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Size = UDim2.new(0, 180, 0, 30)
Title.Font = Enum.Font.GothamBold
Title.Text = "VuaN | STK V1"
Title.TextColor3 = Color3.fromRGB(224, 58, 58)
Title.TextSize = 24
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = Top
CloseBtn.BackgroundColor3 = Color3.fromRGB(224, 58, 58)
CloseBtn.BackgroundTransparency = 0.7
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "x"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
local CloseCorner = Instance.new("UICorner"); CloseCorner.CornerRadius = UDim.new(0, 4); CloseCorner.Parent = CloseBtn
CloseBtn.MouseButton1Click:Connect(function() h:Destroy() end)

local RightContent = Instance.new("Frame")
RightContent.Parent = Main
RightContent.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
RightContent.BackgroundTransparency = 0.05
RightContent.Position = UDim2.new(0, 15, 0, 45)
RightContent.Size = UDim2.new(1, -30, 1, -60)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Parent = RightContent
scrollFrame.BackgroundTransparency = 1
scrollFrame.Size = UDim2.new(1, 0, 1, 0)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 4
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = scrollFrame
listLayout.Padding = UDim.new(0, 12)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function UpdateESP()
    for _, obj in pairs(espObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    espObjects = {}
    if not settings.ESP then return end

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character then
            local color = (player.Team and player.Team.TeamColor.Color) or Color3.fromRGB(255, 0, 0)
            local highlight = Instance.new("Highlight")
            highlight.Adornee = player.Character
            highlight.FillTransparency = 1
            highlight.OutlineColor = color
            highlight.OutlineTransparency = 0.3
            highlight.Parent = player.Character
            table.insert(espObjects, highlight)
        end
    end
end

local function UpdateFly()
    if settings.Fly then
        if flyConnection then flyConnection:Disconnect() end
        flyConnection = RunService.RenderStepped:Connect(function()
            if not settings.Fly or not lp.Character then return end
            local root = lp.Character.HumanoidRootPart
            if not root then return end
            local bg = root:FindFirstChild("BodyGyro") or Instance.new("BodyGyro")
            local bv = root:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity")
            bg.P = 9e4; bg.Parent = root; bg.MaxTorque = Vector3.new(9e9,9e9,9e9); bg.CFrame = root.CFrame
            bv.Parent = root; bv.MaxForce = Vector3.new(9e9,9e9,9e9); bv.Velocity = Vector3.new(0,0,0)
            lp.Character.Humanoid.PlatformStand = true
            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0,0,1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0,0,-1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir + Vector3.new(0,-1,0) end
            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
            local cam = workspace.CurrentCamera
            bv.Velocity = (cam.CFrame.LookVector * moveDir.Z + cam.CFrame.RightVector * moveDir.X + cam.CFrame.UpVector * moveDir.Y) * settings.flySpeed
            bg.CFrame = cam.CFrame
        end)
    else
        if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local root = lp.Character.HumanoidRootPart
            local bg = root:FindFirstChild("BodyGyro"); if bg then bg:Destroy() end
            local bv = root:FindFirstChild("BodyVelocity"); if bv then bv:Destroy() end
            lp.Character.Humanoid.PlatformStand = false
        end
    end
end

local function AutoCollectLoot()
    local map = nil
    for _, child in ipairs(workspace:GetChildren()) do
        if child:FindFirstChild("LootSpawns") then
            map = child
            break
        end
    end
    if not map then return end
    local lootFolder = map:FindFirstChild("LootSpawns")
    if not lootFolder then return end

    local lootList = {}
    for _, child in ipairs(lootFolder:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(lootList, child)
        end
    end
    if #lootList == 0 then return end

    local myPos = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character.HumanoidRootPart.Position or Vector3.new()
    table.sort(lootList, function(a, b)
        return (a.Position - myPos).Magnitude < (b.Position - myPos).Magnitude
    end)

    if savedHomePosition == nil and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        savedHomePosition = lp.Character.HumanoidRootPart.CFrame
        notif("Home position saved", 2)
    end

    for _, lootPart in ipairs(lootList) do
        if not settings.AutoLoot then break end
        if lootPart and lootPart.Parent and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = CFrame.new(lootPart.Position + Vector3.new(0, 3, 0))
            task.wait(0.25)
        end
    end
end

local function ReturnToHome()
    if savedHomePosition and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = savedHomePosition
        notif("Returned to home position", 2)
        savedHomePosition = nil
    end
end

local function TeleportToExit()
    local exitTrigger = nil
    
    for _, child in ipairs(workspace:GetChildren()) do
        local exits = child:FindFirstChild("ExitGateways")
        if exits then
            for _, gateway in ipairs(exits:GetChildren()) do
                local trigger = gateway:FindFirstChild("Trigger")
                if trigger and trigger:IsA("BasePart") then
                    exitTrigger = trigger
                    break
                end
            end
        end
        if exitTrigger then break end
    end
    
    if not exitTrigger then
        notif("Exit not found on this map", 2)
        return
    end
    
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = CFrame.new(exitTrigger.Position + Vector3.new(0, 3, 0))
        notif("Teleported to exit", 2)
    end
end

local function KillAuraLoop()
    local isKiller = (lp.Team and lp.Team.TeamColor == BrickColor.new("Really red")) or false
    if not isKiller then return end

    local closest = nil
    local minDist = math.huge
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local bleedOut = player.Character.HumanoidRootPart:FindFirstChild("BleedOutHealth")
                if not bleedOut or not bleedOut.Enabled then
                    local dist = (player.Character.HumanoidRootPart.Position - lp.Character.HumanoidRootPart.Position).Magnitude
                    if dist < minDist and dist <= settings.killAuraRadius then
                        minDist = dist
                        closest = player
                    end
                end
            end
        end
    end

    if closest then
        local forward = lp.Character.HumanoidRootPart.CFrame.LookVector
        closest.Character.HumanoidRootPart.CFrame = lp.Character.HumanoidRootPart.CFrame + (forward * 3)
        task.wait(0.05)
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0, 0, 0, true, Enum.UserInputType.MouseButton1, 0)
        task.wait()
        vim:SendMouseButtonEvent(0, 0, 0, false, Enum.UserInputType.MouseButton1, 0)
    end
end

local function BringAndKillAll()
    local isKiller = (lp.Team and lp.Team.TeamColor == BrickColor.new("Really red")) or false
    if not isKiller then
        notif("You are not killer!", 2)
        return
    end

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local bleedOut = player.Character.HumanoidRootPart:FindFirstChild("BleedOutHealth")
            if not bleedOut or not bleedOut.Enabled then
                local forward = lp.Character.HumanoidRootPart.CFrame.LookVector
                player.Character.HumanoidRootPart.CFrame = lp.Character.HumanoidRootPart.CFrame + (forward * 3)
                task.wait(0.05)
                local vim = game:GetService("VirtualInputManager")
                vim:SendMouseButtonEvent(0, 0, 0, true, Enum.UserInputType.MouseButton1, 0)
                task.wait()
                vim:SendMouseButtonEvent(0, 0, 0, false, Enum.UserInputType.MouseButton1, 0)
            end
        end
    end
    notif("All killed", 2)
end

local function BringPlayer(name)
    local target = nil
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player.Name:lower():find(name:lower()) or player.DisplayName:lower():find(name:lower()) then
            target = player
            break
        end
    end
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local forward = lp.Character.HumanoidRootPart.CFrame.LookVector
        target.Character.HumanoidRootPart.CFrame = lp.Character.HumanoidRootPart.CFrame + (forward * 3)
        notif("Brought: " .. target.Name, 2)
    else
        notif("Player not found", 2)
    end
end

local function AutoReviveOthersLoop()
    if not settings.AutoReviveOthers then return end
    if isReviving then return end
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = lp.Character.HumanoidRootPart
    local myBleedOut = myRoot:FindFirstChild("BleedOutHealth")
    if myBleedOut and myBleedOut.Enabled then return end
    
    if lp.Team then
        local teamName = lp.Team.Name:lower()
        if teamName == "lobby" or teamName == "spectator" or lp.Team.TeamColor == BrickColor.new("White") then
            return
        end
    end

    local closest = nil
    local minDist = math.huge
    
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local bleedOut = rootPart:FindFirstChild("BleedOutHealth")
                if bleedOut and bleedOut.Enabled then
                    local dist = (rootPart.Position - lp.Character.HumanoidRootPart.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = {player = player, rootPart = rootPart, bleedOut = bleedOut}
                    end
                end
            end
        end
    end
    
    if closest then
        local killerNearby = false
        local killerTooClose = closest.rootPart:FindFirstChild("KillerTooClose")
        if killerTooClose and killerTooClose.Value == true then
            killerNearby = true
        else
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local isKiller = (player.Team and player.Team.TeamColor == BrickColor.new("Really red")) or false
                    if isKiller then
                        local distToKiller = (player.Character.HumanoidRootPart.Position - closest.rootPart.Position).Magnitude
                        if distToKiller <= 15 then
                            killerNearby = true
                            break
                        end
                    end
                end
            end
        end
        
        if killerNearby then
            notif("Killer nearby! Teleporting to home", 2)
            if savedHomePosition then
                lp.Character.HumanoidRootPart.CFrame = savedHomePosition
                notif("Returned to home", 2)
            end
            return
        end
        
        isReviving = true
        local myHomePos = lp.Character.HumanoidRootPart.CFrame
        
        local wasFlying = settings.Fly
        local wasNoclip = settings.Noclip
        if wasFlying then
            settings.Fly = false
            UpdateFly()
        end
        if wasNoclip then
            settings.Noclip = false
            if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
        end
        
        local forward = closest.rootPart.CFrame.LookVector
        lp.Character.HumanoidRootPart.CFrame = closest.rootPart.CFrame + (forward * 2)
        task.wait(0.1)
        
        notif("Reviving: " .. closest.player.Name, 2)
        
        local bleedOut = closest.bleedOut
        local startTime = tick()
        while bleedOut and bleedOut.Enabled and (tick() - startTime) <= 15 do
            task.wait(0.5)
        end
        
        if bleedOut and not bleedOut.Enabled then
            notif(closest.player.Name .. " has been revived!", 2)
        else
            notif("Revive timeout for " .. closest.player.Name, 2)
        end
        
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = myHomePos
            notif("Returned to home", 2)
        end
        
        if wasFlying then
            settings.Fly = true
            UpdateFly()
        end
        if wasNoclip then
            settings.Noclip = true
            if noclipConnection then noclipConnection:Disconnect() end
            noclipConnection = RunService.Stepped:Connect(function()
                if settings.Noclip and lp.Character then
                    for _, part in pairs(lp.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end)
        end
        
        isReviving = false
    end
end

local lastUpdate = 0
local function PeriodicUpdates()
    if tick() - lastUpdate >= 0.02 then
        lastUpdate = tick()
        UpdateESP()
        if settings.speedEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
            lp.Character.Humanoid.WalkSpeed = settings.Speed
        end
    end
end

CreateToggle(scrollFrame, "Speed Hack (16-19 legit)", settings.speedEnabled, function(val)
    settings.speedEnabled = val
    if lp.Character and lp.Character:FindFirstChild("Humanoid") then
        lp.Character.Humanoid.WalkSpeed = val and settings.Speed or 16
    end
end)
CreateSlider(scrollFrame, "Speed Value", 16, 100, settings.Speed, function(val)
    settings.Speed = val
    if settings.speedEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
        lp.Character.Humanoid.WalkSpeed = val
    end
end)

CreateToggle(scrollFrame, "Fly", settings.Fly, function(val)
    settings.Fly = val
    UpdateFly()
end)
CreateSlider(scrollFrame, "Fly Speed", 20, 200, settings.flySpeed, function(val)
    settings.flySpeed = val
end)

CreateToggle(scrollFrame, "Noclip", settings.Noclip, function(val)
    settings.Noclip = val
    if val then
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            if settings.Noclip and lp.Character then
                for _, part in pairs(lp.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
    end
end)

CreateToggle(scrollFrame, "No Fog", settings.NoFog, function(val)
    settings.NoFog = val
    if val then
        Lighting.FogEnd = 100000
        for _, v in pairs(Lighting:GetDescendants()) do if v:IsA("Atmosphere") then v:Destroy() end end
    else
        Lighting.FogEnd = 1000
    end
end)

CreateToggle(scrollFrame, "Fullbright", settings.Fullbright, function(val)
    settings.Fullbright = val
    if val then
        if brightLoop then brightLoop:Disconnect() end
        brightLoop = RunService.RenderStepped:Connect(function()
            Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
        end)
    else
        if brightLoop then brightLoop:Disconnect(); brightLoop = nil end
    end
end)

CreateToggle(scrollFrame, "ESP", settings.ESP, function(val)
    settings.ESP = val
    UpdateESP()
end)

CreateToggle(scrollFrame, "Auto Collect Loot", settings.AutoLoot, function(val)
    settings.AutoLoot = val
    if val then
        savedHomePosition = nil
        if lootConnection then lootConnection:Disconnect() end
        lootConnection = RunService.Heartbeat:Connect(function()
            if settings.AutoLoot and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                AutoCollectLoot()
            end
        end)
    else
        if lootConnection then lootConnection:Disconnect(); lootConnection = nil end
        if settings.returnHomeAfterLoot then ReturnToHome() else savedHomePosition = nil end
    end
end)
CreateToggle(scrollFrame, "Return home after loot", settings.returnHomeAfterLoot, function(val)
    settings.returnHomeAfterLoot = val
end)

CreateButton(scrollFrame, "Teleport to Exit", TeleportToExit)

CreateToggle(scrollFrame, "Kill Aura", settings.KillAura, function(val)
    settings.KillAura = val
    if val then
        if killAuraConnection then killAuraConnection:Disconnect() end
        killAuraConnection = RunService.Heartbeat:Connect(function()
            if settings.KillAura and lp.Character and lp.Character:FindFirstChild("Humanoid") and lp.Character.Humanoid.Health > 0 then
                KillAuraLoop()
            end
        end)
    else
        if killAuraConnection then killAuraConnection:Disconnect(); killAuraConnection = nil end
    end
end)
CreateSlider(scrollFrame, "Kill Aura Radius", 8, 80, settings.killAuraRadius, function(val)
    settings.killAuraRadius = val
end)

CreateButton(scrollFrame, "Kill All", BringAndKillAll)

local bringBox = CreateTextBox(scrollFrame, "Player name")
CreateButton(scrollFrame, "Bring Player", function()
    if bringBox.Text ~= "" then BringPlayer(bringBox.Text) else notif("Enter name", 2) end
end)

CreateToggle(scrollFrame, "Auto Revive", settings.AutoReviveOthers, function(val)
    settings.AutoReviveOthers = val
    if val then
        if reviveOthersConnection then reviveOthersConnection:Disconnect() end
        reviveOthersConnection = RunService.Heartbeat:Connect(AutoReviveOthersLoop)
    else
        if reviveOthersConnection then reviveOthersConnection:Disconnect(); reviveOthersConnection = nil end
        if savedHomePosition and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = savedHomePosition
            notif("Auto Revive disabled, returned home", 2)
        end
    end
end)

local updateConnection = RunService.Stepped:Connect(PeriodicUpdates)

lp.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if settings.speedEnabled and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = settings.Speed
    end
    UpdateESP()
end)

game.Players.PlayerAdded:Connect(UpdateESP)
game.Players.PlayerRemoving:Connect(UpdateESP)

UpdateESP()
notif("SCRIPT loaded", 3)
