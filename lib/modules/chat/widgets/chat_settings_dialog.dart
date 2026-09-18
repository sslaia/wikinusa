import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../../../providers/shared_prefs_provider.dart';
import '../config/chat_module_config.dart';
import '../state/chat_providers.dart';

/// Modal dialog allowing users to customize the discussion page title for the active wiki.
class ChatSettingsDialog extends ConsumerStatefulWidget {
  const ChatSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ChatSettingsDialog(),
    );
  }

  @override
  ConsumerState<ChatSettingsDialog> createState() => _ChatSettingsDialogState();
}

class _ChatSettingsDialogState extends ConsumerState<ChatSettingsDialog> {
  late final TextEditingController _controller;
  late final String _defaultTitle;

  @override
  void initState() {
    super.initState();
    final target = ref.read(chatTargetProvider);
    _defaultTitle =
        ChatModuleConfig.getDefaultPageTitle(target.langCode, target.project);
    _controller = TextEditingController(text: target.pageTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final target = ref.read(chatTargetProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final newTitle = _controller.text.trim();

    if (newTitle.isEmpty || newTitle == _defaultTitle) {
      await ChatModuleConfig.resetPageTitle(
        prefs,
        target.langCode,
        target.project,
      );
    } else {
      await ChatModuleConfig.setCustomPageTitle(
        prefs,
        target.langCode,
        target.project,
        newTitle,
      );
    }

    // Invalidate state to trigger refresh with new page title
    ref.invalidate(chatTargetProvider);
    ref.invalidate(chatTopicsProvider);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('settings_saved'.tr())),
      );
    }
  }

  Future<void> _handleReset() async {
    final target = ref.read(chatTargetProvider);
    final prefs = ref.read(sharedPreferencesProvider);

    await ChatModuleConfig.resetPageTitle(
      prefs,
      target.langCode,
      target.project,
    );

    setState(() {
      _controller.text = _defaultTitle;
    });

    ref.invalidate(chatTargetProvider);
    ref.invalidate(chatTopicsProvider);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('reset_to_default'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final target = ref.watch(chatTargetProvider);
    final accentColor = target.project.getThemedColor(isDark);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.tune_rounded, color: accentColor, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'chat_settings'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Target wiki info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHigh
                    : theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${'project'.tr()}: ',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${target.project.getDisplayName(target.langCode)} (${target.langCode.toUpperCase()})',
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Domain: ',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          target.domain,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: accentColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'chat_page_title'.tr(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'chat_page_title_hint'.tr(),
                border: const OutlineInputBorder(),
                isDense: true,
                helperText: '${'default'.tr()}: $_defaultTitle',
                helperMaxLines: 2,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (target.isCustom)
          TextButton(
            onPressed: _handleReset,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text('reset'.tr()),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        FilledButton(
          onPressed: _handleSave,
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: isDark
                ? theme.colorScheme.onPrimaryContainer
                : Colors.white,
          ),
          child: Text('save'.tr()),
        ),
      ],
    );
  }
}
