-- Window: matches mockup.html design exactly
Window = {}
Window.__index = Window

local UserInputService = game:GetService("UserInputService")

function Window.new(opts, screenGui, flags)
    local self = setmetatable({}, Window)
    self._flags = flags; self._tabs = {}; self._activeTab = nil; self._opts = opts

    local accent = opts.Accent or Theme:Accent()
    Theme:SetAccent(accent)

    -- ROOT WINDOW — transparent shell. Border drawn by a separate stroke frame.
    -- ClipsDescendants is FALSE because Roblox clip is rectangular (ignores UICorner).
    -- Rounded corners come from titlebar (top) + body (bottom), each with its own UICorner
    -- and a "leg" that extends past the join so the inner corners are flush.
    local win = Instance.new("CanvasGroup")
    win.Name = "MuvaWindow"
    win.BackgroundTransparency = 1
    win.BorderSizePixel  = 0
    win.Size        = UDim2.fromOffset(opts.Size and opts.Size.X or 580, opts.Size and opts.Size.Y or 400)
    win.Position    = UDim2.new(0.5, 0, 0.5, 0)
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.ClipsDescendants = false
    win.GroupTransparency = 1
    win.Parent   = screenGui
    self._win    = win

    -- ── RESPONSIVE SCALE & FIT ──────────────────────────────────────
    -- Satu UIScale di root window agar SELURUH UI mengecil proporsional di
    -- layar kecil (Android) tanpa mengubah layout. Dihitung LIVE dari
    -- ViewportSize — bukan deteksi platform sekali jalan — supaya PC yang
    -- fullscreen / minimize / resize ikut re-fit dan tidak salah deteksi.
    self._baseSize = Vector2.new(
        opts.Size and opts.Size.X or 580,
        opts.Size and opts.Size.Y or 400
    )

    local uiScale = Instance.new("UIScale")
    uiScale.Scale  = 1
    uiScale.Parent = win
    self._uiScale  = uiScale

    self._fitWindow = function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        if vp.X <= 0 or vp.Y <= 0 then return end

        local base = self._baseSize
        -- Sisakan margin 6% tiap sisi → window tidak mepet tepi layar HP.
        local maxW = vp.X * 0.94
        local maxH = vp.Y * 0.94

        -- Skala agar window muat di viewport; jangan pernah memperbesar di
        -- atas 1 (PC res tinggi tetap ukuran normal), batas bawah 0.5 supaya
        -- tetap terbaca.
        local scale = math.min(1, maxW / base.X, maxH / base.Y)
        scale = math.max(0.5, scale)
        uiScale.Scale = scale

        -- Responsif: layar sempit (HP portrait) → sidebar jadi DRAWER (overlay),
        -- content lebar penuh. Ambang: lebar viewport efektif < 560 (setelah scale).
        local narrow = (vp.X / scale) < 560
        if self._setSidebarMode then self:_setSidebarMode(narrow) end

        -- Saat maximized, Size memakai Scale (1,1) bukan Offset → lewati clamp
        -- offset agar window tidak ikut menyusut jadi 0.
        if self._maximized then return end

        -- Clamp ukuran window agar tak melebihi layar — TAPI JANGAN PERNAH lebih
        -- kecil dari base size (cegah bug window menyusut jadi 1×1 saat viewport
        -- belum siap di frame pertama). Lantai = base, plafon = layar/scale.
        local curX = win.Size.X.Offset
        local curY = win.Size.Y.Offset
        local capX = math.max(base.X, math.floor(maxW / scale))
        local capY = math.max(base.Y, math.floor(maxH / scale))
        local clampedX = math.min(curX, capX)
        local clampedY = math.min(curY, capY)
        -- jangan biarkan menyusut di bawah base
        clampedX = math.max(clampedX, base.X)
        clampedY = math.max(clampedY, base.Y)
        if clampedX ~= curX or clampedY ~= curY then
            win.Size = UDim2.fromOffset(clampedX, clampedY)
        end
    end

    self._fitWindow()
    task.spawn(function()
        local cam = workspace.CurrentCamera
        if cam then
            self._viewportConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(self._fitWindow)
        end
    end)

    -- TITLEBAR — UICorner 12. Its rounded BOTTOM corners are hidden because the body
    -- (drawn after, sitting at y=34) overlaps the lower 12px of the titlebar.
    -- titlebar children still use the visible 46px height via an inner content frame.
    -- TEMA SOLID PENUH (feedback user): konsep "glass" lama (body tembus 25%)
    -- DIBATALKAN — setelah card/sidebar jadi panel solid, body yang masih
    -- transparan membuat tampilan setengah-setengah (celah antar card tembus
    -- ke dunia game, elemen pekat). Kini body = permukaan solid PALING GELAP;
    -- hierarki: body (tergelap) < card/sidebar (BG2) < hover (BG3).
    local WIN_PANEL_TRANS = 0   -- solid
    -- getgenv hanya ada di executor; di Studio nil → guard. Share nilai panel
    -- transparansi ke komponen lain via getgenv kalau tersedia (kompat).
    pcall(function() if getgenv then getgenv().MuvaUI_PanelTrans = WIN_PANEL_TRANS end end)

    -- TITLEBAR TRANSPARAN: hanya host title/subtitle/tombol. Glass disediakan oleh
    -- BODY yg kini menutupi SELURUH window (1 panel rounded penuh) → tak ada seam
    -- titlebar↔body, tak ada celah sudut yg menembus skybox, tak ada penumpukan
    -- transparansi. Pemisah visual titlebar↔konten = garis divider di bawah.
    local titlebar = Instance.new("Frame")
    titlebar.Name = "Titlebar"
    titlebar.BackgroundTransparency = 1
    titlebar.BorderSizePixel  = 0
    titlebar.Size     = UDim2.new(1, 0, 0, 46)
    titlebar.Position = UDim2.new(0, 0, 0, 0)
    titlebar.ZIndex   = 2   -- di atas body glass
    titlebar.Parent = win
    self._titlebar = titlebar

    local tbDivider = Instance.new("Frame")
    tbDivider.BackgroundColor3 = Color.fromHex("#272b37")
    tbDivider.BorderSizePixel  = 0
    tbDivider.Size = UDim2.new(1, 0, 0, 1)
    tbDivider.Position = UDim2.new(0, 0, 1, -1)
    tbDivider.Parent = titlebar

    -- LEFT: Hamburger + Title stack (title bold, subtitle small below)
    local tbLeft = Instance.new("Frame")
    tbLeft.BackgroundTransparency = 1
    tbLeft.Size     = UDim2.new(0.65, 0, 1, 0)
    tbLeft.Position = UDim2.new(0, 0, 0, 0)
    tbLeft.Parent   = titlebar

    local tbLeftLayout = Instance.new("UIListLayout")
    tbLeftLayout.FillDirection     = Enum.FillDirection.Horizontal
    tbLeftLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tbLeftLayout.Padding = UDim.new(0, 10)
    tbLeftLayout.Parent  = tbLeft

    local tbLeftPad = Instance.new("UIPadding")
    tbLeftPad.PaddingLeft = UDim.new(0, 14)
    tbLeftPad.Parent      = tbLeft

    -- Hamburger menu (TextButton agar bisa diklik utk buka/tutup drawer sidebar
    -- saat layar sempit). Ikon = sprite "menu" (glyph "≡" tofu-risk di Gotham).
    local hamburger = Instance.new("TextButton")
    hamburger.BackgroundTransparency = 1
    hamburger.AutoButtonColor = false
    hamburger.Size       = UDim2.fromOffset(22, 46)
    hamburger.Text       = ""
    hamburger.Parent = tbLeft
    self._logo = hamburger
    local hamIco = Icons.new("menu", 18, Color.fromHex("#7a8194"))
    hamIco.AnchorPoint = Vector2.new(0.5, 0.5)
    hamIco.Position    = UDim2.new(0.5, 0, 0.5, 0)
    hamIco.Parent      = hamburger
    hamburger.MouseEnter:Connect(function() hamIco.ImageColor3 = Theme:Accent() end)
    hamburger.MouseLeave:Connect(function() hamIco.ImageColor3 = Color.fromHex("#7a8194") end)
    hamburger.MouseButton1Click:Connect(function()
        if self._toggleDrawer then self:_toggleDrawer() end
    end)

    -- Title + subtitle stacked vertically
    local titleStack = Instance.new("Frame")
    titleStack.BackgroundTransparency = 1
    titleStack.Size         = UDim2.fromOffset(0, 46)
    titleStack.AutomaticSize = Enum.AutomaticSize.X
    titleStack.Parent       = tbLeft

    local titleStackLayout = Instance.new("UIListLayout")
    titleStackLayout.FillDirection       = Enum.FillDirection.Vertical
    titleStackLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    titleStackLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    titleStackLayout.Padding = UDim.new(0, 1)
    titleStackLayout.Parent  = titleStack

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size          = UDim2.fromOffset(0, 20)
    titleLabel.AutomaticSize = Enum.AutomaticSize.X
    titleLabel.Text          = opts.Title or "MuvaUI"
    titleLabel.Font          = Enum.Font.GothamBold
    titleLabel.TextSize      = 16
    titleLabel.TextColor3    = Color.fromHex("#f0f0f0")
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent        = titleStack

    if opts.SubTitle then
        local subLabel = Instance.new("TextLabel")
        subLabel.BackgroundTransparency = 1
        subLabel.Size          = UDim2.fromOffset(0, 14)
        subLabel.AutomaticSize = Enum.AutomaticSize.X
        subLabel.Text          = opts.SubTitle
        subLabel.Font          = Enum.Font.Gotham
        subLabel.TextSize      = 12
        subLabel.TextColor3    = Color.fromHex("#f0f0f0")   -- sama dgn judul (was #666 — terlalu blend)
        subLabel.TextXAlignment = Enum.TextXAlignment.Left
        subLabel.Parent        = titleStack
    end

    -- RIGHT: Version badge + Controls
    local tbRight = Instance.new("Frame")
    tbRight.BackgroundTransparency = 1
    tbRight.Size        = UDim2.fromOffset(0, 46)
    tbRight.AutomaticSize = Enum.AutomaticSize.X
    tbRight.Position    = UDim2.new(1, -12, 0, 0)
    tbRight.AnchorPoint = Vector2.new(1, 0)
    tbRight.Parent      = titlebar

    local tbRightLayout = Instance.new("UIListLayout")
    tbRightLayout.FillDirection       = Enum.FillDirection.Horizontal
    tbRightLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    tbRightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    tbRightLayout.Padding = UDim.new(0, 6)
    tbRightLayout.Parent  = tbRight

    -- Version badge DIHAPUS TOTAL (tidak dipakai lagi). _badgeLbl tetap nil supaya
    -- pemanggil yg sempat mereferensikannya tidak error.
    self._badgeLbl = nil

    -- Control buttons
    local ctrlFrame = Instance.new("Frame")
    ctrlFrame.BackgroundTransparency = 1
    ctrlFrame.Size        = UDim2.fromOffset(0, 46)
    ctrlFrame.AutomaticSize = Enum.AutomaticSize.X
    ctrlFrame.Parent      = tbRight

    local ctrlLayout = Instance.new("UIListLayout")
    ctrlLayout.FillDirection     = Enum.FillDirection.Horizontal
    ctrlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ctrlLayout.Padding = UDim.new(0, 4)
    ctrlLayout.Parent  = ctrlFrame

    local btnMin = self:_makeCtrlBtn(ctrlFrame, "_", Color.fromHex("#2a2a2e"), Color.fromHex("#aaaaaa"))

    local btnMax = self:_makeCtrlBtn(ctrlFrame, "[  ]", Color.fromHex("#2a2a2e"), Color.fromHex("#aaaaaa"))
    btnMax.TextSize = 11
    btnMax.Size     = UDim2.fromOffset(36, 28)
    self._btnMax = btnMax

    local btnClose = self:_makeCtrlBtn(ctrlFrame, "X", Color.fromHex("#c0392b"), Color.fromHex("#ffffff"))

    -- Klik tombol titlebar DIBATALKAN kalau barusan drag (self._suppressClick) →
    -- cegah min/max/close ter-trigger tak sengaja saat user cuma menggeser window
    -- melewati area tombol. (di-set di _buildDrag saat drag lewat dead-zone)
    btnMin.MouseButton1Click:Connect(function()   if self._suppressClick then return end self:_minimize() end)
    btnMax.MouseButton1Click:Connect(function()   if self._suppressClick then return end self:_toggleMaximize() end)
    btnClose.MouseButton1Click:Connect(function() if self._suppressClick then return end self:_close() end)

    -- BODY — panel SOLID tunggal menutupi SELURUH window (y=0..bawah);
    -- titlebar transparan duduk di atasnya. UICorner 12 membulatkan keempat
    -- sudut window sekaligus → tak ada seam/celah.
    -- PENTING: warna GELAP di-set LANGSUNG di BackgroundColor3 — JANGAN pakai
    -- trik "base putih + UIGradient gelap" (gradient mengalikan warna): di
    -- sebagian executor UIGradient dlm CanvasGroup TIDAK dirender → body
    -- tampil PUTIH polos (bug nyata di device user). Body lebih gelap dari
    -- card (BG2 #13151c) supaya card/sidebar menonjol sebagai panel.
    local body = Instance.new("Frame")
    body.BackgroundColor3 = Color.fromHex("#0b0d12")
    body.BackgroundTransparency = WIN_PANEL_TRANS
    body.BorderSizePixel  = 0
    body.Position         = UDim2.new(0, 0, 0, 0)
    body.Size             = UDim2.new(1, 0, 1, 0)
    body.ClipsDescendants = false
    body.ZIndex           = 0
    body.Parent           = win

    -- Gradient depth OPSIONAL & fail-safe: putih (atas, = warna base persis)
    -- → abu terang (bawah, sedikit menggelapkan). Kalau gradient gagal render
    -- (executor tertentu), body tetap #0b0d12 yang benar.
    local bodyGrad = Instance.new("UIGradient")
    bodyGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color.fromHex("#c4c8d4"))
    bodyGrad.Rotation = 90
    bodyGrad.Parent = body

    local bodyCorner = Instance.new("UICorner")
    bodyCorner.CornerRadius = UDim.new(0, 12)
    bodyCorner.Parent       = body

    -- ── INPUT CATCHER (cegah click tembus ke belakang window) ───────
    -- Frame TIDAK menelan klik di Roblox → klik di area kosong window (body,
    -- content kosong, sidebar) lolos ke GUI/objek 3D di belakang. Solusi: SATU
    -- TextButton transparan penuh menutupi seluruh window di lapisan PALING BAWAH.
    -- TextButton menelan MouseButton1/Touch di area-nya → tidak ada klik yg tembus.
    -- Konten asli (tombol/card) ber-ZIndex lebih tinggi → tetap menerima klik di atasnya.
    -- CATATAN: JANGAN pakai Modal=true — di mobile/console itu memaksa kursor muncul &
    -- mengunci gerak kamera/karakter selama tombol hidup. TextButton biasa sudah cukup
    -- menelan klik. AutoButtonColor=false + transparan → tak terlihat, tak ganggu visual.
    local catcher = Instance.new("TextButton")
    catcher.Name                   = "InputCatcher"
    catcher.BackgroundTransparency = 1
    catcher.BorderSizePixel        = 0
    catcher.AutoButtonColor        = false
    catcher.Text                   = ""
    catcher.Size                   = UDim2.new(1, 0, 1, 0)
    catcher.Position               = UDim2.new(0, 0, 0, 0)
    catcher.ZIndex                 = 0
    catcher.Parent                 = body

    local bodyInner = body

    -- SIDEBAR = SATU PANEL GELAP utuh (feedback user, ala hub modern):
    -- fill SAMA dgn card/separator (BG(2) trans 0.15) → seluruh kolom sidebar
    -- terbaca sebagai blok sendiri yang kontras dgn area konten — BUKAN
    -- per-tombol tab. (Filosofi lama "sidebar transparan biar glass seragam"
    -- DIBATALKAN bersama fill card.) Bonus: di mode drawer, panel solid ini
    -- menutup konten di belakangnya dgn benar saat sidebar overlay.
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.BackgroundColor3       = Theme:BG(2)
    sidebar.BackgroundTransparency = 0.15
    sidebar.BorderSizePixel  = 0
    sidebar.Position         = UDim2.new(0, 0, 0, 46)   -- mulai di bawah header titlebar
    sidebar.Size             = UDim2.new(0, 160, 1, -46)
    sidebar.ClipsDescendants = false
    sidebar.Parent           = bodyInner
    self._sidebar            = sidebar

    local sidebarCorner = Instance.new("UICorner")
    sidebarCorner.CornerRadius = UDim.new(0, 12)
    sidebarCorner.Parent       = sidebar

    -- Right leg & Top leg: dulu mengisi sudut agar persegi & SOLID. Dgn sidebar
    -- transparan seragam, leg solid akan menumpuk transparansi (sudut jadi lebih
    -- pekat → tak seragam). Maka legs dibuat INVISIBLE; sudut membulat sidebar
    -- dibiarkan (tertutup titlebar/divider di sisi yg perlu persegi).
    local sbRightLeg = Instance.new("Frame")
    sbRightLeg.BackgroundTransparency = 1
    sbRightLeg.BorderSizePixel  = 0
    sbRightLeg.Size             = UDim2.new(0, 12, 1, 0)
    sbRightLeg.Position         = UDim2.new(1, -12, 0, 0)
    sbRightLeg.ZIndex           = 0
    sbRightLeg.Parent           = sidebar

    local sbTopLeg = Instance.new("Frame")
    sbTopLeg.BackgroundTransparency = 1
    sbTopLeg.BorderSizePixel  = 0
    sbTopLeg.Size             = UDim2.new(1, 0, 0, 12)
    sbTopLeg.Position         = UDim2.new(0, 0, 0, 0)
    sbTopLeg.ZIndex           = 0
    sbTopLeg.Parent           = sidebar

    -- Sidebar right divider (mulai di bawah header titlebar)
    local sbDivider = Instance.new("Frame")
    sbDivider.BackgroundColor3 = Color.fromHex("#1c1f29")
    sbDivider.BorderSizePixel  = 0
    sbDivider.Size     = UDim2.new(0, 1, 1, -46)
    sbDivider.Position = UDim2.new(0, 160, 0, 46)
    sbDivider.ZIndex   = 2
    sbDivider.Parent   = bodyInner

    -- Search bar: top, absolute, 36px
    local searchOuter = Instance.new("Frame")
    searchOuter.BackgroundTransparency = 1
    searchOuter.Size     = UDim2.new(1, 0, 0, 40)
    searchOuter.Position = UDim2.new(0, 0, 0, 0)
    searchOuter.Parent   = sidebar

    local searchOuterPad = Instance.new("UIPadding")
    searchOuterPad.PaddingLeft   = UDim.new(0, 8)
    searchOuterPad.PaddingRight  = UDim.new(0, 8)
    searchOuterPad.PaddingTop    = UDim.new(0, 7)
    searchOuterPad.PaddingBottom = UDim.new(0, 5)
    searchOuterPad.Parent = searchOuter

    -- Search box: glass-transparan (BUKAN fill solid #161922 yg jadi blok abu).
    local searchWrap = Instance.new("Frame")
    searchWrap.BackgroundColor3       = Color.fromHex("#272b37")
    searchWrap.BackgroundTransparency = 0.88
    searchWrap.BorderSizePixel  = 0
    searchWrap.Size   = UDim2.new(1, 0, 1, 0)
    searchWrap.Parent = searchOuter

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 7)
    searchCorner.Parent = searchWrap

    -- Border = ungu accent (senada Button/input). Idle transparan 0.4.
    local searchStroke = Instance.new("UIStroke")
    searchStroke.Color        = Theme:Accent()
    searchStroke.Transparency = 0.4
    searchStroke.Thickness    = 1
    searchStroke.Parent       = searchWrap
    task.defer(function()
        if searchStroke and searchStroke.Parent then searchStroke.Thickness = 1.0001; searchStroke.Thickness = 1 end
    end)

    local searchRowLayout = Instance.new("UIListLayout")
    searchRowLayout.FillDirection     = Enum.FillDirection.Horizontal
    searchRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    searchRowLayout.Padding = UDim.new(0, 5)
    searchRowLayout.Parent  = searchWrap

    local searchPad = Instance.new("UIPadding")
    searchPad.PaddingLeft  = UDim.new(0, 7)
    searchPad.PaddingRight = UDim.new(0, 7)
    searchPad.Parent = searchWrap

    -- Ikon search = sprite Lucide (bukan emoji 🔍 yg dirender font warna sistem)
    local searchIcon = Icons.new("search", 14, Color.fromHex("#666666"))
    searchIcon.Parent = searchWrap

    local searchBox = Instance.new("TextBox")
    searchBox.BackgroundTransparency = 1
    searchBox.BorderSizePixel   = 0
    searchBox.Size = UDim2.new(1, -20, 1, 0)
    searchBox.PlaceholderText   = "Search..."
    searchBox.PlaceholderColor3 = Color.fromHex("#666666")
    searchBox.Text = ""
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize   = 13
    searchBox.TextColor3 = Color.fromHex("#c0c0c0")
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchWrap

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self:_filterTabs(searchBox.Text)
    end)

    -- Nav scroll: mengisi sisa tinggi sidebar (profil user di bawah sudah DIHAPUS
    -- — UI lebih simpel: sidebar murni search + daftar tab).
    local navScroll = Instance.new("ScrollingFrame")
    navScroll.BackgroundTransparency = 1
    navScroll.BorderSizePixel        = 0
    navScroll.Position            = UDim2.new(0, 0, 0, 40)
    navScroll.Size                = UDim2.new(1, 0, 1, -46)  -- 40 top + 6 padding bawah
    navScroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
    navScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    navScroll.ScrollBarThickness  = 2
    navScroll.ScrollBarImageColor3 = Color.fromHex("#272b37")
    navScroll.Parent      = sidebar
    self._navScroll       = navScroll

    local navLayout = Instance.new("UIListLayout")
    navLayout.FillDirection = Enum.FillDirection.Vertical
    navLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    navLayout.Parent        = navScroll

    -- Profil user (avatar + nama + badge tier) DIHAPUS TOTAL: tidak menampilkan
    -- identitas player di UI, sidebar lebih ringkas, & tanpa fetch thumbnail.

    -- CONTENT AREA (mulai di bawah header titlebar)
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Position = UDim2.new(0, 160, 0, 46)
    content.Size     = UDim2.new(1, -160, 1, -46)
    content.ClipsDescendants = false
    content.Parent   = bodyInner
    self._content    = content

    -- ── DRAWER BACKDROP (dim) — muncul saat sidebar drawer terbuka di layar sempit
    local backdrop = Instance.new("TextButton")
    backdrop.Name                   = "DrawerBackdrop"
    backdrop.BackgroundColor3       = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel        = 0
    backdrop.AutoButtonColor        = false
    backdrop.Text                   = ""
    backdrop.Size                   = UDim2.new(1, 0, 1, -46)
    backdrop.Position               = UDim2.new(0, 0, 0, 46)   -- dim hanya area konten, bukan header
    backdrop.Visible                = false
    backdrop.ZIndex                 = 3
    backdrop.Parent                 = bodyInner

    -- State drawer
    self._drawerNarrow = false   -- mode sempit aktif?
    self._drawerOpen   = false   -- sidebar drawer sedang terbuka?

    -- Terapkan mode docked (lebar) atau drawer (sempit).
    function self:_setSidebarMode(narrow)
        if self._drawerNarrow == narrow then return end
        self._drawerNarrow = narrow
        if narrow then
            -- DRAWER: content lebar penuh, sidebar mengambang di atas (ZIndex tinggi),
            -- tersembunyi di kiri sampai hamburger ditekan. (y=46 = bawah header)
            content.Position = UDim2.new(0, 0, 0, 46)
            content.Size     = UDim2.new(1, 0, 1, -46)
            sbDivider.Visible = false
            sidebar.ZIndex    = 5
            sidebar.Position  = UDim2.new(0, -200, 0, 46)  -- tersembunyi
            hamburger.Visible = true
            self._drawerOpen  = false
            backdrop.Visible  = false
            backdrop.BackgroundTransparency = 1
        else
            -- DOCKED: layout normal (sidebar di kiri, content di kanan).
            content.Position  = UDim2.new(0, 160, 0, 46)
            content.Size      = UDim2.new(1, -160, 1, -46)
            sbDivider.Visible = true
            sidebar.ZIndex    = 1
            sidebar.Position  = UDim2.new(0, 0, 0, 46)
            hamburger.Visible = false   -- hamburger hanya relevan di mode drawer
            backdrop.Visible  = false
        end
    end

    -- Buka/tutup drawer (hanya berlaku di mode sempit).
    function self:_toggleDrawer()
        if not self._drawerNarrow then return end
        self._drawerOpen = not self._drawerOpen
        if self._drawerOpen then
            backdrop.Visible = true
            Tween.fast(backdrop, { BackgroundTransparency = 0.5 })
            Tween.play(sidebar, { Position = UDim2.new(0, 0, 0, 46) },
                TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
        else
            Tween.fast(backdrop, { BackgroundTransparency = 1 })
            Tween.play(sidebar, { Position = UDim2.new(0, -200, 0, 46) },
                TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
            task.delay(0.2, function()
                if not self._drawerOpen then backdrop.Visible = false end
            end)
        end
    end

    backdrop.MouseButton1Click:Connect(function()
        if self._drawerOpen then self:_toggleDrawer() end
    end)

    -- default: docked (hamburger hidden); _fitWindow akan mengubah ke drawer kalau sempit
    hamburger.Visible = false

    if opts.Draggable ~= false then self:_buildDrag(titlebar, win, screenGui) end
    if opts.Resizable ~= false then self:_buildResizeHandle(win) end

    -- Set mode awal (docked/drawer) sekarang setelah method tersedia.
    if self._fitWindow then pcall(self._fitWindow) end

    return self
end

-- ── HELPERS ─────────────────────────────────────────────────

function Window:_makeCtrlBtn(parent, symbol, bgColor, textColor)
    -- Ghost style: transparan saat idle, terisi `bgColor` saat hover + teks
    -- mencerah. Press → sedikit redup (feedback). Lebih ringan & modern.
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3       = bgColor
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel  = 0
    btn.Size = UDim2.fromOffset(28, 28)
    btn.Text = symbol
    btn.Font = Enum.Font.GothamBold
    btn.TextSize   = 13
    btn.TextColor3 = Color.fromHex("#7a8194")
    btn.AutoButtonColor = false
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = btn

    btn.MouseEnter:Connect(function()
        Tween.fast(btn, { BackgroundTransparency = 0 })
        btn.TextColor3 = textColor
    end)
    btn.MouseLeave:Connect(function()
        Tween.fast(btn, { BackgroundTransparency = 1 })
        btn.TextColor3 = Color.fromHex("#7a8194")
    end)
    btn.MouseButton1Down:Connect(function()
        Tween.fast(btn, { BackgroundTransparency = 0.3 })
    end)
    btn.MouseButton1Up:Connect(function()
        Tween.fast(btn, { BackgroundTransparency = 0 })
    end)
    return btn
end

function Window:_buildDrag(titlebar, win, screenGui)
    -- pending = jari ditekan di titlebar tapi BELUM lewat dead-zone (belum geser).
    -- dragging = sudah lewat dead-zone → window benar-benar digeser.
    local pending, dragging, dragStart, startPos = false, false, nil, nil
    local DRAG_THRESHOLD = 6   -- piksel: gerak < ini = klik, ≥ ini = drag
    titlebar.Active = true

    -- self._suppressClick dibaca tombol titlebar (min/max/close) di MouseButton1Click:
    -- kalau true (baru saja drag), klik DIBATALKAN → tombol tak ter-trigger tak sengaja.
    self._suppressClick = false

    -- Koneksi InputChanged/InputEnded GLOBAL (UserInputService). Disimpan di self
    -- supaya bisa di-disconnect & TIDAK menumpuk antar run.
    self._dragConns = self._dragConns or {}
    for _, c in ipairs(self._dragConns) do pcall(function() c:Disconnect() end) end
    self._dragConns = {}

    titlebar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            pending   = true     -- tekan terdeteksi, tunggu apakah cukup jauh utk drag
            dragging  = false
            dragStart = input.Position
            startPos  = win.Position
        end
    end)

    table.insert(self._dragConns, UserInputService.InputChanged:Connect(function(input)
        if not win.Parent then return end   -- window lama ter-destroy → skip
        if not pending then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

        local delta = input.Position - dragStart

        -- DEAD-ZONE: drag baru aktif setelah gerak melewati ambang. Sebelum itu,
        -- gerakan kecil (mis. tangan goyang saat mau klik) TIDAK menggeser window.
        if not dragging then
            if math.abs(delta.X) < DRAG_THRESHOLD and math.abs(delta.Y) < DRAG_THRESHOLD then
                return
            end
            dragging = true                 -- lewat ambang → ini benar2 drag
            self._suppressClick = true      -- → batalkan klik tombol titlebar
        end

        -- KOREKSI SKALA: window di dalam UIScale; HP scale<1 → kalikan delta dgn
        -- scale supaya pergeseran visual = gerak jari 1:1 (PC scale=1 → tak berubah).
        local s = (self._uiScale and self._uiScale.Scale) or 1
        if s <= 0 then s = 1 end
        win.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X * s,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y * s
        )
    end))

    table.insert(self._dragConns, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            pending  = false
            dragging = false
            -- Reset suppress di frame berikutnya: biar handler klik tombol (yg fire
            -- SETELAH InputEnded) sempat membaca _suppressClick lalu di-clear.
            task.defer(function() self._suppressClick = false end)
        end
    end))
end

function Window:_buildResizeHandle(win)
    local handle = Instance.new("TextButton")
    handle.Size = UDim2.fromOffset(18, 18)
    handle.Position = UDim2.new(1, -18, 1, -18)
    handle.BackgroundTransparency = 1
    handle.Text = ""
    handle.ZIndex = 10
    handle.Parent = win

    local resizing, resizeStart, startSize = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            resizing     = true
            resizeStart  = input.Position
            startSize    = win.Size
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not win.Parent then return end   -- guard: window lama ter-destroy → skip
        if resizing
        and (input.UserInputType == Enum.UserInputType.MouseMovement
          or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            -- Koreksi skala sama spt drag: HP scale<1 → kalikan delta dgn scale.
            local s = (self._uiScale and self._uiScale.Scale) or 1
            if s <= 0 then s = 1 end
            win.Size = UDim2.fromOffset(
                math.max(420, startSize.X.Offset + delta.X * s),
                math.max(300, startSize.Y.Offset + delta.Y * s)
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)
end

function Window:_minimize()
    self:Hide()
end

function Window:_restore()
    self:Show()
end

function Window:_toggleMaximize()
    if not self._maximized then
        self._savedSize = self._win.Size
        self._savedPos  = self._win.Position
        self._maximized = true

        -- MAXIMIZE BENAR (window punya AnchorPoint 0.5,0.5 + UIScale):
        --  • Position HARUS center (0.5,0,0.5,0). Dulu (0,0,0,0) → pusat window ke
        --    pojok kiri-atas → separuh window keluar layar (lihat bug di gambar).
        --  • Size pakai OFFSET, bukan Scale(1,1). Karena window dirender ×scale oleh
        --    UIScale, target offset = (viewport×0.96)/scale supaya HASIL render pas
        --    mengisi ~96% layar TANPA keluar border Roblox.
        local cam = workspace.CurrentCamera
        local s   = (self._uiScale and self._uiScale.Scale) or 1
        if s <= 0 then s = 1 end
        if cam then
            local vp = cam.ViewportSize
            local w  = math.floor((vp.X * 0.96) / s)
            local h  = math.floor((vp.Y * 0.96) / s)
            Tween.slow(self._win, {
                Size     = UDim2.fromOffset(w, h),
                Position = UDim2.new(0.5, 0, 0.5, 0),
            })
        else
            Tween.slow(self._win, { Position = UDim2.new(0.5, 0, 0.5, 0) })
        end
    else
        self._maximized = false
        Tween.slow(self._win, { Size = self._savedSize, Position = self._savedPos })
        -- Re-fit ukuran tersimpan ke viewport saat ini (mis. layar berubah saat maximized)
        if self._fitWindow then task.delay(0.05, self._fitWindow) end
    end
end

function Window:_close()
    self:Hide()
end

-- Publik: sembunyikan/tampilkan window dengan animasi
function Window:Hide()
    -- Fade out seluruh window sekaligus via GroupTransparency
    Tween.play(self._win, { GroupTransparency = 1 },
        TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
    task.delay(0.22, function()
        self._win.Visible = false
    end)
end

function Window:Show()
    local win     = self._win
    local origPos = win.Position
    -- Slide dari bawah + fade in seluruh window sekaligus
    win.GroupTransparency = 1
    win.Position = UDim2.new(origPos.X.Scale, origPos.X.Offset,
                             origPos.Y.Scale, origPos.Y.Offset + 28)
    win.Visible  = true
    Tween.play(win, {
        GroupTransparency = 0,
        Position          = origPos,
    }, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
end

function Window:_filterTabs(query)
    query = query:lower()
    for _, child in ipairs(self._navScroll:GetChildren()) do
        if child:IsA("TextButton") then
            local lbl = child:FindFirstChild("Label")
            if lbl then
                child.Visible = query == "" or lbl.Text:lower():find(query, 1, true) ~= nil
            end
        end
    end
end

-- ── PUBLIC API ───────────────────────────────────────────────

function Window:AddTab(opts)
    local tab    = Tab.new(opts, self._content, self._flags)
    local navBtn = self:_makeNavButton(opts, #self._tabs + 1, tab)
    table.insert(self._tabs, tab)
    if #self._tabs == 1 then self:_selectTab(tab, navBtn) end
    return tab
end

function Window:_makeNavButton(opts, order, tab)
    local btn = Instance.new("TextButton")
    btn.Name = "NavBtn_" .. (opts.Title or "Tab")
    btn.BackgroundTransparency = 1
    btn.Size        = UDim2.new(1, 0, 0, 40)
    btn.LayoutOrder = order
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = self._navScroll

    -- Left accent bar (shows only when active) — thicker, rounded
    local accentBar = Instance.new("Frame")
    accentBar.Name = "AccentBar"
    accentBar.Size             = UDim2.new(0, 4, 0, 20)
    accentBar.Position         = UDim2.new(0, 0, 0.5, -10)
    accentBar.AnchorPoint      = Vector2.new(0, 0)
    accentBar.BackgroundColor3       = Theme:Accent()
    accentBar.BackgroundTransparency = 1
    accentBar.BorderSizePixel  = 0
    accentBar.Parent = btn

    local accentBarCorner = Instance.new("UICorner")
    accentBarCorner.CornerRadius = UDim.new(0, 2)
    accentBarCorner.Parent       = accentBar

    -- Ikon tab (opsional, opts.Icon = { Image, RectOffset, RectSize }) —
    -- sprite MONOKROM FLAT di-tint UNGU tema di SEMUA tab (idle & aktif;
    -- tab aktif ikon mencerah sedikit — spotlight tetap dari accent bar +
    -- label bold). TANPA lapisan glow/halo. Gagal load asset → kotak kosong
    -- 18px, label tetap terbaca (fail-safe; ikon murni kosmetik).
    local icon = nil
    if type(opts.Icon) == "table" and opts.Icon.Image then
        icon = Instance.new("ImageLabel")
        icon.Name                   = "Icon"
        icon.BackgroundTransparency = 1
        icon.Size                   = UDim2.fromOffset(16, 16)
        icon.Position               = UDim2.new(0, 14, 0.5, -8)
        icon.Image                  = opts.Icon.Image
        if opts.Icon.RectOffset then icon.ImageRectOffset = opts.Icon.RectOffset end
        if opts.Icon.RectSize   then icon.ImageRectSize   = opts.Icon.RectSize end
        icon.ImageColor3            = Theme:Accent()
        icon.Parent                 = btn

        Theme:OnAccentChanged(function(a)
            icon.ImageColor3 = a
        end)
    end

    -- Label — bergeser ke kanan bila ada ikon.
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size     = UDim2.new(1, icon and -46 or -28, 1, 0)
    label.Position = UDim2.new(0, icon and 38 or 16, 0, 0)
    label.Text     = opts.Title or "Tab"
    label.Font     = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextColor3     = Color.fromHex("#7a8194")
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Name   = "Label"
    label.Parent = btn

    -- Hover effect: tint SANGAT halus (bukan blok abu solid) → senada glass.
    -- Hanya utk tab non-aktif (accent bar masih tersembunyi).
    btn.MouseEnter:Connect(function()
        local bar = btn:FindFirstChild("AccentBar")
        if bar and bar.BackgroundTransparency == 1 then
            btn.BackgroundColor3 = Color.fromHex("#1b1e27")
            Tween.fast(btn, { BackgroundTransparency = 0.85 })
        end
    end)
    btn.MouseLeave:Connect(function()
        local bar = btn:FindFirstChild("AccentBar")
        if bar and bar.BackgroundTransparency == 1 then
            Tween.fast(btn, { BackgroundTransparency = 1 })
        end
    end)

    btn.MouseButton1Click:Connect(function()
        self:_selectTab(tab, btn)
    end)

    return btn
end

function Window:_selectTab(tab, navBtn)
    -- Deactivate all tabs — hide accent bar, dim label
    for _, t in ipairs(self._tabs) do t:Hide() end
    for _, child in ipairs(self._navScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundTransparency = 1
            local bar = child:FindFirstChild("AccentBar")
            local lbl = child:FindFirstChild("Label")
            local ico = child:FindFirstChild("Icon")
            if bar then bar.BackgroundTransparency = 1 end
            if lbl then lbl.TextColor3 = Color.fromHex("#7a8194"); lbl.Font = Enum.Font.GothamMedium end
            -- Ikon TETAP ungu tema saat idle (flat, bukan abu & tanpa halo).
            if ico then ico.ImageColor3 = Theme:Accent() end
        end
    end

    -- Activate selected — TANDA AKTIF = accent bar kiri + teks accent + ikon
    -- mencerah sedikit. TANPA fill abu-abu penuh (senada glass).
    tab:Show()
    navBtn.BackgroundTransparency = 1   -- tetap transparan, tak ada blok abu

    local bar = navBtn:FindFirstChild("AccentBar")
    local lbl = navBtn:FindFirstChild("Label")
    local ico = navBtn:FindFirstChild("Icon")

    if bar then bar.BackgroundTransparency = 0; bar.BackgroundColor3 = Theme:Accent() end
    if lbl then lbl.TextColor3 = Color.fromHex("#d4b3fa"); lbl.Font = Enum.Font.GothamBold end
    if ico then ico.ImageColor3 = Color.lighten(Theme:Accent(), 0.15) end

    self._activeTab = tab
end

function Window:Dialog(opts)  Dialog.show(opts, self._win.Parent) end
function Window:Popup(opts)   Popup.show(opts, self._win) end
function Window:OnClose(fn)    self._onClose    = fn end
function Window:OnMinimize(fn) self._onMinimize = fn end
function Window:OnRestore(fn)  self._onRestore  = fn end
