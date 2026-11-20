import "package:data_table_2/data_table_2.dart";
import "package:easy_localization/easy_localization.dart";
import "package:fluent_ui/fluent_ui.dart";
import "package:provider/provider.dart";

import "../theme.dart";
import "empty_widget/src/widget.dart";

class NoDataWidget extends StatelessWidget {
  final AsyncDataTableSource? datasource;
  final IconData icon;
  final String text;

  const NoDataWidget({
    super.key,
    this.datasource,
    this.icon = FluentIcons.database_block,
    this.text = 'lvide',
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : screenWidth - 32;
        final contentWidth = availableWidth.clamp(0.0, 560.0).toDouble();

        return Center(
          child: SizedBox(
            width: contentWidth,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon == FluentIcons.database_block)
                    Flexible(
                      child: EmptyWidget(
                        title: text.tr(),
                        titleTextStyle: TextStyle(
                          color: appTheme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        image: PackageImage.Image_3.encode(),
                      ),
                    )
                  else
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 52,
                            color: appTheme.color,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            text.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: appTheme.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (datasource != null) bigSpace,
                  if (datasource != null)
                    FilledButton(
                      child: const Text('refresh').tr(),
                      onPressed: () {
                        datasource?.refreshDatasource();
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
