# GUIDE: HOW TO ADD YOUR LANGUAGE TO WIKINUSA

## Introduction

WikiNusa is designed as an open and accessible gateway to free knowledge in the regional and indigenous languages of Indonesia and beyond. To make it effortless for volunteers, language enthusiasts, and local Wikimedia communities to bring their language into the app, WikiNusa features a **modular two-file architecture**.

You **do not need** to write or modify any Dart or Flutter code. Adding or customizing a language only requires editing **two JSON files**:
1. `assets/communities/<language_code>.json` — Community manifest (active Wikimedia projects, page shortcuts, portals, interactive modules, and custom styling rules).
2. `assets/translations/<language_code>.json` — User interface localization strings.

WikiNusa also includes built-in **fault tolerance**. If a formatting error or typo occurs in any individual community file, the app logs the issue and skips that language without crashing or impacting other languages.

---

## Step 1: Choose Your Language Code

Identify the official ISO 639 code (ISO 639-1, 639-2, or 639-3) that corresponds to your language's Wikimedia subdomain.

Examples:
- `ban` for Balinese (*Basa Bali*)
- `ace` for Acehnese (*Bahsa Acèh*)
- `mak` for Makassarese (*Basa Mangkasara'*)
- `min` for Minangkabau (*Baso Minang*)
- `jv` for Javanese (*Basa Jawa*)
- `su` for Sundanese (*Basa Sunda*)
- `nia` for Nias (*Li Niha*)

> **Important:** Both files must use the exact same code in their filenames:  
> `assets/communities/<code>.json` and `assets/translations/<code>.json`.

---

## Step 2: Create the Community Manifest

Create a new file at `assets/communities/<language_code>.json` (for example, `assets/communities/ban.json`).

### File Structure

Here is a full template ready to be copied and customized:

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

### Configuration Keys

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `code` | String | Yes | ISO language code (e.g. `"ban"`). |
| `name` | String | Yes | English or common name of the language (e.g. `"Balinese"`). |
| `nativeName` | String | Yes | Native autonym of the language (e.g. `"Basa Bali"`). |
| `direction` | String | No | Text direction, `"ltr"` (left-to-right) or `"rtl"` (right-to-left). Default: `"ltr"`. |
| `experimental` | Boolean | No | Whether the language is experimental (`true`) or graduated/stable (`false`). Experimental languages display an "Experiment" badge in Language Settings. Default: `false` for primary languages (`id`, `nia`), `true` for others. Set `"experimental": false` to graduate a language without an app release. |
| `defaultProject` | String | No | Default project to open when switching to this language (`"wikipedia"`, `"wiktionary"`, or `"wikibooks"`). |
| `projects` | Object | Yes | Map of active Wikimedia projects for this community. |

### Project Configuration (`projects.<project_key>`)

For each project (`wikipedia`, `wiktionary`, `wikibooks`):
- **`name`**: Local project title (e.g. `"Wikipédia"`, `"Wikikamus"`).
- **`articlePath`**: Article URL pattern with `$1` placeholder (e.g. `"https://ban.wikipedia.org/wiki/$1"`).
- **`apiEndpoint`**: MediaWiki Action API endpoint (e.g. `"https://ban.wikipedia.org/w/api.php"`).
- **`mobileUrl`**: Mobile domain URL.
- **`isIncubator`**: Set to `true` if your language is still in Wikimedia Incubator, along with `incubatorPrefix` (e.g. `"Wp/btm/"`).
- **`homePageSections`**: Map of section selectors used to extract and render clean mobile cards on the Home screen instead of unformatted desktop HTML.
- **`shortcuts`**: List of wiki page titles shown in the Quick Shortcuts menu.
- **`portals`**: List of portal cards shown on the home page.
- **`modules`**: Feature toggles for this language (`chat`, `newsletter`, `crosswords`, `language_course`, `gallery`).

### Home Page Sections Configuration (`homePageSections`)

WikiNusa parses the wiki's Main Page (e.g., `Halaman_Utama`, `Main_Page`, or `Wikipédia:Pendhapa`) and transforms individual content sections into native, touch-friendly cards.

#### Supported Section Keys

| Key | Project | Description | Localized Heading |
| :--- | :--- | :--- | :--- |
| `featuredArticle` | Wikipedia | Featured Article / Lead Story | "FEATURED ARTICLE" / "ARTIKEL PILIHAN" |
| `featuredImage` | Wikipedia / Wiktionary | Picture of the Day / Featured Media | "FEATURED IMAGE" / "GAMBAR PILIHAN" |
| `doYouKnow` | Wikipedia / Wiktionary | "Did You Know" bullet facts | "DID YOU KNOW" / "TAHUKAH ANDA" |
| `inTheNews` | Wikipedia | Current events & headlines | "IN THE NEWS" / "PERISTIWA TERKINI" |
| `onThisDay` | Wikipedia | Historical anniversaries | "ON THIS DAY" / "HARI INI DALAM SEJARAH" |
| `onThisMonth` | Wikipedia | Monthly anniversaries | "ON THIS MONTH" / "BULAN INI DALAM SEJARAH" |
| `featuredList` | Wikipedia | Featured lists & indices | "FEATURED LIST" / "DAFTAR PILIHAN" |
| `featuredWord` | Wiktionary | Word of the day / Selected lemma | "WORD OF THE DAY" / "LEMA TERPILIH" |
| `newWords` | Wiktionary | Newly created dictionary entries | "NEW WORDS" / "LEMA BARU" |
| `featuredBook` | Wikibooks | Featured instructional book | "FEATURED BOOK" / "BUKU PILIHAN" |
| `newBooks` | Wikibooks | New books in development | "NEW BOOKS" / "BUKU BARU" |

#### Section Selector Formats

You can configure each section using either a **Simple String** or a **Detailed Object**:

1. **Simple String (CSS ID or Class)**:
   ```json
   "homePageSections": {
     "featuredArticle": "mp-tfa",
     "featuredImage": "mp-tfp",
     "doYouKnow": "mp-dyk",
     "onThisDay": "mp-otd"
   }
   ```
   > **Note:** IDs can be written with or without a `#` prefix (e.g. `"mp-tfa"` or `"#mp-tfa"`). WikiNusa includes resilient fallbacks between `mp-` (desktop) and `mf-` (MobileFrontend) prefix variants.

2. **Detailed Object (Precision Extraction)**:
   Use this format when the wiki's section contains extraneous navigation links, archive footers, or unstyled tables:
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
   - **`selector`** *(String, Required)*: The CSS selector targeting the section container.
   - **`keep`** *(String or Array of Strings, Optional)*: Specific HTML tags to retain (e.g., `"p"` to keep only paragraphs, or `["p", "ul"]`).
   - **`firstOnly`** *(Boolean, Optional)*: When `true`, extracts only the first matching element within the section, pruning trailing archive links and category blocks.

> [!TIP]
> To standardize your wiki community's Main Page templates with modern CSS classes, refer to the [CSS Standardization Proposal](main-page-css-proposal.md).

### Language-Specific Display Rules (`keep`, `remove`, `hide`)

WikiNusa defines global rules in `assets/communities/_global.json` that remove and hide clutter (such as desktop navigational sidebars and edit tags). If your community needs to preserve an element that is stripped globally, use the `"keep"` key:

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

- **`keep`**: CSS selectors that should **never be stripped or hidden** for this language, overriding global cleanup rules.
- **`remove`**: Additional CSS selectors to strip completely from this project's articles.
- **`hide`**: Additional CSS selectors to hide via CSS styling.

---

## Step 3: Create the UI Translation File

Duplicate `assets/translations/en.json` (or `id.json`) and name it `assets/translations/<language_code>.json` (e.g. `assets/translations/ban.json`).

Open the file in any text editor and translate the strings on the right side of the colon (`:`):

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

> **Tip:** Do not modify the keys on the left (e.g. `"home"`, `"bookmarks"`). Only translate the localized text values on the right.

---

## Step 4: Validate Your JSON Files

Before submitting, check that both JSON files are well-formatted:
1. Ensure all curly braces `{}` and brackets `[]` match and close properly.
2. Ensure there are no **trailing commas** after the last element of an array or object.
3. You can validate your JSON online via [jsonlint.com](https://jsonlint.com/) or run `jq` in your terminal:
   ```bash
   jq . assets/communities/ban.json
   jq . assets/translations/ban.json
   ```

---

## Step 5: Test Locally (Optional for Developers)

If you have a Flutter development environment installed:
1. Run static checks and automated tests:
   ```bash
   flutter test
   ```
2. Launch the app on your device or emulator:
   ```bash
   flutter run
   ```
3. Open the side drawer, tap **Language**, and enable your language. Your community will appear in the UI with its custom portals, shortcuts, and localized text!

---

## Step 6: Submit a Pull Request

1. **Fork** the WikiNusa repository on GitHub: [github.com/sslaia/wikinusa](https://github.com/sslaia/wikinusa).
2. Create a feature branch:
   ```bash
   git checkout -b feat/add-balinese-language
   ```
3. Add your new files:
   ```bash
   git add assets/communities/ban.json assets/translations/ban.json
   git commit -m "feat(community): add Balinese (ban) manifest and translations"
   ```
4. Push to your fork:
   ```bash
   git push origin feat/add-balinese-language
   ```
5. Open a **Pull Request (PR)** against the `main` branch. Our team will review and bundle your language into the next official app release!
