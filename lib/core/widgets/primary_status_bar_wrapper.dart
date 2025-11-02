import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PrimaryStatusBarWrapper extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const PrimaryStatusBarWrapper({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? AppColors.primary,
      child: SafeArea(
        top: false,
        bottom: false,
        left: true,
        right: true,
        child: child,
      ),
    );
  }
}


