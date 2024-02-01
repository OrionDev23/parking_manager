import 'package:flutter/material.dart';
import 'package:parc_oto/datasources/planning/planning_datasource.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../theme.dart';
import 'appointment_widget.dart';

class PlanningCalendar extends StatefulWidget {
  final CalendarController controller;
  final PlanningDatasource datasource;

  final CalendarTapCallback? toDo;

  const PlanningCalendar(
      {super.key,
      required this.controller,
      required this.datasource,
      this.toDo});

  @override
  State<PlanningCalendar> createState() => _PlanningCalendarState();
}

class _PlanningCalendarState extends State<PlanningCalendar> {
  DateTime focusedDay = DateTime.now();

  DateTime? selectedDay;

  CalendarView currentView = CalendarView.month;
  List<CalendarView> views = const [
    CalendarView.month,
    CalendarView.timelineMonth,
    CalendarView.schedule
  ];

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return SfCalendar(
      view: currentView,
      firstDayOfWeek: DateTime.saturday,
      controller: widget.controller,
      onTap: widget.toDo,
      appointmentBuilder: (c, d) => AppointmentWidget(
        calendarController: widget.controller,
        details: d,
      ),
      showNavigationArrow: true,
      showTodayButton: true,
      showDatePickerButton: false,
      allowViewNavigation: true,
      headerStyle: const CalendarHeaderStyle(
        textAlign: TextAlign.center,
      ),
      allowedViews: views,
      monthViewSettings: MonthViewSettings(
        appointmentDisplayCount: 3,
        showTrailingAndLeadingDates: false,
        numberOfWeeksInView: 6,
        agendaItemHeight: 50.px,
        navigationDirection: MonthNavigationDirection.vertical,
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        monthCellStyle: MonthCellStyle(
          trailingDatesBackgroundColor: appTheme.fillColor,
          leadingDatesBackgroundColor: appTheme.fillColor,
        ),
        showAgenda: true,
      ),
      timeSlotViewSettings: const TimeSlotViewSettings(
        timeFormat: "HH:mm",
        nonWorkingDays: [DateTime.friday, DateTime.saturday],
        timeIntervalWidth: 200,
        timeIntervalHeight: 300,
        timelineAppointmentHeight: 100,
        minimumAppointmentDuration: Duration(hours: 1),
      ),
      loadMoreWidgetBuilder: loadMoreWidget,
      dataSource: widget.datasource,
    );
  }

  Widget loadMoreWidget(
      BuildContext context, LoadMoreCallback loadMoreAppointments) {
    return FutureBuilder<void>(
      future: loadMoreAppointments(),
      builder: (context, snapShot) {
        return Container(
            alignment: Alignment.center,
            child: const CircularProgressIndicator());
      },
    );
  }
}
