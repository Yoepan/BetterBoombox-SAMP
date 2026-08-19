# BetterBoombox for SA-MP

The most lightweight & lag-free YouTube Boombox system for SA-MP.
Designed specifically to be flexibly integrated into Roleplay Servers (Inventory Systems) or Freeroam Servers.

**Update v1.1 Features:**
- **Personal Playlist:** Save up to 5 favorite songs per player.
- **Duration Limit:** Maximum 10 minutes per song to prevent abuse.

---

## ENGLISH VERSION

### 1. FILE PREPARATION (REQUIRED FOR ALL SERVERS)
1. Place `better_boombox.amx` into your server's `filterscripts` folder.
2. Open `server.cfg`, and add `better_boombox` to the `filterscripts` line.
3. Still in `server.cfg`, add a new line for your API IP:
   ```text
   bbb_api_url http://YOUR_VPS_IP:3000
   ```
   *(Example: `bbb_api_url http://103.82.11.55:3000`)*

### 2. GAMEMODE INTEGRATION

#### OPTION A: FOR RP/RPG SERVERS (With Existing Inventory/Store Systems)
This system is designed **NOT** to break your item database.
- When a player clicks "Use" on a Boombox item in your inventory, simply call this code in your Gamemode:
  ```pawn
  CallRemoteFunction("PlaceBetterBoombox", "i", playerid);
  ```
  *(Do not forget to decrease the boombox item in your player's database after this function is called).*

- When the boombox is picked up (`/pickupbb`), this script will call your Gamemode back. Add this function to your Gamemode to return the item to the inventory:
  ```pawn
  forward OnBetterBoomboxPickup(playerid);
  public OnBetterBoomboxPickup(playerid) {
      // Give the item to the player here (Example: GivePlayerItem(playerid, 1);)
      return 1;
  }
  ```

#### OPTION B: FOR NEW / FREEROAM SERVERS (No Inventory)
If you just want players to be able to place a boombox using a normal command (without buying it in a store), just add this command inside your Gamemode:
```pawn
CMD:boombox(playerid, params[]) {
    CallRemoteFunction("PlaceBetterBoombox", "i", playerid);
    return 1;
}

// Optional: Leave the pickup function empty as there is no inventory system
forward OnBetterBoomboxPickup(playerid);
public OnBetterBoomboxPickup(playerid) {
    return 1;
}
```

### 3. CONTROLLING THE BOOMBOX
Once the boombox is placed on the ground, the *Owner* simply needs to approach it, **crouch**, and type:
`/setbb`
The panel for setting the song (YouTube URL) and the Distance Radius will appear.

### 4. RUNNING THE API ENGINE (NODE.JS)
Because this system is standalone and lag-free, you must run the API engine on your VPS so the boombox can download songs from YouTube.
1. Move the `API` folder into your VPS.
2. Open Terminal/CMD inside the `API` folder.
3. Install dependencies:
   ```bash
   npm install
   ```
4. Run the engine:
   ```bash
   node index.js
   ```
   *(It is highly recommended to use `pm2` so the API stays alive 24/7: `pm2 start index.js`)*
5. Ensure your VPS IP has been entered into `bbb_api_url` in your `server.cfg`.

---

## VERSI BAHASA INDONESIA

**Fitur Update v1.1:**
- **Personal Playlist:** Simpan hingga 5 lagu favorit per player.
- **Duration Limit:** Maksimal durasi 10 menit per lagu untuk mencegah penyalahgunaan.

### 1. PERSIAPAN FILE (WAJIB UNTUK SEMUA SERVER)
1. Masukkan `better_boombox.amx` ke folder `filterscripts` server Anda.
2. Buka `server.cfg`, lalu tambahkan `better_boombox` di baris `filterscripts`.
3. Masih di `server.cfg`, tambahkan baris baru untuk IP API Anda:
   ```text
   bbb_api_url http://IP_VPS_ANDA:3000
   ```
   *(Contoh: `bbb_api_url http://103.82.11.55:3000`)*

### 2. CARA PEMASANGAN DI GAMEMODE

#### OPSI A: UNTUK SERVER RP/RPG (Sudah Punya Sistem Inventory / Toko)
Sistem ini dirancang agar **TIDAK** merusak database item Anda.
- Saat player mengeklik "Gunakan" pada item Boombox di inventory Anda, cukup panggil kode ini di Gamemode Anda:
  ```pawn
  CallRemoteFunction("PlaceBetterBoombox", "i", playerid);
  ```
  *(Jangan lupa kurangi item boombox di database player setelah fungsi ini dipanggil).*

- Saat boombox diambil (`/pickupbb`), script ini akan memanggil Gamemode Anda kembali. Tambahkan fungsi ini di Gamemode Anda untuk mengembalikan item ke tas:
  ```pawn
  forward OnBetterBoomboxPickup(playerid);
  public OnBetterBoomboxPickup(playerid) {
      // Berikan item ke player di sini (Contoh: GivePlayerItem(playerid, 1);)
      return 1;
  }
  ```

#### OPSI B: UNTUK SERVER BARU / FREEROAM (Belum Punya Inventory)
Jika Anda hanya ingin player bisa mengeluarkan boombox menggunakan command biasa (tanpa beli di toko), cukup tambahkan command ini di dalam Gamemode Anda:
```pawn
CMD:boombox(playerid, params[]) {
    CallRemoteFunction("PlaceBetterBoombox", "i", playerid);
    return 1;
}

// Opsional: Kosongkan fungsi pickup karena tidak ada sistem inventory
forward OnBetterBoomboxPickup(playerid);
public OnBetterBoomboxPickup(playerid) {
    return 1;
}
```

### 3. MENGATUR MUSIK BOOMBOX
Saat boombox sudah ditaruh di tanah, *Pemilik* boombox cukup mendekat, **berjongkok (crouch)**, dan mengetik:
`/setbb`
Maka panel pengaturan lagu (URL YouTube) dan Jangkauan Jarak akan muncul.

### 4. MENJALANKAN MESIN API (NODE.JS)
Karena sistem ini mandiri dan anti-lag, Anda harus menyalakan mesin API di VPS Anda agar boombox bisa mendownload lagu dari YouTube.
1. Pindahkan folder `API` ke dalam VPS Anda.
2. Buka Terminal/CMD di dalam folder `API` tersebut.
3. Install dependencies:
   ```bash
   npm install
   ```
4. Jalankan mesin:
   ```bash
   node index.js
   ```
   *(Sangat disarankan menggunakan `pm2` agar API hidup 24 jam nonstop: `pm2 start index.js`)*
5. Pastikan IP VPS Anda sudah dimasukkan ke `bbb_api_url` di `server.cfg`.
