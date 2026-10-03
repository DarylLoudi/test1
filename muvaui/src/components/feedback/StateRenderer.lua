-- StateRenderer: renders feedback states di Tab atau Section
-- Dipakai oleh Tab:SetState() dan Tab:ClearState()
-- File ini tidak expose method baru — hanya mendefinisikan helper
-- yang sudah dipakai oleh Tab.lua via local reference

-- STATE_ICONS dan STATE_COLORS sudah dideclare di Tab.lua
-- File ini berisi utilitas tambahan untuk rendering yang lebih rich

local StateRenderer = {}

-- Render shimmer loading skeleton (opsional, fallback ke spinner di Tab.lua)
function StateRenderer.buildSkeleton(parent, rows)
    rows = rows or 3
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size                   = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize          = Enum.AutomaticSize.Y
    frame.Parent                 = parent

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding       = UDim.new(0, 6)
    layout.Parent        = frame

    for i = 1, rows do
        local row = Instance.new("Frame")
        row.BackgroundColor3 = Theme:BG(3)
        row.BorderSizePixel  = 0
        row.Size             = UDim2.new(1, 0, 0, 28)
        row.Parent           = frame

        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 6)
        rowCorner.Parent       = row

        -- Shimmer sweep animation
        local shimmer = Instance.new("Frame")
        shimmer.BackgroundColor3       = Theme:BG(4)
        shimmer.BackgroundTransparency = 0.6
        shimmer.BorderSizePixel        = 0
        shimmer.Size                   = UDim2.new(0.3, 0, 1, 0)
        shimmer.Position               = UDim2.new(-0.3, 0, 0, 0)
        shimmer.ZIndex                 = 2
        shimmer.Parent                 = row

        local shCorner = Instance.new("UICorner")
        shCorner.CornerRadius = UDim.new(0, 6)
        shCorner.Parent       = shimmer

        -- Animate shimmer sweep
        local delay = (i - 1) * 0.15
        task.spawn(function()
            task.wait(delay)
            while shimmer.Parent do
                Tween.play(shimmer,
                    { Position = UDim2.new(1.3, 0, 0, 0) },
                    TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                )
                task.wait(0.9)
                shimmer.Position = UDim2.new(-0.3, 0, 0, 0)
                task.wait(0.3)
            end
        end)
    end

    return frame
end

-- Render an inline empty state inside any frame (used by Tab:SetState)
function StateRenderer.buildInline(parent, stateType, opts)
    opts = opts or {}

    -- nama sprite Lucide (Icons.new) — bukan emoji TextLabel
    local STATE_ICONS = {
        Empty     = "inbox",
        Error     = "triangle-alert",
        NoResults = "search",
        Locked    = "lock",
        Warning   = "zap",
    }
    local STATE_COLORS = {
        Empty     = Theme:Text(3),
        Error     = Color.fromHex("#f87171"),
        NoResults = Theme:Text(3),
        Locked    = Theme:Accent(),
        Warning   = Color.fromHex("#fbbf24"),
    }

    local color = STATE_COLORS[stateType] or Theme:Text(3)

    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size                   = UDim2.new(1, 0, 1, 0)
    container.Parent                 = parent

    local layout = Instance.new("UIListLayout")
    layout.FillDirection       = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment   = Enum.VerticalAlignment.Center
    layout.Padding             = UDim.new(0, 6)
    layout.Parent              = container

    -- Spinner for Loading state
    if stateType == "Loading" then
        local spinner = Instance.new("Frame")
        spinner.BackgroundTransparency = 1
        spinner.Size                   = UDim2.fromOffset(28, 28)
        spinner.Parent                 = container

        local ring = Instance.new("UIStroke")
        ring.Color     = Theme:BG(4)
        ring.Thickness = 3
        ring.Parent    = spinner

        local fill = Instance.new("Frame")
        fill.BackgroundTransparency = 1
        fill.Size                   = UDim2.new(1, 0, 1, 0)
        fill.Parent                 = spinner

        -- Spinner = sprite (glyph ◐ tofu-risk di sebagian device)
        local img = Icons.new("loader", 22, Theme:Accent())
        img.AnchorPoint = Vector2.new(0.5, 0.5)
        img.Position    = UDim2.new(0.5, 0, 0.5, 0)
        img.Parent      = spinner

        local spinInfo = TweenInfo.new(0.75, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1)
        Tween.play(img, { Rotation = 360 }, spinInfo)

        Theme:OnAccentChanged(function(a) img.ImageColor3 = a end)
    else
        local iconName = STATE_ICONS[stateType]
        if iconName then
            local ico = Icons.new(iconName, 24, color)
            ico.Parent = container
        end
    end

    -- Title
    if opts.Title then
        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.Size                   = UDim2.new(1, -24, 0, 0)
        title.AutomaticSize          = Enum.AutomaticSize.Y
        title.Text                   = opts.Title
        title.TextSize               = 12
        title.Font                   = Enum.Font.GothamBold
        title.TextColor3             = color
        title.TextXAlignment         = Enum.TextXAlignment.Center
        title.TextWrapped            = true
        title.Parent                 = container
    end

    -- Body
    local bodyText = opts.Body
    if stateType == "NoResults" and opts.Query then
        bodyText = 'Tidak ada hasil untuk "' .. opts.Query .. '"'
    end
    if bodyText then
        local body = Instance.new("TextLabel")
        body.BackgroundTransparency = 1
        body.Size                   = UDim2.new(1, -32, 0, 0)
        body.AutomaticSize          = Enum.AutomaticSize.Y
        body.Text                   = bodyText
        body.TextSize               = 13
        body.Font                   = Enum.Font.Gotham
        body.TextColor3             = Theme:Text(3)
        body.TextXAlignment         = Enum.TextXAlignment.Center
        body.TextWrapped            = true
        body.Parent                 = container
    end

    -- Action button
    if opts.Action then
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = color
        btn.BorderSizePixel  = 0
        btn.Size             = UDim2.fromOffset(90, 26)
        btn.Text             = opts.Action.Text or "Action"
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 10
        btn.TextColor3       = Color3.new(1, 1, 1)
        btn.AutoButtonColor  = false
        btn.Parent           = container

        local btnC = Instance.new("UICorner")
        btnC.CornerRadius = UDim.new(0, 5)
        btnC.Parent       = btn

        btn.MouseButton1Click:Connect(function()
            if opts.Action.Callback then pcall(opts.Action.Callback) end
        end)
    end

    return container
end
