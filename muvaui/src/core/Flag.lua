-- Flag: state container untuk setiap komponen interaktif
-- Diakses via MuvaUI.Flags["ComponentID"]
Flag = {}
Flag.__index = Flag

function Flag.new(id, defaultValue)
    return setmetatable({
        ID       = id,
        Value    = defaultValue,
        _signal  = Signal.new(),
    }, Flag)
end

-- Set value tanpa trigger callback
function Flag:Set(value)
    self.Value = value
end

-- Set value DAN trigger semua OnChanged listeners
function Flag:SetAndFire(value)
    self.Value = value
    self._signal:Fire(value)
end

-- Listen perubahan value
function Flag:OnChanged(fn)
    return self._signal:Connect(fn)
end

-- Internal: dipanggil oleh komponen saat user berinteraksi
function Flag:_fire(value)
    self.Value = value
    self._signal:Fire(value)
end
