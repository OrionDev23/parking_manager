
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../../../providers/client_database.dart';
import '../manager/vehicles_table.dart';
import '../../../widgets/zone_box.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../serializables/vehicle/document_vehicle.dart';
import '../../../serializables/vehicle/vehicle.dart';
import '../../../theme.dart';

class DocumentForm extends StatefulWidget {

  final DocumentVehicle? vd;
  final Vehicle? vehicle;
  const DocumentForm({super.key, this.vd, this.vehicle});

  @override
  DocumentFormState createState() => DocumentFormState();
}

class DocumentFormState extends State<DocumentForm> with AutomaticKeepAliveClientMixin<DocumentForm>{


  DateTime? selectedDate;
  TextEditingController nom=TextEditingController();

  Vehicle? selectedVehicle;

  String? documentID;


  bool loadingVehicle=false;
  @override
  void initState() {
    initValues();
    super.initState();
  }

  void initValues(){
    if(widget.vd!=null){
      nom.text=widget.vd!.nom;
      documentID=widget.vd!.id;
      selectedDate=widget.vd!.dateExpiration;
    if(widget.vd!.vehicle!=null) {
        downloadVehicle(widget.vd!.vehicle!);
      }
    }
    else if(widget.vehicle!=null){
      selectedVehicle=widget.vehicle;
    }
    documentID??=DateTime.now().difference(ClientDatabase.ref).inMilliseconds.toString();
  }


  void downloadVehicle(String id)async{
    loadingVehicle=true;
    await ClientDatabase.database!.getDocument(
        databaseId: databaseId,
        collectionId: vehiculeid,
        documentId: id).then((value) {
          if(value.data.isNotEmpty){
            selectedVehicle=value.convertTo((p0) => Vehicle.fromJson(p0 as Map<String,dynamic>));
          }
    });
    if(mounted){
      setState(() {
        loadingVehicle=false;
      });
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
                  title: Text(selectedVehicle?.matricule??widget.vehicle?.matricule??widget.vd?.vehiclemat??'/'),
                  onPressed: widget.vehicle!=null || loadingVehicle || widget.vd?.vehicle!=null ?null:() async{
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
                    checkForChanges();
                  },
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
                  onChanged: (s){
                    checkForChanges();
                  },
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
                      checkForChanges();
                  },

                ),
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
            FilledButton(onPressed:changes?()=>confirm(appTheme):null, child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 5),
              child: uploading?const ProgressRing():const Text('confirmer',).tr(),
            )),
          ],),
        ),

      ],
    );
  }

  @override
  bool get wantKeepAlive => true;


  bool changes=false;
  bool uploading=false;
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
      if(selectedVehicle!=null){
        if(!changes){
          setState(() {
            changes=true;
          });
        }
        return;
      }
      if(selectedDate!=widget.vd?.dateExpiration)
    {
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
  void confirm(AppTheme appTheme)async{
    checkForChanges();
    if(changes){
      setState(() {
        uploading=true;
      });

      DocumentVehicle dv=DocumentVehicle(id: documentID!, nom: nom.text,vehicle: selectedVehicle?.id,
          vehiclemat:selectedVehicle?.matricule,
          dateExpiration: selectedDate,
      createdBy: ClientDatabase.me.value?.id);
      if(widget.vd!=null){
        await ClientDatabase.database!.updateDocument(
            databaseId: databaseId,
            collectionId: vehicDoc,
            documentId: documentID!,
            data: dv.toJson()
        );
        ClientDatabase().ajoutActivity(8, documentID!,docName: selectedVehicle?.matricule);

      }
      else{
        await ClientDatabase.database!.createDocument(
            databaseId: databaseId,
            collectionId: vehicDoc,
            documentId: documentID!,
            data: dv.toJson()
        );
        ClientDatabase().ajoutActivity(7, documentID!,docName: selectedVehicle?.matricule);

      }


      setState(() {
        changes=false;
        uploading=false;
      });

      Future.delayed(Duration.zero).whenComplete(() {
        displayInfoBar(context,
            builder: (BuildContext context, void Function() close) {
              return InfoBar(
                  title: const Text('done').tr(),
                  severity: InfoBarSeverity.success,
                  style: InfoBarThemeData(
                      iconColor: (c){
                        switch(c){
                          case InfoBarSeverity.success :return appTheme.color.lightest;
                          case InfoBarSeverity.error: return appTheme.color.darkest;
                          case InfoBarSeverity.info:return appTheme.color;
                          default: return appTheme.color;
                        }})
              );
            },
            duration: snackbarShortDuration);
        Future.delayed(snackbarShortDuration).whenComplete(() {

          if(widget.vehicle!=null){
         Navigator.pop(context);
        }
        else{

        }
      });});
    }
  }
}
