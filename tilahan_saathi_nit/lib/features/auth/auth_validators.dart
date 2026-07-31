import 'package:flutter/material.dart';

/// Client-side form validators shared across the auth screens.
abstract final class AuthValidators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? Function(String?) confirmPassword(TextEditingController passwordController) {
    return (value) {
      if (value == null || value.isEmpty) return 'Confirm your password';
      if (value != passwordController.text) return 'Passwords do not match';
      return null;
    };
  }

  static String? required(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }
}
