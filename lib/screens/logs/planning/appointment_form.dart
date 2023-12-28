import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';

import '../../../utilities/theme_colors.dart';
import 'color_picker.dart';


class AppointmentForm extends StatefulWidget {

  final DateTime? startDate;
  const AppointmentForm({super.key,this.startDate});

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
    _startDate=widget.startDate??DateTime.now();
    _endDate=DateTime.now().add(const Duration(hours: 2));
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return Container(
        color: Colors.white,
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: <Widget>[
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
              leading: const Text(''),
              title: TextBox(
                controller: TextEditingController(text: _subject),
                onChanged: (String value) {
                  _subject = value;
                },
                placeholder: 'Add title',
                keyboardType: TextInputType.multiline,
                maxLines: null,
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
                leading: const Icon(
                  FluentIcons.buffer_time_before,
                  color: Colors.grey,
                ),
                title: Row(children: <Widget>[
                  const Expanded(
                    child: Text('All day'),
                  ),
                  Expanded(
                      child: Align(
                          alignment: Alignment.centerRight,
                          child: ToggleSwitch(
                            checked: _isAllDay,
                            onChanged: (bool value) {
                              setState(() {
                                _isAllDay = value;
                              });
                            },
                          ))),
                ])),
            ListTile(
                contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                leading: const Text(''),
                title: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        flex: 7,
                        child: DatePicker(
                            selected: _startDate,
                            startDate: DateTime(1900),
                            endDate: DateTime(2100),
                            onChanged: (s){
                                  if(s!=_startDate){
                                      if(s.difference(_endDate).inMilliseconds>0){
                                        _endDate.add(const Duration(hours: 5));
                                      }
                                      setState(() {
                                        _startDate=DateTime(s.year,s.month,s.day,_startDate.hour,_startDate.minute,_startDate.second);
                                      });}
                            },
                      ),),
                      Expanded(
                          flex: 3,
                          child: _isAllDay
                              ? const Text('')
                              : TimePicker(
                            selected: _startDate,
                            onChanged: (s){
                              if(_startDate!=s){
                                if(s.difference(_endDate).inMilliseconds>0){
                                  _endDate.add(const Duration(hours: 5));
                                }
                                setState(() {
                                  _startDate=DateTime(_startDate.year,_startDate.month,_startDate.day,s.hour,s.minute,s.second);
                                });
                              }
                            },

                          )),
                    ])),
            ListTile(
                contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                leading: const Text(''),
                title: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        flex: 7,
                        child: DatePicker(
                          selected: _endDate,
                          startDate: DateTime(1900),
                          endDate: DateTime(2100),
                          onChanged: (s){
                            if(s!=_endDate){
                              if(s.difference(_endDate).inMilliseconds>0){
                                _endDate.add(const Duration(hours: 5));
                              }
                              setState(() {
                                _endDate=DateTime(s.year,s.month,s.day,_endDate.hour,_endDate.minute,_endDate.second);
                              });}
                          },
                        ),),
                      Expanded(
                          flex: 3,
                          child: _isAllDay
                              ? const Text('')
                              : TimePicker(
                            selected: _startDate,
                            onChanged: (s){
                              if(_endDate!=s){
                                if(s.difference(_endDate).inMilliseconds>0){
                                  _endDate.add(const Duration(hours: 5));
                                }
                                setState(() {
                                  _endDate=DateTime(_endDate.year,_endDate.month,_endDate.day,s.hour,s.minute,s.second);
                                });
                              }
                            },

                          )),
                    ])),
            const Divider(
            ),
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
              leading: Icon(FluentIcons.color,
                  color: _colorCollection[_selectedColorIndex]),
              title: Text(
                _colorNames[_selectedColorIndex],
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
            const Divider(
            ),
            ListTile(
              contentPadding: const EdgeInsets.all(5),
              leading: const Icon(
                FluentIcons.add_notes,
                color: Colors.grey,
              ),
              title: TextBox(
                controller: TextEditingController(text: _notes),
                onChanged: (String value) {
                  _notes = value;
                },
                keyboardType: TextInputType.multiline,
                maxLines: null,
                placeholder: 'Add description',
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
        ));
  }
}
