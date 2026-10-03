-- Checkbox: kotak centang dengan animasi
Section.AddCheckbox = function(self, opts)
    assert(type(opts) == "table", "AddCheckbox: opts must be a table")
    local flag = self:_registerFlag(opts.ID, opts.Default or false)

    local card, stroke = self:_makeCard()

    local row = Instance.new("UIListLayout")
    row.FillDirection       = Enum.FillDirection.Horizontal
    row.VerticalAlignment   = Enum.VerticalAlignment.Center
    row.Padding             = UDim.new(0, 8)
    row.Parent              = card

    -- Info
    local info = self:_makeInfoBlock(card, opts.Title, opts.Desc, 36)

    -- Box
    local box = Instance.new("Frame")
    box.Size             = UDim2.fromOffset(20, 20)
    box.BackgroundColor3 = Theme:BG(1)
    box.BorderSizePixel  = 0
    box.LayoutOrder      = 99
    box.Parent           = card

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent       = box

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color     = Theme:Border(1)
    boxStroke.Thickness = 1
    boxStroke.Parent    = box

    -- Checkmark = sprite (glyph ✓ tofu-risk di Gotham); toggle ImageTransparency.
    local check = Icons.new("check", 12, Color3.new(1, 1, 1))
    check.AnchorPoint       = Vector2.new(0.5, 0.5)
    check.Position          = UDim2.new(0.5, 0, 0.5, 0)
    check.ImageTransparency = 1
    check.Parent            = box

    -- HITBOX tap: transparan, lebih besar dari box (target jari Android). HANYA
    -- area ini yg reaktif — klik teks/judul card TIDAK mencentang. Juga membereskan
    -- bug scroll: menyeret area teks card tak memicu checkbox.
    local hitbox = Instance.new("TextButton")
    hitbox.Name                   = "CheckboxHitbox"
    hitbox.BackgroundTransparency = 1
    hitbox.AutoButtonColor        = false
    hitbox.Text                   = ""
    hitbox.AnchorPoint            = Vector2.new(0.5, 0.5)
    hitbox.Position               = UDim2.new(0.5, 0, 0.5, 0)
    hitbox.Size                   = UDim2.new(1, 20, 1, 20)   -- box 20px + 10px tiap sisi
    hitbox.ZIndex                 = 3
    hitbox.Parent                 = box

    local value = opts.Default or false

    local function updateVisual(val, animated)
        if val then
            if animated then
                Tween.fast(box,   { BackgroundColor3 = Theme:Accent() })
                Tween.fast(check, { ImageTransparency = 0 })
            else
                box.BackgroundColor3    = Theme:Accent()
                check.ImageTransparency = 0
            end
            boxStroke.Color = Theme:Accent()
        else
            if animated then
                Tween.fast(box,   { BackgroundColor3 = Theme:BG(1) })
                Tween.fast(check, { ImageTransparency = 1 })
            else
                box.BackgroundColor3    = Theme:BG(1)
                check.ImageTransparency = 1
            end
            boxStroke.Color = Theme:Border(1)
        end
    end

    updateVisual(value, false)

    -- TAP-detection di HITBOX BOX (bukan seluruh card): centang hanya saat box
    -- benar2 di-tap. Klik area teks card ≠ centang.
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
            box.BackgroundColor3 = accent
            boxStroke.Color      = accent
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
