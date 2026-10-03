-- Theme: accent color system dan semua warna UI
-- Semua komponen ambil warna dari sini, bukan hardcode

Theme = {}
Theme.__index = Theme

-- Default palette — "neo-glass / refined dark".
-- Background gelap dgn undertone biru-dingin (bukan abu netral) → terasa lebih
-- dalam & premium. Border tipis tapi naik kontras saat elevated. Teks confident.
Theme.Colors = {
    -- Backgrounds (cool blue-black, naik bertahap)
    BG0         = Color.fromHex("#08090d"),  -- paling dalam (di balik panel)
    BG1         = Color.fromHex("#0c0e14"),  -- panel / sidebar
    BG2         = Color.fromHex("#13151c"),  -- comp card
    BG3         = Color.fromHex("#1b1e27"),  -- hover / elevated
    BG4         = Color.fromHex("#272b37"),  -- track / kontrol bg

    -- Borders (subtle → crisp)
    Border0     = Color.fromHex("#1c1f29"),  -- subtle (card idle)
    Border1     = Color.fromHex("#2a2e3b"),  -- normal (hover)
    Border2     = Color.fromHex("#3a3f50"),  -- elevated/popup

    -- Text (confident hierarchy, dingin sedikit)
    Text0       = Color.fromHex("#f7f8fa"),  -- primary (titles)
    Text1       = Color.fromHex("#dfe2ea"),  -- secondary (labels)
    Text2       = Color.fromHex("#aab0c0"),  -- muted (values)
    Text3       = Color.fromHex("#7a8194"),  -- descriptions
    Text4       = Color.fromHex("#565d6e"),  -- placeholder / faint

    -- Semantic
    Success     = Color.fromHex("#34d399"),
    Error       = Color.fromHex("#fb7185"),
    Warn        = Color.fromHex("#fbbf24"),
    Info        = Color.fromHex("#60a5fa"),
}

-- Accent — violet elektrik, bisa diganti via MuvaUI:SetAccent()
Theme._accent     = Color.fromHex("#a06bff")
Theme._accentDark = Color.fromHex("#6d3df0")
Theme._listeners  = {}

function Theme:GetAccent()
    return self._accent
end

function Theme:GetAccentDark()
    return self._accentDark
end

-- Transparency helpers (0 = opaque, 1 = invisible)
function Theme:AccentTrans(alpha)
    -- returns transparency value for UIStroke/BackgroundTransparency
    return Color.toTransparency(alpha)
end

function Theme:SetAccent(color)
    self._accent     = color
    self._accentDark = Color.darken(color, 0.15)
    -- notify semua listeners (komponen yang sudah di-render)
    for _, fn in pairs(self._listeners) do
        pcall(fn, color, self._accentDark)
    end
end

function Theme:OnAccentChanged(fn)
    local id = #self._listeners + 1
    self._listeners[id] = fn
    return function()
        self._listeners[id] = nil
    end
end

-- Shorthand untuk warna yang sering dipakai
function Theme:Accent()       return self._accent end
function Theme:AccentDark()   return self._accentDark end
function Theme:BG(level)      return self.Colors["BG"     .. (level or 0)] end
function Theme:Text(level)    return self.Colors["Text"   .. (level or 0)] end
function Theme:Border(level)  return self.Colors["Border" .. (level or 0)] end
