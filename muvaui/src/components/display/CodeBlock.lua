-- CodeBlock: tampilkan cuplikan kode dengan tombol Copy
Section.AddCodeBlock = function(self, opts)
    assert(type(opts) == "table", "AddCodeBlock: opts must be a table")

    local card, stroke = self:_makeCard()
    card.Size             = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize    = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Theme:BG(0)

    local col = Instance.new("UIListLayout")
    col.FillDirection = Enum.FillDirection.Vertical
    col.Padding       = UDim.new(0, 0)
    col.Parent        = card

    -- Header bar (language label + copy button)
    local header = Instance.new("Frame")
    header.BackgroundColor3 = Theme:BG(1)
    header.BorderSizePixel  = 0
    header.Size             = UDim2.new(1, 0, 0, 26)
    header.Parent           = card

    local headerDiv = Instance.new("Frame")
    headerDiv.BackgroundColor3 = Theme:Border(0)
    headerDiv.BorderSizePixel  = 0
    headerDiv.Size             = UDim2.new(1, 0, 0, 1)
    headerDiv.Position         = UDim2.new(0, 0, 1, -1)
    headerDiv.Parent           = header

    local langLbl = Instance.new("TextLabel")
    langLbl.BackgroundTransparency = 1
    langLbl.Size                   = UDim2.new(1, -60, 1, 0)
    langLbl.Position               = UDim2.new(0, 10, 0, 0)
    langLbl.Text                   = (opts.Language or "lua"):upper()
    langLbl.Font                   = Enum.Font.GothamBold
    langLbl.TextSize               = 12
    langLbl.TextColor3             = Theme:Text(3)
    langLbl.TextXAlignment         = Enum.TextXAlignment.Left
    langLbl.Parent                 = header

    local copyBtn = Instance.new("TextButton")
    copyBtn.BackgroundColor3 = Theme:BG(3)
    copyBtn.BorderSizePixel  = 0
    copyBtn.Size             = UDim2.fromOffset(50, 18)
    copyBtn.Position         = UDim2.new(1, -58, 0.5, -9)
    copyBtn.Text             = "Copy"
    copyBtn.Font             = Enum.Font.Gotham
    copyBtn.TextSize         = 9
    copyBtn.TextColor3       = Theme:Text(2)
    copyBtn.AutoButtonColor  = false
    copyBtn.Parent           = header

    local copyCorner = Instance.new("UICorner")
    copyCorner.CornerRadius = UDim.new(0, 4)
    copyCorner.Parent       = copyBtn

    -- Code text
    local code = Instance.new("TextLabel")
    code.BackgroundTransparency = 1
    code.Size                   = UDim2.new(1, 0, 0, 0)
    code.AutomaticSize          = Enum.AutomaticSize.Y
    code.Text                   = opts.Code or ""
    code.Font                   = Enum.Font.Code
    code.TextSize               = Layout.CODE_SIZE
    code.TextColor3             = Color.fromHex("#a8c4a2")
    code.TextXAlignment         = Enum.TextXAlignment.Left
    code.TextYAlignment         = Enum.TextYAlignment.Top
    code.TextWrapped            = true
    code.RichText               = false
    code.Parent                 = card

    local codePad = Instance.new("UIPadding")
    codePad.PaddingLeft   = UDim.new(0, 12)
    codePad.PaddingRight  = UDim.new(0, 12)
    codePad.PaddingTop    = UDim.new(0, 8)
    codePad.PaddingBottom = UDim.new(0, 8)
    codePad.Parent        = code

    -- Copy action
    if opts.Copyable ~= false then
        copyBtn.MouseButton1Click:Connect(function()
            pcall(function()
                setclipboard(opts.Code or "")
            end)
            copyBtn.Text       = "Copied!"
            copyBtn.TextColor3 = Theme:Accent()
            task.delay(1.5, function()
                copyBtn.Text       = "Copy"
                copyBtn.TextColor3 = Theme:Text(2)
            end)
        end)
    end

    copyBtn.MouseEnter:Connect(function()
        Tween.fast(copyBtn, { BackgroundColor3 = Theme:BG(4) })
        copyBtn.TextColor3 = Theme:Text(0)
    end)
    copyBtn.MouseLeave:Connect(function()
        Tween.fast(copyBtn, { BackgroundColor3 = Theme:BG(3) })
        copyBtn.TextColor3 = Theme:Text(2)
    end)

    table.insert(self._components, card)
    return card
end
