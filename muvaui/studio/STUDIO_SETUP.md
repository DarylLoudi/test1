# MuvaUI — Iterasi Visual di Roblox Studio

Tujuan: percantik MuvaUI **tanpa executor / tanpa re-inject**. Edit `src/` → build → tekan **Play (F5)** → lihat hasil dalam ~2 detik. Output lengkap + stack asli + Explorer live.

## Kenapa Studio (bukan re-execute)

| | Re-execute | Studio |
|---|---|---|
| Iterasi visual | edit → build → inject → join game → lihat (~30–60s) | edit → Play → lihat (~2–3s) |
| Debug | console terbatas, stack "Line 1" | Output penuh + stack asli |
| Inspeksi UI | tak bisa | Explorer: klik tiap Frame, ubah properti live |
| Risiko ban | ada tiap inject | nol |

MuvaUI murni Instance Roblox; semua API executor-only (`CoreGui`, `setclipboard`, `writefile`) sudah ter-`pcall`/fallback `PlayerGui`, jadi **jalan normal di Studio**.

## Setup (sekali saja)

1. Buka Studio, buat **baseplate** baru (atau buka tempat apa pun).
2. Di **Explorer**, buka `StarterPlayer` → `StarterPlayerScripts`.
3. Buat **ModuleScript**, rename jadi **`MuvaUI`** (persis). Isi: **paste seluruh isi `muvaui/MuvaUI.lua`** (hasil build) ke dalamnya.
4. Buat **LocalScript**, rename jadi **`MuvaUI_Showcase`**. Isi: paste isi `studio/MuvaUI_Showcase.client.lua`.
5. Tekan **Play (F5)**.

Window showcase muncul berisi **3 tab** (Inputs / Display / Theme) dengan semua komponen. Tombol "Accent: …" menguji ganti warna live.

> **Catatan struktur:** LocalScript me-`require` ModuleScript sibling bernama `MuvaUI`. Saat Play, `StarterPlayerScripts` disalin ke `Players.LocalPlayer.PlayerScripts` — script otomatis menemukannya di sana. Boleh juga taruh ModuleScript `MuvaUI` di `ReplicatedStorage` (showcase punya fallback ke situ).

## Workflow iterasi

```
edit file di muvaui/src/  (mis. core/Theme.lua, components/input/Toggle.lua)
        │
        ▼
python muvaui/build.py        ← regenerate muvaui/MuvaUI.lua
        │
        ▼
copy isi muvaui/MuvaUI.lua → ModuleScript "MuvaUI" di Studio
        │
        ▼
Play (F5) di Studio → lihat hasil
```

**Mempercepat langkah copy:** pakai plugin sinkron file→Studio (mis. **Rojo**) agar `MuvaUI.lua` & showcase otomatis ter-sync tiap build — tak perlu copy-paste manual. (Opsional; manual copy juga cukup untuk iterasi sesekali.)

## Yang AMAN diubah untuk "lebih modern"

Semua ini visual-only, **tidak** menyentuh API → script game (`farm.lua`, `shop.lua`, dst) lewat shim WindUI di `src/modules/ui_template.lua` **tak perlu diubah sama sekali**:

- **`src/core/Theme.lua`** — palette, accent, token warna (sudah terpusat dengan baik).
- **`src/core/Layout.lua`** — spacing, padding, ukuran (radius, tinggi card, dll).
- **`src/components/*`** — corner radius (`UICorner`), shadow/glow (`UIStroke` + gradient), easing animasi (`TweenInfo`), tipografi (`Font`, `TextSize`).

Setelah puas dengan tampilan di Studio → `python build.py` sekali lagi → deploy `MuvaUI.lua` ke produksi seperti biasa. Tidak ada perubahan di sisi script game.

## Verifikasi cepat

Saat Play, **Output** harus menampilkan:
```
[Showcase] MuvaUI showcase siap — 3 tab, semua komponen. Edit src/, build, Play lagi.
```
Kalau ada `warn [Showcase] ...` → ikuti pesannya (biasanya ModuleScript belum bernama persis `MuvaUI`).
