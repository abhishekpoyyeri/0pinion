import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/sign_up_screen.dart';
import '../../features/auth/screens/username_setup_screen.dart';
import '../../features/onboarding/screens/select_zeroes_screen.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/community/screens/community_detail_screen.dart';
import '../../features/community/screens/create_community_screen.dart';
import '../../features/community/screens/create_community_post_screen.dart';
import '../../features/opinion/screens/opinion_detail_screen.dart';
import '../../features/opinion/screens/write_argument_screen.dart';
import '../../features/search/screens/browse_zeroes_screen.dart';
import '../../features/live/screens/live_room_chat_screen.dart';
import '../../features/report/screens/report_screen.dart';
import '../widgets/main_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/supabase_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Define keys inside the provider so they are recreated if the router ever rebuilds,
  // preventing the "Multiple widgets used the same GlobalKey" crash.
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  // Only rebuild the router when the user actually logs in or out, 
  // NOT on every minor background token refresh.
  final isAuthenticated = ref.watch(authStateProvider.select((state) => state.value?.session != null));

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isGoingToAuth = state.matchedLocation == '/splash' || 
                            state.matchedLocation == '/signup' ||
                            state.matchedLocation == '/login';

      if (!isAuthenticated) {
        if (!isGoingToAuth &&
            state.matchedLocation != '/username-setup' &&
            state.matchedLocation != '/select-zeroes' &&
            state.matchedLocation != '/welcome') {
          return '/splash';
        }
      } else {
        if (isGoingToAuth) {
          return '/home';
        }
      }
      return null;
    },
    routes: [
      // ─── Auth & Onboarding ───
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(isLogin: false),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const SignUpScreen(isLogin: true),
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

      // ─── Main App Shell (with bottom navigation and PageView) ───
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScreen(),
      ),

      // ─── Detail Screens (push on top of shell) ───
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/opinion/:id',
        builder: (context, state) => OpinionDetailScreen(
          opinionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/argument/:opinionId',
        builder: (context, state) => WriteArgumentScreen(
          opinionId: state.pathParameters['opinionId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/zeroes',
        builder: (context, state) => const BrowseZeroesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/live/:roomId',
        builder: (context, state) => LiveRoomChatScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/report/:contentType/:contentId',
        builder: (context, state) => ReportScreen(
          contentType: state.pathParameters['contentType']!,
          contentId: state.pathParameters['contentId']!,
        ),
      ),

      // ─── Community Detail Routes ───
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/community/create',
        builder: (context, state) => const CreateCommunityScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/community/:id',
        builder: (context, state) => CommunityDetailScreen(
          communityId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/community/:id/post',
        builder: (context, state) => CreateCommunityPostScreen(
          communityId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
