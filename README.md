# WikiNusa

An Android app for reading and editing Wikipedia, Wiktionary and Wikibooks in Indonesian, local languages and beyond. Get it from Play Store:

<a href="https://play.google.com/store/apps/details?id=io.github.sslaia.wikinusa"><img alt="Get it on Google Play" src="https://play.google.com/intl/en_us/badges/images/apps/en-play-badge.png" height="80pt"/></a>

## Version's history

<!-- WHATS_NEW_START -->
### New 1.5.8

- Dynamic community registry architecture. Adding new language or wiki project only requires adding its domain and home section selectors in JSON, without modifying core Dart code.
- Language management UI & expanded regional translation. Users can now enable or disable languages (13 languages in total) in the Settings.
- Modular & config-driven community features: the interactive modules (WikiChat, Crosswords, Community Newsletter, Language Course and Gallery) can be configured, enabled or disabled from the Settings.
- Custom hero header images: users can customize the project header banners across wiki projects by choosing images from the Wikimedia Commons
<!-- WHATS_NEW_END -->

### New 1.5.7

- Users can write in Teahouse/Warung Kopi/Monganga afo page in a chat-like format
- Users can now enable/disable modules in their language
- Removed home widget feature due to KGP breaking changes
- App theme updates

### New 1.5.6

- Memory usage optimization
- New newsletter module
- Various minor improvements

### New 1.5.5

- Database reflection failure fix
- 16KB ELF page size compatibility
- ProGuard rules

## Updating Language Manifests & Translations (OTA Checklist)

When adding a new language or updating existing language manifests and UI translations for Over-The-Air (OTA) distribution without releasing a new app version:

1. **Edit or Add Language Files**:
   - Community manifest: `assets/communities/<lang_code>.json`
   - UI translations: `assets/translations/<lang_code>.json`
2. **Update [`assets/communities_index.json`](assets/communities_index.json)**:
   - **Increment `"version"`** (e.g., `1` &rarr; `2`): **Crucial!** Existing app installations compare this version against their local cache and will skip downloading updates for existing languages if the version is not increased.
   - **Update `"lastUpdated"`** timestamp (ISO 8601 UTC, e.g. `"2026-09-21T17:35:00Z"`).
   - **Verify `"languages"` array**: Ensure the language code is present.
3. **Commit & Push to `main`**:
   - Once pushed to GitHub, installed WikiNusa apps detect the version bump and automatically download and apply the updated community files on next launch.

> Detailed guides available in [docs/guide-language-en.md](docs/guide-language-en.md) and [docs/guide-language-id.md](docs/guide-language-id.md).

## Getting the app

WikiNusa app is live on [Google Play Store](https://play.google.com/store/apps/details?id=io.github.sslaia.wikinusa).

## Other relevant apps

WikiNusa app is one of some apps made to support wiki volunteers in Indonesia. Check the other wiki apps on [Nusa Apps](https://sslaia.github.io)
