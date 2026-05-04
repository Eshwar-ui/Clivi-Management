import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Auth guard redirect logic
String? authGuard(BuildContext context, GoRouterState state, WidgetRef ref) {
  final authState = ref.read(authProvider);
  final isAuthenticated = authState.isAuthenticated;
  final isLoginRoute = state.matchedLocation == '/login';

  // If not authenticated and trying to access protected route
  if (!isAuthenticated && !isLoginRoute) {
    return '/login';
  }

  // If authenticated and trying to access login route
  if (isAuthenticated && isLoginRoute) {
    return _getRoleBasedRoute(authState.role);
  }

  // No redirect needed
  return null;
}

/// Role-based redirect logic
String? roleGuard(
  BuildContext context,
  GoRouterState state,
  WidgetRef ref,
  List<UserRole> allowedRoles,
) {
  final authState = ref.read(authProvider);
  final userRole = authState.role;

  // If not authenticated, redirect to login
  if (!authState.isAuthenticated) {
    return '/login';
  }

  // If user role not loaded yet, stay on current route
  if (userRole == null) {
    return null;
  }

  // If user role is not in allowed roles, redirect to their dashboard
  if (!allowedRoles.contains(userRole)) {
    return _getRoleBasedRoute(userRole);
  }

  // No redirect needed
  return null;
}

/// Get dashboard route based on user role
String _getRoleBasedRoute(UserRole? role) {
  switch (role) {
    case UserRole.superAdmin:
      return '/super-admin/dashboard';
    case UserRole.admin:
      return '/admin/dashboard';
    case UserRole.siteManager:
      return '/site-manager/dashboard';
    default:
      return '/login';
  }
}

/// Check if user has permission for a role
bool hasRole(WidgetRef ref, UserRole requiredRole) {
  final userRole = ref.watch(userRoleProvider);
  return userRole == requiredRole;
}

/// Check if user has any of the specified roles
bool hasAnyRole(WidgetRef ref, List<UserRole> allowedRoles) {
  final userRole = ref.watch(userRoleProvider);
  return userRole != null && allowedRoles.contains(userRole);
}
