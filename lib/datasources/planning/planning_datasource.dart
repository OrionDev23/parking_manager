import 'dart:ui';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/serializables/planning.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../providers/client_database.dart';

class PlanningDatasource extends CalendarDataSource<Planning> {
  @override
  DateTime getStartTime(int index) {
    return appointments![index].startTime;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].endTime;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].isAllDay;
  }

  @override
  String getSubject(int index) {
    return appointments![index].subject;
  }

  @override
  Color getColor(int index) {
    return appointments![index].color;
  }

  @override
  String? getRecurrenceRule(int index) {
    return appointments![index].recurrenceRule;
  }

  @override
  String? getNotes(int index) {
    return appointments![index].notes;
  }

  @override
  String? getLocation(int index) {
    return appointments![index].location;
  }

  @override
  List<String>? getResourceIds(int index) {
    return appointments![index].resourceIds;
  }

  @override
  String getId(int index) {
    return appointments![index].id;
  }

  PlanningDatasource() {
    appointments = <Planning>[];
  }

  Map<String, Planning> data = {};

  List<Planning> addAppointements() {
    List<Planning> plans = [];
    data.forEach((key, value) {
      if (!alreadyContained(key)) {
        plans.add(value);
      }
    });

    return plans;
  }

  bool alreadyContained(String id) {
    if (appointments == null) {
      return false;
    } else {
      for (Planning p in appointments!) {
        if (p.id == id) {
          return true;
        }
      }
    }

    return false;
  }

  void resetAppointements() {
    List<Planning> plans = [];
    data.forEach((key, value) {
      if (!alreadyContained(key)) {
        plans.add(value);
      }
    });
    appointments!.addAll(plans);
    notifyListeners(CalendarDataSourceAction.reset, appointments!);
  }

  @override
  Future<void> handleLoadMore(DateTime startDate, DateTime endDate) async {
    await DatabaseGetter.database!.listDocuments(
        databaseId: databaseId,
        collectionId: planningID,
        queries: [
          Query.orderAsc('startTime'),
          Query.greaterThanEqual('startTime',
              startDate.difference(DatabaseGetter.ref).inMilliseconds),
          Query.lessThanEqual(
              'endTime', endDate.difference(DatabaseGetter.ref).inMilliseconds),
        ]).then((value) {
      for (var element in value.documents) {
        data[element.$id] = element
            .convertTo((p0) => Planning.fromJson(p0 as Map<String, dynamic>));
      }
      if (value.documents.isNotEmpty) {
        var newOnes = addAppointements();
        appointments!.addAll(newOnes);
        notifyListeners(CalendarDataSourceAction.reset, newOnes);
      } else {
        notifyListeners(CalendarDataSourceAction.add, []);
      }
    }).onError((AppwriteException error, stackTrace) {
      notifyListeners(CalendarDataSourceAction.add, []);
      if (kDebugMode) {
        print('error.message : ${error.message}');
        print('error.response : ${error.response} ');
        print(stackTrace);
      }
    });
  }
}
