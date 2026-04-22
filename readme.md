# exter-fishing (Refactored)

Script memancing modular untuk FiveM dengan dukungan multi-framework, multi-inventory, leaderboard, dan arsitektur bridge agar integrasi lebih stabil.

## Fitur Utama

- Kompatibel framework:
  - **QBCore**
  - **Qbox**
  - **ESX**
  - **Standalone (fallback)**
- Kompatibel inventory:
  - **qb-inventory**
  - **ox_inventory**
  - **esx inventory (native xPlayer inventory)**
  - **qs-inventory**
  - **standalone fallback**
- Sistem leaderboard ikan berdasarkan panjang ikan (top 10 per jenis ikan).
- Minigame NUI untuk menangkap ikan.
- Validasi dan error handling yang lebih aman (input callback, data item, metadata, fallback notification).
- Arsitektur bridge modular (`client/core.lua` + `server/core.lua`) untuk meminimalkan konflik antar ekosistem.
- Dukungan integrasi fuel (opsional) dengan auto-detection:
  - **LegacyFuel**
  - **CDN-Fuel**
  - **ox_fuel**
  - **qb-fuel**

---

## Struktur File

- `config.lua` → Seluruh konfigurasi utama.
- `server/core.lua` → Bridge framework, inventory, callback server, money/item abstraction.
- `server/main.lua` → Logic memancing utama dan penjualan ikan.
- `server/leaderboard.lua` → Simpan data leaderboard + callback fetch leaderboard.
- `client/core.lua` → Bridge client (notify, callback, progressbar, fuel API).
- `client/main.lua` → Logic animasi memancing, validasi kondisi player, start minigame.
- `client/minigame.lua` → Bridge NUI minigame.
- `client/leaderboard.lua` → UI leaderboard.
- `db.sql` → Tabel database leaderboard.

---

## Instalasi

1. **Copy resource** ke folder server Anda, misalnya:
   - `resources/[local]/exter-fishing`
2. Pastikan dependency database:
   - `oxmysql`
3. Import `db.sql` ke database server.
4. Tambahkan ke `server.cfg`:

```cfg
ensure oxmysql
ensure exter-fishing
```

5. Atur konfigurasi pada `config.lua`.

---

## Konfigurasi Dasar (`config.lua`)

### 1) Framework

```lua
Config.Framework = 'auto' -- auto | qbcore | qbox | esx | standalone
```

Jika `auto`, script akan mendeteksi resource framework yang sedang aktif.

### 2) Inventory

```lua
Config.Inventory = 'auto' -- auto | qb-inventory | ox_inventory | esx_inventory | qs-inventory | standalone
```

Jika `auto`, script akan mencoba deteksi inventory populer yang aktif.

### 3) Fuel (Opsional)

```lua
Config.Fuel.enabled = false
Config.Fuel.system = 'auto' -- auto | LegacyFuel | CDN-Fuel | ox_fuel | qb-fuel | none
```

> Catatan: script fishing inti tidak mewajibkan fuel. API fuel disediakan agar mudah diintegrasikan ke fitur tambahan (misalnya boat rental / boat mission).

### 4) Item utama

```lua
Config.Items = {
  bait = 'fishbait',
  rod = 'fishingrod',
  fishNet = 'fishnet'
}
```

### 5) Pengaturan gameplay

```lua
Config.BaitConsumeChance = 0.60
Config.WaitForBiteMs = { min = 10000, max = 20000 }
```

---

## Panduan Tambah Item per Framework/Inventory

## QBCore / Qbox (shared/items.lua)

Tambahkan item berikut (contoh minimal):

```lua
['fishingrod'] = { name = 'fishingrod', label = 'Fishing Rod', weight = 1000, type = 'item', image = 'fishingrod.png', unique = false, useable = true, shouldClose = true, description = 'Rod' },
['fishbait'] = { name = 'fishbait', label = 'Fish Bait', weight = 100, type = 'item', image = 'fishbait.png', unique = false, useable = true, shouldClose = true, description = 'Bait' },
['sturgeon'] = { name = 'sturgeon', label = 'Sturgeon', weight = 2500, type = 'item', image = 'sturgeon.png', unique = true, useable = false, shouldClose = true, description = 'Fish' },
```

Lakukan hal yang sama untuk seluruh daftar ikan pada `Config.FishLists`.

## ox_inventory (`data/items.lua`)

Contoh format:

```lua
['fishingrod'] = {
  label = 'Fishing Rod',
  weight = 1000,
  stack = true,
  close = true,
  description = 'Rod'
},
['fishbait'] = {
  label = 'Fish Bait',
  weight = 100,
  stack = true,
  close = true,
  description = 'Bait'
}
```

Tambahkan juga item ikan (`sturgeon`, `whitefish`, dst).

## ESX (`es_extended` / item table)

Tambahkan item di tabel items sesuai struktur ESX Anda, minimal:

- `fishingrod`
- `fishbait`
- seluruh item ikan di `Config.FishLists`

Pastikan item `fishbait` dan `fishingrod` benar-benar ada agar event fishing tidak gagal.

## qs-inventory

Tambahkan item di data item qs-inventory dengan nama yang sama seperti di konfigurasi (`fishingrod`, `fishbait`, dan list ikan).

---

## Integrasi NPC/Shop/Interaksi

Script ini sudah menyediakan event:

- Jual ikan: `exter-fishing:sellFishes` (server event)
- Buka leaderboard: `exter-fishing:showLeaderboard` (client event)

Silakan integrasikan ke NPC/dialog/target system server Anda (qb-target, ox_target, atau custom).

---

## Validasi & Error Handling yang Sudah Ditambahkan

- Fallback callback system universal client-server.
- Validasi input callback leaderboard.
- Fallback mode untuk notify/progress jika framework resource tidak tersedia.
- Cek aman metadata item saat jual ikan (hindari nil indexing).
- Fallback inventory adapter untuk beberapa sistem populer.
- Proteksi kondisi player sebelum memancing (swimming, di kendaraan, dekat air).
- Proteksi object creation dan cleanup state fishing.

---

## Testing Checklist (Disarankan)

Lakukan pengujian berikut setiap selesai update:

1. Gunakan `fishingrod` di area dekat air.
2. Coba memancing saat berenang (harus ditolak).
3. Coba memancing di dalam kendaraan (harus ditolak).
4. Coba memancing tanpa `fishbait` (harus gagal tangkap).
5. Coba tangkap beberapa ikan, cek metadata `length` & `price`.
6. Jual ikan, pastikan uang bertambah sesuai total.
7. Cek leaderboard NUI dan data top 10 per jenis ikan.
8. Uji resource restart: script harus tetap recover normal.
9. Uji kombinasi framework + inventory yang berbeda (jika server multi-branch deployment).

---

## Troubleshooting

- **Tidak bisa pakai fishing rod**
  - Pastikan `Config.Items.rod` sesuai nama item sebenarnya.
  - Pastikan framework dan inventory terdeteksi benar (gunakan mode non-auto jika perlu).

- **Ikan tidak masuk inventory**
  - Periksa item ikan sudah terdaftar di inventory system.
  - Periksa adapter inventory aktif (`Config.Inventory`).

- **Leaderboard kosong**
  - Pastikan `db.sql` sudah di-import.
  - Pastikan `oxmysql` aktif sebelum `exter-fishing`.

---

## Catatan Kompatibilitas

- Mode `standalone` disediakan sebagai fallback dasar.
- Fitur ekonomi (add money) memerlukan framework ekonomi aktif (QBCore/Qbox/ESX).
- API fuel tersedia untuk ekstensi fitur custom, tidak wajib untuk core fishing.
