class ValidationUtils {
  static const String _emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  static bool isValidEmail(String email) {
    if (email.trim().isEmpty) {
      return false;
    }
    final regex = RegExp(_emailPattern);
    return regex.hasMatch(email.trim());
  }

  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static PasswordValidationResult validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return PasswordValidationResult(
        isValid: false,
        errors: ['Password is required'],
        requirements: PasswordRequirements.allUnmet(),
      );
    }

    final errors = <String>[];
    final requirements = PasswordRequirements(
      hasMinLength: password.length >= 8,
      hasUpperCase: password.contains(RegExp(r'[A-Z]')),
      hasLowerCase: password.contains(RegExp(r'[a-z]')),
      hasNumber: password.contains(RegExp(r'[0-9]')),
      hasSpecialChar: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    );

    if (!requirements.hasMinLength) {
      errors.add('At least 8 characters');
    }

    if (!requirements.hasUpperCase) {
      errors.add('At least one uppercase letter');
    }

    if (!requirements.hasLowerCase) {
      errors.add('At least one lowercase letter');
    }

    if (!requirements.hasNumber) {
      errors.add('At least one number');
    }

    if (!requirements.hasSpecialChar) {
      errors.add('At least one special character (!@#\$%^&*)');
    }

    return PasswordValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      requirements: requirements,
    );
  }
}

class PasswordRequirements {
  final bool hasMinLength;
  final bool hasUpperCase;
  final bool hasLowerCase;
  final bool hasNumber;
  final bool hasSpecialChar;

  PasswordRequirements({
    required this.hasMinLength,
    required this.hasUpperCase,
    required this.hasLowerCase,
    required this.hasNumber,
    required this.hasSpecialChar,
  });

  static PasswordRequirements allUnmet() {
    return PasswordRequirements(
      hasMinLength: false,
      hasUpperCase: false,
      hasLowerCase: false,
      hasNumber: false,
      hasSpecialChar: false,
    );
  }

  bool get allMet => hasMinLength && hasUpperCase && hasLowerCase && hasNumber && hasSpecialChar;
}

class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;
  final PasswordRequirements requirements;

  PasswordValidationResult({
    required this.isValid,
    required this.errors,
    required this.requirements,
  });
}

