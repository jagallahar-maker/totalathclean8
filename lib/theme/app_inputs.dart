import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/theme/theme_tokens.dart';

/// Standard text input field
/// 
/// Provides consistent styling for all text inputs across the app
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? initialValue;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool autofocus;
  
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.initialValue,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onTap,
    this.inputFormatters,
    this.textInputAction,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      enabled: enabled,
      onChanged: onChanged,
      onTap: onTap,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      focusNode: focusNode,
      autofocus: autofocus,
      style: TextStyle(
        color: tokens.inputText,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: tokens.textSecondary),
        hintText: hint,
        hintStyle: TextStyle(color: tokens.inputHint),
        errorText: errorText,
        errorStyle: TextStyle(color: tokens.danger),
        filled: true,
        fillColor: tokens.inputBackground,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: tokens.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: tokens.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: tokens.inputBorderFocused, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: tokens.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: tokens.danger, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

/// Compact number input for workout logging
/// 
/// Used specifically for weight/reps inputs in workout screens
class AppNumberInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final double? width;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool enabled;
  final TextAlign textAlign;
  
  const AppNumberInput({
    super.key,
    this.controller,
    this.hint,
    this.width,
    this.onChanged,
    this.onTap,
    this.textInputAction,
    this.focusNode,
    this.enabled = true,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: tokens.inputBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: tokens.inputBorder,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        onTap: onTap,
        textInputAction: textInputAction,
        focusNode: focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: textAlign,
        style: TextStyle(
          color: tokens.inputText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: tokens.inputHint,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}

/// Search input field with search icon
/// 
/// Used for search/filter functionality
class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;
  
  const AppSearchField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: autofocus,
      style: TextStyle(
        color: tokens.inputText,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint ?? 'Search...',
        hintStyle: TextStyle(color: tokens.inputHint),
        filled: true,
        fillColor: tokens.inputBackground,
        prefixIcon: Icon(Icons.search, color: tokens.icon),
        suffixIcon: controller?.text.isNotEmpty ?? false
            ? IconButton(
                icon: Icon(Icons.clear, color: tokens.icon),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: BorderSide(color: tokens.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: BorderSide(color: tokens.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: BorderSide(color: tokens.inputBorderFocused, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }
}
