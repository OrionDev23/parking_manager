import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/serializables/reparation/entretien_vehicle.dart';

import '../../../../theme.dart';

class EntretienWidget extends StatefulWidget {
  final EntretienVehicle entretienVehicle;

  const EntretienWidget({super.key, required this.entretienVehicle});

  @override
  State<EntretienWidget> createState() => EntretienWidgetState();
}

class EntretienWidgetState extends State<EntretienWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        bigSpace,
        bigSpace,
        firstColumn(),
        smallSpace,
        secondColumn(),
        smallSpace,
        thirdColumn(),
      ],
    );
  }

  Widget firstColumn(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ToggleSwitch(
          content: Text(
            'vidangeMoteur',
            style:littleStyle,).tr(),
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
            'vidangeBoite',
            style:littleStyle,).tr(),
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
            'vidangePont',
            style:littleStyle,).tr(),
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
            'filtreAir',
            style:littleStyle,).tr(),
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
            'filtreHuile',
            style:littleStyle,).tr(),
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
            'filtreCarburant',
            style:littleStyle,).tr(),
          checked: widget.entretienVehicle.filtreCarburant,
          onChanged: (s) {
            setState(() {
              widget.entretienVehicle.filtreCarburant = s;
            });
          },
        ),
        smallSpace,
        ToggleSwitch(
          content: Text(
            "filtreHabitacle",
            style:littleStyle,).tr(),
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
            'liquideFrein',
            style:littleStyle,).tr(),
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
            'liquideRefroidissement',
            style:littleStyle,).tr(),
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
            'liquideTransmission',
            style:littleStyle,).tr(),
          checked: widget.entretienVehicle.liquideTransmission,
          onChanged: (s) {
            setState(() {
              widget.entretienVehicle.liquideTransmission = s;
            });
          },
        ),
      ],
    );
  }
  Widget secondColumn(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ToggleSwitch(
          content: Text(
            'systemSuspension',
            style:littleStyle,).tr(),
          checked: widget.entretienVehicle.systemSuspension,
          onChanged: (s) {
            setState(() {
              widget.entretienVehicle.systemSuspension = s;
            });
          },
        ),
        smallSpace,
        ToggleSwitch(
          content: Text(
            'systemFreinage',
            style:littleStyle,).tr(),
          checked: widget.entretienVehicle.systemFreinage,
          onChanged: (s) {
            setState(() {
              widget.entretienVehicle.systemFreinage = s;
            });
          },
        ),
        smallSpace,
        ToggleSwitch(
          content: Text(
            'inspectionAmortisseurs',
            style:littleStyle,).tr(),
          checked: widget.entretienVehicle.inspectionAmortisseurs,
          onChanged: (s) {
            setState(() {
              widget.entretienVehicle.inspectionAmortisseurs = s;
            });
          },
        ),
        smallSpace,
        ToggleSwitch(
          content: Text(
            'bougies',
            style:littleStyle,).tr(),
          checked: widget.entretienVehicle.bougies,
          onChanged: (s) {
            setState(() {
              widget.entretienVehicle.bougies = s;
            });
          },
        ),
        smallSpace,
        ToggleSwitch(
          content: Text(
            'equilibrageRoues',
            style:littleStyle,).tr(),
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
            'controleNiveaux',
            style:littleStyle,).tr(),
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
            'changerPneux',
            style:littleStyle,).tr(),
          checked: widget.entretienVehicle.changerPneux,
          onChanged: (s) {
            setState(() {
              widget.entretienVehicle.changerPneux = s;
            });
          },
        ),
        smallSpace,
        ToggleSwitch(
          content: Text(
            'differentielAvAr',
            style:littleStyle,).tr(),
          checked: widget.entretienVehicle.differentielAvAr,
          onChanged: (s) {
            setState(() {
              widget.entretienVehicle.differentielAvAr = s;
            });
          },
        ),
        smallSpace,
        ToggleSwitch(
          content: Text(
            'tuyaux',
            style:littleStyle,).tr(),
          checked: widget.entretienVehicle.tuyaux,
          onChanged: (s) {
            setState(() {
              widget.entretienVehicle.tuyaux = s;
            });
          },
        ),
        smallSpace,
        ToggleSwitch(
          content: Text(
            'echappement',
            style:littleStyle,).tr(),
          checked: widget.entretienVehicle.echappement,
          onChanged: (s) {
            setState(() {
              widget.entretienVehicle.echappement = s;
            });
          },
        ),
      ],
    );
  }

  Widget thirdColumn(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ToggleSwitch(
          content: Text(
            'batterie',
            style:littleStyle,).tr(),
          checked: widget.entretienVehicle.batterie,
          onChanged: (s) {
            setState(() {
              widget.entretienVehicle.batterie = s;
            });
          },
        ),
        smallSpace,
        ToggleSwitch(
          content: Text(
            'courroies',
            style:littleStyle,).tr(),
          checked: widget.entretienVehicle.courroies,
          onChanged: (s) {
            setState(() {
              widget.entretienVehicle.courroies = s;
            });
          },
        ),
        smallSpace,
        ToggleSwitch(
          content: Text(
            'eclairage',
            style:littleStyle,).tr(),
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
            'cire',
            style:littleStyle,).tr(),
          checked: widget.entretienVehicle.cire,
          onChanged: (s) {
            setState(() {
              widget.entretienVehicle.cire = s;
            });
          },
        ),
        smallSpace,
        ToggleSwitch(
          content: Text(
            'entretienClimatiseur',
            style:littleStyle,).tr(),
          checked: widget.entretienVehicle.entretienClimatiseur,
          onChanged: (s) {
            setState(() {
              widget.entretienVehicle.entretienClimatiseur = s;
            });
          },
        ),
        smallSpace,
        ToggleSwitch(
          content: Text(
            'balaisEssuieGlace',
            style:littleStyle,).tr(),
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
            'obd',
            style:littleStyle,).tr(),
          checked: widget.entretienVehicle.obd,
          onChanged: (s) {
            setState(() {
              widget.entretienVehicle.obd = s;
            });
          },
        ),
        const Spacer(),

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
    widget.entretienVehicle.systemSuspension=value;
    widget.entretienVehicle.systemFreinage=value;
    widget.entretienVehicle.tuyaux=value;
    widget.entretienVehicle.batterie=value;
    widget.entretienVehicle.changerPneux=value;
    widget.entretienVehicle.cire=value;
    widget.entretienVehicle.courroies=value;
    widget.entretienVehicle.differentielAvAr=value;
    widget.entretienVehicle.echappement=value;
    widget.entretienVehicle.inspectionAmortisseurs=value;
    widget.entretienVehicle.liquideTransmission=value;
    setState(() {});
  }



}
