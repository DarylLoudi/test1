-- Accordion: collapsible section container
Section.AddAccordion = function(self, opts)
    assert(type(opts) == "table", "AddAccordion: opts must be a table")
    local open = opts.Open ~= false and opts.Open or false

    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Theme:BG(2)
    frame.BorderSizePixel  = 0
    frame.Size             = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize    = Enum.AutomaticSize.Y
    frame.ClipsDescendants = false
    frame.LayoutOrder      = #self._components + 10
    frame.Parent           = self._frame

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 7)
    frameCorner.Parent       = frame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color     = Theme:Border(0)
    frameStroke.Thickness = 1
    frameStroke.Parent    = frame

    local outerLayout = Instance.new("UIListLayout")
    outerLayout.FillDirection = Enum.FillDirection.Vertical
    outerLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    outerLayout.Parent        = frame

    -- Header
    local header = Instance.new("TextButton")
    header.BackgroundColor3 = Theme:BG(1)
    header.BorderSizePixel  = 0
    header.Size             = UDim2.new(1, 0, 0, 34)
    header.Text             = ""
    header.AutoButtonColor  = false
    header.LayoutOrder      = 1
    header.Parent           = frame

    local headerPad = Instance.new("UIPadding")
    headerPad.PaddingLeft  = UDim.new(0, 11)
    headerPad.PaddingRight = UDim.new(0, 11)
    headerPad.Parent       = header

    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size                   = UDim2.new(1, -20, 1, 0)
    titleLbl.Text                   = opts.Title or ""
    titleLbl.Font                   = Enum.Font.GothamMedium
    titleLbl.TextSize               = 14
    titleLbl.TextColor3             = open and Theme:Accent() or Theme:Text(2)
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
    titleLbl.Parent                 = header

    local arrowLbl = Instance.new("TextLabel")
    arrowLbl.BackgroundTransparency = 1
    arrowLbl.Size                   = UDim2.fromOffset(16, 34)
    arrowLbl.Position               = UDim2.new(1, -16, 0, 0)
    arrowLbl.Text                   = "v"
    arrowLbl.Font                   = Enum.Font.GothamBold
    arrowLbl.TextSize               = 12
    arrowLbl.TextColor3             = open and Theme:Accent() or Theme:Text(3)
    arrowLbl.Rotation               = open and 180 or 0
    arrowLbl.Parent                 = header

    -- Body container
    local body = Instance.new("Frame")
    body.BackgroundTransparency = 1
    body.Size                   = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize          = Enum.AutomaticSize.Y
    body.Visible                = open
    body.LayoutOrder            = 2
    body.Parent                 = frame

    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.FillDirection = Enum.FillDirection.Vertical
    bodyLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    bodyLayout.Padding       = UDim.new(0, 4)
    bodyLayout.Parent        = body

    local bodyPad = Instance.new("UIPadding")
    bodyPad.PaddingLeft   = UDim.new(0, 8)
    bodyPad.PaddingRight  = UDim.new(0, 8)
    bodyPad.PaddingTop    = UDim.new(0, 6)
    bodyPad.PaddingBottom = UDim.new(0, 8)
    bodyPad.Parent        = body

    -- Toggle open/close
    header.MouseButton1Click:Connect(function()
        open = not open
        body.Visible = open
        Tween.fast(arrowLbl, { Rotation = open and 180 or 0 })
        titleLbl.TextColor3 = open and Theme:Accent() or Theme:Text(2)
        arrowLbl.TextColor3 = open and Theme:Accent() or Theme:Text(3)
        frameStroke.Color   = open and Theme:Border(1) or Theme:Border(0)
    end)

    header.MouseEnter:Connect(function()
        Tween.fast(header, { BackgroundColor3 = Theme:BG(3) })
    end)
    header.MouseLeave:Connect(function()
        Tween.fast(header, { BackgroundColor3 = Theme:BG(1) })
    end)

    Theme:OnAccentChanged(function(accent)
        if open then
            titleLbl.TextColor3 = accent
            arrowLbl.TextColor3 = accent
        end
    end)

    -- Proxy so AddX methods work inside accordion body
    local acc = setmetatable({}, { __index = self })
    acc._frame      = body
    acc._components = {}
    acc._flags      = self._flags

    table.insert(self._components, frame)
    return acc
end
