-- Section: container komponen di dalam Tab
-- Setiap Section punya title separator + vertical list of components
Section = {}
Section.__index = Section

function Section.new(opts, parentFrame, flags)
    local self = setmetatable({}, Section)
    self._flags      = flags
    self._components = {}
    self._collapsed  = true    -- default TERTUTUP → semua section collapse saat load
                               -- (user klik header utk buka). Ubah ke false = default terbuka.

    -- Outer container (header + content wrapper)
    self._frame = Instance.new("Frame")
    self._frame.Name                    = "Section_" .. (opts.Title or "Untitled")
    self._frame.BackgroundTransparency  = 1
    self._frame.Size                    = UDim2.new(1, 0, 0, 0)
    self._frame.AutomaticSize           = Enum.AutomaticSize.Y
    self._frame.Parent                  = parentFrame

    local outerLayout = Instance.new("UIListLayout")
    outerLayout.FillDirection  = Enum.FillDirection.Vertical
    outerLayout.SortOrder      = Enum.SortOrder.LayoutOrder
    outerLayout.Padding        = UDim.new(0, 0)
    outerLayout.Parent         = self._frame

    -- Content wrapper: menampung semua card komponen.
    -- Di-hide saat collapse sehingga AutomaticSize _frame menyusut otomatis.
    self._content = Instance.new("Frame")
    self._content.Name                   = "Content"
    self._content.BackgroundTransparency = 1
    self._content.Size                   = UDim2.new(1, 0, 0, 0)
    self._content.AutomaticSize          = Enum.AutomaticSize.Y
    self._content.LayoutOrder            = 1
    self._content.Parent                 = self._frame

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection  = Enum.FillDirection.Vertical
    contentLayout.SortOrder      = Enum.SortOrder.LayoutOrder
    contentLayout.Padding        = UDim.new(0, Layout.GAP_CARD)
    contentLayout.Parent         = self._content

    local contentPad = Instance.new("UIPadding")
    contentPad.PaddingTop    = UDim.new(0, Layout.GAP_CARD)
    contentPad.PaddingBottom = UDim.new(0, Layout.GAP_CARD)
    contentPad.Parent        = self._content

    -- Section separator header (clickable jika ada title)
    if opts.Title then
        self:_buildSeparator(opts.Title)
    end

    return self
end

function Section:_buildSeparator(label)
    -- Header section gaya "pill": kartu rounded yg jadi terang saat hover, accent
    -- bar kiri, label, & chevron kanan. TANPA garis melebar (yg dulu terlihat
    -- berantakan) — header rapi & terasa interaktif.
    local row = Instance.new("TextButton")
    row.Name                    = "Separator"
    -- Fill SAMA PERSIS dengan card (_makeCard: BG(2) trans 0.15) — konsisten;
    -- pembeda header cukup dari accent bar kiri + label ungu + underline glow.
    row.BackgroundColor3        = Theme:BG(2)
    row.BackgroundTransparency  = 0.15
    row.BorderSizePixel         = 0
    row.AutoButtonColor         = false
    row.Text                    = ""
    row.Size                    = UDim2.new(1, 0, 0, 36)   -- kompak (ala hub modern)
    row.LayoutOrder             = 0
    row.Parent                  = self._frame

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius      = UDim.new(0, 8)
    rowCorner.Parent            = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Color             = Theme:Border(0)
    rowStroke.Thickness         = 1
    rowStroke.ApplyStrokeMode   = Enum.ApplyStrokeMode.Border
    rowStroke.Parent            = row
    task.defer(function()
        if rowStroke and rowStroke.Parent then rowStroke.Thickness = 1.0001; rowStroke.Thickness = 1 end
    end)

    local rowPad = Instance.new("UIPadding")
    rowPad.PaddingLeft  = UDim.new(0, 12)
    rowPad.PaddingRight = UDim.new(0, 12)
    rowPad.Parent       = row

    -- GLOW NEON di bawah header — tampil HANYA saat section TERBUKA, hilang
    -- saat ditutup. Gaya "lampu": inti garis terang di TENGAH yang memudar ke
    -- kedua UJUNG (gradient horizontal) + bloom lembut menyebar di atas/bawah
    -- (lapisan makin tebal makin transparan). Murni frame + UIGradient, tanpa
    -- asset. (Versi lama = garis flat polos → ditolak user.)
    local GLOW_FADE = NumberSequence.new({
        NumberSequenceKeypoint.new(0,    1),
        NumberSequenceKeypoint.new(0.18, 0.45),
        NumberSequenceKeypoint.new(0.5,  0),
        NumberSequenceKeypoint.new(0.82, 0.45),
        NumberSequenceKeypoint.new(1,    1),
    })
    local glowParts = {}
    local function mkGlowLayer(height, baseTrans, z, color)
        local g = Instance.new("Frame")
        g.Name                   = "OpenGlow" .. height
        g.BackgroundColor3       = color
        g.BackgroundTransparency = baseTrans
        g.BorderSizePixel        = 0
        g.AnchorPoint            = Vector2.new(0.5, 0.5)
        g.Position               = UDim2.new(0.5, 0, 1, -1)  -- pusat di tepi bawah header
        g.Size                   = UDim2.new(1, 0, 0, height)
        g.ZIndex                 = z
        g.Parent                 = row
        local grad = Instance.new("UIGradient")
        grad.Transparency = GLOW_FADE
        grad.Parent       = g
        glowParts[#glowParts + 1] = g
        return g
    end
    -- inti "panas" lebih terang dari accent + 2 lapis bloom accent
    local glowCore = mkGlowLayer(2,  0,    3, Color.lighten(Theme:Accent(), 0.3))
    local glowMid  = mkGlowLayer(6,  0.72, 2, Theme:Accent())
    local glowWide = mkGlowLayer(14, 0.88, 1, Theme:Accent())

    local function setOpenGlow(visible)
        for _, g in ipairs(glowParts) do g.Visible = visible end
    end

    -- Accent bar kiri (lebih tinggi & glowy)
    local bar = Instance.new("Frame")
    bar.Name                   = "AccentBar"
    bar.Size                   = UDim2.new(0, 3, 0, 16)
    bar.Position               = UDim2.new(0, 0, 0.5, -8)
    bar.BackgroundColor3       = Theme:Accent()
    bar.BorderSizePixel        = 0
    bar.Parent                 = row
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius     = UDim.new(1, 0)
    barCorner.Parent           = bar

    -- Label (letter-spacing manual via spasi tipis tidak ada di Roblox; pakai
    -- bold + uppercase + ukuran terukur untuk kesan "section heading" premium)
    local lbl = Instance.new("TextLabel")
    lbl.Name                   = "Label"
    lbl.Size                   = UDim2.new(1, -28, 1, 0)
    lbl.Position               = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = label:upper()
    lbl.TextColor3             = Theme:Text(2)
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 13
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.TextYAlignment         = Enum.TextYAlignment.Center
    lbl.Parent                 = row

    -- Ikon expand/collapse. Terbuka → "-", tertutup → "+". Awal ikut _collapsed.
    -- (ASCII "-"/"+", BUKAN U+2212 "−" yg tofu-risk di sebagian device.)
    local arrow = Instance.new("TextLabel")
    arrow.Name                   = "Arrow"
    arrow.BackgroundTransparency = 1
    arrow.Size                   = UDim2.new(0, 20, 1, 0)
    arrow.Position               = UDim2.new(1, -20, 0, 0)
    arrow.Text                   = self._collapsed and "+" or "-"
    arrow.Font                   = Enum.Font.GothamBold
    arrow.TextSize               = 17
    arrow.TextColor3             = self._collapsed and Theme:Text(3) or Theme:Accent()
    arrow.TextXAlignment         = Enum.TextXAlignment.Center
    arrow.Parent                 = row

    -- Keadaan AWAL section ikut self._collapsed (default tertutup): saat tertutup
    -- content disembunyikan, label netral, border redup, glow neon mati. Saat
    -- terbuka: content tampil, label accent, border terang, glow neon nyala.
    local content = self._content
    content.Visible = not self._collapsed
    lbl.TextColor3  = self._collapsed and Theme:Text(2) or Theme:Accent()
    rowStroke.Color = self._collapsed and Theme:Border(0) or Theme:Border(1)
    setOpenGlow(not self._collapsed)

    Theme:OnAccentChanged(function(accent)
        bar.BackgroundColor3      = accent
        glowCore.BackgroundColor3 = Color.lighten(accent, 0.3)
        glowMid.BackgroundColor3  = accent
        glowWide.BackgroundColor3 = accent
        if not self._collapsed then lbl.TextColor3 = accent end
    end)

    -- Hover: border naik (TANPA mengisi fill → jaga keseragaman glass)
    row.MouseEnter:Connect(function()
        Tween.fast(rowStroke, { Thickness = 1 })
        rowStroke.Color = Theme:Accent()
    end)
    row.MouseLeave:Connect(function()
        rowStroke.Color = self._collapsed and Theme:Border(0) or Theme:Border(1)
    end)

    -- Toggle collapse saat header diklik (glow neon ikut: buka=tampil,
    -- tutup=hilang)
    row.MouseButton1Click:Connect(function()
        self._collapsed = not self._collapsed
        if self._collapsed then
            arrow.Text       = "+"
            arrow.TextColor3 = Theme:Text(3)
            lbl.TextColor3   = Theme:Text(2)
            rowStroke.Color  = Theme:Border(0)
            content.Visible  = false
            setOpenGlow(false)
        else
            arrow.Text       = "-"
            arrow.TextColor3 = Theme:Accent()
            lbl.TextColor3   = Theme:Accent()
            rowStroke.Color  = Theme:Border(1)
            content.Visible  = true
            setOpenGlow(true)
        end
    end)
end

-- Helper: buat comp card (background row yang dipakai hampir semua komponen)
function Section:_makeCard(layoutOrder)
    -- Card = PANEL TERPISAH yang jelas (fill gelap hampir solid), BUKAN glass
    -- transparan penuh seperti dulu (0.94). Feedback user: tanpa fill pembeda,
    -- antar-komponen tampak menyatu → membingungkan. Fill + gap antar card
    -- (GAP_CARD) + border tipis = tiap bagian terbaca sebagai blok sendiri.
    -- Warna dasar BG(2) SENGAJA sama dgn target MouseLeave di handler hover
    -- tiap komponen (enter → BG(3) mencerah, leave → balik BG(2) = base).
    local card = Instance.new("Frame")
    card.Name                   = "Card"
    card.BackgroundColor3       = Theme:BG(2)
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel        = 0
    card.Size                   = UDim2.new(1, 0, 0, Layout.CARD_FLOOR_H)
    card.LayoutOrder            = layoutOrder or #self._components + 10
    card.Parent                 = self._content

    -- Card tumbuh mengikuti konten, minimal Layout.CARD_FLOOR_H (anti-overflow).
    -- SENGAJA lebih rendah dari CARD_MIN_H: toggle/checkbox tanpa Desc (mis. "AA
    -- Farm Egg") tidak boleh dipaksa setinggi card yang punya dua baris teks —
    -- itu ruang kosong terbuang. Komponen yang butuh tinggi tetap (Dropdown,
    -- TextInput, dst) tetap override lewat Layout.lockHeight ke CARD_MIN_H.
    Layout.applyAutoHeight(card, Layout.CARD_FLOOR_H)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Layout.CARD_RADIUS)
    corner.Parent       = card

    local stroke = Instance.new("UIStroke")
    stroke.Color            = Theme:Border(0)
    stroke.Thickness        = 1
    stroke.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
    stroke.Parent           = card
    -- paksa raster awal stroke (CanvasGroup quirk)
    task.defer(function()
        if stroke and stroke.Parent then stroke.Thickness = 1.0001; stroke.Thickness = 1 end
    end)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, Layout.PAD_X)
    pad.PaddingRight  = UDim.new(0, Layout.PAD_X)
    pad.PaddingTop    = UDim.new(0, Layout.PAD_Y)
    pad.PaddingBottom = UDim.new(0, Layout.PAD_Y)
    pad.Parent        = card

    return card, stroke
end

-- Helper: frame info vertikal (title + desc opsional) dengan token standar
-- reserveRight: lebar yang dikurangi dari info.Size (default Layout.TOGGLE_RES)
-- returns: info, titleLbl, descLbl (descLbl nil jika tidak ada desc)
function Section:_makeInfoBlock(parent, titleText, descText, reserveRight)
    local reserve = reserveRight or Layout.TOGGLE_RES

    local info = Instance.new("Frame")
    info.BackgroundTransparency = 1
    info.Size                   = UDim2.new(1, -reserve, 0, 0)
    info.AutomaticSize          = Enum.AutomaticSize.Y
    info.Parent                 = parent

    local infoL = Instance.new("UIListLayout")
    infoL.FillDirection     = Enum.FillDirection.Vertical
    infoL.VerticalAlignment = Enum.VerticalAlignment.Center
    infoL.Padding           = UDim.new(0, Layout.GAP_INFO)
    infoL.Parent            = info

    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size                   = UDim2.new(1, 0, 0, Layout.TITLE_SIZE)
    titleLbl.AutomaticSize          = Enum.AutomaticSize.Y
    titleLbl.Text                   = titleText or ""
    titleLbl.Font                   = Layout.FONT_TITLE
    titleLbl.TextSize               = Layout.TITLE_SIZE
    titleLbl.TextColor3             = Theme:Text(1)
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
    titleLbl.TextYAlignment         = Enum.TextYAlignment.Top
    titleLbl.TextWrapped            = true
    titleLbl.Parent                 = info

    local descLbl = nil
    if descText then
        descLbl = Instance.new("TextLabel")
        descLbl.BackgroundTransparency = 1
        descLbl.Size                   = UDim2.new(1, 0, 0, Layout.DESC_SIZE)
        descLbl.AutomaticSize          = Enum.AutomaticSize.Y
        descLbl.Text                   = descText
        descLbl.Font                   = Layout.FONT_BODY
        descLbl.TextSize               = Layout.DESC_SIZE
        descLbl.TextColor3             = Theme:Text(3)
        descLbl.TextXAlignment         = Enum.TextXAlignment.Left
        descLbl.TextYAlignment         = Enum.TextYAlignment.Top
        descLbl.TextWrapped            = true
        descLbl.LineHeight             = 1.25
        descLbl.Parent                 = info
    end

    return info, titleLbl, descLbl
end

-- ── COMPONENT REGISTRATION ──────────────────────────────────

function Section:_registerFlag(id, default)
    if not id then return nil end
    local flag = Flag.new(id, default)
    self._flags[id] = flag
    return flag
end

-- Forward declarations — akan diisi oleh file components/
Section.AddToggle        = nil
Section.AddCheckbox      = nil
Section.AddSlider        = nil
Section.AddNumberInput   = nil
Section.AddTextInput     = nil
Section.AddTextarea      = nil
Section.AddDropdown      = nil
Section.AddMultiDropdown = nil
Section.AddKeybind       = nil
Section.AddColorPicker   = nil
Section.AddButton        = nil
Section.AddBadge         = nil
Section.AddTag           = nil
Section.AddProgressBar   = nil
Section.AddInfoDisplay   = nil
Section.AddParagraph     = nil
Section.AddCodeBlock     = nil
Section.AddDivider       = nil
Section.AddAvatar        = nil
Section.AddTable         = nil
Section.AddSeparator     = nil
Section.AddHStack        = nil
Section.AddVStack        = nil
Section.AddSpace         = nil
Section.AddAccordion     = nil
Section.AddWebhook       = nil
