import 'package:go_router/go_router.dart';
import 'package:sofia/screens/admin/groups_screen.dart';
import 'package:sofia/screens/admin/parents_screen.dart';
import 'package:sofia/screens/parent/parent_home.dart';
import 'package:sofia/screens/teacher/teacher_home.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import 'package:flutter/material.dart';
import '../screens/home_screens.dart';
import '../screens/admin/teachers_screen.dart';

/// Mapea cada rol a su pantalla de inicio.
String homePathForRole(String role) {
  switch (role) {
    case 'ADMIN':
      return '/admin';
    case 'PROFESOR':
      return '/profesor';
    case 'PADRE':
      return '/padre';
    default:
      return '/login';
  }
}

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final atLogin = state.matchedLocation == '/login';

      if (!loggedIn) return atLogin ? null : '/login';

      final home = homePathForRole(auth.user!.role);
      if (atLogin || state.matchedLocation == '/') return home;

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SizedBox.shrink()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminHome()),
      GoRoute(path: '/profesor', builder: (_, __) => const TeacherHome()),
      GoRoute(path: '/padre', builder: (_, __) => const ParentHome()),
      GoRoute(path: '/admin/groups', builder: (_, __) => const GroupsScreen()),
      GoRoute(path: '/admin/teachers', builder: (_,__) => const TeachersScreen()),
      GoRoute(path: '/admin/parents', builder: (_, __) => const ParentsScreen()),
    ],
  );
}