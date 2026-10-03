-- Button: SELURUH CARD adalah tombol (feedback user, ala hub modern) —
-- TANPA kotak button ber-border + teks di sisi kanan seperti versi lama.
-- Isi card: Title + Desc (kiri) + ikon MOUSE (kanan) sebagai penanda
-- "bisa diklik". Fungsi tetap sama: tap card → opts.Callback().
-- Interaksi pakai Tween.bindTap (deteksi tap vs drag) supaya menggeser/scroll
-- di atas card TIDAK memicu klik (card hidup di dalam ScrollingFrame).
local STYLES = {
    Default = { tint = function() return Theme:Accent() end },        -- ungu tema
    Ghost   = { tint = function() return Theme:Text(2)  end },
    Success = { tint = function() return Theme.Colors.Success end },
    Danger  = { tint = function() return Theme.Colors.Error   end },
    Warn    = { tint = function() return Theme.Colors.Warn    end },
}

Section.AddButton = function(self, opts)
    assert(type(opts) == "table", "AddButton: opts must be a table")
    local style = STYLES[opts.Style] or STYLES.Default

    local card, stroke = self:_makeCard()

    -- Baris horizontal: info (kiri, mengisi sisa lebar) + ikon mouse (kanan).
    local layout = Instance.new("UIListLayout")
    layout.FillDirection       = Enum.FillDirection.Horizontal
    layout.VerticalAlignment   = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.Padding             = UDim.new(0, 8)
    layout.SortOrder           = Enum.SortOrder.LayoutOrder
    layout.Parent              = card

    local info = self:_makeInfoBlock(card, opts.Title or "Button", opts.Desc, 38)
    info.LayoutOrder = 1

    -- Ikon mouse = penanda aksi klik; tint mengikuti style (Default = accent).
    local mouseIco = Icons.new("mouse", 18, style.tint())
    mouseIco.LayoutOrder = 2
    mouseIco.Parent      = card

    -- Hover: pola card standar (mencerah + border naik) + ikon ikut menyala.
    card.MouseEnter:Connect(function()
        Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
        stroke.Color = Theme:Border(1)
        mouseIco.ImageColor3 = Color.lighten(style.tint(), 0.15)
    end)
    card.MouseLeave:Connect(function()
        Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
        stroke.Color = Theme:Border(0)
        mouseIco.ImageColor3 = style.tint()
    end)

    -- Tap = klik (drag/scroll TIDAK memicu). Feedback: kedip singkat.
    Tween.bindTap(card, function()
        local tint = style.tint()
        mouseIco.ImageColor3 = Color.lighten(tint, 0.35)
        Tween.fast(card, { BackgroundColor3 = Theme:BG(4) })
        task.delay(0.12, function()
            if mouseIco.Parent then mouseIco.ImageColor3 = tint end
            if card.Parent then Tween.fast(card, { BackgroundColor3 = Theme:BG(2) }) end
        end)
        if opts.Callback then pcall(opts.Callback) end
    end)

    if not opts.Style or opts.Style == "Default" then
        Theme:OnAccentChanged(function(accent)
            mouseIco.ImageColor3 = accent
        end)
    end

    table.insert(self._components, card)
    return card
end
