-- Color: helpers untuk konversi Color3, hex, RGB, HSV
Color = {}

function Color.fromHex(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1,2), 16) / 255
    local g = tonumber(hex:sub(3,4), 16) / 255
    local b = tonumber(hex:sub(5,6), 16) / 255
    return Color3.new(r, g, b)
end

function Color.toHex(color)
    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)
    return string.format("#%02X%02X%02X", r, g, b)
end

function Color.toRGB(color)
    return
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5)
end

-- Darken a Color3 by a given amount (0–1)
function Color.darken(color, amount)
    local h, s, v = Color3.toHSV(color)
    return Color3.fromHSV(h, s, math.max(0, v - amount))
end

-- Lighten a Color3 by a given amount (0–1)
function Color.lighten(color, amount)
    local h, s, v = Color3.toHSV(color)
    return Color3.fromHSV(h, s, math.min(1, v + amount))
end

-- Return Color3 with modified alpha-equivalent (for transparency UDim)
-- Since Color3 has no alpha, this returns the transparency value for UIs
function Color.toTransparency(alpha)
    return 1 - math.clamp(alpha, 0, 1)
end

-- Lerp between two Color3 values
function Color.lerp(a, b, t)
    return a:Lerp(b, t)
end
