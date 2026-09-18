/// Utility functions for safe date and time formatting in WikiChat
/// that do not depend on external locale symbol tables.
///
/// In accordance with project conventions, Indonesian date format (`d MMM` / `d MMM yyyy`)
/// with Indonesian month names (e.g., "17 Sep", "20 Mei 2025", "10 Agu 2026") is used for
/// all local/regional languages in Indonesia (`id`, `nia`, `jv`, `ban`, `bjn`, `su`, etc.),
/// while English (`en`) uses `MMM d` / `MMM d, yyyy`.
class ChatDateUtils {
  static const List<String> _idMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> _enMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Formats a timestamp into relative ("just now", "5m ago", "2h ago", "3d ago")
  /// or safe calendar string.
  ///
  /// For all local languages in Indonesia (`id`, `nia`, `jv`, etc.), Indonesian format
  /// (`d MMM` or `d MMM yyyy`) is applied.
  /// For English (`en`), `MMM d` or `MMM d, yyyy` is used.
  static String formatTimestamp(
    DateTime dt, {
    bool includeYear = false,
    String langCode = 'id',
  }) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      final isEn = langCode.trim().toLowerCase() == 'en';
      final months = isEn ? _enMonths : _idMonths;
      final monthStr = (dt.month >= 1 && dt.month <= 12)
          ? months[dt.month - 1]
          : '${dt.month}';

      if (isEn) {
        if (includeYear || dt.year != now.year) {
          return '$monthStr ${dt.day}, ${dt.year}';
        }
        return '$monthStr ${dt.day}';
      } else {
        // Indonesian date format: d MMM yyyy (e.g. "17 Sep", "20 Mei 2025")
        if (includeYear || dt.year != now.year) {
          return '${dt.day} $monthStr ${dt.year}';
        }
        return '${dt.day} $monthStr';
      }
    }
  }
}
