import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../providers/custom_hero_image_provider.dart';
import '../providers/app_state.dart';
import '../services/commons_service.dart';
import '../utils/wiki_utils.dart';

class CustomHeroImageModal extends ConsumerWidget {
  const CustomHeroImageModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CustomHeroImageModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final customImages = ref.watch(customHeroImageProvider);
    final currentLanguage = ref.watch(languageProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.wallpaper_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'custom_hero_images'.tr(),
                            style: GoogleFonts.plusJakartaSans(
                              textStyle: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'custom_hero_images_desc'.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Project cards list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: ProjectType.values.map((project) {
                    final customUrl = customImages[project];
                    final isCustom = customUrl != null && customUrl.isNotEmpty;
                    return _ProjectHeroCard(
                      project: project,
                      customUrl: customUrl,
                      isCustom: isCustom,
                      currentLanguage: currentLanguage,
                      onSearchCommons: () => _openCommonsSearch(context, ref, project),
                      onEnterUrl: () => _openUrlInputDialog(context, ref, project, customUrl),
                      onReset: () async {
                        await ref
                            .read(customHeroImageProvider.notifier)
                            .resetCustomHeroImage(project);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('cover_image_updated'.tr()),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCommonsSearch(BuildContext context, WidgetRef ref, ProjectType project) async {
    final selectedUrl = await showDialog<String>(
      context: context,
      builder: (context) => const CommonsImageSearchDialog(),
    );

    if (selectedUrl != null && selectedUrl.isNotEmpty && context.mounted) {
      await ref
          .read(customHeroImageProvider.notifier)
          .setCustomHeroImage(project, selectedUrl);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cover_image_updated'.tr()),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openUrlInputDialog(
    BuildContext context,
    WidgetRef ref,
    ProjectType project,
    String? currentUrl,
  ) async {
    final controller = TextEditingController(text: currentUrl ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('enter_image_url'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'enter_image_url_hint'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: Text('ok'.tr()),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      await ref
          .read(customHeroImageProvider.notifier)
          .setCustomHeroImage(project, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cover_image_updated'.tr()),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _ProjectHeroCard extends StatelessWidget {
  final ProjectType project;
  final String? customUrl;
  final bool isCustom;
  final String currentLanguage;
  final VoidCallback onSearchCommons;
  final VoidCallback onEnterUrl;
  final VoidCallback onReset;

  const _ProjectHeroCard({
    required this.project,
    required this.customUrl,
    required this.isCustom,
    required this.currentLanguage,
    required this.onSearchCommons,
    required this.onEnterUrl,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = project.getLocalizedDisplayName(currentLanguage);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCustom
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview container
          SizedBox(
            height: 140,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isCustom)
                  Image.network(
                    customUrl!,
                    fit: BoxFit.cover,
                    headers: WikiConfig.uaHeaders,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      project.homeHeroImagePath,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Image.asset(
                    project.homeHeroImagePath,
                    fit: BoxFit.cover,
                  ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                // Project Name and badge
                Positioned(
                  left: 16,
                  bottom: 12,
                  right: 16,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: GoogleFonts.cinzelDecorative(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCustom
                              ? theme.colorScheme.primary
                              : Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isCustom ? 'custom_badge'.tr() : 'default_badge'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Actions row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onEnterUrl,
                  icon: const Icon(Icons.link, size: 18),
                  label: Text('enter_image_url'.tr()),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onSearchCommons,
                  icon: const Icon(Icons.search, size: 18),
                  label: Text('search_commons'.tr()),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (isCustom)
                  TextButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: Text('reset_to_default'.tr()),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommonsImageSearchDialog extends StatefulWidget {
  const CommonsImageSearchDialog({super.key});

  @override
  State<CommonsImageSearchDialog> createState() => _CommonsImageSearchDialogState();
}

class _CommonsImageSearchDialogState extends State<CommonsImageSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await CommonsService.searchImages(query);
      setState(() {
        _results = results;
        _isLoading = false;
        if (results.isEmpty) {
          _errorMessage = 'no_results_found'.tr();
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

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('search_commons'.tr()),
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
                        hintText: 'search_hint'.tr(),
                        prefixIcon: const Icon(Icons.search),
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
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : _results.isEmpty
                          ? Center(
                              child: Text(
                                'search_hint'.tr(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.1,
                              ),
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final item = _results[index];
                                final fileName = item['fileName'] as String? ?? '';
                                final thumbnailUrl = item['thumbnailUrl'] as String? ?? '';

                                return InkWell(
                                  onTap: () {
                                    final fullUrl = CommonsService.getThumbnailUrl(fileName, width: 1200);
                                    Navigator.of(context).pop(fullUrl);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: GridTile(
                                      footer: GridTileBar(
                                        backgroundColor: Colors.black54,
                                        title: Text(
                                          fileName,
                                          style: const TextStyle(fontSize: 11),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      child: Image.network(
                                        thumbnailUrl,
                                        fit: BoxFit.cover,
                                        headers: WikiConfig.uaHeaders,
                                        errorBuilder: (_, _, _) => const Center(
                                          child: Icon(Icons.broken_image),
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
}
