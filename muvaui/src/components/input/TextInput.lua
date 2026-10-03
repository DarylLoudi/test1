-- TextInput: single-line text input
Section.AddTextInput = function(self, opts)
    assert(type(opts) == "table", "AddTextInput: opts must be a table")
    local flag = self:_registerFlag(opts.ID, opts.Default or "")

    local card, stroke = self:_makeCard()
    Layout.lockHeight(card, Layout.CARD_MIN_H)

    for _, c in ipairs(card:GetChildren()) do
        if c:IsA("UIPadding") or c:IsA("UIListLayout") then c:Destroy() end
    end

    -- Label kiri
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size                   = UDim2.new(0.45, -8, 1, 0)
    title.Position               = UDim2.new(0, Layout.PAD_X, 0, 0)
    title.Text                   = opts.Title or ""
    title.Font                   = Layout.FONT_TITLE
    title.TextSize               = Layout.TITLE_SIZE
    title.TextColor3             = Theme:Text(1)
    title.TextXAlignment         = Enum.TextXAlignment.Left
    title.Parent                 = card

    -- Input wrapper kanan — selalu anchor ke sisi kanan card.
    -- Width: angka px (default 90) atau string "X%" untuk input panjang mis. "55%".
    local CTRL = Layout.CTRL_H   -- tinggi input wrap (diperbesar, 34)
    local wrapSize
    if type(opts.Width) == "string" and opts.Width:match("%%$") then
        local pct = tonumber(opts.Width:match("([%d%.]+)")) or 55
        wrapSize = UDim2.new(pct / 100, 0, 0, CTRL)
    else
        -- default = CTRL_W → kotak input SAMA persis dgn trigger dropdown
        local px = type(opts.Width) == "number" and opts.Width or Layout.CTRL_W
        wrapSize = UDim2.new(0, px, 0, CTRL)
    end

    -- Input wrap: fill halus + border accent JELAS + halo glow tipis di luar
    -- kotak (feedback user: kotak input dulu nyaris tak terlihat di tema solid
    -- → tak ada pembeda area input). CLIP di wrap: teks panjang dipotong rapi
    -- di dalam kotak, tidak meluber.
    local INPUT_FILL = 0.85
    local wrap = Instance.new("Frame")
    wrap.BackgroundColor3       = Theme:BG(4)
    wrap.BackgroundTransparency = INPUT_FILL
    wrap.BorderSizePixel  = 0
    wrap.Size             = wrapSize
    wrap.Position         = UDim2.new(1, -Layout.PAD_X, 0.5, 0)
    wrap.AnchorPoint      = Vector2.new(1, 0.5)
    wrap.ClipsDescendants = true
    wrap.Parent           = card

    local wrapCorner = Instance.new("UICorner")
    wrapCorner.CornerRadius = UDim.new(0, 6)
    wrapCorner.Parent       = wrap

    -- Border = ungu accent. Idle CUKUP TERLIHAT (0.22); focus → penuh (0).
    local wrapStroke = Instance.new("UIStroke")
    wrapStroke.Color        = Theme:Accent()
    wrapStroke.Transparency = 0.22
    wrapStroke.Thickness    = 1
    wrapStroke.Parent       = wrap
    task.defer(function()
        if wrapStroke and wrapStroke.Parent then wrapStroke.Thickness = 1.0001; wrapStroke.Thickness = 1 end
    end)

    -- HALO GLOW: ring accent lembut 2px di LUAR kotak (frame transparan +4px
    -- ber-stroke sendiri — tanpa asset). Idle samar; menguat saat focus.
    -- CATATAN: halo anak wrap tapi wrap ClipsDescendants=true memotongnya →
    -- maka halo di-parent ke CARD dan posisinya disamakan dgn wrap.
    local halo = Instance.new("Frame")
    halo.Name                   = "InputHalo"
    halo.BackgroundTransparency = 1
    halo.AnchorPoint            = Vector2.new(1, 0.5)
    halo.Position               = UDim2.new(1, -Layout.PAD_X + 2, 0.5, 0)
    halo.Size                   = UDim2.new(wrapSize.X.Scale, wrapSize.X.Offset + 4, 0, CTRL + 4)
    halo.ZIndex                 = 0
    halo.Parent                 = card

    local haloCorner = Instance.new("UICorner")
    haloCorner.CornerRadius = UDim.new(0, 8)
    haloCorner.Parent       = halo

    local haloStroke = Instance.new("UIStroke")
    haloStroke.Color        = Theme:Accent()
    haloStroke.Transparency = 0.85
    haloStroke.Thickness    = 2
    haloStroke.Parent       = halo
    task.defer(function()
        if haloStroke and haloStroke.Parent then haloStroke.Thickness = 2.0001; haloStroke.Thickness = 2 end
    end)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, 9)
    pad.PaddingRight  = UDim.new(0, 9)
    pad.Parent        = wrap

    local defaultAlign = opts.Align == "Left" and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center

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
    box.TextXAlignment         = defaultAlign
    box.ClearTextOnFocus       = opts.ClearOnFocus or false
    box.Parent                 = wrap

    -- OVERFLOW: JANGAN TextTruncate "..." (teks panjang jadi "abc..." dan
    -- ketikan berikutnya TAK terlihat → user bingung sudah terketik/belum).
    -- Ganti: saat teks MELEBIHI lebar kotak, rata KANAN → yang tampil adalah
    -- EKOR teks (karakter terakhir yg diketik), overflow terpotong clip wrap
    -- di sisi kiri. Muat lagi → balik ke alignment semula.
    local function updateOverflow()
        local fits = box.TextBounds.X <= (box.AbsoluteSize.X - 2)
        box.TextXAlignment = fits and defaultAlign or Enum.TextXAlignment.Right
    end
    box:GetPropertyChangedSignal("Text"):Connect(updateOverflow)
    box:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateOverflow)
    task.defer(updateOverflow)

    box.Focused:Connect(function()
        wrapStroke.Color = Theme:Accent()
        Tween.fast(wrapStroke, { Transparency = 0 })
        Tween.fast(haloStroke, { Transparency = 0.6 })
    end)

    box.FocusLost:Connect(function()
        wrapStroke.Color = Theme:Accent()
        Tween.fast(wrapStroke, { Transparency = 0.22 })
        Tween.fast(haloStroke, { Transparency = 0.85 })
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
