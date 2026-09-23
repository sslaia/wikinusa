import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../providers/app_state.dart';
import '../utils/wiki_utils.dart';

class ManageProjectsModal extends ConsumerStatefulWidget {
  const ManageProjectsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ManageProjectsModal(),
    );
  }

  @override
  ConsumerState<ManageProjectsModal> createState() =>
      _ManageProjectsModalState();
}

class _ManageProjectsModalState extends ConsumerState<ManageProjectsModal> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabledProjects = ref.watch(enabledProjectsProvider);
    final notifier = ref.read(enabledProjectsProvider.notifier);
    final currentLang = ref.watch(languageProvider);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'manage_projects'.tr(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'close'.tr(),
                    ),
                  ],
                ),
              ),

              // Info note
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'wikipedia_always_active'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 16),

              // Projects list
              Builder(
                builder: (context) {
                  final availableProjects = ProjectType.values.where((p) {
                    return CommunityRegistry.hasProject(currentLang, p);
                  }).toList();

                  return Flexible(
                    child: ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shrinkWrap: true,
                      itemCount: availableProjects.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final project = availableProjects[index];
                    final isAnchor =
                        project == EnabledProjectsNotifier.anchorProject;
                    final isEnabled = enabledProjects.contains(project);
                    final canDisable = notifier.canDisableProject(project);

                    return SwitchListTile(
                      key: ValueKey(
                        'project_switch_${project.name.toLowerCase()}',
                      ),
                      value: isEnabled,
                      activeThumbColor: project.primaryColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      title: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: project.primaryColor,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              project.getLocalizedDisplayName(currentLang),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: isEnabled
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isEnabled
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isAnchor)
                            _buildBadge(
                              context,
                              label: 'Utama',
                              color: project.primaryColor,
                            ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(left: 20, top: 2),
                        child: Text(
                          '${project.name.toLowerCase()}_desc'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      onChanged: isAnchor
                          ? null
                          : (bool value) {
                              if (!value && !canDisable) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('at_least_one_project'.tr()),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              notifier.toggleProject(project, value);
                            },
                    );
                  },
                ),
              );
            },
          ),

              const Divider(height: 1),

              // Footer actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.restore_rounded, size: 16),
                      label: Text(
                        'reset_to_default'.tr(),
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed: () {
                        notifier.resetToDefaults();
                      },
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: Text('done'.tr()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
