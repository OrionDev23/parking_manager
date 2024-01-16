import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../../../providers/counters.dart';
import '../../dashboard/pie_chart/pie_chart.dart';
import '../../logs/logging/log_table.dart';
import 'chauffeur_form.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../../theme.dart';
import '../../../../widgets/button_container.dart';
import '../../../../widgets/page_header.dart';
import 'chauffeur_tabs.dart';
import 'chauffeur_table.dart';

class ChauffeurGestion extends StatefulWidget {
  final bool archive;
  const ChauffeurGestion({super.key,this.archive=false});

  @override
  ChauffeurGestionsState createState() => ChauffeurGestionsState();
}

class ChauffeurGestionsState extends State<ChauffeurGestion> {
  final tstyle=TextStyle(
    fontSize: 10.sp,
  );
  static ValueNotifier<int> stateChanges=ValueNotifier(0);



  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return ScaffoldPage(
      header: PageTitle(
        text: widget.archive?'archive'.tr():'gchauffeurs'.tr(),
        trailing: widget.archive?null:SizedBox(
            width: 15.w,
            height: 10.h,
            child: ButtonContainer(
              icon: FluentIcons.add,
              text: 'add'.tr(),
              showBottom: false,
              showCounter: false,
              action: () {
                final index = ChauffeurTabsState.tabs.length + 1;
                final tab = generateTab(index);
                ChauffeurTabsState.tabs.add(tab);
                ChauffeurTabsState.currentIndex.value = index - 1;
              },
            )),
      ),
      content: Row(
        children: [
          SizedBox(
              width:60.w,
              child: ChauffeurTable(archive: widget.archive,)),
          smallSpace,
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: ValueListenableBuilder(
                      valueListenable: stateChanges,
                      builder: (context,val,w) {
                  
                        return Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: ParcOtoPie(
                            radius: 75,
                            title: 'disponibilite'.tr(),
                            labels: [
                              MapEntry('disponible', DatabaseCounters().countChauffeur(etat: 0)),
                              MapEntry('absent', DatabaseCounters().countChauffeur(etat: 1)),
                              MapEntry('mission', DatabaseCounters().countChauffeur(etat: 2)),
                              MapEntry('quitteentre', DatabaseCounters().countChauffeur(etat: 3))
                            ],
                          ),
                        );
                      }
                  ),
                ),
                smallSpace,
                Text('lactivities',style:  TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: appTheme.writingStyle.color),).tr(),
                smallSpace,
                const Flexible(
                  child: LogTable(
                    statTable: true,
                    pages: false,
                    numberOfRows: 3,
                    filters: {
                      'typemin':'16',
                      'typemax':'25'
                    },
                    fieldsToShow: [
                      'act','date'
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvchauf'.tr()),
      semanticLabel: 'nouvchauf'.tr(),
      icon: const Icon(FluentIcons.document),
      body: const ChauffeurForm(),
      onClosed: () {
        ChauffeurTabsState.tabs.remove(tab);

        if (ChauffeurTabsState.currentIndex.value > 0) {
          ChauffeurTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }
}
