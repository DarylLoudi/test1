-- KeySystem: layar validasi key sebelum window muncul
KeySystem = {}

local function readSavedKey(filename)
    local ok, content = pcall(readfile, filename)
    if not ok or not content or content == "" then return nil end
    local ok2, data = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), content)
    if not ok2 or type(data) ~= "table" then return nil end
    return data.key
end

local function saveKey(filename, key)
    local ok, encoded = pcall(function()
        return game:GetService("HttpService"):JSONEncode({ key = key })
    end)
    if ok then pcall(writefile, filename, encoded) end
end

function KeySystem.show(opts, screenGui, onSuccess)
    opts = opts or {}
    local validKeys = {}
    for _, k in ipairs(opts.Keys or {}) do validKeys[k:upper()] = true end
    local saveFile = opts.SaveFile or "muvaui_key.json"

    local saved = readSavedKey(saveFile)
    if saved and validKeys[saved:upper()] then
        if opts.OnValidated then pcall(opts.OnValidated, saved:upper()) end
        onSuccess()
        return
    end

    -- Card sebagai CanvasGroup agar GroupTransparency fade semua children sekaligus
    local card = Instance.new("CanvasGroup")
    card.BackgroundColor3  = Color.fromHex("#141416")
    card.BorderSizePixel   = 0
    card.Size              = UDim2.fromOffset(400, 0)
    card.AutomaticSize     = Enum.AutomaticSize.Y
    card.Position          = UDim2.new(0.5, -200, 0.5, 0)
    card.AnchorPoint       = Vector2.new(0, 0.5)
    card.GroupTransparency = 1
    card.Parent            = screenGui

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 14)
    cardCorner.Parent       = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color     = Theme:Border(1)
    cardStroke.Thickness = 1
    cardStroke.Parent    = card

    local cardLayout = Instance.new("UIListLayout")
    cardLayout.FillDirection = Enum.FillDirection.Vertical
    cardLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    cardLayout.Parent        = card

    -- Header
    local header = Instance.new("Frame")
    header.BackgroundColor3 = Color.fromHex("#0e0e10")
    header.BorderSizePixel  = 0
    header.Size             = UDim2.new(1, 0, 0, 80)
    header.LayoutOrder      = 1
    header.Parent           = card

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 14)
    headerCorner.Parent       = header

    local headerFill = Instance.new("Frame")
    headerFill.BackgroundColor3 = Color.fromHex("#0e0e10")
    headerFill.BorderSizePixel  = 0
    headerFill.Size             = UDim2.new(1, 0, 0, 14)
    headerFill.Position         = UDim2.new(0, 0, 1, -14)
    headerFill.Parent           = header

    local headerDiv = Instance.new("Frame")
    headerDiv.BackgroundColor3 = Theme:Border(1)
    headerDiv.BorderSizePixel  = 0
    headerDiv.Size             = UDim2.new(1, 0, 0, 1)
    headerDiv.Position         = UDim2.new(0, 0, 1, -1)
    headerDiv.Parent           = header

    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size                   = UDim2.new(1, 0, 0, 32)
    titleLbl.Position               = UDim2.new(0, 0, 0, 12)
    titleLbl.Text                   = opts.Title or "MuvaUI"
    titleLbl.Font                   = Enum.Font.GothamBold
    titleLbl.TextSize               = 24
    titleLbl.TextColor3             = Theme:Text(0)
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Center
    titleLbl.Parent                 = header

    local subLbl = Instance.new("TextLabel")
    subLbl.BackgroundTransparency = 1
    subLbl.Size                   = UDim2.new(1, 0, 0, 20)
    subLbl.Position               = UDim2.new(0, 0, 0, 50)
    subLbl.Text                   = "Enter your key to continue"
    subLbl.Font                   = Enum.Font.Gotham
    subLbl.TextSize               = 13
    subLbl.TextColor3             = Theme:Text(4)
    subLbl.TextXAlignment         = Enum.TextXAlignment.Center
    subLbl.Parent                 = header

    -- Body
    local body = Instance.new("Frame")
    body.BackgroundTransparency = 1
    body.Size                   = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize          = Enum.AutomaticSize.Y
    body.LayoutOrder            = 2
    body.Parent                 = card

    local bodyPad = Instance.new("UIPadding")
    bodyPad.PaddingLeft   = UDim.new(0, 20)
    bodyPad.PaddingRight  = UDim.new(0, 20)
    bodyPad.PaddingTop    = UDim.new(0, 18)
    bodyPad.PaddingBottom = UDim.new(0, 18)
    bodyPad.Parent        = body

    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.FillDirection = Enum.FillDirection.Vertical
    bodyLayout.Padding       = UDim.new(0, 10)
    bodyLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    bodyLayout.Parent        = body

    local keyLabel = Instance.new("TextLabel")
    keyLabel.BackgroundTransparency = 1
    keyLabel.Size                   = UDim2.new(1, 0, 0, 14)
    keyLabel.Text                   = "LICENSE KEY"
    keyLabel.Font                   = Enum.Font.GothamBold
    keyLabel.TextSize               = 11
    keyLabel.TextColor3             = Theme:Text(4)
    keyLabel.TextXAlignment         = Enum.TextXAlignment.Left
    keyLabel.LayoutOrder            = 1
    keyLabel.Parent                 = body

    local inputRow = Instance.new("Frame")
    inputRow.BackgroundTransparency = 1
    inputRow.Size                   = UDim2.new(1, 0, 0, 34)
    inputRow.LayoutOrder            = 2
    inputRow.Parent                 = body

    local inputRowLayout = Instance.new("UIListLayout")
    inputRowLayout.FillDirection     = Enum.FillDirection.Horizontal
    inputRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    inputRowLayout.Padding           = UDim.new(0, 6)
    inputRowLayout.Parent            = inputRow

    local inputWrap = Instance.new("Frame")
    inputWrap.BackgroundColor3 = Theme:BG(1)
    inputWrap.BorderSizePixel  = 0
    inputWrap.Size             = UDim2.new(1, -50, 1, 0)
    inputWrap.ClipsDescendants = true
    inputWrap.Parent           = inputRow

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 7)
    inputCorner.Parent       = inputWrap

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color     = Theme:Border(1)
    inputStroke.Thickness = 1
    inputStroke.Parent    = inputWrap

    local inputPad = Instance.new("UIPadding")
    inputPad.PaddingLeft  = UDim.new(0, 10)
    inputPad.PaddingRight = UDim.new(0, 10)
    inputPad.Parent       = inputWrap

    local keyInput = Instance.new("TextBox")
    keyInput.BackgroundTransparency = 1
    keyInput.BorderSizePixel        = 0
    keyInput.Size                   = UDim2.new(1, 0, 1, 0)
    keyInput.PlaceholderText        = "MUVA-XXXX-XXXX-XXXX"
    keyInput.PlaceholderColor3      = Theme:Text(4)
    keyInput.Text                   = ""
    keyInput.Font                   = Enum.Font.Code
    keyInput.TextSize               = 14
    keyInput.TextColor3             = Theme:Text(0)
    keyInput.ClearTextOnFocus       = false
    keyInput.TextXAlignment         = Enum.TextXAlignment.Left
    keyInput.Parent                 = inputWrap

    -- Overflow → rata kanan: key panjang yg dipaste/diketik tampil EKOR-nya
    -- (bukan terpotong "..." yg bikin ketikan berikutnya tak terlihat).
    local function updateOverflow()
        local fits = keyInput.TextBounds.X <= (keyInput.AbsoluteSize.X - 2)
        keyInput.TextXAlignment = fits and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
    end
    keyInput:GetPropertyChangedSignal("Text"):Connect(updateOverflow)
    keyInput:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateOverflow)
    task.defer(updateOverflow)

    keyInput.Focused:Connect(function()
        Tween.fast(inputStroke, { Color = Theme:Accent() })
    end)
    keyInput.FocusLost:Connect(function()
        Tween.fast(inputStroke, { Color = Theme:Border(1) })
    end)

    -- Tombol submit = sprite "arrow-right" (glyph → tofu-risk di Gotham)
    local submitBtn = Instance.new("TextButton")
    submitBtn.BackgroundColor3 = Theme:Accent()
    submitBtn.BorderSizePixel  = 0
    submitBtn.Size             = UDim2.fromOffset(44, 34)
    submitBtn.Text             = ""
    submitBtn.AutoButtonColor  = false
    submitBtn.LayoutOrder      = 99
    submitBtn.Parent           = inputRow

    local submitIco = Icons.new("arrow-right", 16, Color3.new(1, 1, 1))
    submitIco.AnchorPoint = Vector2.new(0.5, 0.5)
    submitIco.Position    = UDim2.new(0.5, 0, 0.5, 0)
    submitIco.Parent      = submitBtn

    local submitCorner = Instance.new("UICorner")
    submitCorner.CornerRadius = UDim.new(0, 7)
    submitCorner.Parent       = submitBtn

    local statusLbl = Instance.new("TextLabel")
    statusLbl.BackgroundTransparency = 1
    statusLbl.Size                   = UDim2.new(1, 0, 0, 16)
    statusLbl.Text                   = ""
    statusLbl.Font                   = Enum.Font.Gotham
    statusLbl.TextSize               = 13
    statusLbl.TextColor3             = Color.fromHex("#ef4444")
    statusLbl.TextXAlignment         = Enum.TextXAlignment.Center
    statusLbl.LayoutOrder            = 3
    statusLbl.Parent                 = body

    local linksRow = Instance.new("Frame")
    linksRow.BackgroundTransparency = 1
    linksRow.Size                   = UDim2.new(1, 0, 0, 20)
    linksRow.LayoutOrder            = 4
    linksRow.Parent                 = body

    local linksLayout = Instance.new("UIListLayout")
    linksLayout.FillDirection       = Enum.FillDirection.Horizontal
    linksLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    linksLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    linksLayout.Padding             = UDim.new(0, 16)
    linksLayout.Parent              = linksRow

    local function makeLink(text, url)
        local btn = Instance.new("TextButton")
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel        = 0
        btn.Size                   = UDim2.fromOffset(0, 16)
        btn.AutomaticSize          = Enum.AutomaticSize.X
        btn.Text                   = text
        btn.Font                   = Enum.Font.Gotham
        btn.TextSize               = 13
        btn.TextColor3             = Theme:Text(4)
        btn.AutoButtonColor        = false
        btn.Parent                 = linksRow

        btn.MouseEnter:Connect(function() btn.TextColor3 = Theme:Accent() end)
        btn.MouseLeave:Connect(function() btn.TextColor3 = Theme:Text(4) end)
        btn.MouseButton1Click:Connect(function()
            if url and url ~= "" then
                pcall(setclipboard, url)
                statusLbl.TextColor3 = Color.fromHex("#22c55e")
                statusLbl.Text = "Link copied to clipboard!"
                task.delay(2, function()
                    if statusLbl.Parent then statusLbl.Text = "" end
                end)
            end
        end)
        return btn
    end

    makeLink("Get Key", opts.GetKeyUrl or "")
    makeLink("Discord", opts.Discord   or "")
    makeLink("Support", opts.Support   or "")

    local function validate()
        local key = keyInput.Text:match("^%s*(.-)%s*$"):upper()
        if key == "" then
            statusLbl.TextColor3 = Color.fromHex("#ef4444")
            statusLbl.Text = "Please enter a key."
            return
        end
        if validKeys[key] then
            statusLbl.TextColor3 = Color.fromHex("#22c55e")
            statusLbl.Text = "Key valid!"
            saveKey(saveFile, key)
            -- Jeda singkat agar user bisa baca "valid", lalu slide up + fade out
            task.delay(0.6, function()
                Tween.play(card, {
                    GroupTransparency = 1,
                    Position = UDim2.new(0.5, -200, 0.5, -24),
                }, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
                task.delay(0.32, function()
                    pcall(function() card:Destroy() end)
                    if opts.OnValidated then pcall(opts.OnValidated, key) end
                    onSuccess()
                end)
            end)
        else
            statusLbl.TextColor3 = Color.fromHex("#ef4444")
            statusLbl.Text = "Invalid key. Try again."
            Tween.play(card, { Position = UDim2.new(0.5, -208, 0.5, 0) },
                TweenInfo.new(0.05, Enum.EasingStyle.Linear))
            task.delay(0.05, function()
                Tween.play(card, { Position = UDim2.new(0.5, -192, 0.5, 0) },
                    TweenInfo.new(0.05, Enum.EasingStyle.Linear))
                task.delay(0.05, function()
                    Tween.play(card, { Position = UDim2.new(0.5, -200, 0.5, 0) },
                        TweenInfo.new(0.05, Enum.EasingStyle.Linear))
                end)
            end)
        end
    end

    submitBtn.MouseButton1Click:Connect(validate)
    keyInput.FocusLost:Connect(function(enter) if enter then validate() end end)
    submitBtn.MouseEnter:Connect(function() Tween.fast(submitBtn, { BackgroundColor3 = Theme:AccentDark() }) end)
    submitBtn.MouseLeave:Connect(function() Tween.fast(submitBtn, { BackgroundColor3 = Theme:Accent() }) end)
    Theme:OnAccentChanged(function(accent) submitBtn.BackgroundColor3 = accent end)

    -- Animate in: slide dari bawah + fade seluruh card sekaligus via GroupTransparency
    card.GroupTransparency = 1
    card.Position = UDim2.new(0.5, -200, 0.5, 28)
    task.defer(function()
        Tween.play(card, {
            GroupTransparency = 0,
            Position = UDim2.new(0.5, -200, 0.5, 0),
        }, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    end)
end
