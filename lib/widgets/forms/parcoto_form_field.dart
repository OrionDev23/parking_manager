import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

/// Shared Parcoto field layout. Use this wrapper for text inputs, selectors,
/// date pickers and other form controls so labels and spacing stay consistent.
class ParcotoFormField extends StatelessWidget {
  final String label;
  final Widget child;
  final double? width;
  final bool requiredField;
  final String? helperText;
  final String? errorText;

  const ParcotoFormField({
    super.key,
    required this.label,
    required this.child,
    this.width,
    this.requiredField = false,
    this.helperText,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(children: [
              Expanded(
                child: Text(label, style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
              ),
              if (requiredField)
                Text('*', style: TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                )),
            ]),
          ),
          child,
          if (errorText != null && errorText!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(errorText!, style: TextStyle(
              color: Colors.red,
              fontSize: 10,
            )),
          ] else if (helperText != null && helperText!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(helperText!, style: TextStyle(
              color: theme.inactiveColor,
              fontSize: 10,
            )),
          ],
        ],
      ),
    );
  }
}

/// Standard Fluent text input used throughout Parcoto.
class ParcotoTextBox extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final bool enabled;
  final bool readOnly;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final CrossAxisAlignment? crossAxisAlignment;
  final TextStyle? style;
  final TextStyle? placeholderStyle;
  final Color? cursorColor;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;

  const ParcotoTextBox({
    super.key,
    this.controller,
    this.placeholder,
    this.enabled = true,
    this.readOnly = false,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.crossAxisAlignment,
    this.style,
    this.placeholderStyle,
    this.cursorColor,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.prefix,
    this.suffix,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final border = theme.inactiveColor.withValues(alpha: .30);
    return SizedBox(
      height: maxLines == 1 ? 42 : null,
      child: TextBox(
        controller: controller,
        placeholder: placeholder,
        enabled: enabled,
        readOnly: readOnly,
        maxLength: maxLength,
        maxLines: maxLines,
        minLines: minLines,
        keyboardType: keyboardType,
        textAlign: textAlign,
        textAlignVertical: textAlignVertical,
        crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
        style: style ?? theme.typography.body,
        placeholderStyle: placeholderStyle ?? TextStyle(
          color: theme.inactiveColor,
          fontSize: 12,
        ),
        cursorColor: cursorColor ?? theme.accentColor,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTap: onTap,
        prefix: prefix,
        suffix: suffix,
        obscureText: obscureText,
        decoration: WidgetStatePropertyAll(BoxDecoration(
          color: theme.inactiveBackgroundColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: border),
        )),
      ),
    );
  }
}
