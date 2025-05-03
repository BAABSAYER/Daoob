import 'package:flutter/material.dart';
import 'package:eventora_app/config/theme.dart';

enum ButtonType { primary, secondary, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType buttonType;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? height;
  final double? width;
  
  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.buttonType = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.height,
    this.width,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (buttonType) {
      case ButtonType.primary:
        return _buildElevatedButton(theme);
      case ButtonType.secondary:
        return _buildOutlinedButton(theme);
      case ButtonType.text:
        return _buildTextButton(theme);
    }
  }
  
  Widget _buildElevatedButton(ThemeData theme) {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: theme.elevatedButtonTheme.style,
        child: _buildButtonContent(theme, Colors.white),
      ),
    );
  }
  
  Widget _buildOutlinedButton(ThemeData theme) {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height ?? 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: theme.outlinedButtonTheme.style,
        child: _buildButtonContent(theme, AppTheme.primaryColor),
      ),
    );
  }
  
  Widget _buildTextButton(ThemeData theme) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: theme.textButtonTheme.style,
      child: _buildButtonContent(theme, AppTheme.primaryColor),
    );
  }
  
  Widget _buildButtonContent(ThemeData theme, Color color) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }
    
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }
    
    return Text(text);
  }
}