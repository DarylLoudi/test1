-- VStack: susun komponen secara vertikal (nested dalam section)
Section.AddVStack = function(self, opts)
    opts = opts or {}

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size                   = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize          = Enum.AutomaticSize.Y
    frame.LayoutOrder            = #self._components + 10
    frame.Parent                 = self._frame

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder     = Enum.SortOrder.LayoutOrder
    layout.Padding       = UDim.new(0, opts.Gap or 4)
    layout.Parent        = frame

    -- Proxy to Section so all AddX methods work
    local stack = setmetatable({}, { __index = self })
    stack._frame      = frame
    stack._components = {}
    stack._flags      = self._flags

    table.insert(self._components, frame)
    return stack
end
