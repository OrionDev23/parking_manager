import 'package:auto_size_text/auto_size_text.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:dzair_data_usage/langs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart';
import 'package:flutter_chip_tags/flutter_chip_tags.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:parc_oto/admin_parameters.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/chauffeur/manager/chauffeur_table.dart';
import 'package:parc_oto/screens/entreprise/entreprise.dart';
import 'package:parc_oto/serializables/conducteur/conducteur.dart';
import 'package:parc_oto/utilities/vehicle_util.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../serializables/vehicle/vehicle.dart';
import '../../../data/mappers/vehicle_mapper.dart';
import '../../../main.dart';
import '../../../theme.dart';
import '../../../utilities/algeria_lists.dart';
import '../../../widgets/select_dialog/select_dialog.dart';
import '../../../widgets/forms/parcoto_form_field.dart';

class VehicleForm extends StatefulWidget {
  final Vehicle? vehicle;
  final Tab? tab;

  final bool readOnly;

  const VehicleForm({super.key, this.vehicle, this.tab, this.readOnly = false});

  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm>
    with AutomaticKeepAliveClientMixin<VehicleForm> {
  TextEditingController matriculeEtr = TextEditingController();
  TextEditingController matr1 = TextEditingController();
  TextEditingController matr2 = TextEditingController();
  TextEditingController matr3 = TextEditingController();
  TextEditingController wilayaCont = TextEditingController();
  TextEditingController dairaCont = TextEditingController();
  TextEditingController communeCont = TextEditingController();
  TextEditingController quittance = TextEditingController(text: '800');
  TextEditingController numero = TextEditingController();

  TextEditingController matempl = TextEditingController();
  TextEditingController lname = TextEditingController();
  TextEditingController fname = TextEditingController();
  TextEditingController profession = TextEditingController();
  TextEditingController adresse = TextEditingController();
  TextEditingController type = TextEditingController();
  TextEditingController numSer = TextEditingController();
  TextEditingController caross = TextEditingController();
  TextEditingController energie = TextEditingController();
  TextEditingController puissance = TextEditingController();
  TextEditingController places = TextEditingController();
  TextEditingController poidsT = TextEditingController();
  TextEditingController charg = TextEditingController();

  // Professional vehicle data, independent from the legacy registration fields.
  final trimController = TextEditingController();
  final modelYearController = TextEditingController();
  final colorController = TextEditingController();
  final engineDisplacementController = TextEditingController();
  final engineCodeController = TextEditingController();
  final transmissionController = TextEditingController();
  final gearboxController = TextEditingController();
  final driveTypeController = TextEditingController();
  final doorsController = TextEditingController();
  final lengthController = TextEditingController();
  final widthController = TextEditingController();
  final heightController = TextEditingController();
  final acquisitionTypeController = TextEditingController();
  final acquisitionDateController = TextEditingController();
  final purchasePriceController = TextEditingController();
  final supplierController = TextEditingController();
  final warrantyEndDateController = TextEditingController();
  final fleetNumberController = TextEditingController();
  final mileageController = TextEditingController();
  final nextServiceMileageController = TextEditingController();
  DateTime? selectedAnnee = DateTime(2023);
  bool autreMat = false;
  int selectedFormSection = 0;
  int? marque;

  bool erreurMatricule = false;

  int? genre;

  String pays = 'DZ';

  final double height = 55.px;
  final double heightFirst = 118.px;

  String wilaya = "16";

  DateTime selectedDate = DateTime.now();

  bool lourd = false;
  bool service = false;

  TextEditingController selectedAppartenance = TextEditingController();
  TextEditingController selectedAppartenanceEmploye = TextEditingController();
  TextEditingController selectedDepartment = TextEditingController();
  TextEditingController selectedDirection = TextEditingController();
  TextEditingController selectedFiliale = TextEditingController();
  List<String> matriculesPrec = [];

  @override
  void initState() {
    initValues();
    super.initState();
  }

  void initValues() {
    AlgeriaList();
    if (widget.vehicle != null) {
      documentID = widget.vehicle!.id;
      if (widget.vehicle!.matriculeEtrang) {
        autreMat = true;
        matriculeEtr.text = widget.vehicle!.matricule;
      } else {
        autreMat = false;
        var mats = widget.vehicle!.matricule.split('-');
        if (mats.length >= 3) {
          matr1.text = mats[0];
          matr2.text = mats[1];
          matr3.text = mats[2];
        }
      }
      pays = widget.vehicle!.pays ?? 'DZ';
      wilayaCont.text =
          AlgeriaList().getWilayaByNum(
            widget.vehicle!.wilaya?.toString() ?? '16',
          ) ??
          '';
      wilaya = widget.vehicle!.wilaya?.toString() ?? '';
      communeCont.text = widget.vehicle!.commune ?? '';
      dairaCont.text = widget.vehicle!.daira ?? '';
      selectedDate = widget.vehicle!.date ?? DateTime.now();
      quittance.text = widget.vehicle!.quittance?.toString() ?? '';
      numero.text = widget.vehicle!.numero ?? '';
      lname.text = widget.vehicle!.nom ?? '';
      fname.text = widget.vehicle!.prenom ?? '';
      profession.text = widget.vehicle!.profession ?? '';
      adresse.text = widget.vehicle!.adresse ?? '';
      genre = int.tryParse(widget.vehicle!.genre ?? '-1');
      marque = int.tryParse(widget.vehicle!.marque ?? '-1');
      type.text = widget.vehicle!.type ?? '';
      numSer.text = widget.vehicle!.numeroSerie ?? '';
      caross.text = widget.vehicle!.carrosserie ?? '';
      energie.text = widget.vehicle!.energie ?? '';
      puissance.text = widget.vehicle!.puissance?.toString() ?? '';
      places.text = widget.vehicle!.placesAssises?.toString() ?? '';
      poidsT.text = widget.vehicle!.poidsTotal?.toString() ?? '';
      charg.text = widget.vehicle!.charegeUtile?.toString() ?? '';
      matriculesPrec.addAll(widget.vehicle!.matriculePrec ?? []);
      selectedDate = widget.vehicle!.date ?? DateTime.now();
      lourd = widget.vehicle!.lourd;
      matempl.text = widget.vehicle!.matriculeConducteur ?? '';
      service = widget.vehicle!.decision;

      selectedDepartment.text = VehiclesUtilities.getDepartment(
        widget.vehicle!.departement,
      );
      selectedAppartenanceEmploye.text = VehiclesUtilities.getAppartenance(
        widget.vehicle!.appartenanceconducteur,
      );
      selectedFiliale.text = VehiclesUtilities.getAppartenance(
        widget.vehicle!.filliale,
      );
      selectedAppartenance.text = VehiclesUtilities.getAppartenance(
        widget.vehicle!.appartenance,
      );
      selectedDirection.text = VehiclesUtilities.getDirection(
        widget.vehicle!.direction,
      );
      selectedAnnee = DateTime(
        widget.vehicle!.anneeUtil ?? DateTime.now().year,
      );
      trimController.text = widget.vehicle!.trim ?? '';
      modelYearController.text = widget.vehicle!.modelYear?.toString() ?? '';
      colorController.text = widget.vehicle!.color ?? '';
      engineDisplacementController.text =
          widget.vehicle!.engineDisplacement?.toString() ?? '';
      engineCodeController.text = widget.vehicle!.engineCode ?? '';
      transmissionController.text = widget.vehicle!.transmission ?? '';
      gearboxController.text = widget.vehicle!.gearbox ?? '';
      driveTypeController.text = widget.vehicle!.driveType ?? '';
      doorsController.text = widget.vehicle!.doors?.toString() ?? '';
      lengthController.text = widget.vehicle!.lengthMm?.toString() ?? '';
      widthController.text = widget.vehicle!.widthMm?.toString() ?? '';
      heightController.text = widget.vehicle!.heightMm?.toString() ?? '';
      acquisitionTypeController.text = widget.vehicle!.acquisitionType ?? '';
      acquisitionDateController.text = widget.vehicle!.acquisitionDate ?? '';
      purchasePriceController.text = widget.vehicle!.purchasePrice?.toString() ?? '';
      supplierController.text = widget.vehicle!.supplier ?? '';
      warrantyEndDateController.text = widget.vehicle!.warrantyEndDate ?? '';
      fleetNumberController.text = widget.vehicle!.fleetNumber ?? '';
      mileageController.text = widget.vehicle!.currentMileage?.toString() ?? '';
      nextServiceMileageController.text =
          widget.vehicle!.nextServiceMileage?.toString() ?? '';
    }
    documentID ??= DatabaseGetter.ref
        .difference(DateTime.now())
        .inMilliseconds
        .abs()
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
      content: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1180;
        final showSummary = constraints.maxWidth >= 1540;
        return Container(
          color: appTheme.backGroundColor,
          child: Column(children: [
            _buildEditorHeader(appTheme),
            Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (wide) _buildEditorSidebar(appTheme),
              Expanded(child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: wide ? 26 : 14, vertical: 22),
                child: Center(child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (!wide) _buildFormSectionNavigation(appTheme),
                    _buildActiveSectionHeading(appTheme),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: FluentTheme.of(context).micaBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[30]),
                      ),
                      child: StaggeredGrid.count(
                        crossAxisCount: 12,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: gridChildren(appTheme),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildComingNextPanel(appTheme),
                  ]),
                )),
              )),
              if (showSummary) SizedBox(
                width: 278,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(0, 22, 20, 22),
                  child: _buildEditorSummary(appTheme),
                ),
              ),
            ])),
          ]),
        );
      }),
      bottomBar: widget.readOnly ? null : Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 18),
        child: Row(children: [
          if (errorUploading)
            Expanded(child: Text('errupld', style: TextStyle(color: Colors.red)).tr())
          else
            const Expanded(child: Text(
              'Les modifications ne sont enregistrées qu’après confirmation.',
              style: TextStyle(fontSize: 11),
            )),
          Button(
            onPressed: uploading ? null : () => setState(() => selectedFormSection = 0),
            child: const Text('Retour à l’identification'),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: uploading ? null : confirmAndUpload,
            child: uploading ? const ProgressRing() : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(FluentIcons.save, size: 14), SizedBox(width: 8), Text('Enregistrer le véhicule')],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEditorHeader(AppTheme appTheme) {
    final isEditing = widget.vehicle != null;
    final registration = widget.vehicle?.matricule ??
        (autreMat ? matriculeEtr.text : [matr1.text, matr2.text, matr3.text]
            .where((part) => part.trim().isNotEmpty).join('-'));
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).micaBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey[30])),
      ),
      child: Row(children: [
        Container(width: 54, height: 54,
          decoration: BoxDecoration(color: appTheme.color.withValues(alpha: .12), borderRadius: BorderRadius.circular(15)),
          child: Icon(FluentIcons.car, size: 26, color: appTheme.color)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isEditing ? 'Modifier un véhicule' : 'Nouveau véhicule',
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(registration.isEmpty ? 'Fiche véhicule · Parcoto' : '$registration · Fiche véhicule',
            style: TextStyle(color: Colors.grey[100], fontSize: 12)),
        ])),
        _headerPill(isEditing ? FluentIcons.edit : FluentIcons.add,
          isEditing ? 'Modification' : 'Création', appTheme.color),
        const SizedBox(width: 10),
        _headerPill(widget.readOnly ? FluentIcons.lock : FluentIcons.edit,
          widget.readOnly ? 'Consultation' : 'Brouillon',
          widget.readOnly ? Colors.grey : appTheme.color),
      ]),
    );
  }

  Widget _headerPill(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color), const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _buildEditorSidebar(AppTheme appTheme) => Container(
    width: 236,
    padding: const EdgeInsets.fromLTRB(14, 22, 12, 18),
    decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey[30]))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
        child: Text('CONFIGURATION DU VÉHICULE',
          style: TextStyle(fontSize: 10, letterSpacing: 1.1, color: Colors.grey[100], fontWeight: FontWeight.w700)),
      ),
      Expanded(child: ListView(children: List.generate(_formSections.length, (index) {
        final active = selectedFormSection == index;
        const descriptions = [
          'Identité et immatriculation', 'Carte grise et localisation',
          'Conducteur et organisation', 'Motorisation et dimensions',
          'Acquisition et exploitation', 'Anciens numéros connus',
          'Positions et trajets', 'Entretiens et réparations',
          'Pièces et justificatifs', 'Événements du véhicule',
        ];
        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Button(
            style: ButtonStyle(
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
              backgroundColor: WidgetStateProperty.all(active ? appTheme.color.withValues(alpha: .12) : Colors.transparent),
              foregroundColor: WidgetStateProperty.all(active ? appTheme.color : null),
            ),
            onPressed: () => setState(() => selectedFormSection = index),
            child: Row(children: [
              Container(width: 30, height: 30, alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? appTheme.color.withValues(alpha: .16) : Colors.grey[20],
                  borderRadius: BorderRadius.circular(9)),
                child: Icon(_formSections[index].$2, size: 14, color: active ? appTheme.color : Colors.grey[100])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_formSections[index].$1, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w600)),
                const SizedBox(height: 3),
                Text(descriptions[index], maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.grey[100])),
              ])),
              if (active) Icon(FluentIcons.chevron_right, size: 12, color: appTheme.color),
            ]),
          ),
        );
      }))),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: appTheme.color.withValues(alpha: .07), borderRadius: BorderRadius.circular(12)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(FluentIcons.info, size: 16), SizedBox(height: 8),
          Text('Conseil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Renseignez les informations disponibles. Les données facultatives pourront être complétées plus tard.',
            style: TextStyle(fontSize: 10, height: 1.4)),
        ]),
      ),
    ]),
  );

  Widget _buildActiveSectionHeading(AppTheme appTheme) {
    const subtitles = [
      'Définissez l’identité visuelle et administrative du véhicule.',
      'Renseignez les informations de carte grise et son adresse administrative.',
      'Décrivez le rattachement organisationnel et le conducteur associé.',
      'Configurez les caractéristiques mécaniques et physiques.',
      'Centralisez les informations d’acquisition, de garantie et de kilométrage.',
      'Conservez la traçabilité des anciennes immatriculations.',
      'Consultez la dernière position et les relevés GPS disponibles.',
      'Suivez les entretiens, réparations et prochaines échéances.',
      'Centralisez les pièces administratives et leurs dates de validité.',
      'Retrouvez les événements qui composent la vie du véhicule.',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_formSections[selectedFormSection].$1, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(subtitles[selectedFormSection], style: TextStyle(fontSize: 12, color: Colors.grey[100])),
        ])),
        Text('${selectedFormSection + 1} / ${_formSections.length}',
          style: TextStyle(fontSize: 12, color: appTheme.color, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildEditorSummary(AppTheme appTheme) {
    final registration = widget.vehicle?.matricule ?? 'À définir';
    final vehicleName = [
      widget.vehicle?.marque ?? marque?.toString(),
      widget.vehicle?.type ?? type.text,
    ].where((value) => value != null && value.trim().isNotEmpty).join(' ');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: FluentTheme.of(context).micaBackgroundColor,
          border: Border.all(color: Colors.grey[30]), borderRadius: BorderRadius.circular(15)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('APERÇU DU VÉHICULE',
              style: TextStyle(fontSize: 10, letterSpacing: .8, fontWeight: FontWeight.w700))),
            Icon(FluentIcons.car, size: 14, color: Colors.grey[100]),
          ]),
          const SizedBox(height: 14),
          Container(
            height: 118, width: double.infinity,
            decoration: BoxDecoration(color: appTheme.color.withValues(alpha: .08), borderRadius: BorderRadius.circular(11)),
            child: widget.vehicle?.imageUrl?.isNotEmpty == true
                ? ClipRRect(borderRadius: BorderRadius.circular(11),
                    child: Image.network(widget.vehicle!.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(FluentIcons.car, size: 42, color: appTheme.color)))
                : Icon(FluentIcons.car, size: 42, color: appTheme.color),
          ),
          const SizedBox(height: 13),
          Text(vehicleName.isEmpty ? 'Marque et modèle à renseigner' : vehicleName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(registration, style: TextStyle(fontSize: 12, color: Colors.grey[100])),
          const SizedBox(height: 12),
          _summaryLine(FluentIcons.document, 'N° de parc',
            fleetNumberController.text.isEmpty ? 'Non défini' : fleetNumberController.text),
          _summaryLine(FluentIcons.car, 'Kilométrage',
            mileageController.text.isEmpty ? 'Non renseigné' : '${mileageController.text} km'),
        ]),
      ),
      const SizedBox(height: 12),
      _summaryCard('AFFECTATION', [
        ('Conducteur', widget.vehicle?.matriculeConducteur ?? 'À associer'),
        ('Filiale', widget.vehicle?.filliale ?? 'À renseigner'),
        ('Direction', widget.vehicle?.direction ?? 'À renseigner'),
      ]),
      const SizedBox(height: 12),
      _summaryCard('À CONNECTER ENSUITE', [
        ('GPS', 'Position en attente'),
        ('Documents', 'Espace documentaire'),
        ('Maintenance', 'Échéances et interventions'),
        ('Historique', 'Journal des événements'),
      ]),
    ]);
  }

  Widget _summaryCard(String title, List<(String, String)> rows) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: FluentTheme.of(context).micaBackgroundColor,
      border: Border.all(color: Colors.grey[30]), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 10, letterSpacing: .8, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      ...rows.map((row) => _summaryLine(FluentIcons.info, row.$1, row.$2)),
    ]),
  );

  Widget _summaryLine(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 13, color: Colors.grey[100]), const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[100])),
        const SizedBox(height: 2),
        Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ])),
    ]),
  );

  Widget _buildComingNextPanel(AppTheme appTheme) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: appTheme.color.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: appTheme.color.withValues(alpha: .16))),
    child: Row(children: [
      Icon(FluentIcons.document, color: appTheme.color, size: 20), const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Évolution de la fiche véhicule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        SizedBox(height: 4),
        Text('Les prochains lots intégreront les documents, la galerie photo, les alertes de conformité, le suivi GPS et le journal de vie du véhicule.',
          style: TextStyle(fontSize: 11, height: 1.4)),
      ])),
      const SizedBox(width: 8), const Icon(FluentIcons.chevron_right, size: 14),
    ]),
  );

  static const _formSections = [
    ('Identification', FluentIcons.car),
    ('Administratif', FluentIcons.document),
    ('Affectation', FluentIcons.people),
    ('Technique', FluentIcons.repair),
    ('Exploitation & finances', FluentIcons.money),
    ('Immatriculations', FluentIcons.document),
    ('GPS & localisation', FluentIcons.car),
    ('Maintenance', FluentIcons.repair),
    ('Documents', FluentIcons.document),
    ('Historique', FluentIcons.info),
  ];

  Widget _buildFormSectionNavigation(AppTheme appTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
          color: appTheme.color.withValues(alpha: .18),
        )),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_formSections.length, (index) {
            final active = selectedFormSection == index;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Button(
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  ),
                  backgroundColor: WidgetStateProperty.all(
                    active ? appTheme.color.withValues(alpha: .13) : Colors.transparent,
                  ),
                  foregroundColor: WidgetStateProperty.all(active ? appTheme.color : null),
                ),
                onPressed: () => setState(() => selectedFormSection = index),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_formSections[index].$2, size: 14),
                    const SizedBox(width: 7),
                    Text(_formSections[index].$1, style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    )),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  List<Widget> gridChildren(AppTheme appTheme) {
    switch (selectedFormSection) {
      case 0:
        return [_buildVehicleIdentitySection(appTheme)];
      case 1:
        return [
          _sectionHeader(appTheme, 'Localisation et documents administratifs',
            'Pays, wilaya, commune et informations de la carte grise'),
          ...getWilayaCommuneWidget(appTheme),
          ...secondLine(appTheme),
        ];
      case 2:
        return [
          if (conducteurEmploye) ...[
            _sectionHeader(appTheme, 'Propriétaire et conducteur',
              'Informations sur le propriétaire et le conducteur associé'),
            ...thirdLine(appTheme),
            ...forthLine(appTheme),
          ],
          _sectionHeader(appTheme, 'Organisation et rattachement',
            'Appartenance, filiale, direction et département'),
          ...fifthLine(appTheme),
        ];
      case 3:
        return [
          _sectionHeader(appTheme, 'Caractéristiques techniques',
            'Configuration, motorisation, capacité et caractéristiques du véhicule'),
          ...seventhLine(appTheme),
        ];
      case 4:
        return [_buildProfessionalDetailsSection(appTheme)];
      case 5:
        return [
          _sectionHeader(appTheme, 'Historique des immatriculations',
            'Anciennes immatriculations connues pour ce véhicule'),
          ...eightLine(appTheme),
        ];
      case 6:
        return [_buildModulePlaceholder(
          FluentIcons.car,
          'GPS & localisation',
          'Visualisez la dernière position connue du véhicule et consultez ses déplacements lorsque le suivi sera activé.',
          ['Dernière position connue', 'Date et précision du relevé', 'Carte et historique des positions', 'Source du relevé et conducteur associé'],
          'Collecte GPS non connectée',
          appTheme,
        )];
      case 7:
        return [_buildModulePlaceholder(
          FluentIcons.repair,
          'Maintenance & interventions',
          'Centralisez le cycle de maintenance, les entretiens préventifs et les réparations effectuées sur ce véhicule.',
          ['Prochaine échéance kilométrique ou temporelle', 'Planning des entretiens', 'Ordres de réparation', 'Coûts et prestataires'],
          'Module maintenance à connecter',
          appTheme,
        )];
      case 8:
        return [_buildModulePlaceholder(
          FluentIcons.document,
          'Documents du véhicule',
          'Retrouvez les documents administratifs et opérationnels dans un espace unique, avec leurs dates de validité.',
          ['Carte grise et assurance', 'Contrôle technique', 'Factures et justificatifs', 'Alertes avant expiration'],
          'Stockage documentaire à connecter',
          appTheme,
        )];
      default:
        return [_buildModulePlaceholder(
          FluentIcons.info,
          'Historique & journal de vie',
          'Consultez les événements importants qui modifient la vie du véhicule et son utilisation.',
          ['Changements d’affectation', 'Relevés kilométriques', 'Changements de statut', 'Interventions et modifications de la fiche'],
          'Journal d’événements à structurer',
          appTheme,
        )];
    }
  }

  Widget _buildVehicleIdentitySection(AppTheme appTheme) {
    return StaggeredGridTile.fit(
      crossAxisCellCount: 12,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: appTheme.backGroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: appTheme.color.withValues(alpha: 0.28)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final columns = availableWidth >= 900
                ? 4
                : availableWidth >= 560
                    ? 2
                    : 1;
            final spacing = 12.0;
            final fieldWidth =
                (availableWidth - (spacing * (columns - 1))) / columns;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: appTheme.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(FluentIcons.car, color: appTheme.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Identification du véhicule',
                            style: appTheme.writingStyle.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Identité administrative et commerciale du véhicule',
                            style: appTheme.writingStyle.copyWith(
                              fontSize: 12,
                              color: appTheme.writingStyle.color
                                  ?.withValues(alpha: 0.68),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.readOnly)
                      const Tooltip(
                        message: 'Mode consultation',
                        child: Icon(FluentIcons.lock, size: 16),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: spacing,
                  runSpacing: 14,
                  children: [
                    _identityField(
                      appTheme,
                      width: fieldWidth,
                      label: 'Immatriculation',
                      requiredField: true,
                      child: autreMat
                          ? ParcotoTextBox(
                              enabled: !widget.readOnly,
                              controller: matriculeEtr,
                              maxLength: 30,
                              placeholder: 'XXXXXXXXXXXXXX',
                              style: appTheme.writingStyle,
                              placeholderStyle: placeStyle,
                              cursorColor: appTheme.color,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp('[0-9a-zA-Z.-]'),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: ParcotoTextBox(
                                    enabled: !widget.readOnly,
                                    controller: matr1,
                                    maxLength: 6,
                                    placeholder: '123456',
                                    textAlign: TextAlign.center,
                                    style: appTheme.writingStyle,
                                    placeholderStyle: placeStyle,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  child: Text('-'),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: ParcotoTextBox(
                                    enabled: !widget.readOnly,
                                    controller: matr2,
                                    maxLength: 3,
                                    placeholder: '123',
                                    textAlign: TextAlign.center,
                                    style: appTheme.writingStyle,
                                    placeholderStyle: placeStyle,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (_) => updateOverMatricule(appTheme),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  child: Text('-'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: ParcotoTextBox(
                                    enabled: !widget.readOnly,
                                    controller: matr3,
                                    maxLength: 2,
                                    placeholder: '16',
                                    textAlign: TextAlign.center,
                                    style: appTheme.writingStyle,
                                    placeholderStyle: placeStyle,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (_) => updateOverMatricule(appTheme),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    _identityField(
                      appTheme,
                      width: fieldWidth,
                      label: 'Marque',
                      child: Button(
                        onPressed: widget.readOnly
                            ? null
                            : () {
                                SelectDialog.showModal<int?>(
                                  context,
                                  selectedValue: marque,
                                  backgroundColor: appTheme.backGroundColor,
                                  gridView: true,
                                  numberOfGridCross: 3,
                                  constraints: BoxConstraints.loose(
                                    Size(600.px, 650.px),
                                  ),
                                  items: VehiclesUtilities.marques!.keys.toList(),
                                  itemBuilder: (c, v, e) => Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Image.asset(
                                        'assets/images/marques/${v ?? 'default'}.webp',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  onChange: (value) => setState(() => marque = value),
                                  onFind: VehiclesUtilities.findMarque,
                                  emptyBuilder: (_) => const Center(
                                    child: Text('Aucune marque trouvée'),
                                  ),
                                  loadingBuilder: (_) => const Center(
                                    child: ProgressRing(),
                                  ),
                                  searchBoxDecoration:
                                      appTheme.materialUiInputDecoration.copyWith(
                                    labelText: 'search'.tr(),
                                    labelStyle: placeStyle,
                                  ),
                                  searchTextStyle: appTheme.writingStyle,
                                  searchCursorColor: appTheme.color,
                                );
                              },
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/marques/${marque == null || marque! <= 0 ? 'default' : marque!}.webp',
                              width: 28,
                              height: 28,
                              errorBuilder: (_, _, _) =>
                                  const Icon(FluentIcons.car),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                VehiclesUtilities.marques?[
                                      marque == null || marque! <= 0 ? 0 : marque!
                                    ] ??
                                    'nonind'.tr(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(FluentIcons.chevron_down, size: 12),
                          ],
                        ),
                      ),
                    ),
                    _identityField(
                      appTheme,
                      width: fieldWidth,
                      label: 'Modèle',
                      child: ParcotoTextBox(
                        enabled: !widget.readOnly,
                        controller: type,
                        maxLength: 60,
                        placeholder: 'Ex. : Clio, Corolla, Hilux',
                        style: appTheme.writingStyle,
                        placeholderStyle: placeStyle,
                        cursorColor: appTheme.color,
                      ),
                    ),
                    _identityField(
                      appTheme,
                      width: fieldWidth,
                      label: 'Genre',
                      child: Button(
                        onPressed: widget.readOnly
                            ? null
                            : () {
                                SelectDialog.showModal<int>(
                                  context,
                                  selectedValue: genre,
                                  backgroundColor: appTheme.backGroundColor,
                                  items: VehiclesUtilities.genres!.keys.toList(),
                                  itemBuilder: (c, value, e) => Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      '$value  •  ${(VehiclesUtilities.genres?[value] ?? 'nonind').tr()}',
                                    ),
                                  ),
                                  onChange: (value) => setState(() => genre = value),
                                  onFind: VehiclesUtilities.findGenres,
                                  emptyBuilder: (_) => const Center(
                                    child: Text('Aucun genre trouvé'),
                                  ),
                                  loadingBuilder: (_) => const Center(
                                    child: ProgressRing(),
                                  ),
                                  searchBoxDecoration:
                                      appTheme.materialUiInputDecoration.copyWith(
                                    labelText: 'search'.tr(),
                                    labelStyle: placeStyle,
                                  ),
                                  searchTextStyle: appTheme.writingStyle,
                                  searchCursorColor: appTheme.color,
                                  constraints: BoxConstraints.loose(
                                    Size(400.px, 450.px),
                                  ),
                                );
                              },
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                (VehiclesUtilities.genres?[genre ?? -1] ??
                                        'nonind')
                                    .tr(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(FluentIcons.chevron_down, size: 12),
                          ],
                        ),
                      ),
                    ),
                    if (chassisKey)
                      _identityField(
                        appTheme,
                        width: fieldWidth,
                        label: 'Numéro de châssis (VIN)',
                        requiredField: true,
                        child: ParcotoTextBox(
                          enabled: !widget.readOnly,
                          controller: numSer,
                          maxLength: 30,
                          placeholder: '17 caractères généralement',
                          style: appTheme.writingStyle,
                          placeholderStyle: placeStyle,
                          cursorColor: appTheme.color,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Checkbox(
                      checked: autreMat,
                      onChanged: widget.readOnly
                          ? null
                          : (value) => setState(() {
                                autreMat = value ?? false;
                                erreurMatricule = false;
                              }),
                      content: const Text('Immatriculation étrangère'),
                    ),
                    if (erreurMatricule) ...[
                      const SizedBox(width: 12),
                      Icon(FluentIcons.warning, color: Colors.red, size: 14),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Veuillez saisir une immatriculation valide.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                    if (errorChassis) ...[
                      const SizedBox(width: 12),
                      Icon(FluentIcons.warning, color: Colors.red, size: 14),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Le numéro de châssis est obligatoire.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModulePlaceholder(
    IconData icon,
    String title,
    String description,
    List<String> features,
    String status,
    AppTheme appTheme,
  ) {
    return StaggeredGridTile.fit(
      crossAxisCellCount: 12,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: FluentTheme.of(context).micaBackgroundColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[30]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: appTheme.color.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: appTheme.color, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 11, color: Colors.grey[100], height: 1.4)),
                ],
              )),
            ]),
            const SizedBox(height: 22),
            Text('CE QUE CONTIENDRA CE MODULE',
              style: TextStyle(fontSize: 10, letterSpacing: .8, color: Colors.grey[100], fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 2 : 1;
              final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: features.map((feature) => SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: appTheme.backGroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[30]),
                    ),
                    child: Row(children: [
                      Icon(FluentIcons.check_mark, size: 13, color: appTheme.color),
                      const SizedBox(width: 9),
                      Expanded(child: Text(feature, style: const TextStyle(fontSize: 11))),
                    ]),
                  ),
                )).toList(),
              );
            }),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[20],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(FluentIcons.info, size: 12, color: Colors.grey[100]),
                const SizedBox(width: 7),
                Text(status, style: TextStyle(fontSize: 10, color: Colors.grey[100], fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalDetailsSection(AppTheme appTheme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columns = screenWidth >= 1200 ? 4 : screenWidth >= 700 ? 2 : 1;
    final availableWidth = (screenWidth - 100)
        .clamp(240.0, 1008.0)
        .toDouble();
    final fieldWidth = ((availableWidth - (columns - 1) * 12) / columns)
        .clamp(150.0, 420.0)
        .toDouble();

    Widget field(String label, TextEditingController controller,
        {String? hint, bool numeric = false, bool decimal = false}) {
      return _identityField(
        appTheme,
        width: fieldWidth,
        label: label,
        child: ParcotoTextBox(
          enabled: !widget.readOnly,
          controller: controller,
          placeholder: hint ?? label,
          style: appTheme.writingStyle,
          placeholderStyle: placeStyle,
          cursorColor: appTheme.color,
          inputFormatters: numeric
              ? [FilteringTextInputFormatter.digitsOnly]
              : decimal
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
                  : const [],
        ),
      );
    }

    return StaggeredGridTile.fit(
      crossAxisCellCount: 12,
      child: Container(
        margin: const EdgeInsets.only(top: 14, bottom: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: appTheme.backGroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: appTheme.color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.car, color: appTheme.color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Données professionnelles et exploitation',
                    style: appTheme.writingStyle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Informations complémentaires, facultatives et modifiables.',
              style: appTheme.writingStyle.copyWith(
                fontSize: 12,
                color: appTheme.writingStyle.color?.withValues(alpha: 0.68),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 14,
              children: [
                field('Version / finition', trimController),
                field('Année modèle', modelYearController,
                    hint: 'Ex. 2022', numeric: true),
                field('Couleur', colorController),
                field('Cylindrée (cm³)', engineDisplacementController,
                    numeric: true),
                field('Code moteur', engineCodeController),
                field('Transmission', transmissionController,
                    hint: 'Ex. traction, propulsion, 4x4'),
                field('Boîte de vitesses', gearboxController,
                    hint: 'Ex. manuelle, automatique'),
                field('Nombre de portes', doorsController, numeric: true),
                field('Longueur (mm)', lengthController, numeric: true),
                field('Largeur (mm)', widthController, numeric: true),
                field('Hauteur (mm)', heightController, numeric: true),
                field('Type d’acquisition', acquisitionTypeController,
                    hint: 'Achat, leasing, location…'),
                field('Date d’acquisition', acquisitionDateController,
                    hint: 'AAAA-MM-JJ'),
                field('Prix d’acquisition (DA)', purchasePriceController,
                    hint: 'Montant en DA', decimal: true),
                field('Fournisseur / vendeur', supplierController),
                field('Fin de garantie', warrantyEndDateController,
                    hint: 'AAAA-MM-JJ'),
                field('Numéro de parc', fleetNumberController),
                field('Kilométrage actuel (km)', mileageController,
                    numeric: true),
                field('Prochaine révision (km)', nextServiceMileageController,
                    numeric: true),
                field('Type de motricité', driveTypeController,
                    hint: 'Ex. 4x2, 4x4'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Widget _identityField(
    AppTheme appTheme, {
    required double width,
    required String label,
    required Widget child,
    bool requiredField = false,
  }) {
    return ParcotoFormField(
      width: width,
      label: label,
      requiredField: requiredField,
      child: child,
    );
  }


  Widget _sectionHeader(
    AppTheme appTheme,
    String title,
    String description,
  ) {
    return StaggeredGridTile.fit(
      crossAxisCellCount: 12,
      child: Container(
        margin: const EdgeInsets.only(top: 14, bottom: 6),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: appTheme.color.withValues(alpha: 0.08),
          border: Border(
            left: BorderSide(color: appTheme.color, width: 3),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: appTheme.writingStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: appTheme.writingStyle.copyWith(
                fontSize: 11,
                color: appTheme.writingStyle.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> firstLine(AppTheme appTheme) {
    return [
      if (chassisKey) getChassisWidget(appTheme),
      StaggeredGridTile.fit(
        crossAxisCellCount: 6,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: Device.orientation == Orientation.portrait
                  ? BorderSide.none
                  : BorderSide(color: appTheme.color),
              right: Device.orientation == Orientation.portrait
                  ? BorderSide(color: appTheme.color)
                  : BorderSide.none,
              left: Device.orientation == Orientation.portrait
                  ? BorderSide(color: appTheme.color)
                  : BorderSide.none,
            ),
          ),
          height: heightFirst,
          padding: const EdgeInsets.symmetric(horizontal: chassisKey ? 0 : 10),
          child: Container(
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              border: Border.all(color: appTheme.color),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'nummat',
                    style: formHintStyle.copyWith(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ).tr(),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: autreMat
                      ? ParcotoTextBox(
                          enabled: !widget.readOnly,
                          controller: matriculeEtr,
                          maxLength: 30,
                          cursorColor: appTheme.color.darker,
                          style: appTheme.writingStyle,
                          placeholder: 'XXXXXXXXXXXXXX',
                          textAlign: TextAlign.center,
                          placeholderStyle: placeStyle,

                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                              RegExp("[0-9a-zA-Z.-]"),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              flex: 6,
                              child: ParcotoTextBox(
                                enabled: !widget.readOnly,
                                controller: matr1,
                                cursorColor: appTheme.color.darker,
                                style: appTheme.writingStyle,
                                placeholder: '123456',
                                placeholderStyle: placeStyle,

                                maxLength: 6,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                            smallSpace,
                            Text('-', style: formHintStyle),
                            smallSpace,
                            Flexible(
                              flex: 3,
                              child: ParcotoTextBox(
                                enabled: !widget.readOnly,
                                controller: matr2,
                                cursorColor: appTheme.color.darker,
                                style: appTheme.writingStyle,
                                placeholder: '123',
                                maxLength: 3,
                                placeholderStyle: placeStyle,

                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (s) {
                                  updateOverMatricule(appTheme);
                                },
                              ),
                            ),
                            smallSpace,
                            Text('-', style: formHintStyle),
                            smallSpace,
                            Flexible(
                              flex: 2,
                              child: ParcotoTextBox(
                                enabled: !widget.readOnly,
                                controller: matr3,
                                cursorColor: appTheme.color.darker,
                                style: appTheme.writingStyle,
                                placeholder: '12',
                                maxLength: 2,
                                placeholderStyle: placeStyle,

                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (s) {
                                  updateOverMatricule(appTheme);
                                },
                              ),
                            ),
                          ],
                        ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (erreurMatricule)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: Text(
                          'erreurmat',
                          style: TextStyle(color: Colors.red),
                        ).tr(),
                      ),
                    if (erreurMatricule) Spacer(),
                    Checkbox(
                      checked: autreMat,
                      content: Text(
                        'autremat',
                        style: appTheme.writingStyle,
                      ).tr(),
                      onChanged: widget.readOnly
                          ? null
                          : (s) {
                              if (s != null) {
                                setState(() {
                                  autreMat = s;
                                });
                              }
                            },
                    ),
                    smallSpace,
                  ],
                ),
                smallSpace,
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> getWilayaCommuneWidget(AppTheme appTheme) {
    return [
      StaggeredGridTile.fit(
        crossAxisCellCount: chassisKey ? 6 : 4,
        child: Container(
          height: heightFirst,

          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: appTheme.color),
              left: BorderSide(color: appTheme.color),
              right: Device.orientation == Orientation.portrait
                  ? BorderSide(color: appTheme.color)
                  : BorderSide.none,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('pays', style: formHintStyle).tr(),
              CountryCodePicker(
                enabled: !widget.readOnly,
                boxDecoration: BoxDecoration(
                  color: appTheme.backGroundColor,
                  boxShadow: kElevationToShadow[2],
                ),
                padding: const EdgeInsets.all(3),
                searchDecoration: appTheme.inputDecoration,
                dialogSize: Size(40.w, 60.h),
                initialSelection: pays,
                showCountryOnly: true,
                showDropDownButton: true,
                showFlagDialog: true,
                showOnlyCountryWhenClosed: true,
                onChanged: (c) {
                  setState(() {
                    pays = c.code ?? 'DZ';
                  });
                },
              ),
              Text('wilaya', style: formHintStyle).tr(),
              SizedBox(
                height: 5.h,
                child: AutoSuggestBox<String>(
                  enabled: !widget.readOnly,
                  controller: wilayaCont,
                  placeholder: 'wilaya'.tr(),
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,

                  items: AlgeriaList.dzair!.getWilayat()!.map((wilaya) {
                    return AutoSuggestBoxItem<String>(
                      value: wilaya!.getWilayaCode()!,
                      label: wilaya.getWilayaName(
                        appTheme.locale!.languageCode.toUpperCase() == "AR"
                            ? Language.AR
                            : Language.FR,
                      )!,
                    );
                  }).toList(),
                  onSelected: (item) {
                    setState(() {
                      wilaya = item.value!;
                      wilayaCont.text =
                          AlgeriaList.dzair!
                              .searchWilayatByName(
                                item.label,
                                appTheme.locale!.languageCode.toUpperCase() ==
                                        "AR"
                                    ? Language.AR
                                    : Language.FR,
                              )
                              ?.first
                              ?.getWilayaName(Language.FR) ??
                          '';
                    });
                  },
                  onChanged: (s, r) {
                    if (r == TextChangedReason.userInput) {
                      setState(() => wilayaCont.text = s);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: chassisKey ? 6 : 4,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: Device.orientation == Orientation.portrait
                  ? BorderSide.none
                  : BorderSide(color: appTheme.color),
              right: BorderSide(color: appTheme.color),
              left: Device.orientation == Orientation.portrait
                  ? BorderSide(color: appTheme.color)
                  : BorderSide.none,
            ),
          ),
          height: heightFirst,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('daira', style: formHintStyle).tr(),
              SizedBox(
                height: 5.h,
                child: AutoSuggestBox<String>(
                  enabled: !widget.readOnly,
                  controller: dairaCont,
                  placeholder: 'daira'.tr(),
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,
                  placeholderStyle: placeStyle,

                  items: AlgeriaList().getDairas(wilayaCont.text).map((daira) {
                    return AutoSuggestBoxItem<String>(
                      value: daira?.getDairaName(Language.FR) ?? '',
                      label:
                          daira?.getDairaName(
                            appTheme.locale?.languageCode.toUpperCase() == "AR"
                                ? Language.AR
                                : Language.FR,
                          ) ??
                          '',
                    );
                  }).toList(),
                  onSelected: (item) {
                    setState(() => dairaCont.text = item.value ?? "");
                  },
                  onChanged: (s, r) {
                    if (r == TextChangedReason.userInput) {
                      setState(() => dairaCont.text = s);
                    }
                  },
                ),
              ),
              Text('commune', style: formHintStyle).tr(),
              SizedBox(
                height: 5.h,
                child: AutoSuggestBox<String>(
                  enabled: !widget.readOnly,
                  controller: communeCont,
                  placeholder: 'commune'.tr(),
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,

                  items: AlgeriaList().getCommune(wilayaCont.text).map((
                    commune,
                  ) {
                    return AutoSuggestBoxItem<String>(
                      value: commune == null
                          ? ''
                          : commune.getCommuneName(Language.FR) ?? '',
                      label: commune == null
                          ? ''
                          : commune.getCommuneName(
                                  appTheme.locale?.languageCode.toUpperCase() ==
                                          "AR"
                                      ? Language.AR
                                      : Language.FR,
                                ) ??
                                '',
                    );
                  }).toList(),
                  onSelected: (item) {
                    setState(() => communeCont.text = item.value ?? "");
                  },
                  onChanged: (s, r) {
                    if (r == TextChangedReason.userInput) {
                      setState(() => communeCont.text = s);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> secondLine(AppTheme appTheme) {
    return [
      StaggeredGridTile.fit(
        crossAxisCellCount: 4,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: appTheme.color),
              right: Device.orientation == Orientation.portrait
                  ? BorderSide(color: appTheme.color)
                  : BorderSide.none,
            ),
          ),
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('datecartegrise', style: formHintStyle).tr(),
              DatePicker(
                selected: selectedDate,
                onChanged: widget.readOnly
                    ? null
                    : (s) {
                        setState(() {
                          selectedDate = s;
                        });
                      },
              ),
            ],
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 4,
        child: Container(
          decoration: BoxDecoration(
            border: Device.orientation == Orientation.portrait
                ? Border(
                    left: BorderSide(color: appTheme.color),
                    right: BorderSide(color: appTheme.color),
                  )
                : const Border(),
          ),

          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('numcartegrise', style: formHintStyle).tr(),
              ParcotoTextBox(
                enabled: !widget.readOnly,
                controller: numero,
                placeholder: 'numcartegrise'.tr(),
                maxLength: 30,
                placeholderStyle: placeStyle,
                cursorColor: appTheme.color.darker,
                style: appTheme.writingStyle,
              ),
            ],
          ),
        ),
      ),
      if (MediaQuery.of(context).orientation == Orientation.landscape)
        StaggeredGridTile.fit(
          crossAxisCellCount: 2,
          child: SizedBox(height: height),
        ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: appTheme.color),
              left: Device.orientation == Orientation.portrait
                  ? BorderSide(color: appTheme.color)
                  : BorderSide.none,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('quittance', style: formHintStyle).tr(),
              ParcotoTextBox(
                enabled: !widget.readOnly,
                controller: quittance,
                placeholder: 'quittance'.tr(),
                cursorColor: appTheme.color.darker,
                style: appTheme.writingStyle,
                placeholderStyle: placeStyle,

                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^(\d+)?\.?\d{0,2}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> thirdLine(AppTheme appTheme) {
    return [
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: appTheme.color),
              left: BorderSide(color: appTheme.color),
              right: Device.orientation == Orientation.portrait
                  ? BorderSide(color: appTheme.color)
                  : BorderSide.none,
            ),
          ),

          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('existingdriver', style: formHintStyle).tr(),
              SizedBox(
                width: 500.px,
                child: Button(
                  onPressed: () => selectConducteur(appTheme),
                  child: const Text('select').tr(),
                ),
              ),
            ],
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: Container(
          decoration: BoxDecoration(
            border: Device.orientation == Orientation.portrait
                ? Border(
                    left: BorderSide(color: appTheme.color),
                    right: BorderSide(color: appTheme.color),
                  )
                : Border(top: BorderSide(color: appTheme.color)),
          ),

          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('matriculeemploye', style: formHintStyle).tr(),
              SizedBox(
                height: 5.h,
                child: ParcotoTextBox(
                  enabled: !widget.readOnly,
                  controller: matempl,
                  maxLength: 30,
                  placeholder: 'matriculeemploye'.tr(),
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,
                ),
              ),
            ],
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: Container(
          decoration: BoxDecoration(
            border: Device.orientation == Orientation.portrait
                ? Border(
                    left: BorderSide(color: appTheme.color),
                    right: BorderSide(color: appTheme.color),
                  )
                : Border(top: BorderSide(color: appTheme.color)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('nomf', style: formHintStyle).tr(),
              SizedBox(
                height: 5.h,
                child: ParcotoTextBox(
                  enabled: !widget.readOnly,
                  controller: lname,
                  maxLength: 30,
                  placeholder: 'nomf'.tr(),
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,
                ),
              ),
            ],
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,

        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Device.orientation == Orientation.portrait
                ? Border(
                    left: BorderSide(color: appTheme.color),
                    right: BorderSide(color: appTheme.color),
                  )
                : Border(top: BorderSide(color: appTheme.color)),
          ),
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('prenom', style: formHintStyle).tr(),
              SizedBox(
                height: 5.h,
                child: ParcotoTextBox(
                  enabled: !widget.readOnly,
                  controller: fname,
                  maxLength: 30,
                  placeholder: 'prenom'.tr(),
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,
                ),
              ),
            ],
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 4,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: Device.orientation == Orientation.portrait
                  ? BorderSide.none
                  : BorderSide(color: appTheme.color),
              right: BorderSide(color: appTheme.color),
              left: Device.orientation == Orientation.portrait
                  ? BorderSide(color: appTheme.color)
                  : BorderSide.none,
            ),
          ),

          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('poste', style: formHintStyle).tr(),
              SizedBox(
                height: 5.h,
                child: ParcotoTextBox(
                  enabled: !widget.readOnly,
                  controller: profession,
                  maxLength: 40,
                  placeholder: 'poste'.tr(),
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> forthLine(AppTheme appTheme) {
    return [
      StaggeredGridTile.fit(
        crossAxisCellCount: 3,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: Device.orientation == Orientation.portrait
                  ? BorderSide.none
                  : BorderSide(color: appTheme.color),
              left: BorderSide(color: appTheme.color),
              right: Device.orientation == Orientation.portrait
                  ? BorderSide(color: appTheme.color)
                  : BorderSide.none,
            ),
          ),

          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('servicefonction', style: formHintStyle).tr(),
              SizedBox(
                height: 5.h,
                child: Row(
                  children: [
                    const Text('fonction').tr(),
                    smallSpace,
                    ToggleSwitch(
                      checked: service,
                      onChanged: (s) {
                        setState(() {
                          service = s;
                        });
                      },
                    ),
                    smallSpace,
                    const Text('service').tr(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 6,
        child: Container(
          decoration: BoxDecoration(
            border: Device.orientation == Orientation.portrait
                ? Border(
                    bottom: Device.orientation == Orientation.portrait
                        ? BorderSide.none
                        : BorderSide(color: appTheme.color),
                    left: BorderSide(color: appTheme.color),
                    right: BorderSide(color: appTheme.color),
                  )
                : Border(bottom: BorderSide(color: appTheme.color)),
          ),

          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('adresse', style: formHintStyle).tr(),
              SizedBox(
                height: 5.h,
                child: ParcotoTextBox(
                  enabled: !widget.readOnly,
                  controller: adresse,
                  placeholder: 'adresse'.tr(),
                  maxLength: 100,
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,
                ),
              ),
            ],
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 3,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: appTheme.color),
              right: BorderSide(color: appTheme.color),
              left: Device.orientation == Orientation.portrait
                  ? BorderSide(color: appTheme.color)
                  : BorderSide.none,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('appartenanceconducteursingle', style: formHintStyle).tr(),
                AutoSuggestBox<String>(
                  enabled: !widget.readOnly,
                  placeholder: 'appartenanceconducteursingle'.tr(),
                  placeholderStyle: placeStyle,
                  controller: selectedAppartenanceEmploye,
                  items: List.generate(
                    MyEntrepriseState.p!.filiales!.length,
                    (index) => AutoSuggestBoxItem(
                      value: MyEntrepriseState.p!.filiales![index],
                      label: MyEntrepriseState.p!.filiales![index]
                          .toUpperCase(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> fifthLine(AppTheme appTheme) {
    return [
      StaggeredGridTile.fit(
        crossAxisCellCount: 3,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: appTheme.color),
              right: Device.orientation == Orientation.portrait
                  ? BorderSide(color: appTheme.color)
                  : BorderSide.none,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('appartenancevehiculesingle', style: formHintStyle).tr(),
                AutoSuggestBox<String>(
                  enabled: !widget.readOnly,
                  placeholder: 'appartenancevehiculesingle'.tr(),
                  placeholderStyle: placeStyle,
                  controller: selectedAppartenance,
                  items: List.generate(
                    MyEntrepriseState.p!.filiales!.length,
                    (index) => AutoSuggestBoxItem(
                      value: MyEntrepriseState.p!.filiales![index],
                      label: MyEntrepriseState.p!.filiales![index]
                          .toUpperCase(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 3,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            border: Device.orientation == Orientation.portrait
                ? Border(
                    left: BorderSide(color: appTheme.color),
                    right: BorderSide(color: appTheme.color),
                  )
                : const Border(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('filialeexploit', style: formHintStyle).tr(),
                AutoSuggestBox<String>(
                  enabled: !widget.readOnly,
                  placeholder: 'filialeexploit'.tr(),
                  placeholderStyle: placeStyle,
                  controller: selectedFiliale,
                  items: List.generate(
                    MyEntrepriseState.p!.filiales!.length,
                    (index) => AutoSuggestBoxItem(
                      value: MyEntrepriseState.p!.filiales![index],
                      label: MyEntrepriseState.p!.filiales![index]
                          .toUpperCase(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 3,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            border: Device.orientation == Orientation.portrait
                ? Border(
                    left: BorderSide(color: appTheme.color),
                    right: BorderSide(color: appTheme.color),
                  )
                : const Border(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('direction', style: formHintStyle).tr(),
                AutoSuggestBox<String>(
                  enabled: !widget.readOnly,
                  placeholder: 'direction'.tr(),
                  placeholderStyle: placeStyle,
                  controller: selectedDirection,
                  items: List.generate(
                    MyEntrepriseState.p!.directions!.length,
                    (index) => AutoSuggestBoxItem(
                      value: MyEntrepriseState.p!.directions![index],
                      label: MyEntrepriseState.p!.directions![index]
                          .toUpperCase(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 3,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: appTheme.color),
              left: Device.orientation == Orientation.portrait
                  ? BorderSide(color: appTheme.color)
                  : BorderSide.none,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('departement', style: formHintStyle).tr(),
                AutoSuggestBox<String>(
                  enabled: !widget.readOnly,
                  placeholder: 'departement'.tr(),
                  placeholderStyle: placeStyle,
                  controller: selectedDepartment,
                  items: List.generate(
                    MyEntrepriseState.p!.departments!.length,
                    (index) => AutoSuggestBoxItem(
                      value: MyEntrepriseState.p!.departments![index],
                      label: MyEntrepriseState.p!.departments![index]
                          .toUpperCase(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> sixthLine(AppTheme appTheme) {
    return [
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                Text('genre', style: formHintStyle).tr(),
                Flexible(
                  child: ListTile(
                    title: AutoSizeText(
                      (VehiclesUtilities.genres![genre ?? -1] ?? 'nonind').tr(),
                      minFontSize: 5,
                      softWrap: true,
                      maxLines: 1,
                    ),
                    onPressed: widget.readOnly
                        ? null
                        : () {
                            SelectDialog.showModal<int>(
                              context,
                              selectedValue: genre,
                              backgroundColor: appTheme.backGroundColor,
                              items: VehiclesUtilities.genres!.keys.toList(),
                              itemBuilder: (c, v, e) {
                                return Container(
                                  padding: const EdgeInsets.all(5.0),
                                  color: v % 2 == 0
                                      ? Colors.transparent
                                      : appTheme.color.lightest,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(v.toString()),
                                      smallSpace,
                                      smallSpace,
                                      smallSpace,
                                      Text(VehiclesUtilities.genres?[v] ?? '')
                                          .tr(),
                                    ],
                                  ),
                                );
                              },
                              onChange: (s) {
                                setState(() {
                                  genre = s;
                                });
                              },
                              onFind: VehiclesUtilities.findGenres,
                              emptyBuilder: (s) {
                                return Center(
                                  child: Text(
                                    'lvide',
                                    style: TextStyle(color: Colors.grey[100]),
                                  ).tr(),
                                );
                              },
                              loadingBuilder: (s) {
                                return Center(
                                  child: Text(
                                    'telechargement',
                                    style: TextStyle(color: Colors.grey[100]),
                                  ).tr(),
                                );
                              },
                              searchBoxDecoration: appTheme.materialUiInputDecoration
                                  .copyWith(
                                    labelText: 'search'.tr(),
                                    labelStyle: placeStyle,
                                  ),
                              searchTextStyle: appTheme.writingStyle,
                              searchCursorColor: appTheme.color,
                              constraints: BoxConstraints.loose(
                                Size(400.px, 400.px),
                              ),
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                Text('marque', style: formHintStyle).tr(),
                Flexible(
                  child: ListTile(
                    leading: Image.asset(
                      'assets/images/marques/${marque == null || marque! <= 0 ? 'default' : marque!}.webp',
                      width: 4.h,
                      height: 4.h,
                    ),
                    title: AutoSizeText(
                      VehiclesUtilities.marques![marque == null || marque! <= 0
                              ? 0
                              : marque!] ??
                          'nonind'.tr(),
                      minFontSize: 5,
                      maxLines: 1,
                    ),
                    onPressed: widget.readOnly
                        ? null
                        : () {
                            SelectDialog.showModal<int?>(
                              context,
                              selectedValue: marque,
                              backgroundColor: appTheme.backGroundColor,
                              gridView: true,
                              numberOfGridCross: 3,
                              constraints: BoxConstraints.loose(
                                Size(60.w, 70.h),
                              ),
                              items: VehiclesUtilities.marques!.keys.toList(),
                              itemBuilder: (c, v, e) {
                                return Card(
                                  child: Image.asset(
                                    'assets/images/marques/${v ?? 'default'}.webp',
                                  ),
                                );
                              },
                              onChange: (s) {
                                setState(() {
                                  marque = s;
                                });
                              },
                              onFind: VehiclesUtilities.findMarque,
                              emptyBuilder: (s) {
                                return Center(
                                  child: Text(
                                    'lvide',
                                    style: TextStyle(color: Colors.grey[100]),
                                  ).tr(),
                                );
                              },
                              loadingBuilder: (s) {
                                return Center(
                                  child: Text(
                                    'telechargement',
                                    style: TextStyle(color: Colors.grey[100]),
                                  ).tr(),
                                );
                              },
                              searchBoxDecoration: appTheme.materialUiInputDecoration
                                  .copyWith(
                                    labelText: 'search'.tr(),
                                    labelStyle: placeStyle,
                                  ),
                              searchTextStyle: appTheme.writingStyle,
                              searchCursorColor: appTheme.color,
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                Text('type', style: formHintStyle).tr(),
                ParcotoTextBox(
                  enabled: !widget.readOnly,
                  controller: type,
                  placeholder: 'type'.tr(),
                  maxLength: 30,
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,
                ),
              ],
            ),
          ),
        ),
      ),
      if (!chassisKey) getChassisWidget(appTheme),
    ];
  }

  Widget getChassisWidget(AppTheme appTheme) {
    return StaggeredGridTile.fit(
      crossAxisCellCount: 6,
      child: Container(
        height: chassisKey ? heightFirst : height,
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Column(
            crossAxisAlignment: chassisKey
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Text(
                'nchassi',
                style: formHintStyle.copyWith(
                  fontSize: chassisKey ? 12 : 10,
                  color: Colors.red,
                ),
              ).tr(),
              if (chassisKey) const Spacer(),
              ParcotoTextBox(
                enabled: !widget.readOnly,
                controller: numSer,
                maxLength: 30,
                placeholder: 'nchassi'.tr(),
                placeholderStyle: placeStyle,
                cursorColor: appTheme.color.darker,
                style: appTheme.writingStyle,
              ),
              if (chassisKey) const Spacer(),
              if (chassisKey)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: SizedBox(
                    height: 22.px,
                    child: errorChassis
                        ? Text(
                            'chassReq',
                            style: TextStyle(color: Colors.red),
                          ).tr()
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> seventhLine(AppTheme appTheme) {
    return [
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                Text('caross', style: formHintStyle).tr(),
                ParcotoTextBox(
                  enabled: !widget.readOnly,
                  controller: caross,
                  maxLength: 30,
                  placeholder: 'caross'.tr(),
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,
                ),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                Text('energie', style: formHintStyle).tr(),
                ParcotoTextBox(
                  enabled: !widget.readOnly,
                  controller: energie,
                  maxLength: 20,
                  placeholder: 'energie'.tr(),
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,
                ),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                Text('puissance', style: formHintStyle).tr(),
                ParcotoTextBox(
                  enabled: !widget.readOnly,
                  placeholder: '0000',
                  controller: puissance,
                  maxLength: 4,
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,

                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                Text('placeassise', style: formHintStyle).tr(),
                ParcotoTextBox(
                  enabled: !widget.readOnly,
                  placeholder: '000',
                  controller: places,
                  maxLength: 3,
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,

                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                Text('poidstotal', style: formHintStyle).tr(),
                ParcotoTextBox(
                  enabled: !widget.readOnly,
                  placeholder: '000000',
                  controller: poidsT,
                  maxLength: 15,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,
                ),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Row(
              children: [
                Text('lourd?', style: formHintStyle).tr(),
                const Spacer(),
                Checkbox(
                  checked: lourd,
                  onChanged: widget.readOnly
                      ? null
                      : (s) {
                          setState(() {
                            lourd = s ?? false;
                          });
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> eightLine(AppTheme appTheme) {
    return [
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                Text('chargeutil', style: formHintStyle).tr(),
                ParcotoTextBox(
                  enabled: !widget.readOnly,
                  placeholder: '000000',
                  controller: charg,
                  maxLength: 15,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,
                ),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 4,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                Text('anneeutil', style: formHintStyle).tr(),
                Flexible(
                  child: DatePicker(
                    showDay: false,
                    showMonth: false,
                    selected: selectedAnnee,
                    onChanged: widget.readOnly
                        ? null
                        : (s) {
                            setState(() {
                              selectedAnnee = s;
                            });
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 12,
        child: Container(
          height: heightFirst,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                Text('precmat', style: formHintStyle).tr(),
                Flexible(
                  child: ListView(
                    children: [
                      m.Material(
                        color: appTheme.backGroundColor,
                        child: ChipTags(
                          list: matriculesPrec,
                          iconColor: appTheme.color.darkest,
                          chipColor: appTheme.color.lightest,
                          textColor: appTheme.writingStyle.color!,
                          decoration: m.InputDecoration(
                            hintText: 'entervalues'.tr(),
                            hintStyle: placeStyle,
                            fillColor: appTheme.backGroundColor,
                          ),
                          createTagOnSubmit: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  void selectConducteur(AppTheme appTheme) async {
    Conducteur? conducteur = await showDialog<Conducteur>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return ContentDialog(
          constraints: BoxConstraints.tight(Size(700.px, 550.px)),
          title: const Text('selectchauffeur').tr(),
          style: ContentDialogThemeData(
            titleStyle: appTheme.writingStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const ChauffeurTable(selectD: true),
          actions: [
            Button(
              child: const Text('fermer').tr(),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    if (conducteur != null) {
      selectedAppartenanceEmploye.text = VehiclesUtilities.getAppartenance(
        conducteur.filliale,
      );
      adresse.text = conducteur.adresse ?? '';
      fname.text = conducteur.prenom;
      matempl.text = conducteur.matricule;
      lname.text = conducteur.name;
      service = conducteur.service;
      profession.text = conducteur.profession ?? '';
      setState(() {});
    }
  }

  void updateOverMatricule(AppTheme appTheme) {
    if (!autreMat) {
      if (matr3.text.isNotEmpty) {
        wilaya = matr3.text;
        wilayaCont.text = AlgeriaList().getWilayaByNum(matr3.text) ?? '';
        dairaCont.text =
            AlgeriaList()
                .getDairas(wilayaCont.text)
                .firstOrNull
                ?.getDairaName(
                  appTheme.locale?.languageCode.toUpperCase() == "AR"
                      ? Language.AR
                      : Language.FR,
                ) ??
            '';
        communeCont.text =
            AlgeriaList()
                .getCommune(wilayaCont.text)
                .firstOrNull
                ?.getDairaName(
                  appTheme.locale?.languageCode.toUpperCase() == "AR"
                      ? Language.AR
                      : Language.FR,
                ) ??
            '';
        setState(() {});
      }
      if (matr2.text.isNotEmpty) {
        genre = (int.tryParse(matr2.text) ?? 100) ~/ 100;
        selectedAnnee = DateTime(
          VehiclesUtilities.getAnneeFromMatricule('0000-${matr2.text}-00'),
        );
        setState(() {});
      }
    }
  }

  String? documentID;
  bool uploading = false;
  bool errorUploading = false;
  bool errorChassis = false;
  Future<void> confirmAndUpload() async {
    final matriculeIsValid = autreMat
        ? matriculeEtr.text.trim().length >= 4
        : matr1.text.trim().isNotEmpty &&
              matr2.text.trim().length >= 3 &&
              matr3.text.trim().length >= 2;
    final chassisIsValid = !chassisKey || numSer.text.trim().isNotEmpty;
    final acquisitionDate = acquisitionDateController.text.trim();
    final warrantyEndDate = warrantyEndDateController.text.trim();
    final hasInvalidDate =
        (acquisitionDate.isNotEmpty &&
            DateTime.tryParse(acquisitionDate) == null) ||
        (warrantyEndDate.isNotEmpty &&
            DateTime.tryParse(warrantyEndDate) == null);

    if (hasInvalidDate) {
      if (!mounted) return;
      displayInfoBar(
        context,
        builder: (context, close) => const InfoBar(
          title: Text('Date invalide. Utilisez le format AAAA-MM-JJ.'),
          severity: InfoBarSeverity.error,
        ),
        duration: snackbarShortDuration,
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      erreurMatricule = !matriculeIsValid;
      errorChassis = !chassisIsValid;
    });

    // Do not persist an incomplete vehicle record.
    if (!matriculeIsValid || !chassisIsValid) return;

    if (mounted) {
      setState(() {
        uploading = true;
        errorUploading = false;
      });
      Vehicle vehicle = Vehicle(
        id: documentID!,
        matricule: autreMat
            ? matriculeEtr.text
            : '${matr1.text}-${matr2.text}-${matr3.text}',
        matriculeEtrang: autreMat,
        wilaya: int.tryParse(wilaya),
        commune: communeCont.text,
        date: selectedDate,
        adresse: adresse.text,
        quittance: double.tryParse(quittance.text),
        numero: numero.text,
        numeroSerie: numSer.text,
        // Preserve extended data while editing a vehicle in the legacy form.
        trim: _nullableText(trimController.text),
        modelYear: int.tryParse(modelYearController.text.trim()),
        color: _nullableText(colorController.text),
        engineDisplacement: int.tryParse(engineDisplacementController.text.trim()),
        engineCode: _nullableText(engineCodeController.text),
        transmission: _nullableText(transmissionController.text),
        gearbox: _nullableText(gearboxController.text),
        driveType: _nullableText(driveTypeController.text),
        doors: int.tryParse(doorsController.text.trim()),
        lengthMm: int.tryParse(lengthController.text.trim()),
        widthMm: int.tryParse(widthController.text.trim()),
        heightMm: int.tryParse(heightController.text.trim()),
        acquisitionType: _nullableText(acquisitionTypeController.text),
        acquisitionDate: _nullableText(acquisitionDateController.text),
        purchasePrice: double.tryParse(
          purchasePriceController.text.trim().replaceAll(',', '.'),
        ),
        supplier: _nullableText(supplierController.text),
        warrantyEndDate: _nullableText(warrantyEndDateController.text),
        fleetNumber: _nullableText(fleetNumberController.text),
        currentMileage: int.tryParse(mileageController.text.trim()),
        nextServiceMileage: int.tryParse(nextServiceMileageController.text.trim()),
        // Image and custom metadata are preserved until their dedicated editors exist.
        imageFileId: widget.vehicle?.imageFileId,
        imageUrl: widget.vehicle?.imageUrl,
        imageSource: widget.vehicle?.imageSource,
        customFields: widget.vehicle?.customFields,
        anneeUtil: selectedAnnee?.year,
        energie: energie.text,
        pays: pays,
        placesAssises: int.tryParse(places.text),
        poidsTotal: int.tryParse(poidsT.text),
        prenom: fname.text,
        nom: lname.text,
        type: type.text,
        profession: profession.text,
        puissance: int.tryParse(puissance.text),
        daira: dairaCont.text,
        genre: genre?.toString(),
        marque: marque?.toString(),
        matriculePrec: matriculesPrec,
        carrosserie: caross.text,
        charegeUtile: int.tryParse(charg.text),
        createdBy: DatabaseGetter.me.value?.id,
        lourd: lourd,
        direction: selectedDirection.text
            .toUpperCase()
            .replaceAll(' ', '')
            .trim(),
        appartenance: selectedAppartenance.text
            .toUpperCase()
            .replaceAll(' ', '')
            .trim(),
        filliale: selectedFiliale.text.toUpperCase().replaceAll(' ', '').trim(),
        departement: selectedDepartment.text
            .toUpperCase()
            .replaceAll(' ', '')
            .trim(),
        appartenanceconducteur: selectedAppartenanceEmploye.text
            .toUpperCase()
            .replaceAll(' ', '')
            .trim(),
        service: service,
        matriculeConducteur: matempl.text,
      );
      final isUpdate = widget.vehicle != null;
      try {
        // The repository writes to SQLite and queues the remote mutation.
        // A failure in the legacy remote-only activity log must not turn a
        // successful local save into a visible upload failure.
        if (isUpdate) {
          await updateVehicle(vehicle);
        } else {
          await createVehicle(vehicle);
        }

        if (mounted) {
          displayInfoBar(
            context,
            builder: (BuildContext context, void Function() close) => InfoBar(
              title: const Text('done').tr(),
              severity: InfoBarSeverity.success,
            ),
            duration: snackbarShortDuration,
          );
          setState(() {
            uploading = false;
            errorUploading = false;
          });
        }

        try {
          await uploadActivity(isUpdate, vehicle);
        } catch (_) {
          // Activity logging remains best-effort while offline.
        }
      } catch (_) {
        if (mounted) {
          displayInfoBar(
            context,
            builder: (BuildContext context, void Function() close) => InfoBar(
              title: const Text('echec').tr(),
              severity: InfoBarSeverity.error,
            ),
            duration: snackbarShortDuration,
          );
          setState(() {
            errorUploading = true;
            uploading = false;
          });
        }
      }
    }
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    vehicle.updatedAt = DateTime.now().toUtc();
    final domainVehicle = VehicleMapper.toDomain(
      vehicle,
      companyId: project ?? 'local',
    );
    await vehicleServices.repository.updateVehicle(domainVehicle);
  }

  Future<void> createVehicle(Vehicle vehicle) async {
    final now = DateTime.now().toUtc();
    vehicle.createdAt = now;
    vehicle.updatedAt = now;
    final domainVehicle = VehicleMapper.toDomain(
      vehicle,
      companyId: project ?? 'local',
    );
    await vehicleServices.repository.createVehicle(domainVehicle);
  }

  Future<void> uploadActivity(bool update, Vehicle vehicle) async {
    if (update) {
      await DatabaseGetter().ajoutActivity(
        1,
        vehicle.id,
        docName: vehicle.matricule,
      );
    } else {
      await DatabaseGetter().ajoutActivity(
        0,
        vehicle.id,
        docName: vehicle.matricule,
      );
    }
  }

  @override
  bool get wantKeepAlive => true;
}
