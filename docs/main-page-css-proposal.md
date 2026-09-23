# Panduan Standardisasi CSS & Tata Letak Halaman Utama (Main Page Guide)

Dokumen ini berisi panduan dan usulan CSS standar untuk pengurus HU (interface administrator) dan sukarelawan komunitas Wikimedia bahasa-bahasa daerah.

Tujuannya adalah membuat tampilan Halaman Utama (*Main Page*) lebih rapi dan modern di peramban web, serta memudahkan pemrosesan bagian/seksi di aplikasi seluler tanpa perlu merombak ulang seluruh isi halaman.

## 1. Prinsip Desain

1. **Tanpa Merombak Total:** Konten yang ada (templat, gambar, teks) tidak perlu ditulis ulang. Cukup dibungkus menggunakan tag `<div>` dengan kelas (*class*) dan tanda pengenal (*id*) yang terstandarisasi.
2. **Pemisahan Elemen Bersih:** Memisahkan setiap bagian menjadi:
   - **Judul Bagian** (`h2.hu-header` dengan id `-h2`)
   - **Isi Utama** (`div.hu-content` dengan id utama seksi)
   - **Pranala Terkait/Arsip** (`div.hu-links` dengan id `-pranala`)
3. **Responsif & Ringan:** Menggunakan tata letak kartu (*card layout*) modern yang otomatis menyesuaikan layar desktop maupun ponsel pintar.

## 2. Standar Penamaan ID & Kelas

| Kode Seksi | Keterangan | ID Judul | ID Konten Utama | ID Pranala / Arsip |
| :--- | :--- | :--- | :--- | :--- |
| **`ap`** | Artikel Pilihan *(Featured Article)* | `hu-ap-h2` | `hu-ap` | `hu-ap-pranala` |
| **`ta`** / **`ttb`** | Tahukah Anda / Tahukah Kamu *(Did You Know)* | `hu-ta-h2` | `hu-ta` | `hu-ta-pranala` |
| **`gp`** | Gambar Pilihan *(Featured Picture)* | `hu-gp-h2` | `hu-gp` | `hu-gp-pranala` |
| **`phi`** | Peristiwa Hari Ini *(On This Day)* | `hu-phi-h2` | `hu-phi` | `hu-phi-pranala` |
| **`lp`** / **`kp`** | Lema / Kata Pilihan *(khusus Wikikamus)* | `hu-lp-h2` | `hu-lp` | `hu-lp-pranala` |
| **`bp`** | Buku Pilihan *(khusus Wikibuku)* | `hu-bp-h2` | `hu-bp` | `hu-bp-pranala` |

> [!TIP]
> Awalan **`hu-`** merupakan singkatan dari **Halaman Utama**.

## 3. Contoh Penerapan pada Wikitext

Admin cukup menyisipkan tag pembungkus `div` pada halaman utama (misalnya di `Halaman_Utama` atau templat terkait):

```html
<!-- ==================== SEKSI ARTIKEL PILIHAN ==================== -->
<div class="hu-section" id="hu-ap-box">
  <h2 class="hu-header" id="hu-ap-h2">Artikel Pilihan</h2>
  
  <div class="hu-content" id="hu-ap">
    [[Berkas:Contoh_Gambar.jpg|jmpl|ki|250px|Keterangan gambar]]
    '''Judul Artikel''' adalah bagian pembuka artikel terpilih yang memberikan ringkasan informatif bagi pembaca...
  </div>
  
  <div class="hu-links" id="hu-ap-pranala">
    [[Judul Artikel|Baca selengkapnya...]] • [[Wikipedia:Artikel pilihan/Arsip|Arsip Artikel Pilihan]]
  </div>
</div>

<!-- ==================== SEKSI TAHUKAH ANDA ==================== -->
<div class="hu-section" id="hu-ta-box">
  <h2 class="hu-header" id="hu-ta-h2">Tahukah Anda?</h2>
  
  <div class="hu-content" id="hu-ta">
    * ... bahwa danau vulkanik terbesar di dunia berada di Sumatera Utara?
    * ... bahwa aksara Mandailing secara tradisional disebut Tulak-tulak?
    * ... bahwa rumah adat Nias dibangun tanpa paku besi dan tahan terhadap gempa?
  </div>
  
  <div class="hu-links" id="hu-ta-pranala">
    [[Wikipedia:Tahukah Anda/Arsip|Lihat arsip fakta menarik lainnya...]]
  </div>
</div>
```

## 4. Kode CSS untuk `MediaWiki:Common.css`

Salin kode CSS berikut ke halaman templat di wiki proyek yang bersangkutan, mis Templat:Main Page/styles.css:

```css
/* ==========================================================
   MAIN PAGE STYLES
   Standar css untuk Halaman Utama proyek Wikimedia bahasa daerah
   ========================================================== */

/* 1. Wadah Seksi Utama (Card) */
.hu-section {
  background-color: var(--background-color-base, #ffffff);
  border: 1px solid var(--border-color-subtle, #e0e0e0);
  border-radius: 12px;
  padding: 16px 20px;
  margin-bottom: 20px;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.04);
  clear: both;
}

/* 2. Judul Seksi (H2) */
.hu-section h2.hu-header {
  margin: 0 0 12px 0;
  padding: 0 0 8px 0;
  font-size: 1.2rem;
  font-weight: 700;
  border-bottom: 2px solid var(--border-color-subtle, #f0f0f0);
  color: var(--color-base, #202122);
}

/* 3. Isi Konten */
.hu-section .hu-content {
  font-size: 0.95rem;
  line-height: 1.6;
  color: var(--color-base, #333333);
}

/* Pastikan gambar di dalam konten adaptif dan berbingkai halus */
.hu-section .hu-content img {
  max-width: 100%;
  height: auto;
  border-radius: 8px;
}

/* 4. Baris Tautan Tambahan (Footer Seksi) */
.hu-section .hu-links {
  margin-top: 14px;
  padding-top: 8px;
  border-top: 1px dashed var(--border-color-subtle, #eeeeee);
  text-align: right;
  font-size: 0.85rem;
  color: var(--color-subtle, #555555);
}

.hu-section .hu-links a {
  font-weight: 600;
  text-decoration: none;
}

.hu-section .hu-links a:hover {
  text-decoration: underline;
}

/* 5. Dukungan Tema Gelap (Dark Mode di Vector 2022 / Minerva) */
@media (prefers-color-scheme: dark) {
  html.skin-theme-clientpref-night .hu-section {
    background-color: #1a1a1a;
    border-color: #333333;
    box-shadow: none;
  }
  html.skin-theme-clientpref-night .hu-section h2.hu-header {
    border-bottom-color: #333333;
    color: #f8f9fa;
  }
  html.skin-theme-clientpref-night .hu-section .hu-content {
    color: #e0e0e0;
  }
  html.skin-theme-clientpref-night .hu-section .hu-links {
    border-top-color: #333333;
    color: #aaaaaa;
  }
}
```

## 5. Mengaktifkan & Mengonfigurasi Komunitas di Wikinusa

Agar proses kontribusi mudah bagi pengurus dan sukarelawan komunitas bahasa daerah tanpa risiko konflik Git (*merge conflicts*) atau kesalahan sintaks yang merusak bahasa lain, Wikinusa menggunakan **Dua Berkas Mandiri Per Bahasa (*Two-File Modular Architecture*)**:

1. **Berkas Terjemahan UI:** `assets/translations/<kode_bahasa>.json` 
   Berisi seluruh teks antarmuka aplikasi (menu, tombol, dialog, pengaturan, teks orientasi).
2. **Berkas Konfigurasi Komunitas:** `assets/communities/<kode_bahasa>.json` 
   Setiap bahasa memiliki berkas konfigurasi mandirinya sendiri untuk metadata bahasa, proyek wiki aktif, pemetaan Halaman Utama, jalan pintas menu, modul komunitas, hingga penyesuaian aturan HTML.

### Contoh Berkas Bahasa Mandiri (`assets/communities/su.json`):

```json
{
  "code": "su",
  "name": "Basa Sunda",
  "englishName": "Sundanese",
  "direction": "ltr",
  "projects": {
    "wikipedia": {
      "enabled": true,
      "displayName": "Sundapedia",
      "domain": "su.wikipedia.org",
      "apiPrefix": "",
      "mainPageTitle": "Tepas",
      "chatPageTitle": "Wikipedia:Sawala",
      "homePageSections": {
        "featuredArticle": "hu-ap",
        "doYouKnow": "hu-ta",
        "featuredImage": "hu-gp"
      },
      "portals": [
        { "label": "portal_culture", "title": "Portal:Budaya" }
      ],
      "shortcuts": [
        { "icon": "history", "title": "Parobahan anyar", "pageTitle": "Husus:Parobahan_anyar" }
      ]
    }
  },
  "modules": {
    "chat": {
      "enabled": true,
      "project": "wikipedia",
      "pageTitle": "Wikipedia:Sawala"
    }
  }
}
```

---

## 6. Aturan Global & Cara Menampilkan/Menyimpan Elemen Khusus (`keep`)

Wikinusa secara bawaan memiliki **aturan global** terpusat di `assets/communities/_global.json` yang otomatis membersihkan elemen pengganggu web saat artikel dimuat di aplikasi seluler:
* **Dihapus otomatis (`remove`):** Kotak pesan (`.ambox`), kotak info samping (`.infobox`, `.side-box-flex`), daftar isi (`.toc`), kotak navigasi (`.navbox`), skrip/gaya (`script`, `style`), dll.
* **Disembunyikan otomatis (`hide`):** Daftar rujukan web (`.references`, `.reflist`) yang dialihkan ke lembar sembulan catatan kaki khusus.
* **Kata Kunci Rujukan (`referenceKeywords`):** Mendeteksi tajuk seksi catatan kaki seperti `reference`, `referensi`, `catatan kaki`, `rujukan`, `sumber`, `umbu`, `notes`.

### Bagaimana jika Komunitas Ingin Menampilkan Elemen yang Dihapus/Disembunyikan Global?

Jika komunitas Anda **ingin tetap menampilkan** elemen tertentu (misalnya kotak info `.infobox` atau elemen `.nomobile`) dan tidak ingin dihapus oleh aturan global:

Gunakan kunci **`"keep"`** pada konfigurasi proyek di berkas `assets/communities/<kode_bahasa>.json`:

```json
"projects": {
  "wikipedia": {
    "enabled": true,
    "displayName": "Sundapedia",
    "keep": [
      ".infobox",
      ".nomobile"
    ]
  }
}
```

Elemen yang didaftarkan di dalam `"keep"` secara otomatis **dikecualikan** dari daftar `remove` dan `hide` global khusus untuk proyek bahasa tersebut.

### Opsi Penyesuaian HTML Lainnya (Opsional):

| Kunci | Tipe | Keterangan |
| :--- | :--- | :--- |
| **`keep`** | `Array<string>` | Selektor CSS yang **ingin tetap ditampilkan** (menolak aturan `remove`/`hide` global). |
| **`remove`** | `Array<string>` | Selektor CSS tambahan khusus wiki setempat yang ingin dihapus. |
| **`hide`** | `Array<string>` | Selektor CSS tambahan yang ingin disembunyikan. |
| **`referenceKeywords`** | `Array<string>` | Kata kunci lokal untuk mendeteksi seksi catatan kaki/rujukan (mis. `"umbu"`). |
| **`processingFlags`** | `Array<string>` | Fitur pemrosesan khusus, mis. `["removeEmptySections", "removeEmptyImageSections"]`. |

