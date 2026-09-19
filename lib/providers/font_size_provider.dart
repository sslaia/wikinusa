import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_prefs_provider.dart';

enum AppFontSize {
  small('Small', 0.8),
  normal('Default', 0.9),
  large('Large', 1.05),
  extraLarge('Extra Large', 1.25);

  final String label;
  final double scale;

  const AppFontSize(this.label, this.scale);

  static AppFontSize fromName(String name) {
    return AppFontSize.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppFontSize.normal,
    );
  }
}

class FontSizeNotifier extends Notifier<AppFontSize> {
  static const _fontSizeKey = 'app_font_size';

  @override
  AppFontSize build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedName = prefs.getString(_fontSizeKey);
    if (savedName != null) {
      return AppFontSize.fromName(savedName);
    }
    return AppFontSize.normal;
  }

  void setFontSize(AppFontSize size) {
    state = size;
    ref.read(sharedPreferencesProvider).setString(_fontSizeKey, size.name);
  }
}

final fontSizeProvider = NotifierProvider<FontSizeNotifier, AppFontSize>(() {
  return FontSizeNotifier();
});
