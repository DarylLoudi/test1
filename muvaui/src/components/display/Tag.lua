-- Tag: label yang bisa di-dismiss user
Section.AddTag = function(self, opts)
    assert(type(opts) == "table", "AddTag: opts must be a table")
    local removable = opts.Removable ~= false
    local tags      = {}
    for _, v in ipairs(opts.Tags or {}) do table.insert(tags, v) end

    local card, stroke = self:_makeCard()
    card.Size          = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y

    -- SortOrder+LayoutOrder eksplisit (tie by-Name bikin container Frame
    -- nangkring di atas judul — bug sama dgn Textarea).
    local col = Instance.new("UIListLayout")
    col.FillDirection = Enum.FillDirection.Vertical
    col.SortOrder     = Enum.SortOrder.LayoutOrder
    col.Padding       = UDim.new(0, 5)
    col.Parent        = card

    if opts.Title then
        local titleLbl = Instance.new("TextLabel")
        titleLbl.BackgroundTransparency = 1
        titleLbl.Size                   = UDim2.new(1, 0, 0, 15)
        titleLbl.Text                   = opts.Title
        titleLbl.Font                   = Layout.FONT_TITLE
        titleLbl.TextSize               = Layout.TITLE_SIZE
        titleLbl.TextColor3             = Theme:Text(1)
        titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
        titleLbl.LayoutOrder            = 1
        titleLbl.Parent                 = card
    end

    -- Tags container
    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size                   = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize          = Enum.AutomaticSize.Y
    container.LayoutOrder            = 2
    container.Parent                 = card

    local flowLayout = Instance.new("UIListLayout")
    flowLayout.FillDirection     = Enum.FillDirection.Horizontal
    flowLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    flowLayout.Wraps             = true
    flowLayout.Padding           = UDim.new(0, 5)
    flowLayout.Parent            = container

    local tagObjects = {}

    local function removeTag(tag, tagFrame)
        for i, t in ipairs(tags) do
            if t == tag then table.remove(tags, i) break end
        end
        Tween.fast(tagFrame, { Size = UDim2.fromOffset(0, 22) })
        task.delay(0.15, function() tagFrame:Destroy() end)
        if opts.Callback then pcall(opts.Callback, tags) end
    end

    local function buildTag(tag)
        local frame = Instance.new("Frame")
        frame.BackgroundColor3 = Theme:BG(4)
        frame.BorderSizePixel  = 0
        frame.Size             = UDim2.fromOffset(0, 22)
        frame.AutomaticSize    = Enum.AutomaticSize.X
        frame.Parent           = container

        local fCorner = Instance.new("UICorner")
        fCorner.CornerRadius = UDim.new(0, 20)
        fCorner.Parent       = frame

        local fStroke = Instance.new("UIStroke")
        fStroke.Color     = Theme:Border(1)
        fStroke.Thickness = 1
        fStroke.Parent    = frame

        local fPad = Instance.new("UIPadding")
        fPad.PaddingLeft  = UDim.new(0, 8)
        fPad.PaddingRight = UDim.new(0, removable and 4 or 8)
        fPad.Parent       = frame

        local fRow = Instance.new("UIListLayout")
        fRow.FillDirection     = Enum.FillDirection.Horizontal
        fRow.VerticalAlignment = Enum.VerticalAlignment.Center
        fRow.Padding           = UDim.new(0, 4)
        fRow.Parent            = frame

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size                   = UDim2.fromOffset(0, 22)
        lbl.AutomaticSize          = Enum.AutomaticSize.X
        lbl.Text                   = tag
        lbl.Font                   = Enum.Font.Gotham
        lbl.TextSize               = 13
        lbl.TextColor3             = Theme:Accent()
        lbl.Parent                 = frame

        if removable then
            -- Tombol hapus = sprite "x" (glyph ✕ tofu-risk di Gotham)
            local xBtn = Instance.new("TextButton")
            xBtn.BackgroundTransparency = 1
            xBtn.BorderSizePixel        = 0
            xBtn.Size                   = UDim2.fromOffset(14, 22)
            xBtn.Text                   = ""
            xBtn.AutoButtonColor        = false
            xBtn.Parent                 = frame

            local xIco = Icons.new("x", 10, Theme:Text(3))
            xIco.AnchorPoint = Vector2.new(0.5, 0.5)
            xIco.Position    = UDim2.new(0.5, 0, 0.5, 0)
            xIco.Parent      = xBtn

            xBtn.MouseEnter:Connect(function() xIco.ImageColor3 = Theme:Text(0) end)
            xBtn.MouseLeave:Connect(function() xIco.ImageColor3 = Theme:Text(3) end)
            xBtn.MouseButton1Click:Connect(function() removeTag(tag, frame) end)
        end

        Theme:OnAccentChanged(function(accent) lbl.TextColor3 = accent end)
        table.insert(tagObjects, frame)
        return frame
    end

    for _, tag in ipairs(tags) do buildTag(tag) end

    table.insert(self._components, card)
    return card
end
