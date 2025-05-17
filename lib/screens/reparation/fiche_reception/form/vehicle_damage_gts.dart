import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/serializables/reparation/etat_vehicle_gts.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../theme.dart';
import '../../../../widgets/on_tap_scale.dart';

class VehicleDamageGts extends StatefulWidget {
  final EtatVehicleGTS etatVehicle;
  final int vehicleType;
  const VehicleDamageGts({super.key, required this.etatVehicle, required this.vehicleType,});

  @override
  State<VehicleDamageGts> createState() => _VehicleDamageState();
}

class _VehicleDamageState extends State<VehicleDamageGts> {
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      width: 80.w,
      height: 45.h,
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          topTable(appTheme),
          bigSpace,
          bigSpace,
          bigSpace,
          bigSpace,
          bigSpace,
          Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90.px,
                  height: 40.px,
                  child: Row(
                    children: [
                      const Text(
                        "repare",
                      ).tr(),
                      const Spacer(),
                      Checkbox(
                          checked: widget.etatVehicle.showOnList,
                          onChanged: (s) {
                            widget.etatVehicle.showOnList = s ?? false;
                            setState(() {});
                          })
                    ],
                  ),
                ),
                vehicleDamage(appTheme),
                bigSpace,
                Row(children: [
                  Button(
                      onPressed: () => selectAllVehicleDamage(false),
                      child: const Text('clear').tr()),
                  smallSpace,
                  FilledButton(
                      onPressed: () => selectAllVehicleDamage(true),
                      child: const Text('selectall').tr()),
                ]),
              ]),
        ],
      ),
    );
  }

  void selectAllVehicleDamage(bool value) {


    widget.etatVehicle.marchePieds=value;
    widget.etatVehicle.balEss=value;
    widget.etatVehicle.calottes=value;
    widget.etatVehicle.feuxSign=value;
    widget.etatVehicle.intCab=value;
    widget.etatVehicle.optiqueSign=value;
    widget.etatVehicle.parBrise=value;
    widget.etatVehicle.pareChoAr=value;
    widget.etatVehicle.pareChoAv=value;
    widget.etatVehicle.plaqueArriere=value;
    widget.etatVehicle.plaqueAvant=value;
    widget.etatVehicle.reservoir=value;
    widget.etatVehicle.retroVis=value;
    widget.etatVehicle.rouePnArriere=value;
    widget.etatVehicle.rouePnAvant=value;
    widget.etatVehicle.rouesecours=value;


    setState(() {});
  }

  Widget topTable(AppTheme appTheme) {
    return SizedBox(
      width: 40.w,
      height: 45.h,
      child: Table(
        border: TableBorder.all(borderRadius: BorderRadius.circular(5)),
        columnWidths: {
          0: FixedColumnWidth(6.w),
          1: FixedColumnWidth(6.w),
          2: FixedColumnWidth(4.w),
          3: FixedColumnWidth(4.w),
          4: FixedColumnWidth(11.w),
        },
        children: [

        ],
      ),
    );
  }


  double lightHeight = 25.px;
  double lightWidth = 25.px;

  Widget vehicleDamage(AppTheme appTheme) {
    return SizedBox(
      width: 317.px,
      height: 148.px,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          ///image
          Positioned.fill(
              left: 10.px,
              right: 5.px,
              child: Image.asset(getVehicleImage(),
                  fit: BoxFit.fitWidth, color: appTheme.writingStyle.color)),
        ],
      ),
    );
  }


  String getVehicleImage(){
    switch(widget.vehicleType){
      case 1:return 'assets/images/car.webp';
      case 2:return 'assets/images/truck.webp';
      case 4:return 'assets/images/bus.webp';
      case 9:return 'assets/images/moto.webp';
      default:return 'assets/images/car.webp';
    }
  }


}
