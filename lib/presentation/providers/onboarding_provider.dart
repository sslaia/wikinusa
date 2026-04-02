import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_prefs_provider.dart';

class OnboardingNotifier extends Notifier<bool> {
  static const _onboardingKey = 'has_completed_onboarding';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_onboardingKey, true);
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(() {
  return OnboardingNotifier();
});
