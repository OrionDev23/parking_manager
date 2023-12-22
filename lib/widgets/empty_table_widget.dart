
import "package:easy_localization/easy_localization.dart";
import "package:fluent_ui/fluent_ui.dart";
import "package:parc_oto/datasources/parcoto_datasource.dart";
import "package:provider/provider.dart";
import "package:responsive_sizer/responsive_sizer.dart";

import "../theme.dart";

class NoDataWidget extends StatelessWidget {
  final ParcOtoDatasource? datasource;
  final IconData icon;
  final String text;
  const NoDataWidget({super.key, this.datasource,this.icon=FluentIcons.database_block,this.text='lvide'});

  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return Container(
      padding: const EdgeInsets.all(10),
      width: 80.w,
      child: Column(
        children:[
          bigSpace,
          bigSpace,
          bigSpace,
          Icon(
            icon,
            color: appTheme.color.lightest.withOpacity(0.2),
            size: 24.sp,
          ),
          bigSpace,
          bigSpace,
          Text(text.tr(),style: placeStyle.copyWith(fontStyle: FontStyle.italic,fontWeight: FontWeight.bold),).tr(),
          if(datasource!=null)
            bigSpace,
          if(datasource!=null)
          FilledButton(child: const Text('refresh').tr(), onPressed: (){
            datasource?.refreshDatasource();
          })
        ]
      ),
    );
  }
}
