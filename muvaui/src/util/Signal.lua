-- Signal: simple event emitter, pengganti RBXScriptSignal untuk internal use
Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({ _listeners = {} }, Signal)
end

function Signal:Connect(fn)
    local id = #self._listeners + 1
    self._listeners[id] = fn
    return {
        Disconnect = function()
            self._listeners[id] = nil
        end
    }
end

function Signal:Fire(...)
    for _, fn in pairs(self._listeners) do
        pcall(fn, ...)
    end
end

function Signal:DisconnectAll()
    self._listeners = {}
end
