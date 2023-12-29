import 'package:appwrite/appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
import 'package:parc_oto/datasources/planning/planning_datasource.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/serializables/planning.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../utilities/theme_colors.dart';
import 'color_picker.dart';


class AppointmentForm extends StatefulWidget {

  final DateTime? startDate;
  final PlanningDatasource datasource;
  const AppointmentForm({super.key,this.startDate,required this.datasource});


  @override
  State<AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  String _subject='';
  bool _isAllDay=false;
  String? _notes='';
  late DateTime _startDate;

  late DateTime _endDate;

  final List<Color> _colorCollection = ThemeColors.accentColors;
  final List<String> _colorNames = [
    'orange',
    'red',
    'magenta',
    'purple',
    'blue',
    'green'
  ];
  int _selectedColorIndex = 0;

  @override
  void initState() {
    if(widget.startDate!=null){
      _startDate=DateTime(widget.startDate!.year,widget.startDate!.month,widget.startDate!.day,9,0,0);
    }
    else{
      _startDate=DateTime.now();
    }
    _endDate=_startDate.add(const Duration(hours: 2));
    super.initState();
  }


  List<String> categories=[
    'vehicules',
    'prestataires',
    'users',
    'reparations',
    'documents',
    'chauffeurs'
  ];
  int _selectedCategorie=0;

  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return Container(
      decoration: BoxDecoration(
        color: appTheme.backGroundColor,
        borderRadius: BorderRadius.circular(5),
        boxShadow: kElevationToShadow[2]
      ),
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: <Widget>[
                  ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                    leading:Icon(
                      FluentIcons.title,
                      color: appTheme.color.lightest,
                    ),
                    title: TextBox(
                      controller: TextEditingController(text: _subject),
                      onChanged: (String value) {
                        _subject = value;
                      },
                      placeholder: 'addtitle'.tr(),
                      placeholderStyle:placeStyle,
                      maxLength:40,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 25,
                          color: appTheme.writingStyle.color,
                          fontWeight: FontWeight.w400),
                      decoration: BoxDecoration(
                        color: appTheme.fillColor,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                    leading: Row(
                      children: [
                        Icon(FluentIcons.category_classification,
                            color: appTheme.color.lightest),
                        bigSpace,
                        Text('category',style: placeStyle.copyWith(fontWeight: FontWeight.bold)).tr(),
                      ],
                    ),
                    title: ComboBox<int>(
                      items:categories.map((e) => ComboBoxItem<int>(
                          value: categories.indexOf(e),
                          child: Text(e).tr(),
                      )
                      ).toList(),
                      value: _selectedCategorie,
                      onChanged: (s){
                        setState(() {
                          _selectedCategorie=s??0;

                        });
                      },
                    ),
                    onPressed: () {
                      showDialog<Widget>(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) {
                          return ColorPicker(listColors: _colorCollection,colorNames:_colorNames,selectedColorIndex: _selectedColorIndex,setColor: (s){
                            setState(() {
                              _selectedColorIndex=s;
                            });
                          },);
                        },
                      ).then((dynamic value) => setState(() {}));
                    },
                  ),
                  const Divider(),
                  ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                      leading: Icon(
                        FluentIcons.buffer_time_before,
                        color: appTheme.color.lightest,
                      ),
                      title: Row(children: <Widget>[
                         Text('allday',style: placeStyle.copyWith(fontWeight: FontWeight.bold),).tr(),
                        bigSpace,
                        Align(
                            alignment: Alignment.centerRight,
                            child: ToggleSwitch(
                              checked: _isAllDay,
                              onChanged: (bool value) {
                                setState(() {
                                  _isAllDay = value;
                                });
                              },
                            )),
                      ])),
                  ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
              
                      leading: SizedBox(
                          width: 120.px,
                          child: Text('starttime',style: placeStyle.copyWith(fontWeight: FontWeight.bold)).tr()),
                      title: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                              flex: 7,
                              child: DatePicker(
                                locale: appTheme.locale,
                                selected: _startDate,
                                  startDate: DateTime(1900),
                                  endDate: DateTime(2100),
                                  onChanged: (s){
                                        if(s!=_startDate){
                                          _startDate=DateTime(s.year,s.month,s.day,_startDate.hour,_startDate.minute,_startDate.second);

                                          if(s.difference(_endDate).inMilliseconds>0){
                                            _endDate=_startDate.add(const Duration(hours: 2));
                                            }
                                            setState(() {
                                            });}
                                  },
                            ),),
                            const m.VerticalDivider(),
                            Expanded(
                                flex: 3,
                                child: _isAllDay
                                    ? const Text('')
                                    : TimePicker(
                                  hourFormat: HourFormat.HH,
                                  locale: appTheme.locale,
                                  selected: _startDate,
                                  onChanged: (s){
                                    if(_startDate!=s){
                                      _startDate=DateTime(_startDate.year,_startDate.month,_startDate.day,s.hour,s.minute,s.second);
                                      if(s.difference(_endDate).inMilliseconds>0){
                                        _endDate=_startDate.add(const Duration(hours: 2));
                                      }
                                      setState(() {
                                      });
                                    }
                                  },
              
                                )),
                          ])),
                  ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                      leading: SizedBox(
                          width: 120.px,
                          child: Text('endtime',style: placeStyle.copyWith(fontWeight: FontWeight.bold)).tr()),
                      title: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                              flex: 7,
                              child: DatePicker(
                                selected: _endDate,
                                locale: appTheme.locale,
                                startDate: DateTime(1900),
                                endDate: DateTime(2100),
                                onChanged: (s){
                                  if(s!=_endDate){
                                  _endDate=DateTime(s.year,s.month,s.day,_endDate.hour,_endDate.minute,_endDate.second);
                                  if(_startDate.difference(_endDate).inMilliseconds>0){
                                    _endDate=_startDate.add(const Duration(hours: 2));
                                  }
                                  setState(() {
              
                                  });
                                }},
                              ),),
                            const m.VerticalDivider(),
                            Expanded(
                                flex: 3,
                                child: _isAllDay
                                    ? const Text('')
                                    : TimePicker(
                                  locale: appTheme.locale,
              
                                  selected: _endDate,
                                  hourFormat: HourFormat.HH,
                                  onChanged: (s){
                                    if(_endDate!=s){
              
                                        _endDate=DateTime(_endDate.year,_endDate.month,_endDate.day,s.hour,s.minute,s.second);
                                      if(_startDate.difference(_endDate).inMilliseconds>0){
                                        _endDate=_startDate.add(const Duration(hours: 2));
                                      }
                                    setState(() {
                                    });
              
                                    }
                                  },
              
                                )),
                          ])),
                  const Divider(
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                    leading: Row(
                      children: [
                        Icon(FluentIcons.color,
                            color: appTheme.color.lightest),
                        bigSpace,
                        Text('color',style: placeStyle.copyWith(fontWeight: FontWeight.bold)).tr(),
                      ],
                    ),
                    title: Text(
                      _colorNames[_selectedColorIndex],
                    ).tr(),
                    onPressed: () {
                      showDialog<Widget>(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) {
                          return ContentDialog(
                            constraints: BoxConstraints.loose(Size(
                              300.px,300.px
                            )),
                            content: ColorPicker(listColors: _colorCollection,colorNames:_colorNames,selectedColorIndex: _selectedColorIndex,setColor: (s){
                              setState(() {
                                _selectedColorIndex=s;
                              });
                            },),
                          );
                        },
                      ).then((dynamic value) => setState(() {}));
                    },
                  ),
                  const Divider(
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.all(5),
                    leading: Icon(
                      FluentIcons.add_notes,
                      color: appTheme.color.lightest,
                    ),
                    title: TextBox(
                      controller: TextEditingController(text: _notes),
                      onChanged: (String value) {
                        _notes = value;
                      },
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      placeholder: 'adddescription'.tr(),
                      maxLength: 200,
                      style: TextStyle(
                          fontSize: 18,
                          color: appTheme.writingStyle.color,
                          fontWeight: FontWeight.w400),
                      decoration: BoxDecoration(
                       color: appTheme.fillColor,
                      ),
                    ),
                  ),
                  const Divider(
              
                  ),
                ],
              ),
            ),
            bigSpace,
            FilledButton(onPressed: sumbmiting?null:submit, child: sumbmiting?const ProgressRing():const Text('confirmer').tr()),

          ],
        ));
  }


  bool sumbmiting=false;

  String? documentID;

  void submit()async {
    if(_subject.isEmpty){
      showMessage('subjectrequired', 'erreur');
      return;
    }
    setState(() {
      sumbmiting=true;
    });
    documentID??=DateTime.now().difference(ClientDatabase.ref).inMilliseconds.abs().toString();
    Planning planning=Planning(
        id: documentID!,
        subject: _subject,
        startTime: _startDate, endTime: _endDate,
        notes: _notes,
        color: _colorCollection[_selectedColorIndex],
        createdBy: ClientDatabase.me.value?.id,
        isAllDay: _isAllDay,
        type: _selectedCategorie
    );
    await ClientDatabase.database!.createDocument(
        databaseId: databaseId,
        collectionId: planningID,
        documentId: documentID!,
        data: planning.toJson(),
        permissions: [
          Permission.delete(Role.user(ClientDatabase.me.value!.id)),
          Permission.update(Role.user(ClientDatabase.me.value!.id)),
        ]
    ).then((value) {
      widget.datasource.appointments!.add(planning);
      widget.datasource.notifyListeners(CalendarDataSourceAction.add, [planning]);
      Navigator.pop(context);
    }).onError((error, stackTrace) {
      setState(() {
        showMessage('erreur','erreur');
        sumbmiting=false;
      });
    });

  }

  void showMessage(String message, String title) {
    showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(title).tr(),
        content: Text(
          message,
        ).tr(),
        actions: [
          Button(
            child: const Text('OK').tr(),
            onPressed: () async {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

}
