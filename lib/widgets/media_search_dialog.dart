import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/commons_service.dart';

class MediaSearchDialog extends StatefulWidget {
  const MediaSearchDialog({super.key});

  @override
  State<MediaSearchDialog> createState() => _MediaSearchDialogState();
}

class _MediaSearchDialogState extends State<MediaSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _getLocalString(String key, String localeCode) {
    final Map<String, Map<String, String>> strings = {
      'en': {
        'search_images': 'Search Commons',
        'search_hint': 'Search for images...',
        'no_results_found': 'No images found.',
        'image_caption': 'Image Caption',
        'caption_hint': 'Enter image description...',
        'select': 'Select Image',
        'ok': 'OK',
      },
      'id': {
        'search_images': 'Cari di Commons',
        'search_hint': 'Cari gambar...',
        'no_results_found': 'Gambar tidak ditemukan.',
        'image_caption': 'Keterangan Gambar',
        'caption_hint': 'Masukkan deskripsi gambar...',
        'select': 'Pilih Gambar',
        'ok': 'OK',
      },
      'nia': {
        'search_images': 'Alui ba Commons',
        'search_hint': 'Alui gambara...',
        'no_results_found': 'Lö gambara si faudu.',
        'image_caption': 'Keterangan Gambara',
        'caption_hint': 'Suratö zanandrösa ba gambara...',
        'select': 'Fili Gambara',
        'ok': 'OK',
      },
      'jv': {
        'search_images': 'Golek ing Commons',
        'search_hint': 'Golek gambar...',
        'no_results_found': 'Gambar ora ditemokake.',
        'image_caption': 'Katrangan Gambar',
        'caption_hint': 'Lebokake katrangan gambar...',
        'select': 'Pilih Gambar',
        'ok': 'OK',
      },
    };
    final lang = strings.containsKey(localeCode) ? localeCode : 'en';
    return strings[lang]?[key] ?? strings['en']![key]!;
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final locale = EasyLocalization.of(context)?.locale.languageCode ?? 'en';

    try {
      final results = await CommonsService.searchImages(query);
      setState(() {
        _results = results;
        _isLoading = false;
        if (results.isEmpty) {
          _errorMessage = _getLocalString('no_results_found', locale);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'error'.tr();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = EasyLocalization.of(context)?.locale.languageCode ?? 'en';
    
    final String searchTitle = _getLocalString('search_images', locale);
    final String searchHint = _getLocalString('search_hint', locale);

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(searchTitle),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: searchHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _performSearch,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final image = _results[index];
                            final url = image['thumbnailUrl'] as String;
                            final fileName = image['fileName'] as String;
                            return GestureDetector(
                              onTap: () => _openPreview(image),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  child: GridTile(
                                    footer: GridTileBar(
                                      backgroundColor: Colors.black54,
                                      title: Text(
                                        fileName,
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(child: Icon(Icons.broken_image));
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPreview(Map<String, dynamic> image) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => MediaPreviewDialog(image: image, getLocalString: _getLocalString),
    );
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }
}

class MediaPreviewDialog extends StatelessWidget {
  final Map<String, dynamic> image;
  final String Function(String key, String localeCode) getLocalString;

  const MediaPreviewDialog({
    super.key,
    required this.image,
    required this.getLocalString,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = EasyLocalization.of(context)?.locale.languageCode ?? 'en';
    final fileName = image['fileName'] as String;
    final url = image['url'] as String;

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            fileName,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            overflow: TextOverflow.fade,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                      );
                    },
                  ),
                ),
              ),
            ),
            Container(
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('go_back'.tr()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _promptCaption(context),
                      child: Text(getLocalString('select', locale)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _promptCaption(BuildContext context) async {
    final locale = EasyLocalization.of(context)?.locale.languageCode ?? 'en';
    final caption = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(getLocalString('image_caption', locale)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: getLocalString('caption_hint', locale),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: Text(getLocalString('ok', locale)),
            ),
          ],
        );
      },
    );

    if (caption != null && context.mounted) {
      final fileName = image['fileName'] as String;
      final wikitext = '[[Berkas:$fileName|jmpl|$caption]]';
      Navigator.of(context).pop(wikitext);
    }
  }
}
