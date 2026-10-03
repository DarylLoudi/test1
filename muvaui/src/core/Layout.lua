-- Layout: design tokens terpusat — satu-satunya sumber kebenaran angka layout
-- Semua komponen wajib baca dari sini, bukan hardcode angka sendiri.
Layout = {}

-- ════════════════════════════════════════════════════════════════════
-- SKALA KOMPAK (feedback user, kalibrasi ala hub modern): skala 1.35×
-- lama DIBATALKAN — komponen dirampingkan mendekati proporsi referensi.
-- Layar sempit tetap aman: UIScale window menyesuaikan otomatis.
-- ════════════════════════════════════════════════════════════════════

-- Card
Layout.CARD_H     = 46   -- tinggi standar card komponen
Layout.CARD_RADIUS= 10   -- sudut
Layout.PAD_X      = 14   -- padding kiri/kanan card
Layout.PAD_Y      = 9    -- padding atas/bawah card
Layout.GAP_CARD   = 6    -- jarak antar card

-- Teks
Layout.TITLE_SIZE = 15
Layout.DESC_SIZE  = 13
Layout.VALUE_SIZE = 14
Layout.CODE_SIZE  = 13
Layout.GAP_INFO   = 2    -- jarak title↔desc

-- Elemen kontrol
Layout.TOGGLE_W   = 44   -- lebar track toggle
Layout.TOGGLE_RES = 62   -- reserve width info block saat ada toggle
Layout.CTRL_H     = 28   -- tinggi kontrol kecil (input & trigger dropdown)
Layout.CTRL_W     = 130  -- lebar DEFAULT kontrol kanan: input textbox &
                         -- trigger dropdown SAMA persis (konsisten, ala hub)
Layout.GAP_ROW    = 8    -- padding horizontal dalam card

-- Auto-size guards
Layout.CARD_MIN_H     = 46   -- tinggi tetap eksplisit (Dropdown/MultiDropdown/TextInput via lockHeight)
Layout.CARD_FLOOR_H   = 42   -- lantai MINIMUM untuk card auto-height generik (Toggle/Checkbox/dst)
                             -- = PAD_Y*2 + tinggi toggle track (24) — cukup utk kontrol kanan
                             -- tanpa memotongnya, tapi tak memaksa card sepenuh CARD_MIN_H saat
                             -- title tidak punya Desc (mis. toggle tanpa deskripsi).
Layout.BTN_H      = 30   -- tinggi button aksi
Layout.BTN_MIN_W  = 72   -- lebar minimum button
Layout.BTN_MAX_W  = 200  -- lebar maksimum button
Layout.BTN_PAD_X  = 12   -- padding kiri/kanan dalam button

-- Font
Layout.FONT_TITLE = Enum.Font.GothamMedium
Layout.FONT_BODY  = Enum.Font.Gotham
Layout.FONT_BOLD  = Enum.Font.GothamBold

-- Helper: jadikan sebuah Frame auto-tinggi dengan lantai minimum.
-- Dipakai card & info block agar tumbuh mengikuti konten tapi tidak lebih pendek dari minH.
-- Constraint disimpan di frame:FindFirstChild("AutoHeightConstraint") agar bisa di-override
-- oleh komponen yang butuh tinggi fix (lihat Layout.lockHeight).
function Layout.applyAutoHeight(frame, minH)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    local c = Instance.new("UISizeConstraint")
    c.Name    = "AutoHeightConstraint"
    c.MinSize = Vector2.new(0, minH or Layout.CARD_MIN_H)
    c.MaxSize = Vector2.new(math.huge, math.huge)
    c.Parent  = frame
    return c
end

-- Helper: paksa tinggi fix pada card yang sudah dapat applyAutoHeight.
-- Dipakai komponen vertikal (Slider, TextInput) yang punya layout internal sendiri
-- dengan absolute positioning, sehingga AutomaticSize.Y tidak boleh aktif.
function Layout.lockHeight(frame, h)
    frame.AutomaticSize = Enum.AutomaticSize.None
    frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, h)
    local c = frame:FindFirstChild("AutoHeightConstraint")
    if c then
        c.MinSize = Vector2.new(0, h)
        c.MaxSize = Vector2.new(math.huge, h)
    end
end

-- Helper: TextButton dengan lebar TETAP = maxW, tinggi auto mengikuti teks wrap.
-- Lebar tetap (bukan AutomaticSize.X) supaya wrap dapat diprediksi & button tidak
-- terdorong keluar parent. Teks panjang turun ke baris berikutnya, tinggi card ikut.
function Layout.fitButton(btn, minW, maxW)
    local w = maxW or Layout.BTN_MAX_W
    btn.AutomaticSize = Enum.AutomaticSize.Y
    btn.TextWrapped   = true
    btn.Size          = UDim2.fromOffset(w, Layout.BTN_H)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, Layout.BTN_PAD_X)
    pad.PaddingRight  = UDim.new(0, Layout.BTN_PAD_X)
    pad.PaddingTop    = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)
    pad.Parent        = btn
    local c = Instance.new("UISizeConstraint")
    c.MinSize = Vector2.new(w, Layout.BTN_H)
    c.MaxSize = Vector2.new(w, math.huge)
    c.Parent  = btn
    return c
end
