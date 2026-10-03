-- Library: entry point MuvaUI
-- Ini yang di-return ke user dari loadstring(...)()
-- CATATAN: CoreGui hanya bisa diakses di executor (privilege tinggi). Di Roblox
-- Studio, LocalScript biasa TIDAK punya akses CoreGui → game:GetService bisa
-- error/return nil. Jadi resolve & akses CoreGui SELALU lewat pcall (opsional),
-- window aslinya di-parent ke PlayerGui (lihat bawah) yang selalu tersedia.
local CoreGui = nil
pcall(function() CoreGui = game:GetService("CoreGui") end)

Library = {}
Library.__index = Library
Library.Flags   = {}
Library._windows = {}

function Library:CreateWindow(opts)
    -- Cleanup instance lama agar tidak ada ghost UI dari run sebelumnya.
    -- CoreGui di-pcall: di Studio bisa tak terakses → lewati saja (bukan fatal).
    pcall(function()
        if CoreGui then
            for _, v in ipairs(CoreGui:GetChildren()) do
                if v.Name:find("MuvaUI") then v:Destroy() end
            end
        end
    end)
    pcall(function()
        local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            for _, v in ipairs(pg:GetChildren()) do
                if v.Name:find("MuvaUI") then v:Destroy() end
            end
        end
    end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name             = "MuvaUI_" .. (opts.Title or "Window")
    screenGui.ResetOnSpawn     = false
    screenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder     = 5
    screenGui.IgnoreGuiInset   = false

    -- Parent ke PlayerGui — PlayerGui selalu di bawah Roblox CoreGui system menu
    -- Ini memastikan Roblox menu (Esc) selalu di atas MuvaUI
    local Players = game:GetService("Players")
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    screenGui.Parent = playerGui

    -- Key system — tampilkan sebelum window jika ada
    if opts.Key and KeySystem then
        KeySystem.show(opts.Key, screenGui, function()
            -- _spawnWindow menangani OnReady sendiri untuk path BuildTabs & LoadingScreen.
            -- Untuk path biasa (return window langsung), kita panggil OnReady di sini.
            local win = self:_spawnWindow(opts, screenGui)
            if win and opts.OnReady and not opts.BuildTabs and not self._loadingConfig then
                pcall(opts.OnReady, win)
            end
        end)
        return nil
    else
        local win = self:_spawnWindow(opts, screenGui)
        if win and opts.OnReady and not opts.BuildTabs and not self._loadingConfig then
            pcall(opts.OnReady, win)
        end
        return win
    end
end

function Library:_spawnWindow(opts, screenGui)
    local function buildWindow()
        local ok, result = pcall(function() return Window.new(opts, screenGui, self.Flags) end)
        if not ok then
            warn("[MuvaUI] Window.new failed: " .. tostring(result))
            return nil
        end
        table.insert(self._windows, result)
        if self._configSystem and ConfigSystem then
            ConfigSystem.attach(result, self._configSystem, self.Flags)
        end
        return result
    end

    -- ── FLOW BARU: BuildTabs ────────────────────────────────────
    -- Kalau opts.BuildTabs ada, urutannya:
    --   1. Buat window TERSEMBUNYI (Visible=false)
    --   2. Panggil opts.BuildTabs(win) → user buat tab, return daftar step loading
    --   3. LoadingScreen jalan dengan step itu (fetch module terjadi di sini,
    --      tab sudah ada jadi module bisa langsung isi konten)
    --   4. Setelah loading selesai → win:Show() + OnReady
    -- Ini memastikan window muncul SUDAH terisi penuh, bukan kosong dulu.
    if opts.BuildTabs and LoadingScreen then
        local win = buildWindow()
        if not win then return nil end

        win:Hide()

        -- BuildTabs return: array step loading { {Message, Run}, ... } (boleh nil)
        local okB, steps = pcall(opts.BuildTabs, win)
        if not okB then
            warn("[MuvaUI] BuildTabs error: " .. tostring(steps))
            steps = nil
        end

        local loadingConfig = {
            Title    = (self._loadingConfig and self._loadingConfig.Title) or opts.Title or "Loading",
            Steps    = steps or (self._loadingConfig and self._loadingConfig.Steps) or { { Message = "Loading..." } },
            OnResult = self._loadingConfig and self._loadingConfig.OnResult,
        }

        LoadingScreen.show(loadingConfig, screenGui, function()
            win:Show()
            if opts.OnReady then pcall(opts.OnReady, win) end
        end)
        return nil
    end

    if self._loadingConfig and LoadingScreen then
        LoadingScreen.show(self._loadingConfig, screenGui, function()
            local win = buildWindow()
            if opts.OnReady and win then
                pcall(opts.OnReady, win)
            end
        end)
        return nil
    else
        return buildWindow()
    end
end

function Library:SetAccent(color)
    Theme:SetAccent(color)
end

function Library:GetAccent()
    return Theme:GetAccent()
end

-- Library:Notify dipatch oleh components/overlay/Toast.lua

function Library:SetLoadingScreen(config)
    self._loadingConfig = config
end


function Library:SetConfigSystem(config)
    self._configSystem = config
end

function Library:SaveConfig(name)
end

function Library:LoadConfig(name)
end

-- ── PATCH: wire overlay functions setelah semua variable terdefinisi ──
-- Notify meneruskan ScreenGui window (kalau masih hidup) ke Toast — toast
-- ter-render di tempat yang SAMA dengan window (terbukti tampil di executor),
-- bukan ScreenGui CoreGui terpisah yang di sebagian executor tak dirender.
Library.Notify = function(self, opts)
    local sg = nil
    for _, w in ipairs(self._windows) do
        if w and w._win and w._win.Parent then
            sg = w._win.Parent
            break
        end
    end
    Toast.show(opts, sg)
end

Window.Dialog = function(self, opts)
    Dialog.show(opts, self._win.Parent)
end

Window.Popup = function(self, opts)
    Popup.show(opts, self._win)
end
