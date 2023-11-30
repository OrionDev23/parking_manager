
import "package:fluent_ui/fluent_ui.dart";
import "package:provider/provider.dart";

import "../theme.dart";

class NoDataWidget extends StatelessWidget {
  const NoDataWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return Column(
      children:[
        Icon(
          FluentIcons.field_empty,
          color: appTheme.color.withOpacity(0.5),
        ),
        smallSpace,
        const Text('empty')
      ]
    );
  }
}
