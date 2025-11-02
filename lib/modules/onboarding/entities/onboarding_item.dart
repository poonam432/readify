import 'package:flutter/material.dart';

class OnboardingItem {
  final String title;
  final String description;
  final String imagePath;
  final Color illustrationBackgroundColor;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.illustrationBackgroundColor,
  });
}

