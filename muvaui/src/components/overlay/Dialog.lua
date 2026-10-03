-- Dialog: modal konfirmasi full-screen overlay
Dialog = {}

function Dialog.show(opts, screenGui)
    opts = opts or {}

    -- Overlay gelap
    local overlay = Instance.new("Frame")
    overlay.BackgroundColor3       = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel        = 0
    overlay.Size                   = UDim2.new(1, 0, 1, 0)
    overlay.ZIndex = 1
    overlay.Parent                 = screenGui

    -- Modal card
    local modal = Instance.new("Frame")
    modal.BackgroundColor3 = Theme:BG(2)
    modal.BorderSizePixel  = 0
    modal.Size             = UDim2.fromOffset(340, 0)
    modal.AutomaticSize    = Enum.AutomaticSize.Y
    modal.Position         = UDim2.new(0.5, -170, 0.5, 0)
    modal.AnchorPoint      = Vector2.new(0, 0.5)
    modal.ZIndex = 1
    modal.Parent           = screenGui

    local modalCorner = Instance.new("UICorner")
    modalCorner.CornerRadius = UDim.new(0, 12)
    modalCorner.Parent       = modal

    local modalStroke = Instance.new("UIStroke")
    modalStroke.Color     = Theme:Border(2)
    modalStroke.Thickness = 1
    modalStroke.Parent    = modal

    local modalLayout = Instance.new("UIListLayout")
    modalLayout.FillDirection = Enum.FillDirection.Vertical
    modalLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    modalLayout.Padding       = UDim.new(0, 0)
    modalLayout.Parent        = modal

    -- Body section (title + text)
    local bodySection = Instance.new("Frame")
    bodySection.BackgroundTransparency = 1
    bodySection.Size                   = UDim2.new(1, 0, 0, 0)
    bodySection.AutomaticSize          = Enum.AutomaticSize.Y
    bodySection.LayoutOrder            = 1
    bodySection.ZIndex = 1
    bodySection.Parent                 = modal

    local bodyPad = Instance.new("UIPadding")
    bodyPad.PaddingLeft   = UDim.new(0, 20)
    bodyPad.PaddingRight  = UDim.new(0, 20)
    bodyPad.PaddingTop    = UDim.new(0, 20)
    bodyPad.PaddingBottom = UDim.new(0, 16)
    bodyPad.Parent        = bodySection

    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.FillDirection = Enum.FillDirection.Vertical
    bodyLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    bodyLayout.Padding       = UDim.new(0, 8)
    bodyLayout.Parent        = bodySection

    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size                   = UDim2.new(1, 0, 0, 20)
    titleLbl.Text                   = opts.Title or "Confirm"
    titleLbl.Font                   = Enum.Font.GothamBold
    titleLbl.TextSize               = 16
    titleLbl.TextColor3             = Theme:Text(0)
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
    titleLbl.LayoutOrder            = 1
    titleLbl.ZIndex = 1
    titleLbl.Parent                 = bodySection

    -- Body text
    local bodyLbl = Instance.new("TextLabel")
    bodyLbl.BackgroundTransparency = 1
    bodyLbl.Size                   = UDim2.new(1, 0, 0, 0)
    bodyLbl.AutomaticSize          = Enum.AutomaticSize.Y
    bodyLbl.Text                   = opts.Body or ""
    bodyLbl.Font                   = Enum.Font.Gotham
    bodyLbl.TextSize               = 13
    bodyLbl.TextColor3             = Theme:Text(3)
    bodyLbl.TextXAlignment         = Enum.TextXAlignment.Left
    bodyLbl.TextWrapped            = true
    bodyLbl.LineHeight             = 1.4
    bodyLbl.LayoutOrder            = 2
    bodyLbl.ZIndex = 1
    bodyLbl.Parent                 = bodySection

    -- Divider
    local div = Instance.new("Frame")
    div.BackgroundColor3 = Theme:Border(1)
    div.BorderSizePixel  = 0
    div.Size             = UDim2.new(1, 0, 0, 1)
    div.LayoutOrder      = 2
    div.ZIndex = 1
    div.Parent           = modal

    -- Buttons footer
    local btnSection = Instance.new("Frame")
    btnSection.BackgroundTransparency = 1
    btnSection.Size                   = UDim2.new(1, 0, 0, 56)
    btnSection.LayoutOrder            = 3
    btnSection.ZIndex = 1
    btnSection.Parent                 = modal

    local btnPad = Instance.new("UIPadding")
    btnPad.PaddingLeft   = UDim.new(0, 16)
    btnPad.PaddingRight  = UDim.new(0, 16)
    btnPad.PaddingTop    = UDim.new(0, 12)
    btnPad.PaddingBottom = UDim.new(0, 12)
    btnPad.Parent        = btnSection

    local btnLayout = Instance.new("UIListLayout")
    btnLayout.FillDirection       = Enum.FillDirection.Horizontal
    btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    btnLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    btnLayout.Padding             = UDim.new(0, 8)
    btnLayout.Parent              = btnSection

    local function closeDialog()
        Tween.fast(overlay, { BackgroundTransparency = 1 })
        Tween.play(modal, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, -170, 0.5, 10),
        }, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
        task.delay(0.14, function()
            pcall(function() overlay:Destroy() end)
            pcall(function() modal:Destroy() end)
        end)
    end

    local STYLE_COLORS = {
        Default = { bg = Theme:Accent(),            text = Color3.new(1,1,1)  },
        Danger  = { bg = Color.fromHex("#ef4444"),  text = Color3.new(1,1,1)  },
        Success = { bg = Color.fromHex("#22c55e"),  text = Color3.new(1,1,1)  },
        Ghost   = { bg = Theme:BG(4),               text = Theme:Text(2)      },
        Warn    = { bg = Color.fromHex("#eab308"),  text = Color3.new(0,0,0)  },
    }

    local buttons = opts.Buttons or {
        { Text = "Cancel", Style = "Ghost",   Callback = nil },
        { Text = "OK",     Style = "Default", Callback = nil },
    }

    for _, bOpts in ipairs(buttons) do
        local colors = STYLE_COLORS[bOpts.Style] or STYLE_COLORS.Ghost
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = colors.bg
        btn.BorderSizePixel  = 0
        btn.Size             = UDim2.fromOffset(90, 32)
        btn.Text             = bOpts.Text or "OK"
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 12
        btn.TextColor3       = colors.text
        btn.AutoButtonColor  = false
        btn.ZIndex = 1
        btn.Parent           = btnSection

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 7)
        bc.Parent       = btn

        local bs = Instance.new("UIStroke")
        bs.Color     = Color.darken(colors.bg, 0.15)
        bs.Thickness = 1
        bs.Parent    = btn

        btn.MouseEnter:Connect(function()
            Tween.fast(btn, { BackgroundColor3 = Color.lighten(colors.bg, 0.08) })
        end)
        btn.MouseLeave:Connect(function()
            Tween.fast(btn, { BackgroundColor3 = colors.bg })
        end)
        btn.MouseButton1Click:Connect(function()
            closeDialog()
            if bOpts.Callback then pcall(bOpts.Callback) end
        end)
    end

    -- Close on overlay click
    overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            closeDialog()
        end
    end)

    -- Animate in
    modal.BackgroundTransparency = 1
    modal.Position = UDim2.new(0.5, -170, 0.5, 16)
    Tween.play(modal, {
        BackgroundTransparency = 0,
        Position = UDim2.new(0.5, -170, 0.5, 0),
    }, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
end

-- Window.Dialog dipatch di Library.lua
