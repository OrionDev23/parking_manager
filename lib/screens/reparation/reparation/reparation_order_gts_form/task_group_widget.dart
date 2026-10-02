import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../serializables/reparation/task_group.dart';

class TaskGroupWidget extends StatefulWidget {
  final TaskGroup taskGroup;

  const TaskGroupWidget({super.key,required this.taskGroup});

  @override
  State<TaskGroupWidget> createState() => _TaskGroupWidgetState();
}



class _TaskGroupWidgetState extends State<TaskGroupWidget> {
  double rowHeight=50.px;

  double time=0.0;
  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return SizedBox(
      height: rowHeight*(widget.taskGroup.tasks.length+1)+10.px,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: appTheme.color.darkest),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              width: 200.px,
              height: 35.px,
              child: FilledButton(child: Text('addtask').tr(), onPressed: (){
                setState(() {
                  widget.taskGroup.tasks.add('');
                });
              }),
            ),
            smallSpace,
            Flexible(
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(5),
                  2: FlexColumnWidth(1)
                },
                children:[
                  TableRow(
                    children: [
                      TableCell(
                        child: Container(
                          padding: EdgeInsets.all(5),
                          height: rowHeight,
                          child: TextBox(
                            controller: TextEditingController(text: widget.taskGroup.numero),
                            placeholderStyle: placeStyle,
                            placeholder: 'numero'.tr(),
                            onChanged: (s){
                              widget.taskGroup.numero=s;
                            },
                          ),
                        ),
                      ),
                      TableCell(
                        child: Container(
                          padding: EdgeInsets.all(5),
                          height: rowHeight,
                          child: TextBox(
                            controller: TextEditingController(text: widget.taskGroup.tasks.first),
                            placeholderStyle: placeStyle,
                            placeholder: 'desi'.tr(),
                            onChanged: (s){
                              widget.taskGroup.tasks.first=s;
                            },
                          ),
                        ),
                      ),
                      TableCell(
                        child: Container(
                          padding: EdgeInsets.all(5),
                          height: rowHeight,
                          child: NumberBox<double>(
                            value: time,
                            clearButton: false,
                            smallChange: 0.05,
                            largeChange: 0.1,
                            min: 0.00,
                            max: 1.00,
                            mode: SpinButtonPlacementMode.none,
                            placeholderStyle: placeStyle,
                            placeholder: '0.00',
                            onChanged: (s){
                              widget.taskGroup.time=s??0.00;
                            },
                          ),
                        ),
                      ),
                    ]
                  ),
                  ...taskList(appTheme)
                ]
              ),
            ),
          ],
        ),
      ),
    );
  }
  List<TableRow> taskList(AppTheme appTheme){
    List<TableRow> rows=[];
    for(int i=1;i<widget.taskGroup.tasks.length;i++){
      rows.add(TableRow(
        children: [
          SizedBox(width:5),
          Container(
            padding: EdgeInsets.all(5),
            height: rowHeight,
            child: TextBox(
              controller: TextEditingController(text: widget.taskGroup.tasks[i]),
              placeholderStyle: placeStyle,
              placeholder: 'desi'.tr(),
              onChanged: (s){
                widget.taskGroup.tasks[i]=s;
              },
            ),
          ),
          SizedBox(child: IconButton(icon: Icon(Icons.delete,color: appTheme.color,size: 20), onPressed: (){
            widget.taskGroup.tasks.removeAt(i);
            setState(() {

            });
          }),),
        ]
      ));
    }
    return rows;
  }



}
