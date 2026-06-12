import '../models/opinion.dart';
import '../models/argument.dart';
import '../models/zero.dart';
import '../models/user_profile.dart';
import '../models/live_room.dart';

/// Realistic mock data for development without a backend
class MockData {
  MockData._();

  // ─── Zeroes ───
  static const List<Zero> zeroes = [
    Zero(id: 'z1', name: '0technology', displayName: 'Technology', description: 'Discuss the future of tech, AI, and innovation.', opinionsCount: 12450, membersCount: 34200, isJoined: true),
    Zero(id: 'z2', name: '0startup', displayName: 'Startup', description: 'Founders, funding, and building from zero.', opinionsCount: 8320, membersCount: 19500, isJoined: true),
    Zero(id: 'z3', name: '0science', displayName: 'Science', description: 'Evidence-based discussion on scientific topics.', opinionsCount: 6100, membersCount: 15800, isJoined: false),
    Zero(id: 'z4', name: '0gaming', displayName: 'Gaming', description: 'Game design, esports, and industry trends.', opinionsCount: 9870, membersCount: 28100, isJoined: false),
    Zero(id: 'z5', name: '0sports', displayName: 'Sports', description: 'Sports analysis, predictions, and debates.', opinionsCount: 7430, membersCount: 22600, isJoined: true),
    Zero(id: 'z6', name: '0business', displayName: 'Business', description: 'Strategy, markets, and corporate leadership.', opinionsCount: 5670, membersCount: 13400, isJoined: false),
    Zero(id: 'z7', name: '0politics', displayName: 'Politics', description: 'Policy, governance, and political philosophy.', opinionsCount: 11200, membersCount: 31000, isJoined: false),
    Zero(id: 'z8', name: '0philosophy', displayName: 'Philosophy', description: 'Ethics, logic, and existential questions.', opinionsCount: 3450, membersCount: 8900, isJoined: false),
    Zero(id: 'z9', name: '0education', displayName: 'Education', description: 'Teaching methods, curriculum, and learning.', opinionsCount: 4210, membersCount: 11200, isJoined: false),
    Zero(id: 'z10', name: '0ai', displayName: 'AI', description: 'Artificial intelligence, ML, and automation.', opinionsCount: 15300, membersCount: 42000, isJoined: true),
  ];

  // ─── Opinions ───
  static final List<Opinion> opinions = [
    Opinion(
      id: 'op1',
      title: 'AI will replace most junior developers within ten years',
      content: 'The pace of AI code generation is accelerating faster than most people realize. Tools like Copilot are already writing production-grade code. Within a decade, the entry-level software engineering role as we know it will fundamentally change or disappear entirely.',
      authorId: 'u1',
      authorUsername: 'logicwave',
      zeroes: ['0technology', '0ai'],
      supportCount: 342,
      opposeCount: 287,
      questionCount: 56,
      isCooking: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Opinion(
      id: 'op2',
      title: 'Remote work is making us worse communicators',
      content: 'We traded watercooler conversations for Slack threads. We replaced spontaneous brainstorming with scheduled Zoom calls. The result? A generation of professionals who can write a perfect email but struggle with real-time dialogue.',
      authorId: 'u2',
      authorUsername: 'clearview',
      zeroes: ['0business', '0startup'],
      supportCount: 198,
      opposeCount: 156,
      questionCount: 43,
      isCooking: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    Opinion(
      id: 'op3',
      title: 'College degrees are becoming participation trophies',
      content: 'When everyone has a degree, nobody does. The real signal of competence is shifting to portfolio work, certifications, and demonstrated ability. Universities are selling prestige, not preparation.',
      authorId: 'u3',
      authorUsername: 'groundzero',
      zeroes: ['0education'],
      supportCount: 421,
      opposeCount: 389,
      questionCount: 78,
      isCooking: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Opinion(
      id: 'op4',
      title: 'Most startup founders are just cosplaying as entrepreneurs',
      content: 'Building a landing page and calling yourself a founder is not entrepreneurship. Real builders ship products, face rejection, and solve actual problems. The startup ecosystem has become a performance.',
      authorId: 'u4',
      authorUsername: 'anonymous',
      isAnonymous: true,
      zeroes: ['0startup', '0business'],
      supportCount: 567,
      opposeCount: 234,
      questionCount: 89,
      isCooking: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Opinion(
      id: 'op5',
      title: 'Social media algorithms are the greatest threat to critical thinking',
      content: 'Every scroll trains you to accept information passively. Every like reinforces your existing beliefs. We are not using these platforms — they are using us. The algorithm is not neutral; it optimizes for engagement, not truth.',
      authorId: 'u5',
      authorUsername: 'mindfield',
      zeroes: ['0technology', '0philosophy'],
      supportCount: 789,
      opposeCount: 123,
      questionCount: 45,
      isCooking: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Opinion(
      id: 'op6',
      title: 'Esports will surpass traditional sports viewership by 2030',
      content: 'Gen Z and Gen Alpha are growing up watching streamers, not athletes. The infrastructure, sponsorships, and audience are all trending in one direction. Traditional sports leagues are already scrambling to adapt.',
      authorId: 'u6',
      authorUsername: 'pixelshift',
      zeroes: ['0gaming', '0sports'],
      supportCount: 234,
      opposeCount: 456,
      questionCount: 67,
      isCooking: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Opinion(
      id: 'op7',
      title: 'Open source software is being exploited by corporations',
      content: 'Billion-dollar companies build their entire stack on free software maintained by unpaid developers. The sustainability model is broken. We celebrate open source while watching maintainers burn out.',
      authorId: 'u1',
      authorUsername: 'logicwave',
      zeroes: ['0technology', '0business'],
      supportCount: 345,
      opposeCount: 178,
      questionCount: 34,
      isCooking: false,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  // ─── Arguments ───
  static final List<Argument> sampleArguments = [
    Argument(
      id: 'a1',
      opinionId: 'op1',
      authorId: 'u2',
      authorUsername: 'clearview',
      type: ArgumentType.support,
      content: 'Already happening. My company replaced two junior developer positions with AI tooling last quarter. The remaining devs now review AI-generated code instead of writing it from scratch.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Argument(
      id: 'a2',
      opinionId: 'op1',
      authorId: 'u3',
      authorUsername: 'groundzero',
      type: ArgumentType.oppose,
      content: 'AI generates code, but it does not understand systems. Junior developers learn architecture, debugging, and team dynamics — skills that AI cannot replicate. The role will evolve, not vanish.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
    ),
    Argument(
      id: 'a3',
      opinionId: 'op1',
      authorId: 'u5',
      authorUsername: 'mindfield',
      type: ArgumentType.question,
      content: 'What specific evidence do we have for the "ten years" timeline? Predictions about technology replacing jobs have historically overestimated speed and underestimated adaptation.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    ),
    Argument(
      id: 'a4',
      opinionId: 'op1',
      authorId: 'u4',
      authorUsername: 'anonymous',
      isAnonymous: true,
      type: ArgumentType.support,
      content: 'The economics are clear. Why would a startup pay a junior developer when they can give a senior developer AI tools that 10x their output? The math does not work in favor of entry-level hires.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Argument(
      id: 'a5',
      opinionId: 'op1',
      authorId: 'u6',
      authorUsername: 'pixelshift',
      type: ArgumentType.oppose,
      content: 'People said the same thing about Stack Overflow, then about no-code tools. Every generation of technology creates new categories of work. The junior developer of 2035 will do things we cannot imagine today.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
  ];

  // ─── Live Rooms ───
  static final List<LiveRoom> liveRooms = [
    LiveRoom(id: 'lr1', title: 'AI vs Human Creativity', hostId: 'u1', hostUsername: 'logicwave', participantsCount: 23, createdAt: DateTime.now().subtract(const Duration(minutes: 45))),
    LiveRoom(id: 'lr2', title: 'Future of Education', hostId: 'u3', hostUsername: 'groundzero', participantsCount: 15, createdAt: DateTime.now().subtract(const Duration(hours: 1))),
    LiveRoom(id: 'lr3', title: 'Remote Work Debate', hostId: 'u2', hostUsername: 'clearview', participantsCount: 31, createdAt: DateTime.now().subtract(const Duration(minutes: 20))),
    LiveRoom(id: 'lr4', title: 'Should Coding Be Taught in Schools?', hostId: 'u5', hostUsername: 'mindfield', participantsCount: 8, createdAt: DateTime.now().subtract(const Duration(hours: 2))),
    LiveRoom(id: 'lr5', title: 'Startup Culture Is Toxic', hostId: 'u4', hostUsername: 'anonymous', participantsCount: 42, createdAt: DateTime.now().subtract(const Duration(minutes: 10))),
  ];

  // ─── Chat Messages ───
  static final List<ChatMessage> sampleMessages = [
    ChatMessage(id: 'm1', roomId: 'lr1', senderId: 'u1', senderUsername: 'logicwave', content: 'Welcome everyone. Today we are discussing whether AI can truly be creative or if it is just pattern matching at scale.', timestamp: DateTime.now().subtract(const Duration(minutes: 40))),
    ChatMessage(id: 'm2', roomId: 'lr1', senderId: 'u2', senderUsername: 'clearview', content: 'I think the distinction between pattern matching and creativity is less clear than people assume. Human creativity is also built on patterns.', timestamp: DateTime.now().subtract(const Duration(minutes: 38))),
    ChatMessage(id: 'm3', roomId: 'lr1', senderId: 'u3', senderUsername: 'groundzero', content: 'But humans have intention and meaning behind their work. AI generates outputs without understanding.', timestamp: DateTime.now().subtract(const Duration(minutes: 35))),
    ChatMessage(id: 'm4', roomId: 'lr1', senderId: 'u5', senderUsername: 'mindfield', content: 'Does intention matter if the output is indistinguishable? This is essentially the Chinese Room argument applied to art.', timestamp: DateTime.now().subtract(const Duration(minutes: 33))),
    ChatMessage(id: 'm5', roomId: 'lr1', senderId: 'u6', senderUsername: 'pixelshift', content: 'I have been using AI tools for game design and honestly, the results feel more like collaboration than replacement. It is a tool, not an artist.', timestamp: DateTime.now().subtract(const Duration(minutes: 30))),
  ];

  // ─── User Profile ───
  static const UserProfile currentUser = UserProfile(
    id: 'u1',
    username: 'logicwave',
    displayName: 'Logic Wave',
    avatarSeed: 42,
    reputationScore: 1240,
    opinionsCount: 23,
    debatesJoined: 87,
    joinedZeroes: ['0technology', '0ai', '0startup', '0sports'],
  );
}
