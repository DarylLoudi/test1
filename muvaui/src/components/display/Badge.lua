-- Badge: status label inline
local BADGE_COLORS = {
    Purple = { bg = Color.fromHex("#1a0a2e"), text = Color.fromHex("#A855F7"), border = Color.fromHex("#2e1050") },
    Green  = { bg = Color.fromHex("#0a1a0e"), text = Color.fromHex("#22c55e"), border = Color.fromHex("#0e2e18") },
    Red    = { bg = Color.fromHex("#1a0a0a"), text = Color.fromHex("#ef4444"), border = Color.fromHex("#3b1010") },
    Yellow = { bg = Color.fromHex("#1a1500"), text = Color.fromHex("#eab308"), border = Color.fromHex("#2e2600") },
    Blue   = { bg = Color.fromHex("#0a1220"), text = Color.fromHex("#60a5fa"), border = Color.fromHex("#0e1e38") },
}

Section.AddBadge = function(self, opts)
    assert(type(opts) == "table", "AddBadge: opts must be a table")
    local colors = BADGE_COLORS[opts.Color] or BADGE_COLORS.Purple

    local card, stroke = self:_makeCard()

    local row = Instance.new("UIListLayout")
    row.FillDirection     = Enum.FillDirection.Horizontal
    row.VerticalAlignment = Enum.VerticalAlignment.Center
    row.Padding           = UDim.new(0, 8)
    row.Parent            = card

    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size                   = UDim2.new(1, -80, 1, 0)
    titleLbl.Text                   = opts.Title or ""
    titleLbl.Font                   = Layout.FONT_TITLE
    titleLbl.TextSize               = Layout.TITLE_SIZE
    titleLbl.TextColor3             = Theme:Text(1)
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
    titleLbl.Parent                 = card

    -- Badge pill
    local badge = Instance.new("Frame")
    badge.BackgroundColor3 = colors.bg
    badge.BorderSizePixel  = 0
    badge.Size             = UDim2.fromOffset(0, 20)
    badge.AutomaticSize    = Enum.AutomaticSize.X
    badge.LayoutOrder      = 99
    badge.Parent           = card

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 4)
    badgeCorner.Parent       = badge

    local badgeStroke = Instance.new("UIStroke")
    badgeStroke.Color     = colors.border
    badgeStroke.Thickness = 1
    badgeStroke.Parent    = badge

    local badgePad = Instance.new("UIPadding")
    badgePad.PaddingLeft  = UDim.new(0, 7)
    badgePad.PaddingRight = UDim.new(0, 7)
    badgePad.Parent       = badge

    local badgeLbl = Instance.new("TextLabel")
    badgeLbl.BackgroundTransparency = 1
    badgeLbl.Size                   = UDim2.new(1, 0, 1, 0)
    badgeLbl.Text                   = opts.Value or ""
    badgeLbl.Font                   = Enum.Font.GothamBold
    badgeLbl.TextSize               = 12
    badgeLbl.TextColor3             = colors.text
    badgeLbl.Parent                 = badge

    -- Return object with :SetValue()
    local obj = { _badge = badge, _lbl = badgeLbl }
    function obj:SetValue(v)
        badgeLbl.Text = tostring(v)
    end

    table.insert(self._components, card)
    return obj
end
