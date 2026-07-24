import 'package:flutter/material.dart';
import '../modules/crosswords/models/crossword_model.dart';

class CrosswordPreviewWidget extends StatelessWidget {
  final CrosswordPuzzle puzzle;

  const CrosswordPreviewWidget({super.key, required this.puzzle});

  @override
  Widget build(BuildContext context) {
    final size = puzzle.gridSize > 0 ? puzzle.gridSize : 10;

    final grid = List.generate(size, (_) => List.generate(size, (_) => false));
    final numbers = <String, int>{};

    int numberCounter = 1;
    for (final w in puzzle.words) {
      if (!numbers.containsKey('${w.x},${w.y}')) {
        numbers['${w.x},${w.y}'] = numberCounter++;
      }
      final len = w.word.length;
      for (int i = 0; i < len; i++) {
        final cx = w.direction == 'across' ? w.x + i : w.x;
        final cy = w.direction == 'down' ? w.y + i : w.y;
        if (cx >= 0 && cx < size && cy >= 0 && cy < size) {
          grid[cy][cx] = true;
        }
      }
    }

    return Container(
      width: 280,
      height: 280,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WikiNusa Crossword #${puzzle.puzzleId}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${puzzle.words.length} Clues',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: size,
                ),
                itemCount: size * size,
                itemBuilder: (context, index) {
                  final x = index % size;
                  final y = index ~/ size;
                  final isCell = grid[y][x];
                  final num = numbers['$x,$y'];

                  if (!isCell) {
                    return Container(
                      margin: const EdgeInsets.all(0.5),
                      color: const Color(0xFF1E293B),
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.all(0.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                    child: Stack(
                      children: [
                        if (num != null)
                          Positioned(
                            top: 1,
                            left: 1,
                            child: Text(
                              '$num',
                              style: const TextStyle(
                                fontSize: 6.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                      ],
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
}
