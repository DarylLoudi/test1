-- Webhook: Discord webhook input dengan test koneksi
local HttpService = game:GetService("HttpService")

Section.AddWebhook = function(self, opts)
    assert(type(opts) == "table", "AddWebhook: opts must be a table")
    local flag = self:_registerFlag(opts.ID, opts.Default or "")

    local card, stroke = self:_makeCard()
    card.Size          = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y

    -- SortOrder+LayoutOrder eksplisit — tanpa ini tie LayoutOrder dipecah
    -- Roblox by NAME ("Frame" < "TextLabel") → judul nyasar ke bawah
    -- (bug sama dgn Textarea).
    local col = Instance.new("UIListLayout")
    col.FillDirection = Enum.FillDirection.Vertical
    col.SortOrder     = Enum.SortOrder.LayoutOrder
    col.Padding       = UDim.new(0, 6)
    col.Parent        = card

    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size                   = UDim2.new(1, 0, 0, 15)
    titleLbl.Text                   = opts.Title or "Webhook"
    titleLbl.Font                   = Layout.FONT_TITLE
    titleLbl.TextSize               = Layout.TITLE_SIZE
    titleLbl.TextColor3             = Theme:Text(1)
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
    titleLbl.LayoutOrder            = 1
    titleLbl.Parent                 = card

    -- Input row
    local inputRow = Instance.new("Frame")
    inputRow.BackgroundTransparency = 1
    inputRow.Size                   = UDim2.new(1, 0, 0, 28)
    inputRow.LayoutOrder            = 2
    inputRow.Parent                 = card

    local inputLayout = Instance.new("UIListLayout")
    inputLayout.FillDirection     = Enum.FillDirection.Horizontal
    inputLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    inputLayout.Padding           = UDim.new(0, 6)
    inputLayout.Parent            = inputRow

    -- URL input: border accent jelas + clip (URL panjang tampil EKOR-nya,
    -- bukan "..." — konsisten dgn TextInput).
    local inputWrap = Instance.new("Frame")
    inputWrap.BackgroundColor3       = Theme:BG(4)
    inputWrap.BackgroundTransparency = 0.85
    inputWrap.BorderSizePixel  = 0
    inputWrap.Size             = UDim2.new(1, -70, 1, 0)
    inputWrap.ClipsDescendants = true
    inputWrap.Parent           = inputRow

    local iwCorner = Instance.new("UICorner")
    iwCorner.CornerRadius = UDim.new(0, 6)
    iwCorner.Parent       = inputWrap

    -- Border = ungu accent. Idle cukup terlihat (0.22); focus → penuh.
    local iwStroke = Instance.new("UIStroke")
    iwStroke.Color        = Theme:Accent()
    iwStroke.Transparency = 0.22
    iwStroke.Thickness    = 1
    iwStroke.Parent       = inputWrap
    task.defer(function()
        if iwStroke and iwStroke.Parent then iwStroke.Thickness = 1.0001; iwStroke.Thickness = 1 end
    end)

    local iwPad = Instance.new("UIPadding")
    iwPad.PaddingLeft  = UDim.new(0, 8)
    iwPad.PaddingRight = UDim.new(0, 8)
    iwPad.Parent       = inputWrap

    local urlBox = Instance.new("TextBox")
    urlBox.BackgroundTransparency = 1
    urlBox.BorderSizePixel        = 0
    urlBox.Size                   = UDim2.new(1, 0, 1, 0)
    urlBox.Text                   = opts.Default or ""
    urlBox.PlaceholderText        = opts.Placeholder or "https://discord.com/api/webhooks/..."
    urlBox.PlaceholderColor3      = Theme:Text(4)
    urlBox.Font                   = Enum.Font.Code
    urlBox.TextSize               = 13
    urlBox.TextColor3             = Theme:Text(0)
    urlBox.ClearTextOnFocus       = false
    urlBox.TextXAlignment         = Enum.TextXAlignment.Left
    urlBox.Parent                 = inputWrap

    -- Overflow → rata kanan (ekor teks terlihat saat mengetik/paste panjang).
    local function updateOverflow()
        local fits = urlBox.TextBounds.X <= (urlBox.AbsoluteSize.X - 2)
        urlBox.TextXAlignment = fits and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
    end
    urlBox:GetPropertyChangedSignal("Text"):Connect(updateOverflow)
    urlBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateOverflow)
    task.defer(updateOverflow)

    urlBox.Focused:Connect(function()
        iwStroke.Color = Theme:Accent()
        Tween.fast(iwStroke, { Transparency = 0 })
    end)
    urlBox.FocusLost:Connect(function()
        iwStroke.Color = Theme:Accent()
        Tween.fast(iwStroke, { Transparency = 0.22 })
        if flag then flag:_fire(urlBox.Text) end
        if opts.Callback then
            local valid = urlBox.Text:find("discord.com/api/webhooks/") ~= nil
            pcall(opts.Callback, urlBox.Text, valid)
        end
    end)

    -- Test button: glass-transparan + border (senada Button/input).
    local testBtn = Instance.new("TextButton")
    testBtn.BackgroundColor3       = Theme:BG(4)
    testBtn.BackgroundTransparency = 0.88
    testBtn.BorderSizePixel  = 0
    testBtn.Size             = UDim2.fromOffset(62, 28)
    testBtn.Text             = "Test"
    testBtn.Font             = Enum.Font.GothamBold
    testBtn.TextSize         = 10
    testBtn.TextColor3       = Theme:Text(2)
    testBtn.AutoButtonColor  = false
    testBtn.Parent           = inputRow

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 6)
    tbCorner.Parent       = testBtn

    local tbStroke = Instance.new("UIStroke")
    tbStroke.Color     = Theme:Border(2)   -- border lebih terang → jelas di atas glass gelap
    tbStroke.Thickness = 1
    tbStroke.Parent    = testBtn
    task.defer(function()
        if tbStroke and tbStroke.Parent then tbStroke.Thickness = 1.0001; tbStroke.Thickness = 1 end
    end)

    -- Status row
    local statusRow = Instance.new("Frame")
    statusRow.BackgroundTransparency = 1
    statusRow.Size                   = UDim2.new(1, 0, 0, 14)
    statusRow.LayoutOrder            = 3
    statusRow.Parent                 = card

    local statusLayout = Instance.new("UIListLayout")
    statusLayout.FillDirection     = Enum.FillDirection.Horizontal
    statusLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    statusLayout.Padding           = UDim.new(0, 5)
    statusLayout.Parent            = statusRow

    local dot = Instance.new("Frame")
    dot.BackgroundColor3 = Theme:Text(4)
    dot.BorderSizePixel  = 0
    dot.Size             = UDim2.fromOffset(6, 6)
    dot.Parent           = statusRow

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent       = dot

    local statusLbl = Instance.new("TextLabel")
    statusLbl.BackgroundTransparency = 1
    statusLbl.Size                   = UDim2.new(1, -11, 1, 0)
    statusLbl.Text                   = "Not configured"
    statusLbl.Font                   = Layout.FONT_BODY
    statusLbl.TextSize               = Layout.VALUE_SIZE
    statusLbl.TextColor3             = Theme:Text(4)
    statusLbl.TextXAlignment         = Enum.TextXAlignment.Left
    statusLbl.Parent                 = statusRow

    local function setStatus(state, msg)
        local colors = {
            ok      = Color.fromHex("#22c55e"),
            err     = Color.fromHex("#ef4444"),
            testing = Color.fromHex("#eab308"),
            idle    = Theme:Text(4),
        }
        dot.BackgroundColor3   = colors[state] or colors.idle
        statusLbl.TextColor3   = colors[state] or colors.idle
        statusLbl.Text         = msg or ""
    end

    testBtn.MouseButton1Click:Connect(function()
        local url = urlBox.Text:match("^%s*(.-)%s*$")
        if url == "" then
            setStatus("err", "Enter a URL first")
            return
        end
        setStatus("testing", "Testing...")
        testBtn.Text       = "..."
        testBtn.TextColor3 = Theme:Text(3)

        task.spawn(function()
            local ok, result = pcall(function()
                return HttpService:RequestAsync({
                    Url    = url,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body   = HttpService:JSONEncode({
                        content  = "MuvaUI webhook test - OK",
                        username = "MuvaUI",
                    }),
                })
            end)

            task.wait(0.5)
            testBtn.Text       = "Test"
            testBtn.TextColor3 = Theme:Text(2)

            if ok and result and result.StatusCode and result.StatusCode < 300 then
                setStatus("ok", "Connected")
                Toast.show({ Title = "Webhook OK", Type = "Success", Duration = 2 })
            else
                setStatus("err", "Failed - check URL")
                Toast.show({ Title = "Webhook Error", Body = "Invalid URL or no access", Type = "Error", Duration = 3 })
            end
        end)
    end)

    testBtn.MouseEnter:Connect(function()
        Tween.fast(testBtn, { BackgroundColor3 = Theme:BG(3) })
        tbStroke.Color = Theme:Accent()
    end)
    testBtn.MouseLeave:Connect(function()
        Tween.fast(testBtn, { BackgroundColor3 = Theme:BG(4) })
        tbStroke.Color = Theme:Border(2)
    end)

    card.MouseEnter:Connect(function()
        Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
        stroke.Color = Theme:Border(1)
    end)
    card.MouseLeave:Connect(function()
        Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
        stroke.Color = Theme:Border(0)
    end)

    -- Send method via Flag
    if flag then
        flag.Send = function(_, msgOpts)
            local url = flag.Value
            if not url or url == "" then return end
            task.spawn(function()
                pcall(function()
                    HttpService:RequestAsync({
                        Url    = url,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body   = HttpService:JSONEncode({
                            content  = msgOpts.Content  or "",
                            username = msgOpts.Username or "MuvaUI",
                        }),
                    })
                end)
            end)
        end
    end

    table.insert(self._components, card)
    return card
end
