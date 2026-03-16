import 'package:intl/intl.dart';

class AppUtils {
  // Format currency
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // Format number
  static String formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Get initials from name
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Calculate discount percentage
  static int calculateDiscountPercentage(double originalPrice, double discountedPrice) {
    if (originalPrice <= 0) return 0;
    final discount = ((originalPrice - discountedPrice) / originalPrice) * 100;
    return discount.round();
  }
}