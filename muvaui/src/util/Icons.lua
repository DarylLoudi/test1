-- Icons: sprite Lucide INTERNAL untuk chrome UI (close/check/search/spinner
-- dst) — pengganti glyph Unicode/emoji di TextLabel yang bermasalah di device:
--   • glyph non-ASCII (✕ ✓ ◐ ≡ →) tak ada di font Gotham → dirender KOTAK (tofu)
--   • emoji (🔍 🔔 ⚠ 📄) dirender font emoji warna sistem → tak bisa di-tint tema
-- Sumber SAMA dgn ikon tab: spritesheet Lucide 48px publik Roblox
-- (latte-soft/lucide-roblox). Data = { assetId, offsetX, offsetY }.
Icons = {}

Icons.Data = {
    x                  = { 16898613869, 869, 906 },
    check              = { 16898612819, 710, 869 },
    search             = { 16898613699, 918, 857 },
    menu               = { 16898613613, 49,  820 },
    info               = { 16898613509, 612, 869 },
    ["circle-check"]   = { 16898612819, 869, 955 },
    ["circle-x"]       = { 16898613044, 820, 306 },
    ["triangle-alert"] = { 16898613869, 967, 0   },
    ["arrow-right"]    = { 16898612629, 453, 820 },
    ["chevron-right"]  = { 16898612819, 869, 759 },  -- panah trigger dropdown
    loader             = { 16898613509, 771, 906 },   -- loader-circle (spinner)
    mouse              = { 16898613613, 563, 918 },   -- penanda card Button (klik)
    inbox              = { 16898613509, 918, 563 },
    lock               = { 16898613509, 918, 857 },
    zap                = { 16898613869, 918, 906 },
    ["file-text"]      = { 16898613353, 869, 355 },
}

-- Buat ImageLabel sprite ukuran px×px berwarna color (tintable, monokrom).
-- Position/AnchorPoint/ZIndex/Parent di-set pemanggil. Nama tak dikenal →
-- ImageLabel kosong (fail-safe: layout tetap, hanya ikon tak tampak).
function Icons.new(name, px, color)
    local d = Icons.Data[name]
    local img = Instance.new("ImageLabel")
    img.Name                   = "Ico_" .. tostring(name)
    img.BackgroundTransparency = 1
    img.Size                   = UDim2.fromOffset(px, px)
    if d then
        img.Image           = "rbxassetid://" .. tostring(d[1])
        img.ImageRectOffset = Vector2.new(d[2], d[3])
        img.ImageRectSize   = Vector2.new(48, 48)
    end
    if color then img.ImageColor3 = color end
    return img
end
