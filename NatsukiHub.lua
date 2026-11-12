if not game:IsLoaded() then game.Loaded:Wait() end

local RS, UIS, VIM, TS = game:GetService("RunService"), game:GetService("UserInputService"), game:GetService("VirtualInputManager"), game:GetService("TweenService")
local Players, Stats, SoundService = game:GetService("Players"), game:GetService("Stats"), game:GetService("SoundService")
repeat task.wait() until Players.LocalPlayer
local pl = Players.LocalPlayer
local par = (gethui and gethui()) or game:GetService("CoreGui")

print("[Natsuki] PlaceId:", game.PlaceId)

-- find the remote safely instead of crashing
local RepS = game:GetService("ReplicatedStorage")
local Ev = RepS:WaitForChild("UT_BLINK_RELIABLE_REMOTE", 10)
if not Ev then
    warn("[Natsuki] UT_BLINK_RELIABLE_REMOTE not found. Remotes in ReplicatedStorage:")
    for _, d in ipairs(RepS:GetDescendants()) do
        if d:IsA("RemoteEvent") or d:IsA("UnreliableRemoteEvent") then
            print("  ", d:GetFullName(), d.ClassName)
            if not Ev and d.Name:upper():find("BLINK") and d.Name:upper():find("RELIABLE") and not d.Name:upper():find("UNRELIABLE") then
                Ev = d
            end
        end
    end
end
if not Ev then
    warn("[Natsuki] No remote found, GUI will load but farming can't send packets")
    Ev = {FireServer = function() end}
else
    print("[Natsuki] Using remote:", Ev:GetFullName())
end

local LOGO_URL = "https://i.pinimg.com/736x/b9/a3/e4/b9a3e4f0af14cfe3d953dfd9b4d87d8d.jpg"
local SLASH_URL = "https://www.myinstants.com/media/sounds/undertale-slash.mp3"
local HEAVY_URL = "https://www.myinstants.com/media/sounds/undertale-heavy-hit.mp3"
local TEXT_URL = "https://www.myinstants.com/media/sounds/undertale-text.mp3"
local VANISH_URL = "https://www.myinstants.com/media/sounds/gaster-vanish.mp3"
local LAUGH_URL = "https://www.myinstants.com/media/sounds/flowey-udnertale-laugh.mp3"
local CHARA_URL = "https://i.pinimg.com/736x/c5/4c/0f/c54c0fdae6a9bd2336122e7e190d4881.jpg"
local CREEPY_URL = "https://www.myinstants.com/media/sounds/chara-creepy-sound.mp3"
local LAUGH_TIME = 2.5
local SMALL_SLASHES = 3
local ICONS = {
    {name = "Natsuki",        url = "https://i.pinimg.com/736x/af/f6/63/aff663b8b0907d12ebf8bcd30ebaa917.jpg"},
    {name = "Abbie",          url = "https://i.pinimg.com/736x/19/d6/d8/19d6d8b147505c5f82a4e44d69c64109.jpg"},
    {name = "Miss Circle",    url = "https://i.pinimg.com/1200x/41/cb/0f/41cb0f911b73905bd8f5f5e53df4cd6b.jpg"},
    {name = "Ena",            url = "https://i.pinimg.com/736x/62/ac/ff/62acffed78e169a5d0c0dbd46000ccdf.jpg"},
    {name = "Ena dream bbq",  url = "https://i.pinimg.com/736x/32/2d/aa/322daac377dce1aa59078bff50b5b03a.jpg"},
}

local BOSSES = {
    {name = "Golden Freddy",  mob = "Golden Freddy",  spawn = CFrame.new(1285, 342, -1517)},
    {name = "Bonnie",         mob = "Bonnie",         spawn = CFrame.new(1189, 346, -1597)},
    {name = "Chica",          mob = "Chica",          spawn = CFrame.new(1212, 346, -1597)},
    {name = "Freddy Fazbear", mob = "Freddy Fazbear", spawn = CFrame.new(1199, 346, -1597)},
    {name = "Foxy",           mob = "Foxy",           spawn = CFrame.new(1143, 344, -1563)},
}
local BI = 1

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

-- PC crash fix: only hand a file to getcustomasset if it really is a JPG/PNG/MP3.
-- (A failed download saves an HTML error page; loading that as an image/sound can crash the PC client.)
local function validData(d, kind)
    if type(d) ~= "string" or #d < 200 then return false end
    local a, b, c = d:byte(1, 3)
    if kind == "img" then
        return (a == 0xFF and b == 0xD8) or (a == 0x89 and b == 0x50 and c == 0x4E)
    else
        return (a == 0x49 and b == 0x44 and c == 0x33) or (a == 0xFF and b and b >= 0xE0)
    end
end

local function dl(url, file)
    local ok, asset = pcall(function()
        local data = game:HttpGet(url)
        if not validData(data, file:sub(-4) == ".mp3" and "snd" or "img") then
            warn("[Natsuki] skipped invalid download: " .. file)
            return nil
        end
        writefile(file, data)
        task.wait(.05)
        return getcustomasset(file)
    end)
    return ok and asset or nil
end

local logoAsset = dl(LOGO_URL, "natsuki_logo.jpg")
local charaAsset = dl(CHARA_URL, "natsuki_chara.jpg")
local BLACK, WHITE = Color3.new(0, 0, 0), Color3.new(1, 1, 1)
local RED, ORANGE, GRAY = Color3.fromRGB(255, 30, 30), Color3.fromRGB(255, 140, 0), Color3.fromRGB(140, 140, 150)
local FONT = Enum.Font.Arcade

-- creepy loop plays on the start screen until START is pressed
local creepy, creepyOn = nil, true
local slashAsset, heavyAsset, textAsset, vanishAsset, laughAsset, soundsDone
task.spawn(function()
    local creepyAsset = dl(CREEPY_URL, "natsuki_creepy.mp3")
    if creepyAsset and creepyOn then
        creepy = new("Sound", {SoundId = creepyAsset, Looped = true, Volume = .6}, SoundService)
        creepy:Play()
    end
end)
task.spawn(function()
    textAsset = dl(TEXT_URL, "natsuki_text.mp3") task.wait(.1)
    slashAsset = dl(SLASH_URL, "natsuki_slash.mp3") task.wait(.1)
    heavyAsset = dl(HEAVY_URL, "natsuki_heavy.mp3") task.wait(.1)
    vanishAsset = dl(VANISH_URL, "natsuki_vanish.mp3") task.wait(.1)
    laughAsset = dl(LAUGH_URL, "natsuki_laugh.mp3")
    soundsDone = true
end)

-- PC crash fix: one reusable Sound per asset (the old code made a new Sound for every typed letter)
local soundCache = {}
local function playSnd(asset, vol)
    if not asset then return end
    local s = soundCache[asset]
    if not s then
        s = new("Sound", {SoundId = asset}, SoundService)
        soundCache[asset] = s
    end
    s.Volume = vol or 1
    s.TimePosition = 0
    s:Play()
end

local function shake(obj, base, amt, rate)
    local last = 0
    return RS.Heartbeat:Connect(function()
        if os.clock() - last < (rate or .04) then return end
        last = os.clock()
        obj.Position = base + UDim2.fromOffset(math.random(-amt, amt), math.random(-amt, amt))
    end)
end

-- ================= Start screen =================
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
    BackgroundTransparency = 1, Text = "NATSUKI HUB", TextColor3 = WHITE, Font = FONT, TextSize = 34, TextTransparency = 1,
}, sbg)
local titleShake = shake(stitle, titleBase, 2, .04)

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
    TextColor3 = BLACK, Font = FONT, TextSize = 22, TextWrapped = true, ZIndex = 5,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
}, bubble)

local function say(text, delay, force)
    btext.Text = ""
    for i = 1, #text do
        if started and not force then btext.Text = text break end
        btext.Text = string.sub(text, 1, i)
        if string.sub(text, i, i) ~= " " then playSnd(textAsset, .4) end
        task.wait(delay or .06)
    end
end

local sbtn = new("TextButton", {
    AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(200, 50), Position = UDim2.new(0.5, 0, 0.82, 0),
    BackgroundColor3 = BLACK, BorderSizePixel = 0, Text = "START", TextColor3 = WHITE, Font = FONT,
    TextSize = 26, AutoButtonColor = false, TextTransparency = 1,
}, sbg)
local sstroke = new("UIStroke", {Color = WHITE, Thickness = 3, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, sbtn)
local heart = new("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(30, 30), Position = UDim2.new(0.5, -135, 0.82, 0),
    BackgroundTransparency = 1, Text = "♥", TextColor3 = RED, Font = Enum.Font.GothamBold, TextSize = 26, TextTransparency = 1,
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

task.spawn(function()
    task.wait(1.3)
    local t0 = os.clock()
    while not textAsset and not started and os.clock() - t0 < 4 do task.wait() end
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
    if started then return end
    started = true
end)

-- ================= Farm logic =================
local S = {Stop = 8, WDelay = 3, SDelay = 8}
local CANDY = "Monster Candy"
local B = {
    set = {54,1,7,83,101,116,116,105,110,103},
    start = {54,1,5,83,116,97,114,116},
    join = {112,1,4,74,111,105,110},
}
local function buf(t) local b = buffer.create(#t) for i = 1, #t do buffer.writeu8(b, i - 1, t[i]) end return b end
local function setS(n, v) Ev:FireServer(buf(B.set), {n, v}) end
local function pressKey(k) pcall(function() VIM:SendKeyEvent(true, k, false, game) task.wait(.05) VIM:SendKeyEvent(false, k, false, game) end) end

local function equipBytes(name)
    local t = {3, 1, 1, #name}
    for i = 1, #name do t[#t + 1] = string.byte(name, i) end
    t[#t + 1] = 10
    for i = 1, 10 do t[#t + 1] = string.byte("OnEquipped", i) end
    return t
end

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

local function heldWeapon()
    local c = pl.Character
    if not c then return nil end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t.Name ~= CANDY then return t end
    end
end

local function equipWeapon()
    local w = heldWeapon()
    if w then return w end
    clickSlot()
    for _ = 1, 12 do
        task.wait(.05)
        w = heldWeapon()
        if w then return w end
    end
    pressKey(Enum.KeyCode.One)
    for _ = 1, 12 do
        task.wait(.05)
        w = heldWeapon()
        if w then return w end
    end
end

local function hb()
    local m = workspace:FindFirstChild("Mobs")
    local b = m and m:FindFirstChild(BOSSES[BI].mob)
    return b and b:FindFirstChild("Hitbox")
end
local function pos(h) return h:IsA("BasePart") and h.Position or h:GetPivot().Position end

local F = {Farm = false, AutoStart = false, Candy = false, Skill = false, Black = false, AutoAgain = false, AutoVote = false, SafeTP = false}
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
        task.spawn(function()
            while alive(id) do
                if not swap then
                    local t = heldWeapon() or equipWeapon()
                    if t then t:Activate() end
                end
                task.wait(.05)
            end
        end)
        task.spawn(function()
            local last, was = os.clock(), false
            while alive(id) do
                local a = F.Skill and not swap and heldWeapon() ~= nil and hb() ~= nil
                if a and not was then last = os.clock() end
                was = a
                if a and os.clock() - last >= S.SDelay then pressKey(Enum.KeyCode.E) last = os.clock() end
                task.wait(.2)
            end
        end)
        task.spawn(function()
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

-- ================= Undertale-style theme =================
local ACCENTS = {
    Color3.fromRGB(255, 255, 0),   -- yellow (default, like a selected option)
    Color3.fromRGB(255, 140, 0),   -- orange
    Color3.fromRGB(255, 30, 30),   -- red
    Color3.fromRGB(0, 255, 255),   -- cyan
    Color3.fromRGB(80, 255, 120),  -- green
    Color3.fromRGB(255, 130, 180), -- pink
}
local T = {accent = ACCENTS[1]}
local refreshers = {}
local function applyTheme() for _, f in ipairs(refreshers) do f() end end
local function reg(f) refreshers[#refreshers + 1] = f f() end

local function press(o)
    local s = o:FindFirstChild("PressScale") or new("UIScale", {Name = "PressScale"}, o)
    TS:Create(s, TweenInfo.new(.06, Enum.EasingStyle.Quad), {Scale = .96}):Play()
    task.delay(.06, function()
        TS:Create(s, TweenInfo.new(.15, Enum.EasingStyle.Quad), {Scale = 1}):Play()
    end)
end

-- ================= Black backdrop =================
local blackGui = new("ScreenGui", {Name = "NatsukiBlack", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 900, Enabled = false}, par)
new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BorderSizePixel = 0}, blackGui)

-- ================= GUI: Undertale battle-menu style ================
