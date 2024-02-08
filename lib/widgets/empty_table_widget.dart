import "package:data_table_2/data_table_2.dart";
import "package:easy_localization/easy_localization.dart";
import "package:fluent_ui/fluent_ui.dart";
import "package:responsive_sizer/responsive_sizer.dart";

import "../theme.dart";
import "empty_widget/src/widget.dart";

class NoDataWidget extends StatelessWidget {
  final AsyncDataTableSource? datasource;
  final IconData icon;
  final String text;

  const NoDataWidget(
      {super.key,
      this.datasource,
      this.icon = FluentIcons.database_block,
      this.text = 'lvide'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      width: 80.w,
      child: Column(children: [
        bigSpace,
        Flexible(
          child: EmptyWidget(
            title: text.tr(),
            titleTextStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            image: PackageImage.Image_3.encode(),
          ),
        ),
        if (datasource != null) bigSpace,
        if (datasource != null)
          FilledButton(
              child: const Text('refresh').tr(),
              onPressed: () {
                datasource?.refreshDatasource();
              })
      ]),
    );
  }
}
