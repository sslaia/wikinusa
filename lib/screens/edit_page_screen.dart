import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_state.dart';
import '../providers/auth_provider.dart';
import '../services/edit_service.dart';

class EditPageScreen extends ConsumerStatefulWidget {
  final String title;
  final String? preloadTemplate;

  const EditPageScreen({super.key, required this.title, this.preloadTemplate});

  @override
  ConsumerState<EditPageScreen> createState() => _EditPageScreenState();
}

class _EditPageScreenState extends ConsumerState<EditPageScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();

  bool _isLoadingText = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWikitext();
  }

  @override
  void dispose() {
    _textController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _loadWikitext() async {
    setState(() {
      _isLoadingText = true;
      _errorMessage = null;
    });

    final currentProject = ref.read(appStateProvider);
    final languageCode = ref.read(languageProvider);

    final wikitext = await EditService.fetchWikitext(
      project: currentProject,
      languageCode: languageCode,
      title: widget.title,
    );

    if (wikitext != null) {
      if (wikitext.isEmpty && widget.preloadTemplate != null) {
        final templateText = await EditService.fetchWikitext(
          project: currentProject,
          languageCode: languageCode,
          title: widget.preloadTemplate!,
        );
        _textController.text = templateText ?? "";
      } else {
        _textController.text = wikitext;
      }
    } else {
      _errorMessage = 'error_loading_content'.tr();
    }

    if (mounted) {
      setState(() {
        _isLoadingText = false;
      });
    }
  }

  Future<void> _showPublishDialog() async {
    final authState = ref.read(authProvider);

    if (!authState.isLoggedIn) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('login_required'.tr())));
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final dialogTheme = Theme.of(dialogContext);
        return AlertDialog(
          title: Text('confirm_edit_title'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('confirm_edit_message'.tr()),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: dialogTheme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _summaryController,
                    decoration: InputDecoration(
                      labelText: 'edit_summary'.tr(),
                      labelStyle: TextStyle(
                        color: dialogTheme.colorScheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: dialogTheme.colorScheme.outline.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: dialogTheme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('go_back'.tr()),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3366CC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _submitEdit();
              },
              child: Text('submit'.tr().toUpperCase()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitEdit() async {
    final authState = ref.read(authProvider);

    if (!authState.isLoggedIn) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('login_required'.tr())));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final accessToken = await ref
          .read(authProvider.notifier)
          .getValidAccessToken();
      if (accessToken == null) {
        throw Exception('session_expired'.tr());
      }

      final currentProject = ref.read(appStateProvider);
      final languageCode = ref.read(languageProvider);

      final csrfToken = await EditService.fetchCsrfToken(
        project: currentProject,
        languageCode: languageCode,
        accessToken: accessToken,
      );

      if (csrfToken == null) {
        throw Exception('csrf_error'.tr());
      }

      final success = await EditService.editPage(
        project: currentProject,
        languageCode: languageCode,
        title: widget.title,
        text: _textController.text,
        summary: _summaryController.text.isEmpty
            ? 'edit_summary_default'.tr()
            : _summaryController.text,
        accessToken: accessToken,
        csrfToken: csrfToken,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('edit_success'.tr())));
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('api_error'.tr());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${'edit_error'.tr()} $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _insertFormatting(String prefix, String suffix) {
    final text = _textController.text;
    final selection = _textController.selection;
    final int start = selection.start;
    final int end = selection.end;

    if (start < 0 || end < 0) {
      final newText = text + prefix + suffix;
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      return;
    }

    final selectedText = text.substring(start, end);
    final replacement = prefix + selectedText + suffix;
    final newText = text.replaceRange(start, end, replacement);
    final newCursorOffset =
        start +
        prefix.length +
        selectedText.length +
        (selectedText.isEmpty ? 0 : suffix.length);

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }

  String _getToolbarTooltip(String key, String locale) {
    final Map<String, Map<String, String>> tooltips = {
      'en': {
        'heading': 'Heading 2 (==)',
        'bold': "Bold (''')",
        'italic': "Italic ('')",
        'link': 'Link ([[]])',
        'pipe': 'Pipe (|)',
        'template': 'Template ({{}})',
        'numbered_list': 'Numbered List (#)',
        'unordered_list': 'Bullet List (*)',
        'signature': 'Signature (~~~~)',
      },
      'id': {
        'heading': 'Judul 2 (==)',
        'bold': "Tebal (''')",
        'italic': "Miring ('')",
        'link': 'Tautan ([[]])',
        'pipe': 'Pipa (|)',
        'template': 'Templat ({{}})',
        'numbered_list': 'Daftar Bernomor (#)',
        'unordered_list': 'Daftar Bulatan (*)',
        'signature': 'Tanda Tangan (~~~~)',
      },
      'nia': {
        'heading': 'Högö 2 (==)',
        'bold': "Ni'awe'e-we'e'ö (''')",
        'italic': "Nifaöndrö ('')",
        'link': 'Khai-khai ([[]])',
        'pipe': 'Pipa (|)',
        'template': 'Templat ({{}})',
        'numbered_list': 'Angolita nifonumero (#)',
        'unordered_list': 'Angolita nifondröfi (*)',
        'signature': 'Teka (~~~~)',
      },
      'jv': {
        'heading': 'Judul 2 (==)',
        'bold': "Tebal (''')",
        'italic': "Miring ('')",
        'link': 'Tautan ([[]])',
        'pipe': 'Pipa (|)',
        'template': 'Templat ({{}})',
        'numbered_list': 'Daftar Bernomor (#)',
        'unordered_list': 'Daftar Bulatan (*)',
        'signature': 'Tanda Tangan (~~~~)',
      },
    };

    final lang = tooltips.containsKey(locale) ? locale : 'en';
    return tooltips[lang]?[key] ?? tooltips['en']![key]!;
  }

  Widget _buildToolbarButton({
    required Widget child,
    required VoidCallback onTap,
    required String tooltip,
    required ThemeData theme,
  }) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 40,
              constraints: const BoxConstraints(minWidth: 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormattingToolbar(ThemeData theme) {
    final locale = EasyLocalization.of(context)?.locale.languageCode ?? 'en';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.15,
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: [
            _buildToolbarButton(
              theme: theme,
              tooltip: _getToolbarTooltip('heading', locale),
              child: Text(
                'H',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              onTap: () => _insertFormatting('== ', ' =='),
            ),
            _buildToolbarButton(
              theme: theme,
              tooltip: _getToolbarTooltip('bold', locale),
              child: Icon(
                Icons.format_bold,
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
              onTap: () => _insertFormatting("'''", "'''"),
            ),
            _buildToolbarButton(
              theme: theme,
              tooltip: _getToolbarTooltip('italic', locale),
              child: Icon(
                Icons.format_italic,
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
              onTap: () => _insertFormatting("''", "''"),
            ),
            _buildToolbarButton(
              theme: theme,
              tooltip: _getToolbarTooltip('link', locale),
              child: Text(
                '[[]]',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onTap: () => _insertFormatting('[[', ']]'),
            ),
            _buildToolbarButton(
              theme: theme,
              tooltip: _getToolbarTooltip('pipe', locale),
              child: Text(
                '|',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onTap: () => _insertFormatting('|', ''),
            ),
            _buildToolbarButton(
              theme: theme,
              tooltip: _getToolbarTooltip('template', locale),
              child: Text(
                '{{}}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onTap: () => _insertFormatting('{{', '}}'),
            ),
            _buildToolbarButton(
              theme: theme,
              tooltip: _getToolbarTooltip('numbered_list', locale),
              child: Icon(
                Icons.format_list_numbered,
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
              onTap: () => _insertFormatting('# ', ''),
            ),
            _buildToolbarButton(
              theme: theme,
              tooltip: _getToolbarTooltip('unordered_list', locale),
              child: Icon(
                Icons.format_list_bulleted,
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
              onTap: () => _insertFormatting('* ', ''),
            ),
            _buildToolbarButton(
              theme: theme,
              tooltip: _getToolbarTooltip('signature', locale),
              child: Icon(
                Icons.history_edu,
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
              onTap: () => _insertFormatting('~~~~', ''),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: theme.colorScheme.onSurface),
          overflow: TextOverflow.fade,
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (!_isLoadingText && _errorMessage == null)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 8.0,
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3366CC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: _showPublishDialog,
                child: Text(
                  'submit'.tr().toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: _isLoadingText
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadWikitext,
                      icon: const Icon(Icons.refresh),
                      label: Text('retry'.tr()),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  _buildFormattingToolbar(theme),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Scrollbar(
                          child: TextField(
                            controller: _textController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'edit_content_hint'.tr(),
                              contentPadding: const EdgeInsets.all(16),
                              border: InputBorder.none,
                            ),
                            onTapOutside: (event) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
