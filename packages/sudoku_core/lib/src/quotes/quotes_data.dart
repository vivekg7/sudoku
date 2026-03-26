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
  Quote(
    id: 91,
    text:
        'Live as if you were to die tomorrow. Learn as if you were to live forever.',
    author: 'Mahatma Gandhi',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 92,
    text: 'Great dreams of great dreamers are always transcended.',
    author: 'A.P.J. Abdul Kalam',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 93,
    text:
        'Happiness is when what you think, what you say, and what you do are in harmony.',
    author: 'Mahatma Gandhi',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 94,
    text:
        'All birds find shelter during a rain. But the eagle avoids rain by flying above the clouds.',
    author: 'A.P.J. Abdul Kalam',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 95,
    text:
        'Take risks in your life. If you win, you can lead. If you lose, you can guide.',
    author: 'Swami Vivekananda',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 96,
    text:
        'Let us sacrifice our today so that our children can have a better tomorrow.',
    author: 'A.P.J. Abdul Kalam',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 97,
    text:
        'The best way to find yourself is to lose yourself in the service of others.',
    author: 'Mahatma Gandhi',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 98,
    text:
        'We are what our thoughts have made us; so take care about what you think.',
    author: 'Swami Vivekananda',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 116,
    text: 'Fall seven times, stand up eight.',
    author: 'Japanese Proverb',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 117,
    text:
        'The bamboo that bends is stronger than the oak that resists.',
    author: 'Japanese Proverb',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 118,
    text: 'Beginning is easy, continuing is hard.',
    author: 'Japanese Proverb',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 119,
    text: 'Even dust, if piled up, will become a mountain.',
    author: 'Japanese Proverb',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 120,
    text: 'A frog in a well knows nothing of the sea.',
    author: 'Japanese Proverb',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 121,
    text:
        'Be not afraid of growing slowly, be afraid only of standing still.',
    author: 'Chinese Proverb',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 122,
    text: 'Teachers open the door, but you must enter by yourself.',
    author: 'Chinese Proverb',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 123,
    text:
        'One who asks a question is a fool for five minutes; one who does not ask remains a fool forever.',
    author: 'Chinese Proverb',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 124,
    text: 'Talk does not cook rice.',
    author: 'Chinese Proverb',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 125,
    text: 'Smooth seas do not make skillful sailors.',
    author: 'African Proverb',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 126,
    text: 'However long the night, the dawn will break.',
    author: 'African Proverb',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 127,
    text:
        'It does not matter how slowly you go as long as you do not stop.',
    author: 'Confucius',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 128,
    text:
        'A ship in harbour is safe, but that is not what ships are built for.',
    author: 'John A. Shedd',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 129,
    text: 'Not all those who wander are lost.',
    author: 'J.R.R. Tolkien',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 130,
    text:
        'What lies behind us and what lies before us are tiny matters compared to what lies within us.',
    author: 'Ralph Waldo Emerson',
    tier: QuoteTier.light,
  ),
  Quote(
    id: 131,
    text:
        'If you can\'t fly, then run. If you can\'t run, then walk. If you can\'t walk, then crawl, but whatever you do, you have to keep moving forward.',
    author: 'Martin Luther King Jr.',
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
  Quote(
    id: 99,
    text:
        'The fragrance of flowers spreads only in the direction of the wind. But the goodness of a person spreads in all directions.',
    author: 'Chanakya',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 100,
    text: 'Education is the manifestation of the perfection already in man.',
    author: 'Swami Vivekananda',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 101,
    text:
        'Do not dwell in the past, do not dream of the future, concentrate the mind on the present moment.',
    author: 'Buddha',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 102,
    text: 'In a conflict between the heart and the brain, follow your heart.',
    author: 'Swami Vivekananda',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 103,
    text: 'You cannot believe in God until you believe in yourself.',
    author: 'Swami Vivekananda',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 104,
    text:
        'The earth is enjoyed by heroes — this is the unfailing truth. Be a hero.',
    author: 'Chanakya',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 105,
    text:
        'An equation for me has no meaning unless it expresses a thought of God.',
    author: 'Srinivasa Ramanujan',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 106,
    text:
        'Do not be led by others, awaken your own mind, amass your own experience, and decide for yourself your own path.',
    author: 'Atharva Veda',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 107,
    text:
        'There is no end to education. It is not that you read a book, pass an examination, and finish with education. The whole of life is a process of learning.',
    author: 'J. Krishnamurti',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 132,
    text: 'Think lightly of yourself and deeply of the world.',
    author: 'Miyamoto Musashi',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 133,
    text:
        'There is nothing outside of yourself that can ever enable you to get better, stronger, richer, quicker, or smarter. Everything is within.',
    author: 'Miyamoto Musashi',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 134,
    text:
        'Perception is strong and sight weak. In strategy it is important to see distant things as if they were close and to take a distanced view of close things.',
    author: 'Miyamoto Musashi',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 135,
    text:
        'Do not seek to follow in the footsteps of the wise; seek what they sought.',
    author: 'Matsuo Bashō',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 136,
    text: 'To know and not to do is not yet to know.',
    author: 'Zen Proverb',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 137,
    text: 'The obstacle is the path.',
    author: 'Zen Proverb',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 138,
    text: 'When you reach the top of the mountain, keep climbing.',
    author: 'Zen Proverb',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 139,
    text:
        'The more you sweat in practice, the less you bleed in battle.',
    author: 'Chinese Proverb',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 140,
    text: 'Dig the well before you are thirsty.',
    author: 'Chinese Proverb',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 141,
    text:
        'The person who moves a mountain begins by carrying away small stones.',
    author: 'Confucius',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 142,
    text: 'Real knowledge is to know the extent of one\'s ignorance.',
    author: 'Confucius',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 143,
    text: 'Study the past if you would define the future.',
    author: 'Confucius',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 144,
    text: 'Better a diamond with a flaw than a pebble without.',
    author: 'Confucius',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 145,
    text:
        'Be like water making its way through cracks. Adjust, adapt, and find your way.',
    author: 'Bruce Lee',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 146,
    text: 'Knowledge is of no value unless you put it into practice.',
    author: 'Anton Chekhov',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 147,
    text:
        'Knowing is not enough, we must apply. Willing is not enough, we must do.',
    author: 'Johann Wolfgang von Goethe',
    tier: QuoteTier.medium,
  ),
  Quote(
    id: 148,
    text:
        'The master has failed more times than the beginner has even tried.',
    author: 'Stephen McCranie',
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
  Quote(
    id: 108,
    text:
        'It is better to live your own destiny imperfectly than to live an imitation of somebody else\'s life with perfection.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 109,
    text:
        'There is neither this world, nor the world beyond, nor happiness for the one who doubts.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 110,
    text: 'Yoga is the stilling of the fluctuations of the mind.',
    author: 'Patanjali',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 111,
    text:
        'The self-controlled soul, who moves amongst sense objects, free from either attachment or repulsion, wins eternal peace.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 112,
    text:
        'That which seems like poison at first, but tastes like nectar in the end — this is the joy of clarity, born from the serenity of one\'s own mind.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 113,
    text:
        'The knowing self is not born, it does not die. It has not sprung from anything; nothing has sprung from it.',
    author: 'Katha Upanishad',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 114,
    text:
        'When the five senses and the mind are still, and the reasoning intellect does not stir, that is called the highest state.',
    author: 'Katha Upanishad',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 115,
    text:
        'Whatever happened, happened for the good. Whatever is happening, is happening for the good. Whatever will happen, will also happen for the good.',
    author: 'Bhagavad Gita',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 149,
    text:
        'No man ever steps in the same river twice, for it is not the same river and he is not the same man.',
    author: 'Heraclitus',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 150,
    text: 'Nothing lasts, nothing is finished, nothing is perfect.',
    author: 'Wabi-Sabi',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 151,
    text:
        'In the beginner\'s mind there are many possibilities, but in the expert\'s mind there are few.',
    author: 'Shunryu Suzuki',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 152,
    text:
        'Do you have the patience to wait till your mud settles and the water is clear?',
    author: 'Lao Tzu',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 153,
    text: 'Nature does not hurry, yet everything is accomplished.',
    author: 'Lao Tzu',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 154,
    text: 'Mastering others is strength. Mastering yourself is true power.',
    author: 'Lao Tzu',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 155,
    text:
        'One moment of patience may ward off great disaster. One moment of impatience may ruin a whole life.',
    author: 'Chinese Proverb',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 156,
    text: 'Everything has beauty, but not everyone sees it.',
    author: 'Confucius',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 157,
    text:
        'If you understand, things are just as they are; if you do not understand, things are just as they are.',
    author: 'Zen Proverb',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 158,
    text:
        'The first principle is that you must not fool yourself — and you are the easiest person to fool.',
    author: 'Richard Feynman',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 159,
    text:
        'To think is easy. To act is hard. But the hardest thing in the world is to act in accordance with your thinking.',
    author: 'Johann Wolfgang von Goethe',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 160,
    text: 'Silence is the sleep that nourishes wisdom.',
    author: 'Francis Bacon',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 161,
    text:
        'The purpose of life is not to be happy. It is to be useful, to be honourable, to be compassionate.',
    author: 'Ralph Waldo Emerson',
    tier: QuoteTier.deep,
  ),
  Quote(
    id: 162,
    text: 'The less effort, the faster and more powerful you will be.',
    author: 'Bruce Lee',
    tier: QuoteTier.deep,
  ),
];
