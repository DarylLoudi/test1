-- Slider: range input dengan drag
local UserInputService = game:GetService("UserInputService")

Section.AddSlider = function(self, opts)
    assert(type(opts) == "table", "AddSlider: opts must be a table")
    local min     = opts.Min     or 0
    local max     = opts.Max     or 100
    local step    = opts.Step    or 1
    local suffix  = opts.Suffix  or ""
    local default = math.clamp(opts.Default or min, min, max)
    local flag    = self:_registerFlag(opts.ID, default)

    local card, stroke = self:_makeCard()
    Layout.lockHeight(card, 42)

    for _, c in ipairs(card:GetChildren()) do
        if c:IsA("UIListLayout") or c:IsA("UIPadding") then c:Destroy() end
    end

    -- Title + value pada baris atas
    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size                   = UDim2.new(1, -62, 0, 15)
    titleLbl.Position               = UDim2.new(0, 12, 0, 6)
    titleLbl.Text                   = opts.Title or ""
    titleLbl.Font                   = Layout.FONT_TITLE
    titleLbl.TextSize               = Layout.TITLE_SIZE
    titleLbl.TextColor3             = Theme:Text(1)
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
    titleLbl.Parent                 = card

    local valueLbl = Instance.new("TextLabel")
    valueLbl.BackgroundTransparency = 1
    valueLbl.Size                   = UDim2.fromOffset(50, 15)
    valueLbl.Position               = UDim2.new(1, -62, 0, 6)
    valueLbl.Font                   = Layout.FONT_BOLD
    valueLbl.TextSize               = Layout.TITLE_SIZE
    valueLbl.TextColor3             = Theme:Accent()
    valueLbl.TextXAlignment         = Enum.TextXAlignment.Right
    valueLbl.Parent                 = card

    -- Track di baris bawah
    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1, -24, 0, 4)
    track.Position         = UDim2.new(0, 12, 0, 28)
    track.BackgroundColor3 = Theme:BG(4)
    track.BorderSizePixel  = 0
    track.Parent           = card

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent       = track

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Theme:Accent()
    fill.BorderSizePixel  = 0
    fill.Parent           = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent       = fill

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.fromOffset(13, 13)
    knob.Position         = UDim2.new(0, 0, 0.5, -6)
    knob.BackgroundColor3 = Theme:Accent()
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 3
    knob.Parent           = track

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent       = knob

    local value = default

    local function snapStep(v)
        return math.clamp(math.round((v - min) / step) * step + min, min, max)
    end

    local function updateVisual(val)
        local pct = (val - min) / (max - min)
        fill.Size     = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, -6, 0.5, -6)
        valueLbl.Text = tostring(val) .. suffix
    end

    updateVisual(value)

    local dragging = false

    local function calcValue(inputX)
        local abs  = track.AbsolutePosition.X
        local size = track.AbsoluteSize.X
        local pct  = math.clamp((inputX - abs) / size, 0, 1)
        return snapStep(min + pct * (max - min))
    end

    local hitbox = Instance.new("TextButton")
    hitbox.Size                   = UDim2.new(1, 0, 1, 14)
    hitbox.Position               = UDim2.new(0, 0, 0, -5)
    hitbox.BackgroundTransparency = 1
    hitbox.Text                   = ""
    hitbox.ZIndex                 = 4
    hitbox.Parent                 = track

    hitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            value    = calcValue(input.Position.X)
            updateVisual(value)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        -- Touch drag mengirim UserInputType.Touch, mouse drag mengirim MouseMovement
        if dragging
        and (input.UserInputType == Enum.UserInputType.MouseMovement
          or input.UserInputType == Enum.UserInputType.Touch) then
            value = calcValue(input.Position.X)
            updateVisual(value)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1
         or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            dragging = false
            if flag then flag:_fire(value) end
            if opts.Callback then pcall(opts.Callback, value) end
        end
    end)

    hitbox.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1
         or input.UserInputType == Enum.UserInputType.Touch) and not dragging then
            if flag then flag:_fire(value) end
            if opts.Callback then pcall(opts.Callback, value) end
        end
    end)

    card.MouseEnter:Connect(function()
        Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
        stroke.Color = Theme:Border(1)
    end)
    card.MouseLeave:Connect(function()
        Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
        stroke.Color = Theme:Border(0)
    end)

    Theme:OnAccentChanged(function(accent)
        fill.BackgroundColor3  = accent
        knob.BackgroundColor3  = accent
        valueLbl.TextColor3    = accent
    end)

    if flag then
        flag:OnChanged(function(v)
            value = math.clamp(v, min, max)
            updateVisual(value)
        end)
    end

    table.insert(self._components, card)
    return card
end
