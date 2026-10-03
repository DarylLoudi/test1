-- Divider: pemisah visual, plain atau dengan label
Section.AddDivider = function(self, opts)
    opts = opts or {}

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size                   = UDim2.new(1, 0, 0, opts.Label and 16 or 8)
    frame.LayoutOrder            = #self._components + 10
    frame.Parent                 = self._frame

    if opts.Label then
        local row = Instance.new("UIListLayout")
        row.FillDirection     = Enum.FillDirection.Horizontal
        row.VerticalAlignment = Enum.VerticalAlignment.Center
        row.Padding           = UDim.new(0, 6)
        row.Parent            = frame

        local lineL = Instance.new("Frame")
        lineL.BackgroundColor3 = Theme:Border(0)
        lineL.BorderSizePixel  = 0
        lineL.Size             = UDim2.new(0.15, 0, 0, 1)
        lineL.Parent           = frame

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size                   = UDim2.new(0, 0, 1, 0)
        lbl.AutomaticSize          = Enum.AutomaticSize.X
        lbl.Text                   = opts.Label:upper()
        lbl.Font                   = Enum.Font.GothamBold
        lbl.TextSize               = 12
        lbl.TextColor3             = Theme:Text(4)
        lbl.Parent                 = frame

        local lineR = Instance.new("Frame")
        lineR.BackgroundColor3 = Theme:Border(0)
        lineR.BorderSizePixel  = 0
        lineR.Size             = UDim2.new(1, 0, 0, 1)
        lineR.Parent           = frame
    else
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
