import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../state/game_state.dart';

class CellWidget extends StatelessWidget {
  final int row;
  final int col;
  final GameState gameState;

  const CellWidget({
    super.key,
    required this.row,
    required this.col,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    final cell = gameState.puzzle!.board.getCell(row, col);
    final isSelected = gameState.isSelected(row, col);
    final isRelated = gameState.isRelatedToSelected(row, col);
    final sameValue = gameState.hasSameValueAsSelected(row, col);
    final isConflict = gameState.conflicts.contains((row, col));

    final bgColor = _backgroundColor(isSelected, isRelated, sameValue, isConflict);
    final border = _cellBorder();

    return GestureDetector(
      onTap: () => gameState.selectCell(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: border,
        ),
        child: cell.isFilled
            ? _buildValue(cell, isConflict)
            : _buildCandidates(cell.candidates),
      ),
    );
  }

  Color _backgroundColor(
      bool isSelected, bool isRelated, bool sameValue, bool isConflict) {
    if (isConflict && isSelected) return const Color(0xFFFFCDD2);
    if (isSelected) return const Color(0xFFBBDEFB);
    if (isConflict) return const Color(0xFFFFEBEE);
    if (sameValue) return const Color(0xFFE3F2FD);
    if (isRelated) return const Color(0xFFF5F5F5);
    return Colors.white;
  }

  Border _cellBorder() {
    const thin = BorderSide(color: Color(0xFFBDBDBD), width: 0.5);
    const thick = BorderSide(color: Color(0xFF424242), width: 1.5);

    return Border(
      top: row % 3 == 0 ? thick : thin,
      left: col % 3 == 0 ? thick : thin,
      bottom: row == 8 ? thick : BorderSide.none,
      right: col == 8 ? thick : BorderSide.none,
    );
  }

  Widget _buildValue(Cell cell, bool isConflict) {
    final color = isConflict
        ? const Color(0xFFD32F2F)
        : cell.isGiven
            ? const Color(0xFF212121)
            : const Color(0xFF1565C0);

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${cell.value}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: cell.isGiven ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildCandidates(Set<int> candidates) {
    if (candidates.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(1),
      child: Column(
        children: [
          for (var r = 0; r < 3; r++)
            Expanded(
              child: Row(
                children: [
                  for (var c = 0; c < 3; c++)
                    Expanded(
                      child: Center(
                        child: _candidateDigit(r * 3 + c + 1, candidates),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _candidateDigit(int digit, Set<int> candidates) {
    if (!candidates.contains(digit)) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '$digit',
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF757575),
        ),
      ),
    );
  }
}
