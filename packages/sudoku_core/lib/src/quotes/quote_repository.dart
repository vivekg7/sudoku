import '../models/difficulty.dart';
import 'quote.dart';
import 'quotes_data.dart';

/// Provides access to quotes, with weighted tier distribution per difficulty.
class QuoteRepository {
  QuoteRepository._();

  static final QuoteRepository instance = QuoteRepository._();

  /// All quotes, indexed by ID for O(1) lookup.
  late final Map<int, Quote> _byId = {
    for (final q in allQuotes) q.id: q,
  };

  /// Quotes grouped by tier.
  late final Map<QuoteTier, List<Quote>> _byTier = () {
    final map = <QuoteTier, List<Quote>>{};
    for (final tier in QuoteTier.values) {
      map[tier] = allQuotes.where((q) => q.tier == tier).toList();
    }
    return map;
  }();

  /// Tier weight distributions per difficulty.
  ///
  /// Values are percentages (must sum to 100). The primary tier dominates
  /// but every tier has a nonzero chance, so no quote is walled off.
  static const _weights = <Difficulty, Map<QuoteTier, int>>{
    Difficulty.beginner: {QuoteTier.light: 60, QuoteTier.medium: 30, QuoteTier.deep: 10},
    Difficulty.easy:     {QuoteTier.light: 50, QuoteTier.medium: 35, QuoteTier.deep: 15},
    Difficulty.medium:   {QuoteTier.light: 20, QuoteTier.medium: 55, QuoteTier.deep: 25},
    Difficulty.hard:     {QuoteTier.light: 15, QuoteTier.medium: 50, QuoteTier.deep: 35},
    Difficulty.expert:   {QuoteTier.light: 10, QuoteTier.medium: 30, QuoteTier.deep: 60},
    Difficulty.master:   {QuoteTier.light: 10, QuoteTier.medium: 25, QuoteTier.deep: 65},
  };

  /// Returns the primary tier for a given difficulty.
  static QuoteTier tierFor(Difficulty difficulty) => switch (difficulty) {
        Difficulty.beginner || Difficulty.easy => QuoteTier.light,
        Difficulty.medium || Difficulty.hard => QuoteTier.medium,
        Difficulty.expert || Difficulty.master => QuoteTier.deep,
      };

  /// Picks a quote for a puzzle based on difficulty and a seed value.
  ///
  /// Uses the seed to first select a tier (weighted by difficulty), then
  /// pick a quote within that tier. Returns the quote's stable [id].
  int pickQuoteId(Difficulty difficulty, int seed) {
    final absSeed = seed.abs();
    final tier = _pickTier(difficulty, absSeed);
    final pool = _byTier[tier]!;
    // Use a different portion of the seed for within-tier selection
    // to avoid correlation between tier choice and quote choice.
    return pool[(absSeed ~/ 100) % pool.length].id;
  }

  /// Selects a tier using weighted distribution based on `seed % 100`.
  QuoteTier _pickTier(Difficulty difficulty, int seed) {
    final weights = _weights[difficulty]!;
    final roll = seed % 100;
    var cumulative = 0;
    for (final entry in weights.entries) {
      cumulative += entry.value;
      if (roll < cumulative) return entry.key;
    }
    // Fallback (shouldn't happen if weights sum to 100).
    return weights.entries.last.key;
  }

  /// Looks up a quote by its stable ID. Returns `null` if not found
  /// (e.g. the quote was retired).
  Quote? getById(int id) => _byId[id];
}
