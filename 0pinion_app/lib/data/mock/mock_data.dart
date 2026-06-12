import '../models/opinion.dart';
import '../models/argument.dart';
import '../models/zero.dart';
import '../models/user_profile.dart';
import '../models/live_room.dart';

/// Clean mock data for development
class MockData {
  MockData._();

  // ─── Zeroes ───
  static const List<Zero> zeroes = [
    Zero(id: 'z1', name: '0technology', displayName: 'Technology', description: 'Discuss the future of tech, AI, and innovation.', opinionsCount: 0, membersCount: 0, isJoined: false),
    Zero(id: 'z2', name: '0startup', displayName: 'Startup', description: 'Founders, funding, and building from zero.', opinionsCount: 0, membersCount: 0, isJoined: false),
    Zero(id: 'z3', name: '0science', displayName: 'Science', description: 'Evidence-based discussion on scientific topics.', opinionsCount: 0, membersCount: 0, isJoined: false),
    Zero(id: 'z4', name: '0gaming', displayName: 'Gaming', description: 'Game design, esports, and industry trends.', opinionsCount: 0, membersCount: 0, isJoined: false),
    Zero(id: 'z5', name: '0sports', displayName: 'Sports', description: 'Sports analysis, predictions, and debates.', opinionsCount: 0, membersCount: 0, isJoined: false),
    Zero(id: 'z6', name: '0business', displayName: 'Business', description: 'Strategy, markets, and corporate leadership.', opinionsCount: 0, membersCount: 0, isJoined: false),
    Zero(id: 'z7', name: '0politics', displayName: 'Politics', description: 'Policy, governance, and political philosophy.', opinionsCount: 0, membersCount: 0, isJoined: false),
    Zero(id: 'z8', name: '0philosophy', displayName: 'Philosophy', description: 'Ethics, logic, and existential questions.', opinionsCount: 0, membersCount: 0, isJoined: false),
    Zero(id: 'z9', name: '0education', displayName: 'Education', description: 'Teaching methods, curriculum, and learning.', opinionsCount: 0, membersCount: 0, isJoined: false),
    Zero(id: 'z10', name: '0ai', displayName: 'AI', description: 'Artificial intelligence, ML, and automation.', opinionsCount: 0, membersCount: 0, isJoined: false),
  ];

  // ─── Opinions ───
  static final List<Opinion> opinions = [];

  // ─── Arguments ───
  static final List<Argument> sampleArguments = [];

  // ─── Live Rooms ───
  static final List<LiveRoom> liveRooms = [];

  // ─── Chat Messages ───
  static final List<ChatMessage> sampleMessages = [];

  // ─── User Profile ───
  static const UserProfile currentUser = UserProfile(
    id: 'u1',
    username: 'logicwave',
    displayName: 'Logic Wave',
    avatarSeed: 42,
    reputationScore: 0,
    opinionsCount: 0,
    debatesJoined: 0,
    joinedZeroes: [],
  );
}
