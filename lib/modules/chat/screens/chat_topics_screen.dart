import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../services/wiki_chat_api_service.dart';
import '../state/chat_providers.dart';
import '../widgets/chat_settings_dialog.dart';
import '../widgets/topic_card.dart';
import '../widgets/wiki_captcha_dialog.dart';
import 'chat_conversation_screen.dart';

/// Main screen displaying the list of discussion topics on the active wiki talk page.
class ChatTopicsScreen extends ConsumerStatefulWidget {
  const ChatTopicsScreen({super.key});

  @override
  ConsumerState<ChatTopicsScreen> createState() => _ChatTopicsScreenState();
}

class _ChatTopicsScreenState extends ConsumerState<ChatTopicsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(chatUnreadProvider.notifier).markAsSeen();
      }
    });
  }

  Future<void> _refresh() async {
    await ref.read(chatTopicsProvider.notifier).refresh();
    if (mounted) {
      await ref.read(chatUnreadProvider.notifier).markAsSeen();
    }
  }

  Future<void> _showNewTopicDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    String? formError;
    bool showCaptchaOption = false;
    String? captchaSiteKey;

    final target = ref.read(chatTargetProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = target.project.getThemedColor(isDark);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setSheetState) {
            final bottomInset = MediaQuery.of(modalContext).viewInsets.bottom;
            final theme = Theme.of(modalContext);

            Future<void> submitWithCaptcha([String? captchaWord, String? captchaId]) async {
              final title = titleController.text.trim();
              final message = messageController.text.trim();

              setSheetState(() {
                isSubmitting = true;
                formError = null;
              });

              try {
                final success = await ref
                    .read(chatTopicsProvider.notifier)
                    .createNewTopic(
                      context: modalContext,
                      topicTitle: title,
                      message: message,
                      captchaWord: captchaWord,
                      captchaId: captchaId,
                    );

                if (modalContext.mounted) {
                  if (success) {
                    Navigator.pop(modalContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('chat_sent'.tr()),
                      ),
                    );
                  } else {
                    setSheetState(() => isSubmitting = false);
                  }
                }
              } on WikiCaptchaException catch (ce) {
                if (!modalContext.mounted) return;
                setSheetState(() {
                  isSubmitting = false;
                  formError = 'chat_captcha_desc'.tr();
                  showCaptchaOption = true;
                  captchaSiteKey = ce.siteKey;
                });

                // Prompt user to solve CAPTCHA
                final token = await WikiCaptchaDialog.show(
                  modalContext,
                  siteKey: ce.siteKey,
                  domain: target.domain,
                  pageTitle: target.pageTitle,
                  captchaId: ce.id,
                  captchaUrl: ce.url,
                  captchaQuestion: ce.question,
                  prefillTitle: title,
                  prefillContent: message,
                );

                if (token != null && token.isNotEmpty && modalContext.mounted) {
                  await submitWithCaptcha(token, ce.id);
                }
              } catch (e) {
                if (modalContext.mounted) {
                  setSheetState(() {
                    isSubmitting = false;
                    formError = e.toString().replaceFirst("Exception: ", "");
                  });
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: bottomInset + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.add_comment_rounded,
                          color: accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'chat_new_topic'.tr(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'chat_topic_title'.tr(),
                        hintText: 'chat_new_topic_hint'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'chat_enter_title'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'chat_topic_content'.tr(),
                        hintText: 'chat_reply_hint'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'chat_enter_message'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (formError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                formError!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (showCaptchaOption && captchaSiteKey != null) ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.security_rounded, size: 18),
                          label: Text('chat_captcha_solve'.tr()),
                          onPressed: () async {
                            final token = await WikiCaptchaDialog.show(
                              modalContext,
                              siteKey: captchaSiteKey!,
                              domain: target.domain,
                              pageTitle: target.pageTitle,
                              prefillTitle: titleController.text.trim(),
                              prefillContent: messageController.text.trim(),
                            );
                            if (token != null &&
                                token.isNotEmpty &&
                                modalContext.mounted) {
                              await submitWithCaptcha(token);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: isDark
                              ? theme.colorScheme.onPrimaryContainer
                              : Colors.white,
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                await submitWithCaptcha();
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'create_submit'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final target = ref.watch(chatTargetProvider);
    final topicsAsync = ref.watch(chatTopicsProvider);
    final accentColor = target.project.getThemedColor(isDark);
    final appBarForeground = theme.appBarTheme.foregroundColor ??
        (isDark ? theme.colorScheme.onSurface : Colors.white);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        foregroundColor: appBarForeground,
        iconTheme: IconThemeData(color: appBarForeground),
        actionsIconTheme: IconThemeData(color: appBarForeground),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'chat'.tr(),
              style: (theme.appBarTheme.titleTextStyle ??
                      theme.textTheme.titleMedium)
                  ?.copyWith(
                color: appBarForeground,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              '${target.project.getDisplayName(target.langCode)} • ${target.pageTitle}',
              style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
                fontSize: 10,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: appBarForeground,
            tooltip: 'refresh'.tr(),
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            color: appBarForeground,
            tooltip: 'chat_settings'.tr(),
            onPressed: () => ChatSettingsDialog.show(context),
          ),
        ],
      ),
      body: topicsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: accentColor),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  err.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () =>
                      ref.read(chatTopicsProvider.notifier).refresh(),
                  child: Text('retry'.tr()),
                ),
              ],
            ),
          ),
        ),
        data: (topics) {
          if (topics.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      size: 64,
                      color: accentColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'chat_no_topics'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'chat_empty_prompt'.tr(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: accentColor,
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                return TopicCard(
                  topic: topic,
                  project: target.project,
                  langCode: target.langCode,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatConversationScreen(topicId: topic.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTopicDialog(context),
        backgroundColor: accentColor,
        foregroundColor: isDark
            ? theme.colorScheme.onPrimaryContainer
            : Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: Text('chat_new_topic'.tr()),
      ),
    );
  }
}
