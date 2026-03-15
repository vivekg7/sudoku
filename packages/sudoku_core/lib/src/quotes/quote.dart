/// Tier that controls which difficulty levels a quote is shown for.
enum QuoteTier {
  /// Beginner, Easy — fun, encouraging, simple wisdom.
  light,

  /// Medium, Hard — thoughtful, persistence-themed.
  medium,

  /// Expert, Master — philosophy, complexity, mastery.
  deep;
}

/// An inspirational quote shown alongside a puzzle.
class Quote {
  /// Stable identifier — never reused, even if the quote is removed.
  final int id;

  /// The quote text.
  final String text;

  /// Attribution (author name).
  final String author;

  /// Which difficulty tier this quote belongs to.
  final QuoteTier tier;

  const Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.tier,
  });
}
