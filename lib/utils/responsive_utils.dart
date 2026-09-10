import 'package:flutter/material.dart';

enum DeviceType { compact, medium, expanded }

class ResponsiveUtils {
  static const double compactBreakpoint = 500;
  static const double expandedBreakpoint = 840;

  static DeviceType getDeviceType(BuildContext context) {
    double shortestSide = MediaQuery.of(context).size.shortestSide;
    if (shortestSide < compactBreakpoint) {
      return DeviceType.compact;
    } else if (shortestSide < expandedBreakpoint) {
      return DeviceType.medium;
    } else {
      return DeviceType.expanded;
    }
  }

  static bool isCompact(BuildContext context) =>
      getDeviceType(context) == DeviceType.compact;

  static bool isMedium(BuildContext context) =>
      getDeviceType(context) == DeviceType.medium;

  static bool isExpanded(BuildContext context) =>
      getDeviceType(context) == DeviceType.expanded;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  /// Tablet is considered Medium or Expanded, or shortestSide >= 480, or landscape width >= 720 with height >= 480
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide >= 480 ||
        (size.width >= 720 && size.height >= 480) ||
        getDeviceType(context) != DeviceType.compact;
  }

  /// Whether tablet landscape mode is active (permanent drawer mode)
  static bool isTabletLandscape(BuildContext context) =>
      isTablet(context) && isLandscape(context);
}
