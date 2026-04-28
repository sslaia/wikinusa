import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wikinusa/models/project_type.dart';
import 'package:wikinusa/providers/app_state.dart';
import 'package:wikinusa/providers/wiki_api_provider.dart';
import 'package:wikinusa/screens/article_screen.dart';
import 'package:wikinusa/services/wiki_api_service.dart';

import '../screens/create_book_screen.dart';
import '../screens/create_entry_screen.dart';
import '../screens/create_page_screen.dart';
import 'shortcuts_bottom_sheet.dart';

class CustomBottomAppBar extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ProjectType currentProject;
  final bool isHomeScreen;
  final String? pageTitle;

  const CustomBottomAppBar({
    super.key,
    required this.scaffoldKey,
    required this.currentProject,
    this.isHomeScreen = false,
    this.pageTitle,
  });

  @override
  ConsumerState<CustomBottomAppBar> createState() => _CustomBottomAppBarState();
}

class _CustomBottomAppBarState extends ConsumerState<CustomBottomAppBar> {
  bool _isFetchingRandom = false;

  Future<void> _navigateToRandomArticle() async {
    setState(() => _isFetchingRandom = true);
    
    try {
      final langCode = context.locale.languageCode;
      final projectStr = widget.currentProject.name.toLowerCase();
      
      final randomTitle = await WikiApiService.fetchRandomArticleTitle(langCode, projectStr);
      
      if (randomTitle != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleScreen(title: randomTitle),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_fetching_random_article').tr()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingRandom = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final langCode = context.locale.languageCode;

    return BottomAppBar(
      color: colorScheme.primary,
      child: IconTheme(
        data: IconThemeData(color: colorScheme.onPrimary),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                widget.scaffoldKey.currentState?.openDrawer();
              },
            ),
            const SizedBox(width: 8),
            Text(
              widget.currentProject.name.toLowerCase().tr(),
              style: GoogleFonts.cinzelDecorative(
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            if (!widget.isHomeScreen)
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            if (widget.isHomeScreen)
              IconButton(
                icon: const Icon(Icons.edit_note_outlined),
                onPressed: () {
                  Widget destination;
                  if (widget.currentProject == ProjectType.wikipedia) {
                    destination = const CreatePageScreen();
                  } else if (langCode == 'nia' && widget.currentProject == ProjectType.wiktionary) {
                    destination = const CreateEntryScreen();
                  } else if (langCode == 'nia' && widget.currentProject == ProjectType.wikibooks) {
                    destination = const CreateBookScreen();
                  } else {
                    destination = const CreatePageScreen();
                  }
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => destination,
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                final langCode = ref.read(languageProvider);
                await WikiApiService.clearCache(
                  widget.currentProject, 
                  langCode, 
                  widget.isHomeScreen ? null : widget.pageTitle
                );
                
                // 2. Invalidate the provider to trigger a fresh rebuild
                final targetTitle = widget.isHomeScreen ? null : widget.pageTitle;
                ref.invalidate(wikiApiProvider(targetTitle));
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('refreshing_content').tr(),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.switch_access_shortcut_outlined),
              onPressed: () {
                showShortcutsBottomSheet(context, ref);
              },
            ),
            _isFetchingRandom 
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.shuffle),
                  onPressed: _navigateToRandomArticle,
                ),
          ],
        ),
      ),
    );
  }
}
