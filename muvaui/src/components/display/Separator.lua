-- Separator: section header separator di dalam section
-- Berbeda dari Divider — Separator punya accent bar kiri + label + garis kanan
Section.AddSeparator = function(self, opts)
    opts = opts or {}

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size                   = UDim2.new(1, 0, 0, 18)
    frame.LayoutOrder            = #self._components + 10
    frame.Parent                 = self._frame

    if opts.Label then
        -- Accent bar
        local bar = Instance.new("Frame")
        bar.BackgroundColor3 = Theme:Accent()
        bar.BorderSizePixel  = 0
        bar.Size             = UDim2.fromOffset(3, 12)
        bar.Position         = UDim2.new(0, 0, 0.5, -6)
        bar.Parent           = frame

        local barC = Instance.new("UICorner")
        barC.CornerRadius = UDim.new(0, 2)
        barC.Parent       = bar

        -- Label
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size                   = UDim2.new(0, 0, 1, 0)
        lbl.AutomaticSize          = Enum.AutomaticSize.X
        lbl.Position               = UDim2.new(0, 8, 0, 0)
        lbl.Text                   = opts.Label:upper()
        lbl.Font                   = Enum.Font.GothamBold
        lbl.TextSize               = 12
        lbl.TextColor3             = Theme:Text(3)
        lbl.Parent                 = frame

        -- Line
        local line = Instance.new("Frame")
        line.BackgroundColor3 = Theme:Border(0)
        line.BorderSizePixel  = 0
        line.Size             = UDim2.new(1, -16, 0, 1)
        line.Position         = UDim2.new(0, 16, 0.5, 0)
        line.Parent           = frame

        -- Realign line after label renders
        lbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            line.Size     = UDim2.new(1, -(lbl.AbsoluteSize.X + 14), 0, 1)
            line.Position = UDim2.new(0, lbl.AbsoluteSize.X + 14, 0.5, 0)
        end)

        Theme:OnAccentChanged(function(accent) bar.BackgroundColor3 = accent end)
    else
        -- Plain line only
        local line = Instance.new("Frame")
        line.BackgroundColor3 = Theme:Border(0)
        line.BorderSizePixel  = 0
        line.Size             = UDim2.new(1, 0, 0, 1)
        line.Position         = UDim2.new(0, 0, 0.5, 0)
        line.Parent           = frame
    end

    table.insert(self._components, frame)
    return frame
end
