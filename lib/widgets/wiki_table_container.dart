import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

/// A custom [WidgetFactory] that enhances Wikipedia tables with
/// horizontal scrolling, responsive cell breathing space, and
/// modern card presentation while keeping infoboxes and navboxes fitting normally.
class WikiWidgetFactory extends WidgetFactory {
  @override
  Widget? buildHorizontalScrollView(BuildTree tree, Widget child) {
    final element = tree.element;
    final isSpecialTable = element.classes.any((c) =>
        c.contains('infobox') ||
        c.contains('navbox') ||
        c.contains('ambox') ||
        c.contains('metadata') ||
        c.contains('toc'));

    if (isSpecialTable) {
      return super.buildHorizontalScrollView(tree, child);
    }

    Widget content = child;
    if (child is CssSizingHint) {
      content = child.child;
    }

    return WikiTableContainer(child: content);
  }
}

/// A wrapper container for Wikipedia data tables that provides
/// a modern card aesthetic, horizontal scrolling, scrollbar,
/// and a contextual swipe hint banner when the table overflows.
class WikiTableContainer extends StatefulWidget {
  final Widget child;

  const WikiTableContainer({
    super.key,
    required this.child,
  });

  @override
  State<WikiTableContainer> createState() => _WikiTableContainerState();
}

class _WikiTableContainerState extends State<WikiTableContainer> {
  final ScrollController _scrollController = ScrollController();
  bool _canScroll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollability());
  }

  void _checkScrollability() {
    if (!mounted) return;
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final canScrollNow = maxScroll > 2.0;
      if (canScrollNow != _canScroll) {
        setState(() {
          _canScroll = canScrollNow;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String hintText;
    try {
      hintText = 'table_scroll_hint'.tr();
    } catch (_) {
      hintText = 'table_scroll_hint';
    }
    if (hintText == 'table_scroll_hint') {
      final locale = Localizations.maybeLocaleOf(context);
      hintText = locale?.languageCode == 'en'
          ? 'Scroll horizontally to view more columns ↔'
          : 'Geser ke samping untuk melihat kolom lainnya ↔';
    }

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        final canScrollNow = notification.metrics.maxScrollExtent > 2.0;
        if (canScrollNow != _canScroll && mounted) {
          setState(() {
            _canScroll = canScrollNow;
          });
        }
        return false;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_canScroll)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.45),
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.swipe_left_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hintText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Scrollbar(
                controller: _scrollController,
                thumbVisibility: _canScroll,
                interactive: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: widget.child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
