import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../../theme.dart';
import '../../../../widgets/page_header.dart';
import 'disponibilite_table.dart';

class DisponibiliteGestion extends StatefulWidget {
  const DisponibiliteGestion({super.key,});

  @override
  DisponibiliteGestionState createState() => DisponibiliteGestionState();
}

class DisponibiliteGestionState extends State<DisponibiliteGestion> {
  final tstyle=TextStyle(
    fontSize: 10.sp,
  );



  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return ScaffoldPage(
      header: PageTitle(
        text: 'disponibilite'.tr(),
      ),
      content: const DisponibliteTable(),
    );
  }
}
