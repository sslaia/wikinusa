# PANDUAN MENAMBAHKAN BAHASA BARU KE WIKINUSA

## Pengantar

WikiNusa dirancang sebagai aplikasi pelestarian dan pembuka akses pengetahuan dalam bahasa daerah di Indonesia dan sekitarnya. Untuk mempermudah para relawan, pemerhati bahasa, dan komunitas Wikimedia daerah, WikiNusa menggunakan **arsitektur modular dua berkas**.

Anda **tidak perlu** memahami atau mengubah kode pemrograman Dart/Flutter sama sekali. Cukup dengan menyiapkan dan menyunting **dua berkas JSON**:
1. `assets/communities/<kode_bahasa>.json` — Berkas konfigurasi komunitas (proyek Wikimedia aktif, pintasan halaman, portal, modul, dan penyesuaian aturan tampilan).
2. `assets/translations/<kode_bahasa>.json` — Berkas penerjemahan antarmuka pengguna (UI) ke dalam bahasa Anda.

Sistem WikiNusa dilengkapi dengan **isolasi kesalahan (*fault tolerance*)**. Apabila terjadi kesalahan sintaksis atau ketik pada salah satu berkas bahasa, aplikasi hanya akan melewati berkas tersebut tanpa memengaruhi bahasa-bahasa lain atau membuat aplikasi mogok (*crash*).

---

## Langkah 1: Tentukan Kode Bahasa

Gunakan kode bahasa resmi ISO 639 (ISO 639-1, 639-2, atau 639-3) yang sesuai dengan sub-domain Wikimedia bahasa Anda. 

Contoh:
- `ban` untuk Bahasa Bali
- `ace` untuk Bahasa Aceh
- `mak` untuk Bahasa Makassar
- `min` untuk Bahasa Minangkabau
- `jv` untuk Bahasa Jawa
- `su` untuk Bahasa Sunda
- `nia` untuk Bahasa Nias

> **Penting:** Nama kedua berkas Anda harus menggunakan kode yang sama persis:  
> `assets/communities/<kode>.json` dan `assets/translations/<kode>.json`.

---

## Langkah 2: Buat Berkas Konfigurasi Komunitas

Buat berkas baru bernama `assets/communities/<kode>.json` (contoh: `assets/communities/ban.json`).

### Struktur Format Berkas

Berikut adalah templat lengkap yang dapat Anda salin dan sesuaikan:

```json
{
  "code": "ban",
  "name": "Balinese",
  "nativeName": "Basa Bali",
  "direction": "ltr",
  "experimental": false,
  "defaultProject": "wikipedia",
  "projects": {
    "wikipedia": {
      "name": "Wikipédia",
      "articlePath": "https://ban.wikipedia.org/wiki/$1",
      "apiEndpoint": "https://ban.wikipedia.org/w/api.php",
      "mobileUrl": "https://ban.m.wikipedia.org",
      "isIncubator": false,
      "homePageSections": {
        "featuredArticle": "mp-tfa",
        "featuredImage": "mp-tfp",
        "doYouKnow": "mp-dyk",
        "onThisDay": "mp-otd"
      },
      "shortcuts": [
        "Portal:Komunitas",
        "Istimewa:Perubahan_terbaru",
        "Wikipédia:Pitulung"
      ],
      "portals": [
        {
          "title": "Budaya",
          "page": "Portal:Budaya"
        }
      ],
      "modules": {
        "chat": true,
        "newsletter": false,
        "crosswords": false,
        "language_course": false,
        "gallery": false
      }
    },
    "wiktionary": {
      "name": "Wikikamus",
      "articlePath": "https://ban.wiktionary.org/wiki/$1",
      "apiEndpoint": "https://ban.wiktionary.org/w/api.php",
      "mobileUrl": "https://ban.m.wiktionary.org",
      "isIncubator": false,
      "homePageSections": {
        "featuredWord": "mp-word-day-body",
        "newWords": "mp-new-words-body"
      },
      "shortcuts": [
        "Wikikamus:Pitulung"
      ]
    }
  }
}
```

### Penjelasan Kunci Konfigurasi

| Kunci | Tipe | Wajib | Keterangan |
| :--- | :--- | :--- | :--- |
| `code` | String | Ya | Kode bahasa ISO (misal: `"ban"`). |
| `name` | String | Ya | Nama umum bahasa (misal: `"Balinese"` atau `"Bali"`). |
| `nativeName` | String | Ya | Nama bahasa dalam penutur aslinya (misal: `"Basa Bali"`). |
| `direction` | String | Tidak | Arah tulisan, `"ltr"` (kiri-ke-kanan) atau `"rtl"` (kanan-ke-kiri). Standar: `"ltr"`. |
| `experimental` | Boolean | Tidak | Menandakan apakah bahasa masih dalam tahap eksperimen (`true`) atau sudah stabil/lulus (`false`). Bahasa eksperimen menampilkan lencana "Eksperimen" di Pengaturan Bahasa. Standar: `false` untuk bahasa utama (`id`, `nia`), dan `true` untuk bahasa komunitas lainnya. Setel `"experimental": false` agar bahasa lulus tanpa perlu rilis pembaruan aplikasi. |
| `defaultProject` | String | Tidak | Proyek pertama yang terbuka saat bahasa ini dipilih (`"wikipedia"`, `"wiktionary"`, atau `"wikibooks"`). |
| `projects` | Objek | Ya | Daftar proyek Wikimedia yang aktif untuk bahasa ini. |

### Konfigurasi Proyek (`projects.<jenis_proyek>`)

Setiap proyek (`wikipedia`, `wiktionary`, `wikibooks`) memiliki parameter:
- **`name`**: Nama proyek lokal (misal: `"Wikipédia"`, `"Wikikamus"`).
- **`articlePath`**: Pola tautan artikel dengan `$1` sebagai pengganti judul (misal: `"https://ban.wikipedia.org/wiki/$1"`).
- **`apiEndpoint`**: URL titik akhir MediaWiki API (misal: `"https://ban.wikipedia.org/w/api.php"`).
- **`mobileUrl`**: URL versi seluler situs.
- **`isIncubator`**: Setel `true` jika bahasa Anda masih berada di Wikimedia Incubator (belum memiliki subdomain mandiri), dan tentukan `incubatorPrefix` (misal: `"Wp/btm/"`).
- **`homePageSections`**: Pemetaan selektor untuk mengekstrak dan menampilkan seksi halaman utama dalam format kartu ponsel yang rapi (bukan tampilan desktop mentah).
- **`shortcuts`**: Daftar judul halaman wiki yang ingin ditampilkan pada menu pintasan cepat.
- **`portals`**: Daftar judul portal dan halaman tujuannya untuk ditampilkan di kartu beranda.
- **`modules`**: Sakelar fitur interaktif untuk komunitas Anda (`chat` untuk ruang diskusi komunitas, `newsletter` untuk buletin, `crosswords` untuk TTS, `language_course` untuk kursus, `gallery` untuk galeri).

### Konfigurasi Seksi Beranda (`homePageSections`)

WikiNusa memproses Halaman Utama wiki (seperti `Halaman_Utama`, `Main_Page`, atau `Wikipédia:Pendhapa`) dan mengubah setiap bagian konten menjadi kartu interaktif native di beranda aplikasi.

#### Kunci Seksi yang Didukung

| Kunci | Proyek | Deskripsi | Judul Tampilan |
| :--- | :--- | :--- | :--- |
| `featuredArticle` | Wikipedia | Artikel Pilihan utama | "ARTIKEL PILIHAN" / "FEATURED ARTICLE" |
| `featuredImage` | Wikipedia / Wiktionary | Gambar Pilihan / Foto hari ini | "GAMBAR PILIHAN" / "FEATURED IMAGE" |
| `doYouKnow` | Wikipedia / Wiktionary | Fakta menarik "Tahukah Anda" | "TAHUKAH ANDA" / "DID YOU KNOW" |
| `inTheNews` | Wikipedia | Peristiwa terkini & warta berita | "PERISTIWA TERKINI" / "IN THE NEWS" |
| `onThisDay` | Wikipedia | Peristiwa hari ini dalam sejarah | "HARI INI DALAM SEJARAH" / "ON THIS DAY" |
| `onThisMonth` | Wikipedia | Peristiwa bulan ini dalam sejarah | "BULAN INI DALAM SEJARAH" / "ON THIS MONTH" |
| `featuredList` | Wikipedia | Daftar pilihan | "DAFTAR PILIHAN" / "FEATURED LIST" |
| `featuredWord` | Wiktionary | Lema terpilih / kata hari ini | "LEMA TERPILIH" / "WORD OF THE DAY" |
| `newWords` | Wiktionary | Lema baru yang baru ditambahkan | "LEMA BARU" / "NEW WORDS" |
| `featuredBook` | Wikibooks | Buku pilihan pembelajaran | "BUKU PILIHAN" / "FEATURED BOOK" |
| `newBooks` | Wikibooks | Buku baru yang sedang disusun | "BUKU BARU" / "NEW BOOKS" |

#### Format Penulisan Selektor

Setiap seksi dapat diatur menggunakan **String Sederhana** atau **Objek Terperinci**:

1. **Format String Sederhana (ID atau Kelas CSS)**:
   ```json
   "homePageSections": {
     "featuredArticle": "mp-tfa",
     "featuredImage": "mp-tfp",
     "doYouKnow": "mp-dyk",
     "onThisDay": "mp-otd"
   }
   ```
   > **Catatan:** ID elemen dapat ditulis langsung dengan atau tanpa tanda pagar `#` (contoh: `"mp-tfa"` atau `"#mp-tfa"`). WikiNusa juga otomatis memeriksa variasi awalan `mp-` (desktop) dan `mf-` (seluler/MobileFrontend).

2. **Format Objek Terperinci (Ekstraksi Presisi)**:
   Gunakan format ini jika kotak templat di wiki Anda memiliki pranala navigasi arsip, tombol sunting, atau tabel yang perlu dirapikan:
   ```json
   "homePageSections": {
     "featuredArticle": {
       "selector": "mf-artikelpilihan",
       "keep": "p",
       "firstOnly": true
     },
     "doYouKnow": {
       "selector": "mf-tahukahanda",
       "keep": "ul",
       "firstOnly": true
     }
   }
   ```
   - **`selector`** *(String, Wajib)*: Selektor CSS dari elemen pembungkus konten di Halaman Utama.
   - **`keep`** *(String atau Array of Strings, Opsional)*: Tag HTML tertentu yang ingin dipertahankan (misal `"p"` agar hanya mengambil paragraf ringkasan, atau `["p", "ul"]`).
   - **`firstOnly`** *(Boolean, Opsional)*: Bila bernilai `true`, hanya mengambil elemen pertama yang cocok dan membuang pranala arsip tambahan di bawahnya.

> [!TIP]
> Untuk menyelaraskan templat Halaman Utama wiki bahasa Anda dengan kelas CSS standar modern, silakan baca [Panduan Standarisasi CSS Halaman Utama](main-page-css-proposal.md).

### Penyesuaian Tampilan Khusus Bahasa (`keep`, `remove`, `hide`)

Secara umum, WikiNusa memiliki aturan global di `assets/communities/_global.json` untuk membersihkan elemen web yang kurang rapi di layar ponsel. Namun, jika komunitas Anda ingin menampilkan elemen tertentu yang biasanya dihilangkan oleh aturan global, Anda cukup menambahkan kunci `"keep"`:

```json
"projects": {
  "wikipedia": {
    "name": "Wikipédia",
    "articlePath": "https://ban.wikipedia.org/wiki/$1",
    "apiEndpoint": "https://ban.wikipedia.org/w/api.php",
    "keep": [".infobox", ".nomobile"],
    "remove": [".reflist"]
  }
}
```

- **`keep`**: Selektor CSS yang **tidak boleh dibuang/disembunyikan** untuk bahasa ini, meskipun aturan global menyuruh menghapusnya.
- **`remove`**: Selektor CSS tambahan yang ingin dihapus dari artikel bahasa ini.
- **`hide`**: Selektor CSS tambahan yang ingin disembunyikan menggunakan gaya CSS.

---

## Langkah 3: Buat Berkas Terjemahan Antarmuka

Salin berkas `assets/translations/id.json` atau `assets/translations/en.json` dan beri nama sesuai kode bahasa Anda, misalnya `assets/translations/ban.json`.

Buka berkas tersebut dengan editor teks (seperti VS Code atau Notepad), lalu terjemahkan teks di sebelah kanan tanda titik dua (`:`):

```json
{
  "app_name": "WikiNusa",
  "home": "Kaca Utama",
  "shortcuts": "Pintasan",
  "random": "Acak",
  "bookmarks": "Tanda Buku",
  "search_hint": "Rereh ring WikiNusa...",
  "share": "Bagikan",
  "edit": "Uwah",
  "view_in_browser": "Cingak ring Browser",
  "table_of_contents": "Daftar Isi",
  "drawer_modules": "Modul Komunitas",
  "drawer_language": "Basa",
  "drawer_appearance": "Tampilan",
  "drawer_font_size": "Ukuran Aksara",
  "drawer_about": "Indik Aplikasi"
}
```

> **Tips:** Jangan ubah kunci di sebelah kiri (misalnya `"home"`, `"bookmarks"`). Cukup terjemahkan nilai teks di sebelah kanan.

---

## Langkah 4: Validasi Berkas JSON

Sebelum mengirimkan kontribusi Anda, pastikan berkas JSON Anda bebas dari kesalahan sintaksis:
1. Pastikan setiap tanda kurung kurawal `{}` dan kurung siku `[]` tertutup dengan benar.
2. Pastikan tidak ada **koma berlebih di akhir (*trailing comma*)**, misalnya setelah item terakhir dalam daftar atau objek.
3. Anda dapat memvalidasi berkas JSON secara daring di [jsonlint.com](https://jsonlint.com/) atau melalui terminal menggunakan `jq`:
   ```bash
   jq . assets/communities/ban.json
   jq . assets/translations/ban.json
   ```

---

## Langkah 5: Uji Coba Aplikasi (Opsional bagi Pengembang)

Jika Anda memiliki lingkungan Flutter di komputer Anda:
1. Pastikan seluruh berkas terdeteksi:
   ```bash
   flutter test
   ```
2. Jalankan aplikasi pada emulator atau perangkat fisik:
   ```bash
   flutter run
   ```
3. Buka menu samping, pilih **Bahasa**, lalu aktifkan bahasa yang baru Anda tambahkan. Bahasa baru Anda akan langsung muncul di antarmuka dan halaman depan!

---

## Langkah 6: Kirimkan Kontribusi (Pull Request)

1. **Fork** repositori WikiNusa di GitHub: [github.com/sslaia/wikinusa](https://github.com/sslaia/wikinusa).
2. Buat branch baru untuk kontribusi Anda:
   ```bash
   git checkout -b feat/tambah-bahasa-bali
   ```
3. Masukkan kedua berkas baru Anda:
   ```bash
   git add assets/communities/ban.json assets/translations/ban.json
   git commit -m "feat(community): tambah konfigurasi dan terjemahan bahasa Bali (ban)"
   ```
4. Unggah ke akun GitHub Anda:
   ```bash
   git push origin feat/tambah-bahasa-bali
   ```
5. Buat **Pull Request (PR)** ke repositori utama. Pengelola WikiNusa akan meninjau dan menggabungkan kontribusi Anda untuk rilis aplikasi berikutnya!
