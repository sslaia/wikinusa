import 'package:flutter/widgets.dart';

/// Manages application memory footprint, specifically bitmap memory and image caches,
/// ensuring compliance with Google Play Store memory usage thresholds and preventing
/// Out-Of-Memory (OOM) kills on low-spec and 2 GB RAM Android devices.
class MemoryManager with WidgetsBindingObserver {
  MemoryManager._();

  static final MemoryManager instance = MemoryManager._();

  bool _initialized = false;

  /// Conservative memory cache limit for 2 GB RAM devices (24 MB).
  /// Android LMK starts killing foreground apps around 180-250 MB on 2 GB devices.
  static const int maxImageCacheBytes = 24 * 1024 * 1024;

  /// Maximum number of decoded images retained in memory (45).
  static const int maxImageCacheCount = 45;

  /// Initializes the memory manager, sets conservative image cache bounds,
  /// and attaches the lifecycle observer.
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // 1. Constrain image cache limits to prevent memory bloat on low-RAM devices
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSizeBytes = maxImageCacheBytes;
    imageCache.maximumSize = maxImageCacheCount;

    // 2. Register lifecycle and memory pressure observer
    WidgetsBinding.instance.addObserver(this);
  }

  /// Cleans up observers.
  void dispose() {
    if (!_initialized) return;
    WidgetsBinding.instance.removeObserver(this);
    _initialized = false;
  }

  /// Evicts all cached decoded bitmaps and live images from memory.
  void clearImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Release bitmap allocations when the app is placed in the background or hidden.
    // This directly complies with Google Play Store's requirement that bitmaps
    // must not be retained in non-visible (background/cached) app states.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      clearImageCache();
    }
  }

  @override
  void didHaveMemoryPressure() {
    // Aggressively reclaim memory on OS low memory warnings
    clearImageCache();
  }
}
