-- Dropdown: single select. Menu BUKAN popup kecil di bawah trigger — terbuka
-- sebagai PANEL SAMPING dari tepi KANAN window (slide-in), tinggi mengikuti
-- window, selalu ber-search. Panel anak window (CanvasGroup) → ikut UIScale,
-- ikut drag window, dan tak butuh ScreenGui terpisah per-dropdown (dulu tiap
-- dropdown membuat 1 ScreenGui sendiri — boros & rawan tak ter-render).
Section.AddDropdown = function(self, opts)
    assert(type(opts) == "table", "AddDropdown: opts must be a table")
    local items   = opts.Options or opts.Items or {}
    local default = opts.Default  or (items[1] or "")
    local flag    = self:_registerFlag(opts.ID, default)

    -- opts.LayoutOrder (opsional): paksa urutan card di section. Berguna saat
    -- dropdown di-rebuild (mis. refresh opsi) supaya posisinya TIDAK berubah —
    -- tanpa ini _makeCard pakai #components+10 → dropdown baru lompat ke bawah.
    local card, stroke = self:_makeCard(opts.LayoutOrder)
    card.ClipsDescendants = false
    Layout.lockHeight(card, Layout.CARD_MIN_H)

    for _, c in ipairs(card:GetChildren()) do
        if c:IsA("UIPadding") then c:Destroy() end
    end

    -- LAYOUT BARU (feedback user, ala hub modern): judul KIRI + trigger di
    -- KANAN — bukan judul atas + trigger full-width bawah. Ukuran trigger =
    -- kotak input TextInput (CTRL_W × CTRL_H) supaya seragam.
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size                   = UDim2.new(1, -(Layout.CTRL_W + Layout.PAD_X * 2 + 8), 1, 0)
    title.Position               = UDim2.new(0, Layout.PAD_X, 0, 0)
    title.Text                   = opts.Title or ""
    title.Font                   = Layout.FONT_TITLE
    title.TextSize               = Layout.TITLE_SIZE
    title.TextColor3             = Theme:Text(1)
    title.TextXAlignment         = Enum.TextXAlignment.Left
    title.TextTruncate           = Enum.TextTruncate.AtEnd
    title.Parent                 = card

    local trigger = Instance.new("TextButton")
    trigger.BackgroundColor3       = Theme:BG(4)
    trigger.BackgroundTransparency = 0.85
    trigger.BorderSizePixel  = 0
    trigger.Size             = UDim2.new(0, Layout.CTRL_W, 0, Layout.CTRL_H)
    trigger.AnchorPoint      = Vector2.new(1, 0.5)
    trigger.Position         = UDim2.new(1, -Layout.PAD_X, 0.5, 0)
    trigger.Text             = ""
    trigger.AutoButtonColor  = false
    trigger.Parent           = card

    local trigCorner = Instance.new("UICorner")
    trigCorner.CornerRadius = UDim.new(0, 6)
    trigCorner.Parent       = trigger

    local trigStroke = Instance.new("UIStroke")
    trigStroke.Color          = Theme:Accent()
    trigStroke.Transparency   = 0.35
    trigStroke.Thickness      = 1
    trigStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    trigStroke.Parent         = trigger
    task.defer(function()
        if trigStroke and trigStroke.Parent then trigStroke.Thickness = 1.0001; trigStroke.Thickness = 1 end
    end)

    local trigPad = Instance.new("UIPadding")
    trigPad.PaddingLeft  = UDim.new(0, 8)
    trigPad.PaddingRight = UDim.new(0, 20)   -- ruang chevron kanan
    trigPad.Parent       = trigger

    local valLbl = Instance.new("TextLabel")
    valLbl.BackgroundTransparency = 1
    valLbl.Size                   = UDim2.new(1, 0, 1, 0)
    valLbl.Text                   = default
    valLbl.Font                   = Layout.FONT_BODY
    valLbl.TextSize               = 13
    valLbl.TextColor3             = Theme:Text(2)
    valLbl.TextXAlignment         = Enum.TextXAlignment.Left
    valLbl.TextTruncate           = Enum.TextTruncate.AtEnd
    valLbl.Parent                 = trigger

    -- Panah trigger = sprite chevron ber-tint UNGU tema (bukan teks ">").
    -- Rotasi 90 derajat saat panel terbuka (di openMenu/closeMenu).
    local arrow = Icons.new("chevron-right", 12, Theme:Accent())
    arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    arrow.Position    = UDim2.new(1, 10, 0.5, 0)   -- di zona padding kanan
    arrow.Parent      = trigger
    Theme:OnAccentChanged(function(a) arrow.ImageColor3 = a end)

    -- ── STATE ───────────────────────────────────────────────────────
    local selected = default
    local open     = false
    local allBtns  = {}
    -- Panel dibuat LAZY saat open pertama (window ancestor pasti sudah ada).
    local panel, blocker, list, searchBox
    -- Forward-declare supaya closure di ensurePanel bisa merujuknya.
    local closeMenu, buildItems

    local PANEL_TOP = 50   -- mulai di bawah titlebar (46) + jarak kecil

    local function winRoot()
        return card:FindFirstAncestorWhichIsA("CanvasGroup")
    end

    local function ensurePanel(win)
        if panel and panel.Parent then return end

        -- Backdrop dim: menutup seluruh window, klik = tutup panel.
        blocker = Instance.new("TextButton")
        blocker.Name                   = "DropPanelBlocker"
        blocker.BackgroundColor3       = Color3.new(0, 0, 0)
        blocker.BackgroundTransparency = 1
        blocker.BorderSizePixel        = 0
        blocker.AutoButtonColor        = false
        blocker.Text                   = ""
        blocker.Size                   = UDim2.new(1, 0, 1, 0)
        blocker.ZIndex                 = 40
        blocker.Visible                = false
        blocker.Parent                 = win
        blocker.MouseButton1Click:Connect(function() closeMenu() end)

        panel = Instance.new("Frame")
        panel.Name                   = "DropPanel"
        panel.BackgroundColor3       = Theme:BG(1)
        panel.BackgroundTransparency = 0.03   -- hampir solid → opsi jelas terbaca
        panel.BorderSizePixel        = 0
        panel.AnchorPoint            = Vector2.new(1, 0)
        panel.Position               = UDim2.new(1, -6, 0, PANEL_TOP)
        panel.ZIndex                 = 41
        panel.ClipsDescendants       = true
        panel.Visible                = false
        panel.Parent                 = win

        local pCorner = Instance.new("UICorner")
        pCorner.CornerRadius = UDim.new(0, 12)
        pCorner.Parent       = panel

        local pStroke = Instance.new("UIStroke")
        pStroke.Color        = Theme:Accent()
        pStroke.Transparency = 0.35
        pStroke.Thickness    = 1
        pStroke.Parent       = panel
        task.defer(function()
            if pStroke and pStroke.Parent then pStroke.Thickness = 1.0001; pStroke.Thickness = 1 end
        end)

        -- Header: judul dropdown + tombol tutup.
        local header = Instance.new("Frame")
        header.BackgroundTransparency = 1
        header.Size                   = UDim2.new(1, 0, 0, 40)
        header.ZIndex                 = 42
        header.Parent                 = panel

        local hLbl = Instance.new("TextLabel")
        hLbl.BackgroundTransparency = 1
        hLbl.Size                   = UDim2.new(1, -50, 1, 0)
        hLbl.Position               = UDim2.new(0, 14, 0, 0)
        hLbl.Text                   = opts.Title or ""
        hLbl.Font                   = Enum.Font.GothamBold
        hLbl.TextSize               = 15
        hLbl.TextColor3             = Theme:Accent()
        hLbl.TextXAlignment         = Enum.TextXAlignment.Left
        hLbl.TextTruncate           = Enum.TextTruncate.AtEnd
        hLbl.ZIndex                 = 42
        hLbl.Parent                 = header

        -- Tombol tutup = sprite "x" (glyph ✕ tak ada di Gotham → tofu di device)
        local closeBtn = Instance.new("TextButton")
        closeBtn.BackgroundTransparency = 1
        closeBtn.Size                   = UDim2.fromOffset(30, 30)
        closeBtn.Position               = UDim2.new(1, -36, 0, 5)
        closeBtn.Text                   = ""
        closeBtn.AutoButtonColor        = false
        closeBtn.ZIndex                 = 42
        closeBtn.Parent                 = header
        local closeIco = Icons.new("x", 14, Theme:Text(3))
        closeIco.AnchorPoint = Vector2.new(0.5, 0.5)
        closeIco.Position    = UDim2.new(0.5, 0, 0.5, 0)
        closeIco.ZIndex      = 42
        closeIco.Parent      = closeBtn
        closeBtn.MouseEnter:Connect(function() closeIco.ImageColor3 = Theme:Text(0) end)
        closeBtn.MouseLeave:Connect(function() closeIco.ImageColor3 = Theme:Text(3) end)
        closeBtn.MouseButton1Click:Connect(function() closeMenu() end)

        local hDiv = Instance.new("Frame")
        hDiv.BackgroundColor3 = Theme:Border(1)
        hDiv.BorderSizePixel  = 0
        hDiv.Size             = UDim2.new(1, 0, 0, 1)
        hDiv.Position         = UDim2.new(0, 0, 1, -1)
        hDiv.ZIndex           = 42
        hDiv.Parent           = header

        -- Search (selalu ada — daftar panjang gampang dicari).
        local sWrap = Instance.new("Frame")
        sWrap.BackgroundColor3       = Theme:BG(4)
        sWrap.BackgroundTransparency = 0.7
        sWrap.BorderSizePixel        = 0
        sWrap.Size                   = UDim2.new(1, -20, 0, 30)
        sWrap.Position               = UDim2.new(0, 10, 0, 47)
        sWrap.ZIndex                 = 42
        sWrap.Parent                 = panel

        local sCorner = Instance.new("UICorner")
        sCorner.CornerRadius = UDim.new(0, 7)
        sCorner.Parent       = sWrap

        local sBox = Instance.new("TextBox")
        sBox.BackgroundTransparency = 1
        sBox.BorderSizePixel        = 0
        sBox.Size                   = UDim2.new(1, -16, 1, 0)
        sBox.Position               = UDim2.new(0, 8, 0, 0)
        sBox.PlaceholderText        = "Search..."
        sBox.PlaceholderColor3      = Theme:Text(4)
        sBox.Text                   = ""
        sBox.Font                   = Enum.Font.Gotham
        sBox.TextSize               = 13
        sBox.TextColor3             = Theme:Text(0)
        sBox.ClearTextOnFocus       = false
        sBox.ZIndex                 = 42
        sBox.Parent                 = sWrap
        searchBox = sBox
        sBox:GetPropertyChangedSignal("Text"):Connect(function()
            if not open then return end
            buildItems(sBox.Text ~= "" and sBox.Text or nil)
        end)

        -- Daftar opsi (mengisi sisa tinggi panel).
        list = Instance.new("ScrollingFrame")
        list.BackgroundTransparency  = 1
        list.BorderSizePixel         = 0
        list.Size                    = UDim2.new(1, 0, 1, -84)
        list.Position                = UDim2.new(0, 0, 0, 84)
        list.CanvasSize              = UDim2.new(0, 0, 0, 0)
        list.AutomaticCanvasSize     = Enum.AutomaticSize.Y
        list.ScrollBarThickness      = 3
        list.ScrollBarImageColor3    = Theme:Accent()
        list.ZIndex                  = 42
        list.Parent                  = panel

        local listLayout = Instance.new("UIListLayout")
        listLayout.FillDirection = Enum.FillDirection.Vertical
        listLayout.SortOrder     = Enum.SortOrder.LayoutOrder
        listLayout.Parent        = list

        local listPad = Instance.new("UIPadding")
        listPad.PaddingBottom = UDim.new(0, 8)
        listPad.Parent        = list
    end

    buildItems = function(filter)
        for _, b in ipairs(allBtns) do b:Destroy() end
        allBtns = {}
        for _, item in ipairs(items) do
            if not filter or item:lower():find(filter:lower(), 1, true) then
                -- Nama panjang WRAP ke baris berikutnya (baris auto-tinggi) —
                -- BUKAN dipotong "..." (nama item game bisa sangat panjang;
                -- di daftar pilihan user HARUS bisa baca lengkap).
                local row = Instance.new("TextButton")
                row.BackgroundTransparency = 1
                row.BorderSizePixel        = 0
                row.Size                   = UDim2.new(1, 0, 0, 32)   -- minimum
                row.AutomaticSize          = Enum.AutomaticSize.Y
                row.Text                   = ""
                row.AutoButtonColor        = false
                row.ZIndex                 = 43
                row.Parent                 = list

                local pad = Instance.new("UIPadding")
                pad.PaddingLeft   = UDim.new(0, 14)
                pad.PaddingRight  = UDim.new(0, 12)
                pad.PaddingTop    = UDim.new(0, 8)
                pad.PaddingBottom = UDim.new(0, 8)
                pad.Parent        = row

                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Size                   = UDim2.new(1, -18, 0, 15)
                lbl.AutomaticSize          = Enum.AutomaticSize.Y
                lbl.Text                   = item
                lbl.Font                   = item == selected and Enum.Font.GothamBold or Enum.Font.Gotham
                lbl.TextSize               = 13
                lbl.TextColor3             = item == selected and Theme:Accent() or Theme:Text(2)
                lbl.TextXAlignment         = Enum.TextXAlignment.Left
                lbl.TextYAlignment         = Enum.TextYAlignment.Top
                lbl.TextWrapped            = true
                lbl.ZIndex                 = 43
                lbl.Parent                 = row

                if item == selected then
                    local check = Icons.new("check", 14, Theme:Accent())
                    check.Position = UDim2.new(1, -14, 0.5, -7)
                    check.ZIndex   = 43
                    check.Parent   = row
                end

                row.MouseEnter:Connect(function()
                    row.BackgroundTransparency = 0.85
                    row.BackgroundColor3       = Theme:BG(4)
                end)
                row.MouseLeave:Connect(function()
                    row.BackgroundTransparency = 1
                end)

                row.MouseButton1Click:Connect(function()
                    selected    = item
                    valLbl.Text = item
                    if flag then flag:_fire(item) end
                    if opts.Callback then pcall(opts.Callback, item) end
                    closeMenu()
                end)

                table.insert(allBtns, row)
            end
        end
    end

    closeMenu = function()
        if not open then return end
        open = false
        if panel then
            Tween.play(panel, { Position = UDim2.new(1, 20, 0, PANEL_TOP) },
                TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
            task.delay(0.16, function()
                if not open and panel then panel.Visible = false end
            end)
        end
        if blocker then
            Tween.fast(blocker, { BackgroundTransparency = 1 })
            task.delay(0.16, function()
                if not open and blocker then blocker.Visible = false end
            end)
        end
        Tween.fast(arrow, { Rotation = 0 })
        trigStroke.Color = Theme:Accent()
        Tween.fast(trigStroke, { Transparency = 0.35 })
        if searchBox then searchBox.Text = "" end
    end

    local function openMenu()
        local win = winRoot()
        if not win then return end
        ensurePanel(win)
        open = true

        -- Lebar panel mengikuti lebar window (46%), clamp supaya tetap nyaman.
        local w = math.floor(math.clamp(win.Size.X.Offset * 0.46, 200, 320))
        panel.Size     = UDim2.new(0, w, 1, -(PANEL_TOP + 8))
        panel.Position = UDim2.new(1, 20, 0, PANEL_TOP)   -- start agak keluar → slide masuk
        buildItems(nil)

        blocker.Visible = true
        Tween.fast(blocker, { BackgroundTransparency = 0.55 })
        panel.Visible = true
        Tween.play(panel, { Position = UDim2.new(1, -6, 0, PANEL_TOP) },
            TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))

        Tween.fast(arrow, { Rotation = 90 })
        trigStroke.Color = Theme:Accent()
        Tween.fast(trigStroke, { Transparency = 0 })
    end

    trigger.MouseButton1Click:Connect(function()
        if open then closeMenu() else openMenu() end
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
            selected    = v
            valLbl.Text = v
        end)
    end

    -- Panel & blocker di-parent ke WINDOW (bukan card) → saat card di-Destroy
    -- (pola rebuild dropdown di module game) keduanya WAJIB ikut dibersihkan,
    -- kalau tidak menumpuk frame tersembunyi di window tiap refresh.
    card.Destroying:Connect(function()
        if panel then pcall(function() panel:Destroy() end) end
        if blocker then pcall(function() blocker:Destroy() end) end
    end)

    table.insert(self._components, card)
    return card
end
