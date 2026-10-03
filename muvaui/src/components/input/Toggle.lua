-- Toggle: ON/OFF switch
Section.AddToggle = function(self, opts)
    assert(type(opts) == "table", "AddToggle: opts must be a table")
    local flag = self:_registerFlag(opts.ID, opts.Default or false)

    local card, stroke = self:_makeCard()

    -- Horizontal row layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection        = Enum.FillDirection.Horizontal
    layout.VerticalAlignment    = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment  = Enum.HorizontalAlignment.Left
    layout.Padding              = UDim.new(0, 8)
    layout.SortOrder            = Enum.SortOrder.LayoutOrder
    layout.Parent               = card

    -- Info (left, fills remaining space)
    local info = self:_makeInfoBlock(card, opts.Title, opts.Desc, Layout.TOGGLE_RES)
    info.LayoutOrder = 1

    -- Toggle track (right) — kompak (TOGGLE_W=44, tinggi 24, knob 18)
    local TRACK_H, KNOB, PAD = 24, 18, 3
    local KNOB_ON  = Layout.TOGGLE_W - KNOB - PAD   -- posisi x knob saat ON
    local KNOB_OFF = PAD
    local track = Instance.new("Frame")
    track.Size              = UDim2.fromOffset(Layout.TOGGLE_W, TRACK_H)
    track.BackgroundColor3  = Theme:BG(4)
    track.BorderSizePixel   = 0
    track.LayoutOrder       = 2
    track.Parent            = card

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent       = track

    local trackStroke = Instance.new("UIStroke")
    trackStroke.Color     = Theme:Border(1)
    trackStroke.Thickness = 1
    trackStroke.Parent    = track

    -- Knob
    local knob = Instance.new("Frame")
    knob.Size             = UDim2.fromOffset(KNOB, KNOB)
    knob.Position         = UDim2.fromOffset(KNOB_OFF, PAD)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 2
    knob.Parent           = track

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent       = knob

    -- HITBOX tap: transparan, sedikit lebih besar dari track (target jari Android
    -- ≥44px) & menutupi area switch. HANYA hitbox ini yg reaktif — area teks/judul
    -- card TIDAK men-toggle (sesuai ekspektasi: cuma switch yg bisa di-tap). Ini
    -- juga otomatis membereskan bug scroll: menyeret area teks card tak memicu toggle.
    local hitbox = Instance.new("TextButton")
    hitbox.Name                   = "ToggleHitbox"
    hitbox.BackgroundTransparency = 1
    hitbox.AutoButtonColor        = false
    hitbox.Text                   = ""
    hitbox.AnchorPoint            = Vector2.new(0.5, 0.5)
    hitbox.Position               = UDim2.new(0.5, 0, 0.5, 0)
    hitbox.Size                   = UDim2.new(1, 16, 1, 16)   -- track + 8px tiap sisi
    hitbox.ZIndex                 = 3
    hitbox.Parent                 = track

    local value = opts.Default or false

    local function updateVisual(val, animated)
        if val then
            if animated then
                Tween.play(track, { BackgroundColor3 = Theme:Accent() })
                Tween.play(knob,  { Position = UDim2.fromOffset(KNOB_ON, PAD) })
            else
                track.BackgroundColor3 = Theme:Accent()
                knob.Position          = UDim2.fromOffset(KNOB_ON, PAD)
            end
            trackStroke.Color = Theme:Accent()
        else
            if animated then
                Tween.play(track, { BackgroundColor3 = Theme:BG(4) })
                Tween.play(knob,  { Position = UDim2.fromOffset(KNOB_OFF, PAD) })
            else
                track.BackgroundColor3 = Theme:BG(4)
                knob.Position          = UDim2.fromOffset(KNOB_OFF, PAD)
            end
            trackStroke.Color = Theme:Border(1)
        end
    end

    updateVisual(value, false)

    -- TAP-detection di HITBOX SWITCH (bukan seluruh card): flip hanya saat switch
    -- benar2 di-tap (tekan-lepas tanpa menyeret). Klik area teks card ≠ toggle.
    Tween.bindTap(hitbox, function()
        value = not value
        updateVisual(value, true)
        if flag then flag:_fire(value) end
        if opts.Callback then pcall(opts.Callback, value) end
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
        if value then
            track.BackgroundColor3 = accent
            trackStroke.Color      = accent
        end
    end)

    if flag then
        flag:OnChanged(function(v)
            value = v
            updateVisual(v, true)
        end)
    end

    table.insert(self._components, card)
    return card
end
