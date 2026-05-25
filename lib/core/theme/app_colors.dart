import 'package:flutter/material.dart';

/// Application color palette
/// Primary: Blue (#2196F3) - Material Design Blue
/// Secondary: Amber (#F59E0B) - Warm, sophisticated amber
class AppColors {
  AppColors._();

  // Primary Colors - Blue (#2196F3)
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryVariant = Color(0xFF1565C0);

  // Secondary Colors - Amber
  static const Color secondary = Color(0xFFF59E0B);
  static const Color secondaryDark = Color(0xFFD97706);
  static const Color secondaryLight = Color(0xFFFBBF24);
  static const Color secondaryVariant = Color(0xFFB45309);

  // Accent Colors - Cyan
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentDark = Color(0xFF0891B2);
  static const Color accentLight = Color(0xFF22D3EE);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF6EE7B7);
  static const Color successDark = Color(0xFF059669);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFCA5A5);
  static const Color errorDark = Color(0xFFDC2626);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFCD34D);
  static const Color warningDark = Color(0xFFD97706);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF93C5FD);
  static const Color infoDark = Color(0xFF2563EB);

  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color scaffoldBackground = Color(0xFFF8FAFC);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF000000);

  // Border Colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFFE2E8F0);

  // Shadow
  static const Color shadow = Color(0x12000000);
  static const Color shadowLight = Color(0x08000000);
  static const Color shadowDark = Color(0x24000000);

  // Role-based Colors
  static const Color superAdmin = Color(0xFF8B5CF6);
  static const Color admin = Color(0xFF2196F3);
  static const Color siteManager = Color(0xFF10B981);

  // Project Status Colors
  static const Color statusActive = Color(0xFF10B981);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusCompleted = Color(0xFF3B82F6);
  static const Color statusOnHold = Color(0xFF94A3B8);
  static const Color statusCancelled = Color(0xFFEF4444);

  // Sidebar Colors
  static const Color sidebarBackground = Color(0xFF0F1729);
  static const Color sidebarSurface = Color(0xFF1E293B);
  static const Color sidebarTextPrimary = Color(0xFFE2E8F0);
  static const Color sidebarTextSecondary = Color(0xFF94A3B8);
  static const Color sidebarSelectedBg = Color(0x1AFFFFFF);
  static const Color sidebarHoverBg = Color(0x0DFFFFFF);
  static const Color sidebarAccent = Color(0xFF64B5F6);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF2196F3),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFF1976D2),
  ];

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Layered shadow helpers (cached as static const lists)
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x06000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x12000000), blurRadius: 24, offset: Offset(0, 12)),
  ];
}
