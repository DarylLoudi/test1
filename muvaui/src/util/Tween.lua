-- Tween: shorthand helpers untuk TweenService
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

Tween = {}

-- ── bindTap: deteksi TAP (klik nyata) vs DRAG/SCROLL ────────────────
-- Card berada DI DALAM ScrollingFrame. Memakai card.InputBegan (flip saat ditekan)
-- atau card.InputEnded itu rapuh: ScrollingFrame menelan gesture scroll sehingga
-- event Frame & InputChanged tak konsisten → toggle nyala saat scroll.
--
-- PENDEKATAN KOKOH (tak bergantung event Frame/ScrollingFrame sama sekali):
--   • InputBegan card hanya MENANDAI kandidat + simpan posisi pointer awal.
--   • Keputusan tap diambil di UserInputService.InputEnded GLOBAL (selalu fire,
--     posisi pointer selalu valid, TIDAK ditelan ScrollingFrame).
--   • Tap valid HANYA jika SEMUA benar:
--       1) jarak pointer awal→akhir < TAP_MOVE_MAX (tak menyeret),
--       2) DAN titik lepas masih DI DALAM kotak card (AbsolutePosition/Size),
--          dgn cek visibility (tak ter-clip keluar viewport ScrollingFrame).
--   Scroll = pointer berpindah jauh ATAU lepas di luar card → BUKAN tap.
local TAP_MOVE_MAX = 6   -- piksel; perpindahan pointer ≥ ini = drag/scroll (batal)

-- true kalau titik layar p ada di dalam kotak absolut gui. Pakai AbsolutePosition/
-- AbsoluteSize (koordinat layar). Size 0 → gui tak ter-render → selalu false.
local function pointInGui(gui, p)
    local pos  = gui.AbsolutePosition
    local size = gui.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then return false end
    return p.X >= pos.X and p.X <= pos.X + size.X
       and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
end

function Tween.bindTap(gui, onTap)
    gui.Active = true
    local armed, startPos = false, nil

    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            armed    = true
            startPos = Vector2.new(input.Position.X, input.Position.Y)
        end
    end)

    -- Keputusan di UIS global: fire utk SEMUA pelepasan klik/sentuh di mana pun.
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if not armed then return end
        armed = false
        if not startPos then return end

        local endPos = Vector2.new(input.Position.X, input.Position.Y)

        -- 1) Pointer menyeret jauh → scroll/drag, bukan tap.
        local d = endPos - startPos
        if math.abs(d.X) >= TAP_MOVE_MAX or math.abs(d.Y) >= TAP_MOVE_MAX then
            return
        end

        -- 2) Titik lepas harus masih di dalam card. Saat scroll, card ikut
        --    bergeser → titik lepas jatuh di luar kotak card sekarang → batal.
        --    (Juga mencegah flip kalau jari diangkat di luar card.)
        if not pointInGui(gui, endPos) then return end

        onTap()
    end)
end

-- Lazy-init TweenInfo objects to avoid top-level Enum access issues
local _D, _F, _S, _SP

local function getInfos()
    if not _D then
        _D  = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        _F  = TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        _S  = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        _SP = TweenInfo.new(0.3,  Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
    end
end

function Tween.play(instance, props, tweenInfo)
    getInfos()
    local t = TweenService:Create(instance, tweenInfo or _D, props)
    t:Play()
    return t
end

function Tween.fast(instance, props)
    getInfos()
    return Tween.play(instance, props, _F)
end

function Tween.slow(instance, props)
    getInfos()
    return Tween.play(instance, props, _S)
end

function Tween.spring(instance, props)
    getInfos()
    return Tween.play(instance, props, _SP)
end

-- Fade in a GuiObject (BackgroundTransparency + TextTransparency)
function Tween.fadeIn(obj, duration)
    local info = TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
        Tween.play(obj, { BackgroundTransparency = 0 }, info)
    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
        Tween.play(obj, { TextTransparency = 0, BackgroundTransparency = 0 }, info)
    elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
        Tween.play(obj, { ImageTransparency = 0, BackgroundTransparency = 0 }, info)
    end
end

function Tween.fadeOut(obj, duration)
    local info = TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
        Tween.play(obj, { BackgroundTransparency = 1 }, info)
    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
        Tween.play(obj, { TextTransparency = 1, BackgroundTransparency = 1 }, info)
    elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
        Tween.play(obj, { ImageTransparency = 1, BackgroundTransparency = 1 }, info)
    end
end
