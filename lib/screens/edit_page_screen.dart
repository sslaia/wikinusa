import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_state.dart';
import '../providers/auth_provider.dart';
import '../services/edit_service.dart';

class EditPageScreen extends ConsumerStatefulWidget {
  final String title;

  const EditPageScreen({super.key, required this.title});

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
      _textController.text = wikitext;
    } else {
      _errorMessage = 'error_loading_content'.tr();
    }

    if (mounted) {
      setState(() {
        _isLoadingText = false;
      });
    }
  }

  Future<bool> _showConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('confirm_edit_title'.tr()),
          content: Text('confirm_edit_message'.tr()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('go_back'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('submit'.tr()),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _submitEdit() async {
    final authState = ref.read(authProvider);

    if (!authState.isLoggedIn) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('login_required'.tr())));
      return;
    }

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

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
            ? 'Edited via WikiNusa App'
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text(
              widget.title,
              style: TextStyle(color: theme.colorScheme.onSurface),
              overflow: TextOverflow.fade,
            ),
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
          ),
          if (_isLoadingText)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(
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
              ),
            )
          else
            SliverSafeArea(
              top: false, // SliverAppBar handles top safe area
              sliver: SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Wikitext Content Field
                    Container(
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
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        minLines: 15,
                        scrollPhysics: const NeverScrollableScrollPhysics(),
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
                        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Summary Field
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _summaryController,
                        decoration: InputDecoration(
                          labelText: 'edit_summary'.tr(),
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Submit Button
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submitEdit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            _isSubmitting ? 'submitting'.tr() : 'submit'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
