-- MultiDropdown: multi-select. Menu terbuka sebagai PANEL SAMPING dari tepi
-- KANAN window (slide-in) — sama seperti Dropdown — berisi baris checkbox.
-- Panel tetap terbuka saat mencentang (multi pick nyaman); tutup via backdrop,
-- tombol ✕, atau klik trigger lagi. Selalu ber-search.
Section.AddMultiDropdown = function(self, opts)
    assert(type(opts) == "table", "AddMultiDropdown: opts must be a table")
    local items    = opts.Options or opts.Items or {}
    local defaults = opts.Default or {}
    local flag     = self:_registerFlag(opts.ID, defaults)

    local card, stroke = self:_makeCard()
    card.ClipsDescendants = false
    Layout.lockHeight(card, Layout.CARD_MIN_H)

    for _, c in ipairs(card:GetChildren()) do
        if c:IsA("UIPadding") then c:Destroy() end
    end

    -- LAYOUT BARU (feedback user, ala hub modern): judul KIRI + trigger di
    -- KANAN — ukuran trigger = kotak input TextInput (CTRL_W × CTRL_H).
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
    trigger.AutomaticSize    = Enum.AutomaticSize.None
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
    trigPad.PaddingLeft   = UDim.new(0, 8)
    trigPad.PaddingRight  = UDim.new(0, 20)   -- ruang chevron kanan
    trigPad.Parent        = trigger

    -- Summary label: satu baris ringkas
    -- Format: "Select options..." | "Item A" | "Item A, Item B" | "Item A, +2 more"
    local summaryLbl = Instance.new("TextLabel")
    summaryLbl.BackgroundTransparency = 1
    summaryLbl.Size                   = UDim2.new(1, 0, 1, 0)
    summaryLbl.Text                   = "Select options..."
    summaryLbl.Font                   = Enum.Font.Gotham
    summaryLbl.TextSize               = 13
    summaryLbl.TextColor3             = Theme:Text(4)
    summaryLbl.TextXAlignment         = Enum.TextXAlignment.Left
    summaryLbl.TextTruncate           = Enum.TextTruncate.AtEnd
    summaryLbl.Parent                 = trigger

    -- Panah trigger = sprite chevron ber-tint UNGU tema (bukan teks ">").
    -- Rotasi 90 derajat saat panel terbuka (di openMenu/closeMenu).
    local arrow = Icons.new("chevron-right", 12, Theme:Accent())
    arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    arrow.Position    = UDim2.new(1, 10, 0.5, 0)   -- di zona padding kanan
    arrow.Parent      = trigger
    Theme:OnAccentChanged(function(a) arrow.ImageColor3 = a end)

    -- ── STATE ───────────────────────────────────────────────────────
    local selected = {}
    for _, v in ipairs(defaults) do selected[v] = true end
    local open    = false
    local allRows = {}
    local panel, blocker, list, searchBox, countLbl, selectAllBtn, selectAllLbl
    local closeMenu, buildRows, refreshSelectAll   -- forward-declare utk closure ensurePanel

    local PANEL_TOP = 50

    local function winRoot()
        return card:FindFirstAncestorWhichIsA("CanvasGroup")
    end

    -- Indeks asli tiap item (utk jaga urutan relatif dalam tiap grup saat sort).
    local _origIndex = {}
    for i, item in ipairs(items) do _origIndex[item] = i end

    -- Urutan TAMPIL: item TERPILIH di ATAS (urut asli), lalu yg belum (urut asli).
    -- Dipakai buildRows supaya yg dicentang naik ke atas; begitu di-uncheck ia
    -- kembali ke barisan aslinya (karena grup "belum" tetap urut _origIndex).
    -- Filter search diterapkan dulu agar hanya yg cocok yang di-list.
    local function orderedItems(filter)
        local picked, rest = {}, {}
        for _, item in ipairs(items) do
            if not filter or item:lower():find(filter:lower(), 1, true) then
                if selected[item] then table.insert(picked, item)
                else table.insert(rest, item) end
            end
        end
        local out = {}
        for _, v in ipairs(picked) do out[#out + 1] = v end
        for _, v in ipairs(rest)   do out[#out + 1] = v end
        return out
    end

    local function refreshSummary()
        local activeList = {}
        for _, item in ipairs(items) do
            if selected[item] then table.insert(activeList, item) end
        end
        local count = #activeList
        if count == 0 then
            summaryLbl.Text       = "Select options..."
            summaryLbl.TextColor3 = Theme:Text(4)
        elseif count == 1 then
            summaryLbl.Text       = activeList[1]
            summaryLbl.TextColor3 = Theme:Accent()
        elseif count == 2 then
            summaryLbl.Text       = activeList[1] .. ", " .. activeList[2]
            summaryLbl.TextColor3 = Theme:Accent()
        else
            summaryLbl.Text       = activeList[1] .. ", " .. activeList[2] .. ", +" .. (count - 2) .. " more"
            summaryLbl.TextColor3 = Theme:Accent()
        end
        if countLbl then
            countLbl.Text = count > 0 and (count .. " selected") or ""
        end
    end

    -- Perbarui label tombol aksi: "Deselect All" kalau SEMUA item tampil (lolos
    -- filter) sudah terpilih; else "Select All". filter = teks search saat ini.
    refreshSelectAll = function(filter)
        if not selectAllLbl then return end
        local anyVisible, allOn = false, true
        for _, item in ipairs(items) do
            if not filter or item:lower():find(filter:lower(), 1, true) then
                anyVisible = true
                if not selected[item] then allOn = false end
            end
        end
        selectAllLbl.Text = (anyVisible and allOn) and "Deselect All" or "Select All"
    end

    local function ensurePanel(win)
        if panel and panel.Parent then return end

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
        panel.BackgroundTransparency = 0.03
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

        -- Header: judul + hitungan terpilih + tombol tutup.
        local header = Instance.new("Frame")
        header.BackgroundTransparency = 1
        header.Size                   = UDim2.new(1, 0, 0, 40)
        header.ZIndex                 = 42
        header.Parent                 = panel

        local hLbl = Instance.new("TextLabel")
        hLbl.BackgroundTransparency = 1
        hLbl.Size                   = UDim2.new(1, -50, 0, 22)
        hLbl.Position               = UDim2.new(0, 14, 0, 3)
        hLbl.Text                   = opts.Title or ""
        hLbl.Font                   = Enum.Font.GothamBold
        hLbl.TextSize               = 15
        hLbl.TextColor3             = Theme:Accent()
        hLbl.TextXAlignment         = Enum.TextXAlignment.Left
        hLbl.TextTruncate           = Enum.TextTruncate.AtEnd
        hLbl.ZIndex                 = 42
        hLbl.Parent                 = header

        countLbl = Instance.new("TextLabel")
        countLbl.BackgroundTransparency = 1
        countLbl.Size                   = UDim2.new(1, -50, 0, 13)
        countLbl.Position               = UDim2.new(0, 14, 0, 24)
        countLbl.Text                   = ""
        countLbl.Font                   = Enum.Font.Gotham
        countLbl.TextSize               = 12
        countLbl.TextColor3             = Theme:Text(3)
        countLbl.TextXAlignment         = Enum.TextXAlignment.Left
        countLbl.ZIndex                 = 42
        countLbl.Parent                 = header

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

        -- Search
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
            local f = sBox.Text ~= "" and sBox.Text or nil
            buildRows(f)
            refreshSelectAll(f)
        end)

        -- ── Aksi "Select All / Deselect All" (utk daftar yg SEDANG tampil) ──
        -- Bekerja pada item yg lolos filter search saat ini: kalau semua yg
        -- tampil sudah terpilih → jadi "Deselect All"; else "Select All".
        selectAllBtn = Instance.new("TextButton")
        selectAllBtn.BackgroundColor3       = Theme:BG(4)
        selectAllBtn.BackgroundTransparency = 0.7
        selectAllBtn.BorderSizePixel        = 0
        selectAllBtn.Size                   = UDim2.new(1, -20, 0, 26)
        selectAllBtn.Position               = UDim2.new(0, 10, 0, 81)
        selectAllBtn.Text                   = ""
        selectAllBtn.AutoButtonColor        = false
        selectAllBtn.ZIndex                 = 42
        selectAllBtn.Parent                 = panel

        local saCorner = Instance.new("UICorner")
        saCorner.CornerRadius = UDim.new(0, 7)
        saCorner.Parent       = selectAllBtn

        local saStroke = Instance.new("UIStroke")
        saStroke.Color        = Theme:Accent()
        saStroke.Transparency = 0.5
        saStroke.Thickness    = 1
        saStroke.Parent       = selectAllBtn

        selectAllLbl = Instance.new("TextLabel")
        selectAllLbl.BackgroundTransparency = 1
        selectAllLbl.Size                   = UDim2.new(1, 0, 1, 0)
        selectAllLbl.Text                   = "Select All"
        selectAllLbl.Font                   = Enum.Font.GothamMedium
        selectAllLbl.TextSize               = 12
        selectAllLbl.TextColor3             = Theme:Accent()
        selectAllLbl.ZIndex                 = 42
        selectAllLbl.Parent                 = selectAllBtn

        selectAllBtn.MouseEnter:Connect(function() selectAllBtn.BackgroundTransparency = 0.5 end)
        selectAllBtn.MouseLeave:Connect(function() selectAllBtn.BackgroundTransparency = 0.7 end)

        selectAllBtn.MouseButton1Click:Connect(function()
            local f = searchBox and searchBox.Text ~= "" and searchBox.Text or nil
            -- Tentukan aksi: kalau SEMUA yg tampil sudah terpilih → un-select semua;
            -- else pilih semua yg tampil.
            local visible = {}
            for _, item in ipairs(items) do
                if not f or item:lower():find(f:lower(), 1, true) then
                    visible[#visible + 1] = item
                end
            end
            local allOn = (#visible > 0)
            for _, item in ipairs(visible) do
                if not selected[item] then allOn = false; break end
            end
            local target = not allOn
            for _, item in ipairs(visible) do selected[item] = target end

            refreshSummary()
            refreshSelectAll(f)
            local vals = {}
            for k, v in pairs(selected) do if v then table.insert(vals, k) end end
            if flag then flag:_fire(vals) end
            if opts.Callback then pcall(opts.Callback, vals) end
            buildRows(f)   -- reorder: terpilih naik ke atas
        end)

        list = Instance.new("ScrollingFrame")
        list.BackgroundTransparency  = 1
        list.BorderSizePixel         = 0
        list.Size                    = UDim2.new(1, 0, 1, -116)
        list.Position                = UDim2.new(0, 0, 0, 116)
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

    buildRows = function(filter)
        for _, r in ipairs(allRows) do r:Destroy() end
        allRows = {}
        local order = 0
        for _, item in ipairs(orderedItems(filter)) do
            do
                order = order + 1
                -- Nama panjang WRAP ke baris berikutnya (baris auto-tinggi) —
                -- BUKAN dipotong "..." (user harus bisa baca nama item lengkap).
                local row = Instance.new("TextButton")
                row.BackgroundTransparency = 1
                row.BorderSizePixel        = 0
                row.Size                   = UDim2.new(1, 0, 0, 32)   -- minimum
                row.AutomaticSize          = Enum.AutomaticSize.Y
                row.LayoutOrder            = order   -- jaga urutan terpilih-di-atas
                row.Text                   = ""
                row.AutoButtonColor        = false
                row.ZIndex                 = 43
                row.Parent                 = list

                local pad = Instance.new("UIPadding")
                pad.PaddingLeft   = UDim.new(0, 12)
                pad.PaddingRight  = UDim.new(0, 12)
                pad.PaddingTop    = UDim.new(0, 8)
                pad.PaddingBottom = UDim.new(0, 8)
                pad.Parent        = row

                -- Checkbox 16px senada komponen Checkbox.
                local check = Instance.new("Frame")
                check.Size             = UDim2.fromOffset(16, 16)
                check.Position         = UDim2.new(0, 0, 0.5, -8)
                check.BackgroundColor3 = selected[item] and Theme:Accent() or Theme:BG(1)
                check.BorderSizePixel  = 0
                check.ZIndex           = 43
                check.Parent           = row

                local checkCorner = Instance.new("UICorner")
                checkCorner.CornerRadius = UDim.new(0, 4)
                checkCorner.Parent       = check

                local checkStroke = Instance.new("UIStroke")
                checkStroke.Color     = selected[item] and Theme:Accent() or Theme:Border(1)
                checkStroke.Thickness = 1
                checkStroke.Parent    = check

                -- Checkmark = sprite (glyph ✓ tofu-risk); toggle via
                -- ImageTransparency (0 = tampil, 1 = sembunyi).
                local checkMark = Icons.new("check", 12, Color3.new(1, 1, 1))
                checkMark.AnchorPoint       = Vector2.new(0.5, 0.5)
                checkMark.Position          = UDim2.new(0.5, 0, 0.5, 0)
                checkMark.ImageTransparency = selected[item] and 0 or 1
                checkMark.ZIndex            = 44
                checkMark.Parent            = check

                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Size                   = UDim2.new(1, -26, 0, 15)
                lbl.AutomaticSize          = Enum.AutomaticSize.Y
                lbl.Position               = UDim2.new(0, 24, 0, 0)
                lbl.Text                   = item
                lbl.Font                   = Enum.Font.Gotham
                lbl.TextSize               = 13
                lbl.TextColor3             = selected[item] and Theme:Accent() or Theme:Text(2)
                lbl.TextXAlignment         = Enum.TextXAlignment.Left
                lbl.TextYAlignment         = Enum.TextYAlignment.Top
                lbl.TextWrapped            = true
                lbl.ZIndex                 = 43
                lbl.Parent                 = row

                row.MouseEnter:Connect(function()
                    row.BackgroundTransparency = 0.85
                    row.BackgroundColor3       = Theme:BG(4)
                end)
                row.MouseLeave:Connect(function()
                    row.BackgroundTransparency = 1
                end)

                row.MouseButton1Click:Connect(function()
                    selected[item] = not selected[item]
                    -- Update visual baris ini dulu (feedback instan), lalu REBUILD
                    -- daftar dgn filter yg sama → baris terpilih LANGSUNG naik ke
                    -- atas / yg di-uncheck kembali ke barisan aslinya (live reorder).
                    check.BackgroundColor3      = selected[item] and Theme:Accent() or Theme:BG(1)
                    checkStroke.Color           = selected[item] and Theme:Accent() or Theme:Border(1)
                    checkMark.ImageTransparency = selected[item] and 0 or 1
                    lbl.TextColor3              = selected[item] and Theme:Accent() or Theme:Text(2)
                    refreshSummary()
                    if refreshSelectAll then refreshSelectAll(filter) end
                    local vals = {}
                    for k, v in pairs(selected) do if v then table.insert(vals, k) end end
                    if flag then flag:_fire(vals) end
                    if opts.Callback then pcall(opts.Callback, vals) end
                    buildRows(filter)   -- reorder: terpilih naik ke atas
                end)

                table.insert(allRows, row)
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

        local w = math.floor(math.clamp(win.Size.X.Offset * 0.46, 200, 320))
        panel.Size     = UDim2.new(0, w, 1, -(PANEL_TOP + 8))
        panel.Position = UDim2.new(1, 20, 0, PANEL_TOP)
        buildRows(nil)
        refreshSummary()
        refreshSelectAll(nil)

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

    refreshSummary()

    card.MouseEnter:Connect(function()
        Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
        stroke.Color = Theme:Border(1)
    end)
    card.MouseLeave:Connect(function()
        Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
        stroke.Color = Theme:Border(0)
    end)

    -- VISUAL SYNC saat config restore: Flags[ID]:SetAndFire(list) → OnChanged
    -- ini me-rebuild state `selected` dari list, refresh summary, & (kalau panel
    -- sedang terbuka) rebuild baris agar checkbox ikut tercentang. TIDAK
    -- memanggil opts.Callback (SetAndFire hanya Fire signal, bukan _fire dari
    -- interaksi) → aman, tak rekursi & tak double-apply ke loop fitur.
    if flag then
        flag:OnChanged(function(v)
            if type(v) ~= "table" then return end
            selected = {}
            for _, item in ipairs(v) do selected[item] = true end
            refreshSummary()
            if refreshSelectAll then refreshSelectAll(nil) end
            if open then buildRows(nil) end
        end)
    end

    -- Panel & blocker di-parent ke WINDOW (bukan card) → saat card di-Destroy
    -- (pola rebuild dropdown di module game, mis. Refresh Items) keduanya WAJIB
    -- ikut dibersihkan agar tidak menumpuk frame tersembunyi di window.
    card.Destroying:Connect(function()
        if panel then pcall(function() panel:Destroy() end) end
        if blocker then pcall(function() blocker:Destroy() end) end
    end)

    table.insert(self._components, card)
    return card
end
