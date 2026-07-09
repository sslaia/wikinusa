import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../providers/app_state.dart';
import '../providers/auth_provider.dart';
import '../services/edit_service.dart';
import 'edit_page_screen.dart';

// This is used only for creating new page on Wiktionary
class CreateEntryScreen extends ConsumerStatefulWidget {
  final String? title;
  const CreateEntryScreen({super.key, this.title});

  @override
  ConsumerState<CreateEntryScreen> createState() => _CreateEntryScreenState();
}

class _CreateEntryScreenState extends ConsumerState<CreateEntryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  var _selectedValue = 'Verba';
  var _selectedLanguageCode = 'nia';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
  }

  String _getOptionLabel(String option) {
    switch (option.toLowerCase()) {
      case 'verba':
        return 'pos_verba'.tr();
      case 'nomina':
        return 'pos_nomina'.tr();
      case 'adjektiva':
        return 'pos_adjektiva'.tr();
      case 'adverbia':
        return 'pos_adverbia'.tr();
      case 'numeralia':
        return 'pos_numeralia'.tr();
      case 'partikel':
        return 'pos_partikel'.tr();
      case 'pronomina':
        return 'pos_pronomina'.tr();
      case 'preposisi':
        return 'pos_preposisi'.tr();
      case 'konjungsi':
        return 'pos_konjungsi'.tr();
      case 'intejeksi':
        return 'pos_interjeksi'.tr();
      default:
        return option;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submitEntry() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final String title = _titleController.text.trim().toLowerCase();
    final String part = _selectedValue;
    String templateName;

    if (part == 'Nomina') {
      templateName = 'Templat:Famörögö wanura nomina';
    } else if (part == 'Adjektiva') {
      templateName = 'Templat:Famörögö wanura adjetiva';
    } else if (part == 'Adverbia') {
      templateName = 'Templat:Famörögö wanura adverbia';
    } else if (part == 'Numeralia') {
      templateName = 'Templat:Famörögö wanura numeralia';
    } else if (part == 'Partikel') {
      templateName = 'Templat:Famörögö wanura partikel';
    } else if (part == 'Pronomina') {
      templateName = 'Templat:Famörögö wanura pronomina';
    } else if (part == 'Preposisi') {
      templateName = 'Templat:Famörögö wanura preposisi';
    } else if (part == 'Konjungsi') {
      templateName = 'Templat:Famörögö wanura konjungsi';
    } else if (part == 'Intejeksi') {
      templateName = 'Templat:Famörögö wanura interjeksi';
    } else {
      templateName = 'Templat:Famörögö wanura verba';
    }

    if (_selectedLanguageCode == 'id') {
      templateName += ' (id)';
    }

    final langCode = ref.read(languageProvider);
    final currentProject = ref.read(appStateProvider);

    Future<void> launchWebEditor() async {
      final String encodedTemplate = Uri.encodeComponent(templateName);
      final String urlString =
          'https://nia.m.wiktionary.org/wiki/$title?action=edit&section=all&preload=$encodedTemplate';
      final url = Uri.parse(urlString);

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.inAppBrowserView,
          browserConfiguration: const BrowserConfiguration(showTitle: true),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('editor_cant_open'.tr())));
        }
      }
    }

    var authState = ref.read(authProvider);
    bool loggedIn = authState.isLoggedIn;

    if (!loggedIn) {
      final bool? shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          constraints: const BoxConstraints(maxWidth: 400),
          title: Text('login_required').tr(),
          content: Text('login_to_edit_message').tr(),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('continue_in_browser').tr(),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('login').tr(),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (shouldLogin == true) {
        await ref.read(authProvider.notifier).login(context);
        if (!mounted) return;
        loggedIn = ref.read(authProvider).isLoggedIn;
        if (!loggedIn) return;
      } else if (shouldLogin == false) {
        await launchWebEditor();
        return;
      } else {
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final wikitext = await EditService.fetchWikitext(
        project: currentProject,
        languageCode: langCode,
        title: title,
      );

      if (!mounted) return;

      if (wikitext != null) {
        final didEdit = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => EditPageScreen(
              title: title,
              preloadTemplate: templateName,
            ),
          ),
        );

        if (didEdit == true && mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_loading_content').tr(),
            action: SnackBarAction(
              label: 'continue_in_browser'.tr(),
              onPressed: () => launchWebEditor(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_loading_content').tr()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentProject = ref.watch(appStateProvider);

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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 64),
              _buildHeader(theme, currentProject),
              const SizedBox(height: 32),
              _buildWordField(theme),
              const SizedBox(height: 24),
              _buildLanguageField(theme),
              const SizedBox(height: 24),
              _buildPartOfSpeechField(theme),
              const SizedBox(height: 32),
              _buildSubmitButton(theme),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ProjectType currentProject) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit,
                size: 12,
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
              Text(
                'new_entry'.tr().toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 9,
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'create_new_entry'.tr(),
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
          'create_new_wiktionary_page'.tr(),
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

  Widget _buildWordField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'word'.tr().toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 14,
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
          child: TextFormField(
            controller: _titleController,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              hintText: 'enter_word_here'.tr(),
              hintStyle: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
                fontSize: 14,
              ),
              border: InputBorder.none,
            ),
            onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "enter_word_please".tr();
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'language'.tr().toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 14,
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
          child: DropdownButtonFormField<String>(
            initialValue: _selectedLanguageCode,
            decoration: const InputDecoration(border: InputBorder.none),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            items: [
              DropdownMenuItem(value: 'nia', child: Text('nias'.tr())),
              DropdownMenuItem(value: 'id', child: Text('indonesian'.tr())),
            ],
            onChanged: (value) {
              setState(() {
                _selectedLanguageCode = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPartOfSpeechField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_part_of_speech'.tr().toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 14,
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
          child: DropdownButtonFormField<String>(
            initialValue: _selectedValue,
            decoration: const InputDecoration(border: InputBorder.none),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            items:
                [
                      'Verba',
                      'Nomina',
                      'Adjektiva',
                      'Adverbia',
                      'Numeralia',
                      'Partikel',
                      'Pronomina',
                      'Preposisi',
                      'Konjungsi',
                      'Intejeksi',
                    ]
                    .map(
                      (option) =>
                          DropdownMenuItem(value: option, child: Text(_getOptionLabel(option))),
                    )
                    .toList(),
            onChanged: (value) {
              setState(() {
                _selectedValue = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return Center(
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 32),
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
            onTap: _isLoading ? null : _submitEntry,
            borderRadius: BorderRadius.circular(25),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  _isLoading ? 'submitting'.tr() : 'open_the_editor'.tr(),
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
    );
  }
}
