-- ConfigSystem: tab otomatis untuk simpan/load preset konfigurasi
-- Data disimpan ke file JSON lokal via executor readfile/writefile
-- Dipanggil via Library:SetConfigSystem({ File = "myconfig.json", Slots = 3 })
ConfigSystem = {}

local HttpService = game:GetService("HttpService")
local SAVE_FILE_DEFAULT = "muvaui_configs.json"

local function loadAllConfigs(filename)
    local ok, content = pcall(readfile, filename)
    if not ok or not content or content == "" then return {} end
    local ok2, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if not ok2 or type(data) ~= "table" then return {} end
    return data
end

local function saveAllConfigs(filename, configs)
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(configs)
    end)
    if ok then
        pcall(writefile, filename, encoded)
    end
end

local function getTimestamp()
    return os.date and os.date("%Y-%m-%d %H:%M") or "just now"
end

function ConfigSystem.attach(win, config, flags)
    config = config or {}
    local saveFile = config.File or SAVE_FILE_DEFAULT
    local maxSlots = config.Slots or 5

    -- Add Config tab automatically
    local tab = win:AddTab({ Title = "Config" })
    local sec = tab:AddSection({ Title = "Saved Configurations" })

    local configsData = loadAllConfigs(saveFile)
    local slotCards   = {}

    local function getCurrentFlagValues()
        local snapshot = {}
        for id, flag in pairs(flags) do
            local val = flag.Value
            -- Only serialize simple types (bool, number, string)
            local t = type(val)
            if t == "boolean" or t == "number" or t == "string" then
                snapshot[id] = val
            end
        end
        return snapshot
    end

    local function applyFlagValues(snapshot)
        if type(snapshot) ~= "table" then return end
        for id, val in pairs(snapshot) do
            local flag = flags[id]
            if flag then
                flag:SetAndFire(val)
            end
        end
    end

    local function refreshSlots()
        -- Destroy existing slot cards
        for _, card in ipairs(slotCards) do
            pcall(function() card:Destroy() end)
        end
        slotCards = {}

        for i, slot in ipairs(configsData) do
            local card, stroke = sec:_makeCard()
            table.insert(slotCards, card)

            local row = Instance.new("UIListLayout")
            row.FillDirection     = Enum.FillDirection.Horizontal
            row.VerticalAlignment = Enum.VerticalAlignment.Center
            row.Padding           = UDim.new(0, 8)
            row.Parent            = card

            -- Icon slot = sprite (bukan emoji 📄 font warna sistem)
            local iconImg = Icons.new("file-text", 18, Theme:Text(2))
            iconImg.Parent = card

            -- Info
            local info = Instance.new("Frame")
            info.BackgroundTransparency = 1
            info.Size                   = UDim2.new(1, -130, 1, 0)
            info.Parent                 = card

            local infoLayout = Instance.new("UIListLayout")
            infoLayout.FillDirection     = Enum.FillDirection.Vertical
            infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        infoLayout.Padding          = UDim.new(0, Layout.GAP_INFO)
            infoLayout.Parent            = info

            local nameLbl = Instance.new("TextLabel")
            nameLbl.BackgroundTransparency = 1
            nameLbl.Size                   = UDim2.new(1, 0, 0, Layout.TITLE_SIZE)
            nameLbl.Text                   = slot.Name or ("Config " .. i)
            nameLbl.Font                   = Layout.FONT_TITLE
            nameLbl.TextSize               = Layout.VALUE_SIZE
            nameLbl.TextColor3             = Theme:Text(1)
            nameLbl.TextXAlignment         = Enum.TextXAlignment.Left
            nameLbl.Parent                 = info

            local metaLbl = Instance.new("TextLabel")
            metaLbl.BackgroundTransparency = 1
            metaLbl.Size                   = UDim2.new(1, 0, 0, Layout.DESC_SIZE)
            metaLbl.Text                   = "Last saved: " .. (slot.SavedAt or "never")
            metaLbl.Font                   = Layout.FONT_BODY
            metaLbl.TextSize               = Layout.DESC_SIZE
            metaLbl.TextColor3             = Theme:Text(4)
            metaLbl.TextXAlignment         = Enum.TextXAlignment.Left
            metaLbl.Parent                 = info

            -- Buttons
            local btnFrame = Instance.new("Frame")
            btnFrame.BackgroundTransparency = 1
            btnFrame.Size                   = UDim2.fromOffset(100, 26)
            btnFrame.LayoutOrder            = 99
            btnFrame.Parent                 = card

            local btnLayout = Instance.new("UIListLayout")
            btnLayout.FillDirection     = Enum.FillDirection.Horizontal
            btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            btnLayout.Padding           = UDim.new(0, 4)
            btnLayout.Parent            = btnFrame

            local function makeBtn(text, bgColor, textColor, callback)
                local btn = Instance.new("TextButton")
                btn.BackgroundColor3 = bgColor
                btn.BorderSizePixel  = 0
                btn.Size             = UDim2.fromOffset(46, 24)
                btn.Text             = text
                btn.Font             = Enum.Font.GothamBold
                btn.TextSize         = 10
                btn.TextColor3       = textColor
                btn.AutoButtonColor  = false
                btn.Parent           = btnFrame

                local bc = Instance.new("UICorner")
                bc.CornerRadius = UDim.new(0, 5)
                bc.Parent       = btn

                btn.MouseEnter:Connect(function()
                    Tween.fast(btn, { BackgroundColor3 = Color.lighten(bgColor, 0.08) })
                end)
                btn.MouseLeave:Connect(function()
                    Tween.fast(btn, { BackgroundColor3 = bgColor })
                end)
                btn.MouseButton1Click:Connect(function()
                    pcall(callback)
                end)
                return btn
            end

            makeBtn("Load", Theme:Accent(), Color3.new(1,1,1), function()
                applyFlagValues(slot.Data)
                Toast.show({ Title = "Loaded", Body = slot.Name .. " applied", Type = "success", Duration = 2 })
            end)

            makeBtn("Save", Theme:BG(4), Theme:Text(2), function()
                configsData[i].Data    = getCurrentFlagValues()
                configsData[i].SavedAt = getTimestamp()
                saveAllConfigs(saveFile, configsData)
                metaLbl.Text = "Last saved: " .. configsData[i].SavedAt
                Toast.show({ Title = "Saved", Body = slot.Name .. " updated", Type = "success", Duration = 2 })
            end)

            card.MouseEnter:Connect(function()
                Tween.fast(card, { BackgroundColor3 = Theme:BG(3) })
                stroke.Color = Theme:Border(1)
            end)
            card.MouseLeave:Connect(function()
                Tween.fast(card, { BackgroundColor3 = Theme:BG(2) })
                stroke.Color = Theme:Border(0)
            end)
        end
    end

    -- "+ New Config" button
    local newBtn = Instance.new("TextButton")
    newBtn.BackgroundColor3 = Theme:BG(2)
    newBtn.BorderSizePixel  = 0
    newBtn.Size             = UDim2.new(1, 0, 0, 36)
    newBtn.Text             = "+ New Config"
    newBtn.Font             = Enum.Font.GothamMedium
    newBtn.TextSize         = 13
    newBtn.TextColor3       = Theme:Text(3)
    newBtn.AutoButtonColor  = false
    newBtn.LayoutOrder      = 999
    newBtn.Parent           = sec._frame

    local newBtnCorner = Instance.new("UICorner")
    newBtnCorner.CornerRadius = UDim.new(0, 7)
    newBtnCorner.Parent       = newBtn

    local newBtnStroke = Instance.new("UIStroke")
    newBtnStroke.Color            = Theme:Border(0)
    newBtnStroke.Thickness        = 1
    newBtnStroke.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
    newBtnStroke.Parent           = newBtn

    newBtn.MouseEnter:Connect(function()
        Tween.fast(newBtn, { BackgroundColor3 = Theme:BG(3) })
        newBtnStroke.Color = Theme:Border(1)
        newBtn.TextColor3  = Theme:Accent()
    end)
    newBtn.MouseLeave:Connect(function()
        Tween.fast(newBtn, { BackgroundColor3 = Theme:BG(2) })
        newBtnStroke.Color = Theme:Border(0)
        newBtn.TextColor3  = Theme:Text(3)
    end)
    newBtn.MouseButton1Click:Connect(function()
        if #configsData >= maxSlots then
            Toast.show({ Title = "Limit Reached", Body = "Max " .. maxSlots .. " config slots", Type = "warn", Duration = 2 })
            return
        end
        -- (Icon per-slot dulu emoji acak — kini semua slot pakai sprite
        -- "file-text" di refreshSlots; field Icon tak dipakai lagi.)
        local newSlot = {
            Name    = "Config " .. (#configsData + 1),
            SavedAt = "never",
            Data    = {},
        }
        table.insert(configsData, newSlot)
        saveAllConfigs(saveFile, configsData)
        refreshSlots()
        Toast.show({ Title = "Created", Body = newSlot.Name .. " added", Type = "info", Duration = 2 })
    end)

    -- Initial render
    refreshSlots()
end
