import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/crossword_model.dart';
import '../providers/crosswords_provider.dart';

class CrosswordGrid extends ConsumerStatefulWidget {
  final CrosswordPuzzle puzzle;
  final bool isFillable;

  const CrosswordGrid({
    super.key,
    required this.puzzle,
    this.isFillable = true,
  });

  @override
  ConsumerState<CrosswordGrid> createState() => _CrosswordGridState();
}

class _CrosswordGridState extends ConsumerState<CrosswordGrid> {
  int? selectedX;
  int? selectedY;
  CrosswordWord? selectedWord;

  bool _isWordWrong(CrosswordWord word, Map<String, String> userAnswers) {
    for (int i = 0; i < word.word.length; i++) {
      int cx = word.direction == 'across' ? word.x + i : word.x;
      int cy = word.direction == 'down' ? word.y + i : word.y;
      final answer = userAnswers['$cx,$cy'];
      if (answer != null && answer.isNotEmpty) {
        if (answer.toUpperCase() != word.word[i].toUpperCase()) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isCellInWrongWord(
    int x,
    int y,
    List<CrosswordWord> words,
    Map<String, String> userAnswers,
  ) {
    for (var word in words) {
      bool isPart = false;
      if (word.direction == 'across') {
        if (y == word.y && x >= word.x && x < word.x + word.word.length) {
          isPart = true;
        }
      } else {
        if (x == word.x && y >= word.y && y < word.y + word.word.length) {
          isPart = true;
        }
      }
      if (isPart && _isWordWrong(word, userAnswers)) {
        return true;
      }
    }
    return false;
  }

  bool _isWordWrongOrIncomplete(CrosswordWord word, Map<String, String> userAnswers) {
    for (int i = 0; i < word.word.length; i++) {
      int cx = word.direction == 'across' ? word.x + i : word.x;
      int cy = word.direction == 'down' ? word.y + i : word.y;
      final answer = userAnswers['$cx,$cy'];
      if (answer == null || answer.isEmpty) {
        return true;
      }
      if (answer.toUpperCase() != word.word[i].toUpperCase()) {
        return true;
      }
    }
    return false;
  }

  bool _isCellInWrongOrIncompleteWord(
    int x,
    int y,
    List<CrosswordWord> words,
    Map<String, String> userAnswers,
  ) {
    for (var word in words) {
      bool isPart = false;
      if (word.direction == 'across') {
        if (y == word.y && x >= word.x && x < word.x + word.word.length) {
          isPart = true;
        }
      } else {
        if (x == word.x && y >= word.y && y < word.y + word.word.length) {
          isPart = true;
        }
      }
      if (isPart && _isWordWrongOrIncomplete(word, userAnswers)) {
        return true;
      }
    }
    return false;
  }

  void _handleLockedCellTap(BuildContext context, int x, int y) {
    final matchingWords = widget.puzzle.words.where((word) {
      if (word.direction == 'across') {
        return y == word.y && x >= word.x && x < word.x + word.word.length;
      } else {
        return x == word.x && y >= word.y && y < word.y + word.word.length;
      }
    }).toList();

    if (matchingWords.isEmpty) return;

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (builderContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'reference'.tr().toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'crossword_wiktionary_ref'.tr(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: matchingWords.length,
                  itemBuilder: (context, index) {
                    final word = matchingWords[index];
                    final wordIndex = widget.puzzle.words.indexOf(word) + 1;
                    final directionLabel = word.direction == 'across' ? 'Misa' : 'Mitou';
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                '$wordIndex. ${word.pageTitle} ($directionLabel)',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  word.clue,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  final pageTitle = Uri.encodeComponent(word.pageTitle);
                                  final url = Uri.parse('https://nia.wiktionary.org/wiki/$pageTitle');
                                  try {
                                    await launchUrl(url, mode: LaunchMode.inAppBrowserView);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('crossword_cant_open_wiktionary'.tr()),
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                label: Text('crossword_open_wiktionary'.tr()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(crosswordsProvider);
    final size = widget.puzzle.gridSize;

    // Create a matrix to represent the grid
    // null means black cell, empty string means empty white cell, string means filled letter
    List<List<String?>> grid = List.generate(
      size,
      (_) => List.generate(size, (_) => null),
    );
    Map<String, int> wordNumbers = {};
    Map<String, String> correctMap = {};

    for (var i = 0; i < widget.puzzle.words.length; i++) {
      var word = widget.puzzle.words[i];
      wordNumbers['${word.x},${word.y}'] = i + 1;

      for (int j = 0; j < word.word.length; j++) {
        int cx = word.direction == 'across' ? word.x + j : word.x;
        int cy = word.direction == 'down' ? word.y + j : word.y;

        if (cx < size && cy < size) {
          correctMap['$cx,$cy'] = word.word[j].toUpperCase();
          final isCellWrong = _isCellInWrongOrIncompleteWord(cx, cy, widget.puzzle.words, state.userAnswers);
          if (state.isTemporarilyRevealed && isCellWrong) {
            grid[cy][cx] = word.word[j].toUpperCase();
          } else {
            grid[cy][cx] = state.userAnswers['$cx,$cy'] ?? '';
          }
        }
      }
    }

    return TapRegion(
      onTapOutside: (event) {
        FocusScope.of(context).unfocus();
        setState(() {
          selectedX = null;
          selectedY = null;
          selectedWord = null;
        });
      },
      child: Column(
        children: [
          if (selectedWord != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '${wordNumbers['${selectedWord!.x},${selectedWord!.y}']}. ${selectedWord!.clue}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: size,
                  childAspectRatio: 1,
                ),
                itemCount: size * size,
                itemBuilder: (context, index) {
                  int x = index % size;
                  int y = index ~/ size;
                  String? cellValue = grid[y][x];

                  bool isBlack = cellValue == null;
                  bool isSelected = selectedX == x && selectedY == y;
                  bool isPartOfSelectedWord = false;

                  if (selectedWord != null) {
                    if (selectedWord!.direction == 'across') {
                      if (y == selectedWord!.y &&
                          x >= selectedWord!.x &&
                          x < selectedWord!.x + selectedWord!.word.length) {
                        isPartOfSelectedWord = true;
                      }
                    } else {
                      if (x == selectedWord!.x &&
                          y >= selectedWord!.y &&
                          y < selectedWord!.y + selectedWord!.word.length) {
                        isPartOfSelectedWord = true;
                      }
                    }
                  }

                  if (isBlack) {
                    return GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          selectedX = null;
                          selectedY = null;
                          selectedWord = null;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 0.5,
                          ),
                        ),
                      ),
                    );
                  }

                  bool isWrong = false;
                  bool isWrongOrIncomplete = false;
                  if (cellValue.isNotEmpty) {
                    isWrong = _isCellInWrongWord(
                      x,
                      y,
                      widget.puzzle.words,
                      state.userAnswers,
                    );
                  }
                  isWrongOrIncomplete = _isCellInWrongOrIncompleteWord(
                    x,
                    y,
                    widget.puzzle.words,
                    state.userAnswers,
                  );

                  final cellColor = isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : (isPartOfSelectedWord
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : Theme.of(context).colorScheme.surface);

                  final isCellRevealed = state.isTemporarilyRevealed && isWrongOrIncomplete;
                  final cellTextColor = isCellRevealed
                      ? Theme.of(context).colorScheme.primary
                      : isWrong
                      ? Theme.of(context).colorScheme.error
                      : (isSelected || isPartOfSelectedWord
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : Theme.of(context).colorScheme.onSurface);

                  return GestureDetector(
                    onTap: () {
                      if (widget.isFillable && !state.isTemporarilyRevealed) {
                        _handleCellTap(x, y);
                      } else if (!widget.isFillable) {
                        _handleLockedCellTap(context, x, y);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: cellColor,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 0.5,
                        ),
                      ),
                      child: Stack(
                        children: [
                          if (wordNumbers.containsKey('$x,$y'))
                            Positioned(
                              top: 2,
                              left: 2,
                              child: Text(
                                wordNumbers['$x,$y'].toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          Center(
                            child: isSelected && !state.isTemporarilyRevealed
                                ? TextField(
                                    autofocus: true,
                                    textAlign: TextAlign.center,
                                    maxLength: 1,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: cellTextColor,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      counterText: '',
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (val) {
                                      ref
                                          .read(crosswordsProvider.notifier)
                                          .setAnswer(x, y, val);
                                      _moveToNextCell();
                                    },
                                  )
                                : Text(
                                    cellValue,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: cellTextColor,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCellTap(int x, int y) {
    setState(() {
      selectedX = x;
      selectedY = y;

      // Find the word that contains this cell. Prefer 'across' if double tapped or if only one exists.
      List<CrosswordWord> matchingWords = [];
      for (var word in widget.puzzle.words) {
        if (word.direction == 'across') {
          if (y == word.y && x >= word.x && x < word.x + word.word.length) {
            matchingWords.add(word);
          }
        } else {
          if (x == word.x && y >= word.y && y < word.y + word.word.length) {
            matchingWords.add(word);
          }
        }
      }

      if (matchingWords.isNotEmpty) {
        if (matchingWords.length == 1) {
          selectedWord = matchingWords.first;
        } else {
          // toggle direction if clicking same cell
          if (selectedWord != null && matchingWords.contains(selectedWord)) {
            selectedWord = matchingWords.firstWhere((w) => w != selectedWord);
          } else {
            selectedWord = matchingWords.first;
          }
        }
      } else {
        selectedWord = null;
      }
    });
  }

  void _moveToNextCell() {
    if (selectedWord == null || selectedX == null || selectedY == null) return;

    setState(() {
      if (selectedWord!.direction == 'across') {
        if (selectedX! < selectedWord!.x + selectedWord!.word.length - 1) {
          selectedX = selectedX! + 1;
        }
      } else {
        if (selectedY! < selectedWord!.y + selectedWord!.word.length - 1) {
          selectedY = selectedY! + 1;
        }
      }
    });
  }
}
