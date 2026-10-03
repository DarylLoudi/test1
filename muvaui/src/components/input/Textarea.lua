-- Textarea: multi-line text input
Section.AddTextarea = function(self, opts)
    assert(type(opts) == "table", "AddTextarea: opts must be a table")
    local flag = self:_registerFlag(opts.ID, opts.Default or "")

    local card, stroke = self:_makeCard()
    -- Tinggi = padY 9 + judul 15 + gap 5 + kotak 64 + padY 9 = 102 (dulu 96
    -- dgn isi 106 → elemen terakhir terpotong tepi card).
    Layout.lockHeight(card, 102)

    -- SortOrder + LayoutOrder WAJIB eksplisit. BUG LAMA: keduanya default →
    -- LayoutOrder seri (0) di-tie-break Roblox berdasarkan NAME alfabetis:
    -- "Frame" (kotak) < "TextLabel" (judul) → KOTAK dirender DI ATAS, judul
    -- nyasar ke bawah (terlihat "bukan input textbox").
    local col = Instance.new("UIListLayout")
    col.FillDirection = Enum.FillDirection.Vertical
    col.SortOrder     = Enum.SortOrder.LayoutOrder
    col.Padding       = UDim.new(0, 5)
    col.Parent        = card

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size                   = UDim2.new(1, 0, 0, 15)
    title.Text                   = opts.Title or ""
    title.Font                   = Layout.FONT_TITLE
    title.TextSize               = Layout.TITLE_SIZE
    title.TextColor3             = Theme:Text(1)
    title.TextXAlignment         = Enum.TextXAlignment.Left
    title.LayoutOrder            = 1
    title.Parent                 = card

    -- Textarea wrapper (di BAWAH judul)
    local wrap = Instance.new("Frame")
    wrap.BackgroundColor3 = Theme:BG(1)
    wrap.BorderSizePixel  = 0
    wrap.Size             = UDim2.new(1, 0, 0, 64)
    wrap.ClipsDescendants = true
    wrap.LayoutOrder      = 2
    wrap.Parent           = card

    local wrapCorner = Instance.new("UICorner")
    wrapCorner.CornerRadius = UDim.new(0, 6)
    wrapCorner.Parent       = wrap

    -- Border = ungu accent, cukup terlihat saat idle (0.22); focus → penuh.
    local wrapStroke = Instance.new("UIStroke")
    wrapStroke.Color        = Theme:Accent()
    wrapStroke.Transparency = 0.22
    wrapStroke.Thickness    = 1
    wrapStroke.Parent       = wrap
    task.defer(function()
        if wrapStroke and wrapStroke.Parent then wrapStroke.Thickness = 1.0001; wrapStroke.Thickness = 1 end
    end)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, 9)
    pad.PaddingRight  = UDim.new(0, 9)
    pad.PaddingTop    = UDim.new(0, 7)
    pad.PaddingBottom = UDim.new(0, 7)
    pad.Parent        = wrap

    local box = Instance.new("TextBox")
    box.BackgroundTransparency = 1
    box.BorderSizePixel        = 0
    box.Size                   = UDim2.new(1, 0, 1, 0)
    box.Text                   = opts.Default or ""
    box.PlaceholderText        = opts.Placeholder or ""
    box.PlaceholderColor3      = Theme:Text(4)
    box.Font                   = Enum.Font.Gotham
    box.TextSize               = Layout.VALUE_SIZE
    box.TextColor3             = Theme:Text(0)
    box.TextXAlignment         = Enum.TextXAlignment.Left
    box.TextYAlignment         = Enum.TextYAlignment.Top
    box.MultiLine              = true
    box.ClearTextOnFocus       = false
    box.TextWrapped            = true
    box.Parent                 = wrap

    box.Focused:Connect(function()
        wrapStroke.Color = Theme:Accent()
        Tween.fast(wrapStroke, { Transparency = 0 })
    end)

    box.FocusLost:Connect(function()
        wrapStroke.Color = Theme:Accent()
        Tween.fast(wrapStroke, { Transparency = 0.22 })
        if flag then flag:_fire(box.Text) end
        if opts.Callback then pcall(opts.Callback, box.Text) end
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
            box.Text = tostring(v)
        end)
    end

    table.insert(self._components, card)
    return card
end
