import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  // Maximum value to prevent integer overflow (10 crores)
  static const int maxValue = 100000000;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }

    // Limit to prevent overflow
    if (digitsOnly.length > 8) {
      digitsOnly = digitsOnly.substring(0, 8);
    }

    // Parse the number safely
    int value;
    try {
      value = int.parse(digitsOnly);
      if (value > maxValue) {
        return oldValue; // Return old value if exceeds max
      }
    } catch (e) {
      return oldValue;
    }

    // Format with Indian numbering system
    String formatted = _formatIndianCurrency(value);

    // Calculate new cursor position
    int cursorPosition = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }

  String _formatIndianCurrency(int number) {
    if (number < 1000) {
      return number.toString();
    }

    String numStr = number.toString();
    String result = '';
    int length = numStr.length;

    // Add last 3 digits
    result = numStr.substring(length - 3);
    int remaining = length - 3;

    // Add remaining digits in groups of 2
    while (remaining > 0) {
      int start = remaining - 2;
      if (start < 0) start = 0;
      result = '${numStr.substring(start, remaining)},$result';
      remaining = start;
    }

    return result;
  }
}
