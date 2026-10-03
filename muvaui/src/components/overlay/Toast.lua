-- Toast: notifikasi pojok kanan bawah, stack dari bawah ke atas, auto-dismiss
Toast = {}

-- icon = nama sprite Lucide (Icons.new) — bukan glyph/emoji TextLabel yang
-- di sebagian device dirender tofu/emoji warna.
local TOAST_STYLES = {
    Info    = { color = function() return Theme:Accent() end,           icon = "info" },
    Success = { color = function() return Color.fromHex("#22c55e") end, icon = "circle-check" },
    Error   = { color = function() return Color.fromHex("#ef4444") end, icon = "circle-x" },
    Warn    = { color = function() return Color.fromHex("#eab308") end, icon = "triangle-alert" },
}

-- Pemanggil bebas menulis "success"/"Success"/"warn"/"warning" dst —
-- normalisasi di sini supaya style tidak diam-diam jatuh ke Info.
local TOAST_TYPE_ALIAS = {
    info = "Info", success = "Success", ok = "Success",
    error = "Error", err = "Error",
    warn = "Warn", warning = "Warn",
}
local function resolveStyle(t)
    local key = TOAST_TYPE_ALIAS[string.lower(tostring(t or "info"))] or "Info"
    return TOAST_STYLES[key]
end

local _container  = nil
local _orderCount = 0

local function getContainer(screenGui)
    if _container and _container.Parent and _container.Parent.Parent then
        return _container
    end
    _container = nil

    -- PRIORITAS parent: ScreenGui window (dikirim Library.Notify — TERBUKTI
    -- ter-render karena window tampil di sana) → gethui() (executor modern) →
    -- CoreGui (pcall) → PlayerGui. ROOT CAUSE notif "tidak muncul sama sekali"
    -- di device: dulu langsung Instance ke CoreGui — banyak executor memblok /
    -- tidak me-render parenting CoreGui langsung tanpa gethui.
    local sg = nil
    if screenGui and screenGui.Parent then sg = screenGui end
    if not sg then
        local host = nil
        pcall(function()
            if type(gethui) == "function" then host = gethui() end
        end)
        if not host then
            pcall(function() host = game:GetService("CoreGui") end)
        end
        sg = Instance.new("ScreenGui")
        sg.Name           = "MuvaUI_Toasts"
        sg.ResetOnSpawn   = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.DisplayOrder   = 1000
        sg.IgnoreGuiInset = true
        if host then pcall(function() sg.Parent = host end) end
        if not sg.Parent then
            pcall(function()
                sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
            end)
        end
    end

    -- Container penuh layar agar VerticalAlignment.Bottom bisa bekerja.
    -- ZIndex tinggi → toast selalu di atas window saat share ScreenGui yg sama.
    local c = Instance.new("Frame")
    c.Name                   = "ToastContainer"
    c.BackgroundTransparency = 1
    c.Size                   = UDim2.new(1, 0, 1, 0)
    c.Position               = UDim2.new(0, 0, 0, 0)
    c.ZIndex                 = 100
    c.ClipsDescendants       = false
    c.Parent                 = sg

    -- Stack dari bawah ke atas, di pojok kanan
    local layout = Instance.new("UIListLayout")
    layout.FillDirection        = Enum.FillDirection.Vertical
    layout.HorizontalAlignment  = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment    = Enum.VerticalAlignment.Bottom
    layout.SortOrder            = Enum.SortOrder.LayoutOrder
    layout.Padding              = UDim.new(0, 6)
    layout.Parent               = c

    -- Padding bawah dan kanan agar tidak mepet tepi
    local pad = Instance.new("UIPadding")
    pad.PaddingBottom = UDim.new(0, 24)
    pad.PaddingRight  = UDim.new(0, 16)
    pad.Parent        = c

    _container = c
    return c
end

function Toast.show(opts, screenGui)
    opts = opts or {}
    local style   = resolveStyle(opts.Type)
    local color   = style.color()
    local hasBody = opts.Body and opts.Body ~= ""
    local toastH  = hasBody and 60 or 42

    local container = getContainer(screenGui)

    _orderCount = _orderCount + 1

    local toast = Instance.new("Frame")
    toast.Name             = "Toast"
    toast.BackgroundColor3 = Color.fromHex("#1c1c20")
    toast.BorderSizePixel  = 0
    toast.Size             = UDim2.fromOffset(280, toastH)
    toast.LayoutOrder      = _orderCount
    toast.ClipsDescendants = false
    toast.Parent           = container

    local toastCorner = Instance.new("UICorner")
    toastCorner.CornerRadius = UDim.new(0, 9)
    toastCorner.Parent       = toast

    local toastStroke = Instance.new("UIStroke")
    toastStroke.Color     = Color.fromHex("#2a2a2e")
    toastStroke.Thickness = 1
    toastStroke.Parent    = toast

    -- Left accent bar
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = color
    bar.BorderSizePixel  = 0
    bar.Size             = UDim2.new(0, 3, 1, -12)
    bar.Position         = UDim2.new(0, 0, 0, 6)
    bar.ZIndex = 1
    bar.Parent           = toast

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 2)
    barCorner.Parent       = bar

    -- Icon (sprite)
    local iconImg = Icons.new(style.icon, 16, color)
    iconImg.Position = UDim2.new(0, 14, 0.5, -8)
    iconImg.ZIndex   = 1
    iconImg.Parent   = toast

    -- Close button (sprite "x" — glyph ✕ tofu-risk)
    local closeBtn = Instance.new("TextButton")
    closeBtn.BackgroundTransparency = 1
    closeBtn.BorderSizePixel        = 0
    closeBtn.Size                   = UDim2.fromOffset(18, 18)
    closeBtn.Position               = UDim2.new(1, -22, 0, 7)
    closeBtn.Text                   = ""
    closeBtn.ZIndex = 1
    closeBtn.AutoButtonColor        = false
    closeBtn.Parent                 = toast

    local closeIco = Icons.new("x", 12, Color.fromHex("#555555"))
    closeIco.AnchorPoint = Vector2.new(0.5, 0.5)
    closeIco.Position    = UDim2.new(0.5, 0, 0.5, 0)
    closeIco.ZIndex      = 1
    closeIco.Parent      = closeBtn

    closeBtn.MouseEnter:Connect(function() closeIco.ImageColor3 = Color.fromHex("#cccccc") end)
    closeBtn.MouseLeave:Connect(function() closeIco.ImageColor3 = Color.fromHex("#555555") end)

    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size                   = UDim2.new(1, -56, 0, 16)
    titleLbl.Position               = hasBody
        and UDim2.new(0, 36, 0, 12)
        or  UDim2.new(0, 36, 0.5, -8)
    titleLbl.Text                   = opts.Title or ""
    titleLbl.Font                   = Enum.Font.GothamBold
    titleLbl.TextSize               = 13
    titleLbl.TextColor3             = Color.fromHex("#f0f0f0")
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 1
    titleLbl.Parent                 = toast

    -- Body
    if hasBody then
        local msgLbl = Instance.new("TextLabel")
        msgLbl.BackgroundTransparency = 1
        msgLbl.Size                   = UDim2.new(1, -56, 0, 24)
        msgLbl.Position               = UDim2.new(0, 36, 0, 30)
        msgLbl.Text                   = opts.Body
        msgLbl.Font                   = Enum.Font.Gotham
        msgLbl.TextSize               = 12
        msgLbl.TextColor3             = Color.fromHex("#999999")
        msgLbl.TextXAlignment         = Enum.TextXAlignment.Left
        msgLbl.TextWrapped            = true
        msgLbl.ZIndex = 1
        msgLbl.Parent                 = toast
    end

    -- Dismiss
    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        Tween.play(toast, {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(280, 0),
        }, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
        task.delay(0.2, function() pcall(function() toast:Destroy() end) end)
    end

    closeBtn.MouseButton1Click:Connect(dismiss)

    -- Fade in. (JANGAN tween Position — toast anak UIListLayout, posisinya
    -- dikontrol layout sehingga tween posisi tak berefek.)
    toast.BackgroundTransparency = 1
    Tween.play(toast, {
        BackgroundTransparency = 0,
    }, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))

    local duration = opts.Duration or 3.5
    if duration > 0 then
        task.delay(duration, dismiss)
    end
end
