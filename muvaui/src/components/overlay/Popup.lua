-- Popup: modal kecil ringan, tidak blokir background seperti Dialog
Popup = {}

-- icon = nama sprite Lucide (Icons.new) — bukan glyph/emoji TextLabel.
local POPUP_STYLES = {
    Default = { accent = function() return Theme:Accent() end,           icon = "info" },
    Success = { accent = function() return Color.fromHex("#22c55e") end,  icon = "circle-check" },
    Error   = { accent = function() return Color.fromHex("#ef4444") end,  icon = "circle-x" },
    Warn    = { accent = function() return Color.fromHex("#eab308") end,  icon = "triangle-alert" },
}

function Popup.show(opts, parentWin)
    opts = opts or {}
    local style = POPUP_STYLES[opts.Style] or POPUP_STYLES.Default

    -- Parent ke ScreenGui agar tidak terpotong window frame
    local screenGui = parentWin
    while screenGui and not screenGui:IsA("ScreenGui") do
        screenGui = screenGui.Parent
    end
    if not screenGui then return end


    -- Popup card — lebih kecil dari Dialog
    local card = Instance.new("Frame")
    card.BackgroundColor3       = Theme:BG(2)
    card.BackgroundTransparency = 1
    card.BorderSizePixel        = 0
    card.Size                   = UDim2.fromOffset(300, 0)
    card.AutomaticSize          = Enum.AutomaticSize.Y
    card.Position               = UDim2.new(0.5, -150, 0.5, 12)
    card.AnchorPoint            = Vector2.new(0, 0.5)
    card.ZIndex = 1
    card.Parent                 = screenGui

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent       = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color     = style.accent()
    cardStroke.Thickness = 1
    cardStroke.Parent    = card

    local cardLayout = Instance.new("UIListLayout")
    cardLayout.FillDirection = Enum.FillDirection.Vertical
    cardLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    cardLayout.Padding       = UDim.new(0, 0)
    cardLayout.Parent        = card

    -- Body section
    local bodySection = Instance.new("Frame")
    bodySection.BackgroundTransparency = 1
    bodySection.Size                   = UDim2.new(1, 0, 0, 0)
    bodySection.AutomaticSize          = Enum.AutomaticSize.Y
    bodySection.LayoutOrder            = 1
    bodySection.ZIndex = 1
    bodySection.Parent                 = card

    local bodyPad = Instance.new("UIPadding")
    bodyPad.PaddingLeft   = UDim.new(0, 16)
    bodyPad.PaddingRight  = UDim.new(0, 16)
    bodyPad.PaddingTop    = UDim.new(0, 16)
    bodyPad.PaddingBottom = UDim.new(0, 12)
    bodyPad.Parent        = bodySection

    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.FillDirection = Enum.FillDirection.Vertical
    bodyLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    bodyLayout.Padding       = UDim.new(0, 6)
    bodyLayout.Parent        = bodySection

    -- Icon + Title row
    local titleRow = Instance.new("Frame")
    titleRow.BackgroundTransparency = 1
    titleRow.Size                   = UDim2.new(1, 0, 0, 20)
    titleRow.LayoutOrder            = 1
    titleRow.ZIndex = 1
    titleRow.Parent                 = bodySection

    local titleLayout = Instance.new("UIListLayout")
    titleLayout.FillDirection     = Enum.FillDirection.Horizontal
    titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    titleLayout.Padding           = UDim.new(0, 6)
    titleLayout.Parent            = titleRow

    local iconImg = Icons.new(style.icon, 16, style.accent())
    iconImg.ZIndex = 1
    iconImg.Parent = titleRow

    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size                   = UDim2.new(1, -24, 1, 0)
    titleLbl.Text                   = opts.Title or ""
    titleLbl.Font                   = Enum.Font.GothamBold
    titleLbl.TextSize               = 14
    titleLbl.TextColor3             = Theme:Text(0)
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 1
    titleLbl.Parent                 = titleRow

    if opts.Body and opts.Body ~= "" then
        local bodyLbl = Instance.new("TextLabel")
        bodyLbl.BackgroundTransparency = 1
        bodyLbl.Size                   = UDim2.new(1, 0, 0, 0)
        bodyLbl.AutomaticSize          = Enum.AutomaticSize.Y
        bodyLbl.Text                   = opts.Body
        bodyLbl.Font                   = Enum.Font.Gotham
        bodyLbl.TextSize               = 12
        bodyLbl.TextColor3             = Theme:Text(3)
        bodyLbl.TextXAlignment         = Enum.TextXAlignment.Left
        bodyLbl.TextWrapped            = true
        bodyLbl.LineHeight             = 1.35
        bodyLbl.LayoutOrder            = 2
        bodyLbl.ZIndex = 1
        bodyLbl.Parent                 = bodySection
    end

    -- Buttons (opsional)
    local buttons = opts.Buttons or {}
    if #buttons > 0 then
        local divLine = Instance.new("Frame")
        divLine.BackgroundColor3 = Theme:Border(1)
        divLine.BorderSizePixel  = 0
        divLine.Size             = UDim2.new(1, 0, 0, 1)
        divLine.LayoutOrder      = 2
        divLine.ZIndex = 1
        divLine.Parent           = card

        local btnSection = Instance.new("Frame")
        btnSection.BackgroundTransparency = 1
        btnSection.Size                   = UDim2.new(1, 0, 0, 48)
        btnSection.LayoutOrder            = 3
        btnSection.ZIndex = 1
        btnSection.Parent                 = card

        local btnPad = Instance.new("UIPadding")
        btnPad.PaddingLeft   = UDim.new(0, 12)
        btnPad.PaddingRight  = UDim.new(0, 12)
        btnPad.PaddingTop    = UDim.new(0, 10)
        btnPad.PaddingBottom = UDim.new(0, 10)
        btnPad.Parent        = btnSection

        local btnLayout = Instance.new("UIListLayout")
        btnLayout.FillDirection       = Enum.FillDirection.Horizontal
        btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        btnLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
        btnLayout.Padding             = UDim.new(0, 6)
        btnLayout.Parent              = btnSection

        local STYLE_COLORS = {
            Default = { bg = Theme:Accent(),           text = Color3.new(1,1,1) },
            Danger  = { bg = Color.fromHex("#ef4444"), text = Color3.new(1,1,1) },
            Success = { bg = Color.fromHex("#22c55e"), text = Color3.new(1,1,1) },
            Ghost   = { bg = Theme:BG(4),              text = Theme:Text(2)     },
            Warn    = { bg = Color.fromHex("#eab308"), text = Color3.new(0,0,0) },
        }

        local function closePopup()
            Tween.play(card, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, -150, 0.5, 20),
            }, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
            task.delay(0.12, function()
                pcall(function() card:Destroy() end)
            end)
        end

        for _, bOpts in ipairs(buttons) do
            local colors = STYLE_COLORS[bOpts.Style] or STYLE_COLORS.Ghost
            local btn = Instance.new("TextButton")
            btn.BackgroundColor3 = colors.bg
            btn.BorderSizePixel  = 0
            btn.Size             = UDim2.fromOffset(80, 28)
            btn.Text             = bOpts.Text or "OK"
            btn.Font             = Enum.Font.GothamBold
            btn.TextSize         = 11
            btn.TextColor3       = colors.text
            btn.AutoButtonColor  = false
            btn.ZIndex = 1
            btn.Parent           = btnSection

            local bc = Instance.new("UICorner")
            bc.CornerRadius = UDim.new(0, 6)
            bc.Parent       = btn

            btn.MouseEnter:Connect(function()
                Tween.fast(btn, { BackgroundColor3 = Color.lighten(colors.bg, 0.08) })
            end)
            btn.MouseLeave:Connect(function()
                Tween.fast(btn, { BackgroundColor3 = colors.bg })
            end)
            btn.MouseButton1Click:Connect(function()
                closePopup()
                if bOpts.Callback then pcall(bOpts.Callback) end
            end)
        end

    else
        -- No buttons: auto-dismiss after duration
        local duration = opts.Duration or 3
        local function closePopup()
            Tween.play(card, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, -150, 0.5, 20),
            }, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
            task.delay(0.12, function()
                pcall(function() card:Destroy() end)
            end)
        end
        task.delay(duration, closePopup)
    end

    -- Animate in
    Tween.play(card, {
        BackgroundTransparency = 0,
        Position = UDim2.new(0.5, -150, 0.5, 0),
    }, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
end

-- Window.Popup dipatch di Library.lua
