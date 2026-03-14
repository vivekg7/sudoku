import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Sudoku',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a difficulty',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 40),
                for (final difficulty in Difficulty.values) ...[
                  SizedBox(
                    width: 220,
                    child: FilledButton.tonal(
                      onPressed: () => _startGame(context, difficulty),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        difficulty.label,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context, Difficulty difficulty) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(difficulty: difficulty),
      ),
    );
  }
}
