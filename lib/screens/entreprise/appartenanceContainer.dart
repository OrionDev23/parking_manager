import 'package:appwrite/appwrite.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/vehicle/manager/vehicle_tabs.dart';
import 'package:parc_oto/utilities/vehicle_util.dart';
import 'package:parc_oto/widgets/on_tap_scale.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../theme.dart';
import '../../main.dart';
import '../sidemenu/pane_items.dart';
import '../sidemenu/sidemenu.dart';
import '../vehicle/manager/vehicles_table.dart';
import 'entreprise.dart';
import 'fililales.dart';

class AppartenanceContainer extends StatefulWidget {
  final String fieldToSearch;
  final int type;
  final String name;

  final MesFillialesState state;

  const AppartenanceContainer(
      {super.key,
        required this.state,
      this.type = 0,
      required this.fieldToSearch,
      required this.name});

  @override
  State<AppartenanceContainer> createState() => _AppartenanceContainerState();
}

class _AppartenanceContainerState extends State<AppartenanceContainer> {
  bool loading = true;
  int? vCount;

  @override
  void initState() {
    getCount();
    super.initState();
  }

  void getCount() async {
    await ClientDatabase.database!.listDocuments(
        databaseId: databaseId,
        collectionId: vehiculeid,
        queries: [
          Query.equal(widget.fieldToSearch, widget.name.replaceAll(' ', '').toUpperCase()),
          Query.limit(1),
        ]).then((value) {
      vCount = value.total;
    });
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return OnTapScaleAndFade(
      child: Container(
        width: 200.px,
        height: 70.px,
        decoration: BoxDecoration(
            borderRadius:BorderRadius.circular(5),
            color: appTheme.backGroundColor,
            boxShadow: kElevationToShadow[2]),
        child: Column(
          children: [
            if (widget.type==0)
              AutoSizeText(
                VehiclesUtilities.getAppartenance(widget.name),
                style:
                    TextStyle(color: appTheme.color.lightest),
              ),
            if (widget.type==1)
              AutoSizeText(
                VehiclesUtilities.getDirection(widget.name),
                style:
                    TextStyle(color: appTheme.color.lightest),
              ),
            if (widget.type==2)
              AutoSizeText(
                VehiclesUtilities.getDepartment(widget.name),
                style:
                TextStyle(color: appTheme.color.lightest),
              ),
              const Spacer(),
            Container(
              padding: const EdgeInsets.all(5),
                  child:  Row(
                children: [
                  loading
                      ? const Text('')
                      : Text(
                          '$vCount ${'vehicules'.tr()}',
                          style: appTheme.writingStyle,
                        ),
                  const Spacer(),
                  Button(onPressed: confirmDelete,child: const Icon(FluentIcons.delete,),),
                ],
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        PanesListState.index.value = PaneItemsAndFooters.originalItems
                .indexOf(PaneItemsAndFooters.vehicles) +
            1;
        VehicleTabsState.currentIndex.value = 0;
        VehicleTableState.filterNow = true;
        VehicleTableState.filterVehicule.value =
            '"${widget.name.replaceAll(' ', '').toUpperCase()}"';
      },
    );
  }



  void confirmDelete(){
    showDialog(
        context: widget.state.context,
        barrierDismissible: true,
        builder: (c) {
          return ContentDialog(
            constraints: BoxConstraints.loose(Size(300.px, 150.px)),
            content: Text('confirmsuppr',style:TextStyle(fontSize: 16.px)).tr(),
            actions: [
              Button(child:const Text('fermer').tr(),onPressed:(){
                Navigator.of(context).pop();
              }),
              FilledButton(onPressed: delete, child: const Text('confirmer').tr())
            ],
          );
        });
  }

  void delete() async{

    Navigator.of(widget.state.context).pop();
    if(widget.type==1){
      if(MyEntrepriseState.p!.directions==null){
        MyEntrepriseState.p!.directions=[];
      }
      MyEntrepriseState.p!.directions!.remove(widget.name);
    }
    else if(widget.type==0){
      if(MyEntrepriseState.p!.filiales==null){
        MyEntrepriseState.p!.filiales=[];
      }
      MyEntrepriseState.p!.filiales!.remove(widget.name);
    }
    else if(widget.type==2){
      if(MyEntrepriseState.p!.departments==null){
        MyEntrepriseState.p!.departments=[];
      }
      MyEntrepriseState.p!.departments!.remove(widget.name);
    }
    await ClientDatabase.database!
        .updateDocument(
        databaseId: databaseId,
        collectionId: entrepriseid,
        documentId: MyEntrepriseState.p!.id,
        data: {
          if(widget.type==1)
            'directions':MyEntrepriseState.p!.directions,
          if(widget.type==0)
            'filiales':MyEntrepriseState.p!.filiales,
          if(widget.type==2)
            'departments':MyEntrepriseState.p!.departments,
        })
        .then((value) {
      displayMessage(widget.state.context,'done',InfoBarSeverity.success);
      widget.state.setState(() {

      });
    }).onError((AppwriteException error, stackTrace) {
      displayMessage(widget.state.context,'error',InfoBarSeverity.error);
    });

  }
}
