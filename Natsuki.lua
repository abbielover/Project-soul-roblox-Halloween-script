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

-- ================= GUI: Undertale battle-menu style =================
local ord = 0
local function nextOrd() ord += 1 return ord end

local cam = workspace.CurrentCamera
local vp = (cam and cam.ViewportSize) or Vector2.new(800, 500)
local W, H = math.clamp(vp.X - 24, 300, 560), math.clamp(vp.Y - 24, 240, 350)
local TOP, BOT = 34, 46

local gui = new("ScreenGui", {Name = "NatsukiHub", ResetOnSpawn = false, DisplayOrder = 950, Enabled = false}, par)
local live = false
local function syncBlack() blackGui.Enabled = live and F.Black and gui.Enabled end

local frame = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(W, H), BorderSizePixel = 0, BackgroundColor3 = BLACK, ClipsDescendants = true,
}, gui)
new("UIStroke", {Color = WHITE, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, frame)
local pop = new("UIScale", {Scale = 1}, frame)

-- top bar (drag handle): NAME  LV  HP [bar]  stats  - X
local header = new("Frame", {Size = UDim2.new(1, 0, 0, TOP), BackgroundTransparency = 1}, frame)
local hubTitle = new("TextLabel", {
    Size = UDim2.fromOffset(150, TOP), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1,
    Text = "NATSUKI  LV 19", TextColor3 = WHITE, Font = FONT, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
}, header)
local titleBase2 = UDim2.fromOffset(10, 0)
local titleShake2 = shake(hubTitle, titleBase2, 1, .08)
new("TextLabel", {Size = UDim2.fromOffset(24, TOP), Position = UDim2.fromOffset(160, 0), BackgroundTransparency = 1, Text = "HP", TextColor3 = WHITE, Font = FONT, TextSize = 11}, header)
local hpBar = new("Frame", {Size = UDim2.fromOffset(56, 14), Position = UDim2.fromOffset(186, (TOP - 14) / 2), BackgroundColor3 = RED, BorderSizePixel = 0}, header)
local hpFill = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 255, 0), BorderSizePixel = 0}, hpBar)
local hpText = new("TextLabel", {Size = UDim2.fromOffset(64, TOP), Position = UDim2.fromOffset(248, 0), BackgroundTransparency = 1, Text = "- / -", TextColor3 = WHITE, Font = FONT, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, header)
local statLbl = new("TextLabel", {
    Size = UDim2.fromOffset(190, TOP), Position = UDim2.new(1, -250, 0, 0), BackgroundTransparency = 1, Text = "",
    TextColor3 = WHITE, Font = FONT, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, RichText = true, Visible = W >= 520,
}, header)
local minBtn = new("TextButton", {Size = UDim2.fromOffset(26, TOP), Position = UDim2.new(1, -56, 0, 0), BackgroundTransparency = 1, Text = "-", TextColor3 = WHITE, Font = FONT, TextSize = 22}, header)
local closeBtn = new("TextButton", {Size = UDim2.fromOffset(26, TOP), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1, Text = "X", TextColor3 = RED, Font = FONT, TextSize = 18}, header)

-- body: dialogue box (white border) + bottom buttons (orange border)
local bodyHolder = new("Frame", {Position = UDim2.fromOffset(0, TOP), Size = UDim2.new(1, 0, 1, -TOP), BackgroundTransparency = 1}, frame)
local box = new("Frame", {Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 1, -(BOT + 10)), BackgroundColor3 = BLACK, BorderSizePixel = 0}, bodyHolder)
new("UIStroke", {Color = WHITE, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, box)

local TABS = {"Main", "Night Shift", "Player", "Icons", "Theme"}
local TABTXT = {Main = "MAIN", ["Night Shift"] = "NIGHT", Player = "PLAYER", Icons = "ICONS", Theme = "THEME"}
local pages, sfs, tabBtns, tabStroke = {}, {}, {}, {}
local tw = (W - 20 - 4 * 6) / 5
for idx, name in ipairs(TABS) do
    local pg = new("Frame", {Size = UDim2.new(1, -16, 1, -16), Position = UDim2.fromOffset(8, 8), BackgroundTransparency = 1, Visible = false}, box)
    local sf = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
        ScrollBarImageColor3 = WHITE, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, pg)
    new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, sf)
    new("UIPadding", {PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4)}, sf)
    pages[name], sfs[name] = pg, sf

    local b = new("TextButton", {
        Size = UDim2.fromOffset(tw, 34), Position = UDim2.new(0, 10 + (idx - 1) * (tw + 6), 1, -(BOT - 2)),
        BackgroundColor3 = BLACK, BorderSizePixel = 0, Text = TABTXT[name], Font = FONT, TextSize = 14,
        TextColor3 = ORANGE, AutoButtonColor = false, TextScaled = true,
    }, bodyHolder)
    new("UITextSizeConstraint", {MaxTextSize = 15, MinTextSize = 8}, b)
    tabStroke[name] = new("UIStroke", {Color = ORANGE, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, b)
    tabBtns[name] = b
end
local pMain, pNight, pPlayer, pIcons, pTheme = sfs.Main, sfs["Night Shift"], sfs.Player, sfs.Icons, sfs.Theme

local currentTab = "Main"
local function refreshTabs()
    for n, b in pairs(tabBtns) do
        local on = n == currentTab
        b.TextColor3 = on and T.accent or ORANGE
        tabStroke[n].Color = on and T.accent or ORANGE
    end
end
reg(refreshTabs)
local function showTab(name)
    currentTab = name
    for n, p in pairs(pages) do p.Visible = (n == name) end
    refreshTabs()
end
for n, b in pairs(tabBtns) do
    b.MouseButton1Click:Connect(function() press(b) showTab(n) end)
end

-- ===== builders =====
local function makeRow(page, h)
    local row = new("TextButton", {Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = nextOrd()}, page)
    local hrt = new("TextLabel", {Size = UDim2.fromOffset(18, 26), BackgroundTransparency = 1, Text = "♥", TextColor3 = RED, Font = Enum.Font.GothamBold, TextSize = 15, Visible = false}, row)
    return row, hrt
end

local function toggle(page, text, flag, onChange)
    local row, hrt = makeRow(page, 26)
    local lbl = new("TextLabel", {Size = UDim2.new(1, -80, 0, 26), Position = UDim2.fromOffset(22, 0), BackgroundTransparency = 1, Text = "* " .. text, Font = FONT, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE}, row)
    local st = new("TextLabel", {Size = UDim2.fromOffset(50, 26), Position = UDim2.new(1, -50, 0, 0), BackgroundTransparency = 1, Font = FONT, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Right}, row)
    local hov = false
    local function refresh()
        local on = F[flag]
        st.Text = on and "[ON]" or "[OFF]"
        st.TextColor3 = on and T.accent or GRAY
        lbl.TextColor3 = (on or hov) and T.accent or WHITE
    end
    reg(refresh)
    row.MouseEnter:Connect(function() hov = true hrt.Visible = true refresh() end)
    row.MouseLeave:Connect(function() hov = false hrt.Visible = false refresh() end)
    row.MouseButton1Click:Connect(function()
        press(row)
        F[flag] = not F[flag]
        refresh()
        if onChange then onChange(F[flag]) end
    end)
    return refresh
end

local function slider(page, name, min, max, step, get, set)
    local row, hrt = makeRow(page, 38)
    local lbl = new("TextLabel", {Size = UDim2.new(1, -22, 0, 20), Position = UDim2.fromOffset(22, 0), BackgroundTransparency = 1, Font = FONT, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE}, row)
    local barF = new("Frame", {Size = UDim2.new(1, -30, 0, 8), Position = UDim2.fromOffset(22, 24), BackgroundColor3 = BLACK, BorderSizePixel = 0}, row)
    new("UIStroke", {Color = WHITE, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, barF)
    local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BorderSizePixel = 0}, barF)
    local hov = false
    local function update()
        fill.Size = UDim2.fromScale((get() - min) / (max - min), 1)
        fill.BackgroundColor3 = T.accent
        lbl.Text = "* " .. name .. ": " .. get()
        lbl.TextColor3 = hov and T.accent or WHITE
    end
    reg(update)
    row.MouseEnter:Connect(function() hov = true hrt.Visible = true update() end)
    row.MouseLeave:Connect(function() hov = false hrt.Visible = false update() end)
    local sliding = false
    local function setX(x)
        local a = math.clamp((x - barF.AbsolutePosition.X) / math.max(barF.AbsoluteSize.X, 1), 0, 1)
        set(math.floor((min + (max - min) * a) / step + .5) * step)
        update()
    end
    row.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = true setX(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then setX(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sliding = false end
    end)
end

local function label(page, text, bright)
    return new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = text,
        Font = FONT, TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = bright and WHITE or GRAY, LayoutOrder = nextOrd(),
    }, page)
end

local function button(page, text, onClick)
    local row, hrt = makeRow(page, 26)
    local lbl = new("TextLabel", {Size = UDim2.new(1, -22, 0, 26), Position = UDim2.fromOffset(22, 0), BackgroundTransparency = 1, Text = "* " .. text, Font = FONT, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE}, row)
    local hov = false
    local function refresh() lbl.TextColor3 = hov and T.accent or WHITE end
    reg(refresh)
    row.MouseEnter:Connect(function() hov = true hrt.Visible = true refresh() end)
    row.MouseLeave:Connect(function() hov = false hrt.Visible = false refresh() end)
    row.MouseButton1Click:Connect(function() press(row) onClick() end)
    return row, lbl
end

-- ===== MAIN tab =====
label(pMain, "* Natsuki Hub fills you with DETERMINATION.", true)
local statCard = new("Frame", {Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, LayoutOrder = nextOrd()}, pMain)
local function statusLine(y)
    return new("TextLabel", {Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, y), BackgroundTransparency = 1, Text = "", Font = FONT, TextSize = 14, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, RichText = true}, statCard)
end
local stA, stB, stC = statusLine(0), statusLine(18), statusLine(36)

label(pMain, "* Target boss", true)
local chipFrame = new("Frame", {Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1, LayoutOrder = nextOrd()}, pMain)
new("UIGridLayout", {CellSize = UDim2.new(1/3, -6, 0, 28), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder}, chipFrame)
local chips, chipStroke = {}, {}
local function refreshChips()
    for i, c in ipairs(chips) do
        local on = i == BI
        c.TextColor3 = on and T.accent or WHITE
        chipStroke[i].Color = on and T.accent or WHITE
    end
end
for i, b in ipairs(BOSSES) do
    local c = new("TextButton", {
        BorderSizePixel = 0, Text = b.name, Font = FONT, TextSize = 12, TextColor3 = WHITE, TextScaled = true,
        AutoButtonColor = false, LayoutOrder = i, BackgroundColor3 = BLACK,
    }, chipFrame)
    new("UITextSizeConstraint", {MaxTextSize = 13, MinTextSize = 7}, c)
    chipStroke[i] = new("UIStroke", {Color = WHITE, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, c)
    chips[i] = c
    c.MouseButton1Click:Connect(function()
        press(c)
        BI = i
        refreshChips()
        if F.Farm then start() end
    end)
end
reg(refreshChips)

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
slider(pMain, "Teleport distance", 3, 15, 1, function() return S.Stop end, function(v) S.Stop = v end)
slider(pMain, "Skill delay (s)", 2, 20, 1, function() return S.SDelay end, function(v) S.SDelay = v end)
label(pMain, "* Weapon = hotbar slot 1 (auto equip)")
label(pMain, "* RightShift = hide / show")

-- ===== NIGHT SHIFT tab =====
local NS = {Delay = 3, Pause = 0}
local SAFE = CFrame.new(1203, 403, -1085)
local warnedNight = false

local function nightAction(...)
    local args = {...}
    pcall(function()
        game:GetService("ReplicatedStorage").NightRemotes.Action:FireServer(unpack(args))
    end)
end

local function shown(o, root)
    while o and o ~= root do
        if o:IsA("GuiObject") and not o.Visible then return false end
        o = o.Parent
    end
    return true
end

local function isLocked(bx)
    if bx:GetAttribute("Locked") == true then return true end
    if bx:IsA("GuiButton") and (not bx.Active or bx.Interactable == false) then return true end
    for _, d in ipairs(bx:GetDescendants()) do
        if d:IsA("GuiObject") then
            local nm = d.Name:lower()
            if nm:find("lock") and not nm:find("unlock") and shown(d, bx) then
                if not (d:IsA("ImageLabel") or d:IsA("ImageButton")) or d.ImageTransparency < 1 then
                    return true
                end
            end
        end
    end
    return false
end

local function highestNight()
    local pg = pl:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local seen, locked = {}, {}
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("GuiObject") then
            local n, bx = d.Name:match("^[Nn]ight[%s_]*(%d)$"), d
            if not n and (d:IsA("TextLabel") or d:IsA("TextButton")) then
                n = d.Text:match("^%s*[Nn][Ii][Gg][Hh][Tt]%s*(%d)%s*$")
                if n and not d:IsA("TextButton") then bx = d.Parent end
            end
            n = tonumber(n)
            if n and n >= 1 and n <= 6 and bx then
                seen[n] = true
                if isLocked(bx) then locked[n] = true end
            end
        end
    end
    local best
    for n = 1, 6 do
        if not seen[n] or locked[n] then break end
        best = n
    end
    return best
end

local nsId = {again = 0, vote = 0, safe = 0}
local function nsLoop(key, flag, fn)
    nsId[key] += 1
    local id = nsId[key]
    task.spawn(function()
        while F[flag] and nsId[key] == id and gui.Parent do
            fn()
            task.wait(NS.Delay)
        end
    end)
end

label(pNight, "* Night Shift", true)

button(pNight, "Instant join Night Shift", function()
    NS.Pause = os.clock() + 4
    task.spawn(function()
        local c = pl.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if r then
            r.AssemblyLinearVelocity = Vector3.zero
            r.CFrame = CFrame.new(1191, 342, -1493)
            task.wait(.3)
        end
        pcall(function() Ev:FireServer(buf(B.join), {}) end)
    end)
end)

toggle(pNight, "Auto play again", "AutoAgain", function(on)
    if on then nsLoop("again", "AutoAgain", function() nightAction("Vote", "Again") end) end
end)

toggle(pNight, "Auto vote highest night", "AutoVote", function(on)
    if on then
        warnedNight = false
        nsLoop("vote", "AutoVote", function()
            local n = highestNight()
            if n then
                nightAction("Pick", n)
            elseif not warnedNight then
                warnedNight = true
                warn("Auto vote: couldn't read the night buttons - press 'Print vote UI' and send me the output")
            end
        end)
    end
end)

toggle(pNight, "Auto teleport to safe place", "SafeTP", function(on)
    if on then
        nsId.safe += 1
        local id = nsId.safe
        task.spawn(function()
            while F.SafeTP and nsId.safe == id and gui.Parent do
                if os.clock() >= NS.Pause then
                    local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
                    if r and (r.Position - SAFE.Position).Magnitude > 8 then
                        r.AssemblyLinearVelocity = Vector3.zero
                        r.CFrame = SAFE
                    end
                end
                task.wait(.5)
            end
        end)
    end
end)

slider(pNight, "Loop delay (s)", 1, 10, 1, function() return NS.Delay end, function(v) NS.Delay = v end)

button(pNight, "Print vote UI (debug)", function()
    local pg = pl:FindFirstChild("PlayerGui")
    if not pg then return end
    local count = 0
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("GuiObject") then
            local nm = d.Name:lower()
            local tx = (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text or ""
            if nm:find("night") or nm:find("lock") or tx:lower():find("night") then
                count += 1
                if count <= 200 then
                    print(d:GetFullName(), d.ClassName, "Visible=" .. tostring(d.Visible), tx ~= "" and ('Text="' .. tx .. '"') or "")
                end
            end
        end
    end
    print("[Night Shift] matches: " .. count .. " | highest unlocked night: " .. tostring(highestNight()))
end)
label(pNight, "* Votes 1-6, stops at the first locked night")

-- ===== PLAYER tab =====
local prof = new("Frame", {Size = UDim2.new(1, 0, 0, 76), BackgroundTransparency = 1, LayoutOrder = nextOrd()}, pPlayer)
local avatar = new("ImageLabel", {Size = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(4, 4), BackgroundColor3 = BLACK, BorderSizePixel = 0}, prof)
new("UIStroke", {Color = WHITE, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, avatar)
pcall(function()
    avatar.Image = Players:GetUserThumbnailAsync(pl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
end)
new("TextLabel", {Size = UDim2.new(1, -86, 0, 22), Position = UDim2.fromOffset(80, 6), BackgroundTransparency = 1, Text = pl.DisplayName, Font = FONT, TextSize = 18, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, prof)
new("TextLabel", {Size = UDim2.new(1, -86, 0, 16), Position = UDim2.fromOffset(80, 30), BackgroundTransparency = 1, Text = "@" .. pl.Name, Font = FONT, TextSize = 13, TextColor3 = GRAY, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, prof)
new("TextLabel", {Size = UDim2.new(1, -86, 0, 16), Position = UDim2.fromOffset(80, 48), BackgroundTransparency = 1, Text = "ID: " .. pl.UserId, Font = FONT, TextSize = 13, TextColor3 = GRAY, TextXAlignment = Enum.TextXAlignment.Left}, prof)

local info = new("Frame", {Size = UDim2.new(1, 0, 0, 84), BackgroundTransparency = 1, LayoutOrder = nextOrd()}, pPlayer)
local function infoLine(y)
    return new("TextLabel", {Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, y), BackgroundTransparency = 1, Text = "", Font = FONT, TextSize = 14, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left}, info)
end
local i1, i2, i3, i4 = infoLine(0), infoLine(21), infoLine(42), infoLine(63)
i1.Text = "* Account age: " .. pl.AccountAge .. " days"
local gameName = "Unknown"
pcall(function() gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
i2.Text = "* Game: " .. gameName

local afkLoaded = false
local afkLbl
_, afkLbl = button(pPlayer, "Anti AFK", function()
    if afkLoaded then return end
    afkLoaded = true
    afkLbl.Text = "* Anti AFK (on)"
    pl.Idled:Connect(function()
        pcall(function()
            local VU = game:GetService("VirtualUser")
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end)
    end)
end)

-- ===== ICONS tab =====
label(pIcons, "* Changes the HUD PlayerIcon (only you see it)")
local function iconRow(i, name)
    local row, hrt = makeRow(pIcons, 46)
    hrt.Position = UDim2.fromOffset(0, 10)
    local th = new("ImageLabel", {Size = UDim2.fromOffset(38, 38), Position = UDim2.fromOffset(22, 4), BackgroundColor3 = BLACK, BorderSizePixel = 0, ScaleType = Enum.ScaleType.Crop}, row)
    new("UIStroke", {Color = WHITE, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, th)
    if i == 0 then
        new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "↺", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 20}, th)
    end
    local nm = new("TextLabel", {Size = UDim2.new(1, -190, 1, 0), Position = UDim2.fromOffset(68, 0), BackgroundTransparency = 1, Text = "* " .. name, Font = FONT, TextSize = 15, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, row)
    local tag = new("TextLabel", {Size = UDim2.fromOffset(90, 46), Position = UDim2.new(1, -90, 0, 0), BackgroundTransparency = 1, Text = "[USE]", Font = FONT, TextSize = 13, TextColor3 = GRAY, TextXAlignment = Enum.TextXAlignment.Right}, row)
    local hov = false
    local function refresh()
        local on = selIcon == i
        tag.Text = on and "[SELECTED]" or "[USE]"
        tag.TextColor3 = on and T.accent or GRAY
        nm.TextColor3 = (on or hov) and T.accent or WHITE
    end
    reg(refresh)
    iconRefresh[#iconRefresh + 1] = refresh
    row.MouseEnter:Connect(function() hov = true hrt.Visible = true refresh() end)
    row.MouseLeave:Connect(function() hov = false hrt.Visible = false refresh() end)
    row.MouseButton1Click:Connect(function() press(row) setIcon(i) end)
    return th
end
iconRow(0, "Original (default)")
for i, ic in ipairs(ICONS) do ic.thumb = iconRow(i, ic.name) end
task.spawn(function()
    for i, ic in ipairs(ICONS) do
        ic.asset = ic.asset or dl(ic.url, "natsuki_icon" .. i .. ".jpg")
        if ic.asset and ic.thumb then ic.thumb.Image = ic.asset end
        task.wait(.1)
    end
end)

-- ===== THEME tab =====
label(pTheme, "* Highlight color", true)
local swRow = new("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = nextOrd()}, pTheme)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8)}, swRow)
for _, col3 in ipairs(ACCENTS) do
    local sw = new("TextButton", {Size = UDim2.fromOffset(34, 26), BackgroundColor3 = col3, BorderSizePixel = 0, Text = "", AutoButtonColor = false}, swRow)
    new("UIStroke", {Color = WHITE, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, sw)
    sw.MouseButton1Click:Connect(function()
        press(sw)
        T.accent = col3
        applyTheme()
    end)
end
label(pTheme, "* Custom color", true)
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

applyTheme()
showTab("Main")

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
        statLbl.Text = 'FPS <font color="' .. fcol .. '">' .. fps .. '</font>  PING <font color="' .. col(ping, 80, 150) .. '">' .. ping .. '</font>'

        local h = hb()
        local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
        stA.Text = '* Status: ' .. (F.Farm and '<font color="#3cc86e">Farming</font>' or '<font color="#ff6464">Idle</font>')
        stB.Text = '* ' .. BOSSES[BI].name .. ': ' .. (h and '<font color="#3cc86e">Alive</font>' or '<font color="#ff6464">Not found</font>')
        stC.Text = '* Distance: ' .. ((h and r) and (math.floor((r.Position - pos(h)).Magnitude) .. " studs") or "-")

        local hum = pl.Character and pl.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.MaxHealth > 0 then
            hpFill.Size = UDim2.fromScale(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 1)
            hpText.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
        end
        i3.Text = "* Health: " .. (hum and (math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)) or "-")
        i4.Text = "* Players: " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers
        task.wait(.25)
    end
end)

-- ================= Minimize / close / hotkey / drag =================
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    minBtn.Text = minimized and "+" or "-"
    bodyHolder.Visible = not minimized
    frame.Size = UDim2.fromOffset(W, minimized and TOP or H)
end)
closeBtn.MouseButton1Click:Connect(function()
    setFarm(false)
    titleShake2:Disconnect()
    if iconConn then iconConn:Disconnect() iconConn = nil end
    if iconTarget and iconWant and iconOrig then pcall(function() iconTarget.Image = iconOrig end) end
    for _, s in pairs(soundCache) do s:Destroy() end
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

-- ================= New intro: slash START -> it falls with the logo -> SOUL fades in -> slash spam -> huge slash -> shatter =================
local SOUL_RED = Color3.fromRGB(255, 0, 0)

local function introSequence(onCovered)
    local g = new("ScreenGui", {Name = "NatsukiSlash", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 1001}, par)

    -- stop the creepy loop (quick fade out)
    creepyOn = false
    if creepy then
        local c = creepy
        creepy = nil
        TS:Create(c, TweenInfo.new(.4), {Volume = 0}):Play()
        task.delay(.5, function() c:Stop() c:Destroy() end)
    end
    heart.Visible = false
    do
        local t0 = os.clock()
        while not ready and os.clock() - t0 < 5 do task.wait() end
    end

    -- Chara: ". . ." then slides to the middle, vanishes, Flowey laughs
    say(". . .", .15, true)
    task.wait(1.2)
    do
        local t0 = os.clock()
        while not soundsDone and os.clock() - t0 < 6 do task.wait() end
    end
    tail.Visible, bubble.Visible = false, false
    local charaMid = UDim2.new(.5, 0, .52, 0)
    TS:Create(chara, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = charaMid}):Play()
    task.wait(1.6)
    local charaShake = shake(chara, charaMid, 3, .03)
    playSnd(vanishAsset, 1.3)
    TS:Create(chara, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {ImageTransparency = 1}):Play()
    task.wait(1.5)
    charaShake:Disconnect()
    chara.Visible = false
    task.wait(.8)
    playSnd(laughAsset, 1.5)
    task.wait(LAUGH_TIME)

    -- oversize the start screen so shaking never shows the edges
    sbg.Size = UDim2.new(1, 40, 1, 40)
    sbg.Position = UDim2.fromOffset(-20, -20)
    local function shakeScreen(amt, dur)
        task.spawn(function()
            local t0 = os.clock()
            while os.clock() - t0 < dur do
                sbg.Position = UDim2.fromOffset(-20 + math.random(-amt, amt), -20 + math.random(-amt, amt))
                task.wait(.02)
            end
            sbg.Position = UDim2.fromOffset(-20, -20)
        end)
    end

    local flash = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 10}, g)

    -- Undertale-style slash: tapered streak that sweeps out in a few hard frames, then thins away
    local taper = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.15, .2),
        NumberSequenceKeypoint.new(.5, 0), NumberSequenceKeypoint.new(.85, .2), NumberSequenceKeypoint.new(1, 1),
    })
    local function cut(rot, x, y, len, h)
        local function streak(color, z)
            local f = new("Frame", {
                AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(x, y), Size = UDim2.fromOffset(0, 0),
                Rotation = rot, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z,
            }, g)
            new("UIGradient", {Transparency = taper}, f)
            new("UICorner", {CornerRadius = UDim.new(1, 0)}, f)
            return f
        end
        local glow = streak(Color3.fromRGB(255, 70, 70), 4)
        local core = streak(Color3.fromRGB(255, 250, 220), 5)
        task.spawn(function()
            for k = 1, 4 do
                local l = len * k / 4
                glow.Size = UDim2.fromOffset(l, h * 3)
                core.Size = UDim2.fromOffset(l, h)
                task.wait(.025)
            end
            task.wait(.05)
            for k = 1, 4 do
                glow.Size = UDim2.fromOffset(len, h * 3 * (1 - k / 4))
                core.Size = UDim2.fromOffset(len, h * (1 - k / 4))
                task.wait(.03)
            end
            glow:Destroy() core:Destroy()
        end)
    end

    -- 1) slash across the START button
    playSnd(slashAsset)
    cut(-18, .5, .82, 420, 9)
    shakeScreen(3, .12)
    task.wait(.16)

    -- 2) the button splits in two and falls, the logo falls at the same time
    sbtn.Visible = false
    local function half(top)
        local clip = new("Frame", {
            AnchorPoint = Vector2.new(.5, top and 1 or 0), Position = UDim2.new(.5, 0, .82, 0), Size = UDim2.fromOffset(200, 25),
            BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 3,
        }, sbg)
        local c = sbtn:Clone()
        c.Visible = true
        c.Position = UDim2.fromOffset(100, top and 25 or 0)
        c.Parent = clip
        return clip
    end
    local topH, botH = half(true), half(false)
    local fall = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    TS:Create(topH, fall, {Position = UDim2.new(.5, -70, 1.4, 0)}):Play()
    TS:Create(botH, fall, {Position = UDim2.new(.5, 70, 1.5, 0)}):Play()
    -- logo + title fall with a manual per-frame loop (no tween, so nothing can fight it)
    titleShake:Disconnect()
    stitle.Position = titleBase
    local function drop(obj, rot, dur)
        local from = obj.Position
        task.spawn(function()
            local t0 = os.clock()
            while true do
                local t = math.min((os.clock() - t0) / dur, 1)
                obj.Position = from + UDim2.fromScale(0, 1.5 * t * t)
                obj.Rotation = rot * t
                if t >= 1 then break end
                RS.Heartbeat:Wait()
            end
        end)
    end
    drop(slogo, -30, 1.1)
    drop(stitle, 8, 1.1)
    task.wait(1.4)
    topH:Destroy() botH:Destroy()

    -- 3) the SOUL slowly fades in
    local soul = new("TextLabel", {
        AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(90, 90),
        BackgroundTransparency = 1, Text = "♥", TextColor3 = SOUL_RED, Font = Enum.Font.GothamBold, TextSize = 84,
        TextTransparency = 1, ZIndex = 6,
    }, sbg)
    TS:Create(soul, TweenInfo.new(2.2, Enum.EasingStyle.Sine), {TextTransparency = 0}):Play()
    task.wait(2.8)

    -- 4) slash spam on the SOUL (gets faster)
    local jit = shake(soul, UDim2.fromScale(.5, .5), 4, .02)
    shakeScreen(5, 5)
    local t0, n = os.clock(), 0
    while os.clock() - t0 < 5 do
        local p = (os.clock() - t0) / 5
        local ang = math.random(10, 80) * (math.random() < .5 and -1 or 1)
        cut(ang, .5 + (math.random() - .5) * .08, .5 + (math.random() - .5) * .08, math.random(600, 1100), math.random(4, 9))
        n += 1
        if n % 2 == 1 then playSnd(slashAsset, .8) end
        task.wait(.18 - .145 * p) -- starts fast, ends frantic
    end
    task.wait(.35)

    -- 5) the final slash: much bigger than the others
    local dim = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3}, g)
    TS:Create(dim, TweenInfo.new(.4), {BackgroundTransparency = .5}):Play()
    task.wait(.6)
    playSnd(heavyAsset, 1.5)
    cut(-35, .5, .5, 3000, 34)
    shakeScreen(14, .45)
    task.wait(.25)
    TS:Create(flash, TweenInfo.new(.06), {BackgroundTransparency = 0}):Play()
    task.wait(.3)
    jit:Disconnect()
    local cover = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BorderSizePixel = 0, ZIndex = 20}, g)
    flash:Destroy() dim:Destroy()

    -- 6) everything cracks...
    local cracks = {}
    for i = 1, 12 do
        local ang = (i / 12) * 360 + math.random(-10, 10)
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
    playSnd(heavyAsset, 1)
    task.wait(.8)

    -- ...and shatters: black tiles fall away, red SOUL shards burst out, the UI is underneath
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
    for i = 1, 14 do
        local sz = math.random(5, 11)
        local ang = math.rad((i / 14) * 360 + math.random(-15, 15))
        local dist = math.random(160, 520)
        local rs = new("Frame", {
            AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, math.random(-12, 12), .5, math.random(-12, 12)),
            Size = UDim2.fromOffset(sz, sz), Rotation = math.random(0, 90), BackgroundColor3 = SOUL_RED, BorderSizePixel = 0, ZIndex = 22,
        }, g)
        local dur = math.random(110, 170) / 100
        TS:Create(rs, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(.5, math.cos(ang) * dist, .5, math.sin(ang) * dist + 60),
            Rotation = math.random(-300, 300),
        }):Play()
        task.delay(dur * .5, function()
            TS:Create(rs, TweenInfo.new(dur * .5), {BackgroundTransparency = 1}):Play()
        end)
    end
    task.wait(2.4)
    g:Destroy()
end

-- ================= Wait for START, then run the intro =================
repeat task.wait() until started

local uiLoaded = false
local function loadUI()
    if uiLoaded then return end
    uiLoaded = true
    titleShake:Disconnect()
    startGui:Destroy()
    live = true
    pop.Scale = .8
    gui.Enabled = true
    syncBlack()
    TS:Create(pop, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

local okI, errI = pcall(introSequence, loadUI)
if not okI then
    warn("[Natsuki] intro error (loading UI anyway): " .. tostring(errI))
    pcall(loadUI)
    local sg = par:FindFirstChild("NatsukiSlash")
    if sg then sg:Destroy() end
end
