local RS, UIS, VIM, TS = game:GetService("RunService"), game:GetService("UserInputService"), game:GetService("VirtualInputManager"), game:GetService("TweenService")
local Players, Stats, SoundService, Debris = game:GetService("Players"), game:GetService("Stats"), game:GetService("SoundService"), game:GetService("Debris")
local pl = Players.LocalPlayer
local Ev = game:GetService("ReplicatedStorage").UT_BLINK_RELIABLE_REMOTE
local par = (gethui and gethui()) or game:GetService("CoreGui")

local LOGO_URL = "https://i.pinimg.com/736x/b9/a3/e4/b9a3e4f0af14cfe3d953dfd9b4d87d8d.jpg"
local SLASH_URL = "https://www.myinstants.com/media/sounds/undertale-slash.mp3"
local HEAVY_URL = "https://www.myinstants.com/media/sounds/undertale-heavy-hit.mp3"
local TEXT_URL = "https://www.myinstants.com/media/sounds/undertale-text.mp3"
local VANISH_URL = "https://www.myinstants.com/media/sounds/gaster-vanish.mp3"
local LAUGH_URL = "https://www.myinstants.com/media/sounds/flowey-udnertale-laugh.mp3"
local CHARA_URL = "https://i.pinimg.com/736x/c5/4c/0f/c54c0fdae6a9bd2336122e7e190d4881.jpg"
local LAUGH_TIME = 2.5    -- seconds to wait for the laugh before the slashes start
local SMALL_SLASHES = 3   -- how many small slashes before the huge one (max 5)
local ICONS = {
    {name = "Natsuki",        url = "https://i.pinimg.com/736x/af/f6/63/aff663b8b0907d12ebf8bcd30ebaa917.jpg"},
    {name = "Abbie",          url = "https://i.pinimg.com/736x/19/d6/d8/19d6d8b147505c5f82a4e44d69c64109.jpg"},
    {name = "Miss Circle",    url = "https://i.pinimg.com/1200x/41/cb/0f/41cb0f911b73905bd8f5f5e53df4cd6b.jpg"},
    {name = "Ena",            url = "https://i.pinimg.com/736x/62/ac/ff/62acffed78e169a5d0c0dbd46000ccdf.jpg"},
    {name = "Ena dream bbq",  url = "https://i.pinimg.com/736x/32/2d/aa/322daac377dce1aa59078bff50b5b03a.jpg"},
}

-- name = button text, mob = name inside workspace.Mobs, spawn = where Auto Start teleports you
local BOSSES = {
    {name = "Golden Freddy",  mob = "Golden Freddy",  spawn = CFrame.new(1285, 342, -1517)},
    {name = "Bonnie",         mob = "Bonnie",         spawn = CFrame.new(1189, 346, -1597)},
    {name = "Chica",          mob = "Chica",          spawn = CFrame.new(1212, 346, -1597)},
    {name = "Freddy Fazbear", mob = "Freddy Fazbear", spawn = CFrame.new(1199, 346, -1597)},
    {name = "Foxy",           mob = "Foxy",           spawn = CFrame.new(1143, 344, -1563)},
}
local BI = 1 -- selected boss index

local function new(c, p, parent)
    local i = Instance.new(c)
    for k, v in pairs(p) do i[k] = v end
    i.Parent = parent
    return i
end

for _, n in ipairs({"NatsukiIntro", "NatsukiPrompt", "NatsukiStart", "NatsukiSlash", "NatsukiBlack", "NatsukiHub"}) do
    local o = par:FindFirstChild(n)
    if o then o:Destroy() end
end

local function dl(url, file)
    local ok, asset = pcall(function()
        writefile(file, game:HttpGet(url))
        return getcustomasset(file)
    end)
    return ok and asset or nil
end

local logoAsset = dl(LOGO_URL, "natsuki_logo.jpg")
local charaAsset = dl(CHARA_URL, "natsuki_chara.jpg")
local BLACK, WHITE = Color3.new(0, 0, 0), Color3.new(1, 1, 1)

-- sounds download in the background
local slashAsset, heavyAsset, textAsset, vanishAsset, laughAsset, soundsDone
task.spawn(function()
    textAsset = dl(TEXT_URL, "natsuki_text.mp3")
    slashAsset = dl(SLASH_URL, "natsuki_slash.mp3")
    heavyAsset = dl(HEAVY_URL, "natsuki_heavy.mp3")
    vanishAsset = dl(VANISH_URL, "natsuki_vanish.mp3")
    laughAsset = dl(LAUGH_URL, "natsuki_laugh.mp3")
    soundsDone = true
end)

local function playSnd(asset, vol)
    if not asset then return end
    local s = new("Sound", {SoundId = asset, Volume = vol or 1}, SoundService)
    s:Play()
    Debris:AddItem(s, 6)
end

-- Undertale-style jitter
local function shake(obj, base, amt, rate)
    local last = 0
    return RS.Heartbeat:Connect(function()
        if os.clock() - last < (rate or .04) then return end
        last = os.clock()
        obj.Position = base + UDim2.fromOffset(math.random(-amt, amt), math.random(-amt, amt))
    end)
end

-- ================= Start screen (nothing runs until START is clicked) =================
local started, ready = false, false
local startGui = new("ScreenGui", {Name = "NatsukiStart", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 1000}, par)
local sbg = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BorderSizePixel = 0}, startGui)
local slogo = new("ImageLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(110, 110), Position = UDim2.new(0.5, 0, 0.14, 0),
    BackgroundTransparency = 1, ImageTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = logoAsset or "",
}, sbg)
local titleBase = UDim2.new(0.5, 0, 0.14, 85)
local stitle = new("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(420, 40), Position = titleBase,
    BackgroundTransparency = 1, Text = "NATSUKI HUB", TextColor3 = WHITE, Font = Enum.Font.Arcade, TextSize = 34, TextTransparency = 1,
}, sbg)
local titleShake = shake(stitle, titleBase, 2, .04)

-- Chara + speech bubble
local charaBase = UDim2.new(0.5, -170, 0.52, 0)
local chara = new("ImageLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(150, 150), Position = charaBase,
    BackgroundTransparency = 1, ImageTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = charaAsset or "",
}, sbg)
local tail = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, -85, 0.52, 0), Size = UDim2.fromOffset(18, 18),
    Rotation = 45, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1, Visible = false,
}, sbg)
new("UIStroke", {Color = BLACK, Thickness = 3}, tail)
local bubble = new("Frame", {
    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.5, -85, 0.52, 0), Size = UDim2.fromOffset(280, 90),
    BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2, Visible = false,
}, sbg)
new("UIStroke", {Color = BLACK, Thickness = 4}, bubble)
local btext = new("TextLabel", {
    Size = UDim2.new(1, -20, 1, -16), Position = UDim2.fromOffset(10, 8), BackgroundTransparency = 1, Text = "",
    TextColor3 = BLACK, Font = Enum.Font.Arcade, TextSize = 22, TextWrapped = true, ZIndex = 5,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
}, bubble)

-- typewriter: reveals the text letter by letter and plays the Undertale text blip
local function say(text, delay)
    btext.Text = ""
    for i = 1, #text do
        btext.Text = string.sub(text, 1, i)
        if string.sub(text, i, i) ~= " " then playSnd(textAsset, .5) end
        task.wait(delay or .06)
    end
end

local sbtn = new("TextButton", {
    AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(200, 50), Position = UDim2.new(0.5, 0, 0.82, 0),
    BackgroundColor3 = BLACK, BorderSizePixel = 0, Text = "START", TextColor3 = WHITE, Font = Enum.Font.Arcade,
    TextSize = 26, AutoButtonColor = false, TextTransparency = 1,
}, sbg)
local sstroke = new("UIStroke", {Color = WHITE, Thickness = 3, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, sbtn)
local heart = new("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(30, 30), Position = UDim2.new(0.5, -135, 0.82, 0),
    BackgroundTransparency = 1, Text = "♥", TextColor3 = Color3.fromRGB(255, 30, 30), Font = Enum.Font.GothamBold, TextSize = 26, TextTransparency = 1,
}, sbg)
local scredit = new("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(400, 20), Position = UDim2.new(0.5, 0, 0.95, 0),
    BackgroundTransparency = 1, Text = "thanks for use my script  -  COF", TextColor3 = Color3.fromRGB(130, 130, 140),
    Font = Enum.Font.Gotham, TextSize = 13, TextTransparency = 1,
}, sbg)

do
    local fi = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    TS:Create(slogo, fi, {ImageTransparency = 0}):Play()
    TS:Create(chara, fi, {ImageTransparency = 0}):Play()
    TS:Create(stitle, fi, {TextTransparency = 0}):Play()
    TS:Create(sbtn, fi, {TextTransparency = 0}):Play()
    TS:Create(sstroke, fi, {Transparency = 0}):Play()
    TS:Create(heart, fi, {TextTransparency = 0}):Play()
    TS:Create(scredit, fi, {TextTransparency = 0}):Play()
end

-- Chara greets you
task.spawn(function()
    task.wait(1.3)
    -- wait for the text sound so the first letters aren't silent
    local t0 = os.clock()
    while not textAsset and os.clock() - t0 < 4 do task.wait() end
    tail.Visible, bubble.Visible = true, true
    say("Let's start, Partner..", .07)
    ready = true
end)

sbtn.MouseEnter:Connect(function()
    if not started then sbtn.TextColor3 = Color3.fromRGB(255, 255, 0) sstroke.Color = Color3.fromRGB(255, 255, 0) end
end)
sbtn.MouseLeave:Connect(function()
    if not started then sbtn.TextColor3 = WHITE sstroke.Color = WHITE end
end)
sbtn.MouseButton1Click:Connect(function()
    if started or not ready then return end
    started = true
end)

-- ================= Farm logic =================
local S = {Stop = 8, WDelay = 3, SDelay = 8}
local CANDY = "Monster Candy"
local B = {
    set = {54,1,7,83,101,116,116,105,110,103},
    start = {54,1,5,83,116,97,114,116},
    join = {112,1,4,74,111,105,110}, -- "Join" (Night Shift instant join)
}
local function buf(t) local b = buffer.create(#t) for i = 1, #t do buffer.writeu8(b, i - 1, t[i]) end return b end
local function setS(n, v) Ev:FireServer(buf(B.set), {n, v}) end
local function pressKey(k) pcall(function() VIM:SendKeyEvent(true, k, false, game) task.wait(.05) VIM:SendKeyEvent(false, k, false, game) end) end

-- Builds the OnEquipped packet for any tool name: 3,1,1,<name length>,<name>,10,"OnEquipped"
local function equipBytes(name)
    local t = {3, 1, 1, #name}
    for i = 1, #name do t[#t + 1] = string.byte(name, i) end
    t[#t + 1] = 10
    for i = 1, 10 do t[#t + 1] = string.byte("OnEquipped", i) end
    return t
end

-- Equips a specific tool by name (used for Monster Candy)
local function equip(n)
    local c = pl.Character local h = c and c:FindFirstChildOfClass("Humanoid") if not h then return end
    local t = c:FindFirstChild(n)
    if not t then
        local bp = pl.Backpack:FindFirstChild(n) if not bp then return end
        h:EquipTool(bp) t = c:WaitForChild(n, 3)
    end
    if t then Ev:FireServer(buf(equipBytes(n)), {{t}}) end
    return t
end

-- Hotbar slot 1 (whatever weapon is in it)
local function slotButton()
    local inv = pl.PlayerGui:FindFirstChild("Inventory")
    local main = inv and inv:FindFirstChild("Main")
    local hotbar = main and main:FindFirstChild("Hotbar")
    return hotbar and hotbar:FindFirstChild("FullSlot1")
end
local function clickSlot()
    local s = slotButton()
    if not s then return false end
    local btn = s:IsA("GuiButton") and s
    if not btn then
        for _, d in ipairs(s:GetDescendants()) do
            if d:IsA("GuiButton") then btn = d break end
        end
    end
    if not btn then return false end
    pcall(function()
        firesignal(btn.MouseButton1Click)
        firesignal(btn.Activated)
    end)
    return true
end

-- The weapon currently held = any tool in your character that isn't the candy
local function heldWeapon()
    local c = pl.Character
    if not c then return nil end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t.Name ~= CANDY then return t end
    end
end

-- Auto equip slot 1. Only clicks when no weapon is held (clicking again would unequip it)
local function equipWeapon()
    local w = heldWeapon()
    if w then return w end
    clickSlot()
    for _ = 1, 12 do
        task.wait(.05)
        w = heldWeapon()
        if w then return w end
    end
    pressKey(Enum.KeyCode.One) -- fallback: the "1" hotkey
    for _ = 1, 12 do
        task.wait(.05)
        w = heldWeapon()
        if w then return w end
    end
end

-- Hitbox of the currently selected boss: workspace.Mobs.<mob>.Hitbox
local function hb()
    local m = workspace:FindFirstChild("Mobs")
    local b = m and m:FindFirstChild(BOSSES[BI].mob)
    return b and b:FindFirstChild("Hitbox")
end
local function pos(h) return h:IsA("BasePart") and h.Position or h:GetPivot().Position end

-- everything starts OFF
local F = {Farm = false, AutoStart = false, Candy = false, Skill = false, Black = false}
local sid, conn, swap = 0, nil, false
local function alive(i) return F.Farm and sid == i end

local function start()
    sid += 1 local id = sid swap = false
    if conn then conn:Disconnect() conn = nil end
    task.spawn(function()
        if F.AutoStart then
            local c = pl.Character or pl.CharacterAdded:Wait()
            c:WaitForChild("HumanoidRootPart").CFrame = BOSSES[BI].spawn
            task.wait(1) if not alive(id) then return end
            setS("Cutscenes", false) task.wait(.2) setS("Grind", true) task.wait(.5)
            if not alive(id) then return end
            Ev:FireServer(buf(B.start), {newproxy(), newproxy()})
        end
        local cur, at
        conn = RS.Heartbeat:Connect(function()
            if not alive(id) then return end
            local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") if not r then return end
            local h = hb()
            if h and h ~= cur then cur = h at = os.clock() elseif not h and cur then cur = nil end
            r.Anchored = false
            -- teleport next to the target (S.Stop studs away), only when we're not already there
            if h and os.clock() - at >= S.WDelay then
                local tpos = pos(h)
                local flat = Vector3.new(r.Position.X - tpos.X, 0, r.Position.Z - tpos.Z)
                local dist = flat.Magnitude
                r.AssemblyLinearVelocity = Vector3.zero r.AssemblyAngularVelocity = Vector3.zero
                if dist > S.Stop + 1 or math.abs(r.Position.Y - tpos.Y) > 4 then
                    local dir = dist > 0.1 and flat.Unit or Vector3.new(0, 0, 1)
                    local np = Vector3.new(tpos.X, tpos.Y, tpos.Z) + dir * S.Stop
                    r.CFrame = CFrame.lookAt(np, Vector3.new(tpos.X, np.Y, tpos.Z))
                end
            end
        end)
        task.spawn(function() -- auto equip slot 1 + clicking
            while alive(id) do
                if not swap then
                    local t = heldWeapon() or equipWeapon()
                    if t then t:Activate() end
                end
                task.wait(.05)
            end
        end)
        task.spawn(function() -- skill E
            local last, was = os.clock(), false
            while alive(id) do
                local a = F.Skill and not swap and heldWeapon() ~= nil and hb() ~= nil
                if a and not was then last = os.clock() end
                was = a
                if a and os.clock() - last >= S.SDelay then pressKey(Enum.KeyCode.E) last = os.clock() end
                task.wait(.2)
            end
        end)
        task.spawn(function() -- candy swap
            while alive(id) do
                task.wait(10) if not alive(id) then break end
                if F.Candy then
                    swap = true
                    local c = equip(CANDY)
                    if c then task.wait(.3) c:Activate() task.wait(.5) else warn("Monster Candy not found") end
                    equipWeapon() task.wait(.2) swap = false
                end
            end
            swap = false
        end)
    end)
end

local function stop()
    sid += 1 swap = false
    if conn then conn:Disconnect() conn = nil end
    local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
    if r then r.Anchored = false r.AssemblyLinearVelocity = Vector3.zero end
end

-- ================= HUD icon changer =================
local selIcon, iconWant, iconTarget, iconOrig, iconConn = 0, nil, nil, nil, nil
local iconRefresh = {}
local function refreshIcons() for _, f in ipairs(iconRefresh) do f() end end

local function findIcon()
    local m = pl.PlayerGui:FindFirstChild("Main")
    local bl = m and m:FindFirstChild("BottomLeft")
    local mm = bl and bl:FindFirstChild("Main")
    local pi = mm and mm:FindFirstChild("PlayerIcon")
    if not pi then return nil end
    return pi:FindFirstChild("PlayerImage")
        or ((pi:IsA("ImageLabel") or pi:IsA("ImageButton")) and pi or nil)
        or pi:FindFirstChildWhichIsA("ImageLabel", true)
end

local function setIcon(i)
    selIcon = i
    refreshIcons()
    task.spawn(function()
        local img = findIcon()
        if not img then warn("PlayerIcon image not found") return end
        if iconTarget ~= img then
            if iconConn then iconConn:Disconnect() iconConn = nil end
            iconTarget, iconOrig = img, img.Image
            iconConn = img:GetPropertyChangedSignal("Image"):Connect(function()
                if iconWant and img.Image ~= iconWant then img.Image = iconWant end
            end)
        end
        if i == 0 then
            iconWant = nil
            img.Image = iconOrig or ""
            return
        end
        local ic = ICONS[i]
        if not ic.asset then ic.asset = dl(ic.url, "natsuki_icon" .. i .. ".jpg") end
        if not ic.asset then warn("Icon download failed") return end
        iconWant = ic.asset
        img.Image = ic.asset
    end)
end

pl.CharacterAdded:Connect(function()
    if selIcon ~= 0 then task.wait(2) setIcon(selIcon) end
end)

-- ================= Theme system =================
local PRESETS = {
    {"Natsuki", Color3.fromRGB(150, 100, 255), Color3.fromRGB(18, 18, 24), Color3.fromRGB(30, 28, 42)},
    {"Ocean",   Color3.fromRGB(50, 150, 255),  Color3.fromRGB(14, 20, 30), Color3.fromRGB(24, 34, 50)},
    {"Crimson", Color3.fromRGB(235, 60, 80),   Color3.fromRGB(22, 14, 16), Color3.fromRGB(40, 24, 28)},
    {"Emerald", Color3.fromRGB(50, 205, 120),  Color3.fromRGB(14, 22, 18), Color3.fromRGB(24, 40, 32)},
    {"Sakura",  Color3.fromRGB(255, 130, 180), Color3.fromRGB(28, 18, 24), Color3.fromRGB(46, 28, 38)},
    {"Mono",    Color3.fromRGB(220, 220, 230), Color3.fromRGB(14, 14, 14), Color3.fromRGB(30, 30, 30)},
}
local T = {accent = PRESETS[1][2], bg = PRESETS[1][3], card = PRESETS[1][4], text = Color3.fromRGB(235, 235, 245), sub = Color3.fromRGB(150, 150, 170)}
T.off = T.card:Lerp(WHITE, 0.15)

local reg, refreshers = {}, {}
local function themed(obj, prop, key) table.insert(reg, {obj, prop, key}) obj[prop] = T[key] return obj end
local headerGrad, stroke
local function applyTheme()
    T.off = T.card:Lerp(WHITE, 0.15)
    for _, r in ipairs(reg) do r[1][r[2]] = T[r[3]] end
    if headerGrad then headerGrad.Color = ColorSequence.new(T.accent:Lerp(BLACK, 0.45), T.card) end
    if stroke then stroke.Color = T.accent end
    for _, f in ipairs(refreshers) do f() end
end
local function round(o, r) new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end

-- click animation (quick squash + bounce back)
local function press(o)
    local s = o:FindFirstChild("PressScale") or new("UIScale", {Name = "PressScale"}, o)
    TS:Create(s, TweenInfo.new(.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = .94}):Play()
    task.delay(.08, function()
        TS:Create(s, TweenInfo.new(.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    end)
end

-- ================= Black backdrop =================
local blackGui = new("ScreenGui", {Name = "NatsukiBlack", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 900, Enabled = false}, par)
new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BorderSizePixel = 0}, blackGui)

-- ================= GUI (landscape, sidebar left) =================
local ord = 0
local function nextOrd() ord += 1 return ord end

local cam = workspace.CurrentCamera
local vp = (cam and cam.ViewportSize) or Vector2.new(800, 500)
local W, H = math.clamp(vp.X - 24, 300, 560), math.clamp(vp.Y - 24, 220, 340)
local SB = 120

local gui = new("ScreenGui", {Name = "NatsukiHub", ResetOnSpawn = false, DisplayOrder = 950, Enabled = false}, par)
local live = false
local function syncBlack() blackGui.Enabled = live and F.Black and gui.Enabled end

local frame = themed(new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(W, H), BorderSizePixel = 0, ClipsDescendants = true,
}, gui), "BackgroundColor3", "bg")
round(frame, 10)
stroke = new("UIStroke", {Color = T.accent, Thickness = 1.2, Transparency = 0.3}, frame)

-- header
local header = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = WHITE, BorderSizePixel = 0}, frame)
headerGrad = new("UIGradient", {Rotation = 0}, header)
new("ImageLabel", {Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(8, 6), BackgroundTransparency = 1, Image = logoAsset or "", ScaleType = Enum.ScaleType.Fit}, header)
local hubTitle = new("TextLabel", {
    Size = UDim2.new(0, 150, 1, 0), Position = UDim2.fromOffset(44, 0), BackgroundTransparency = 1,
    Text = "Natsuki Hub", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
}, header)
shake(hubTitle, UDim2.fromOffset(44, 0), 1, .05)
local statLbl = new("TextLabel", {
    Size = UDim2.new(0, 190, 1, 0), Position = UDim2.new(1, -258, 0, 0), BackgroundTransparency = 1, Text = "FPS: --  |  Ping: --",
    TextColor3 = T.text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, RichText = true, Visible = W >= 460,
}, header)
local minBtn = new("TextButton", {Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -62, 0, 7), BackgroundTransparency = 1, Text = "-", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 20}, header)
local closeBtn = new("TextButton", {Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -32, 0, 7), BackgroundTransparency = 1, Text = "X", TextColor3 = Color3.fromRGB(255, 100, 100), Font = Enum.Font.GothamBold, TextSize = 14}, header)

-- body
local body = new("Frame", {Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40), BackgroundTransparency = 1}, frame)
local sidebar = themed(new("Frame", {Size = UDim2.new(0, SB, 1, 0), BorderSizePixel = 0}, body), "BackgroundColor3", "card")
local content = new("Frame", {Position = UDim2.fromOffset(SB + 8, 8), Size = UDim2.new(1, -(SB + 16), 1, -16), BackgroundTransparency = 1, ClipsDescendants = true}, body)

local selector = themed(new("Frame", {Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 8), BorderSizePixel = 0}, sidebar), "BackgroundColor3", "accent")
round(selector, 6)

local TABS = {"Main", "Player", "Icons", "Theme"}
local pages, sfs, tabBtns = {}, {}, {}
for idx, name in ipairs(TABS) do
    local cg = new("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false}, content)
    local sf = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y,
    }, cg)
    new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, sf)
    new("UIPadding", {PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}, sf)
    pages[name], sfs[name] = cg, sf

    local b = new("TextButton", {
        Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 8 + (idx - 1) * 36), BackgroundTransparency = 1,
        BorderSizePixel = 0, Text = name, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.sub, AutoButtonColor = false,
    }, sidebar)
    tabBtns[name] = b
end
local pMain, pPlayer, pIcons, pTheme = sfs.Main, sfs.Player, sfs.Icons, sfs.Theme

local currentTab = "Main"
local function showTab(name, anim)
    currentTab = name
    for n, p in pairs(pages) do if n ~= name then p.Visible = false end end
    TS:Create(selector, TweenInfo.new(.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = tabBtns[name].Position}):Play()
    for n, b in pairs(tabBtns) do
        TS:Create(b, TweenInfo.new(.2), {TextColor3 = (n == name) and WHITE or T.sub}):Play()
    end
    local p = pages[name]
    p.Visible = true
    if anim then
        p.GroupTransparency = 1
        p.Position = UDim2.fromOffset(0, 18)
        TS:Create(p, TweenInfo.new(.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)}):Play()
    else
        p.GroupTransparency = 0
        p.Position = UDim2.fromOffset(0, 0)
    end
end
for n, b in pairs(tabBtns) do
    b.MouseButton1Click:Connect(function() press(b) showTab(n, true) end)
end

-- builders
local function toggle(page, label, flag, onChange)
    local row = themed(new("TextButton", {Size = UDim2.new(1, 0, 0, 32), BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = nextOrd()}, page), "BackgroundColor3", "card")
    round(row, 8)
    themed(new("TextLabel", {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Text = label, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}, row), "TextColor3", "text")
    local pill = new("Frame", {Size = UDim2.fromOffset(38, 20), Position = UDim2.new(1, -48, 0.5, -10), BorderSizePixel = 0}, row)
    round(pill, 10)
    local knob = new("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0}, pill)
    round(knob, 8)
    local function refresh()
        local on = F[flag]
        TS:Create(pill, TweenInfo.new(.15), {BackgroundColor3 = on and T.accent or T.off}):Play()
        TS:Create(knob, TweenInfo.new(.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = on and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2)}):Play()
    end
    refresh()
    refreshers[#refreshers + 1] = refresh
    row.MouseButton1Click:Connect(function()
        press(row)
        F[flag] = not F[flag]
        refresh()
        if onChange then onChange(F[flag]) end
    end)
    return refresh
end

local function slider(page, name, min, max, step, get, set)
    local row = themed(new("Frame", {Size = UDim2.new(1, 0, 0, 40), BorderSizePixel = 0, LayoutOrder = nextOrd()}, page), "BackgroundColor3", "card")
    round(row, 8)
    local lbl = themed(new("TextLabel", {Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 3), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left}, row), "TextColor3", "text")
    local barF = themed(new("Frame", {Size = UDim2.new(1, -20, 0, 6), Position = UDim2.fromOffset(10, 27), BorderSizePixel = 0}, row), "BackgroundColor3", "off")
    round(barF, 3)
    local fill = themed(new("Frame", {Size = UDim2.fromScale(0, 1), BorderSizePixel = 0}, barF), "BackgroundColor3", "accent")
    round(fill, 3)
    local hit = new("TextButton", {Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 20), BackgroundTransparency = 1, Text = ""}, row)
    local function update()
        fill.Size = UDim2.fromScale((get() - min) / (max - min), 1)
        lbl.Text = name .. ": " .. get()
    end
    update()
    refreshers[#refreshers + 1] = update
    local sliding = false
    local function setX(x)
        local a = math.clamp((x - barF.AbsolutePosition.X) / barF.AbsoluteSize.X, 0, 1)
        set(math.floor((min + (max - min) * a) / step + .5) * step)
        update()
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = true setX(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then setX(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = false end
    end)
end

local function label(page, text, key)
    return themed(new("TextLabel", {Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 11, LayoutOrder = nextOrd()}, page), "TextColor3", key or "sub")
end

-- one-shot action button (fires onClick every time it is pressed)
local function button(page, text, onClick)
    local b = themed(new("TextButton", {
        Size = UDim2.new(1, 0, 0, 32), BorderSizePixel = 0, Text = text, Font = Enum.Font.GothamBold,
        TextSize = 14, AutoButtonColor = false, LayoutOrder = nextOrd(),
    }, page), "BackgroundColor3", "card")
    themed(b, "TextColor3", "text")
    round(b, 8)
    b.MouseButton1Click:Connect(function()
        press(b)
        onClick()
    end)
    return b
end

-- ===== MAIN tab =====
local card = themed(new("Frame", {Size = UDim2.new(1, 0, 0, 62), BorderSizePixel = 0, LayoutOrder = nextOrd()}, pMain), "BackgroundColor3", "card")
round(card, 8)
local function statusLine(y)
    return themed(new("TextLabel", {Size = UDim2.new(1, -16, 0, 18), Position = UDim2.fromOffset(8, y), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, RichText = true}, card), "TextColor3", "text")
end
local stA, stB, stC = statusLine(5), statusLine(22), statusLine(39)

-- boss selector
label(pMain, "Target boss", "text")
local chipFrame = new("Frame", {Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1, LayoutOrder = nextOrd()}, pMain)
new("UIGridLayout", {CellSize = UDim2.new(1/3, -4, 0, 28), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder}, chipFrame)
local chips = {}
local function refreshChips()
    for i, c in ipairs(chips) do
        TS:Create(c, TweenInfo.new(.2), {BackgroundColor3 = (i == BI) and T.accent or T.card}):Play()
    end
end
refreshers[#refreshers + 1] = refreshChips
for i, b in ipairs(BOSSES) do
    local c = new("TextButton", {
        BorderSizePixel = 0, Text = b.name, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = WHITE,
        AutoButtonColor = false, LayoutOrder = i, BackgroundColor3 = T.card,
    }, chipFrame)
    round(c, 6)
    chips[i] = c
    c.MouseButton1Click:Connect(function()
        press(c)
        BI = i
        refreshChips()
        if F.Farm then start() end -- restart on the new boss
    end)
end
refreshChips()

local farmRefresh
local function setFarm(on)
    F.Farm = on
    if farmRefresh then farmRefresh() end
    if on then start() else stop() end
end
farmRefresh = toggle(pMain, "Auto Farm", "Farm", function(on) if on then start() else stop() end end)
toggle(pMain, "Auto Start (tp + Start)", "AutoStart")
toggle(pMain, "Monster Candy swap", "Candy")
toggle(pMain, "Skill (E) every few sec", "Skill")
toggle(pMain, "Black screen behind UI", "Black", function() syncBlack() end)
button(pMain, "Instant join Night Shift", function()
    task.spawn(function()
        -- teleport to the join spot first
        local c = pl.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if r then
            r.AssemblyLinearVelocity = Vector3.zero
            r.CFrame = CFrame.new(1191, 342, -1493)
            task.wait(.3) -- let the server register the new position
        end
        pcall(function() Ev:FireServer(buf(B.join), {}) end)
    end)
end)
slider(pMain, "Teleport distance", 3, 15, 1, function() return S.Stop end, function(v) S.Stop = v end)
slider(pMain, "Skill delay (s)", 2, 20, 1, function() return S.SDelay end, function(v) S.SDelay = v end)
label(pMain, "Weapon = hotbar slot 1 (auto equip)")
label(pMain, "RightShift = hide / show")

-- ===== PLAYER tab =====
local prof = themed(new("Frame", {Size = UDim2.new(1, 0, 0, 84), BorderSizePixel = 0, LayoutOrder = nextOrd()}, pPlayer), "BackgroundColor3", "card")
round(prof, 8)
local avatar = themed(new("ImageLabel", {Size = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(10, 10), BorderSizePixel = 0}, prof), "BackgroundColor3", "off")
round(avatar, 32)
pcall(function()
    avatar.Image = Players:GetUserThumbnailAsync(pl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
end)
themed(new("TextLabel", {Size = UDim2.new(1, -90, 0, 22), Position = UDim2.fromOffset(82, 12), BackgroundTransparency = 1, Text = pl.DisplayName, Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, prof), "TextColor3", "text")
themed(new("TextLabel", {Size = UDim2.new(1, -90, 0, 16), Position = UDim2.fromOffset(82, 34), BackgroundTransparency = 1, Text = "@" .. pl.Name, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, prof), "TextColor3", "sub")
themed(new("TextLabel", {Size = UDim2.new(1, -90, 0, 16), Position = UDim2.fromOffset(82, 52), BackgroundTransparency = 1, Text = "ID: " .. pl.UserId, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, prof), "TextColor3", "sub")

local info = themed(new("Frame", {Size = UDim2.new(1, 0, 0, 104), BorderSizePixel = 0, LayoutOrder = nextOrd()}, pPlayer), "BackgroundColor3", "card")
round(info, 8)
local function infoLine(y)
    return themed(new("TextLabel", {Size = UDim2.new(1, -16, 0, 18), Position = UDim2.fromOffset(8, y), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, RichText = true}, info), "TextColor3", "text")
end
local i1, i2, i3, i4 = infoLine(6), infoLine(30), infoLine(54), infoLine(78)
i1.Text = "Account age: " .. pl.AccountAge .. " days"
local gameName = "Unknown"
pcall(function() gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
i2.Text = "Game: " .. gameName

-- ===== ICONS tab =====
label(pIcons, "Changes the HUD PlayerIcon (only you see it)", "sub")
local function iconRow(i, name)
    local row = themed(new("TextButton", {Size = UDim2.new(1, 0, 0, 50), BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = nextOrd()}, pIcons), "BackgroundColor3", "card")
    round(row, 8)
    local st = new("UIStroke", {Thickness = 1.5, Transparency = 1, Color = T.accent}, row)
    local th = themed(new("ImageLabel", {Size = UDim2.fromOffset(38, 38), Position = UDim2.fromOffset(8, 6), BorderSizePixel = 0, ScaleType = Enum.ScaleType.Crop}, row), "BackgroundColor3", "off")
    round(th, 19)
    if i == 0 then
        new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "↺", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 20}, th)
    end
    themed(new("TextLabel", {Size = UDim2.new(1, -140, 1, 0), Position = UDim2.fromOffset(54, 0), BackgroundTransparency = 1, Text = name, Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, row), "TextColor3", "text")
    local tag = new("TextLabel", {Size = UDim2.fromOffset(72, 50), Position = UDim2.new(1, -80, 0, 0), BackgroundTransparency = 1, Text = "Use", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Right}, row)
    local function refresh()
        local on = selIcon == i
        tag.Text = on and "Selected" or "Use"
        tag.TextColor3 = on and T.accent or T.sub
        TS:Create(st, TweenInfo.new(.2), {Transparency = on and 0 or 1, Color = T.accent}):Play()
    end
    refresh()
    iconRefresh[#iconRefresh + 1] = refresh
    refreshers[#refreshers + 1] = refresh
    row.MouseButton1Click:Connect(function() press(row) setIcon(i) end)
    return th
end
iconRow(0, "Original (default)")
for i, ic in ipairs(ICONS) do ic.thumb = iconRow(i, ic.name) end
task.spawn(function()
    for i, ic in ipairs(ICONS) do
        ic.asset = ic.asset or dl(ic.url, "natsuki_icon" .. i .. ".jpg")
        if ic.asset and ic.thumb then ic.thumb.Image = ic.asset end
    end
end)

-- ===== THEME tab =====
label(pTheme, "Presets", "text")
local swRow = new("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = nextOrd()}, pTheme)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)}, swRow)
for _, p in ipairs(PRESETS) do
    local sw = new("TextButton", {Size = UDim2.fromOffset(36, 28), BackgroundColor3 = p[2], BorderSizePixel = 0, Text = "", AutoButtonColor = false}, swRow)
    round(sw, 6)
    sw.MouseButton1Click:Connect(function()
        press(sw)
        T.accent, T.bg, T.card = p[2], p[3], p[4]
        applyTheme()
    end)
end
label(pTheme, "Custom accent color", "text")
local function channel(name, idx)
    slider(pTheme, name, 0, 255, 1,
        function() return math.floor(({T.accent.R, T.accent.G, T.accent.B})[idx] * 255 + .5) end,
        function(v)
            local c = {math.floor(T.accent.R * 255 + .5), math.floor(T.accent.G * 255 + .5), math.floor(T.accent.B * 255 + .5)}
            c[idx] = v
            T.accent = Color3.fromRGB(c[1], c[2], c[3])
            applyTheme()
        end)
end
channel("Red", 1) channel("Green", 2) channel("Blue", 3)
label(pTheme, "Presets also change the background and card colors")

applyTheme()
showTab("Main", false)

-- ================= Live stats =================
local frames, fps, lastT = 0, 60, os.clock()
RS.Heartbeat:Connect(function()
    frames += 1
    local now = os.clock()
    if now - lastT >= 0.5 then
        fps = math.floor(frames / (now - lastT) + .5)
        frames, lastT = 0, now
    end
end)

local function col(v, good, ok) return v <= good and "#3cc86e" or (v <= ok and "#ffc84a" or "#ff6464") end

task.spawn(function()
    while gui.Parent do
        local ping = 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + .5) end)
        local fcol = fps >= 50 and "#3cc86e" or (fps >= 30 and "#ffc84a" or "#ff6464")
        statLbl.Text = 'FPS: <font color="' .. fcol .. '">' .. fps .. '</font>  |  Ping: <font color="' .. col(ping, 80, 150) .. '">' .. ping .. ' ms</font>'

        local h = hb()
        local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
        stA.Text = 'Status: ' .. (F.Farm and '<font color="#3cc86e">Farming</font>' or '<font color="#ff6464">Idle</font>')
        stB.Text = BOSSES[BI].name .. ': ' .. (h and '<font color="#3cc86e">Alive</font>' or '<font color="#ff6464">Not found</font>')
        stC.Text = 'Distance: ' .. ((h and r) and (math.floor((r.Position - pos(h)).Magnitude) .. " studs") or "-")

        local hum = pl.Character and pl.Character:FindFirstChildOfClass("Humanoid")
        i3.Text = "Health: " .. (hum and (math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)) or "-")
        i4.Text = "Players: " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers
        task.wait(.25)
    end
end)

-- ================= Minimize / close / hotkey / drag =================
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    press(minBtn)
    minimized = not minimized
    minBtn.Text = minimized and "+" or "-"
    local ti = TweenInfo.new(.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    if minimized then
        TS:Create(frame, ti, {Size = UDim2.fromOffset(W, 40)}):Play()
        task.delay(.3, function() if minimized then body.Visible = false end end)
    else
        body.Visible = true
        TS:Create(frame, ti, {Size = UDim2.fromOffset(W, H)}):Play()
    end
end)
closeBtn.MouseButton1Click:Connect(function()
    setFarm(false)
    if iconConn then iconConn:Disconnect() iconConn = nil end
    if iconTarget and iconWant and iconOrig then pcall(function() iconTarget.Image = iconOrig end) end
    gui:Destroy()
    blackGui:Destroy()
end)
UIS.InputBegan:Connect(function(i, gp)
    if not gp and live and i.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
        syncBlack()
    end
end)

local drag, ds, sp
header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag, ds, sp = true, i.Position, frame.Position end
end)
UIS.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - ds
        frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
end)

-- ================= Slash + shatter effect =================
local function slashFX(onCovered)
    local g = new("ScreenGui", {Name = "NatsukiSlash", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 1001}, par)
    local flash = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 10}, g)

    local function cut(rot, x, y, h, dur)
        local function bar(height, color, tr, z)
            return new("Frame", {
                AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(x, y), Size = UDim2.fromOffset(0, height),
                Rotation = rot, BackgroundColor3 = color, BackgroundTransparency = tr, BorderSizePixel = 0, ZIndex = z,
            }, g)
        end
        local glow = bar(h * 3.5, Color3.fromRGB(255, 60, 60), .45, 4)
        local line = bar(h, WHITE, 0, 5)
        local ti = TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TS:Create(glow, ti, {Size = UDim2.fromOffset(3200, h * 3.5)}):Play()
        TS:Create(line, ti, {Size = UDim2.fromOffset(3200, h)}):Play()
        task.delay(dur + .05, function()
            local fade = TweenInfo.new(.3)
            TS:Create(glow, fade, {BackgroundTransparency = 1, Size = UDim2.fromOffset(3200, 0)}):Play()
            TS:Create(line, fade, {BackgroundTransparency = 1, Size = UDim2.fromOffset(3200, 0)}):Play()
        end)
    end

    -- small slashes (slash sound repeated once per slash)
    local smalls = {{-32, .30, .40}, {24, .66, .56}, {-8, .50, .28}, {58, .38, .66}, {-52, .62, .34}}
    for i = 1, math.min(SMALL_SLASHES, #smalls) do
        local c = smalls[i]
        playSnd(slashAsset)
        cut(c[1], c[2], c[3], 4, .09)
        task.wait(.3)
    end

    -- last slash: huge + slower + heavy hit
    task.wait(.4)
    local dim = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3}, g)
    TS:Create(dim, TweenInfo.new(.5), {BackgroundTransparency = .45}):Play()
    task.wait(.6)
    playSnd(heavyAsset, 1.5)
    cut(-35, .5, .5, 30, .5)
    task.wait(.6)

    -- flash, then the screen goes black
    TS:Create(flash, TweenInfo.new(.08), {BackgroundTransparency = 0}):Play()
    task.wait(.12)
    local cover = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BorderSizePixel = 0, ZIndex = 20}, g)
    flash:Destroy()

    -- cracks spread from the center
    local cracks = {}
    for i = 1, 10 do
        local ang = (i / 10) * 360 + math.random(-12, 12)
        local len = math.random(500, 1400)
        local rad = math.rad(ang)
        local crack = new("Frame", {
            AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, 0, .5, 0), Size = UDim2.fromOffset(0, 2),
            Rotation = ang, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 21,
        }, g)
        TS:Create(crack, TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(len, 2),
            Position = UDim2.new(.5, math.cos(rad) * len / 2, .5, math.sin(rad) * len / 2),
        }):Play()
        cracks[#cracks + 1] = crack
    end
    task.wait(.7)

    -- swap the scene underneath, then shatter the black screen into falling shards
    onCovered()
    for _, c in ipairs(cracks) do c:Destroy() end
    cover:Destroy()
    local cols, rows = 9, 6
    for cx = 1, cols do
        for ry = 1, rows do
            local px, py = (cx - .5) / cols, (ry - .5) / rows
            local d = math.sqrt((px - .5) ^ 2 + (py - .5) ^ 2)
            local shard = new("Frame", {
                AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(px, py), Size = UDim2.new(1 / cols, 2, 1 / rows, 2),
                BackgroundColor3 = BLACK, BorderSizePixel = 0, ZIndex = 20,
            }, g)
            task.delay(d * .5, function()
                TS:Create(shard, TweenInfo.new(math.random(80, 140) / 100, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Position = UDim2.fromScale(px + (math.random() - .5) * .3, py + 1.2),
                    Rotation = math.random(-200, 200),
                    BackgroundTransparency = 1,
                }):Play()
            end)
        end
    end
    task.wait(2.2)
    g:Destroy()
end

-- ================= Wait for START, then the full intro =================
repeat task.wait() until started

sbtn.Visible, heart.Visible = false, false
say(". . .", .15)
task.wait(3)

-- make sure the sounds finished downloading
do
    local t0 = os.clock()
    while not soundsDone and os.clock() - t0 < 6 do task.wait() end
end

-- Chara just disappears (Gaster vanish sound)
tail.Visible, bubble.Visible = false, false
local charaShake = shake(chara, charaBase, 3, .03)
playSnd(vanishAsset, 1.3)
TS:Create(chara, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {ImageTransparency = 1}):Play()
task.wait(1.5)
charaShake:Disconnect()
chara.Visible = false
task.wait(.8)

-- Flowey laugh
playSnd(laughAsset, 1.5)
task.wait(LAUGH_TIME)

slashFX(function()
    charaShake:Disconnect()
    titleShake:Disconnect()
    startGui:Destroy()
    live = true
    frame.Size = UDim2.fromOffset(W * 0.8, H * 0.8)
    gui.Enabled = true
    syncBlack()
    TS:Create(frame, TweenInfo.new(.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(W, H)}):Play()
end)
