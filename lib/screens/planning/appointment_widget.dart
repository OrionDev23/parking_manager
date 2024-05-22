import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:parc_oto/serializables/planning.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../utilities/color_manip.dart';

class AppointmentWidget extends StatelessWidget {
  final CalendarAppointmentDetails details;
  final CalendarController calendarController;

  const AppointmentWidget(
      {super.key, required this.details, required this.calendarController});

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    final Planning planning = details.appointments.first;
    bool mobile = MediaQuery.of(context).orientation == Orientation.portrait;
    const Color textColor = Colors.black;

    return f.Tooltip(
      message: planning.notes ?? '',
      child: getWidget(planning, mobile, textColor, appTheme),
    );
  }

  Widget getWidget(
      Planning planning, bool mobile, Color textColor, AppTheme appTheme) {
    final double fontSize =
        details.bounds.height > 12 ? 12 : details.bounds.height - 1;
    return f.Column(
      children: [
        Container(
          width: details.bounds.width,
          height: details.bounds.height / 2,
          color: ColorManipulation.lighten(ColorManipulation.lighten(
              ColorManipulation.lighten(planning.color ?? Colors.black))),
          child: Center(
            child: Image.asset(
              'assets/images/planning/${planning.type}'
              '.webp',
              fit: BoxFit.fitWidth,
              width: 35.px,
            ),
          ),
        ),
        Container(
          width: details.bounds.width,
          height: details.bounds.height / 2,
          alignment: Alignment.center,
          color: ColorManipulation.lighten(ColorManipulation.lighten(
              ColorManipulation.lighten(planning.color ?? Colors.black))),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
          child: details.isMoreAppointmentRegion
              ? Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    '+ More',
                    style: TextStyle(
                      color: textColor,
                      fontSize: fontSize,
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ))
              : mobile
                  ? Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        planning.subject,
                        style: TextStyle(
                          color: textColor,
                          fontSize: fontSize,
                        ),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ))
                  : Row(
                      children: <Widget>[
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              planning.isAllDay
                                  ? '${'allday'.tr()} :'
                                  : DateFormat('HH:mm')
                                      .format(planning.endTime),
                              style: TextStyle(
                                color: textColor,
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            )),
                        Expanded(
                            child: Text(
                          planning.subject,
                          style: TextStyle(
                            color: textColor,
                            fontSize: fontSize,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
                      ],
                    ),
        ),
      ],
    );
  }
}
