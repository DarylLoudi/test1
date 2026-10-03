-- NumberInput: angka dengan tombol +/−
Section.AddNumberInput = function(self, opts)
    assert(type(opts) == "table", "AddNumberInput: opts must be a table")
    local min     = opts.Min     or 0
    local max     = opts.Max     or math.huge
    local step    = opts.Step    or 1
    local default = math.clamp(opts.Default or 0, min, max)
    local flag    = self:_registerFlag(opts.ID, default)

    local card, stroke = self:_makeCard()

    local row = Instance.new("UIListLayout")
    row.FillDirection     = Enum.FillDirection.Horizontal
    row.VerticalAlignment = Enum.VerticalAlignment.Center
    row.Padding           = UDim.new(0, 8)
    row.Parent            = card

    -- Info
    local info = self:_makeInfoBlock(card, opts.Title, nil, 110)

    -- Controls wrapper
    local controls = Instance.new("Frame")
    controls.BackgroundColor3 = Theme:BG(1)
    controls.BorderSizePixel  = 0
    controls.Size             = UDim2.fromOffset(100, 28)
    controls.ClipsDescendants = true
    controls.LayoutOrder      = 99
    controls.Parent           = card

    local ctrlCorner = Instance.new("UICorner")
    ctrlCorner.CornerRadius = UDim.new(0, 6)
    ctrlCorner.Parent       = controls

    -- Border = ungu accent (senada Button). Idle transparan 0.4; focus → penuh.
    local ctrlStroke = Instance.new("UIStroke")
    ctrlStroke.Color        = Theme:Accent()
    ctrlStroke.Transparency = 0.4
    ctrlStroke.Thickness    = 1
    ctrlStroke.Parent       = controls

    -- Minus button
    local btnMinus = Instance.new("TextButton")
    btnMinus.Size                   = UDim2.fromOffset(26, 28)
    btnMinus.Position               = UDim2.new(0, 0, 0, 0)
    btnMinus.BackgroundColor3       = Theme:BG(3)
    btnMinus.BorderSizePixel        = 0
    btnMinus.Text                   = "-"
    btnMinus.Font                   = Enum.Font.GothamBold
    btnMinus.TextSize               = 14
    btnMinus.TextColor3             = Theme:Text(2)
    btnMinus.AutoButtonColor        = false
    btnMinus.Parent                 = controls

    -- Value box
    local valBox = Instance.new("TextBox")
    valBox.Size                   = UDim2.new(1, -52, 1, 0)
    valBox.Position               = UDim2.new(0, 26, 0, 0)
    valBox.BackgroundTransparency = 1
    valBox.BorderSizePixel        = 0
    valBox.Text                   = tostring(default)
    valBox.Font                   = Enum.Font.Gotham
    valBox.TextSize               = 14
    valBox.TextColor3             = Theme:Text(0)
    valBox.TextXAlignment         = Enum.TextXAlignment.Center
    valBox.ClearTextOnFocus       = false
    valBox.Parent                 = controls

    -- Plus button
    local btnPlus = Instance.new("TextButton")
    btnPlus.Size                   = UDim2.fromOffset(26, 28)
    btnPlus.Position               = UDim2.new(1, -26, 0, 0)
    btnPlus.BackgroundColor3       = Theme:BG(3)
    btnPlus.BorderSizePixel        = 0
    btnPlus.Text                   = "+"
    btnPlus.Font                   = Enum.Font.GothamBold
    btnPlus.TextSize               = 14
    btnPlus.TextColor3             = Theme:Text(2)
    btnPlus.AutoButtonColor        = false
    btnPlus.Parent                 = controls

    local value = default

    local function setValue(v)
        value        = math.clamp(v, min, max)
        valBox.Text  = tostring(value)
        if flag then flag:_fire(value) end
        if opts.Callback then pcall(opts.Callback, value) end
    end

    btnMinus.MouseButton1Click:Connect(function()
        setValue(value - step)
    end)
    btnPlus.MouseButton1Click:Connect(function()
        setValue(value + step)
    end)

    -- Direct text edit
    valBox.FocusLost:Connect(function()
        local n = tonumber(valBox.Text)
        if n then
            setValue(n)
        else
            valBox.Text = tostring(value)
        end
    end)

    -- Hover effects on buttons
    for _, btn in ipairs({ btnMinus, btnPlus }) do
        btn.MouseEnter:Connect(function()
            Tween.fast(btn, { BackgroundColor3 = Theme:BG(4) })
            btn.TextColor3 = Theme:Text(0)
        end)
        btn.MouseLeave:Connect(function()
            Tween.fast(btn, { BackgroundColor3 = Theme:BG(3) })
            btn.TextColor3 = Theme:Text(2)
        end)
    end

    -- Focus ring
    valBox.Focused:Connect(function()
        ctrlStroke.Color = Theme:Accent()
        Tween.fast(ctrlStroke, { Transparency = 0 })
    end)
    valBox.FocusLost:Connect(function()
        ctrlStroke.Color = Theme:Accent()
        Tween.fast(ctrlStroke, { Transparency = 0.4 })
    end)

    card.MouseEnter:Connect(function()
        Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
        stroke.Color = Theme:Border(1)
    end)
    card.MouseLeave:Connect(function()
        Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
        stroke.Color = Theme:Border(0)
    end)

    if flag then
        flag:OnChanged(function(v)
            value       = math.clamp(v, min, max)
            valBox.Text = tostring(value)
        end)
    end

    table.insert(self._components, card)
    return card
end
