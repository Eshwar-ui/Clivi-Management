import 'package:intl/intl.dart';
import '../config/app_constants.dart';

/// Date formatting utilities
/// Provides consistent date formatting throughout the app
class DateFormatter {
  // Private constructor to prevent instantiation
  DateFormatter._();

  // ============================================================
  // DATE FORMATTERS
  // ============================================================

  /// Standard date format: dd/MM/yyyy
  static final DateFormat _dateFormat = DateFormat(AppConstants.dateFormat);

  /// Time format: HH:mm
  static final DateFormat _timeFormat = DateFormat(AppConstants.timeFormat);

  /// Date and time format: dd/MM/yyyy HH:mm
  static final DateFormat _dateTimeFormat = DateFormat(
    AppConstants.dateTimeFormat,
  );

  /// API date format: yyyy-MM-dd
  static final DateFormat _apiDateFormat = DateFormat(
    AppConstants.apiDateFormat,
  );

  /// Display date format: MMM dd, yyyy
  static final DateFormat _displayDateFormat = DateFormat(
    AppConstants.displayDateFormat,
  );

  /// Day and month format: dd MMM
  static final DateFormat _dayMonthFormat = DateFormat('dd MMM');

  /// Month and year format: MMM yyyy
  static final DateFormat _monthYearFormat = DateFormat('MMM yyyy');

  /// Full date format: EEEE, MMMM dd, yyyy
  static final DateFormat _fullDateFormat = DateFormat('EEEE, MMMM dd, yyyy');



  /// 12-hour time format: hh:mm a
  static final DateFormat _time12HourFormat = DateFormat('hh:mm a');

  // ============================================================
  // FORMAT METHODS
  // ============================================================

  /// Format to standard date (dd/MM/yyyy)
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _dateFormat.format(date);
  }

  /// Format to time (HH:mm)
  static String formatTime(DateTime? date) {
    if (date == null) return '-';
    return _timeFormat.format(date);
  }

  /// Format to 12-hour time (hh:mm AM/PM)
  static String formatTime12Hour(DateTime? date) {
    if (date == null) return '-';
    return _time12HourFormat.format(date);
  }

  /// Format to date and time (dd/MM/yyyy HH:mm)
  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return _dateTimeFormat.format(date);
  }

  /// Format for API (yyyy-MM-dd)
  static String formatForApi(DateTime? date) {
    if (date == null) return '';
    return _apiDateFormat.format(date);
  }

  /// Format for display (MMM dd, yyyy)
  static String formatDisplay(DateTime? date) {
    if (date == null) return '-';
    return _displayDateFormat.format(date);
  }

  /// Format to day and month (dd MMM)
  static String formatDayMonth(DateTime? date) {
    if (date == null) return '-';
    return _dayMonthFormat.format(date);
  }

  /// Format to month and year (MMM yyyy)
  static String formatMonthYear(DateTime? date) {
    if (date == null) return '-';
    return _monthYearFormat.format(date);
  }

  /// Format to full date (EEEE, MMMM dd, yyyy)
  static String formatFullDate(DateTime? date) {
    if (date == null) return '-';
    return _fullDateFormat.format(date);
  }

  // ============================================================
  // PARSE METHODS
  // ============================================================

  /// Parse from standard date format (dd/MM/yyyy)
  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return _dateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse from API format (yyyy-MM-dd)
  static DateTime? parseApiDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return _apiDateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse ISO 8601 date string
  static DateTime? parseIso(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // RELATIVE TIME
  // ============================================================

  /// Format as relative time (e.g., "2 hours ago", "yesterday")
  static String formatRelative(DateTime? date) {
    if (date == null) return '-';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.isNegative) {
      return _formatFuture(difference.abs());
    }

    return _formatPast(difference);
  }

  static String _formatPast(Duration difference) {
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }

    if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }

    if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inHours > 1) {
      return '${difference.inHours} hours ago';
    }

    if (difference.inHours == 1) {
      return '1 hour ago';
    }

    if (difference.inMinutes > 1) {
      return '${difference.inMinutes} minutes ago';
    }

    if (difference.inMinutes == 1) {
      return '1 minute ago';
    }

    return 'Just now';
  }

  static String _formatFuture(Duration difference) {
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? 'In 1 year' : 'In $years years';
    }

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'In 1 month' : 'In $months months';
    }

    if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? 'In 1 week' : 'In $weeks weeks';
    }

    if (difference.inDays > 1) {
      return 'In ${difference.inDays} days';
    }

    if (difference.inDays == 1) {
      return 'Tomorrow';
    }

    if (difference.inHours > 1) {
      return 'In ${difference.inHours} hours';
    }

    if (difference.inHours == 1) {
      return 'In 1 hour';
    }

    if (difference.inMinutes > 1) {
      return 'In ${difference.inMinutes} minutes';
    }

    return 'In a moment';
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Check if date is today
  static bool isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime? date) {
    if (date == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime? date) {
    if (date == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Check if date is in current week
  static bool isThisWeek(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Check if date is in current month
  static bool isThisMonth(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  /// Get number of days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return to.difference(from).inDays;
  }

  /// Get list of dates between two dates
  static List<DateTime> getDateRange(DateTime start, DateTime end) {
    final days = daysBetween(start, end);
    return List.generate(days + 1, (index) => start.add(Duration(days: index)));
  }

  /// Format duration to readable string
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    }
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    }
    return '${duration.inSeconds}s';
  }

  /// Smart date display (Today, Yesterday, or date)
  static String formatSmart(DateTime? date) {
    if (date == null) return '-';

    if (isToday(date)) {
      return 'Today, ${formatTime(date)}';
    }

    if (isYesterday(date)) {
      return 'Yesterday, ${formatTime(date)}';
    }

    if (isTomorrow(date)) {
      return 'Tomorrow, ${formatTime(date)}';
    }

    if (isThisWeek(date)) {
      return DateFormat('EEEE, HH:mm').format(date);
    }

    return formatDisplay(date);
  }
}
