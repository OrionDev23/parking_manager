import 'dart:io';

import 'package:dzair_data_usage/langs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/theme.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../serializables/vehicle/vehicle.dart';
import '../utilities/algeria_lists.dart';
import '../utilities/vehicle_util.dart';

class ImportVehicles extends StatefulWidget {

  final FilePickerResult file;
  const ImportVehicles({super.key, required this.file});

  @override
  State<ImportVehicles> createState() => _ImportVehiclesState();
}

class _ImportVehiclesState extends State<ImportVehicles> {

  bool loading=true;
  double progressLoadingFile=0;

  @override
  void initState() {
    loadFile();
    super.initState();
  }
  Map<String,Vehicle> importedVehicles={};
  Map<String,int> columnToRead={};

  bool invalidFile=false;
  void loadFile() async{
    if(!loading){
      setState(() {
        loading=true;
      });
    }
    Uint8List? bytes=widget.file.files.first.bytes;
    if(kIsWeb){
      bytes= widget.file.files.first.bytes;
    }
    else{
      bytes=await File(widget.file.files.single.path!).readAsBytes();
    }
    if(bytes!=null){
      setState(() {
        progressLoadingFile=10;
      });
      var excel = Excel.decodeBytes(bytes);
      for (var table in excel.tables.keys) {
        setState(() {
          progressLoadingFile+=80/(excel.tables.length);
        });
        if(isFileValid(excel,table)){
          for (var row in excel.tables[table]!.rows) {
            addVehicle(row);
          }
        }
        else{
          invalidFile=true;
          break;
        }
      }
    }

    setState(() {
      progressLoadingFile=100;
      loading=false;
    });
  }

  void addVehicle(List<Data?> data){

    String matricule=data[columnToRead['mat']!]!.value.toString().replaceAll(' ', '').trim();
    if(matricule.contains('matricul')|| (!matricule.contains('-') && int.tryParse(matricule)==null)){
      return;
    }
    bool etrang=matricule.split('-').length!=3;
    String id=data[columnToRead['numero']!]!.value.toString();
    int etat=getEtat(data[columnToRead['etat']!]!.value.toString());
    String model=data[columnToRead['model']!]!.value.toString();
    String nom=data[columnToRead['nom']!]!.value.toString();
    String prenom=data[columnToRead['prenom']!]!.value.toString();

    List<String> ms=matricule.split('-');
    int? wilaya=etrang?null:int.tryParse(ms[2])??16;
    Vehicle vehicle=
    Vehicle(id: id,
        matricule: matricule,
        matriculeEtrang: etrang,
      etatactuel: etat,
      nom: nom,
      prenom: prenom,
      type: model,
      wilaya: etrang?null:wilaya,
      daira: etrang?null:AlgeriaList().getDairas(AlgeriaList().getWilayaByNum(wilaya.toString())??'').firstOrNull?.getDairaName(
          Language
          .FR)??'',
      commune:etrang?null: AlgeriaList().getCommune(AlgeriaList().getWilayaByNum(wilaya.toString())??'').firstOrNull?.getDairaName(
        Language
            .FR)??'',
      genre:(etrang?1:(int.tryParse(ms[1])??100)~/100).toString(),
      anneeUtil: VehiclesUtilities.getAnneeFromMatricule(matricule)

    );

    importedVehicles[vehicle.matricule]=vehicle;
  }




  int getEtat(String etats){
    int etat=0;
    switch(etats.toLowerCase()){
      case 'en marche':
        etat=3;
        break;
      case 'disponible':
        etat=0;
        break;
      case 'libre':
        etat=0;
        break;
      case 'en panne':
        etat=1;
        break;
      case 'panne':
        etat=1;
        break;
      case 'reforme':
        etat=4;
        break;
      case 'garage':
        etat=2;
        break;
      case 'en reparation':
        etat=2;
        break;
      case 'en garage':
        etat=2;
        break;
      case 'reparation':
        etat=2;
        break;
    }
    return etat;
  }

  bool isFileValid(Excel excel,String table){
    bool foundMatric=false;

    for (var row in excel.tables[table]!.rows) {
      for(var cell in row){
        if(cell?.value!=null){

          switch(cell?.value){
            case null:break;
            case FormulaCellValue():
              break;
            case IntCellValue():
              break;

            case DoubleCellValue():
              break;

            case DateCellValue():
              break;

            case TextCellValue():
              final value=cell!.value as TextCellValue;
            if(value.value.toLowerCase().contains('matricul') && !foundMatric){
              columnToRead['mat']=cell.columnIndex;
              foundMatric=true;
            }

            if(value.value.toLowerCase()=='model'){
              columnToRead['model']=cell.columnIndex;
            }
              if(value.value.toLowerCase()=='n'){
                columnToRead['numero']=cell.columnIndex;
              }
              if(value.value.toLowerCase().contains('état') ||value.value.toLowerCase().contains('etat')||value.value.toLowerCase().contains('state')   ){
                columnToRead['etat']=cell.columnIndex;
              }
              if(value.value.toLowerCase().contains('nom') ||value.value.toLowerCase().contains('familyname')  ||value.value.toLowerCase().replaceAll(' ','').contains('secondname')){
                columnToRead['nom']=cell.columnIndex;
              }
              if(value.value.toLowerCase().contains('prenom') ||value.value.toLowerCase().contains('prénom')  ||value.value.toLowerCase().replaceAll(' ','').contains('firstname')){
                columnToRead['prenom']=cell.columnIndex;
              }
            case BoolCellValue():
              break;

            case TimeCellValue():
              break;

            case DateTimeCellValue():
              break;

          }
        }

      }
      if(foundMatric){
        break;
      }
    }

    return foundMatric;
  }
  @override
  Widget build(BuildContext context) {
    return ContentDialog(
        title: const Text("importlist").tr(),
        constraints: BoxConstraints.loose(Size(600.px, 500.px)),
        content: loading? Center(child: ProgressBar(value: progressLoadingFile,),):invalidFile?invalidFileWidget():getList(),
        actions: [
          Button(child: const Text('annuler').tr(), onPressed: (){
            Navigator.of(context).pop();
          }),
          FilledButton(onPressed: loading||invalidFile?null:(){}, child: const Text('confirmer').tr())
        ],
    );
  }



  bool? selectAll=false;
  Widget getList(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('selectimport',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14.sp),).tr(),
        bigSpace,
        SizedBox(
          height: 30.px,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Checkbox(
                checked: selectAll,
                onChanged: (s){
                  setState(() {
                    selectAll=s??false;
                  });
                  selectAllVehicles();
                },
                content: const Text('selectall').tr(),
                ),
            const Text('lselection').tr(namedArgs: {'select':getNumberOfSelected().toString()})
          ],),
        ),
        Flexible(
          child: ListView(
            children: importedVehicles.entries.map((e) =>
                ListTile.selectable(
                  selected: e.value.selected,
                  onSelectionChange: (s){
                    setState(() {
                      e.value.selected=s;
                    });
                  },
                  trailing: Checkbox(
                    checked: e.value.selected,
                    onChanged: (bool? value) {
                      setState(() {
                        e.value.selected=value??false;
                      });
                    },
                  ),
                  title: Text(e.value.type??''),
                  leading: Text(e.value.matricule),
                )).toList(),
          ),
        ),
      ],
    );
  }

  Widget invalidFileWidget(){
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(FluentIcons.error,color: Colors.grey[100],),
          smallSpace,
          const Text('invalidvehiclefile',
            textAlign: TextAlign.justify,
            style: TextStyle(
              wordSpacing: 2,

            ),).tr(),
        ],
      ),
    );
  }



  void selectAllVehicles(){
    importedVehicles.forEach((key, value) {
      value.selected=selectAll??false;
    });

    setState(() {

    });
  }

  void checkSelection(){
    bool? firstSelection;

    importedVehicles.forEach((key, value) {
      if(firstSelection==null){
        firstSelection=value.selected;
      }
      else{
        if(value.selected!=firstSelection){
          selectAll=null;
          return;
        }

      }
    });

    setState(() {

    });
  }


  int getNumberOfSelected(){
    int result=0;
    importedVehicles.forEach((key, value) {
      if(value.selected){
        result++;
      }
    });
    return result;
  }
}
