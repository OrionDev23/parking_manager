import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/serializables/entretien_vehicle.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../theme.dart';
import '../../../widgets/zone_box.dart';

class EntretienWidget extends StatefulWidget {
  final EntretienVehicle entretienVehicle;
  const EntretienWidget({super.key, required this.entretienVehicle});

  @override
  State<EntretienWidget> createState() => EntretienWidgetState();
}

class EntretienWidgetState extends State<EntretienWidget> {
  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return Container(
      height: 170.px,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          bigSpace,
          bigSpace,
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToggleSwitch(
                content: Text(
                  'Vidange moteur',
                  style: littleStyle,
                ),
                checked: widget.entretienVehicle.vidangeMoteur,
                onChanged: (s) {
                  setState(() {
                    widget.entretienVehicle.vidangeMoteur = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Vidange boite',
                  style: littleStyle,
                ),
                checked: widget.entretienVehicle.vidangeBoite,
                onChanged: (s) {
                  setState(() {
                    widget.entretienVehicle.vidangeBoite = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Vidange pont AV AR',
                  style: littleStyle,
                ),
                checked: widget.entretienVehicle.vidangePont,
                onChanged: (s) {
                  setState(() {
                    widget.entretienVehicle.vidangePont = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Filtre à air',
                  style: littleStyle,
                ),
                checked: widget.entretienVehicle.filtreAir,
                onChanged: (s) {
                  setState(() {
                    widget.entretienVehicle.filtreAir = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Filtre à huile',
                  style: littleStyle,
                ),
                checked: widget.entretienVehicle.filtreHuile,
                onChanged: (s) {
                  setState(() {
                    widget.entretienVehicle.filtreHuile = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Filtre à carburant',
                  style: littleStyle,
                ),
                checked: widget.entretienVehicle.filtreCarburant,
                onChanged: (s) {
                  setState(() {
                    widget.entretienVehicle.filtreCarburant = s;
                  });
                },
              ),
            ],
          ),
          smallSpace,
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToggleSwitch(
                content: Text(
                  "Filtre d'habitacle",
                  style: littleStyle,
                ),
                checked: widget.entretienVehicle.filtreHabitacle,
                onChanged: (s) {
                  setState(() {
                    widget.entretienVehicle.filtreHabitacle = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Liquide de frein',
                  style: littleStyle,
                ),
                checked: widget.entretienVehicle.liquideFrein,
                onChanged: (s) {
                  setState(() {
                    widget.entretienVehicle.liquideFrein = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Liquide de refroidissement',
                  style: littleStyle,
                ),
                checked: widget.entretienVehicle.liquideRefroidissement,
                onChanged: (s) {
                  setState(() {
                    widget.entretienVehicle.liquideRefroidissement = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Equilibrage roues',
                  style: littleStyle,
                ),
                checked: widget.entretienVehicle.equilibrageRoues,
                onChanged: (s) {
                  setState(() {
                    widget.entretienVehicle.equilibrageRoues = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Controle niveaux',
                  style: littleStyle,
                ),
                checked: widget.entretienVehicle.controleNiveaux,
                onChanged: (s) {
                  setState(() {
                    widget.entretienVehicle.controleNiveaux = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Entretien climatisation',
                  style: littleStyle,
                ),
                checked: widget.entretienVehicle.entretienClimatiseur,
                onChanged: (s) {
                  setState(() {
                    widget.entretienVehicle.entretienClimatiseur = s;
                  });
                },
              ),
            ],
          ),
          smallSpace,
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToggleSwitch(
                content: Text(
                  'Balais essuie-glace',
                  style: littleStyle,
                ),
                checked: widget.entretienVehicle.balaisEssuieGlace,
                onChanged: (s) {
                  setState(() {
                    widget.entretienVehicle.balaisEssuieGlace = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Eclairage',
                  style: littleStyle,
                ),
                checked: widget.entretienVehicle.eclairage,
                onChanged: (s) {
                  setState(() {
                    widget.entretienVehicle.eclairage = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'OBD',
                  style: littleStyle,
                ),
                checked: widget.entretienVehicle.obd,
                onChanged: (s) {
                  setState(() {
                    widget.entretienVehicle.obd = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Bougies',
                  style: littleStyle,
                ),
                checked: widget.entretienVehicle.bougies,
                onChanged: (s) {
                  setState(() {
                    widget.entretienVehicle.bougies = s;
                  });
                },
              ),
              bigSpace,
              smallSpace,
              Row(
                children: [
                  Button(
                      onPressed: () => selectAllEntretien(false),
                      child: const Text('clear').tr()),
                  smallSpace,
                  FilledButton(
                      onPressed: () => selectAllEntretien(true),
                      child: const Text('selectall').tr()),
                ],
              ),
            ],
          ),

        ],
      ),
    );
  }

  void selectAllEntretien(bool value) {
    widget.entretienVehicle.vidangeMoteur = value;
    widget.entretienVehicle.vidangeBoite = value;
    widget.entretienVehicle.vidangePont = value;
    widget.entretienVehicle.filtreAir = value;
    widget.entretienVehicle.filtreHuile = value;
    widget.entretienVehicle.filtreCarburant = value;
    widget.entretienVehicle.filtreHabitacle = value;
    widget.entretienVehicle.liquideFrein = value;
    widget.entretienVehicle.liquideRefroidissement = value;
    widget.entretienVehicle.equilibrageRoues = value;
    widget.entretienVehicle.controleNiveaux = value;
    widget.entretienVehicle.entretienClimatiseur = value;
    widget.entretienVehicle.balaisEssuieGlace = value;
    widget.entretienVehicle.eclairage = value;
    widget.entretienVehicle.obd = value;
    widget.entretienVehicle.bougies = value;
    setState(() {});
  }
}
