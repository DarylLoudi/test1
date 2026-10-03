-- Tab: satu tab di dalam Window
-- Berisi satu atau lebih Section
Tab = {}
Tab.__index = Tab

function Tab.new(opts, contentParent, flags)
    local self = setmetatable({}, Tab)
    self._flags    = flags
    self._sections = {}
    self._state    = nil  -- feedback state aktif

    -- Content frame — ditampilkan saat tab ini aktif
    self._frame = Instance.new("ScrollingFrame")
    self._frame.Name                   = "Tab_" .. (opts.Title or "Tab")
    self._frame.BackgroundTransparency = 1
    self._frame.Size                   = UDim2.new(1, 0, 1, 0)
    self._frame.CanvasSize             = UDim2.new(0, 0, 0, 0)
    self._frame.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    self._frame.ScrollBarThickness     = 3
    self._frame.ScrollBarImageColor3   = Theme:BG(4)
    self._frame.BorderSizePixel        = 0
    self._frame.Visible                = false
    self._frame.Parent                 = contentParent

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder     = Enum.SortOrder.LayoutOrder
    layout.Padding       = UDim.new(0, 8)
    layout.Parent        = self._frame

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, 12)
    pad.PaddingRight  = UDim.new(0, 12)
    pad.PaddingTop    = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent        = self._frame

    -- State overlay (empty/error/loading etc)
    self._stateFrame = Instance.new("Frame")
    self._stateFrame.Name                   = "StateOverlay"
    self._stateFrame.BackgroundTransparency = 1
    self._stateFrame.Size                   = UDim2.new(1, 0, 1, 0)
    self._stateFrame.Position               = UDim2.new(0, 0, 0, 0)
    self._stateFrame.Visible                = false
    self._stateFrame.ZIndex                 = 10
    self._stateFrame.Parent                 = self._frame

    return self
end

function Tab:Show()
    self._frame.Visible = true
end

function Tab:Hide()
    self._frame.Visible = false
end

function Tab:AddSection(opts)
    local section = Section.new(opts, self._frame, self._flags)
    section._frame.LayoutOrder = #self._sections + 1
    table.insert(self._sections, section)
    return section
end

-- ── FEEDBACK STATES ─────────────────────────────────────────

-- nama sprite Lucide (Icons.new) — bukan emoji TextLabel
local STATE_ICONS = {
    Empty     = "inbox",
    Error     = "triangle-alert",
    NoResults = "search",
    Loading   = nil,   -- spinner, no icon
    Locked    = "lock",
    Warning   = "zap",
}

local STATE_COLORS = {
    Empty     = function() return Theme:Text(3) end,
    Error     = function() return Theme.Colors.Error end,
    NoResults = function() return Theme:Text(3) end,
    Loading   = function() return Theme:Text(3) end,
    Locked    = function() return Theme:Accent() end,
    Warning   = function() return Theme.Colors.Warn end,
}

function Tab:SetState(stateType, opts)
    -- Hide normal content
    for _, sec in ipairs(self._sections) do
        sec._frame.Visible = false
    end

    -- Clear previous state UI
    for _, child in ipairs(self._stateFrame:GetChildren()) do
        child:Destroy()
    end
    self._stateFrame.Visible = true

    local layout = Instance.new("UIListLayout")
    layout.FillDirection        = Enum.FillDirection.Vertical
    layout.HorizontalAlignment  = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment    = Enum.VerticalAlignment.Center
    layout.Padding              = UDim.new(0, 6)
    layout.Parent               = self._stateFrame

    local colorFn = STATE_COLORS[stateType]
    local color = colorFn and colorFn() or Theme:Accent()

    -- Icon or spinner (sprite Lucide — bukan glyph/emoji TextLabel)
    if stateType == "Loading" then
        local spinWrap = Instance.new("Frame")
        spinWrap.BackgroundTransparency = 1
        spinWrap.Size                   = UDim2.fromOffset(32, 32)
        spinWrap.Parent                 = self._stateFrame

        local spinner = Icons.new("loader", 22, Theme:Accent())
        spinner.Name        = "Spinner"
        spinner.AnchorPoint = Vector2.new(0.5, 0.5)
        spinner.Position    = UDim2.new(0.5, 0, 0.5, 0)
        spinner.Parent      = spinWrap
        Tween.play(spinner, { Rotation = 360 },
            TweenInfo.new(0.75, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1))
    else
        local iconName = STATE_ICONS[stateType]
        if iconName then
            local ico = Icons.new(iconName, 24, color)
            ico.Parent = self._stateFrame
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
        title.Parent                 = self._stateFrame
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
        body.TextSize               = 10
        body.Font                   = Enum.Font.Gotham
        body.TextColor3             = Theme:Text(3)
        body.TextXAlignment         = Enum.TextXAlignment.Center
        body.TextWrapped            = true
        body.Parent                 = self._stateFrame
    end

    -- Action button
    if opts.Action then
        local btn = Instance.new("TextButton")
        btn.Size                   = UDim2.fromOffset(90, 26)
        btn.BackgroundColor3       = color
        btn.BorderSizePixel        = 0
        btn.Text                   = opts.Action.Text or "Action"
        btn.TextSize               = 11
        btn.Font                   = Enum.Font.GothamBold
        btn.TextColor3             = Color.fromHex("#ffffff")
        btn.AutoButtonColor        = false
        btn.Parent                 = self._stateFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 5)
        btnCorner.Parent       = btn

        btn.MouseEnter:Connect(function()
            Tween.fast(btn, { BackgroundColor3 = Color.lighten(color, 0.08) })
        end)
        btn.MouseLeave:Connect(function()
            Tween.fast(btn, { BackgroundColor3 = color })
        end)
        btn.MouseButton1Click:Connect(function()
            if opts.Action.Callback then pcall(opts.Action.Callback) end
        end)
    end

    self._state = stateType
end

function Tab:ClearState()
    for _, child in ipairs(self._stateFrame:GetChildren()) do
        child:Destroy()
    end
    self._stateFrame.Visible = false
    for _, sec in ipairs(self._sections) do
        sec._frame.Visible = true
    end
    self._state = nil
end
