-- ColorPicker: preset swatch palette (tanpa slider/hue bar)
local PRESETS = {
    "#A855F7","#8B5CF6","#6366F1","#3B82F6","#06B6D4","#22C55E",
    "#EAB308","#F97316","#EF4444","#EC4899","#F43F5E","#14B8A6",
    "#FFFFFF","#D4D4D8","#A1A1AA","#71717A","#52525B","#27272A",
    "#FDE68A","#BBF7D0","#BAE6FD","#E9D5FF","#FECACA","#FED7AA",
}

Section.AddColorPicker = function(self, opts)
    assert(type(opts) == "table", "AddColorPicker: opts must be a table")
    local default = opts.Default or Color.fromHex("#A855F7")
    local flag    = self:_registerFlag(opts.ID, default)

    local card, stroke = self:_makeCard()
    card.ClipsDescendants = false

    local row = Instance.new("UIListLayout")
    row.FillDirection     = Enum.FillDirection.Horizontal
    row.VerticalAlignment = Enum.VerticalAlignment.Center
    row.Padding           = UDim.new(0, 8)
    row.Parent            = card

    -- Info
    local info = self:_makeInfoBlock(card, opts.Title, opts.Desc, 46)

    -- Color preview button
    local previewBtn = Instance.new("TextButton")
    previewBtn.BackgroundColor3 = default
    previewBtn.BorderSizePixel  = 0
    previewBtn.Size             = UDim2.fromOffset(30, 30)
    previewBtn.LayoutOrder      = 99
    previewBtn.Text             = ""
    previewBtn.AutoButtonColor  = false
    previewBtn.Parent           = card

    local pvCorner = Instance.new("UICorner")
    pvCorner.CornerRadius = UDim.new(0, 7)
    pvCorner.Parent       = previewBtn

    local pvStroke = Instance.new("UIStroke")
    pvStroke.Color     = Theme:Border(1)
    pvStroke.Thickness = 2
    pvStroke.Parent    = previewBtn

    -- Palette popup — hanya preset grid
    local palette = Instance.new("Frame")
    palette.BackgroundColor3 = Theme:BG(3)
    palette.BorderSizePixel  = 0
    palette.Size             = UDim2.fromOffset(188, 0)
    palette.AutomaticSize    = Enum.AutomaticSize.Y
    palette.Visible          = false
    palette.ZIndex = 3
    palette.Parent           = card

    local palCorner = Instance.new("UICorner")
    palCorner.CornerRadius = UDim.new(0, 10)
    palCorner.Parent       = palette

    local palStroke = Instance.new("UIStroke")
    palStroke.Color     = Theme:Border(2)
    palStroke.Thickness = 1
    palStroke.Parent    = palette

    local palPad = Instance.new("UIPadding")
    palPad.PaddingLeft   = UDim.new(0, 10)
    palPad.PaddingRight  = UDim.new(0, 10)
    palPad.PaddingTop    = UDim.new(0, 10)
    palPad.PaddingBottom = UDim.new(0, 10)
    palPad.Parent        = palette

    -- Grid swatches
    local grid = Instance.new("Frame")
    grid.BackgroundTransparency = 1
    grid.Size                   = UDim2.new(1, 0, 0, 0)
    grid.AutomaticSize          = Enum.AutomaticSize.Y
    grid.Parent                 = palette

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize    = UDim2.fromOffset(26, 26)
    gridLayout.CellPadding = UDim2.fromOffset(5, 5)
    gridLayout.Parent      = grid

    local value = default
    local selectedStroke = nil  -- track swatch terpilih

    local function selectColor(c, hex, swStroke)
        value = c
        previewBtn.BackgroundColor3 = c
        -- reset stroke swatch sebelumnya
        if selectedStroke then
            selectedStroke.Thickness = 0
        end
        selectedStroke = swStroke
        if selectedStroke then
            selectedStroke.Color     = Color3.new(1, 1, 1)
            selectedStroke.Thickness = 2
        end
        if flag then flag:_fire(c) end
        if opts.Callback then pcall(opts.Callback, c) end
    end

    for _, hex in ipairs(PRESETS) do
        local sw = Instance.new("TextButton")
        sw.BackgroundColor3 = Color.fromHex(hex)
        sw.BorderSizePixel  = 0
        sw.Size             = UDim2.fromOffset(26, 26)
        sw.Text             = ""
        sw.AutoButtonColor  = false
        sw.ZIndex           = 62
        sw.Parent           = grid

        local swCorner = Instance.new("UICorner")
        swCorner.CornerRadius = UDim.new(0, 5)
        swCorner.Parent       = sw

        local swStroke = Instance.new("UIStroke")
        swStroke.Thickness = 0
        swStroke.Parent    = sw

        -- Mark default sebagai terpilih
        if Color.toHex(default):lower() == hex:lower() then
            selectedStroke           = swStroke
            swStroke.Color           = Color3.new(1, 1, 1)
            swStroke.Thickness       = 2
        end

        sw.MouseButton1Click:Connect(function()
            selectColor(Color.fromHex(hex), hex, swStroke)
        end)

        sw.MouseEnter:Connect(function()
            Tween.fast(sw, { Size = UDim2.fromOffset(28, 28) })
        end)
        sw.MouseLeave:Connect(function()
            Tween.fast(sw, { Size = UDim2.fromOffset(26, 26) })
        end)
    end

    -- Open / close palette
    local open   = false
    local _palSG = nil

    local function closePalette()
        open = false
        palette.Visible = false
        palette.Parent  = card
        if _palSG then
            pcall(function() _palSG:Destroy() end)
            _palSG = nil
        end
        pvStroke.Color = Theme:Border(1)
    end

    local function openPalette()
        open = true
        pvStroke.Color = Theme:Accent()

        local absPos  = previewBtn.AbsolutePosition
        local absSize = previewBtn.AbsoluteSize

        -- CoreGui hanya terakses di executor; di Studio → pcall + fallback PlayerGui.
        local CoreGui = nil
        pcall(function() CoreGui = game:GetService("CoreGui") end)
        if CoreGui then
            for _, v in ipairs(CoreGui:GetChildren()) do
                if v.Name == "MuvaUI_ColorPicker" then
                    pcall(function() v:Destroy() end)
                end
            end
        end
        local sg = Instance.new("ScreenGui")
        sg.Name           = "MuvaUI_ColorPicker"
        sg.ResetOnSpawn   = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.DisplayOrder   = 9
        sg.IgnoreGuiInset = false
        if CoreGui then pcall(function() sg.Parent = CoreGui end) end
        if not sg.Parent then
            pcall(function()
                sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
            end)
        end
        _palSG = sg

        local blocker = Instance.new("TextButton")
        blocker.BackgroundTransparency = 1
        blocker.BorderSizePixel        = 0
        blocker.Size                   = UDim2.new(1, 0, 1, 0)
        blocker.Text                   = ""
        blocker.AutoButtonColor        = false
        blocker.ZIndex = 3
        blocker.Parent                 = sg
        blocker.MouseButton1Click:Connect(function() closePalette() end)

        palette.Parent = sg

        local palW    = 188
        local screenW = workspace.CurrentCamera.ViewportSize.X
        local posX    = absPos.X - palW - 6
        if posX < 0 then posX = absPos.X + absSize.X + 6 end
        if posX + palW > screenW then posX = absPos.X end

        palette.Position = UDim2.fromOffset(posX, absPos.Y)
        palette.Visible  = true
    end

    -- Auto-close saat tab berganti
    local function isCardVisible()
        local p = card.Parent
        while p do
            local ok, visible = pcall(function() return p.Visible end)
            if ok and visible == false then return false end
            p = p.Parent
        end
        return true
    end

    game:GetService("RunService").Heartbeat:Connect(function()
        if open and not isCardVisible() then closePalette() end
    end)

    previewBtn.MouseButton1Click:Connect(function()
        if open then closePalette() else openPalette() end
    end)

    previewBtn.MouseEnter:Connect(function()
        Tween.fast(previewBtn, { Size = UDim2.fromOffset(32, 32) })
        pvStroke.Color = Theme:Accent()
    end)
    previewBtn.MouseLeave:Connect(function()
        Tween.fast(previewBtn, { Size = UDim2.fromOffset(30, 30) })
        if not open then pvStroke.Color = Theme:Border(1) end
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
            value = v
            previewBtn.BackgroundColor3 = v
        end)
    end

    table.insert(self._components, card)
    return card
end
