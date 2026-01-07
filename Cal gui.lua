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
    Speed = 16, Noclip = false, Fly = false, ESP = false, Orbit = false, ClickTP = false, SpinSpeed = 0
}

-- --- UTILITY ---
local function DoFlip(force)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then
        local vel = Instance.new("BodyAngularVelocity")
        vel.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        vel.AngularVelocity = root.CFrame.RightVector * force
        vel.Parent = root
        task.wait(0.3)
        vel:Destroy()
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
        btn.Size = UDim2.new(0.2, 0, 1, 0); btn.BackgroundColor3 = Color3.fromRGB(0, 140, 180); btn.Text = name
        btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.Ubuntu; btn.TextSize = 11; Instance.new("UICorner", btn)
        btn.MouseButton1Click:Connect(function() for _, pg in pairs(pages) do pg.Visible = false end p.Visible = true end)
        return p
    end

    local movePage = createPage("Move"); local visualPage = createPage("Visual"); local tpPage = createPage("Teleport"); local chatPage = createPage("Chat"); local miscPage = createPage("Misc")
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

    -- --- TABS CONTENT ---
    local walkInput = Instance.new("TextBox", movePage); walkInput.Size = UDim2.new(1,0,0,40); walkInput.PlaceholderText = "Set WalkSpeed"; walkInput.BackgroundColor3 = Color3.fromRGB(0, 120, 160); walkInput.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", walkInput)
    walkInput.FocusLost:Connect(function(ep) if ep then _G.DevSettings.Speed = tonumber(walkInput.Text) or 16 end end)
    local spinInput = Instance.new("TextBox", movePage); spinInput.Size = UDim2.new(1,0,0,40); spinInput.PlaceholderText = "Spin Power (0 to stop)"; spinInput.BackgroundColor3 = Color3.fromRGB(0, 120, 160); spinInput.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", spinInput)
    spinInput.FocusLost:Connect(function(ep) if ep then _G.DevSettings.SpinSpeed = tonumber(spinInput.Text) or 0 end end)
    makeBtn("Fly", "Fly", movePage); makeBtn("Noclip", "Noclip", movePage)
    makeBtn("ESP Info & Outline", "ESP", visualPage)

    local function RefreshTPList()
        for _, c in pairs(tpPage:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= player then
                local b = Instance.new("TextButton", tpPage); b.Size = UDim2.new(1, 0, 0, 35); b.BackgroundColor3 = Color3.fromRGB(0, 100, 140); b.Text = "Goto: " .. v.DisplayName; b.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", b)
                b.MouseButton1Click:Connect(function() if v.Character then player.Character:SetPrimaryPartCFrame(v.Character.HumanoidRootPart.CFrame) end end)
            end
        end
    end
    local refBtn = Instance.new("TextButton", tpPage); refBtn.Size = UDim2.new(1, 0, 0, 35); refBtn.Text = "REFRESH LIST"; refBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255); Instance.new("UICorner", refBtn); refBtn.MouseButton1Click:Connect(RefreshTPList); RefreshTPList()

    local targetInput = Instance.new("TextBox", chatPage); targetInput.Size = UDim2.new(1,0,0,40); targetInput.PlaceholderText = "Target Username"; targetInput.BackgroundColor3 = Color3.fromRGB(0, 120, 160); targetInput.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", targetInput)
    local msgInput = Instance.new("TextBox", chatPage); msgInput.Size = UDim2.new(1,0,0,40); msgInput.PlaceholderText = "Bubble Message"; msgInput.BackgroundColor3 = Color3.fromRGB(0, 120, 160); msgInput.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", msgInput)
    local forceBtn = makeBtn("Force Bubble", "None", chatPage)
    forceBtn.MouseButton1Click:Connect(function()
        for _, v in pairs(Players:GetPlayers()) do if targetInput.Text:lower() == "all" or v.Name:lower():find(targetInput.Text:lower()) then Chat:Chat(v.Character.Head, msgInput.Text, "White") end end
    end)

    local btoolBtn = makeBtn("Give BTools", "None", miscPage)
    btoolBtn.MouseButton1Click:Connect(function() for i = 1, 4 do local tool = Instance.new("HopperBin", player.Backpack); tool.BinType = i == 4 and 1 or i end end)
    local skyBtn = makeBtn("Hack Skybox", "None", miscPage)
    skyBtn.MouseButton1Click:Connect(function()
        local sky = Instance.new("Sky", Lighting); sky.SkyboxBk = "rbxassetid://0"; sky.SkyboxDn = "rbxassetid://0"; sky.SkyboxFt = "rbxassetid://0"; sky.SkyboxLf = "rbxassetid://0"; sky.SkyboxRt = "rbxassetid://0"; sky.SkyboxUp = "rbxassetid://0"; sky.CelestialBodiesShown = false; Lighting.Ambient = Color3.fromRGB(0, 180, 220)
        local hackGui = Instance.new("ScreenGui", pGui); local txt = Instance.new("TextLabel", hackGui); txt.Size = UDim2.new(1, 0, 0, 100); txt.Position = UDim2.new(0, 0, 0.4, 0); txt.BackgroundTransparency = 1; txt.TextColor3 = Color3.new(0, 1, 1); txt.Font = Enum.Font.Arcade; txt.TextSize = 60; txt.Text = "YOU HAVE BEEN HACKED BY CAL"
    end)

    -- NEW: VOID CAR BUTTON
    local voidBtn = makeBtn("Void Car (Sitting)", "None", miscPage)
    voidBtn.MouseButton1Click:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart then
            local vehicle = char.Humanoid.SeatPart.Parent
            local allPlayers = Players:GetPlayers()
            local target = allPlayers[math.random(1, #allPlayers)]
            if target ~= player and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                vehicle:MoveTo(target.Character.HumanoidRootPart.Position)
                task.wait(0.2)
                vehicle:MoveTo(Vector3.new(0, -5000, 0))
            end
        end
    end)

    makeBtn("Orbit Unanchored", "Orbit", miscPage); makeBtn("Click TP [Hold R]", "ClickTP", miscPage)
    local rjBtn = makeBtn("Rejoin Server", "None", miscPage); rjBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    rjBtn.MouseButton1Click:Connect(function() TeleportService:SetTeleportSetting("CyanAutoOpen", true); TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)

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

    UIS.InputBegan:Connect(function(io, t)
        if not t and io.KeyCode == Enum.KeyCode.K then ToggleMenu(not isOpen)
        elseif not t and io.KeyCode == Enum.KeyCode.Z then DoFlip(15)
        elseif not t and io.KeyCode == Enum.KeyCode.X then DoFlip(-15)
        elseif not t and io.UserInputType == Enum.UserInputType.MouseButton1 and _G.DevSettings.ClickTP and UIS:IsKeyDown(Enum.KeyCode.R) then
            if player.Character and mouse.Hit then player.Character:MoveTo(mouse.Hit.Position) end
        end
    end)
end

-- --- ENGINES ---
local orbitTick = 0
RunService.RenderStepped:Connect(function()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    if _G.DevSettings.Fly then
        char.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        local moveDir = Vector3.new(0,0,0)
        if UIS:IsKeyDown("W") then moveDir = moveDir + camera.CFrame.LookVector end
        if UIS:IsKeyDown("S") then moveDir = moveDir - camera.CFrame.LookVector end
        if UIS:IsKeyDown("A") then moveDir = moveDir - camera.CFrame.RightVector end
        if UIS:IsKeyDown("D") then moveDir = moveDir + camera.CFrame.RightVector end
        char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + (moveDir * 1.25)
    end
    if _G.DevSettings.SpinSpeed > 0 then char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(_G.DevSettings.SpinSpeed), 0) end
    if _G.DevSettings.Orbit then
        orbitTick = orbitTick + 0.04
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(char) then
                if (part.Position - char.HumanoidRootPart.Position).Magnitude < 100 then
                    local angle = orbitTick + (part:GetHashCode() % 10); local targetPos = char.HumanoidRootPart.Position + Vector3.new(math.cos(angle) * 12, 5, math.sin(angle) * 12); part.Velocity = (targetPos - part.Position) * 25; part.CanCollide = false
                end
            end
        end
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head; local tag = head:FindFirstChild("CyanESP"); local highlight = p.Character:FindFirstChild("CyanOutline")
            if _G.DevSettings.ESP then
                if not tag then
                    tag = Instance.new("BillboardGui", head); tag.Name = "CyanESP"; tag.Size = UDim2.new(0, 200, 0, 50); tag.AlwaysOnTop = true; tag.ExtentsOffset = Vector3.new(0, 3, 0)
                    local txt = Instance.new("TextLabel", tag); txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.TextColor3 = Color3.new(0, 1, 1); txt.Font = Enum.Font.Ubuntu; txt.TextSize = 14; txt.Name = "Info"
                end
                tag.Info.Text = p.DisplayName .. "\nHP: " .. math.floor(p.Character.Humanoid.Health) .. " | Dist: " .. math.floor((head.Position - char.HumanoidRootPart.Position).Magnitude)
                if not highlight then highlight = Instance.new("Highlight", p.Character); highlight.Name = "CyanOutline"; highlight.OutlineColor = Color3.new(0, 1, 1); highlight.FillTransparency = 0.6; highlight.DepthMode = "AlwaysOnTop" end
            else
                if tag then tag:Destroy() end; if highlight then highlight:Destroy() end
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = _G.DevSettings.Speed
        if _G.DevSettings.Noclip then for _, v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
    end
end)

CreateUI()
player.CharacterAdded:Connect(CreateUI)