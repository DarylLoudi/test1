--[[
    ════════════════════════════════════════════════════════════════════
    MuvaUI — STUDIO SHOWCASE HARNESS
    ════════════════════════════════════════════════════════════════════
    Tujuan: lihat SEMUA komponen MuvaUI dalam satu window saat menekan Play
    di Roblox Studio — TANPA executor, TANPA re-inject. Edit src/ → build →
    Play (F5) → lihat hasil dalam ~2 detik.

    SETUP (lihat studio/STUDIO_SETUP.md untuk detail):
      1. StarterPlayer > StarterPlayerScripts:
           • LocalScript ini  (MuvaUI_Showcase)
           • ModuleScript bernama "MuvaUI"  ← isi = muvaui/MuvaUI.lua hasil build
      2. Play (F5).

    Script ini me-require ModuleScript "MuvaUI" (sibling), bukan loadstring,
    supaya Studio bisa debug penuh (Output + stack asli + Explorer live).
    ════════════════════════════════════════════════════════════════════
--]]

warn("[Showcase] ===== LocalScript MULAI berjalan =====")  -- beacon: kalau ini tak muncul, script tak dieksekusi (cek tab Client di Output)

local LocalPlayer = game:GetService("Players").LocalPlayer

-- Resolve ModuleScript MuvaUI (sibling di StarterPlayerScripts → PlayerScripts).
local function resolveMuvaUI()
    -- saat runtime, StarterPlayerScripts disalin ke Player.PlayerScripts
    local scripts = LocalPlayer:WaitForChild("PlayerScripts")
    local mod = scripts:FindFirstChild("MuvaUI")
    if not mod then
        -- fallback: cari di mana pun (mis. ditaruh di ReplicatedStorage)
        mod = game:GetService("ReplicatedStorage"):FindFirstChild("MuvaUI")
    end
    return mod
end

local mod = resolveMuvaUI()
if not mod then
    warn("[Showcase] ModuleScript 'MuvaUI' tidak ditemukan. Taruh hasil build "
        .. "muvaui/MuvaUI.lua sebagai ModuleScript bernama 'MuvaUI' di "
        .. "StarterPlayerScripts (sibling LocalScript ini).")
    return
end

-- VERIFIKASI VERSI: baca timestamp build dari .Source ModuleScript. Kalau
-- timestamp ini TIDAK cocok dgn build terbaru di disk → ModuleScript di Studio
-- masih versi LAMA (paste belum berhasil) → itu sebab perubahan tak muncul.
pcall(function()
    local src = mod.Source
    local built = src and src:match("Built:%s*([%d%-: ]+)")
    warn("[Showcase] MuvaUI build di Studio = " .. (built or "??? (tak terbaca)"))
end)

local MuvaUI = require(mod)
if not MuvaUI then
    warn("[Showcase] require(MuvaUI) return nil — cek Output untuk error init.")
    return
end

-- Data dummy utk dropdown.
local FRUITS = { "Strawberry", "Blueberry", "Bamboo", "Tomato", "Apple", "Corn", "Cactus" }

-- Tanpa Key / BuildTabs → CreateWindow me-RETURN window langsung (lihat Library.lua
-- path `else: return buildWindow()`). Itu yang kita pakai utk bangun tab manual.
local win = MuvaUI:CreateWindow({
    Title    = "MuvaUI Showcase",
    SubTitle = "Studio Harness",
})

if not win then
    warn("[Showcase] Window tidak ter-spawn (return nil). Kemungkinan Key/BuildTabs "
        .. "aktif tanpa sengaja, atau error init — cek Output.")
    return
end

-- ════════════════════════════════════════════════════════════════════
-- TAB 1 — INPUTS (semua komponen input)
-- ════════════════════════════════════════════════════════════════════
local tabInputs = win:AddTab({ Title = "Inputs" })

local secToggle = tabInputs:AddSection({ Title = "Toggles & Checkbox" })
secToggle:AddToggle({ ID = "sc_toggle1", Title = "Auto Farm", Desc = "Aktifkan auto farm", Default = true,
    Callback = function(v) print("[Showcase] toggle1:", v) end })
secToggle:AddToggle({ ID = "sc_toggle2", Title = "Notifications", Desc = "Toggle tanpa default", Default = false,
    Callback = function(v) print("[Showcase] toggle2:", v) end })
secToggle:AddCheckbox({ ID = "sc_check1", Title = "Confirm action", Default = false,
    Callback = function(v) print("[Showcase] check1:", v) end })

local secSliders = tabInputs:AddSection({ Title = "Sliders & Numbers" })
secSliders:AddSlider({ ID = "sc_slider1", Title = "Walk Speed", Min = 16, Max = 200, Step = 1, Default = 50, Suffix = " sps",
    Callback = function(v) print("[Showcase] slider1:", v) end })
secSliders:AddSlider({ ID = "sc_slider2", Title = "Volume", Min = 0, Max = 100, Step = 5, Default = 75, Suffix = "%",
    Callback = function(v) print("[Showcase] slider2:", v) end })
secSliders:AddNumberInput({ ID = "sc_num1", Title = "Quantity", Min = 0, Max = 999, Step = 1, Default = 10,
    Callback = function(v) print("[Showcase] num1:", v) end })

local secText = tabInputs:AddSection({ Title = "Text Inputs" })
secText:AddTextInput({ ID = "sc_text1", Title = "Username", Placeholder = "Enter name…", Default = "",
    Callback = function(v) print("[Showcase] text1:", v) end })
secText:AddTextarea({ ID = "sc_area1", Title = "Notes", Placeholder = "Multi-line…", Default = "",
    Callback = function(v) print("[Showcase] area1:", v) end })

local secDrop = tabInputs:AddSection({ Title = "Dropdowns & Keybind" })
secDrop:AddDropdown({ ID = "sc_drop1", Title = "Select Fruit", Options = FRUITS, Default = "Bamboo", Searchable = true,
    Callback = function(v) print("[Showcase] drop1:", v) end })
secDrop:AddMultiDropdown({ ID = "sc_mdrop1", Title = "Harvest Items", Options = FRUITS, Default = { "Strawberry", "Bamboo" },
    Callback = function(v) print("[Showcase] mdrop1:", v) end })
secDrop:AddKeybind({ ID = "sc_key1", Title = "Toggle UI", Default = Enum.KeyCode.RightShift,
    Callback = function() print("[Showcase] keybind fired") end })
secDrop:AddColorPicker({ ID = "sc_color1", Title = "Accent Color", Default = Color3.fromRGB(168, 85, 247),
    Callback = function(c) print("[Showcase] color1:", c) end })

-- ════════════════════════════════════════════════════════════════════
-- TAB 2 — DISPLAY (komponen tampilan)
-- ════════════════════════════════════════════════════════════════════
local tabDisplay = win:AddTab({ Title = "Display" })

local secBtn = tabDisplay:AddSection({ Title = "Buttons" })
secBtn:AddButton({ Title = "Primary Action", Desc = "Gradient accent CTA", Style = "Default",
    Callback = function() MuvaUI:Notify({ Title = "Clicked", Body = "Primary button", Type = "info", Duration = 2 }) end })
secBtn:AddButton({ Title = "Ghost / Secondary", Style = "Ghost",
    Callback = function() print("[Showcase] ghost") end })
secBtn:AddButton({ Title = "Success", Style = "Success",
    Callback = function() MuvaUI:Notify({ Title = "Saved", Type = "success", Duration = 2 }) end })
secBtn:AddButton({ Title = "Danger", Style = "Danger",
    Callback = function() MuvaUI:Notify({ Title = "Deleted", Type = "error", Duration = 2 }) end })
secBtn:AddButton({ Title = "Warn", Style = "Warn",
    Callback = function() print("[Showcase] warn") end })

local secInfo = tabDisplay:AddSection({ Title = "Text & Info" })
secInfo:AddParagraph({ Title = "About", Body = "MuvaUI showcase — semua komponen ada di sini untuk iterasi visual cepat di Studio." })
secInfo:AddBadge({ Title = "Status", Value = "Online", Color = Color3.fromRGB(34, 197, 94) })
secInfo:AddTag({ Title = "Tags", Tags = { "fast", "modern", "dark" }, Removable = false })
secInfo:AddDivider({})
secInfo:AddProgressBar({ Title = "Loading", Value = 0.65 })

local secAcc = tabDisplay:AddSection({ Title = "Layout" })
secAcc:AddAccordion({ Title = "Expandable section", Open = false })

-- ════════════════════════════════════════════════════════════════════
-- TAB 3 — THEME (uji accent / overlay)
-- ════════════════════════════════════════════════════════════════════
local tabTheme = win:AddTab({ Title = "Theme" })
local secTheme = tabTheme:AddSection({ Title = "Accent & Overlays" })

local ACCENTS = {
    { "Purple", Color3.fromRGB(168, 85, 247) },
    { "Blue",   Color3.fromRGB(96, 165, 250) },
    { "Green",  Color3.fromRGB(34, 197, 94) },
    { "Pink",   Color3.fromRGB(236, 72, 153) },
    { "Orange", Color3.fromRGB(249, 115, 22) },
}
for _, a in ipairs(ACCENTS) do
    secTheme:AddButton({ Title = "Accent: " .. a[1], Style = "Ghost",
        Callback = function() MuvaUI:SetAccent(a[2]) end })
end

secTheme:AddButton({ Title = "Test Toast (success)",
    Callback = function() MuvaUI:Notify({ Title = "Success", Body = "Operasi berhasil!", Type = "success", Duration = 3 }) end })
secTheme:AddButton({ Title = "Test Toast (error)",
    Callback = function() MuvaUI:Notify({ Title = "Error", Body = "Sesuatu gagal.", Type = "error", Duration = 3 }) end })

-- PENTING: window dibuat dgn GroupTransparency=1 (invisible) & baru terlihat
-- setelah win:Show(). Path CreateWindow biasa (tanpa BuildTabs) TIDAK memanggil
-- Show otomatis (itu hanya di path BuildTabs/LoadingScreen yg dipakai production).
-- Jadi di harness kita panggil manual supaya window tampil.
if win.Show then pcall(function() win:Show() end) end

print("[Showcase] MuvaUI showcase siap — 3 tab, semua komponen. Edit src/, build, Play lagi.")

-- ── DIAGNOSTIK 2: pantau perubahan Size win (siapa yg menyusutkan?) ───
do
    local w = win._win
    if w then
        warn(("[DIAG-INIT] Size awal=%s AbsSize=%s"):format(tostring(w.Size), tostring(w.AbsoluteSize)))
        w:GetPropertyChangedSignal("Size"):Connect(function()
            warn(("[DIAG-SIZE] Size BERUBAH → %s  (stack: %s)"):format(
                tostring(w.Size), debug.traceback("", 2)))
        end)
        -- coba PAKSA ukuran benar setelah 0.5s; kalau tetap balik ke 1×1,
        -- berarti ada yg terus-menerus meng-overwrite.
        task.delay(0.5, function()
            w.Size = UDim2.fromOffset(680, 480)
            warn("[DIAG-FORCE] Size dipaksa ke 680x480")
        end)
    end
end

-- ── DIAGNOSTIK: dump kondisi window utk cari kenapa tak terlihat ──────
task.delay(1, function()
    local w = win._win
    if not w then warn("[DIAG] win._win = nil!"); return end
    warn(("[DIAG] win._win: Class=%s Visible=%s GroupTransp=%.2f"):format(
        w.ClassName, tostring(w.Visible), w.GroupTransparency))
    warn(("[DIAG] Size=%s Position=%s"):format(tostring(w.Size), tostring(w.Position)))
    warn(("[DIAG] AbsPos=%s AbsSize=%s"):format(tostring(w.AbsolutePosition), tostring(w.AbsoluteSize)))
    local sg = w.Parent
    warn(("[DIAG] Parent=%s (%s)  Enabled=%s"):format(
        sg and sg.Name or "nil",
        sg and sg.ClassName or "?",
        sg and sg:IsA("ScreenGui") and tostring(sg.Enabled) or "n/a"))
    -- UIScale (responsive fit) bisa membuat scale 0
    local us = w:FindFirstChildOfClass("UIScale")
    warn(("[DIAG] UIScale=%s"):format(us and tostring(us.Scale) or "none"))
    -- viewport
    local cam = workspace.CurrentCamera
    warn(("[DIAG] Viewport=%s"):format(cam and tostring(cam.ViewportSize) or "no cam"))
end)
