-- InfoDisplay: key-value rows dengan optional badge
local BADGE_COLORS = {
    Purple = Color.fromHex("#A855F7"),
    Green  = Color.fromHex("#22c55e"),
    Red    = Color.fromHex("#ef4444"),
    Yellow = Color.fromHex("#eab308"),
    Blue   = Color.fromHex("#60a5fa"),
}
local BADGE_BG = {
    Purple = Color.fromHex("#1a0a2e"),
    Green  = Color.fromHex("#0a1a0e"),
    Red    = Color.fromHex("#1a0a0a"),
    Yellow = Color.fromHex("#1a1500"),
    Blue   = Color.fromHex("#0a1220"),
}

Section.AddInfoDisplay = function(self, opts)
    assert(type(opts) == "table", "AddInfoDisplay: opts must be a table")

    local card, stroke = self:_makeCard()
    card.Size          = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y

    -- Remove default padding, pakai padding manual di dalam
    for _, c in ipairs(card:GetChildren()) do
        if c:IsA("UIPadding") then c:Destroy() end
    end

    local outerPad = Instance.new("UIPadding")
    outerPad.PaddingLeft   = UDim.new(0, 12)
    outerPad.PaddingRight  = UDim.new(0, 12)
    outerPad.PaddingTop    = UDim.new(0, 8)
    outerPad.PaddingBottom = UDim.new(0, 8)
    outerPad.Parent        = card

    -- SortOrder+LayoutOrder eksplisit (tie by-Name bikin baris Frame nangkring
    -- di atas header TextLabel — bug sama dgn Textarea).
    local col = Instance.new("UIListLayout")
    col.FillDirection = Enum.FillDirection.Vertical
    col.SortOrder     = Enum.SortOrder.LayoutOrder
    col.Padding       = UDim.new(0, 0)
    col.Parent        = card

    -- Title header
    if opts.Title then
        local hdr = Instance.new("TextLabel")
        hdr.BackgroundTransparency = 1
        hdr.Size                   = UDim2.new(1, 0, 0, 20)
        hdr.Text                   = opts.Title
        hdr.Font                   = Layout.FONT_BOLD
        hdr.TextSize               = Layout.VALUE_SIZE
        hdr.TextColor3             = Theme:Accent()
        hdr.TextXAlignment         = Enum.TextXAlignment.Left
        hdr.LayoutOrder            = 1
        hdr.Parent                 = card
        Theme:OnAccentChanged(function(a) hdr.TextColor3 = a end)
    end

    local rowObjects = {}

    local function buildRow(rowOpts, isLast, order)
        local row = Instance.new("Frame")
        row.BackgroundTransparency = 1
        row.Size                   = UDim2.new(1, 0, 0, 24)
        row.LayoutOrder            = 1 + (order or 1)
        row.Parent                 = card

        -- Tidak pakai UIListLayout agar key kiri + value kanan bisa space-between

        -- Bottom divider (not on last row)
        if not isLast then
            local div = Instance.new("Frame")
            div.BackgroundColor3 = Theme:Border(0)
            div.BorderSizePixel  = 0
            div.Size             = UDim2.new(1, 0, 0, 1)
            div.Position         = UDim2.new(0, 0, 1, -1)
            div.Parent           = row
        end

        local keyLbl = Instance.new("TextLabel")
        keyLbl.BackgroundTransparency = 1
        keyLbl.Size                   = UDim2.new(0.5, 0, 1, 0)
        keyLbl.Position               = UDim2.new(0, 0, 0, 0)
        keyLbl.Text                   = rowOpts.Key or ""
        keyLbl.Font                   = Layout.FONT_BODY
        keyLbl.TextSize               = Layout.VALUE_SIZE
        keyLbl.TextColor3             = Theme:Text(3)
        keyLbl.TextXAlignment         = Enum.TextXAlignment.Left
        keyLbl.Parent                 = row

        -- Value: badge or plain text
        if rowOpts.Badge then
            local badgeColor = BADGE_COLORS[rowOpts.Badge] or BADGE_COLORS.Purple
            local badgeBg    = BADGE_BG[rowOpts.Badge]    or BADGE_BG.Purple

            local badgeFrame = Instance.new("Frame")
            badgeFrame.BackgroundColor3 = badgeBg
            badgeFrame.BorderSizePixel  = 0
            badgeFrame.Size             = UDim2.fromOffset(0, 18)
            badgeFrame.AutomaticSize    = Enum.AutomaticSize.X
            badgeFrame.Position         = UDim2.new(1, 0, 0.5, -9)
            badgeFrame.AnchorPoint      = Vector2.new(1, 0)
            badgeFrame.Parent           = row

            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 4)
            bCorner.Parent       = badgeFrame

            local bPad = Instance.new("UIPadding")
            bPad.PaddingLeft  = UDim.new(0, 6)
            bPad.PaddingRight = UDim.new(0, 6)
            bPad.Parent       = badgeFrame

            local bLbl = Instance.new("TextLabel")
            bLbl.BackgroundTransparency = 1
            bLbl.Size                   = UDim2.new(1, 0, 1, 0)
            bLbl.Text                   = rowOpts.Value or ""
            bLbl.Font                   = Enum.Font.GothamBold
            bLbl.TextSize               = 12
            bLbl.TextColor3             = badgeColor
            bLbl.Parent                 = badgeFrame

            rowObjects[rowOpts.Key] = { frame = badgeFrame, lbl = bLbl }
        else
            local valLbl = Instance.new("TextLabel")
            valLbl.BackgroundTransparency = 1
            valLbl.Size                   = UDim2.new(0.5, 0, 1, 0)
            valLbl.Position               = UDim2.new(0.5, 0, 0, 0)
            valLbl.Text                   = tostring(rowOpts.Value or "")
            valLbl.Font                   = Layout.FONT_BODY
            valLbl.TextSize               = Layout.VALUE_SIZE
            valLbl.TextColor3             = Theme:Text(2)
            valLbl.TextXAlignment         = Enum.TextXAlignment.Right
            valLbl.TextTruncate           = Enum.TextTruncate.AtEnd
            valLbl.Parent                 = row

            rowObjects[rowOpts.Key] = { lbl = valLbl }
        end

        return row
    end

    local rows = opts.Rows or {}
    for i, rowOpts in ipairs(rows) do
        buildRow(rowOpts, i == #rows, i)
    end

    -- Return object with :SetRow()
    local obj = {}
    function obj:SetRow(key, value)
        local r = rowObjects[key]
        if r and r.lbl then r.lbl.Text = tostring(value) end
    end

    table.insert(self._components, card)
    return obj
end
