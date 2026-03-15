import 'quote.dart';

/// All bundled quotes. IDs are stable and never reused.
///
/// To add quotes: append to the end of the relevant tier section
/// with the next available ID.
const allQuotes = <Quote>[
  // ── Light tier (Beginner, Easy) ──────────────────────────────────

  Quote(
    id: 1,
    text: 'The secret of getting ahead is getting started.',
    author: 'Mark Twain',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 2,
    text: 'Every expert was once a beginner.',
    author: 'Helen Hayes',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 3,
    text: 'Curiosity is the wick in the candle of learning.',
    author: 'William Arthur Ward',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 4,
    text: 'Small steps in the right direction can turn out to be the biggest step of your life.',
    author: 'Naeem Callaway',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 5,
    text: 'The only way to do great work is to love what you do.',
    author: 'Steve Jobs',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 6,
    text: 'A journey of a thousand miles begins with a single step.',
    author: 'Lao Tzu',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 7,
    text: 'Do what you can, with what you have, where you are.',
    author: 'Theodore Roosevelt',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 8,
    text: 'The best time to plant a tree was twenty years ago. The second best time is now.',
    author: 'Chinese Proverb',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 9,
    text: 'You don\'t have to be great to start, but you have to start to be great.',
    author: 'Zig Ziglar',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 10,
    text: 'It always seems impossible until it is done.',
    author: 'Nelson Mandela',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 11,
    text: 'Enjoy the little things, for one day you may look back and realise they were the big things.',
    author: 'Robert Brault',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 12,
    text: 'The mind is not a vessel to be filled, but a fire to be kindled.',
    author: 'Plutarch',
    tier: QuoteTier.light,
  ),

  // ── Medium tier (Medium, Hard) ───────────────────────────────────

  Quote(
    id: 13,
    text: 'The impediment to action advances action. What stands in the way becomes the way.',
    author: 'Marcus Aurelius',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 14,
    text: 'Patience is not the ability to wait, but the ability to keep a good attitude while waiting.',
    author: 'Joyce Meyer',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 15,
    text: 'The gem cannot be polished without friction, nor man perfected without trials.',
    author: 'Chinese Proverb',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 16,
    text: 'It is not that I\'m so smart. But I stay with the questions much longer.',
    author: 'Albert Einstein',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 17,
    text: 'Out of difficulties grow miracles.',
    author: 'Jean de La Bruyère',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 18,
    text: 'The only impossible journey is the one you never begin.',
    author: 'Tony Robbins',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 19,
    text: 'Rivers know this: there is no hurry. We shall get there some day.',
    author: 'A.A. Milne',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 20,
    text: 'A problem well stated is a problem half solved.',
    author: 'Charles Kettering',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 21,
    text: 'Perseverance is not a long race; it is many short races one after the other.',
    author: 'Walter Elliot',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 22,
    text: 'The harder the conflict, the greater the triumph.',
    author: 'George Washington',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 23,
    text: 'No problem can withstand the assault of sustained thinking.',
    author: 'Voltaire',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 24,
    text: 'He who has a why to live can bear almost any how.',
    author: 'Friedrich Nietzsche',
    tier: QuoteTier.medium,
  ),

  // ── Deep tier (Expert, Master) ───────────────────────────────────

  Quote(
    id: 25,
    text: 'We are what we repeatedly do. Excellence, then, is not an act, but a habit.',
    author: 'Aristotle',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 26,
    text: 'The unexamined life is not worth living.',
    author: 'Socrates',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 27,
    text: 'Knowing yourself is the beginning of all wisdom.',
    author: 'Aristotle',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 28,
    text: 'He who conquers himself is the mightiest warrior.',
    author: 'Confucius',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 29,
    text: 'The mind that opens to a new idea never returns to its original size.',
    author: 'Albert Einstein',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 30,
    text: 'Simplicity is the ultimate sophistication.',
    author: 'Leonardo da Vinci',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 31,
    text: 'You have power over your mind — not outside events. Realise this, and you will find strength.',
    author: 'Marcus Aurelius',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 32,
    text: 'The only true wisdom is in knowing you know nothing.',
    author: 'Socrates',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 33,
    text: 'Order and simplification are the first steps toward mastery of a subject.',
    author: 'Thomas Mann',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 34,
    text: 'What we observe is not nature itself, but nature exposed to our method of questioning.',
    author: 'Werner Heisenberg',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 35,
    text: 'The whole is more than the sum of its parts.',
    author: 'Aristotle',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 36,
    text: 'No great mind has ever existed without a touch of madness.',
    author: 'Aristotle',
    tier: QuoteTier.deep,
  ),
];
