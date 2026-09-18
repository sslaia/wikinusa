import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:wikimedia_core/wikimedia_core.dart';
import '../modules/chat/state/chat_providers.dart';
import 'adaptive_nav_actions.dart';

class CustomBottomAppBar extends ConsumerWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ProjectType currentProject;
  final bool isHomeScreen;
  final String? pageTitle;
  final Future<void> Function()? onRefresh;

  const CustomBottomAppBar({
    super.key,
    required this.scaffoldKey,
    required this.currentProject,
    this.isHomeScreen = false,
    this.pageTitle,
    this.onRefresh,
  });

  Color _getBadgeColor(ProjectType project) {
    switch (project) {
      case ProjectType.wikipedia:
        return const Color(0xFFFF5252); // High-contrast coral red on Indigo
      case ProjectType.wiktionary:
        return const Color(0xFFFFD54F); // High-contrast amber on Deep Orange
      case ProjectType.wikibooks:
        return const Color(0xFFFF5252); // High-contrast coral red on Purple
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasUnreadChat = ref.watch(chatUnreadProvider).hasUnread;

    return BottomAppBar(
      color: colorScheme.primary,
      height: 72,
      child: IconTheme(
        data: IconThemeData(color: colorScheme.onPrimary),
        child: Row(
          children: [
            IconButton(
              tooltip: 'open_navigation_menu'.tr(),
              icon: Badge(
                isLabelVisible: hasUnreadChat,
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                label: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _getBadgeColor(currentProject),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.onPrimary,
                      width: 1.5,
                    ),
                  ),
                ),
                child: const Icon(Icons.menu),
              ),
              onPressed: () {
                scaffoldKey.currentState?.openDrawer();
              },
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'WikiNusa',
                // overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.cinzelDecorative(
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Spacer(),
            ...AdaptiveNavActions.buildActions(
              context,
              ref,
              currentProject: currentProject,
              isHomeScreen: isHomeScreen,
              pageTitle: pageTitle,
              showShortcuts: false,
              onRefresh: onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}
