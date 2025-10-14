class SalaryUtils {
  /// Parses a salary range string and returns the minimum and maximum values in thousands
  /// Handles formats like: "50k-80k", "15-25", "50000-80000", "$50k-$80k", "50K-80K"
  static Map<String, double>? parseSalaryRange(String salaryRange) {
    if (salaryRange.isEmpty) return null;
    
    try {
      // Clean the string: remove $, spaces, and convert to lowercase
      String cleaned = salaryRange
          .toLowerCase()
          .replaceAll('\$', '')
          .replaceAll(' ', '')
          .replaceAll(',', '');
      
      // Handle different separators: -, to, –, —
      List<String> separators = ['-', 'to', '–', '—'];
      String? separator;
      
      for (String sep in separators) {
        if (cleaned.contains(sep)) {
          separator = sep;
          break;
        }
      }
      
      if (separator == null) {
        // Single value, treat as minimum with no maximum
        double value = _parseValue(cleaned);
        return {'min': value, 'max': value};
      }
      
      List<String> parts = cleaned.split(separator);
      if (parts.length != 2) return null;
      
      double minSalary = _parseValue(parts[0].trim());
      double maxSalary = _parseValue(parts[1].trim());
      
      return {
        'min': minSalary,
        'max': maxSalary,
      };
    } catch (e) {
      return null;
    }
  }
  
  /// Parses a single salary value and converts it to thousands
  static double _parseValue(String value) {
    if (value.isEmpty) throw FormatException('Empty value');
    
    // Remove any trailing characters that aren't numbers or k
    value = value.replaceAll(RegExp(r'[^0-9k.]'), '');
    
    if (value.endsWith('k')) {
      // Value is already in thousands
      String numStr = value.substring(0, value.length - 1);
      return double.parse(numStr);
    } else {
      // Value might be in full numbers, convert to thousands
      double fullValue = double.parse(value);
      
      // If the value is greater than 1000, assume it's in full dollars and convert to thousands
      if (fullValue >= 1000) {
        return fullValue / 1000;
      } else {
        // If less than 1000, assume it's already in thousands
        return fullValue;
      }
    }
  }
  
  /// Checks if a job's salary range falls within the filter range
  static bool isWithinSalaryRange(String jobSalaryRange, double minFilter, double maxFilter) {
    Map<String, double>? parsed = parseSalaryRange(jobSalaryRange);
    if (parsed == null) return true; // Include jobs with unparseable salary ranges
    
    double jobMin = parsed['min']!;
    double jobMax = parsed['max']!;
    
    // Check if there's any overlap between job salary range and filter range
    // Job range overlaps with filter range if:
    // - Job min is less than or equal to filter max AND
    // - Job max is greater than or equal to filter min
    return jobMin <= maxFilter && jobMax >= minFilter;
  }
  
  /// Formats salary range for display
  static String formatSalaryRange(double min, double max) {
    if (min == max) {
      return '\$${min.round()}k';
    }
    return '\$${min.round()}k - \$${max.round()}k';
  }
}