-- Table: data grid dengan sortable header dan search
Section.AddTable = function(self, opts)
    assert(type(opts) == "table", "AddTable: opts must be a table")
    local columns    = opts.Columns   or {}
    local pageSize   = opts.PageSize  or 20
    local searchable = opts.Searchable ~= false

    local card, stroke = self:_makeCard()
    card.Size             = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize    = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Theme:BG(0)
    card.ClipsDescendants = false

    -- Remove default padding from card
    for _, c in ipairs(card:GetChildren()) do
        if c:IsA("UIPadding") then c:Destroy() end
    end

    local col = Instance.new("UIListLayout")
    col.FillDirection = Enum.FillDirection.Vertical
    col.SortOrder     = Enum.SortOrder.LayoutOrder
    col.Parent        = card

    -- Toolbar (search + count)
    local toolbar = Instance.new("Frame")
    toolbar.BackgroundColor3 = Theme:BG(1)
    toolbar.BorderSizePixel  = 0
    toolbar.Size             = UDim2.new(1, 0, 0, 34)
    toolbar.LayoutOrder      = 1
    toolbar.Parent           = card

    local tbDiv = Instance.new("Frame")
    tbDiv.BackgroundColor3 = Theme:Border(0)
    tbDiv.BorderSizePixel  = 0
    tbDiv.Size             = UDim2.new(1, 0, 0, 1)
    tbDiv.Position         = UDim2.new(0, 0, 1, -1)
    tbDiv.Parent           = toolbar

    local tbPad = Instance.new("UIPadding")
    tbPad.PaddingLeft   = UDim.new(0, 10)
    tbPad.PaddingRight  = UDim.new(0, 10)
    tbPad.PaddingTop    = UDim.new(0, 6)
    tbPad.PaddingBottom = UDim.new(0, 6)
    tbPad.Parent        = toolbar

    local searchBox = nil
    if searchable then
        searchBox = Instance.new("TextBox")
        searchBox.BackgroundColor3  = Theme:BG(2)
        searchBox.BorderSizePixel   = 0
        searchBox.Size              = UDim2.new(0.6, 0, 1, 0)
        searchBox.PlaceholderText   = "Search..."
        searchBox.PlaceholderColor3 = Theme:Text(4)
        searchBox.Text              = ""
        searchBox.Font              = Enum.Font.Gotham
        searchBox.TextSize          = 11
        searchBox.TextColor3        = Theme:Text(0)
        searchBox.ClearTextOnFocus  = false
        searchBox.Parent            = toolbar

        local sCorner = Instance.new("UICorner")
        sCorner.CornerRadius = UDim.new(0, 5)
        sCorner.Parent       = searchBox

        local sStroke = Instance.new("UIStroke")
        sStroke.Color     = Theme:Border(1)
        sStroke.Thickness = 1
        sStroke.Parent    = searchBox

        local sPad = Instance.new("UIPadding")
        sPad.PaddingLeft  = UDim.new(0, 8)
        sPad.PaddingRight = UDim.new(0, 8)
        sPad.Parent       = searchBox

        searchBox.Focused:Connect(function() sStroke.Color = Theme:Accent() end)
        searchBox.FocusLost:Connect(function() sStroke.Color = Theme:Border(1) end)
    end

    local countLbl = Instance.new("TextLabel")
    countLbl.BackgroundTransparency = 1
    countLbl.Size                   = UDim2.new(searchable and 0.4 or 1, 0, 1, 0)
    countLbl.Position               = UDim2.new(searchable and 0.6 or 0, 0, 0, 0)
    countLbl.Text                   = "0 rows"
    countLbl.Font                   = Enum.Font.Gotham
    countLbl.TextSize               = 13
    countLbl.TextColor3             = Theme:Text(3)
    countLbl.TextXAlignment         = Enum.TextXAlignment.Right
    countLbl.Parent                 = toolbar

    -- Header row
    local header = Instance.new("Frame")
    header.BackgroundColor3 = Theme:BG(1)
    header.BorderSizePixel  = 0
    header.Size             = UDim2.new(1, 0, 0, 28)
    header.LayoutOrder      = 2
    header.Parent           = card

    local headerDiv = Instance.new("Frame")
    headerDiv.BackgroundColor3 = Color.fromHex("#2a2a3a")
    headerDiv.BorderSizePixel  = 0
    headerDiv.Size             = UDim2.new(1, 0, 0, 1)
    headerDiv.Position         = UDim2.new(0, 0, 1, -1)
    headerDiv.Parent           = header

    local headerRow = Instance.new("UIListLayout")
    headerRow.FillDirection = Enum.FillDirection.Horizontal
    headerRow.SortOrder     = Enum.SortOrder.LayoutOrder
    headerRow.Parent        = header

    -- Body scroll
    local body = Instance.new("ScrollingFrame")
    body.BackgroundTransparency = 1
    body.BorderSizePixel        = 0
    body.Size                   = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize          = Enum.AutomaticSize.None
    body.CanvasSize             = UDim2.new(0, 0, 0, 0)
    body.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    body.ScrollBarThickness     = 2
    body.ScrollBarImageColor3   = Theme:BG(4)
    body.LayoutOrder            = 3
    body.Parent                 = card

    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.FillDirection = Enum.FillDirection.Vertical
    bodyLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    bodyLayout.Parent        = body

    -- State
    local allRows   = opts.Rows or {}
    local sortCol   = nil
    local sortAsc   = true
    local headerBtns = {}

    -- Build header cells
    local colWidth = 1 / math.max(#columns, 1)
    for i, colDef in ipairs(columns) do
        local cell = Instance.new("TextButton")
        cell.BackgroundTransparency = 1
        cell.BorderSizePixel        = 0
        cell.Size                   = UDim2.new(colWidth, 0, 1, 0)
        cell.LayoutOrder            = i
        cell.Text                   = ""
        cell.AutoButtonColor        = false
        cell.Parent                 = header

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft  = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 4)
        pad.Parent       = cell

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size                   = UDim2.new(1, -12, 1, 0)
        lbl.Text                   = (colDef.Label or colDef.Key):upper()
        lbl.Font                   = Enum.Font.GothamBold
        lbl.TextSize               = 12
        lbl.TextColor3             = Theme:Accent()
        lbl.TextXAlignment         = Enum.TextXAlignment.Left
        lbl.Parent                 = cell

        local arrow = Instance.new("TextLabel")
        arrow.BackgroundTransparency = 1
        arrow.Size                   = UDim2.fromOffset(10, 28)
        arrow.Position               = UDim2.new(1, -10, 0, 0)
        arrow.Text                   = ""
        arrow.Font                   = Enum.Font.GothamBold
        arrow.TextSize               = 8
        arrow.TextColor3             = Theme:Accent()
        arrow.Parent                 = cell

        headerBtns[i] = { cell = cell, arrow = arrow, key = colDef.Key }

        if colDef.Sortable ~= false then
            cell.MouseButton1Click:Connect(function()
                if sortCol == i then
                    sortAsc = not sortAsc
                else
                    sortCol = i
                    sortAsc = true
                end
                -- Update arrows (ASCII — glyph ▲▼ tofu-risk di sebagian device)
                for j, h in ipairs(headerBtns) do
                    h.arrow.Text = j == sortCol and (sortAsc and "^" or "v") or ""
                end
                renderRows()
            end)
            cell.MouseEnter:Connect(function()
                lbl.TextColor3 = Theme:Text(0)
            end)
            cell.MouseLeave:Connect(function()
                lbl.TextColor3 = Theme:Accent()
            end)
        end

        Theme:OnAccentChanged(function(a) lbl.TextColor3 = a end)
    end

    local function makeRowFrame(rowData, rowIndex)
        local rowFrame = Instance.new("Frame")
        rowFrame.BackgroundColor3 = rowIndex % 2 == 0 and Theme:BG(0) or Theme:BG(1)
        rowFrame.BorderSizePixel  = 0
        rowFrame.Size             = UDim2.new(1, 0, 0, 28)
        rowFrame.LayoutOrder      = rowIndex

        local rowDiv = Instance.new("Frame")
        rowDiv.BackgroundColor3 = Theme:Border(0)
        rowDiv.BorderSizePixel  = 0
        rowDiv.Size             = UDim2.new(1, 0, 0, 1)
        rowDiv.Position         = UDim2.new(0, 0, 1, -1)
        rowDiv.Parent           = rowFrame

        local rowLayout = Instance.new("UIListLayout")
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.SortOrder     = Enum.SortOrder.LayoutOrder
        rowLayout.Parent        = rowFrame

        -- Hover via Frame events (no overlay btn — would break UIListLayout)
        rowFrame.Active = true
        rowFrame.MouseEnter:Connect(function()
            Tween.fast(rowFrame, { BackgroundColor3 = Theme:BG(3) })
        end)
        rowFrame.MouseLeave:Connect(function()
            rowFrame.BackgroundColor3 = rowIndex % 2 == 0 and Theme:BG(0) or Theme:BG(1)
        end)

        for i, colDef in ipairs(columns) do
            local cell = Instance.new("TextLabel")
            cell.BackgroundTransparency = 1
            cell.BorderSizePixel        = 0
            cell.Size                   = UDim2.new(colWidth, 0, 1, 0)
            cell.LayoutOrder            = i
            cell.Font                   = i == 1 and Enum.Font.GothamBold or Enum.Font.Gotham
            cell.TextSize               = 13
            cell.TextColor3             = i == 1 and Theme:Text(0) or Theme:Text(2)
            cell.TextXAlignment         = Enum.TextXAlignment.Left
            cell.TextWrapped            = false
            cell.ClipsDescendants       = true
            cell.Parent                 = rowFrame

            local pad = Instance.new("UIPadding")
            pad.PaddingLeft  = UDim.new(0, 8)
            pad.PaddingRight = UDim.new(0, 4)
            pad.Parent       = cell

            local v = rowData[colDef.Key]
            cell.Text = tostring(v ~= nil and v or "")
        end

        return rowFrame
    end

    function renderRows()
        -- Clear existing rows
        for _, child in ipairs(body:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        -- Filter
        local query   = searchBox and searchBox.Text:lower() or ""
        local filtered = {}
        for _, row in ipairs(allRows) do
            if query == "" then
                table.insert(filtered, row)
            else
                for _, v in pairs(row) do
                    if tostring(v):lower():find(query, 1, true) then
                        table.insert(filtered, row)
                        break
                    end
                end
            end
        end

        -- Sort
        if sortCol then
            local key = columns[sortCol] and columns[sortCol].Key
            if key then
                table.sort(filtered, function(a, b)
                    local av, bv = tostring(a[key] or ""), tostring(b[key] or "")
                    local an, bn = tonumber(av), tonumber(bv)
                    if an and bn then
                        return sortAsc and an < bn or an > bn
                    end
                    return sortAsc and av < bv or av > bv
                end)
            end
        end

        -- Render up to pageSize
        local visible = math.min(#filtered, pageSize)
        for i = 1, visible do
            local f = makeRowFrame(filtered[i], i)
            f.Parent = body
        end

        -- Body height: max 8 rows visible
        local rowH     = 28
        local maxShow  = math.min(visible, 8)
        body.Size      = UDim2.new(1, 0, 0, maxShow * rowH)

        -- Count label
        if #filtered == #allRows then
            countLbl.Text = #allRows .. " row" .. (#allRows ~= 1 and "s" or "")
        else
            countLbl.Text = visible .. " / " .. #allRows
        end
    end

    if searchBox then
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            renderRows()
        end)
    end

    renderRows()

    -- Public API
    local obj = {}

    function obj:SetRows(rows)
        allRows = rows or {}
        renderRows()
    end

    function obj:AppendRow(row)
        table.insert(allRows, row)
        renderRows()
    end

    function obj:Clear()
        allRows = {}
        renderRows()
    end

    table.insert(self._components, card)
    return obj
end
