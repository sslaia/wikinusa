import 'package:flutter_riverpod/legacy.dart';

// Keeps track of which language codes have already seen the warning
final webViewWarningProvider = StateProvider<Set<String>>((ref) => {});