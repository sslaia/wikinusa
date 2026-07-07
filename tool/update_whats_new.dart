import 'dart:convert';
import 'dart:io';

void main() {
  final whatsNewFile = File('whats_new.json');
  if (!whatsNewFile.existsSync()) {
    print('Error: whats_new.json not found in current directory!');
    exit(1);
  }

  print('Reading whats_new.json...');
  final jsonContent = whatsNewFile.readAsStringSync();
  final List<dynamic> releases = jsonDecode(jsonContent);

  // 1. Update JSON translation files
  updateTranslations(releases);

  // 2. Update README.md
  updateReadme(releases);

  // 3. Update TODO.md
  updateTodo(releases);

  print('\nAll files updated successfully!');
}

void updateTranslations(List<dynamic> releases) {
  final locales = ['en', 'id'];
  
  // Localized headers and text
  String getVersionHeader(String locale, String version) {
    switch (locale) {
      case 'id':
        return '<h3>Baru di versi $version</h3>';
      case 'en':
      default:
        return '<h3>New in version $version</h3>';
    }
  }

  String getFooter(String locale) {
    switch (locale) {
      case 'id':
        return '<p>Selengkapnya di situs web aplikasi di <a href="https://sslaia.github.io/wikinusa/">https://sslaia.github.io/wikinusa</a>.</p>\n\n<p>Repositori GitHub untuk aplikasi ini adalah: <a href="https://github.com/sslaia/wikinusa">https://github.com/sslaia/wikinusa</a>.</p>\n\n<p>Aplikasi terkait wiki lainnya ada di <a href="https://sslaia.github.io/">Aplikasi Nusa</a></p>';
      case 'en':
      default:
        return '<p>More on the app website at <a href="https://sslaia.github.io/wikinusa/">https://sslaia.github.io/wikinusa</a>.</p>\n\n<p>The GitHub repository for the app is: <a href="https://github.com/sslaia/wikinusa">https://github.com/sslaia/wikinusa</a>.</p>\n\n<p>Other wiki related apps are at <a href="https://sslaia.github.io/">Nusa Apps</a></p>';
    }
  }

  // Clean up nia.json if it exists by removing 'whats_new_content' to enable automatic fallback to en.json
  final niaFile = File('assets/translations/nia.json');
  if (niaFile.existsSync()) {
    try {
      final fileContent = niaFile.readAsStringSync();
      final Map<String, dynamic> data = jsonDecode(fileContent);
      if (data.containsKey('whats_new_content')) {
        print('Cleaning up whats_new_content from assets/translations/nia.json to enable fallback...');
        data.remove('whats_new_content');
        final encoder = JsonEncoder.withIndent('  ');
        niaFile.writeAsStringSync(encoder.convert(data));
      }
    } catch (e) {
      print('Warning: Failed to clean nia.json: $e');
    }
  }

  if (releases.isEmpty) return;
  final latestRelease = releases.first;

  for (final locale in locales) {
    final translationFilePath = 'assets/translations/$locale.json';
    final translationFile = File(translationFilePath);

    if (!translationFile.existsSync()) {
      print('Warning: Translation file $translationFilePath does not exist. Skipping.');
      continue;
    }

    print('Updating $translationFilePath (latest release only)...');
    final fileContent = translationFile.readAsStringSync();
    // Parse while preserving keys order
    final Map<String, dynamic> translationData = jsonDecode(fileContent);

    // Build the HTML content for whats_new_content (latest version only)
    final htmlBuffer = StringBuffer();
    final version = latestRelease['version'] as String;
    final descriptionMap = latestRelease['description'] as Map<String, dynamic>?;
    final changesMap = latestRelease['changes'] as Map<String, dynamic>;

    // Get translated items for this locale, fall back to English if missing
    final description = descriptionMap?[locale] ?? descriptionMap?['en'];
    final changes = changesMap[locale] ?? changesMap['en'] as List<dynamic>?;

    if (changes != null && changes.isNotEmpty) {
      htmlBuffer.write('${getVersionHeader(locale, version)}\n');
      
      if (description != null) {
        htmlBuffer.write('\n$description\n');
      }
      
      htmlBuffer.write('<ul>\n');
      for (final change in changes) {
        htmlBuffer.write('<li>$change</li>\n');
      }
      htmlBuffer.write('</ul>');
    }

    // Append footer
    htmlBuffer.write('\n\n${getFooter(locale)}');

    // Update key
    translationData['whats_new_content'] = htmlBuffer.toString();

    // Write back with 2 spaces indentation
    final encoder = JsonEncoder.withIndent('  ');
    var formattedJson = encoder.convert(translationData);
    translationFile.writeAsStringSync(formattedJson);
  }
}

void updateReadme(List<dynamic> releases) {
  final readmeFile = File('README.md');
  if (!readmeFile.existsSync()) {
    print('Warning: README.md not found.');
    return;
  }

  print('Updating README.md...');
  final content = readmeFile.readAsStringSync();

  // Generate markdown Version History (in English)
  final markdownBuffer = StringBuffer();
  markdownBuffer.write('<!-- WHATS_NEW_START -->\n');

  for (final release in releases) {
    final version = release['version'] as String;
    final changesMap = release['changes'] as Map<String, dynamic>;
    final changes = changesMap['en'] as List<dynamic>?;

    if (changes == null || changes.isEmpty) {
      continue;
    }

    markdownBuffer.write('### Version $version:\n');
    for (final change in changes) {
      markdownBuffer.write('- $change\n');
    }
    markdownBuffer.write('\n');
  }

  // Remove trailing newline if any, then append marker
  var mdContent = markdownBuffer.toString().trimRight();
  mdContent += '\n<!-- WHATS_NEW_END -->';

  final startMarker = '<!-- WHATS_NEW_START -->';
  final endMarker = '<!-- WHATS_NEW_END -->';

  final startIndex = content.indexOf(startMarker);
  final endIndex = content.indexOf(endMarker);

  if (startIndex == -1 || endIndex == -1) {
    print('Warning: Placeholders <!-- WHATS_NEW_START --> and <!-- WHATS_NEW_END --> not found in README.md!');
    return;
  }

  final updatedContent = content.replaceRange(
    startIndex,
    endIndex + endMarker.length,
    mdContent,
  );

  readmeFile.writeAsStringSync(updatedContent);
}

void updateTodo(List<dynamic> releases) {
  final todoFile = File('TODO.md');
  if (!todoFile.existsSync()) {
    print('Warning: TODO.md not found.');
    return;
  }

  print('Updating TODO.md...');
  final content = todoFile.readAsStringSync();

  if (releases.isEmpty) return;
  final latestRelease = releases.first;
  
  final markdownBuffer = StringBuffer();
  markdownBuffer.write('<!-- WHATS_NEW_START -->\n');

  final version = latestRelease['version'] as String;
  final changesMap = latestRelease['changes'] as Map<String, dynamic>;
  final changes = changesMap['en'] as List<dynamic>?;

  if (changes != null && changes.isNotEmpty) {
    // Capitalization matches the existing style in TODO.md: "### New 1.5.2"
    markdownBuffer.write('### New $version\n');
    for (final change in changes) {
      markdownBuffer.write('- $change\n');
    }
  }

  // Remove trailing newline, then append marker
  var mdContent = markdownBuffer.toString().trimRight();
  mdContent += '\n<!-- WHATS_NEW_END -->';

  final startMarker = '<!-- WHATS_NEW_START -->';
  final endMarker = '<!-- WHATS_NEW_END -->';

  final startIndex = content.indexOf(startMarker);
  final endIndex = content.indexOf(endMarker);

  if (startIndex == -1 || endIndex == -1) {
    print('Warning: Placeholders <!-- WHATS_NEW_START --> and <!-- WHATS_NEW_END --> not found in TODO.md!');
    return;
  }

  final updatedContent = content.replaceRange(
    startIndex,
    endIndex + endMarker.length,
    mdContent,
  );

  todoFile.writeAsStringSync(updatedContent);
}
