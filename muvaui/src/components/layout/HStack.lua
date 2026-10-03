-- HStack: susun komponen secara horizontal
Section.AddHStack = function(self, opts)
    opts = opts or {}

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size                   = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize          = Enum.AutomaticSize.Y
    frame.LayoutOrder            = #self._components + 10
    frame.Parent                 = self._frame

    local layout = Instance.new("UIListLayout")
    layout.FillDirection        = Enum.FillDirection.Horizontal
    layout.VerticalAlignment    = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment  = Enum.HorizontalAlignment.Left
    layout.Wraps                = opts.Wrap ~= false
    layout.Padding              = UDim.new(0, opts.Gap or 6)
    layout.Parent               = frame

    -- HStack exposes the same AddX methods as Section
    -- by proxying through a lightweight wrapper that parents to this frame
    local stack = setmetatable({}, { __index = self })
    stack._frame      = frame
    stack._components = {}
    stack._flags      = self._flags

    table.insert(self._components, frame)
    return stack
end
