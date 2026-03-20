import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

/// A subtle banner displaying the quote assigned to the current puzzle.
class QuoteBanner extends StatelessWidget {
  final int? quoteId;

  const QuoteBanner({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context) {
    if (quoteId == null) return const SizedBox.shrink();

    final quote = QuoteRepository.instance.getById(quoteId!);
    if (quote == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Text(
        '"${quote.text}" - ${quote.author}',
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          height: 1.4,
        ),
      ),
    );
  }
}
