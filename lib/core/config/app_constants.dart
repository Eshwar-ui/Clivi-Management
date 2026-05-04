/// Application constants
/// Contains all static configuration values used throughout the app
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // ============================================================
  // APP INFO
  // ============================================================

  /// Application name
  static const String appName = 'Civil Management';

  /// Application version
  static const String appVersion = '1.0.0';

  /// Application build number
  static const int buildNumber = 1;

  // ============================================================
  // DATABASE TABLES
  // ============================================================

  /// User profiles table
  static const String tableUserProfiles = 'user_profiles';

  /// Projects table
  static const String tableProjects = 'projects';

  /// Project assignments table
  static const String tableProjectAssignments = 'project_assignments';

  /// Stock items table
  static const String tableStockItems = 'stock_items';

  /// Stock transactions table
  static const String tableStockTransactions = 'stock_transactions';

  /// Labour records table
  static const String tableLabourRecords = 'labour_records';

  /// Bills table
  static const String tableBills = 'bills';

  /// Blueprints table
  static const String tableBlueprints = 'blueprints';

  /// Machinery table
  static const String tableMachinery = 'machinery';

  /// Daily reports table
  static const String tableDailyReports = 'daily_reports';

  // ============================================================
  // STORAGE BUCKETS
  // ============================================================

  /// Avatars storage bucket
  static const String bucketAvatars = 'avatars';

  /// Blueprints storage bucket
  static const String bucketBlueprints = 'blueprints';

  /// Bills storage bucket
  static const String bucketBills = 'bills';

  /// Project images storage bucket
  static const String bucketProjectImages = 'project-images';

  // ============================================================
  // USER ROLES
  // ============================================================

  /// Super Admin role
  static const String roleSuperAdmin = 'super_admin';

  /// Admin role
  static const String roleAdmin = 'admin';

  /// Site Manager role
  static const String roleSiteManager = 'site_manager';

  // ============================================================
  // PROJECT STATUS
  // ============================================================

  /// Project status: Active
  static const String statusActive = 'active';

  /// Project status: Pending
  static const String statusPending = 'pending';

  /// Project status: Completed
  static const String statusCompleted = 'completed';

  /// Project status: On Hold
  static const String statusOnHold = 'on_hold';

  /// Project status: Cancelled
  static const String statusCancelled = 'cancelled';

  // ============================================================
  // PAGINATION
  // ============================================================

  /// Default page size for pagination
  static const int defaultPageSize = 20;

  /// Maximum page size allowed
  static const int maxPageSize = 100;

  // ============================================================
  // VALIDATION
  // ============================================================

  /// Minimum password length
  static const int minPasswordLength = 8;

  /// Maximum password length
  static const int maxPasswordLength = 128;

  /// Minimum name length
  static const int minNameLength = 2;

  /// Maximum name length
  static const int maxNameLength = 100;

  /// Maximum file size in bytes (10MB)
  static const int maxFileSize = 10 * 1024 * 1024;

  /// Allowed image extensions
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  /// Allowed document extensions
  static const List<String> allowedDocumentExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
  ];

  /// Allowed blueprint extensions
  static const List<String> allowedBlueprintExtensions = [
    'pdf',
    'dwg',
    'dxf',
    'jpg',
    'jpeg',
    'png',
  ];

  // ============================================================
  // TIMEOUTS
  // ============================================================

  /// API request timeout in seconds
  static const int apiTimeout = 30;

  /// File upload timeout in seconds
  static const int uploadTimeout = 120;

  /// Session refresh interval in minutes
  static const int sessionRefreshInterval = 55;

  // ============================================================
  // UI CONSTANTS
  // ============================================================

  /// Default border radius
  static const double borderRadius = 12.0;

  /// Small border radius
  static const double borderRadiusSmall = 8.0;

  /// Large border radius
  static const double borderRadiusLarge = 16.0;

  /// Default padding
  static const double padding = 16.0;

  /// Small padding
  static const double paddingSmall = 8.0;

  /// Large padding
  static const double paddingLarge = 24.0;

  /// Default spacing
  static const double spacing = 16.0;

  /// Small spacing
  static const double spacingSmall = 8.0;

  /// Large spacing
  static const double spacingLarge = 24.0;

  /// Default elevation
  static const double elevation = 2.0;

  /// Card elevation
  static const double cardElevation = 1.0;

  /// AppBar height
  static const double appBarHeight = 56.0;

  /// Bottom navigation bar height
  static const double bottomNavHeight = 80.0;

  // ============================================================
  // ANIMATION DURATIONS
  // ============================================================

  /// Short animation duration in milliseconds
  static const int animationShort = 200;

  /// Medium animation duration in milliseconds
  static const int animationMedium = 300;

  /// Long animation duration in milliseconds
  static const int animationLong = 500;

  // ============================================================
  // DATE FORMATS
  // ============================================================

  /// Date format: dd/MM/yyyy
  static const String dateFormat = 'dd/MM/yyyy';

  /// Time format: HH:mm
  static const String timeFormat = 'HH:mm';

  /// DateTime format: dd/MM/yyyy HH:mm
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  /// API date format: yyyy-MM-dd
  static const String apiDateFormat = 'yyyy-MM-dd';

  /// Display date format: MMM dd, yyyy
  static const String displayDateFormat = 'MMM dd, yyyy';

  // ============================================================
  // CURRENCY
  // ============================================================

  /// Default currency symbol
  static const String currencySymbol = '₹';

  /// Default currency code
  static const String currencyCode = 'INR';

  /// Default locale for formatting
  static const String defaultLocale = 'en_IN';
}
