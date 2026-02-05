import 'package:flutter/material.dart';
import '../widgets/eco_pulse_widgets.dart';

enum PasswordStrength { weak, medium, strong }

class ValidationUtils {
  // RFC 5322 Official Standard Email Regex
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? validateConfirmPassword(
    String? value,
    String originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static PasswordStrength calculatePasswordStrength(String password) {
    if (password.length < 8) return PasswordStrength.weak;

    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
    );

    int score = 0;
    if (hasUppercase) score++;
    if (hasDigits) score++;
    if (hasSpecialCharacters) score++;

    if (score == 3 && password.length >= 10) return PasswordStrength.strong;
    if (score >= 2) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  static Color getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return EcoColors.terracotta;
      case PasswordStrength.medium:
        // A middle ground color, similar to generic amber/orange
        return const Color(0xFFF59E0B);
      case PasswordStrength.strong:
        return EcoColors.forest;
    }
  }

  static String getStrengthLabel(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }
}
