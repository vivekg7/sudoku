import 'package:sudoku_core/sudoku_core.dart';

/// Creates a board from a flat string and computes candidates.
Board boardWithCandidates(String flat) {
  final board = Board.fromString(flat);
  computeCandidates(board);
  return board;
}
