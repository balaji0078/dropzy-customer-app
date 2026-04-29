import 'package:flutter/material.dart';
import '../config/theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isSecondary;
  final double? width;
  final double height;
  final IconData? icon;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.width,
    this.height = 50,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: isSecondary
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: AppTheme.primaryRed,
                  width: 2,
                ),
                foregroundColor: AppTheme.primaryRed,
              ),
              child: _buildContent(),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}
