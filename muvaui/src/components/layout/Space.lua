-- Space: gap kosong manual antar komponen
Section.AddSpace = function(self, height)
    height = height or 8

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size                   = UDim2.new(1, 0, 0, height)
    frame.LayoutOrder            = #self._components + 10
    frame.Parent                 = self._frame

    table.insert(self._components, frame)
    return frame
end
