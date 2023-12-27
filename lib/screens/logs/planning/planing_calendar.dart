import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:parc_oto/widgets/page_header.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../theme.dart';

class PlanningCalendar extends StatefulWidget {
  const PlanningCalendar({super.key});

  @override
  State<PlanningCalendar> createState() => _PlanningCalendarState();
}

class _PlanningCalendarState extends State<PlanningCalendar> {

  CalendarFormat format =CalendarFormat.month;

  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return ScaffoldPage(
      header: PageTitle(
        text: 'planning'.tr(),
      ),
      content: Material(
        child: TableCalendar(
          focusedDay: focusedDay,
          firstDay: DateTime(2000),
          lastDay: DateTime(focusedDay.year+30),
          locale: appTheme.locale?.languageCode,
          calendarFormat: format,
          weekendDays: const [DateTime.friday,DateTime.saturday],
        
        ),
      ),
    );
  }
}
