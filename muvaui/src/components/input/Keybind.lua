-- Keybind: klik lalu tekan key untuk rebind
local UserInputService = game:GetService("UserInputService")

-- Map KeyCode.Name → label pendek yang user-friendly
local KEY_LABELS = {
    -- Angka row atas
    Zero = "0", One = "1", Two = "2", Three = "3", Four = "4",
    Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
    -- Numpad
    KeypadZero = "KP0", KeypadOne = "KP1", KeypadTwo = "KP2",
    KeypadThree = "KP3", KeypadFour = "KP4", KeypadFive = "KP5",
    KeypadSix = "KP6", KeypadSeven = "KP7", KeypadEight = "KP8",
    KeypadNine = "KP9",
    KeypadPlus = "KP+", KeypadMinus = "KP-", KeypadAsterisk = "KP*",
    KeypadSlash = "KP/", KeypadPeriod = "KP.", KeypadEnter = "KP-ENT",
    -- Modifier
    LeftShift = "L.SHIFT", RightShift = "R.SHIFT",
    LeftControl = "L.CTRL", RightControl = "R.CTRL",
    LeftAlt = "L.ALT", RightAlt = "R.ALT",
    LeftMeta = "L.WIN", RightMeta = "R.WIN",
    -- Navigasi (ASCII — glyph panah ←↑→↓ tofu-risk di sebagian device)
    Up = "UP", Down = "DOWN", Left = "LEFT", Right = "RIGHT",
    Home = "HOME", End = "END",
    PageUp = "PGUP", PageDown = "PGDN",
    Insert = "INS", Delete = "DEL",
    -- Spesial
    Return = "ENTER", BackSpace = "BKSP", Tab = "TAB",
    Space = "SPACE", Escape = "ESC", CapsLock = "CAPS",
    -- Tanda baca umum
    Minus = "-", Equals = "=", LeftBracket = "[", RightBracket = "]",
    BackSlash = "\\", Semicolon = ";", Quote = "'",
    Comma = ",", Period = ".", Slash = "/",
    Backquote = "`",
}

Section.AddKeybind = function(self, opts)
    assert(type(opts) == "table", "AddKeybind: opts must be a table")
    local default = opts.Default or Enum.KeyCode.Unknown
    local flag    = self:_registerFlag(opts.ID, default)

    local card, stroke = self:_makeCard()

    local row = Instance.new("UIListLayout")
    row.FillDirection     = Enum.FillDirection.Horizontal
    row.VerticalAlignment = Enum.VerticalAlignment.Center
    row.Padding           = UDim.new(0, 8)
    row.Parent            = card

    -- Info
    local info = self:_makeInfoBlock(card, opts.Title, opts.Desc, 80)

    -- Key label button — style sama dengan value label di Slider
    local keyBtn = Instance.new("TextButton")
    keyBtn.BackgroundTransparency = 1
    keyBtn.BorderSizePixel        = 0
    keyBtn.Size                   = UDim2.fromOffset(68, 26)
    keyBtn.LayoutOrder            = 99
    keyBtn.AutoButtonColor        = false
    keyBtn.Font                   = Layout.FONT_BOLD
    keyBtn.TextSize               = Layout.TITLE_SIZE
    keyBtn.TextColor3             = Theme:Accent()
    keyBtn.TextXAlignment         = Enum.TextXAlignment.Right
    keyBtn.Parent                 = card

    -- Stroke tipis hanya saat listening
    local keyStroke = Instance.new("UIStroke")
    keyStroke.Color     = Theme:Accent()
    keyStroke.Thickness = 0
    keyStroke.Parent    = keyBtn

    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 5)
    keyCorner.Parent       = keyBtn

    local function keyName(kc)
        if kc == Enum.KeyCode.Unknown then return "NONE" end
        return KEY_LABELS[kc.Name] or kc.Name:upper()
    end

    local value    = default
    local listening = false

    keyBtn.Text = keyName(value)

    local function setListening(state)
        listening = state
        if state then
            keyBtn.Text          = "..."
            keyBtn.TextColor3    = Theme:Text(3)
            keyStroke.Thickness  = 1
            keyStroke.Color      = Theme:Accent()
        else
            keyBtn.Text          = keyName(value)
            keyBtn.TextColor3    = Theme:Accent()
            keyStroke.Thickness  = 0
        end
    end

    keyBtn.MouseButton1Click:Connect(function()
        setListening(not listening)
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Escape then
                setListening(false)
                return
            end
            value = input.KeyCode
            setListening(false)
            if flag then flag:_fire(value) end
            if opts.Callback then pcall(opts.Callback, value) end
        end
    end)

    keyBtn.MouseEnter:Connect(function()
        if not listening then
            Tween.fast(keyBtn, { TextColor3 = Color.lighten(Theme:Accent(), 0.15) })
        end
    end)
    keyBtn.MouseLeave:Connect(function()
        if not listening then
            Tween.fast(keyBtn, { TextColor3 = Theme:Accent() })
        end
    end)

    card.MouseEnter:Connect(function()
        Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
        stroke.Color = Theme:Border(1)
    end)
    card.MouseLeave:Connect(function()
        Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
        stroke.Color = Theme:Border(0)
    end)

    Theme:OnAccentChanged(function(accent)
        keyBtn.TextColor3 = accent
    end)

    if flag then
        flag:OnChanged(function(v)
            value     = v
            keyBtn.Text = keyName(v)
        end)
    end

    table.insert(self._components, card)
    return card
end
