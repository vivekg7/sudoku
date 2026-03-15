import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  final repo = QuoteRepository.instance;

  test('all quote IDs are unique', () {
    final ids = allQuotes.map((q) => q.id).toSet();
    expect(ids.length, equals(allQuotes.length));
  });

  test('each tier has at least one quote', () {
    for (final tier in QuoteTier.values) {
      expect(
        allQuotes.where((q) => q.tier == tier),
        isNotEmpty,
        reason: 'tier $tier has no quotes',
      );
    }
  });

  test('tierFor maps primary tier correctly', () {
    expect(QuoteRepository.tierFor(Difficulty.beginner), QuoteTier.light);
    expect(QuoteRepository.tierFor(Difficulty.easy), QuoteTier.light);
    expect(QuoteRepository.tierFor(Difficulty.medium), QuoteTier.medium);
    expect(QuoteRepository.tierFor(Difficulty.hard), QuoteTier.medium);
    expect(QuoteRepository.tierFor(Difficulty.expert), QuoteTier.deep);
    expect(QuoteRepository.tierFor(Difficulty.master), QuoteTier.deep);
  });

  test('pickQuoteId always returns a valid quote', () {
    for (final difficulty in Difficulty.values) {
      for (var seed = 0; seed < 100; seed++) {
        final id = repo.pickQuoteId(difficulty, seed);
        expect(repo.getById(id), isNotNull,
            reason: 'invalid ID $id for $difficulty seed $seed');
      }
    }
  });

  test('pickQuoteId is deterministic for same seed', () {
    final id1 = repo.pickQuoteId(Difficulty.medium, 123);
    final id2 = repo.pickQuoteId(Difficulty.medium, 123);
    expect(id1, equals(id2));
  });

  test('different seeds produce different quotes', () {
    final ids = <int>{};
    for (var seed = 0; seed < 1000; seed++) {
      ids.add(repo.pickQuoteId(Difficulty.beginner, seed));
    }
    expect(ids.length, greaterThan(1));
  });

  test('weighted distribution gives beginner mostly light quotes', () {
    final tierCounts = <QuoteTier, int>{};
    for (var seed = 0; seed < 1000; seed++) {
      final id = repo.pickQuoteId(Difficulty.beginner, seed);
      final quote = repo.getById(id)!;
      tierCounts[quote.tier] = (tierCounts[quote.tier] ?? 0) + 1;
    }
    // Light should dominate (60%) but all tiers should appear.
    expect(tierCounts[QuoteTier.light]!, greaterThan(tierCounts[QuoteTier.medium]!));
    expect(tierCounts[QuoteTier.medium]!, greaterThan(tierCounts[QuoteTier.deep]!));
    expect(tierCounts[QuoteTier.deep]!, greaterThan(0));
  });

  test('weighted distribution gives master mostly deep quotes', () {
    final tierCounts = <QuoteTier, int>{};
    for (var seed = 0; seed < 1000; seed++) {
      final id = repo.pickQuoteId(Difficulty.master, seed);
      final quote = repo.getById(id)!;
      tierCounts[quote.tier] = (tierCounts[quote.tier] ?? 0) + 1;
    }
    // Deep should dominate (65%) but all tiers should appear.
    expect(tierCounts[QuoteTier.deep]!, greaterThan(tierCounts[QuoteTier.medium]!));
    expect(tierCounts[QuoteTier.medium]!, greaterThan(tierCounts[QuoteTier.light]!));
    expect(tierCounts[QuoteTier.light]!, greaterThan(0));
  });

  test('getById returns null for non-existent ID', () {
    expect(repo.getById(99999), isNull);
  });

  test('generated puzzles have a quoteId', () {
    final generator = PuzzleGenerator(random: null);
    final puzzle = generator.generate(Difficulty.easy);
    expect(puzzle, isNotNull);
    expect(puzzle!.quoteId, isNotNull);
    expect(repo.getById(puzzle.quoteId!), isNotNull);
  });
}
