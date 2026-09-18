import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../providers/app_state.dart';
import '../providers/modules_provider.dart';
import '../modules/chat/config/chat_module_config.dart';

class ModuleSettingsScreen extends ConsumerStatefulWidget {
  const ModuleSettingsScreen({super.key});

  @override
  ConsumerState<ModuleSettingsScreen> createState() =>
      _ModuleSettingsScreenState();
}

class _ModuleSettingsScreenState extends ConsumerState<ModuleSettingsScreen> {
  late String _selectedLanguage;

  // Controllers for text fields
  final TextEditingController _newsletterTitleController =
      TextEditingController();
  final TextEditingController _courseTitleController = TextEditingController();
  final TextEditingController _chatTitleController = TextEditingController();

  // Temporary state for current language editing
  bool _newsletterEnabled = false;
  ProjectType _newsletterProject = ProjectType.wikipedia;

  bool _courseEnabled = false;
  ProjectType _courseProject = ProjectType.wiktionary;

  bool _crosswordsEnabled = false;
  String? _crosswordsDataFile;
  bool _crosswordsIsCustom = false;

  bool _galleryEnabled = false;
  String? _galleryDataFile;
  bool _galleryIsCustom = false;

  bool _chatEnabled = true;
  ProjectType _chatProject = ProjectType.wikipedia;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = 'id';
  }



  void _loadLanguageConfig(String langCode) {
    final notifier = ref.read(modulesConfigNotifierProvider);
    final langConfigs = notifier[langCode] ?? {};

    // 1. Newsletter
    final newsletter = langConfigs['newsletter'] ??
        ModuleConfig(
          enabled: langCode == 'nia',
          project: ProjectType.wikipedia,
          pageTitle: 'Wikipedia:Turia',
        );
    _newsletterEnabled = newsletter.enabled;
    _newsletterProject = newsletter.project;
    _newsletterTitleController.text = newsletter.pageTitle;

    // 2. Language course
    final course = langConfigs['course'] ??
        ModuleConfig(
          enabled: langCode == 'nia',
          project: ProjectType.wiktionary,
          pageTitle: 'Wikikamus:Sulu',
        );
    _courseEnabled = course.enabled;
    _courseProject = course.project;
    _courseTitleController.text = course.pageTitle;

    // 3. Crosswords (project is fixed to Wiktionary)
    final crosswords = langConfigs['crosswords'] ??
        ModuleConfig(
          enabled: langCode == 'nia',
          project: ProjectType.wiktionary,
          pageTitle: '',
          dataFile: 'assets/data/nia_crosswords.json',
        );
    _crosswordsEnabled = crosswords.enabled;
    _crosswordsDataFile = crosswords.dataFile;
    _crosswordsIsCustom = crosswords.isCustomDataFile;

    // 4. Gallery (project is fixed to Wikimedia Commons)
    final gallery = langConfigs['gallery'] ??
        ModuleConfig(
          enabled: langCode == 'nia',
          project: ProjectType.wikipedia,
          pageTitle: 'Wikipedia:Galeri',
          dataFile: 'assets/data/gallery.json',
        );
    _galleryEnabled = gallery.enabled;
    _galleryDataFile = gallery.dataFile;
    _galleryIsCustom = gallery.isCustomDataFile;

    // 5. WikiChat
    final defaultChatTitle =
        ChatModuleConfig.getDefaultPageTitle(langCode, ProjectType.wikipedia);
    final chat = langConfigs['chat'] ??
        ModuleConfig(
          enabled: true,
          project: ProjectType.wikipedia,
          pageTitle: defaultChatTitle,
        );
    _chatEnabled = chat.enabled;
    _chatProject = chat.project;
    _chatTitleController.text =
        chat.pageTitle.isNotEmpty ? chat.pageTitle : defaultChatTitle;
  }

  Future<void> _pickJsonFile({
    required String moduleKey,
    required Function(String filePath) onFileSelected,
  }) async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result.isNotEmpty && result.first.path != null) {
        final path = result.first.path!;
        final file = File(path);
        final content = await file.readAsString();

        // Validate JSON
        try {
          jsonDecode(content);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('invalid_json_file'.tr())),
            );
          }
          return;
        }

        // Copy to app documents directory
        final docsDir = await getApplicationDocumentsDirectory();
        final targetDir = Directory('${docsDir.path}/custom_modules');
        if (!targetDir.existsSync()) {
          await targetDir.create(recursive: true);
        }
        final fileName = result.first.name;
        final targetPath =
            '${targetDir.path}/${_selectedLanguage}_${moduleKey}_$fileName';
        await File(targetPath).writeAsString(content);

        onFileSelected(targetPath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('data_file_uploaded'.tr())),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'error'.tr()}: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    final notifier = ref.read(modulesConfigNotifierProvider.notifier);

    // Save Newsletter
    await notifier.updateModuleConfig(
      langCode: _selectedLanguage,
      moduleKey: 'newsletter',
      config: ModuleConfig(
        enabled: _newsletterEnabled,
        project: _newsletterProject,
        pageTitle: _newsletterTitleController.text.trim(),
      ),
    );

    // Save Language Course
    await notifier.updateModuleConfig(
      langCode: _selectedLanguage,
      moduleKey: 'course',
      config: ModuleConfig(
        enabled: _courseEnabled,
        project: _courseProject,
        pageTitle: _courseTitleController.text.trim(),
      ),
    );

    // Save Crosswords (fixed to Wiktionary)
    await notifier.updateModuleConfig(
      langCode: _selectedLanguage,
      moduleKey: 'crosswords',
      config: ModuleConfig(
        enabled: _crosswordsEnabled,
        project: ProjectType.wiktionary,
        pageTitle: '',
        dataFile: _crosswordsDataFile,
        isCustomDataFile: _crosswordsIsCustom,
      ),
    );

    // Save Gallery (project set to Commons)
    await notifier.updateModuleConfig(
      langCode: _selectedLanguage,
      moduleKey: 'gallery',
      config: ModuleConfig(
        enabled: _galleryEnabled,
        project: ProjectType.wikipedia,
        pageTitle: 'Wikipedia:Galeri',
        dataFile: _galleryDataFile,
        isCustomDataFile: _galleryIsCustom,
      ),
    );

    // Save WikiChat
    await notifier.updateModuleConfig(
      langCode: _selectedLanguage,
      moduleKey: 'chat',
      config: ModuleConfig(
        enabled: _chatEnabled,
        project: _chatProject,
        pageTitle: _chatTitleController.text.trim(),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('settings_saved'.tr())),
      );
    }
  }

  Future<void> _resetLanguageToDefaults() async {
    final notifier = ref.read(modulesConfigNotifierProvider.notifier);
    await notifier.resetToDefaults(langCode: _selectedLanguage);
    if (mounted) {
      setState(() {
        _loadLanguageConfig(_selectedLanguage);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('reset_to_default'.tr())),
      );
    }
  }

  @override
  void dispose() {
    _newsletterTitleController.dispose();
    _courseTitleController.dispose();
    _chatTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allConfigs = ref.watch(modulesConfigNotifierProvider);
    if (allConfigs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('module_settings'.tr())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isInitialized) {
      final currentLang = ref.read(languageProvider);
      _selectedLanguage = currentLang;
      _loadLanguageConfig(_selectedLanguage);
      _isInitialized = true;
    }

    final theme = Theme.of(context);
    final currentProject = ref.watch(appStateProvider);
    final primaryColor = currentProject.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('module_settings'.tr()),
        actions: [
          IconButton(
            tooltip: 'reset_to_default'.tr(),
            icon: const Icon(Icons.restore),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('reset_to_default'.tr()),
                  content: Text(
                    'Are you sure you want to reset settings for this language to defaults?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('cancel'.tr()),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('reset_to_default'.tr()),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _resetLanguageToDefaults();
              }
            },
          ),
          IconButton(
            tooltip: 'save'.tr(),
            icon: const Icon(Icons.check),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Newsletter section
          _buildModuleSection(
            theme: theme,
            primaryColor: primaryColor,
            icon: Icons.feed_rounded,
            title: 'newsletter'.tr(),
            enabled: _newsletterEnabled,
            onChangedEnabled: (val) => setState(() => _newsletterEnabled = val),
            children: [
              _buildProjectDropdown(
                theme: theme,
                value: _newsletterProject,
                onChanged: (p) {
                  if (p != null) setState(() => _newsletterProject = p);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newsletterTitleController,
                decoration: InputDecoration(
                  labelText: 'page_title'.tr(),
                  hintText: 'Wikipedia:Turia',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Language Course section
          _buildModuleSection(
            theme: theme,
            primaryColor: primaryColor,
            icon: Icons.school_rounded,
            title: 'language_course'.tr(),
            enabled: _courseEnabled,
            onChangedEnabled: (val) => setState(() => _courseEnabled = val),
            children: [
              _buildProjectDropdown(
                theme: theme,
                value: _courseProject,
                onChanged: (p) {
                  if (p != null) setState(() => _courseProject = p);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _courseTitleController,
                decoration: InputDecoration(
                  labelText: 'page_title'.tr(),
                  hintText: 'Wikikamus:Sulu',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Crosswords section (project fixed to Wiktionary)
          _buildModuleSection(
            theme: theme,
            primaryColor: primaryColor,
            icon: Icons.grid_on_rounded,
            title: 'crosswords'.tr(),
            enabled: _crosswordsEnabled,
            onChangedEnabled: (val) => setState(() => _crosswordsEnabled = val),
            children: [
              _buildFixedProjectBadge(
                theme: theme,
                projectName: 'Wiktionary',
                projectColor: ProjectType.wiktionary.primaryColor,
                description: 'crosswords_fixed_project_desc'.tr(),
              ),
              const SizedBox(height: 12),
              _buildDataFileTile(
                theme: theme,
                dataFile: _crosswordsDataFile,
                isCustom: _crosswordsIsCustom,
                onPickFile: () {
                  _pickJsonFile(
                    moduleKey: 'crosswords',
                    onFileSelected: (path) {
                      setState(() {
                        _crosswordsDataFile = path;
                        _crosswordsIsCustom = true;
                      });
                    },
                  );
                },
                onResetDefault: () {
                  setState(() {
                    _crosswordsDataFile = 'assets/data/nia_crosswords.json';
                    _crosswordsIsCustom = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Gallery section (project set to Commons)
          _buildModuleSection(
            theme: theme,
            primaryColor: primaryColor,
            icon: Icons.photo_library_rounded,
            title: 'gallery'.tr(),
            enabled: _galleryEnabled,
            onChangedEnabled: (val) => setState(() => _galleryEnabled = val),
            children: [
              _buildFixedProjectBadge(
                theme: theme,
                projectName: 'Wikimedia Commons',
                projectColor: const Color(0xFF006699),
                description: 'gallery_fixed_project_desc'.tr(),
              ),
              const SizedBox(height: 12),
              _buildDataFileTile(
                theme: theme,
                dataFile: _galleryDataFile,
                isCustom: _galleryIsCustom,
                onPickFile: () {
                  _pickJsonFile(
                    moduleKey: 'gallery',
                    onFileSelected: (path) {
                      setState(() {
                        _galleryDataFile = path;
                        _galleryIsCustom = true;
                      });
                    },
                  );
                },
                onResetDefault: () {
                  setState(() {
                    _galleryDataFile = 'assets/data/gallery.json';
                    _galleryIsCustom = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5. WikiChat section
          _buildModuleSection(
            theme: theme,
            primaryColor: primaryColor,
            icon: Icons.chat_bubble_outline_rounded,
            title: 'chat'.tr(),
            enabled: _chatEnabled,
            onChangedEnabled: (val) => setState(() => _chatEnabled = val),
            children: [
              _buildProjectDropdown(
                theme: theme,
                value: _chatProject,
                onChanged: (proj) {
                  if (proj != null) {
                    setState(() {
                      _chatProject = proj;
                      _chatTitleController.text =
                          ChatModuleConfig.getDefaultPageTitle(
                        _selectedLanguage,
                        proj,
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _chatTitleController,
                decoration: InputDecoration(
                  labelText: 'chat_page_title'.tr(),
                  hintText: 'chat_page_title_hint'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                  helperText:
                      '${'default'.tr()}: ${ChatModuleConfig.getDefaultPageTitle(_selectedLanguage, _chatProject)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Big save button
          FilledButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save_rounded),
            label: Text('save'.tr()),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildModuleSection({
    required ThemeData theme,
    required Color primaryColor,
    required IconData icon,
    required String title,
    required bool enabled,
    required ValueChanged<bool> onChangedEnabled,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: enabled
              ? primaryColor.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: enabled ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (enabled ? primaryColor : theme.colorScheme.onSurface)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: enabled ? primaryColor : theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onChangedEnabled,
                  activeThumbColor: primaryColor,
                ),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              ...children,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectDropdown({
    required ThemeData theme,
    required ProjectType value,
    required ValueChanged<ProjectType?> onChanged,
  }) {
    return DropdownButtonFormField<ProjectType>(
      key: ValueKey(value),
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'project'.tr(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.language_rounded),
      ),
      items: ProjectType.values.map((project) {
        return DropdownMenuItem<ProjectType>(
          value: project,
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: project.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(project.name),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildFixedProjectBadge({
    required ThemeData theme,
    required String projectName,
    required Color projectColor,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: projectColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: projectColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_rounded, size: 18, color: projectColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'project'.tr()}: $projectName',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: projectColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataFileTile({
    required ThemeData theme,
    required String? dataFile,
    required bool isCustom,
    required VoidCallback onPickFile,
    required VoidCallback onResetDefault,
  }) {
    final displayFileName = dataFile != null
        ? dataFile.split('/').last
        : 'Default';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCustom ? Icons.insert_drive_file : Icons.folder_zip,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'data_file'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      displayFileName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isCustom)
                IconButton(
                  icon: const Icon(Icons.restart_alt, size: 20),
                  tooltip: 'use_default_file'.tr(),
                  onPressed: onResetDefault,
                ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onPickFile,
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: Text('upload_json_file'.tr()),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
