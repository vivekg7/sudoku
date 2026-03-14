import 'package:flutter/material.dart';

import '../state/game_state.dart';
import 'cell_widget.dart';

class BoardWidget extends StatelessWidget {
  final GameState gameState;

  const BoardWidget({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
        ),
        itemCount: 81,
        itemBuilder: (context, index) {
          final row = index ~/ 9;
          final col = index % 9;
          return CellWidget(row: row, col: col, gameState: gameState);
        },
      ),
    );
  }
}
