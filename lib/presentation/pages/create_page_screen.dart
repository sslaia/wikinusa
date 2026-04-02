import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/language_provider.dart';

class CreatePageScreen extends ConsumerStatefulWidget {
  const CreatePageScreen({super.key});

  @override
  ConsumerState<CreatePageScreen> createState() => _CreatePageScreenState();
}

class _CreatePageScreenState extends ConsumerState<CreatePageScreen> {
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _capitalizeTitle(String text) {
    if (text.isEmpty) return text;
    return text.trim().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> _openEditor() async {
    final rawTitle = _titleController.text.trim();
    if (rawTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title first')),
      );
      return;
    }

    final capitalizedTitle = _capitalizeTitle(rawTitle);
    final langCode = ref.read(languageProvider).code;
    
    // Format: https://$langCode.wikipedia.org/wiki/$title?action=edit&section=all
    final encodedTitle = Uri.encodeComponent(capitalizedTitle.replaceAll(' ', '_'));
    final url = Uri.parse(
      'https://$langCode.wikipedia.org/wiki/$encodedTitle?action=edit&section=all',
    );

    // Using inAppBrowserView ensures there is a "Close" or "Back" button 
    // provided by the OS at the top of the browser window.
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url, 
        mode: LaunchMode.inAppBrowserView,
        browserConfiguration: const BrowserConfiguration(showTitle: true),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch editor for $capitalizedTitle')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            const SizedBox(height: 64),
            _buildHeader(theme),
            const SizedBox(height: 32),
            _buildArchiveTitleField(theme),
            const SizedBox(height: 24),
            _buildActionButtons(theme),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF0D5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
              Text(
                'NEW ENTRY',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 9,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Create New Page',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Contribute to Wikipedia\nand make knowledge free for every one.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            height: 1.4,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildArchiveTitleField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TITLE',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 10,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _titleController,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              hintText: 'e.g., The Unexpected Island Effect',
              hintStyle: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info, color: Color(0xFFB51A1E), size: 12),
            const SizedBox(width: 4),
            Text(
              'Enter the title before hitting the Editor button.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFB51A1E),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openEditor,
              borderRadius: BorderRadius.circular(25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Open the Editor',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
