import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/navigation/views/main_navigation_view.dart';
import '../../features/auth/services/auth_provider.dart';

// Route names
class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
}

// Helper class to refresh GoRouter when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _subscription;

  GoRouterRefreshStream(Stream stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: GoRouterRefreshStream(ref.watch(currentUserProvider.stream)),
    redirect: (context, state) {
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.value;
      final isLoggedIn = user != null;

      // If user is not logged in and not on login page, redirect to login
      if (!isLoggedIn && state.uri.path != AppRoutes.login) {
        return AppRoutes.login;
      }

      // If user is logged in and on login page, redirect to home
      if (isLoggedIn && state.uri.path == AppRoutes.login) {
        return AppRoutes.home;
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const MainNavigationView(),
      ),
    ],
  );
});