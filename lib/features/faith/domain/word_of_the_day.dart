/// Daily scripture and a short original reflection for Christian Golfers.
///
/// Scripture excerpts use the public-domain King James Version (KJV).
class WordOfTheDay {
  const WordOfTheDay({
    required this.reference,
    required this.verse,
    required this.reflection,
  });

  final String reference;
  final String verse;
  final String reflection;

  static const List<WordOfTheDay> _readings = [
    WordOfTheDay(
      reference: 'Proverbs 3:5',
      verse: 'Trust in the LORD with all thine heart; and lean not unto thine own understanding.',
      reflection: 'Trust is choosing the right direction even when you cannot see every step ahead.',
    ),
    WordOfTheDay(
      reference: 'Philippians 4:13',
      verse: 'I can do all things through Christ which strengtheneth me.',
      reflection: 'Meet today’s challenges with courage, humility, and strength beyond your own.',
    ),
    WordOfTheDay(
      reference: 'Micah 6:8',
      verse: '...to do justly, and to love mercy, and to walk humbly with thy God.',
      reflection: 'Compete fairly, show mercy when others struggle, and keep humility at the centre of the game.',
    ),
    WordOfTheDay(
      reference: 'Psalm 19:14',
      verse: 'Let the words of my mouth, and the meditation of my heart, be acceptable in thy sight, O LORD.',
      reflection: 'Let your words encourage your playing partners, on the course and beyond it.',
    ),
    WordOfTheDay(
      reference: 'Colossians 3:23',
      verse: 'And whatsoever ye do, do it heartily, as to the Lord, and not unto men;',
      reflection: 'Bring your best effort to every task, while remembering that character matters more than a score.',
    ),
    WordOfTheDay(
      reference: 'Joshua 1:9',
      verse: 'Be strong and of a good courage; be not afraid, neither be thou dismayed: for the LORD thy God is with thee whithersoever thou goest.',
      reflection: 'Take the next shot, decision, or conversation with courage. You do not walk alone.',
    ),
    WordOfTheDay(
      reference: 'Psalm 23:1',
      verse: 'The LORD is my shepherd; I shall not want.',
      reflection: 'Make room for gratitude today. Faith reminds us that our worth is not measured by what we own or achieve.',
    ),
    WordOfTheDay(
      reference: 'James 1:19',
      verse: '...let every man be swift to hear, slow to speak, slow to wrath:',
      reflection: 'Listen well to your friends. Patience can turn a tense moment into a chance to show grace.',
    ),
    WordOfTheDay(
      reference: 'Galatians 6:9',
      verse: 'And let us not be weary in well doing: for in due season we shall reap, if we faint not.',
      reflection: 'Small acts of kindness and steady practice both matter. Keep going with a faithful heart.',
    ),
    WordOfTheDay(
      reference: 'Romans 12:10',
      verse: 'Be kindly affectioned one to another with brotherly love; in honour preferring one another;',
      reflection: 'Celebrate another golfer’s good shot as sincerely as your own. Fellowship grows through honour.',
    ),
    WordOfTheDay(
      reference: 'Psalm 46:10',
      verse: 'Be still, and know that I am God:',
      reflection: 'Pause before you react. A quiet moment can restore perspective and peace.',
    ),
    WordOfTheDay(
      reference: 'Matthew 5:9',
      verse: 'Blessed are the peacemakers: for they shall be called the children of God.',
      reflection: 'Be someone who brings calm, fairness, and reconciliation into every group you join.',
    ),
    WordOfTheDay(
      reference: '1 Corinthians 16:14',
      verse: 'Let all your things be done with charity.',
      reflection: 'Let love shape how you compete, speak, lead, and treat those around you.',
    ),
    WordOfTheDay(
      reference: 'Psalm 118:24',
      verse: 'This is the day which the LORD hath made; we will rejoice and be glad in it.',
      reflection: 'Receive this day as a gift, whatever your scorecard or circumstances may hold.',
    ),
    WordOfTheDay(
      reference: 'Proverbs 16:3',
      verse: 'Commit thy works unto the LORD, and thy thoughts shall be established.',
      reflection: 'Set your intentions, work diligently, and entrust the outcome to God.',
    ),
    WordOfTheDay(
      reference: 'Ephesians 4:32',
      verse: 'And be ye kind one to another, tenderhearted, forgiving one another, even as God for Christ’s sake hath forgiven you.',
      reflection: 'Extend the same patience to others that you hope to receive yourself.',
    ),
    WordOfTheDay(
      reference: 'Hebrews 12:1',
      verse: '...let us run with patience the race that is set before us,',
      reflection: 'Your journey is your own. Stay focused on steady progress rather than comparison.',
    ),
    WordOfTheDay(
      reference: 'Matthew 6:34',
      verse: 'Take therefore no thought for the morrow: for the morrow shall take thought for the things of itself.',
      reflection: 'Give your attention to the moment in front of you. You only need to take today’s next step.',
    ),
    WordOfTheDay(
      reference: 'Psalm 37:5',
      verse: 'Commit thy way unto the LORD; trust also in him; and he shall bring it to pass.',
      reflection: 'Bring your plans to God and stay open to the path that unfolds.',
    ),
    WordOfTheDay(
      reference: '1 Peter 4:10',
      verse: 'As every man hath received the gift, even so minister the same one to another...',
      reflection: 'Use your gifts to serve fellow golfers, whether by teaching, encouraging, or making room for others.',
    ),
    WordOfTheDay(
      reference: 'Proverbs 27:17',
      verse: 'Iron sharpeneth iron; so a man sharpeneth the countenance of his friend.',
      reflection: 'Good friends help each other grow through honest feedback, encouragement, and shared time.',
    ),
    WordOfTheDay(
      reference: 'Romans 15:13',
      verse: 'Now the God of hope fill you with all joy and peace in believing...',
      reflection: 'Make space for hope today, even when results have not yet arrived.',
    ),
    WordOfTheDay(
      reference: 'Psalm 121:2',
      verse: 'My help cometh from the LORD, which made heaven and earth.',
      reflection: 'When you feel stretched, remember to ask for help and to offer it to someone else.',
    ),
    WordOfTheDay(
      reference: 'Matthew 7:12',
      verse: 'Therefore all things whatsoever ye would that men should do to you, do ye even so to them...',
      reflection: 'Treat every golfer, official, and staff member with the respect you would want in return.',
    ),
    WordOfTheDay(
      reference: '2 Timothy 1:7',
      verse: 'For God hath not given us the spirit of fear; but of power, and of love, and of a sound mind.',
      reflection: 'Let love and clear judgement guide your response when pressure rises.',
    ),
    WordOfTheDay(
      reference: 'Psalm 90:17',
      verse: 'And let the beauty of the LORD our God be upon us: and establish thou the work of our hands upon us...',
      reflection: 'Ask that the work you do today leaves something good behind for others.',
    ),
    WordOfTheDay(
      reference: 'Luke 6:31',
      verse: 'And as ye would that men should do to you, do ye also to them likewise.',
      reflection: 'Respect, honesty, and kindness make fellowship stronger than any leaderboard.',
    ),
    WordOfTheDay(
      reference: 'Isaiah 40:31',
      verse: 'But they that wait upon the LORD shall renew their strength; they shall mount up with wings as eagles...',
      reflection: 'Rest is not failure. Give yourself time to recover, learn, and return with renewed strength.',
    ),
    WordOfTheDay(
      reference: '1 Thessalonians 5:11',
      verse: 'Wherefore comfort yourselves together, and edify one another...',
      reflection: 'Look for one person you can build up today with a sincere word of encouragement.',
    ),
    WordOfTheDay(
      reference: 'Psalm 16:8',
      verse: 'I have set the LORD always before me: because he is at my right hand, I shall not be moved.',
      reflection: 'Keep your values in view, especially when competition or disappointment tests them.',
    ),
  ];

  static WordOfTheDay forDate(DateTime date) {
    final dayIndex = DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(date.year, 1, 1))
        .inDays;
    return _readings[dayIndex % _readings.length];
  }
}
