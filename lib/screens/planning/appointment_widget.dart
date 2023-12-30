import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parc_oto/serializables/planning.dart';
import 'package:parc_oto/theme.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

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
    final Color textColor = appTheme.writingStyle.color!;
    
   return f.Tooltip(
     message: planning.notes??'',
     child: getWidget(planning, mobile, textColor, appTheme),
   );
   
  }
  
  Widget getWidget(Planning planning,bool mobile,Color textColor,AppTheme appTheme){
    if (calendarController.view == CalendarView.timelineDay ||
        calendarController.view == CalendarView.timelineWeek ||
        calendarController.view == CalendarView.timelineWorkWeek ||
        calendarController.view == CalendarView.timelineMonth) {
      final double horizontalHighlight =
      calendarController.view == CalendarView.timelineMonth ? 30 : 50;
      final double cornerRadius = horizontalHighlight / 4;
      return Row(
        children: <Widget>[
          Container(
            width: horizontalHighlight,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(cornerRadius),
                    bottomLeft: Radius.circular(cornerRadius)),
                color: planning.color,
                image: DecorationImage(
                    image: AssetImage(
                        'assets/images/planning/${planning.type}.webp'))),
          ),
          Expanded(
              child: Container(
                  alignment: Alignment.center,
                  color: planning.color?.withOpacity(0.8),
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    planning.subject,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ))),
          Container(
            width: horizontalHighlight,
            decoration: BoxDecoration(
              image: DecorationImage(
                image:
                AssetImage('assets/images/planning/${planning.type}.webp'),
              ),
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(cornerRadius),
                  bottomRight: Radius.circular(cornerRadius)),
              color: planning.color,
            ),
          ),
        ],
      );
    } else if (calendarController.view != CalendarView.month &&
        calendarController.view != CalendarView.schedule) {
      return Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(3),
            height: 50,
            alignment: mobile ? Alignment.topLeft : Alignment.centerLeft,
            decoration: BoxDecoration(
              image: DecorationImage(
                image:
                AssetImage('assets/images/planning/${planning.type}.webp'),
              ),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5), topRight: Radius.circular(5)),
              color: planning.color,
            ),
            child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      planning.subject,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: mobile ? 3 : 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (mobile)
                      Container()
                    else
                      Text(
                        'Time: ${DateFormat('HH:mm').format(planning.startTime)} - '
                            '${DateFormat('HH:mm').format(planning.endTime)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      )
                  ],
                )),
          ),
          Container(
            height: details.bounds.height - 70,
            padding: const EdgeInsets.fromLTRB(3, 5, 3, 2),
            color: planning.color?.withOpacity(0.8),
            alignment: Alignment.topLeft,
            child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Image(
                            image: ExactAssetImage(
                                'assets/images/planning/${planning.type}.webp'),
                            fit: BoxFit.contain,
                            width: details.bounds.width,
                            height: 60)),
                    Text(
                      planning.notes ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    )
                  ],
                )),
          ),
          Container(
            height: 20,
            decoration: BoxDecoration(
              image: DecorationImage(
                image:
                AssetImage('assets/images/planning/${planning.type}.webp'),
              ),

              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5)),
              color: planning.color,
            ),
          ),
        ],
      );
    } else if (calendarController.view == CalendarView.month) {
      final double fontSize =
      details.bounds.height > 12 ? 11 : details.bounds.height - 1;
      return Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 2),
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
            ? Row(
          children: <Widget>[
            Icon(
              Icons.circle,
              color: planning.color,
              size: fontSize,
            ),
            Expanded(
                child: Padding(
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
                    ))),
          ],
        )
            : Row(
          children: <Widget>[
            Icon(
              Icons.circle,
              color: planning.color,
              size: fontSize,
            ),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  planning.isAllDay
                      ? 'All'
                      : DateFormat('HH:mm').format(planning.endTime),
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
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
      );
    }
    final String format =
    (planning.endTime.difference(planning.startTime).inHours < 24)
        ? 'HH:mm'
        : 'dd MMM';
    bool web = kIsWeb && !mobile;

    return Container(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        color: appTheme.backGroundColor,
        child: Row(
          children: <Widget>[
            Container(
              width: 8,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image:
                  AssetImage('assets/images/planning/${planning.type}.webp'),
                ),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    bottomLeft: Radius.circular(3)),
                color: planning.color,
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image:
                    AssetImage('assets/images/planning/${planning.type}.webp'),
                  ),
                  borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(3),
                      bottomRight: Radius.circular(3)),
                ),
                padding: const EdgeInsets.only(left: 7),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          planning.subject + (web ? ', ' : ''),
                          style: TextStyle(
                              color: textColor,
                              fontSize: web ? 15 : 18,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.normal),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (web)
                          Text(
                            planning.location ?? '',
                            style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontFamily: 'Roboto',
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          const Text(''),
                      ],
                    ),
                    Text(
                      '${DateFormat(format).format(planning.startTime)} - ${DateFormat(format).format(planning.endTime)}',
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontFamily: 'Roboto',
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.zero,
              width: 30,
              alignment: Alignment.center,
              child: Image(
                  image: ExactAssetImage('assets/images/planning/${planning.type}.webp'),
                  fit: BoxFit.contain,
                  width: details.bounds.width,
                  height: 20),
            ),
          ],
        ));
  }
}
