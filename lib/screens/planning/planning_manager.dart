import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../datasources/planning/planning_datasource.dart';
import '../../../serializables/planning.dart';
import '../../../theme.dart';
import '../../../widgets/button_container.dart';
import '../../providers/client_database.dart';
import '../../widgets/page_header.dart';
import 'appointment_form.dart';
import 'planing_calendar.dart';

class PlanningManager extends StatefulWidget {
  const PlanningManager({super.key});

  @override
  State<PlanningManager> createState() => _PlanningManagerState();
}

class _PlanningManagerState extends State<PlanningManager> {
  final ScrollController _controller = ScrollController();
  PlanningDatasource datasource = PlanningDatasource();
  CalendarController controller = CalendarController();

  Planning? selectedPlanning;

  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return f.ScaffoldPage(
      header: PageTitle(
        text: 'planifier'.tr(),
        trailing: f.Row(
          children: [
            ButtonContainer(
              color: Colors.grey,
              icon: f.FluentIcons.add,
              text: 'delete'.tr(),
              showBottom: false,
              showCounter: false,
              action: selectedPlanning != null &&
                      (selectedPlanning!.createdBy ==
                              DatabaseGetter.me.value!.id ||
                          DatabaseGetter().isAdmin())
                  ? deleteAppointement
                  : null,
            ),
            smallSpace,
            ButtonContainer(
                icon: f.FluentIcons.add,
                text: 'add'.tr(),
                showBottom: false,
                showCounter: false,
                action: showPlanningCreation),
          ],
        ),
      ),
      content: Row(children: <Widget>[
        Expanded(
            child: Scrollbar(
                thumbVisibility: true,
                controller: _controller,
                child: ListView(
                  controller: _controller,
                  children: <Widget>[
                    Container(
                      color: appTheme.backGroundColor,
                      height: 500.px,
                      child: PlanningCalendar(
                        controller: controller,
                        datasource: datasource,
                        toDo: (s) {
                          setState(() {
                            selectedDate = s.date;
                            if (s.appointments != null &&
                                s.appointments!.isNotEmpty) {
                              selectedPlanning = s.appointments!.first;
                            } else {
                              selectedPlanning = null;
                            }
                          });
                        },
                      ),
                    )
                  ],
                )))
      ]),
    );
  }

  void deleteAppointement() {
    if (selectedPlanning != null) {
      DatabaseGetter.database!
          .deleteDocument(
              databaseId: databaseId,
              collectionId: planningID,
              documentId: selectedPlanning!.id)
          .then((value) {
        datasource.appointments?.remove(selectedPlanning);
        datasource.notifyListeners(
            CalendarDataSourceAction.remove, [selectedPlanning]);
        selectedPlanning = null;
      });
    }
  }

  void showPlanningCreation() {
    f.showDialog(
        context: context,
        barrierDismissible: true,
        builder: (c) {
          return f.ContentDialog(
            title: const Text("createevent").tr(),
            constraints: BoxConstraints.loose(f.Size(800.px, 500.px)),
            content: AppointmentForm(
              startDate: selectedDate,
              datasource: datasource,
            ),
          );
        });
  }
}
