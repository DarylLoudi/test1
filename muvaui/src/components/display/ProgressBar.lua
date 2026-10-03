-- ProgressBar: visual indikator 0–100 dengan SetValue
Section.AddProgressBar = function(self, opts)
    assert(type(opts) == "table", "AddProgressBar: opts must be a table")
    local min     = opts.Min   or 0
    local max     = opts.Max   or 100
    local initial = math.clamp(opts.Value or 0, min, max)

    local card, stroke = self:_makeCard()
    Layout.lockHeight(card, 46)

    -- Title row
    local titleRow = Instance.new("Frame")
    titleRow.BackgroundTransparency = 1
    titleRow.Size                   = UDim2.new(1, 0, 0, 16)
    titleRow.Parent                 = card

    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size                   = UDim2.new(1, -40, 1, 0)
    titleLbl.Text                   = opts.Title or ""
    titleLbl.Font                   = Layout.FONT_TITLE
    titleLbl.TextSize               = Layout.TITLE_SIZE
    titleLbl.TextColor3             = Theme:Text(1)
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
    titleLbl.Parent                 = titleRow

    local pctLbl = Instance.new("TextLabel")
    pctLbl.BackgroundTransparency = 1
    pctLbl.Size                   = UDim2.fromOffset(40, 16)
    pctLbl.Position               = UDim2.new(1, -40, 0, 0)
    pctLbl.Font                   = Layout.FONT_BOLD
    pctLbl.TextSize               = Layout.TITLE_SIZE
    pctLbl.TextColor3             = Theme:Accent()
    pctLbl.TextXAlignment         = Enum.TextXAlignment.Right
    pctLbl.Parent                 = titleRow

    -- Track
    local track = Instance.new("Frame")
    track.BackgroundColor3 = Theme:BG(4)
    track.BorderSizePixel  = 0
    track.Size             = UDim2.new(1, 0, 0, 5)
    track.Position         = UDim2.new(0, 0, 0, 24)
    track.Parent           = card

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent       = track

    -- Fill
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Theme:Accent()
    fill.BorderSizePixel  = 0
    fill.Size             = UDim2.new(0, 0, 1, 0)
    fill.Parent           = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent       = fill

    local fillGrad = Instance.new("UIGradient")
    fillGrad.Color    = ColorSequence.new(Theme:AccentDark(), Theme:Accent())
    fillGrad.Rotation = 90
    fillGrad.Parent   = fill

    local function updateVisual(v, animated)
        local pct = (v - min) / (max - min)
        local pctStr = tostring(math.floor(pct * 100)) .. "%"
        pctLbl.Text = pctStr
        if animated then
            Tween.slow(fill, { Size = UDim2.new(pct, 0, 1, 0) })
        else
            fill.Size = UDim2.new(pct, 0, 1, 0)
        end
    end

    updateVisual(initial, false)

    Theme:OnAccentChanged(function(accent)
        fill.BackgroundColor3 = accent
        pctLbl.TextColor3     = accent
        fillGrad.Color        = ColorSequence.new(Theme:AccentDark(), accent)
    end)

    -- Return object with :SetValue()
    local obj = {}
    function obj:SetValue(v)
        local clamped = math.clamp(v, min, max)
        updateVisual(clamped, true)
    end

    table.insert(self._components, card)
    return obj
end
