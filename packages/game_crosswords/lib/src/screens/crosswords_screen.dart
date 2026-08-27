import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/crosswords_provider.dart';
import '../widgets/crossword_grid.dart';
import '../widgets/scoreboard_widget.dart';

class CrosswordsScreen extends ConsumerStatefulWidget {
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? leading;
  final List<Widget>? actions;

  const CrosswordsScreen({
    super.key,
    this.drawer,
    this.bottomNavigationBar,
    this.leading,
    this.actions,
  });

  @override
  ConsumerState<CrosswordsScreen> createState() => _CrosswordsScreenState();
}

class _CrosswordsScreenState extends ConsumerState<CrosswordsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _captureAndShare(double score) async {
    setState(() {
      _isSharing = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary =
          _globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/crossword_score.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(pngBytes);

        final text =
            "${'crossword_share_1'.tr()} ${score.toStringAsFixed(1)}/10. ${'crossword_share_2'.tr()}";
        SharePlus.instance.share(
          ShareParams(files: [XFile(imagePath)], text: text),
        );
      }
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(crosswordsProvider);
    final theme = Theme.of(context);

    Widget? effectiveLeading = widget.leading;
    if (effectiveLeading == null && widget.drawer != null) {
      effectiveLeading = IconButton(
        icon: const Icon(Icons.menu),
        tooltip: 'Menu',
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: widget.drawer,
      appBar: AppBar(
        leading: effectiveLeading,
        title: Text('crosswords'.tr()),
        actions: widget.actions,
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.currentPuzzle == null
          ? Center(child: Text(state.error ?? 'crossword_no_data'.tr()))
          : RepaintBoundary(
              key: _globalKey,
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildMainTab(context, state),
                  _buildArchiveTab(context, state),
                  const ScoreboardWidget(),
                ],
              ),
            ),
      bottomSheet: _currentIndex == 0 ? _buildBottomTabSelector(theme) : null,
    );
  }

  Widget _buildBottomTabSelector(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.grid_on),
            label: 'crossword_daily'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.collections_bookmark_outlined),
            selectedIcon: const Icon(Icons.collections_bookmark),
            label: 'crossword_all'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard_outlined),
            selectedIcon: const Icon(Icons.leaderboard),
            label: 'crossword_scoreboard'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTab(BuildContext context, CrosswordsState state) {
    final theme = Theme.of(context);
    final isDaily = ref.watch(crosswordsProvider.notifier).isDailyPuzzleActive;
    final isFav = state.favoritePuzzles.contains(state.currentPuzzle?.puzzleId);

    final scores = ref.watch(crosswordsProvider.notifier).getScores();
    final todayScore = scores['weekly'] ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'crossword_title'.tr()} #${state.currentPuzzle?.puzzleId}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isDaily)
                    Text(
                      'crossword_daily_puzzle'.tr(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.bookmark : Icons.bookmark_border,
                      color: isFav ? theme.colorScheme.primary : null,
                    ),
                    onPressed: () {
                      ref.read(crosswordsProvider.notifier).toggleFavorite();
                    },
                    tooltip: isFav ? 'Remove Favorite' : 'Save Favorite',
                  ),
                  if (_isSharing)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () => _captureAndShare(todayScore),
                      tooltip: 'Share',
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.currentPuzzle != null)
            CrosswordGrid(
              puzzle: state.currentPuzzle!,
              isFillable: true,
            ),
        ],
      ),
    );
  }

  Widget _buildArchiveTab(BuildContext context, CrosswordsState state) {
    final theme = Theme.of(context);
    final notifier = ref.read(crosswordsProvider.notifier);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.puzzles.length,
      itemBuilder: (context, index) {
        final puzzle = state.puzzles[index];
        final isSelected = state.currentPuzzle?.puzzleId == puzzle.puzzleId;
        final isDaily = puzzle.puzzleId == notifier.dailyPuzzleId;
        final isFav = state.favoritePuzzles.contains(puzzle.puzzleId);

        return Card(
          elevation: isSelected ? 3 : 1,
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
              : null,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isDaily
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondaryContainer,
              foregroundColor: isDaily
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSecondaryContainer,
              child: Text('#${puzzle.puzzleId}'),
            ),
            title: Text(
              '${'crossword_title'.tr()} #${puzzle.puzzleId}',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              '${puzzle.words.length} ${'crossword_words_count'.tr()}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFav)
                  Icon(Icons.bookmark, color: theme.colorScheme.primary, size: 20),
                if (isDaily)
                  Chip(
                    label: Text(
                      'crossword_daily'.tr(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            onTap: () {
              notifier.playPuzzle(puzzle.puzzleId);
              setState(() {
                _currentIndex = 0;
              });
            },
          ),
        );
      },
    );
  }
}
