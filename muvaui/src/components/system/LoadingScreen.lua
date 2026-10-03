-- LoadingScreen: layar loading yang sync dengan operasi nyata
-- Setiap Step = satu operasi async (fetch, parse, dll)
-- Progress bar maju hanya setelah operasi selesai
--
-- API:
--   Library:SetLoadingScreen({
--     Title = "My Script",
--     Steps = {
--       { Message = "Loading Main...",     Run = function() return game:HttpGet(url) end },
--       { Message = "Loading Teleport...", Run = function() return game:HttpGet(url2) end },
--       { Message = "Ready!" },  -- step tanpa Run = cosmetic delay singkat
--     },
--     OnResult = function(results) end,  -- opsional: terima array hasil tiap step
--   })
--
-- Jika step.Run() error → step ditandai ✗ (warna Error), loading tetap lanjut
-- results[i] = { ok=bool, value=any, err=string|nil }

LoadingScreen = {}

local COSMETIC_DELAY = 0.35  -- detik jeda untuk step tanpa Run (visual feedback)

function LoadingScreen.show(config, screenGui, onDone)
    config = config or {}
    local title    = config.Title    or "MuvaUI"
    local steps    = config.Steps    or { { Message = "Loading..." } }
    local onResult = config.OnResult  -- opsional callback hasil semua step

    -- ── Card ────────────────────────────────────────────────────
    local card = Instance.new("CanvasGroup")
    card.BackgroundColor3 = Color.fromHex("#0e0e10")
    card.BorderSizePixel  = 0
    card.Size             = UDim2.fromOffset(310, 0)
    card.AutomaticSize    = Enum.AutomaticSize.Y
    card.Position         = UDim2.new(0.5, -155, 0.5, 0)
    card.AnchorPoint      = Vector2.new(0, 0.5)
    card.GroupTransparency = 1
    card.Parent           = screenGui

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 14)
    cardCorner.Parent       = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color     = Theme:Border(1)
    cardStroke.Thickness = 1
    cardStroke.Parent    = card

    local cardPad = Instance.new("UIPadding")
    cardPad.PaddingLeft   = UDim.new(0, 24)
    cardPad.PaddingRight  = UDim.new(0, 24)
    cardPad.PaddingTop    = UDim.new(0, 28)
    cardPad.PaddingBottom = UDim.new(0, 28)
    cardPad.Parent        = card

    local cardLayout = Instance.new("UIListLayout")
    cardLayout.FillDirection       = Enum.FillDirection.Vertical
    cardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    cardLayout.Padding             = UDim.new(0, 12)
    cardLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    cardLayout.Parent              = card

    -- ── Spinner ─────────────────────────────────────────────────
    local spinnerFrame = Instance.new("Frame")
    spinnerFrame.BackgroundTransparency = 1
    spinnerFrame.Size                   = UDim2.fromOffset(38, 38)
    spinnerFrame.LayoutOrder            = 1
    spinnerFrame.Parent                 = card

    -- Spinner = sprite "loader" (glyph ◐ tofu-risk di sebagian device)
    local spinnerImg = Icons.new("loader", 28, Theme:Accent())
    spinnerImg.AnchorPoint = Vector2.new(0.5, 0.5)
    spinnerImg.Position    = UDim2.new(0.5, 0, 0.5, 0)
    spinnerImg.Parent      = spinnerFrame

    local spinTween = Tween.play(spinnerImg, { Rotation = 360 },
        TweenInfo.new(0.75, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1))

    Theme:OnAccentChanged(function(accent)
        spinnerImg.ImageColor3 = accent
    end)

    -- ── Title ───────────────────────────────────────────────────
    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size                   = UDim2.new(1, 0, 0, 20)
    titleLbl.Text                   = title
    titleLbl.Font                   = Enum.Font.GothamBold
    titleLbl.TextSize               = 16
    titleLbl.TextColor3             = Theme:Text(0)
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Center
    titleLbl.LayoutOrder            = 2
    titleLbl.Parent                 = card

    -- ── Progress bar ────────────────────────────────────────────
    local progressFrame = Instance.new("Frame")
    progressFrame.BackgroundTransparency = 1
    progressFrame.Size                   = UDim2.new(1, 0, 0, 5)
    progressFrame.LayoutOrder            = 3
    progressFrame.Parent                 = card

    local track = Instance.new("Frame")
    track.BackgroundColor3 = Theme:BG(4)
    track.BorderSizePixel  = 0
    track.Size             = UDim2.new(1, 0, 1, 0)
    track.Parent           = progressFrame

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent       = track

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

    Theme:OnAccentChanged(function(accent)
        fill.BackgroundColor3 = accent
        fillGrad.Color        = ColorSequence.new(Theme:AccentDark(), accent)
    end)

    -- ── Status line (SATU baris, berganti tiap step) ────────────
    local statusLbl = Instance.new("TextLabel")
    statusLbl.BackgroundTransparency = 1
    statusLbl.Size                   = UDim2.new(1, 0, 0, 18)
    statusLbl.Text                   = steps[1] and steps[1].Message or "Loading..."
    statusLbl.Font                   = Enum.Font.Gotham
    statusLbl.TextSize               = 13
    statusLbl.TextColor3             = Theme:Text(2)
    statusLbl.TextXAlignment         = Enum.TextXAlignment.Center
    statusLbl.TextTruncate           = Enum.TextTruncate.AtEnd
    statusLbl.LayoutOrder            = 4
    statusLbl.Parent                 = card

    -- ── Animate in: slide dari bawah + fade seluruh card via GroupTransparency
    card.GroupTransparency = 1
    card.Position = UDim2.new(0.5, -155, 0.5, 28)
    task.defer(function()
        Tween.play(card, {
            GroupTransparency = 0,
            Position = UDim2.new(0.5, -155, 0.5, 0),
        }, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    end)

    -- ── Jalankan step satu per satu ─────────────────────────────
    task.spawn(function()
        local totalSteps = #steps
        local results    = {}

        for i, step in ipairs(steps) do
            -- Update SATU baris status ke message step aktif
            statusLbl.Text       = step.Message or ("Step " .. i)
            statusLbl.TextColor3 = Theme:Text(1)

            local ok, value = true, nil
            local errMsg    = nil

            if step.Run then
                -- Jalankan operasi nyata (blocking dalam coroutine ini)
                ok, value = pcall(step.Run)
                if not ok then
                    errMsg = tostring(value)
                    value  = nil
                end
            else
                -- Step kosmetik: tunggu sebentar agar user sempat baca
                task.wait(COSMETIC_DELAY)
            end

            results[i] = { ok = ok, value = value, err = errMsg }

            -- Advance progress bar setelah step selesai
            local pct = i / totalSteps
            Tween.slow(fill, { Size = UDim2.new(pct, 0, 1, 0) })

            -- Jeda minimal antar step agar transisi progress terlihat (tidak menahan)
            if i < totalSteps then
                task.wait(0.04)
            end
        end

        -- Semua step selesai — jeda kecil lalu exit
        task.wait(0.2)

        -- Callback hasil opsional
        if onResult then
            pcall(onResult, results)
        end

        -- Slide up + fade out seluruh card sekaligus via GroupTransparency
        Tween.play(card, {
            GroupTransparency = 1,
            Position = UDim2.new(0.5, -155, 0.5, -24),
        }, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
        task.delay(0.32, function()
            pcall(function() card:Destroy() end)
            onDone()  -- onDone memanggil win:Show() yang sudah punya animasi
        end)
    end)
end
