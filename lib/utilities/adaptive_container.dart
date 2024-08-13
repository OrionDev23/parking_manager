import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../datasources/parcoto_datasource.dart';
import '../theme.dart';

class AdaptiveTextContainer extends StatelessWidget {
  final String text;

  const AdaptiveTextContainer({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: appTheme.color,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(text,style: rowTextStyle,)),
        ),
      ],
    );
  }
}
