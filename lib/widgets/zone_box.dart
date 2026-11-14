import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../theme.dart';

class ZoneBox extends StatelessWidget {
  final String label;
  final Widget? child;
  final double? width;
  final double? height;
  final Widget? trailing;
  final Color? backGroundColor;

  const ZoneBox({
    super.key,
    this.child,
    required this.label,
    this.width,
    this.height,
    this.trailing,
    this.backGroundColor,
  });

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            top: 15,
            child: Container(
              decoration: BoxDecoration(
                color: appTheme.fillColor,
                border: Border.all(color: appTheme.borderColor, width: 1),
                borderRadius: BorderRadius.circular(appTheme.controlRadius),
              ),
              child: child,
            ),
          ),
          Positioned(
            left: 5,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              color: backGroundColor ?? appTheme.backGroundColor,
              child: Text(
                label,
                style: appTheme.writingStyle.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: appTheme.mutedTextColor,
                ),
              ),
            ),
          ),
          if (trailing != null)
            Positioned(
              right: 5,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                color: backGroundColor ?? appTheme.backGroundColor,
                child: trailing,
              ),
            ),
        ],
      ),
    );
  }
}
