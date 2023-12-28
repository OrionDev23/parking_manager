
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/logs/planning/planing_calendar.dart';
import 'package:parc_oto/widgets/page_header.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../datasources/planning/planning_datasource.dart';
import '../../../serializables/planning.dart';
import '../../../theme.dart';
import '../../../widgets/button_container.dart';
import 'appointment_form.dart';

class PlanningManager extends StatefulWidget {
  const PlanningManager({super.key});

  @override
  State<PlanningManager> createState() => _PlanningManagerState();
}

class _PlanningManagerState extends State<PlanningManager> {


  final ScrollController _controller=ScrollController();
  PlanningDatasource datasource=PlanningDatasource();
  CalendarController controller =CalendarController();

  Planning? selectedPlanning;

  @override
  Widget build(BuildContext context) {

    var appTheme=context.watch<AppTheme>();
    return f.ScaffoldPage(
      header: PageTitle(
        text: 'planifier'.tr(),
        trailing: f.Row(
          children: [
            SizedBox(
                width: 15.w,
                height: 10.h,
                child: ButtonContainer(
                  color: Colors.grey,
                  icon: f.FluentIcons.add,
                  text: 'delete'.tr(),
                  showBottom: false,
                  showCounter: false,
                  action: selectedPlanning!=null && (selectedPlanning!.createdBy==ClientDatabase.me.value!.id || ClientDatabase().isAdmin())?deleteAppointement:null,
                )),
            smallSpace,
            SizedBox(
                width: 15.w,
                height: 10.h,
                child: ButtonContainer(
                  icon: f.FluentIcons.add,
                  text: 'add'.tr(),
                  showBottom: false,
                  showCounter: false,
                  action: showPlanningCreation
                )),
          ],
        ),
      ),
      content: Row(children: <Widget>[
        Expanded(
          child:Scrollbar(
              thumbVisibility: true,
              controller: _controller,
              child: ListView(
                controller: _controller,
                children: <Widget>[
                  Container(
                    color: appTheme.backGroundColor,
                    height: 100.h,
                    child: PlanningCalendar(controller: controller,datasource: datasource,toDo: (s){
                      setState(() {
                        selectedPlanning=s.appointments?.first;
                      });
                    },),
                  )
                ],
              ))
        )
      ]),
    );
  }



  void deleteAppointement(){
    if(selectedPlanning!=null){
      ClientDatabase.database!.deleteDocument(
          databaseId: databaseId,
          collectionId: planningID,
          documentId: selectedPlanning!.id).then((value) {
        datasource.appointments?.remove(selectedPlanning);
        datasource.notifyListeners(CalendarDataSourceAction.remove, [selectedPlanning]);
        selectedPlanning=null;
      });
    }

  }

  void showPlanningCreation(){
    f.showDialog(
        context: context,
        builder: (c){
          return f.ContentDialog(
            title: const Text("Création d'evenement"),
            constraints: BoxConstraints.loose(f.Size(
              600.px,600.px
            )),
            content: const AppointmentForm(),
          );
        });
  }



}
