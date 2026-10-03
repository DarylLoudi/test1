-- Avatar: player thumbnail atau placeholder inisial
local Players = game:GetService("Players")

local SIZE_MAP = { Small = 26, sm = 26, Medium = 36, md = 36, Large = 48, lg = 48 }
local TEXT_MAP = { Small = 10, sm = 10, Medium = 13, md = 13, Large = 18, lg = 18 }

Section.AddAvatar = function(self, opts)
    assert(type(opts) == "table", "AddAvatar: opts must be a table")
    local sz   = SIZE_MAP[opts.Size] or SIZE_MAP.Medium
    local txsz = TEXT_MAP[opts.Size] or TEXT_MAP.Medium

    local card, stroke = self:_makeCard()
    card.Size = UDim2.new(1, 0, 0, math.max(50, sz + 20))

    local row = Instance.new("UIListLayout")
    row.FillDirection     = Enum.FillDirection.Horizontal
    row.VerticalAlignment = Enum.VerticalAlignment.Center
    row.Padding           = UDim.new(0, 10)
    row.Parent            = card

    -- Avatar circle
    local circle = Instance.new("Frame")
    circle.BackgroundColor3 = Theme:Accent()
    circle.BorderSizePixel  = 0
    circle.Size             = UDim2.fromOffset(sz, sz)
    circle.Parent           = card

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent       = circle

    local circleStroke = Instance.new("UIStroke")
    circleStroke.Color     = Theme:Accent()
    circleStroke.Thickness = 2
    circleStroke.Parent    = circle

    -- Initials fallback
    local initials = Instance.new("TextLabel")
    initials.BackgroundTransparency = 1
    initials.Size                   = UDim2.new(1, 0, 1, 0)
    initials.Font                   = Enum.Font.GothamBold
    initials.TextSize               = txsz
    initials.TextColor3             = Color3.new(1, 1, 1)
    initials.ZIndex                 = 2
    initials.Parent                 = circle

    -- Image label (loaded async)
    local img = Instance.new("ImageLabel")
    img.BackgroundTransparency = 1
    img.Size                   = UDim2.new(1, 0, 1, 0)
    img.Image                  = ""
    img.ScaleType              = Enum.ScaleType.Crop
    img.ZIndex                 = 3
    img.Visible                = false
    img.Parent                 = circle

    local imgCorner = Instance.new("UICorner")
    imgCorner.CornerRadius = UDim.new(1, 0)
    imgCorner.Parent       = img

    -- Load avatar thumbnail if UserId given
    if opts.UserId then
        local initial = "?"
        pcall(function()
            local name = Players:GetNameFromUserIdAsync(opts.UserId)
            initial = name:sub(1, 1):upper()
        end)
        initials.Text = initial

        task.spawn(function()
            local ok, thumb = pcall(function()
                return Players:GetUserThumbnailAsync(
                    opts.UserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size100x100
                )
            end)
            if ok and thumb then
                img.Image   = thumb
                img.Visible = true
            end
        end)
    else
        initials.Text = opts.Label and opts.Label:sub(1,1):upper() or "?"
    end

    -- Label beside avatar
    if opts.Label then
        local info = Instance.new("Frame")
        info.BackgroundTransparency = 1
        info.Size                   = UDim2.new(1, -(sz + 10), 1, 0)
        info.Parent                 = card

        local infoL = Instance.new("UIListLayout")
        infoL.FillDirection     = Enum.FillDirection.Vertical
        infoL.VerticalAlignment = Enum.VerticalAlignment.Center
    infoL.Padding           = UDim.new(0, 2)
        infoL.Parent            = info

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size                   = UDim2.new(1, 0, 0, Layout.TITLE_SIZE)
        lbl.Text                   = opts.Label
        lbl.Font                   = Layout.FONT_TITLE
        lbl.TextSize               = Layout.TITLE_SIZE
        lbl.TextColor3             = Theme:Text(1)
        lbl.TextXAlignment         = Enum.TextXAlignment.Left
        lbl.Parent                 = info
    end

    Theme:OnAccentChanged(function(accent)
        circle.BackgroundColor3 = accent
        circleStroke.Color      = accent
    end)

    table.insert(self._components, card)
    return card
end
