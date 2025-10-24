import 'package:intl/intl.dart';

class NumberFormatter {
  /// Formats a number with commas (e.g., 1000 -> 1,000)
  static String formatWithCommas(int number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  /// Formats salary amount with proper comma formatting
  /// Handles both regular numbers and K/M suffixes
  static String formatSalaryAmount(int amount) {
    if (amount >= 1000000) {
      // For millions, show as M (e.g., 1,200,000 -> 1.2M)
      double millions = amount / 1000000;
      if (millions == millions.roundToDouble()) {
        return '${millions.round()}M';
      } else {
        return '${millions.toStringAsFixed(1)}M';
      }
    } else if (amount >= 1000) {
      // For thousands, show with commas (e.g., 50,000)
      return formatWithCommas(amount);
    } else {
      // For amounts less than 1000, show as-is
      return amount.toString();
    }
  }

  /// Parses salary string and extracts the first number
  static int? parseSalaryNumber(String salaryText) {
    // Remove currency symbols, commas, and spaces
    String cleaned = salaryText.replaceAll(RegExp(r'[₹$,\s]'), '');
    
    // Handle K/M suffixes
    if (cleaned.toLowerCase().contains('k')) {
      final numberPart = cleaned.toLowerCase().replaceAll('k', '');
      final number = double.tryParse(numberPart);
      if (number != null) {
        return (number * 1000).round();
      }
    } else if (cleaned.toLowerCase().contains('m')) {
      final numberPart = cleaned.toLowerCase().replaceAll('m', '');
      final number = double.tryParse(numberPart);
      if (number != null) {
        return (number * 1000000).round();
      }
    }
    
    // Extract first number from the string
    final numbers = RegExp(r'\d+').allMatches(cleaned);
    if (numbers.isNotEmpty) {
      return int.tryParse(numbers.first.group(0)!);
    }
    
    return null;
  }
}