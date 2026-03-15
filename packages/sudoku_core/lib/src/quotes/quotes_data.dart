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
    text:
        'Small steps in the right direction can turn out to be the biggest step of your life.',
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
    text:
        'The best time to plant a tree was twenty years ago. The second best time is now.',
    author: 'Chinese Proverb',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 9,
    text:
        'You don\'t have to be great to start, but you have to start to be great.',
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
    text:
        'Enjoy the little things, for one day you may look back and realise they were the big things.',
    author: 'Robert Brault',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 12,
    text: 'The mind is not a vessel to be filled, but a fire to be kindled.',
    author: 'Plutarch',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 37,
    text: 'What you seek is seeking you.',
    author: 'Rumi',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 38,
    text: 'Have patience. All things are difficult before they become easy.',
    author: 'Saadi Shirazi',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 39,
    text: 'Faith is the bird that feels the light when the dawn is still dark.',
    author: 'Rabindranath Tagore',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 40,
    text: 'In the middle of difficulty lies opportunity.',
    author: 'Albert Einstein',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 41,
    text: 'Learning is a treasure that will follow its owner everywhere.',
    author: 'Chinese Proverb',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 42,
    text:
        'A calm mind brings inner strength and self-confidence, so that is very important for good health.',
    author: 'Dalai Lama',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 43,
    text:
        'The flower that blooms in adversity is the rarest and most beautiful of all.',
    author: 'Mulan (Chinese Proverb)',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 44,
    text: 'Arise, awake, and stop not till the goal is reached.',
    author: 'Swami Vivekananda',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 45,
    text: 'Well begun is half done.',
    author: 'Aristotle',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 46,
    text:
        'Where there is a will, there is a way. If there is a chance in a million that you can do something to keep what you love from ending, do it.',
    author: 'A.P.J. Abdul Kalam',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 47,
    text:
        'The greatest glory in living lies not in never falling, but in rising every time we fall.',
    author: 'Nelson Mandela',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 48,
    text: 'Do not wait for leaders; do it alone, person to person.',
    author: 'Mother Teresa',
    tier: QuoteTier.light,
  ),

  // ── Medium tier (Medium, Hard) ───────────────────────────────────
  Quote(
    id: 13,
    text:
        'The impediment to action advances action. What stands in the way becomes the way.',
    author: 'Marcus Aurelius',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 14,
    text:
        'Patience is not the ability to wait, but the ability to keep a good attitude while waiting.',
    author: 'Joyce Meyer',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 15,
    text:
        'The gem cannot be polished without friction, nor man perfected without trials.',
    author: 'Chinese Proverb',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 16,
    text:
        'It is not that I\'m so smart. But I stay with the questions much longer.',
    author: 'Albert Einstein',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 17,
    text: 'Out of difficulties grow miracles.',
    author: 'Jean de La Bruyere',
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
    text:
        'Perseverance is not a long race; it is many short races one after the other.',
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
  Quote(
    id: 49,
    text:
        'You have to grow from the inside out. None can teach you, none can make you spiritual. There is no other teacher but your own soul.',
    author: 'Swami Vivekananda',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 50,
    text: 'Yoga is the journey of the self, through the self, to the self.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 51,
    text: 'The soul is neither born, and nor does it die.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 52,
    text: 'There is nothing lost or wasted in this life.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 53,
    text: 'An ounce of practice is worth more than tons of preaching.',
    author: 'Mahatma Gandhi',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 54,
    text:
        'Strength does not come from physical capacity. It comes from an indomitable will.',
    author: 'Mahatma Gandhi',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 55,
    text:
        'The world has enough for everyone\'s need, but not enough for everyone\'s greed.',
    author: 'Mahatma Gandhi',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 56,
    text:
        'Let your plans be dark and impenetrable as night, and when you move, fall like a thunderbolt.',
    author: 'Sun Tzu',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 57,
    text: 'A person can achieve everything by being simple and humble.',
    author: 'Rig Veda',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 58,
    text: 'The wise see knowledge and action as one.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 59,
    text:
        'Before you speak, let your words pass through three gates: Is it true? Is it necessary? Is it kind?',
    author: 'Rumi',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 60,
    text: 'The mind is everything. What you think, you become.',
    author: 'Buddha',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 61,
    text:
        'As the heat of a fire reduces wood to ashes, the fire of knowledge burns to ashes all karma.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 62,
    text:
        'If you want to walk fast, walk alone. If you want to walk far, walk together.',
    author: 'African Proverb',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 63,
    text:
        'Dream is not that which you see while sleeping. It is something that does not let you sleep.',
    author: 'A.P.J. Abdul Kalam',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 64,
    text: 'Stillness is where creativity and solutions to problems are found.',
    author: 'Eckhart Tolle',
    tier: QuoteTier.medium,
  ),

  // ── Deep tier (Expert, Master) ───────────────────────────────────
  Quote(
    id: 25,
    text:
        'We are what we repeatedly do. Excellence, then, is not an act, but a habit.',
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
    text:
        'The mind that opens to a new idea never returns to its original size.',
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
    text:
        'You have power over your mind - not outside events. Realise this, and you will find strength.',
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
    text:
        'Order and simplification are the first steps toward mastery of a subject.',
    author: 'Thomas Mann',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 34,
    text:
        'What we observe is not nature itself, but nature exposed to our method of questioning.',
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
  Quote(
    id: 65,
    text:
        'You have the right to work, but never to the fruit of work. You should never engage in action for the sake of reward.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 66,
    text:
        'When meditation is mastered, the mind is unwavering like the flame of a candle in a windless place.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 67,
    text:
        'The one who sees inaction in action, and action in inaction, is wise among men.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 68,
    text:
        'Reshape yourself through the power of your will. Those who have conquered themselves live in peace, alike in cold and heat, pleasure and pain, praise and blame.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 69,
    text:
        'From a clear knowledge of the Bhagavad Gita all the goals of human existence become fulfilled.',
    author: 'Adi Shankaracharya',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 70,
    text: 'As a man thinketh in his heart, so is he.',
    author: 'Proverbs 23:7',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 71,
    text:
        'That which permeates the entire body, know it to be indestructible. No one can cause the destruction of the imperishable soul.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 72,
    text: 'All that we are is the result of what we have thought.',
    author: 'Buddha',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 73,
    text:
        'In the depth of winter, I finally learned that within me there lay an invincible summer.',
    author: 'Albert Camus',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 74,
    text: 'Who looks outside, dreams; who looks inside, awakes.',
    author: 'Carl Jung',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 75,
    text:
        'The self is the friend of the self, and the self is the enemy of the self.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 76,
    text:
        'There is nothing higher than dharma. The weak overcomes the stronger by dharma, as over a king.',
    author: 'Brihadaranyaka Upanishad',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 77,
    text:
        'Lead me from the unreal to the real, from darkness to light, from death to immortality.',
    author: 'Brihadaranyaka Upanishad',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 78,
    text:
        'As is the human body, so is the cosmic body. As is the human mind, so is the cosmic mind.',
    author: 'Upanishads',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 79,
    text: 'Truth is one; the wise call it by many names.',
    author: 'Rig Veda',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 80,
    text: 'When you let go of what you are, you become what you might be.',
    author: 'Lao Tzu',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 81,
    text: 'They alone live who live for others.',
    author: 'Swami Vivekananda',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 82,
    text:
        'Where the mind is without fear and the head is held high, into that heaven of freedom, let my country awake.',
    author: 'Rabindranath Tagore',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 83,
    text:
        'The learned give up the fruit of action, and freed from the bondage of rebirth, they reach the state beyond all suffering.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 84,
    text:
        'A man is but the product of his thoughts. What he thinks, he becomes.',
    author: 'Mahatma Gandhi',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 85,
    text: 'The measure of intelligence is the ability to change.',
    author: 'Albert Einstein',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 86,
    text: 'He who has conquered his own mind has conquered the world.',
    author: 'Guru Nanak',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 87,
    text:
        'Educating the mind without educating the heart is no education at all.',
    author: 'Aristotle',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 88,
    text: 'An eye for an eye only ends up making the whole world blind.',
    author: 'Mahatma Gandhi',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 89,
    text: 'Those who know do not speak. Those who speak do not know.',
    author: 'Lao Tzu',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 90,
    text: 'The greatest wealth is a poverty of desires.',
    author: 'Seneca',
    tier: QuoteTier.deep,
  ),
];
