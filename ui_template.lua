--[[
    ====================================================================
    MUIHUB - UI TEMPLATE (MuvaUI)
    ====================================================================
    Jembatan antara MuvaUI (library UI milik sendiri) dengan module game.
    Expose getgenv() yang stabil agar module game tidak perlu diubah:
      getgenv().MuiHub_Window   → MuvaUI Window
      getgenv().MuiHub_Notify   → router notifikasi (:Notify)
      getgenv().MuiHub_WindUI   → ALIAS lama MuiHub_Notify (kompat module
                                  game terbitan lama; jangan dipakai baru)
      getgenv().MuiHub_Tab<Nama> → Tab (API shim ringkas)
    Flow: MuiUI.Init(MuvaUI) → CreateWindow (Key=nil, no prompt) → BuildTabs
    (window hidden, runs in-blob bundle) → loading → OnReady.
    ====================================================================
--]]

local MuiUI = {}

-- ── Shim: bungkus Section MuvaUI jadi API ringkas utk module game ───
local function wrapSection(sec)
    local s = {}

    function s:Button(opts)
        return sec:AddButton({
            Title    = opts.Title or opts.Name or "",
            Desc     = opts.Desc or opts.Description or nil,
            Style    = "Default",
            Callback = opts.Callback or function() end,
        })
    end

    function s:Toggle(opts)
        return sec:AddToggle({
            ID       = opts.Flag or opts.Title or tostring(math.random(1e6)),
            Title    = opts.Title or "",
            Desc     = opts.Desc or opts.Description or nil,
            Default  = opts.Value or false,
            Callback = opts.Callback or function() end,
        })
    end

    -- ID = opts.Flag DULU, baru Title — alasannya sama persis dengan Input di
    -- bawah: restore config mencari kontrol lewat MuiHub_Flags[ID], jadi kalau
    -- ID-nya judul, memperhalus teks judul diam-diam memutus config tersimpan
    -- dari sliedernya (nilainya pulih di _G tapi knob di layar tidak ikut).
    -- Aman ke belakang: pemanggil lama tidak mengirim Flag, jadi tetap ke Title.
    function s:Slider(opts)
        return sec:AddSlider({
            ID       = opts.Flag or opts.Title or tostring(math.random(1e6)),
            Title    = opts.Title or "",
            Desc     = opts.Desc or nil,
            Min      = opts.Min or 0,
            Max      = opts.Max or 100,
            Step     = opts.Step or 1,
            Default  = opts.Default or opts.Value or 0,
            Suffix   = opts.Suffix or "",
            Callback = opts.Callback or function() end,
        })
    end

    -- ID = opts.Flag DULU, baru Title. Tanpa cabang Flag ini, satu-satunya
    -- pegangan untuk memulihkan isi kotak saat load config adalah judulnya —
    -- dan judul berubah setiap kali teksnya diperhalus, sehingga config yang
    -- tersimpan diam-diam berhenti terpasang ke layar. Toggle & MultiDropdown
    -- sudah memakai pola ini; Input/Textarea tertinggal.
    -- Aman ke belakang: pemanggil lama tidak mengirim Flag, jadi tetap ke Title.
    --
    -- ⚠ 2026-08-24 KRITIS: berkas produksi ini SEMPAT tertinggal dari
    -- src/modules/ui_template.lua — Toggle/Slider/MultiDropdown sudah
    -- diperbaiki di sana tapi Input/Textarea/Dropdown TIDAK ikut ter-deploy.
    -- Dibuktikan langsung di client hidup: kontrol Webhook URL, Kaitun Target,
    -- dan Dashboard API Key terdaftar di MuiHub_Flags dengan ID = JUDULNYA
    -- ("Webhook URL"), bukan Flag-nya ("SAE_WebhookUrl") — sehingga
    -- setVisual/SetAndFire dari registerCfg tak pernah menemukan kotaknya, dan
    -- isinya tetap kosong di layar walau NILAINYA tersimpan benar di file dan
    -- LOGIKANYA berjalan benar. Kalau kelak ada shim baru di sini, WAJIB samakan
    -- dengan src/modules/ui_template.lua — dua salinan ini gampang menyimpang
    -- karena tidak ada tes paritas otomatis di antara keduanya.
    function s:Input(opts)
        return sec:AddTextInput({
            ID          = opts.Flag or opts.Title or tostring(math.random(1e6)),
            Title       = opts.Title or "",
            Desc        = opts.Desc or nil,
            Placeholder = opts.Placeholder or "",
            Default     = opts.Value or "",
            Width       = opts.Width or nil,
            Align       = opts.Align or nil,
            Callback    = opts.Callback or function() end,
        })
    end

    -- Textarea: input multi-baris (MultiLine + TextWrapped, kotak tinggi). WAJIB
    -- dipakai utk paste teks panjang (mis. Import Config JSON ~3000+ char) —
    -- :Input single-line memotong paste panjang di executor mobile → JSON terpotong.
    function s:Textarea(opts)
        return sec:AddTextarea({
            ID          = opts.Flag or opts.Title or tostring(math.random(1e6)),
            Title       = opts.Title or "",
            Desc        = opts.Desc or nil,
            Placeholder = opts.Placeholder or "",
            Default     = opts.Value or "",
            Callback    = opts.Callback or function() end,
        })
    end

    -- ID = opts.Flag DULU (alasan sama seperti Input/Textarea di atas).
    -- Aman ke belakang: pemanggil lama tak mengirim Flag.
    function s:Dropdown(opts)
        return sec:AddDropdown({
            ID       = opts.Flag or opts.Title or tostring(math.random(1e6)),
            Title    = opts.Title or "",
            Options  = opts.Values or opts.Options or {},
            Default  = opts.Default or nil,
            Callback = opts.Callback or function() end,
        })
    end

    function s:MultiDropdown(opts)
        return sec:AddMultiDropdown({
            ID       = opts.Flag or opts.Title or tostring(math.random(1e6)),
            Title    = opts.Title or "",
            Desc     = opts.Desc or nil,
            Options  = opts.Values or opts.Options or {},
            Default  = opts.Default or {},
            Callback = opts.Callback or function() end,
        })
    end

    function s:Paragraph(opts)
        return sec:AddParagraph({
            Title = opts.Title or "",
            Body  = opts.Content or opts.Body or "",
        })
    end

    function s:Keybind(opts)
        return sec:AddKeybind({
            ID       = opts.Title or tostring(math.random(1e6)),
            Title    = opts.Title or "",
            Default  = opts.Default or Enum.KeyCode.Unknown,
            Callback = opts.Callback or function() end,
        })
    end

    function s:Destroy()
        pcall(function() sec:ClearComponents() end)
    end

    return s
end

-- ── Shim: bungkus Tab MuvaUI jadi API ringkas utk module game ───────
local function wrapTab(tab)
    local t = {}

    function t:Section(opts)
        local sec = tab:AddSection({ Title = opts.Title or "" })
        return wrapSection(sec)
    end

    function t:Button(opts)
        local sec = tab:AddSection({ Title = "" })
        return wrapSection(sec):Button(opts)
    end

    function t:Toggle(opts)
        local sec = tab:AddSection({ Title = "" })
        return wrapSection(sec):Toggle(opts)
    end

    return t
end

-- ── MuiUI.Init ─────────────────────────────────────────────────────
function MuiUI.Init(MuvaUI)
    if not MuvaUI then
        warn("[MuiUI] MuvaUI library tidak ditemukan")
        return
    end

    -- muihubv2: bundle SUDAH di dalam blob ini. Tak ada lagi HttpGet/FetchSource/
    -- CdnURL untuk menarik source. Yang tersisa: base ingest (game modules dipakai
    -- /presence, /backpack, /api/dash) + identitas placeId/gameName.
    local ctx     = getgenv().__MH_ctx or {}
    if ctx.key then getgenv().script_key = ctx.key end
    local ApiURL  = ctx.api or ctx.base or getgenv().MuiHub_BaseURL or ""
    getgenv().MuiHub_BaseURL = ApiURL
    local TradeApiURL = ctx.tradeApi or getgenv().MuiHub_TradeBaseURL or ""
    getgenv().MuiHub_TradeBaseURL = TradeApiURL
    getgenv().MuiHub_CdnURL  = ApiURL
    local PlaceId  = getgenv().MuiHub_PlaceId or tostring(game.PlaceId)
    getgenv().MuiHub_PlaceId = PlaceId
    local GameName = getgenv().MuiHub_GameName
    if not GameName or GameName == "" then
        local ok, info = pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        end)
        GameName = (ok and info and info.Name) or "Roblox"
        getgenv().MuiHub_GameName = GameName
    end

    -- ⚠⚠⚠ ANTI-AFK VirtualUser DIBUANG TOTAL — INI AKAR KICK "removed for
    -- cheating" (CODE BAC-xxxx, Error 267) DI STEAL AN EGG. JANGAN DIKEMBALIKAN.
    --
    -- Isi blok yang dihapus (jangan ditulis ulang dalam bentuk apa pun):
    --     local VU = game:GetService("VirtualUser")
    --     LocalPlayer.Idled:Connect(function()
    --         VU:CaptureController() VU:ClickButton2(Vector2.new())
    --     end)
    --
    -- TERBUKTI LEWAT ISOLASI MCP, 20+ varian, korelasi 100%:
    --   • MEMANGGIL game:GetService("VirtualUser") SAJA sudah cukup memicu kick
    --     — tanpa Connect, tanpa CaptureController, tanpa ClickButton2. Varian
    --     yang isinya HANYA baris GetService itu tetap ditendang (t+20s).
    --   • Init() PENUH tanpa blok ini: 3 dari 3 client BERSIH (88-106 detik).
    --     Init() PENUH dengan blok ini: kena, berulang, 8 dari 8.
    --   • Semua varian tanpa VirtualUser aman (W1,W2,W3,X1,X2,X3,V1..V4);
    --     semua varian dengan VirtualUser kena (V5,W4,W5,W6,X4,X5,Y2,Y3,Y4).
    --
    -- Blok ini juga yang membuat SEMUA jejak lain terlihat "tidak masuk akal":
    -- menghapus farm.lua total tetap kena (VU ada di sini, bukan di modul),
    -- UI-only tanpa 12 modul tetap kena, dan obfuscator/guard/stagger/minimize
    -- sama sekali tak berpengaruh. Ia ikut ke SETIAP blob, SEMUA game.
    --
    -- Ini SALINAN KEDUA dari cacat yang sama: antiafk.lua milik Steal an Egg
    -- sudah dibersihkan lebih dulu (VirtualUser/VirtualInputManager -> firesignal
    -- pada UserInputService.InputChanged), tapi salinan di lapisan ui_template
    -- ini terlewat dan tetap hidup. Kalau anti-AFK universal dibutuhkan lagi,
    -- pakai pola firesignal itu — JANGAN API simulasi input level-driver.

    -- Router notifikasi module game → MuvaUI:Notify.
    -- ROOT CAUSE "notifikasi tidak muncul sama sekali": versi lama MEMBLOKIR
    -- SEMUA notif kecuali Title "Config" (niatnya meredam spam ratusan popup
    -- saat auto-load config) → efek sampingnya notif fitur (Bought/Sent/dll)
    -- tak pernah tampil selamanya. Ganti dgn FLOOD-GUARD: notif normal LOLOS,
    -- hanya BURST berlebihan yang diredam (maks 5 notif per jendela 2 detik;
    -- kelebihannya dibuang diam-diam). "Config" selalu lolos (ringkasan load).
    local _nfStamps = {}
    local function _floodOk()
        local now = os.clock()
        local keep = {}
        for _, t in ipairs(_nfStamps) do
            if (now - t) < 2 then keep[#keep + 1] = t end
        end
        _nfStamps = keep
        if #_nfStamps >= 5 then return false end
        _nfStamps[#_nfStamps + 1] = now
        return true
    end

    local Notifier = {}
    function Notifier:Notify(opts)
        opts = opts or {}
        if opts.Title ~= "Config" and not _floodOk() then return end
        MuvaUI:Notify({
            Title    = opts.Title or "",
            Body     = opts.Content or opts.Body or "",
            Type     = opts.Type or "info",
            Duration = opts.Duration or 3,
        })
    end
    getgenv().MuiHub_Notify = Notifier
    -- Alias genv LAMA — masih direferensikan module game terbitan lama.
    -- Object yang sama persis; kode baru pakai MuiHub_Notify.
    getgenv().MuiHub_WindUI = Notifier

    -- Expose registry Flag MuvaUI (Library.Flags) agar module game bisa sinkron
    -- VISUAL kontrol saat load config: MuiHub_Flags[ID]:SetAndFire(value) memicu
    -- updateVisual komponen (toggle/textbox/dropdown ikut ter-update tampilannya).
    pcall(function() getgenv().MuiHub_Flags = MuvaUI.Flags end)

    -- Lazy remote factory (dipakai modul games yang sudah pakai MuiHub_Remote)
    do
        local _objCache = {}
        local _RS = game:GetService("ReplicatedStorage")
        local _netCache, _netResolved = nil, false
        local function _getNet()
            if _netResolved then return _netCache end
            _netResolved = true
            local ok, f = pcall(function()
                return _RS:WaitForChild("Shared",3):WaitForChild("Packages",3):WaitForChild("Network",3)
            end)
            _netCache = ok and f or nil
            return _netCache
        end
        local _NOOP = setmetatable({}, {
            __index    = function() return _NOOP end,
            __call     = function() return _NOOP end,
            __newindex = function() end,
        })
        getgenv().MuiHub_Remote = function(name)
            return setmetatable({}, {
                __index = function(_, k)
                    if _objCache[name] == nil then
                        local net = _getNet()
                        _objCache[name] = (net and net:FindFirstChild(name)) or false
                    end
                    local r = _objCache[name]
                    if not r then return _NOOP end
                    local v = r[k]
                    return v ~= nil and v or _NOOP
                end,
                __newindex = function(_, k, v)
                    if _objCache[name] then _objCache[name][k] = v end
                end,
            })
        end
    end

    -- Flag: di-set true oleh BuildTabs jika game belum disupport, dibaca di OnReady
    local _gameNotSupported = false
    -- Alasan kegagalan, kalau ada. Dipisah dari _gameNotSupported karena
    -- keduanya BEDA: "game ini memang belum didukung" itu keadaan normal,
    -- sedangkan "bundle-nya gagal diunduh" adalah masalah yang bisa
    -- ditindaklanjuti user (coba lagi). Dulu keduanya dilaporkan sama.
    local _gameLoadError = nil

    -- Loading screen pakai title pendek "MuiHub" (tanpa link discord), supaya saat
    -- loading tidak menampilkan URL panjang. Window title boleh tetap panjang.
    if MuvaUI.SetLoadingScreen then
        MuvaUI:SetLoadingScreen({ Title = "MuiHub" })
    end

    MuvaUI:CreateWindow({
        Title    = "MuiHub  |  http://discord.gg/muihub",
        SubTitle = GameName,
        Version  = "v1.0.0",

        -- muihubv2: hash-only. Tak ada key-prompt klien sama sekali.
        Key = nil,

        -- muihubv2: bundle game ADA DI BLOB ini (bukan lagi fetch terpisah).
        -- Tab dideklarasikan runtime lewat MuiHub_DeclareTabs (dipanggil bundle),
        -- dgn fallback DEFAULT_TABS kalau bundle lama/tanpa header.
        BuildTabs = function(win)
            local DEFAULT_TABS = { "Home", "Farm", "Shop", "Misc", "Etc" }
            local DISCORD_LINK = "http://discord.gg/muihub"
            local _tabsBuilt = false

            -- Ikon tab: sprite LUCIDE (keep verbatim dari sumber lama).
            local TAB_ICON = {
                Home      = { 16898613869, 967, 661 },  Farm      = { 16898613869, 453, 967 },
                Kaitun    = { 16898613777, 918, 306 },  Guild     = { 16898613777, 869, 0   },
                Gear      = { 16898613044, 918, 563 },  Shop      = { 16898613777, 869, 257 },
                Trade     = { 16898613699, 820, 710 },  Misc      = { 16898613699, 49,  918 },
                Movement  = { 16898613353, 918, 710 },  Weather   = { 16898613044, 0,   967 },
                Etc       = { 16898613613, 918, 196 },  Settings  = { 16898613777, 771, 257 },
                Config    = { 16898613699, 918, 453 },  Main      = { 16898613777, 967, 147 },
                Inventory = { 16898612629, 710, 869 },  Pet       = { 16898613699, 771, 257 },
                Utility   = { 16898613869, 820, 906 },  Esp       = { 16898613353, 771, 563 },
                Webhook   = { 16898612819, 820, 257 },  Event     = { 16898613613, 918, 955 },
                Quest     = { 16898613699, 918, 808 },
                -- "Event" (tunggal) dipakai bundle lain; JANGAN diganti nama.
                -- Tab GAG Bake Sale bernama "Events", jadi ia butuh kuncinya
                -- sendiri — tanpa ini ia jatuh ke TAB_ICON_FALLBACK.
                Events    = { 16898613613, 918, 955 },

                -- Lima tab PS99 di bawah sebelumnya JATUH ke TAB_ICON_FALLBACK
                -- (circle-dot) — itulah "lingkaran kecil" yang dilaporkan.
                --
                -- Koordinat egg/fish/mail diambil dari sumber sheet yang sama
                -- (latte-soft/lucide-roblox, lib/Icons.luau, format
                -- ["nama"]={assetId,{48,48},{x,y}}) dan DIVERIFIKASI DUA ARAH:
                -- nama→koordinat lalu koordinat→nama harus sama. Metodenya
                -- sendiri divalidasi lebih dulu terhadap entri yang SUDAH
                -- terbukti di tabel ini: wheat={16898613869,{453,967}} = Farm
                -- dan backpack={16898612629,{710,869}} = Inventory — keduanya
                -- cocok persis. Kandidat yang GAGAL uji dua arah
                -- (mis. chevrons-up) sengaja TIDAK dipakai; Upgrades memakai
                -- ulang koordinat cog milik Gear yang memang sudah terbukti
                -- ketimbang menebak koordinat baru.
                Eggs      = { 16898613353, 514, 771 },  -- egg
                Upgrades  = { 16898613044, 918, 563 },  -- cog (sama dgn Gear)
                Items     = { 16898612629, 710, 869 },  -- backpack (sama dgn Inventory)
                Fishing   = { 16898613353, 869, 147 },  -- fish
                Mailbox   = { 16898613613, 820, 0   },  -- mail

                -- MM2 (placeId 142823291). Koordinat DIPAKAI ULANG dari entri
                -- yang sudah terbukti di tabel ini -- bukan koordinat baru hasil
                -- tebakan. Tanpa entri ini kelimanya jatuh ke TAB_ICON_FALLBACK
                -- (circle-dot), gejala "lingkaran kecil" yang dulu dilaporkan
                -- di PS99.
                MM2       = { 16898613777, 967, 147 },  -- sama dgn Main
                Visuals   = { 16898613353, 771, 563 },  -- sama dgn Esp
                Fling     = { 16898613353, 918, 710 },  -- sama dgn Movement
                Fun       = { 16898613699, 49,  918 },  -- sama dgn Misc
                Utilities = { 16898613869, 820, 906 },  -- sama dgn Utility

                -- Anime Dice (placeId 113290951185459). Koordinat DIPAKAI ULANG
                -- dari entri yang sudah terbukti di tabel ini -- bukan tebakan
                -- koordinat baru. Tanpa entri ini "Plot" jatuh ke
                -- TAB_ICON_FALLBACK (circle-dot).
                Plot      = { 16898613869, 453, 967 },  -- sama dgn Farm (wheat)
                Tower     = { 16898613044, 918, 563 },  -- sama dgn Gear (cog)
                Reward    = { 16898613613, 820, 0   },  -- sama dgn Mailbox (mail)
                Rebirth   = { 16898613777, 869, 257 },  -- sama dgn Shop
                -- "Upgrades" (jamak) sudah ada di atas utk PS99; Anime Dice
                -- memakai bentuk TUNGGAL, jadi ia butuh kuncinya sendiri --
                -- tanpa ini ia jatuh ke TAB_ICON_FALLBACK (circle-dot).
                Upgrade   = { 16898613044, 918, 563 },  -- sama dgn Upgrades (cog)

                -- Dungeon Quest-like (placeId 77649408247578 LOBBY +
                -- 85776757589518 DUNGEON). Koordinat DIPAKAI ULANG dari entri
                -- yang sudah terbukti -- bukan tebakan koordinat baru.
                Dungeon   = { 16898613777, 869, 257 },  -- sama dgn Shop
                Character = { 16898613699, 771, 257 },  -- sama dgn Pet
                Combat    = { 16898613353, 771, 563 },  -- sama dgn Esp

                -- Ride a Pet (placeId 124216119978534). Koordinat DIPAKAI
                -- ULANG dari entri yang sudah terbukti -- bukan tebakan.
                Hatch     = { 16898613353, 514, 771 },  -- sama dgn Eggs (egg)
                Ranch     = { 16898613699, 771, 257 },  -- sama dgn Pet
            }
            local TAB_ICON_FALLBACK = { 16898613044, 514, 771 }

            local function buildTabsFromList(tabNames)
                if _tabsBuilt then return end
                _tabsBuilt = true
                if type(tabNames) ~= "table" or #tabNames == 0 then tabNames = DEFAULT_TABS end
                local tabByName = {}
                for _, tabName in ipairs(tabNames) do
                    if type(tabName) == "string" and tabName ~= "" then
                        local ic = TAB_ICON[tabName] or TAB_ICON_FALLBACK
                        local tab = win:AddTab({
                            Title = tabName,
                            Icon  = {
                                Image      = "rbxassetid://" .. tostring(ic[1]),
                                RectOffset = Vector2.new(ic[2], ic[3]),
                                RectSize   = Vector2.new(48, 48),
                            },
                        })
                        tabByName[tabName] = tab
                        local key = tabName:gsub("[^%w]", "")
                        if key ~= "" then getgenv()["MuiHub_Tab" .. key] = wrapTab(tab) end
                    end
                end
                getgenv().MuiHub_Window = win

                local tabHome = tabByName["Home"]
                if tabHome then
                    local secInfo = wrapSection(tabHome:AddSection({ Title = "MuiHub Info" }))
                    secInfo:Paragraph({
                        Title = "Welcome to MuiHub",
                        Body  = "Discord: " .. DISCORD_LINK .. "\nGame: " .. GameName ..
                                "\nPlaceId: " .. PlaceId,
                    })
                    secInfo:Button({
                        Title = "Copy Discord Link", Desc = DISCORD_LINK,
                        Callback = function()
                            local clip = setclipboard or toclipboard or set_clipboard
                                or (syn and syn.write_clipboard)
                            local ok = clip and pcall(clip, DISCORD_LINK)
                            MuvaUI:Notify({
                                Title = "MuiHub",
                                Body  = ok and "Discord link disalin ke clipboard!"
                                            or "Executor tidak mendukung copy clipboard.",
                                Type  = ok and "success" or "warn", Duration = 3,
                            })
                        end,
                    })
                end
            end

            -- Ekspos runtime declare (tahan obfuscate) — bundle memanggilnya di header.
            getgenv().MuiHub_DeclareTabs = function(tabNames) buildTabsFromList(tabNames) end

            -- Bundle game ADA DI BLOB ini. Jalankan LANGSUNG (bukan fetch), sekali
            -- per jendela. Penjaga dikunci ke OBJEK jendela: reload sah (rejoin) bikin
            -- jendela baru -> bundle memang harus jalan lagi.
            return {
                {
                    Message = "Loading...",
                    Run = function()
                        if getgenv().MuiHub_BundleWindow == win then
                            if not _tabsBuilt then buildTabsFromList(DEFAULT_TABS) end
                            return
                        end
                        getgenv().MuiHub_BundleWindow = win
                        local run = getgenv().MuiHub_RunBundle
                        if type(run) == "function" then pcall(run) end
                        if not _tabsBuilt then buildTabsFromList(DEFAULT_TABS) end
                    end,
                },
            }
        end,

        OnReady = function(win)
            -- Modul sudah selesai di-load di loading steps — OnReady hanya setup toggle
            if _gameLoadError then
                -- Bukan "belum disupport": ini kegagalan unduh yang bisa dicoba
                -- ulang. Menyebutnya salah membuat user menyerah pada game yang
                -- sebenarnya didukung penuh.
                MuvaUI:Notify({ Title = "MuiHub", Body = _gameLoadError, Type = "warn", Duration = 8 })
            elseif _gameNotSupported then
                MuvaUI:Notify({ Title = "MuiHub", Body = "Game ini belum disupport.", Type = "warn", Duration = 4 })
            end

            -- ── PERFORMANCE: destroy window GUI saat WhiteScreen auto-start ──────
            -- Kalau AutoStart memuat "WhiteScreen", player akan langsung di layar
            -- hitam (lihat etc.lua) — window UI berat ini tidak perlu di-render.
            -- Semua modul SUDAH selesai load di loading steps & expose getgenv()
            -- (toggle logic, Farm Bacon, Target Mutation, dll TETAP hidup karena
            -- berupa closure/connection, bukan bergantung pada instance GUI).
            -- Jadi aman destroy ScreenGui window-nya — hanya visual yang hilang.
            -- Tombol floating tetap dibuat di bawah; win:Show() sudah ber-pcall
            -- jadi no-op aman setelah window di-destroy.
            do
                local _as = tostring(getgenv().AutoStart or _G.AutoStart or AutoStart or "")
                if _as:find("WhiteScreen") then
                    task.delay(0.2, function()
                        pcall(function()
                            -- Cara utama: ScreenGui = parent dari CanvasGroup window.
                            local sg = win and win._win and win._win.Parent
                            if sg and sg:IsA("ScreenGui") then
                                sg:Destroy()
                                return
                            end
                            -- Fallback: cari ScreenGui bernama "MuvaUI*" di CoreGui & PlayerGui.
                            local function killByName(parent)
                                if not parent then return end
                                for _, v in ipairs(parent:GetChildren()) do
                                    if v:IsA("ScreenGui") and v.Name:find("MuvaUI") then
                                        v:Destroy()
                                    end
                                end
                            end
                            killByName(game:GetService("CoreGui"))
                            local plr = game:GetService("Players").LocalPlayer
                            killByName(plr and plr:FindFirstChild("PlayerGui"))
                        end)
                    end)
                end
            end

            -- ── HORMATI "Destroy UI" YANG SUDAH DI-RESTORE CONFIG ───────────────
            -- Urutan flow BuildTabs: window dibuat TERSEMBUNYI → BuildTabs (modul
            -- dimuat → settings.lua restore config → _applyDestroyUI(true) →
            -- win:Hide()) → LoadingScreen selesai → **win:Show()** → OnReady.
            -- Jadi restore-nya BENAR, lalu langsung ditimpa win:Show() tanpa
            -- syarat. Tanpa blok ini, toggle-nya tersimpan & ter-load tapi
            -- efeknya tak pernah terlihat setelah rejoin.
            --
            -- Sengaja `== true`: ui_template dipakai SEMUA placeId, dan di game
            -- selain GaG flag ini nil — cabang ini harus diam saja, bukan
            -- menyembunyikan UI siapa pun.
            -- Tombol apung di bawah tetap dibuat, jadi user selalu bisa membuka
            -- window-nya kembali.
            if _G.GAG_DestroyUI == true then
                pcall(function() win:Hide() end)
            end

            -- Floating toggle button + Right Shift
            local UserInputService = game:GetService("UserInputService")
            local Players          = game:GetService("Players")
            local CoreGui          = game:GetService("CoreGui")
            local TweenService     = game:GetService("TweenService")

            -- Awali dari keadaan SEBENARNYA, bukan asumsi "pasti tampil".
            -- Kalau "Destroy UI" ter-restore dari config, window sudah tersembunyi
            -- di sini — dan dgn nilai true, klik PERTAMA tombol apung malah
            -- menyembunyikannya lagi (tak terjadi apa-apa) sehingga user harus
            -- mengklik dua kali untuk membukanya.
            local isUIVisible = not (_G.GAG_DestroyUI == true)
            local player      = Players.LocalPlayer
            local playerGui   = player:WaitForChild("PlayerGui")

            local function toggleUI()
                isUIVisible = not isUIVisible
                pcall(function() if isUIVisible then win:Show() else win:Hide() end end)
            end

            local ScreenGui = Instance.new("ScreenGui")
            ScreenGui.Name           = "MuiHubToggleButton"
            ScreenGui.ResetOnSpawn   = false
            ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            pcall(function() ScreenGui.Parent = CoreGui end)
            if not ScreenGui.Parent then ScreenGui.Parent = playerGui end

            local ToggleButton = Instance.new("ImageButton")
            ToggleButton.Name                   = "ToggleButton"
            ToggleButton.Size                   = UDim2.new(0, 75, 0, 75)
            ToggleButton.Position               = UDim2.new(0, 10, 0.5, -37)
            ToggleButton.BackgroundColor3        = Color3.fromRGB(20, 20, 20)
            ToggleButton.BorderSizePixel        = 0
            ToggleButton.AutoButtonColor        = false
            ToggleButton.Image                  = ""
            ToggleButton.ScaleType              = Enum.ScaleType.Crop
            ToggleButton.Parent                 = ScreenGui

            local UICorner = Instance.new("UICorner")
            UICorner.CornerRadius = UDim.new(0, 15)
            UICorner.Parent       = ToggleButton

            -- Arceus X TAK me-render custom-asset gambar hasil-download (diukur
            -- 2026-09-04: getcustomasset ADA, download PNG BERHASIL 351KB, tapi
            -- logo tetap abu -- quirk render Arceus X, bukan fungsi hilang). Aset
            -- rbxassetid pun perlu upload Roblox (sulit di sisi pemilik) & belum
            -- terverifikasi. Jalur DEFAULT (PNG+getcustomasset, executor lain spt
            -- Delta) TAK DISENTUH -- fallback di bawah HANYA aktif di Arceus X.
            local isArceusX = false
            pcall(function()
                local nm = (identifyexecutor and identifyexecutor())
                    or (getexecutorname and getexecutorname()) or ""
                isArceusX = tostring(nm):lower():find("arceus", 1, true) ~= nil
            end)

            if isArceusX then
                -- Logo UI murni (lingkaran ungu + "MH") -- tak ada aset/download/
                -- getcustomasset sama sekali, jadi render di executor mana pun yg
                -- gagal me-render custom-asset. Cakupan KETAT ke Arceus X saja.
                ToggleButton.BackgroundColor3 = Color3.fromRGB(124, 77, 255)
                local MHLabel = Instance.new("TextLabel")
                MHLabel.Name                  = "MHLabel"
                MHLabel.Size                  = UDim2.new(1, 0, 1, 0)
                MHLabel.BackgroundTransparency = 1
                MHLabel.Text                  = "MH"
                MHLabel.TextColor3            = Color3.fromRGB(255, 255, 255)
                MHLabel.Font                  = Enum.Font.GothamBold
                MHLabel.TextScaled            = true
                MHLabel.Parent                = ToggleButton
            else
            task.spawn(function()
                local assetPath = nil

                pcall(function()
                    if not isfolder("MuiHub") then makefolder("MuiHub") end
                    if not isfolder("MuiHub/assets") then makefolder("MuiHub/assets") end

                    local verFile = "MuiHub/assets/logo.ver"
                    local serverVer = ""

                    -- Ambil versi dari server
                    pcall(function()
                        local v = game:HttpGet(ApiURL .. "/muihub-logo.version")
                        if v and #v <= 64 and not v:find("<") then
                            serverVer = v:gsub("%s", "")
                        end
                    end)

                    local localVer = ""
                    if isfile(verFile) then
                        localVer = readfile(verFile):gsub("%s", "")
                    end

                    -- Tentukan folder berdasarkan versi agar path unik per-gambar
                    local ver = serverVer ~= "" and serverVer or localVer
                    if ver == "" then ver = "default" end

                    local folder  = "MuiHub/assets/" .. ver
                    local imgFile = folder .. "/logo.png"

                    -- Download hanya jika versi beda atau file belum ada
                    if not isfile(imgFile) then
                        if not isfolder(folder) then makefolder(folder) end
                        local bust = tostring(math.floor(os.time()))
                        local data = game:HttpGet(ApiURL .. "/muihub-logo.png?v=" .. bust)
                        writefile(imgFile, data)
                        -- Simpan versi baru
                        if serverVer ~= "" then
                            writefile(verFile, serverVer)
                            -- Hapus folder versi lama
                            if localVer ~= "" and localVer ~= serverVer then
                                pcall(function()
                                    local oldFolder = "MuiHub/assets/" .. localVer
                                    if isfolder(oldFolder) then
                                        delfile(oldFolder .. "/logo.png")
                                        delfolder(oldFolder)
                                    end
                                end)
                            end
                        end
                    end

                    -- getcustomasset executor-specific: Delta punya `getcustomasset`,
                    -- executor lain pakai nama beda. Arceus X: sering TAK punya
                    -- custom-asset -> logo gagal senyap (abu). Rantai + fallback.
                    local gca = getcustomasset or getsynasset
                        or (syn and syn.getcustomasset) or getcustomassetfunc
                    if gca then assetPath = gca(imgFile) end
                end)

                if assetPath and assetPath ~= "" then
                    ToggleButton.Image                  = assetPath
                    ToggleButton.BackgroundTransparency = 1
                end
            end)
            end

            local dragging, dragInput, mousePos, framePos = false, nil, nil, nil
            ToggleButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    mousePos = input.Position
                    framePos = ToggleButton.Position
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then dragging = false end
                    end)
                end
            end)
            ToggleButton.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragInput = input
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if input == dragInput and dragging then
                    local delta = input.Position - mousePos
                    ToggleButton.Position = UDim2.new(
                        framePos.X.Scale, framePos.X.Offset + delta.X,
                        framePos.Y.Scale, framePos.Y.Offset + delta.Y)
                end
            end)
            ToggleButton.MouseButton1Click:Connect(function()
                TweenService:Create(ToggleButton, TweenInfo.new(0.1), { Size = UDim2.new(0,69,0,69) }):Play()
                task.wait(0.1)
                TweenService:Create(ToggleButton, TweenInfo.new(0.1), { Size = UDim2.new(0,75,0,75) }):Play()
                toggleUI()
            end)
            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.KeyCode == Enum.KeyCode.RightShift then toggleUI() end
            end)

            MuvaUI:Notify({ Title = "MuiHub Ready", Body = "Semua modul berhasil dimuat", Type = "success", Duration = 3 })
        end,
    })
end

return MuiUI
