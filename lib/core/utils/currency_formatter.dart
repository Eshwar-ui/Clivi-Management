import 'package:intl/intl.dart';
import '../config/app_constants.dart';

/// Currency formatting utilities
/// Provides consistent currency formatting throughout the app
class CurrencyFormatter {
  // Private constructor to prevent instantiation
  CurrencyFormatter._();

  // ============================================================
  // FORMATTERS
  // ============================================================

  /// Indian Rupee formatter with symbol
  static final NumberFormat _rupeeFormat = NumberFormat.currency(
    locale: AppConstants.defaultLocale,
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  /// Indian Rupee formatter without symbol
  static final NumberFormat _rupeeFormatNoSymbol = NumberFormat.currency(
    locale: AppConstants.defaultLocale,
    symbol: '',
    decimalDigits: 2,
  );

  /// Compact currency formatter (e.g., 1.2L, 50K)
  static final NumberFormat _compactFormat = NumberFormat.compactCurrency(
    locale: AppConstants.defaultLocale,
    symbol: AppConstants.currencySymbol,
    decimalDigits: 1,
  );

  /// Simple currency formatter (no decimals for whole numbers)
  static final NumberFormat _simpleFormat = NumberFormat.currency(
    locale: AppConstants.defaultLocale,
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  /// Number formatter with grouping
  static final NumberFormat _numberFormat = NumberFormat.decimalPattern(
    AppConstants.defaultLocale,
  );

  // ============================================================
  // FORMAT METHODS
  // ============================================================

  /// Format to Indian Rupees (₹1,23,456.78)
  static String format(double? amount) {
    if (amount == null) return '${AppConstants.currencySymbol}0.00';
    return _rupeeFormat.format(amount);
  }

  /// Format without symbol (1,23,456.78)
  static String formatWithoutSymbol(double? amount) {
    if (amount == null) return '0.00';
    return _rupeeFormatNoSymbol.format(amount).trim();
  }

  /// Format with compact notation (₹1.2L, ₹50K)
  static String formatCompact(double? amount) {
    if (amount == null) return '${AppConstants.currencySymbol}0';
    return _compactFormat.format(amount);
  }

  /// Format without decimals for whole numbers (₹1,23,456)
  static String formatSimple(double? amount) {
    if (amount == null) return '${AppConstants.currencySymbol}0';

    // If amount is a whole number, format without decimals
    if (amount == amount.truncateToDouble()) {
      return _simpleFormat.format(amount);
    }

    return _rupeeFormat.format(amount);
  }

  /// Format as number with grouping (1,23,456.78)
  static String formatNumber(double? amount) {
    if (amount == null) return '0';
    return _numberFormat.format(amount);
  }

  /// Format with custom decimal places
  static String formatWithDecimals(double? amount, int decimals) {
    if (amount == null) return '${AppConstants.currencySymbol}0';

    final formatter = NumberFormat.currency(
      locale: AppConstants.defaultLocale,
      symbol: AppConstants.currencySymbol,
      decimalDigits: decimals,
    );

    return formatter.format(amount);
  }

  // ============================================================
  // INDIAN NOTATION (Lakhs, Crores)
  // ============================================================

  /// Format in Indian notation (₹1.5 Cr, ₹25 L, ₹50 K)
  static String formatIndian(double? amount) {
    if (amount == null || amount == 0) return '${AppConstants.currencySymbol}0';

    final symbol = AppConstants.currencySymbol;
    final absAmount = amount.abs();
    final sign = amount < 0 ? '-' : '';

    if (absAmount >= 10000000) {
      // Crores (1 Cr = 10,000,000)
      final crores = absAmount / 10000000;
      return '$sign$symbol${_formatDecimal(crores)} Cr';
    } else if (absAmount >= 100000) {
      // Lakhs (1 L = 100,000)
      final lakhs = absAmount / 100000;
      return '$sign$symbol${_formatDecimal(lakhs)} L';
    } else if (absAmount >= 1000) {
      // Thousands
      final thousands = absAmount / 1000;
      return '$sign$symbol${_formatDecimal(thousands)} K';
    }

    return '$sign$symbol${_formatDecimal(absAmount)}';
  }

  static String _formatDecimal(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  /// Get amount in lakhs
  static double toLakhs(double amount) => amount / 100000;

  /// Get amount in crores
  static double toCrores(double amount) => amount / 10000000;

  /// Convert lakhs to amount
  static double fromLakhs(double lakhs) => lakhs * 100000;

  /// Convert crores to amount
  static double fromCrores(double crores) => crores * 10000000;

  // ============================================================
  // PARSE METHODS
  // ============================================================

  /// Parse currency string to double
  static double? parse(String? value) {
    if (value == null || value.isEmpty) return null;

    // Remove currency symbol, commas, and spaces
    final cleaned = value
        .replaceAll(AppConstants.currencySymbol, '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();

    return double.tryParse(cleaned);
  }

  /// Parse with default value
  static double parseWithDefault(String? value, {double defaultValue = 0}) {
    return parse(value) ?? defaultValue;
  }

  // ============================================================
  // DISPLAY HELPERS
  // ============================================================

  /// Format for display with sign (+ / -)
  static String formatWithSign(double? amount) {
    if (amount == null) return '${AppConstants.currencySymbol}0.00';

    final formatted = format(amount.abs());

    if (amount > 0) {
      return '+$formatted';
    } else if (amount < 0) {
      return '-$formatted';
    }

    return formatted;
  }

  /// Format for accounting (negative in parentheses)
  static String formatAccounting(double? amount) {
    if (amount == null) return '${AppConstants.currencySymbol}0.00';

    if (amount < 0) {
      return '(${format(amount.abs())})';
    }

    return format(amount);
  }

  /// Format range (₹1,000 - ₹5,000)
  static String formatRange(double? min, double? max) {
    final minStr = formatSimple(min);
    final maxStr = formatSimple(max);
    return '$minStr - $maxStr';
  }

  /// Format as percentage
  static String formatPercent(double? value, {int decimals = 1}) {
    if (value == null) return '0%';
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format percentage change
  static String formatPercentChange(double? value) {
    if (value == null) return '0%';

    final formatted = value.abs().toStringAsFixed(1);

    if (value > 0) {
      return '+$formatted%';
    } else if (value < 0) {
      return '-$formatted%';
    }

    return '0%';
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  /// Check if string is valid currency format
  static bool isValidCurrency(String? value) {
    if (value == null || value.isEmpty) return false;
    return parse(value) != null;
  }

  /// Clean currency input (remove all non-numeric except decimal)
  static String cleanInput(String input) {
    return input.replaceAll(RegExp(r'[^\d.]'), '');
  }

  // ============================================================
  // CALCULATION HELPERS
  // ============================================================

  /// Calculate percentage
  static double percentage(double value, double total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }

  /// Calculate discount amount
  static double discountAmount(double price, double discountPercent) {
    return price * (discountPercent / 100);
  }

  /// Calculate price after discount
  static double priceAfterDiscount(double price, double discountPercent) {
    return price - discountAmount(price, discountPercent);
  }

  /// Calculate GST amount
  static double gstAmount(double price, {double gstPercent = 18}) {
    return price * (gstPercent / 100);
  }

  /// Calculate price with GST
  static double priceWithGst(double price, {double gstPercent = 18}) {
    return price + gstAmount(price, gstPercent: gstPercent);
  }

  /// Calculate sum of amounts
  static double sum(List<double> amounts) {
    return amounts.fold(0, (sum, amount) => sum + amount);
  }

  /// Calculate average of amounts
  static double average(List<double> amounts) {
    if (amounts.isEmpty) return 0;
    return sum(amounts) / amounts.length;
  }
}
