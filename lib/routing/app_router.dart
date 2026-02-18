import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:hortus_app/features/auth/views/auth_gate.dart';
import 'package:hortus_app/features/auth/views/forgot_password_page.dart';
import 'package:hortus_app/features/auth/views/login_page.dart';
import 'package:hortus_app/features/auth/views/register_page.dart';
import 'package:hortus_app/features/gardens/views/add_garden_page.dart';
import 'package:hortus_app/features/gardens/views/garden_map_page.dart';
import 'package:hortus_app/features/gardens/views/gardens_page.dart';
import 'package:hortus_app/features/home/views/home_page.dart';
import 'package:hortus_app/routing/router_notifier.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);

  return GoRouter(
    refreshListenable: authNotifier,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AuthGate()),
      GoRoute(path: '/login', builder: (_, __) => LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => RegisterPage()),
      GoRoute(path: '/forgot', builder: (_, __) => ForgotPasswordPage()),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      GoRoute(path: '/gardens', builder: (_, __) => const GardensPage()),
      GoRoute(path: '/add-garden', builder: (_, __) => const AddGardenPage()),
      GoRoute(
        path: '/garden/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GardenMapPage(gardenId: id);
        },
      ),
    ],
  );
});
