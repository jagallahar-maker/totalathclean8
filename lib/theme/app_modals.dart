import 'package:flutter/material.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/theme/theme_tokens.dart';
import 'package:total_athlete/theme/app_buttons.dart';

/// Standard modal dialog
/// 
/// Provides consistent styling for all modal dialogs
class AppModal extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget content;
  final List<Widget>? actions;
  final bool dismissible;
  final EdgeInsetsGeometry? padding;
  
  const AppModal({
    super.key,
    this.title,
    this.titleWidget,
    required this.content,
    this.actions,
    this.dismissible = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    return Dialog(
      backgroundColor: tokens.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: tokens.cardBorder,
          width: 1,
        ),
      ),
      child: Container(
        padding: padding ?? AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title section
            if (title != null || titleWidget != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: titleWidget ?? Text(
                      title!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  if (dismissible)
                    IconButton(
                      icon: Icon(Icons.close, color: tokens.icon),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Content
            content,
            
            // Actions
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet modal
/// 
/// Provides consistent styling for bottom sheet modals
class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;
  final bool dismissible;
  final double? height;
  
  const AppBottomSheet({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.dismissible = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        border: Border(
          top: BorderSide(color: tokens.cardBorder, width: 1),
          left: BorderSide(color: tokens.cardBorder, width: 1),
          right: BorderSide(color: tokens.cardBorder, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title section
          if (title != null) ...[
            Padding(
              padding: AppSpacing.horizontalLg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: tokens.textPrimary,
                    ),
                  ),
                  if (dismissible)
                    IconButton(
                      icon: Icon(Icons.close, color: tokens.icon),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingLg,
              child: content,
            ),
          ),
          
          // Actions
          if (actions != null && actions!.isNotEmpty) ...[
            Padding(
              padding: AppSpacing.paddingLg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Confirmation dialog helper
/// 
/// Shows a standard confirmation dialog
Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool isDanger = false,
}) {
  final tokens = context.tokens;
  
  return showDialog<bool>(
    context: context,
    builder: (context) => AppModal(
      title: title,
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: tokens.textSecondary,
        ),
      ),
      actions: [
        AppTextButton(
          label: cancelText,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        const SizedBox(width: 12),
        AppPrimaryButton(
          label: confirmText,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
}

/// Info dialog helper
/// 
/// Shows a standard info dialog
Future<void> showAppInfoDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'OK',
}) {
  final tokens = context.tokens;
  
  return showDialog(
    context: context,
    builder: (context) => AppModal(
      title: title,
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: tokens.textSecondary,
        ),
      ),
      actions: [
        AppPrimaryButton(
          label: buttonText,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

/// Bottom sheet helper
/// 
/// Shows a standard bottom sheet
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  String? title,
  required Widget content,
  List<Widget>? actions,
  bool dismissible = true,
  double? height,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => AppBottomSheet(
      title: title,
      content: content,
      actions: actions,
      dismissible: dismissible,
      height: height,
    ),
  );
}
