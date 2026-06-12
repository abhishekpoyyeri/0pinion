import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/sign_up_screen.dart';
import '../../features/auth/screens/username_setup_screen.dart';
import '../../features/onboarding/screens/select_zeroes_screen.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/feed/screens/home_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/opinion/screens/create_opinion_screen.dart';
import '../../features/live/screens/live_rooms_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/opinion/screens/opinion_detail_screen.dart';
import '../../features/opinion/screens/write_argument_screen.dart';
import '../../features/search/screens/browse_zeroes_screen.dart';
import '../../features/live/screens/live_room_chat_screen.dart';
import '../../features/report/screens/report_screen.dart';
import '../widgets/bottom_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // ─── Auth & Onboarding ───
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/username-setup',
      builder: (context, state) => const UsernameSetupScreen(),
    ),
    GoRoute(
      path: '/select-zeroes',
      builder: (context, state) => const SelectZeroesScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),

    // ─── Main App Shell (with bottom navigation) ───
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => BottomNavShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SearchScreen(),
          ),
        ),
        GoRoute(
          path: '/create',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CreateOpinionScreen(),
          ),
        ),
        GoRoute(
          path: '/live',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LiveRoomsScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),

    // ─── Detail Screens (push on top of shell) ───
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/opinion/:id',
      builder: (context, state) => OpinionDetailScreen(
        opinionId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/argument/:opinionId',
      builder: (context, state) => WriteArgumentScreen(
        opinionId: state.pathParameters['opinionId']!,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/zeroes',
      builder: (context, state) => const BrowseZeroesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/live/:roomId',
      builder: (context, state) => LiveRoomChatScreen(
        roomId: state.pathParameters['roomId']!,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/report/:contentType/:contentId',
      builder: (context, state) => ReportScreen(
        contentType: state.pathParameters['contentType']!,
        contentId: state.pathParameters['contentId']!,
      ),
    ),
  ],
);
