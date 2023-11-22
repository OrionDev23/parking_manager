
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/vehicle/vehicles_table.dart';
import 'package:parc_oto/serializables/document_vehicle.dart';
import 'package:parc_oto/widgets/zone_box.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../serializables/vehicle.dart';
import '../../../theme.dart';

class DocumentForm extends StatefulWidget {

  final DocumentVehicle? vd;
  final Vehicle? v;
  const DocumentForm({super.key, this.vd, this.v});

  @override
  DocumentFormState createState() => DocumentFormState();
}

class DocumentFormState extends State<DocumentForm> with AutomaticKeepAliveClientMixin<DocumentForm>{


  DateTime selectedDate=DateTime.now();
  TextEditingController nom=TextEditingController();

  Vehicle? selectedVehicle;

  String? documentID;

  @override
  void initState() {
    initValues();
    super.initState();
  }

  void initValues(){
    if(widget.vd!=null){
      nom.text=widget.vd!.nom;
      documentID=widget.vd!.id;
      selectedVehicle=widget.v;
      if(widget.vd!.dateExpiration!=null) {
        selectedDate=ClientDatabase.ref.add(Duration(milliseconds: widget.vd!.dateExpiration??0));
      }
    }
    if(widget.v!=null){
      selectedVehicle=widget.v;
    }
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    var appTheme=context.watch<AppTheme>();
    return  Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
      SizedBox(height: 10.h,),
      Container(
      decoration: BoxDecoration(
        color: appTheme.backGroundColor,
      boxShadow: kElevationToShadow[2],
        borderRadius: BorderRadius.circular(10)
      ),
      padding: const EdgeInsets.all(10),
      width: 30.w,
      height: 40.h,
        child:Column(children: [
          Flexible(
            child: ZoneBox(
              label:'vehicule'.tr(),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: ListTile(
                  title: Text(selectedVehicle?.matricule??'/'),
                  onPressed: widget.v==null?() async{
                    selectedVehicle=await showDialog<Vehicle>(context: context,
                        barrierDismissible: true,
                        builder: (context){
                          return  ContentDialog(
                            constraints: BoxConstraints.tight(Size(
                              60.w,60.h
                            )),
                            title: const Text('selectvehicle').tr(),
                            style: ContentDialogThemeData(
                              titleStyle: appTheme.writingStyle.copyWith(fontWeight: FontWeight.bold)
                            ),
                            content: Container(
                                color: appTheme.backGroundColor,
                                width: 60.w,
                                height: 60.h,
                                child: const VehicleTable(selectV: true,)
                            ),
                          );
                        }
                    );
                    setState(() {

                    });
                  }:null,
                ),
              ),
            ),
          ),
          smallSpace,
          smallSpace,
          Flexible(
            child: ZoneBox(
              label:'nom'.tr(),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextBox(
                  controller: nom,
                  style: appTheme.writingStyle,
                  decoration: BoxDecoration(color: appTheme.fillColor),
                  cursorColor: appTheme.color.darker,
                  placeholderStyle: placeStyle,
                  placeholder: 'nom'.tr(),
                ),
              ),
            ),
          ),
          smallSpace,
          smallSpace,
          Flexible(
            child: ZoneBox(
              label: 'dateexp'.tr(),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: DatePicker(
                  selected: selectedDate,
                  onChanged: (d){
                    setState(() {
                      selectedDate=d;
                    });
                  },),
              ),
            ),
          )
        ],)),
        smallSpace,
        smallSpace,
        smallSpace,
        SizedBox(
          width: 30.w,
          child: Row(mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 5),
              child: const Text('confirmer',).tr(),
            ), onPressed: (){}),
          ],),
        ),

      ],
    );
  }

  @override
  bool get wantKeepAlive => true;


  bool changes=false;
  void checkForChanges(){
    if(widget.vd!=null){
      if(nom.text.isNotEmpty && nom.text!=widget.vd!.nom){
        if(!changes){
          setState(() {
            changes=true;
          });
        }
        return;
      }
    }
    else{
      if(nom.text.isNotEmpty){
        if(!changes) {
          setState(() {
          changes=true;
        });
          return;
        }
      }
    }
  }
  void confirm()async{

  }
}
