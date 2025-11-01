/// Enhanced email validator to prevent fake/disposable emails
class EmailValidator {
  // List of disposable/temporary email domains to block
  static const List<String> _disposableDomains = [
    'tempmail.com',
    'guerrillamail.com',
    '10minutemail.com',
    'throwaway.email',
    'mailinator.com',
    'maildrop.cc',
    'temp-mail.org',
    'getnada.com',
    'trashmail.com',
    'fakeinbox.com',
    'yopmail.com',
    'mohmal.com',
    'sharklasers.com',
    'guerrillamail.info',
    'grr.la',
    'guerrillamail.biz',
    'guerrillamail.de',
    'spam4.me',
    'mailnesia.com',
    'mytemp.email',
    'tempinbox.com',
    'emailondeck.com',
    'mintemail.com',
    'dispostable.com',
    'throwawaymail.com',
    'tempr.email',
    'getairmail.com',
    'mailcatch.com',
    'mailnull.com',
    'spamgourmet.com',
  ];

  // Common test/fake email patterns
  static const List<String> _testPatterns = [
    'test@test.com',
    'fake@fake.com',
    'asdf@asdf.com',
    'user@example.com',
    'test@example.com',
    'admin@test.com',
  ];

  /// Main validation method - returns error message or null if valid
  static String? validate(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }

    email = email.trim().toLowerCase();

    // Basic format check
    if (!_hasValidFormat(email)) {
      return 'Please enter a valid email address';
    }

    // Check for test/fake patterns
    if (_testPatterns.contains(email)) {
      return 'Please use a real email address';
    }

    // Extract username and domain
    final parts = email.split('@');
    if (parts.length != 2) {
      return 'Invalid email format';
    }

    final username = parts[0];
    final domain = parts[1];

    // Validate username
    final usernameError = _validateUsername(username);
    if (usernameError != null) {
      return usernameError;
    }

    // Validate domain
    final domainError = _validateDomain(domain);
    if (domainError != null) {
      return domainError;
    }

    return null; // Email is valid
  }

  /// Check basic email format
  static bool _hasValidFormat(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate username part (before @)
  static String? _validateUsername(String username) {
    // Check minimum length
    if (username.length < 3) {
      return 'Email username must be at least 3 characters';
    }

    // Block number-only usernames (777, 123, etc.)
    if (RegExp(r'^\d+$').hasMatch(username)) {
      return 'Email cannot be only numbers';
    }

    // Block excessive repeated characters (aaa, xxx, etc.)
    if (_hasExcessiveRepeats(username)) {
      return 'Please use a valid email address';
    }

    return null;
  }

  /// Validate domain part (after @)
  static String? _validateDomain(String domain) {
    // Check if domain is in disposable email list
    if (_disposableDomains.contains(domain)) {
      return 'Temporary email addresses are not allowed';
    }

    // Check for obvious fake domains
    if (domain == 'test.com' || domain == 'fake.com' || domain == 'asdf.com') {
      return 'Please use a real email address';
    }

    // Domain must have at least one dot
    if (!domain.contains('.')) {
      return 'Invalid email domain';
    }

    return null;
  }

  /// Check if string has 3+ consecutive repeated characters
  static bool _hasExcessiveRepeats(String text) {
    if (text.length < 3) return false;

    for (int i = 0; i < text.length - 2; i++) {
      if (text[i] == text[i + 1] && text[i] == text[i + 2]) {
        return true;
      }
    }
    return false;
  }

  /// Quick check if email is valid (returns bool)
  static bool isValid(String? email) {
    return validate(email) == null;
  }
}
