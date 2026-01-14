local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local Chat = game:GetService("Chat")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- --- CONFIGURATION ---
_G.DevSettings = _G.DevSettings or {
    Speed = 16, Noclip = false, Fly = false, ESP = false, Orbit = false, ClickTP = false, SpinSpeed = 0,
    Aimbot = false, ShowFOV = false, FOVSize = 150, TeamCheck = true
}

-- --- AIMBOT DRAWING ---
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(0, 255, 255)
FOVCircle.Transparency = 1
FOVCircle.Filled = false

-- --- NOTIFICATION SYSTEM ---
local function SendNotification(text)
    local sg = player:WaitForChild("PlayerGui"):FindFirstChild("CyanMenu")
    if not sg then return end
    
    local notif = Instance.new("Frame", sg)
    notif.Size = UDim2.new(0, 250, 0, 50)
    notif.Position = UDim2.new(0, -300, 1, -70) 
    notif.BackgroundColor3 = Color3.fromRGB(0, 180, 220)
    notif.BackgroundTransparency = 0.2
    Instance.new("UICorner", notif)
    local stroke = Instance.new("UIStroke", notif)
    stroke.Color = Color3.new(1,1,1); stroke.Thickness = 2
    
    local lab = Instance.new("TextLabel", notif)
    lab.Size = UDim2.new(1, 0, 1, 0); lab.BackgroundTransparency = 1
    lab.Text = text; lab.TextColor3 = Color3.new(1, 1, 1)
    lab.Font = Enum.Font.Ubuntu; lab.TextSize = 18

    notif:TweenPosition(UDim2.new(0, 20, 1, -70), "Out", "Back", 0.5, true)
    
    task.delay(5, function()
        if notif then
            notif:TweenPosition(UDim2.new(0, -300, 1, -70), "In", "Quad", 0.5, true)
            task.wait(0.5)
            notif:Destroy()
        end
    end)
end

-- --- FIXED AIMBOT TARGETING ---
local function GetClosestToMouse()
    local target = nil
    local maxDist = _G.DevSettings.FOVSize
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character and v.Character:FindFirstChild("Head") and v.Character:FindFirstChild("Humanoid") then
            -- Only target living players
            if v.Character.Humanoid.Health <= 0 then continue end
            -- Team Check
            if _G.DevSettings.TeamCheck and v.Team == player.Team then continue end
            
            local pos, onScreen = camera:WorldToViewportPoint(v.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                if dist < maxDist then
                    maxDist = dist
                    target = v
                end
            end
        end
    end
    return target
end

-- --- UTILITY (NO-RAGDOLL FLIPS) ---
local function DoFlip(rotForce, moveDir)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
    
    if root and hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum.PlatformStand = true
        hum.Jump = true
        
        local bg = Instance.new("BodyGyro")
        bg.P = 100000 
        bg.MaxTorque = Vector3.new(math.huge, 0, math.huge) 
        bg.CFrame = root.CFrame
        bg.Parent = root
        
        local vel = Instance.new("BodyAngularVelocity")
        vel.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        vel.AngularVelocity = root.CFrame.RightVector * (rotForce * 2.5); vel.Parent = root
        
        local boost = Instance.new("BodyVelocity")
        boost.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        boost.Velocity = (root.CFrame.LookVector * (moveDir * 60)) + Vector3.new(0, 35, 0); boost.Parent = root
        
        task.delay(0.45, function()
            if vel then vel:Destroy() end
            if bg then bg:Destroy() end
            if boost then boost:Destroy() end
            hum.PlatformStand = false
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end)
    end
end

-- --- UI CREATION ---
local function CreateUI()
    local pGui = player:WaitForChild("PlayerGui")
    if pGui:FindFirstChild("CyanMenu") then pGui.CyanMenu:Destroy() end

    local sg = Instance.new("ScreenGui", pGui)
    sg.Name = "CyanMenu"; sg.ResetOnSpawn = false

    local main = Instance.new("Frame", sg)
    main.Size = UDim2.new(0, 380, 0, 420) 
    main.Position = UDim2.new(0.05, 0, 0.3, 0)
    main.AnchorPoint = Vector2.new(0, 0.5)
    main.BackgroundColor3 = Color3.fromRGB(0, 180, 220)
    main.BackgroundTransparency = 0.25; main.Active = true; main.Draggable = true; main.ClipsDescendants = true 
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", main).Color = Color3.new(1, 1, 1)

    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1, 0, 0, 40); title.BackgroundTransparency = 1; title.Text = "Cal's Cyan Panel [K]"
    title.TextColor3 = Color3.new(1, 1, 1); title.Font = Enum.Font.Ubuntu; title.TextSize = 22

    local tabContainer = Instance.new("Frame", main)
    tabContainer.Size = UDim2.new(1, -20, 0, 35); tabContainer.Position = UDim2.new(0, 10, 0, 45); tabContainer.BackgroundTransparency = 1
    Instance.new("UIListLayout", tabContainer).FillDirection = Enum.FillDirection.Horizontal

    local pages = {}
    local function createPage(name)
        local p = Instance.new("ScrollingFrame", main)
        p.Size = UDim2.new(1, -20, 1, -100); p.Position = UDim2.new(0, 10, 0, 90)
        p.BackgroundTransparency = 1; p.CanvasSize = UDim2.new(0, 0, 0, 600); p.ScrollBarThickness = 0; p.Visible = false
        Instance.new("UIListLayout", p).Padding = UDim.new(0, 8); Instance.new("UIListLayout", p).HorizontalAlignment = Enum.HorizontalAlignment.Center
        pages[name] = p
        
        local btn = Instance.new("TextButton", tabContainer)
        btn.Size = UDim2.new(0.16, 0, 1, 0); btn.BackgroundColor3 = Color3.fromRGB(0, 140, 180); btn.Text = name
        btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.Ubuntu; btn.TextSize = 10; Instance.new("UICorner", btn)
        btn.MouseButton1Click:Connect(function() for _, pg in pairs(pages) do pg.Visible = false end p.Visible = true end)
        return p
    end

    local movePage = createPage("Move"); local combatPage = createPage("Combat"); local visualPage = createPage("Visual"); local tpPage = createPage("TP"); local chatPage = createPage("Chat"); local miscPage = createPage("Misc")
    movePage.Visible = true

    local function makeBtn(name, prop, parent)
        local b = Instance.new("TextButton", parent); b.Size = UDim2.new(1, 0, 0, 40)
        b.BackgroundColor3 = _G.DevSettings[prop] and Color3.fromRGB(0, 220, 100) or Color3.fromRGB(0, 140, 180)
        b.Text = name .. ": " .. (_G.DevSettings[prop] and "ON" or "OFF")
        b.Font = Enum.Font.Ubuntu; b.TextColor3 = Color3.new(1,1,1); b.TextSize = 16; Instance.new("UICorner", b)
        b.MouseButton1Click:Connect(function()
            if prop ~= "None" then
                _G.DevSettings[prop] = not _G.DevSettings[prop]
                b.Text = name .. (_G.DevSettings[prop] and ": ON" or ": OFF")
                b.BackgroundColor3 = _G.DevSettings[prop] and Color3.fromRGB(0, 220, 100) or Color3.fromRGB(0, 140, 180)
            end
        end)
        return b
    end

    -- --- TAB CONTENT ---
    local walkInput = Instance.new("TextBox", movePage); walkInput.Size = UDim2.new(1,0,0,40); walkInput.PlaceholderText = "WalkSpeed"; walkInput.BackgroundColor3 = Color3.fromRGB(0, 120, 160); walkInput.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", walkInput)
    walkInput.FocusLost:Connect(function() _G.DevSettings.Speed = tonumber(walkInput.Text) or 16 end)
    makeBtn("Fly", "Fly", movePage); makeBtn("Noclip", "Noclip", movePage)

    makeBtn("Aimbot (R-Click)", "Aimbot", combatPage)
    makeBtn("Team Check", "TeamCheck", combatPage)
    makeBtn("Show FOV", "ShowFOV", combatPage)
    local fovIn = Instance.new("TextBox", combatPage); fovIn.Size = UDim2.new(1,0,0,40); fovIn.PlaceholderText = "FOV Radius (150)"; fovIn.BackgroundColor3 = Color3.fromRGB(0, 120, 160); fovIn.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", fovIn)
    fovIn.FocusLost:Connect(function() _G.DevSettings.FOVSize = tonumber(fovIn.Text) or 150 end)

    makeBtn("ESP (Fixed)", "ESP", visualPage)

    local function RefreshTPList()
        for _, c in pairs(tpPage:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= player then
                local b = Instance.new("TextButton", tpPage); b.Size = UDim2.new(1, 0, 0, 35); b.BackgroundColor3 = Color3.fromRGB(0, 100, 140); b.Text = "Goto: " .. v.DisplayName; b.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", b)
                b.MouseButton1Click:Connect(function() if v.Character then player.Character:SetPrimaryPartCFrame(v.Character.HumanoidRootPart.CFrame) end end)
            end
        end
    end
    local refBtn = Instance.new("TextButton", tpPage); refBtn.Size = UDim2.new(1, 0, 0, 35); refBtn.Text = "REFRESH"; refBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255); Instance.new("UICorner", refBtn); refBtn.MouseButton1Click:Connect(RefreshTPList); RefreshTPList()

    local btoolBtn = makeBtn("Give BTools", "None", miscPage)
    btoolBtn.MouseButton1Click:Connect(function() for i = 1, 4 do local tool = Instance.new("HopperBin", player.Backpack); tool.BinType = i == 4 and 1 or i end end)
    
    local voidBtn = makeBtn("Void Car (Sitting)", "None", miscPage)
    voidBtn.MouseButton1Click:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart then
            local vehicle = char.Humanoid.SeatPart.Parent
            local target = Players:GetPlayers()[math.random(1, #Players:GetPlayers())]
            if target ~= player and target.Character then
                vehicle:MoveTo(target.Character.HumanoidRootPart.Position); task.wait(0.2); vehicle:MoveTo(Vector3.new(0, -5000, 0))
            end
        end
    end)

    -- --- ANIMATION LOGIC ---
    local isOpen = true; local debouncing = false
    local function ToggleMenu(state)
        if debouncing then return end
        debouncing = true; isOpen = state
        if isOpen then
            main.Visible = true; main.Size = UDim2.new(0, 300, 0, 350); main.BackgroundTransparency = 1
            TweenService:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 380, 0, 420), BackgroundTransparency = 0.25}):Play()
            task.wait(0.4)
        else
            local tw = TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 250, 0, 300), BackgroundTransparency = 1})
            tw:Play(); tw.Completed:Connect(function() if not isOpen then main.Visible = false end end)
            task.wait(0.3)
        end
        debouncing = false
    end

    if TeleportService:GetTeleportSetting("CyanAutoOpen") then TeleportService:SetTeleportSetting("CyanAutoOpen", false); isOpen = true; main.Visible = true else isOpen = false; main.Visible = false end

    SendNotification("Hi, " .. player.Name .. "!")

    UIS.InputBegan:Connect(function(io, t)
        if not t and io.KeyCode == Enum.KeyCode.K then ToggleMenu(not isOpen)
        elseif not t and io.KeyCode == Enum.KeyCode.Z then DoFlip(-15, -1) 
        elseif not t and io.KeyCode == Enum.KeyCode.X then DoFlip(15, 1) 
        end
    end)
end

-- --- ENGINES ---
RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = _G.DevSettings.ShowFOV
    FOVCircle.Radius = _G.DevSettings.FOVSize
    FOVCircle.Position = UIS:GetMouseLocation()

    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        -- FIXED AIMBOT LOGIC
        if _G.DevSettings.Aimbot and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = GetClosestToMouse()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                -- Camera Aim
                camera.CFrame = CFrame.new(camera.CFrame.Position, target.Character.Head.Position)
                -- Body Lock (Looks towards enemy torso level)
                local targetPos = target.Character.HumanoidRootPart.Position
                local lookAt = Vector3.new(targetPos.X, char.HumanoidRootPart.Position.Y, targetPos.Z)
                char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position, lookAt)
            end
        end

        if _G.DevSettings.Fly then
            char.HumanoidRootPart.Velocity = Vector3.zero
            local move = Vector3.zero
            if UIS:IsKeyDown("W") then move = move + camera.CFrame.LookVector end
            if UIS:IsKeyDown("S") then move = move - camera.CFrame.LookVector end
            char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + (move * 1.25)
        end
        
        -- ESP Logic
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local high = p.Character:FindFirstChild("CyanESP")
                if _G.DevSettings.ESP then
                    if not high then
                        high = Instance.new("Highlight", p.Character)
                        high.Name = "CyanESP"; high.FillColor = Color3.new(0,1,1); high.OutlineColor = Color3.new(1,1,1)
                    end
                elseif high then high:Destroy() end
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = _G.DevSettings.Speed
        if _G.DevSettings.Noclip then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end
end)

CreateUI()
player.CharacterAdded:Connect(CreateUI)
