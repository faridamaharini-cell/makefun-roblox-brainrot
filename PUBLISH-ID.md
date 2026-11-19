# Publish Brainrot Bay ke Roblox — panduan buat user

Bounty: make.fun `roblox-brainrot-01` — "Make the best AI Roblox brainrot game", pot $1.000.
Deadline: **Jumat 20 Nov 2026, 21:30 WIB** (2026-11-20T14:30:00Z).
Status game: v4 sudah jadi — `game.rbxl` (84.697 byte, sha256
`e6007ea5903b4a77e3366071bc277b5ef5975ce7694dda6239337687a44b1c0e`, 19 Nov 17:44 WIB).
Game **Brainrot Bay** v4: 32 brainrot, 9 rarity, 6 mutasi, Baydex Index (koleksi brainrot),
tangga GOALS, Poseidon Tier (unlock rebirth), quest, upgrade base, gifting antar pemain,
tsunami + Golden Hour + Meteor Shower, 10 base, conveyor 300 stud.
Yang baru di v4 (rebuild dari screenshot v3.6): tanah pasir/rumput/laut menutup SELURUH
map 512x512 — tidak ada lagi baseplate abu-abu; papan nama kecil & tidak menumpuk;
brainrot berdiri dengan kaki tepat di permukaan (diukur dari bounding box, bukan
konstanta) dan label nama/rarity/$-nya kecil + berselang-seling.
Terverifikasi: Rojo build 2x byte-identik, dossier main.ts cocok 100% (21/21 script),
Luau 21/21 lolos compile, cek make.fun 5 passed 0 failed (play_link lolos).

## Yang kamu butuhkan

- File `game.rbxl` dari repo ini (Muse yang kirim ke kamu).
- Roblox Studio di Windows/Mac + akun Roblox kamu (somnia935 — login sudah terverifikasi,
  umur akun ~13 bulan, verifikasi umur 21+ lengkap).

## Langkah publish (di komputermu) — UPDATE EXPERIENCE YANG SUDAH ADA

PENTING: experience **Brainrot Bay** SUDAH ADA dan SUDAH PUBLIC — place_id
97215362967211, universe_id 10777791390
(https://www.roblox.com/games/97215362967211). **UPDATE experience itu, JANGAN
buat experience baru.** Jangan pakai experience lama "Pasar Brainrot:
Tsunami Run" (universe 9054540783) — itu bukan game ini.

1. Buka Roblox Studio, **File > Open from File**, pilih `game.rbxl` (yang baru, 84.697 byte, v4).
2. **File > Publish to Roblox As... > pilih experience "Brainrot Bay" yang sudah ada**
   (bukan "Create New Experience").
   - Deskripsi sudah berisi play code — jangan dihapus:
     > Play code: makefun-domino-cinema-frosting
   - Visibility: **Public**. Publish.
3. Di Creator Dashboard (create.roblox.com) > Creations > experience Brainrot Bay:
   - Upload **icon** dan **thumbnail** (pakai satu screenshot gameplay asli sebagai thumbnail).
4. Mainkan gamenya dari Roblox (bukan cuma di Studio), lalu ambil **4 screenshot gameplay asli**:
   - 1) pemandangan luas: conveyor + papan nama + HUD, 2) event lagi jalan (tsunami / meteor /
     Golden Hour), 3) Baydex Index lagi terbuka (pencet B di keyboard), 4) base penuh brainrot.
   - Salah satu screenshot harus sama dengan thumbnail yang di-upload di atas.
   - Kalau pas main muncul error, screenshot/foto teks errornya dan kirim ke Muse biar diperbaiki.
5. Kirim balik ke Muse: **4 file screenshot PNG** (link place sudah ada di `PLAY.json`:
   place_id 97215362967211, universe_id 10777791390 — tidak perlu kirim link lagi).

## Penting — jangan pakai screenshot yang ada di repo sekarang

File `screenshots/1-start.png`, `2-play.png`, `3-end.png` di repo ini **bukan** gameplay
Brainrot Bay. Ketiganya dibuat 19 Nov 01:13 WIB — sebelum kode gamenya ada — dan isinya
kotak abu-abu starter: "Use the arrow keys to move the square". Kalau ikut ter-submit,
cover entry-nya jadi kotak abu-abu. Screenshot itu wajib diganti dengan 4 foto gameplay
asli dari langkah 4 di atas.

## Setelah kamu kirim balik

Muse yang kerjakan: ganti screenshot repo dengan fotomu, lalu submit entry-nya
dengan judul "Tidepool Heist: Brainrot Bay" sebelum deadline 21:30 WIB 20 Nov.
Jatah submit disimpan — submit hanya untuk versi terbaik ini, tidak langsung dihabiskan.
