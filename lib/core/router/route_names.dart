/// Route names and paths for the application
/// Centralized routing configuration for type-safe navigation
class RouteNames {
  // Private constructor to prevent instantiation
  RouteNames._();

  // ============================================================
  // SPLASH & AUTH ROUTES
  // ============================================================

  /// Splash screen route
  static const String splash = 'splash';
  static const String splashPath = '/splash';

  /// Login screen route
  static const String login = 'login';
  static const String loginPath = '/login';

  /// Signup screen route
  static const String signup = 'signup';
  static const String signupPath = '/signup';

  /// Forgot password screen route
  static const String forgotPassword = 'forgot-password';
  static const String forgotPasswordPath = '/forgot-password';

  /// Reset password screen route
  static const String resetPassword = 'reset-password';
  static const String resetPasswordPath = '/reset-password';

  // ============================================================
  // DASHBOARD ROUTES
  // ============================================================

  /// Super Admin dashboard route
  static const String superAdminDashboard = 'super-admin-dashboard';
  static const String superAdminDashboardPath = '/super-admin/dashboard';

  /// Admin dashboard route
  static const String adminDashboard = 'admin-dashboard';
  static const String adminDashboardPath = '/admin/dashboard';

  /// Site Manager dashboard route
  static const String siteManagerDashboard = 'site-manager-dashboard';
  static const String siteManagerDashboardPath = '/site-manager/dashboard';

  // ============================================================
  // PROJECT ROUTES
  // ============================================================

  /// Projects list route
  static const String projects = 'projects';
  static const String projectsPath = '/projects';

  /// Create project route
  static const String createProject = 'create-project';
  static const String createProjectPath = '/projects/create';

  /// Project detail route (with parameter)
  static const String projectDetail = 'project-detail';
  static const String projectDetailPath = '/projects/:id';

  /// Edit project route (with parameter)
  static const String editProject = 'edit-project';
  static const String editProjectPath = '/projects/:id/edit';

  // ============================================================
  // BLUEPRINT ROUTES
  // ============================================================

  /// Project blueprints route
  static const String projectBlueprints = 'project-blueprints';
  static const String projectBlueprintsPath = '/projects/:id/blueprints';

  /// Blueprint files route
  static const String blueprintFiles = 'project-blueprint-files';
  static const String blueprintFilesPath =
      '/projects/:id/blueprints/:folderName';

  /// Blueprint viewer route
  static const String blueprintViewer = 'project-blueprint-viewer';
  static const String blueprintViewerPath =
      '/projects/:id/blueprints/:folderName/:fileId';

  // ============================================================
  // STOCK ROUTES
  // ============================================================

  /// Stock list route
  static const String stock = 'stock';
  static const String stockPath = '/stock';

  /// Add stock item route
  static const String addStock = 'add-stock';
  static const String addStockPath = '/stock/add';

  /// Stock detail route
  static const String stockDetail = 'stock-detail';
  static const String stockDetailPath = '/stock/:id';

  /// Stock transactions route
  static const String stockTransactions = 'stock-transactions';
  static const String stockTransactionsPath = '/stock/:id/transactions';

  // ============================================================
  // LABOUR ROUTES
  // ============================================================

  /// Labour list route
  static const String labour = 'labour';
  static const String labourPath = '/labour';

  /// Add labour record route
  static const String addLabour = 'add-labour';
  static const String addLabourPath = '/labour/add';

  /// Labour detail route
  static const String labourDetail = 'labour-detail';
  static const String labourDetailPath = '/labour/:id';

  /// Labour attendance route
  static const String labourAttendance = 'labour-attendance';
  static const String labourAttendancePath = '/labour/attendance';

  // ============================================================
  // BILLS ROUTES
  // ============================================================

  /// Bills list route
  static const String bills = 'bills';
  static const String billsPath = '/bills';

  /// Add bill route
  static const String addBill = 'add-bill';
  static const String addBillPath = '/bills/add';

  /// Bill detail route
  static const String billDetail = 'bill-detail';
  static const String billDetailPath = '/bills/:id';

  // ============================================================
  // MACHINERY ROUTES
  // ============================================================

  /// Machinery list route
  static const String machinery = 'machinery';
  static const String machineryPath = '/machinery';

  /// Add machinery route
  static const String addMachinery = 'add-machinery';
  static const String addMachineryPath = '/machinery/add';

  /// Machinery detail route
  static const String machineryDetail = 'machinery-detail';
  static const String machineryDetailPath = '/machinery/:id';

  // ============================================================
  // REPORTS ROUTES
  // ============================================================

  /// Reports list route
  static const String reports = 'reports';
  static const String reportsPath = '/reports';

  /// Daily report route
  static const String dailyReport = 'daily-report';
  static const String dailyReportPath = '/reports/daily';

  /// Generate report route
  static const String generateReport = 'generate-report';
  static const String generateReportPath = '/reports/generate';

  // ============================================================
  // USER MANAGEMENT ROUTES
  // ============================================================

  /// Users list route
  static const String users = 'users';
  static const String usersPath = '/users';

  /// User detail route
  static const String userDetail = 'user-detail';
  static const String userDetailPath = '/users/:id';

  /// Invite user route
  static const String inviteUser = 'invite-user';
  static const String inviteUserPath = '/users/invite';

  // ============================================================
  // SETTINGS ROUTES
  // ============================================================

  /// Settings route
  static const String settings = 'settings';
  static const String settingsPath = '/settings';

  /// Profile settings route
  static const String profile = 'profile';
  static const String profilePath = '/settings/profile';

  /// Notifications settings route
  static const String notifications = 'notifications';
  static const String notificationsPath = '/settings/notifications';

  /// Change password route
  static const String changePassword = 'change-password';
  static const String changePasswordPath = '/settings/change-password';

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Get project detail path with ID
  static String getProjectDetailPath(String projectId) =>
      '/projects/$projectId';

  /// Get project edit path with ID
  static String getEditProjectPath(String projectId) =>
      '/projects/$projectId/edit';

  /// Get project blueprints path with ID
  static String getProjectBlueprintsPath(String projectId) =>
      '/projects/$projectId/blueprints';

  /// Get blueprint files path with project ID and folder name
  static String getBlueprintFilesPath(String projectId, String folderName) =>
      '/projects/$projectId/blueprints/$folderName';

  /// Get blueprint viewer path
  static String getBlueprintViewerPath(
    String projectId,
    String folderName,
    String fileId,
  ) => '/projects/$projectId/blueprints/$folderName/$fileId';

  /// Get stock detail path with ID
  static String getStockDetailPath(String stockId) => '/stock/$stockId';

  /// Get labour detail path with ID
  static String getLabourDetailPath(String labourId) => '/labour/$labourId';

  /// Get bill detail path with ID
  static String getBillDetailPath(String billId) => '/bills/$billId';

  /// Get machinery detail path with ID
  static String getMachineryDetailPath(String machineryId) =>
      '/machinery/$machineryId';

  /// Get user detail path with ID
  static String getUserDetailPath(String userId) => '/users/$userId';

  // ============================================================
  // ROUTE LISTS
  // ============================================================

  /// Public routes that don't require authentication
  static const List<String> publicRoutes = [
    splashPath,
    loginPath,
    signupPath,
    forgotPasswordPath,
    resetPasswordPath,
  ];

  /// Routes accessible by all authenticated users
  static const List<String> commonRoutes = [
    settingsPath,
    profilePath,
    notificationsPath,
    changePasswordPath,
  ];

  /// Routes accessible only by Super Admin
  static const List<String> superAdminOnlyRoutes = [usersPath, inviteUserPath];

  /// Routes accessible by Admin and Super Admin
  static const List<String> adminRoutes = [
    createProjectPath,
    addStockPath,
    addLabourPath,
    addBillPath,
    addMachineryPath,
  ];

  /// Check if route is public
  static bool isPublicRoute(String path) => publicRoutes.contains(path);

  /// Check if route requires admin privileges
  static bool requiresAdmin(String path) => adminRoutes.contains(path);

  /// Check if route requires super admin privileges
  static bool requiresSuperAdmin(String path) =>
      superAdminOnlyRoutes.contains(path);
}
