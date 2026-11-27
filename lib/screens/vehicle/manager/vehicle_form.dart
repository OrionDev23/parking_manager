import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:image_picker/image_picker.dart';
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
import '../../../core/services/vehicle_image_service.dart';
import '../../../core/services/vehicle_make_service.dart';
import '../../../core/services/vehicle_vin_service.dart';
import '../../../data/mappers/vehicle_mapper.dart';
import '../../../main.dart';
import '../../../theme.dart';
import '../../../utilities/algeria_lists.dart';
import '../../../widgets/select_dialog/select_dialog.dart';
import '../../../widgets/forms/parcoto_form_field.dart';

Size _responsiveVehicleCountryDialogSize(BuildContext context) {
  final screenSize = MediaQuery.sizeOf(context);
  return Size(
    (screenSize.width - 32).clamp(280.0, 520.0).toDouble(),
    (screenSize.height - 80).clamp(320.0, 600.0).toDouble(),
  );
}

BoxConstraints _responsiveVehiclePickerConstraints(
  BuildContext context, {
  required double maxWidth,
  required double maxHeight,
}) {
  final screenSize = MediaQuery.sizeOf(context);
  return BoxConstraints.loose(
    Size(
      (screenSize.width - 32).clamp(260.0, maxWidth).toDouble(),
      (screenSize.height - 80).clamp(280.0, maxHeight).toDouble(),
    ),
  );
}


const List<Map<String, String>> _vehiclePaintOptions = [
  {'value': 'original', 'label': 'Peinture d’origine'},
  {'value': 'white', 'label': 'Blanc'},
  {'value': 'black', 'label': 'Noir'},
  {'value': 'silver', 'label': 'Argent'},
  {'value': 'grey', 'label': 'Gris foncé'},
  {'value': 'blue', 'label': 'Bleu'},
  {'value': 'red', 'label': 'Rouge'},
];

const Map<String, Color> _vehiclePaintSwatches = {
  'original': Color(0xFF8A8A8A),
  'white': Color(0xFFF3F3F3),
  'black': Color(0xFF202124),
  'silver': Color(0xFFB9BEC5),
  'grey': Color(0xFF62676D),
  'blue': Color(0xFF2563B8),
  'red': Color(0xFFCC3636),
};

String _normalizeVehiclePaint(String? value) {
  final normalized = (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ');

  switch (normalized) {
    case '':
    case 'original':
    case 'origine':
    case 'peinture d origine':
    case 'couleur d origine':
    case 'original paint':
    case 'default':
      return 'original';
    case 'white':
    case 'blanc':
    case 'blanche':
      return 'white';
    case 'black':
    case 'noir':
    case 'noire':
      return 'black';
    case 'silver':
    case 'argent':
    case 'argente':
    case 'argenté':
    case 'gris clair':
    case 'gris metallise':
    case 'gris métallisé':
      return 'silver';
    case 'grey':
    case 'gray':
    case 'gris':
    case 'gris fonce':
    case 'gris foncé':
    case 'anthracite':
      return 'grey';
    case 'blue':
    case 'bleu':
    case 'bleue':
      return 'blue';
    case 'red':
    case 'rouge':
      return 'red';
    default:
      return 'original';
  }
}

class VehicleForm extends StatefulWidget {
  final Vehicle? vehicle;
  final Tab? tab;

  final bool readOnly;
  final VoidCallback? onCancel;
  final ValueChanged<Vehicle>? onSaved;

  const VehicleForm({
    super.key,
    this.vehicle,
    this.tab,
    this.readOnly = false,
    this.onCancel,
    this.onSaved,
  });

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
  final enginePowerHpController = TextEditingController();
  final enginePowerKwController = TextEditingController();
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

  String? _resolvedImageUrl;
  String? _resolvedImageFileId;
  String? _resolvedImageMake;
  String? _resolvedImageModel;
  int? _resolvedImageYear;
  String? _resolvedImageColor;
  String? _vehicleImageMessage;
  String? _resolvedImageSource;
  String? _resolvedImageLicense;
  String? _resolvedImageLicenseUrl;
  String? _resolvedImageSourceUrl;
  String? _resolvedImageAttribution;
  bool _resolvingVehicleImage = false;
  bool _vehicleImageLookupCompleted = false;
  List<VehicleImageCandidate> _vehicleImageCandidates = [];
  bool _canUploadVehicleImage = false;
  bool _canForceRefreshVehicleImage = false;
  bool _decodingVin = false;
  String? _vinDecodeMessage;
  Map<String, dynamic>? _vinDecodeMetadata;
  final ImagePicker _vehicleImagePicker = ImagePicker();
  bool autreMat = false;
  String? marque;

  bool erreurMatricule = false;

  int? genre;

  String pays = 'DZ';

  final double height = 72.px;
  final double heightFirst = 118.px;

  // Responsive layout is width-based: the mobile browser viewport height can
  // shrink when the virtual keyboard opens and must not change form geometry.
  bool get _isCompactViewport => MediaQuery.sizeOf(context).width < 640;

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
    super.initState();
    initValues();
    unawaited(
      VehicleMakeService.load().then((_) {
        if (!mounted) return;
        if (widget.vehicle?.imageUrl?.isNotEmpty == true) {
          _resolvedImageMake = VehicleMakeService.nameFor(marque);
        }
        setState(() {});
      }),
    );
    unawaited(_loadVehicleImageCapabilities());
  }

  void initValues() {
    _resolvedImageUrl = widget.vehicle?.imageUrl;
    _resolvedImageFileId = widget.vehicle?.imageFileId;
    _resolvedImageSource = widget.vehicle?.imageSource;
    colorController.text = _normalizeVehiclePaint(widget.vehicle?.color);
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
      marque = VehicleMakeService.canonicalId(widget.vehicle!.marque);
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
      service = widget.vehicle!.service;

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
      colorController.text = _normalizeVehiclePaint(widget.vehicle!.color);
      engineDisplacementController.text =
          widget.vehicle!.engineDisplacement?.toString() ?? '';
      enginePowerHpController.text = widget.vehicle!.enginePowerHp?.toString() ?? '';
      enginePowerKwController.text = widget.vehicle!.enginePowerKw?.toString() ?? '';
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
    // Treat an existing image as resolved for the vehicle's current identity.
    // New or image-less vehicles will be looked up when saved.
    if (widget.vehicle?.imageUrl?.isNotEmpty == true) {
      _resolvedImageMake = VehicleMakeService.nameFor(marque);
      _resolvedImageModel = type.text.trim();
      _resolvedImageYear = int.tryParse(modelYearController.text.trim());
      _resolvedImageColor = _normalizeVehiclePaint(colorController.text);
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
      padding: EdgeInsets.zero,
      content: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final showSummary = constraints.maxWidth >= 1220;

          final formContent = Container(
            padding: EdgeInsets.all(compact ? 12 : 20),
            decoration: BoxDecoration(
              color: FluentTheme.of(context).micaBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[30]),
            ),
            child: StaggeredGrid.count(
              crossAxisCount: 12,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: gridChildren(appTheme),
            ),
          );

          return Container(
            color: appTheme.backGroundColor,
            child: Column(
              children: [
                _buildEditorHeader(appTheme),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 24,
                      vertical: compact ? 14 : 22,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1380),
                        child: showSummary
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 7, child: formContent),
                                  const SizedBox(width: 20),
                                  SizedBox(
                                    width: 300,
                                    child: _buildEditorSummary(appTheme),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [formContent],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomBar: widget.readOnly
          ? null
          : LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 680;
                final message = errorUploading
                    ? Text(
                        'errupld',
                        style: TextStyle(color: Colors.red),
                      ).tr()
                    : const Text(
                        'Les modifications ne sont enregistrées qu’après confirmation.',
                        style: TextStyle(fontSize: 11),
                      );
                final actions = <Widget>[
                  if (widget.onCancel != null)
                    Button(
                      onPressed: uploading ? null : widget.onCancel,
                      child: const Text('Annuler'),
                    ),
                  FilledButton(
                    onPressed: uploading ? null : confirmAndUpload,
                    child: uploading
                        ? const ProgressRing()
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(FluentIcons.save, size: 14),
                              SizedBox(width: 8),
                              Text('Enregistrer le véhicule'),
                            ],
                          ),
                  ),
                ];

                return Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 9,
                    horizontal: compact ? 12 : 18,
                  ),
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            message,
                            const SizedBox(height: 9),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 8,
                              runSpacing: 8,
                              children: actions,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: message),
                            ...actions.expand((action) => [
                                  if (action != actions.first)
                                    const SizedBox(width: 10),
                                  action,
                                ]),
                          ],
                        ),
                );
              },
            ),
    );
  }

  Widget _buildEditorHeader(AppTheme appTheme) {
    final isEditing = widget.vehicle != null;
    final registration = widget.vehicle?.matricule ??
        (autreMat ? matriculeEtr.text : [matr1.text, matr2.text, matr3.text]
            .where((part) => part.trim().isNotEmpty).join('-'));
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Modifier un véhicule' : 'Nouveau véhicule',
              style: TextStyle(
                fontSize: compact ? 17 : 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              registration.isEmpty
                  ? 'Fiche véhicule · Parcoto'
                  : '$registration · Fiche véhicule',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[100], fontSize: 12),
            ),
          ],
        );
        final status = Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _headerPill(
              isEditing ? FluentIcons.edit : FluentIcons.add,
              isEditing ? 'Modification' : 'Création',
              appTheme.color,
            ),
            _headerPill(
              widget.readOnly ? FluentIcons.lock : FluentIcons.edit,
              widget.readOnly ? 'Consultation' : 'Brouillon',
              widget.readOnly ? Colors.grey : appTheme.color,
            ),
          ],
        );
        return Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 24,
            compact ? 14 : 20,
            compact ? 14 : 24,
            compact ? 14 : 18,
          ),
          decoration: BoxDecoration(
            color: FluentTheme.of(context).micaBackgroundColor,
            border: Border(bottom: BorderSide(color: Colors.grey[30])),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: appTheme.color.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(FluentIcons.car, size: 21, color: appTheme.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: title),
                      ],
                    ),
                    const SizedBox(height: 12),
                    status,
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: appTheme.color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(FluentIcons.car, size: 26, color: appTheme.color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: title),
                    status,
                  ],
                ),
        );
      },
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

  Widget _buildEditorSummary(AppTheme appTheme) {
    final previewListenable = Listenable.merge([
      matriculeEtr,
      matr1,
      matr2,
      matr3,
      type,
      modelYearController,
      fleetNumberController,
      mileageController,
      matempl,
      selectedFiliale,
      selectedDirection,
    ]);

    return AnimatedBuilder(
      animation: previewListenable,
      builder: (context, _) {
        final typedRegistration = autreMat
            ? matriculeEtr.text.trim()
            : [matr1.text, matr2.text, matr3.text]
                .map((part) => part.trim())
                .where((part) => part.isNotEmpty)
                .join('-');
        final registration = typedRegistration.isNotEmpty
            ? typedRegistration
            : widget.vehicle?.matricule ?? 'À définir';
        final brandName = marque == null
            ? VehiclesUtilities.getMarqueName(widget.vehicle?.marque)
            : VehicleMakeService.nameFor(marque);
        final modelName = type.text.trim().isNotEmpty
            ? type.text.trim()
            : widget.vehicle?.type;
        final modelYear = modelYearController.text.trim().isNotEmpty
            ? modelYearController.text.trim()
            : widget.vehicle?.modelYear?.toString();
        final vehicleName = [
          brandName,
          modelName,
          modelYear,
        ].where((value) => value != null && value.trim().isNotEmpty).join(' ');
        final fleetNumber = fleetNumberController.text.trim();
        final mileage = mileageController.text.trim();
        final driver = matempl.text.trim().isNotEmpty
            ? matempl.text.trim()
            : widget.vehicle?.matriculeConducteur ?? 'À associer';
        final branch = selectedFiliale.text.trim().isNotEmpty
            ? selectedFiliale.text.trim()
            : widget.vehicle?.filliale ?? 'À renseigner';
        final direction = selectedDirection.text.trim().isNotEmpty
            ? selectedDirection.text.trim()
            : widget.vehicle?.direction ?? 'À renseigner';
        final imageUrl = _resolvedImageUrl?.trim();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: FluentTheme.of(context).micaBackgroundColor,
                border: Border.all(color: Colors.grey[30]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(
                      child: Text(
                        'APERÇU DU VÉHICULE',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(FluentIcons.car, size: 14, color: Colors.grey[100]),
                  ]),
                  const SizedBox(height: 14),
                  Container(
                    height: 118,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: appTheme.color.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                FluentIcons.car,
                                size: 42,
                                color: appTheme.color,
                              ),
                            ),
                          )
                        : Icon(
                            FluentIcons.car,
                            size: 42,
                            color: appTheme.color,
                          ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    vehicleName.isEmpty
                        ? 'Marque et modèle à renseigner'
                        : vehicleName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    registration,
                    style: TextStyle(fontSize: 12, color: Colors.grey[100]),
                  ),
                  const SizedBox(height: 12),
                  _summaryLine(
                    FluentIcons.document,
                    'N° de parc',
                    fleetNumber.isEmpty ? 'Non défini' : fleetNumber,
                  ),
                  _summaryLine(
                    FluentIcons.car,
                    'Kilométrage',
                    mileage.isEmpty ? 'Non renseigné' : '$mileage km',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _summaryCard('AFFECTATION', [
              ('Conducteur', driver),
              ('Filiale', branch),
              ('Direction', direction),
            ]),
          ],
        );
      },
    );
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

  List<Widget> gridChildren(AppTheme appTheme) {
    return [
      _buildVehicleIdentitySection(appTheme),
      _sectionHeader(
        appTheme,
        'Informations administratives algériennes',
        'Immatriculation, carte grise, titulaire et localisation administrative',
      ),
      ...getWilayaCommuneWidget(appTheme),
      ...secondLine(appTheme),
      if (conducteurEmploye) ...[
        _sectionHeader(
          appTheme,
          'Propriétaire et conducteur',
          'Identité du propriétaire et conducteur actuellement associé',
        ),
        ...thirdLine(appTheme),
        ...forthLine(appTheme),
      ],
      _sectionHeader(
        appTheme,
        'Organisation et rattachement',
        'Appartenance, filiale, direction et département',
      ),
      ...fifthLine(appTheme),
      _sectionHeader(
        appTheme,
        'Caractéristiques techniques',
        'Motorisation, transmission, dimensions et capacités',
      ),
      ...seventhLine(appTheme),
      _buildProfessionalDetailsSection(appTheme),
      _sectionHeader(
        appTheme,
        'Historique des immatriculations',
        'Anciennes immatriculations connues pour ce véhicule',
      ),
      ...eightLine(appTheme),
    ];
  }
  Widget _buildVehicleIdentitySection(AppTheme appTheme) {
    return StaggeredGridTile.fit(
      crossAxisCellCount: _isCompactViewport ? 12 : 12,
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
                            'Identité et photo du véhicule',
                            style: appTheme.writingStyle.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Immatriculation algérienne et caractéristiques constructeur',
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
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: appTheme.color.withValues(alpha: .055),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: appTheme.color.withValues(alpha: .16),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, imageConstraints) {
                      final compactImage = imageConstraints.maxWidth < 520;
                      final image = Container(
                        width: compactImage ? double.infinity : 176,
                        height: 112,
                        decoration: BoxDecoration(
                          color: appTheme.backGroundColor,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _resolvedImageUrl != null &&
                                _resolvedImageUrl!.isNotEmpty
                            ? Image.network(
                                _resolvedImageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => Icon(
                                  FluentIcons.car,
                                  size: 38,
                                  color: appTheme.color,
                                ),
                              )
                            : Icon(
                                FluentIcons.car,
                                size: 38,
                                color: appTheme.color,
                              ),
                      );
                      final controls = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            const Text(
                              'IMAGE DU VÉHICULE',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: .8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _vehicleImageMessage ??
                                  'L’année choisie sert à retrouver la génération la plus proche. Choisissez aussi la couleur souhaitée.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.35,
                                color: appTheme.writingStyle.color
                                    ?.withValues(alpha: .72),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (!widget.readOnly)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FilledButton(
                                    onPressed: _resolvingVehicleImage
                                        ? null
                                        : () => _resolveVehicleImage(),
                                    child: _resolvingVehicleImage
                                        ? const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ProgressRing(strokeWidth: 2),
                                              SizedBox(width: 8),
                                              Text('Recherche…'),
                                            ],
                                          )
                                        : const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(FluentIcons.search, size: 13),
                                              SizedBox(width: 7),
                                              Text('Comparer les images'),
                                            ],
                                          ),
                                  ),
                                  if (_canForceRefreshVehicleImage)
                                    Button(
                                      onPressed: _resolvingVehicleImage
                                          ? null
                                          : () => _resolveVehicleImage(
                                                forceRefresh: true,
                                              ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(FluentIcons.refresh, size: 13),
                                          SizedBox(width: 7),
                                          Text('Comparer et remplacer'),
                                        ],
                                      ),
                                    ),
                                  if (_canUploadVehicleImage &&
                                      _vehicleImageLookupCompleted &&
                                      _vehicleImageCandidates.isEmpty &&
                                      !(_resolvedImageUrl?.isNotEmpty ?? false))
                                    FilledButton(
                                      onPressed: _resolvingVehicleImage
                                          ? null
                                          : () => _pickAndUploadVehicleImage(
                                                ImageSource.gallery,
                                              ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(FluentIcons.upload, size: 13),
                                          SizedBox(width: 7),
                                          Text('Importer une photo'),
                                        ],
                                      ),
                                    ),
                                  if (_canUploadVehicleImage &&
                                      _vehicleImageLookupCompleted &&
                                      _vehicleImageCandidates.isEmpty &&
                                      !(_resolvedImageUrl?.isNotEmpty ?? false))
                                    Button(
                                      onPressed: _resolvingVehicleImage
                                          ? null
                                          : () => _pickAndUploadVehicleImage(
                                                ImageSource.camera,
                                              ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(FluentIcons.camera, size: 13),
                                          SizedBox(width: 7),
                                          Text('Prendre une photo'),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            if (_vehicleImageCandidates.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'COMPARER LES SOURCES',
                                      style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: .7,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _vehicleImageCandidates.map((candidate) {
                                        final sourceLabel =
                                            _vehicleImageSourceLabel(candidate.source);
                                        return SizedBox(
                                          width: 164,
                                          child: Button(
                                            onPressed: _resolvingVehicleImage
                                                ? null
                                                : () => _selectVehicleImageCandidate(candidate),
                                            child: SizedBox(
                                              width: 148,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(7),
                                                    child: Image.network(
                                                      candidate.imageUrl,
                                                      width: 148,
                                                      height: 82,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, _, _) => Container(
                                                        width: 148,
                                                        height: 82,
                                                        color: appTheme.backGroundColor,
                                                        alignment: Alignment.center,
                                                        child: const Icon(FluentIcons.car),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    sourceLabel,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  if (candidate.colorFallback)
                                                    const Text(
                                                      'Couleur non vérifiée',
                                                      style: TextStyle(fontSize: 9),
                                                    )
                                                  else if (candidate.license?.isNotEmpty == true)
                                                    Text(
                                                      candidate.license!,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 9),
                                                    ),
                                                  if (candidate.attribution?.isNotEmpty == true)
                                                    Text(
                                                      candidate.attribution!,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 9),
                                                    ),
                                                  const SizedBox(height: 5),
                                                  const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(FluentIcons.check_mark, size: 11),
                                                      SizedBox(width: 5),
                                                      Text(
                                                        'Choisir cette image',
                                                        style: TextStyle(fontSize: 10),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            if (_resolvedImageAttribution?.isNotEmpty == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Crédit : $_resolvedImageAttribution'
                                        '${_resolvedImageLicense?.isNotEmpty == true ? ' · $_resolvedImageLicense' : ''}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: appTheme.writingStyle.color
                                              ?.withValues(alpha: .65),
                                        ),
                                      ),
                                    ),
                                    if (_resolvedImageSourceUrl?.isNotEmpty == true ||
                                        _resolvedImageLicenseUrl?.isNotEmpty == true)
                                      Tooltip(
                                        message: [
                                          if (_resolvedImageSourceUrl?.isNotEmpty == true)
                                            'Source : $_resolvedImageSourceUrl',
                                          if (_resolvedImageLicenseUrl?.isNotEmpty == true)
                                            'Licence : $_resolvedImageLicenseUrl',
                                        ].join('\\n'),
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 6),
                                          child: Icon(
                                            FluentIcons.info,
                                            size: 13,
                                            color: appTheme.writingStyle.color
                                                ?.withValues(alpha: .65),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                        ],
                      );
                      return compactImage
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                image,
                                const SizedBox(height: 10),
                                controls,
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                image,
                                const SizedBox(width: 14),
                                Expanded(child: controls),
                              ],
                            );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: spacing,
                  runSpacing: 14,
                  children: [
                    _identitySubsectionTitle(
                      appTheme,
                      availableWidth,
                      'Immatriculation algérienne',
                      'Numéro d’immatriculation et informations de la carte grise',
                    ),
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
                                    textAlign: TextAlign.center,                                    style: appTheme.writingStyle,
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
                                  constraints: _responsiveVehiclePickerConstraints(
                                    context,
                                    maxWidth: 400,
                                    maxHeight: 450,
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
                    _identitySubsectionTitle(
                      appTheme,
                      availableWidth,
                      'Caractéristiques constructeur',
                      'Marque, modèle, finition, année modèle et numéro VIN',
                    ),
                    _identityField(
                      appTheme,
                      width: fieldWidth,
                      label: 'Marque',
                      child: Button(
                        onPressed: widget.readOnly ? null : _selectVehicleMake,
                        child: Row(
                          children: [
                            VehicleMakeLogo(makeId: marque, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                VehicleMakeService.nameFor(marque).isEmpty
                                    ? 'Choisir une marque'
                                    : VehicleMakeService.nameFor(marque),
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
                    if (chassisKey)
                      _identityField(
                        appTheme,
                        width: fieldWidth,
                        label: 'Numéro de châssis (VIN)',
                        requiredField: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ParcotoTextBox(
                              enabled: !widget.readOnly,
                              controller: numSer,
                              maxLength: 30,
                              placeholder: '17 caractères généralement',
                              style: appTheme.writingStyle,
                              placeholderStyle: placeStyle,
                              cursorColor: appTheme.color,
                              onChanged: (_) {
                                if (_vinDecodeMetadata != null) {
                                  setState(() {
                                    _vinDecodeMetadata = null;
                                    _vinDecodeMessage =
                                        'VIN modifié : relancez le décodage pour actualiser les données proposées.';
                                  });
                                }
                              },
                            ),
                            if (!widget.readOnly) ...[
                              const SizedBox(height: 7),
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Button(
                                  onPressed: _decodingVin ? null : _decodeVehicleVin,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_decodingVin)
                                        const ProgressRing(strokeWidth: 2)
                                      else
                                        const Icon(FluentIcons.search, size: 13),
                                      const SizedBox(width: 7),
                                      Text(
                                        _decodingVin
                                            ? 'Décodage en cours…'
                                            : 'Décoder le VIN',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (_vinDecodeMessage?.isNotEmpty == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _vinDecodeMessage!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    height: 1.3,
                                    color: _vinDecodeMessage!.startsWith('Échec')
                                        ? Colors.red
                                        : appTheme.writingStyle.color
                                            ?.withValues(alpha: .75),
                                  ),
                                ),
                              ),
                          ],
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

    Widget dateField(String label, TextEditingController controller) {
      final selected = DateTime.tryParse(controller.text.trim());
      return _identityField(
        appTheme,
        width: fieldWidth,
        label: label,
        child: ParcotoFieldSurface(
          child: IgnorePointer(
            ignoring: widget.readOnly,
            child: Opacity(
              opacity: widget.readOnly ? 0.65 : 1,
              child: DatePicker(
                selected: selected,
                locale: appTheme.locale,
                startDate: DateTime(1900),
                endDate: DateTime(2100),
                onChanged: (date) {
                  final year = date.year.toString().padLeft(4, '0');
                  final month = date.month.toString().padLeft(2, '0');
                  final day = date.day.toString().padLeft(2, '0');
                  controller.text = '$year-$month-$day';
                  setState(() {});
                },
              ),
            ),
          ),
        ),
      );
    }

    return StaggeredGridTile.fit(
      crossAxisCellCount: _isCompactViewport ? 12 : 12,
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
                _identityField(
                  appTheme,
                  width: fieldWidth,
                  label: 'Couleur',
                  child: ParcotoFieldSurface(
                    child: ComboBox<String>(
                      value: _normalizeVehiclePaint(colorController.text),
                      isExpanded: true,
                      items: _vehiclePaintOptions.map((option) {
                        final value = option['value']!;
                        return ComboBoxItem<String>(
                          value: value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 13,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: _vehiclePaintSwatches[value],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey[100],
                                    width: value == 'white' ? 1 : 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 9),
                              Text(option['label']!),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: widget.readOnly
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => colorController.text = value);
                            },
                    ),
                  ),
                ),
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
                dateField('Date d’acquisition', acquisitionDateController),
                field('Prix d’acquisition (DA)', purchasePriceController,
                    hint: 'Montant en DA', decimal: true),
                field('Fournisseur / vendeur', supplierController),
                dateField('Fin de garantie', warrantyEndDateController),
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

  Widget _identitySubsectionTitle(
    AppTheme appTheme,
    double width,
    String title,
    String subtitle,
  ) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: appTheme.writingStyle.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: appTheme.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: appTheme.writingStyle.copyWith(
                fontSize: 10,
                color: appTheme.writingStyle.color?.withValues(alpha: .65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _decodeVehicleVin() async {
    if (widget.readOnly || _decodingVin) return;
    final vin = numSer.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (!RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(vin)) {
      setState(() {
        _vinDecodeMessage =
            'Saisissez un VIN valide de 17 caractères (sans I, O ni Q).';
      });
      return;
    }

    setState(() {
      _decodingVin = true;
      _vinDecodeMessage = 'Interrogation des décodeurs VIN…';
    });

    try {
      final result = await VehicleVinService.decode(
        companyId: vehicleServices.companyId,
        vin: vin,
      );
      if (!mounted) return;

      if (result.status == 'not_found') {
        setState(() {
          _vinDecodeMetadata = null;
          _vinDecodeMessage =
              'Aucune fiche constructeur exploitable n’a été retournée.';
        });
        return;
      }

      try {
        await VehicleMakeService.load();
      } catch (_) {
        // Keep the cached/legacy make catalogue available when offline.
      }

      final data = result.data;
      var populated = 0;

      void fillIfEmpty(TextEditingController controller, dynamic rawValue) {
        final value = rawValue?.toString().trim() ?? '';
        if (controller.text.trim().isEmpty && value.isNotEmpty) {
          controller.text = value;
          populated++;
        }
      }

      final decodedMake = data['make']?.toString().trim() ?? '';
      if ((marque ?? '').trim().isEmpty && decodedMake.isNotEmpty) {
        final normalizedMake = VehicleMakeService.normalize(decodedMake);
        VehicleMake? matchedMake;
        for (final candidate in VehicleMakeService.cached) {
          if (VehicleMakeService.normalize(candidate.name) == normalizedMake ||
              candidate.aliases.any(
                (alias) =>
                    VehicleMakeService.normalize(alias) == normalizedMake,
              )) {
            matchedMake = candidate;
            break;
          }
        }
        marque = matchedMake?.id ??
            VehicleMakeService.canonicalId(decodedMake) ??
            decodedMake;
        populated++;
      }

      fillIfEmpty(type, data['model']);
      fillIfEmpty(trimController, data['trim']);
      fillIfEmpty(modelYearController, data['modelYear']);
      fillIfEmpty(caross, data['body']);
      fillIfEmpty(energie, data['fuel']);
      fillIfEmpty(engineDisplacementController, data['engineDisplacementCc']);
      fillIfEmpty(enginePowerHpController, data['enginePowerHp']);
      fillIfEmpty(enginePowerKwController, data['enginePowerKw']);
      fillIfEmpty(engineCodeController, data['engineCode'] ?? data['engine']);
      fillIfEmpty(transmissionController, data['transmission']);
      fillIfEmpty(driveTypeController, data['drive']);
      fillIfEmpty(doorsController, data['doors']);

      final providerLabel = result.providers.isEmpty
          ? 'source inconnue'
          : result.providers.join(' + ');
      final warningText = result.warnings.isEmpty
          ? ''
          : ' ' + result.warnings.join(' ');

      setState(() {
        _vinDecodeMetadata = {
          'vin': result.vin,
          'status': result.status,
          'providers': result.providers,
          'decodedAt': DateTime.now().toUtc().toIso8601String(),
          'data': result.data,
          'warnings': result.warnings,
        };
        _vinDecodeMessage = result.status == 'decoded'
            ? 'Décodage terminé via ' +
                providerLabel +
                ' : ' +
                populated.toString() +
                ' champ(s) renseigné(s).' +
                warningText
            : 'Décodage partiel via ' +
                providerLabel +
                '. Vérifiez les données manquantes.' +
                warningText;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _vinDecodeMetadata = null;
        _vinDecodeMessage = 'Échec du décodage VIN : ' + error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _decodingVin = false);
      }
    }
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
      crossAxisCellCount: _isCompactViewport ? 12 : 12,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 6,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: _isCompactViewport
                  ? BorderSide.none
                  : BorderSide(color: appTheme.color),
              right: _isCompactViewport
                  ? BorderSide(color: appTheme.color)
                  : BorderSide.none,
              left: _isCompactViewport
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
        crossAxisCellCount: _isCompactViewport ? 12 : 6,
        child: Container(
          height: heightFirst,

          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: appTheme.color),
              left: BorderSide(color: appTheme.color),
              right: _isCompactViewport
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
                dialogSize: _responsiveVehicleCountryDialogSize(context),
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
                height: 44,
                child: ParcotoFieldSurface(child: AutoSuggestBox<String>(
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
                )),
              ),
            ],
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 6,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: _isCompactViewport
                  ? BorderSide.none
                  : BorderSide(color: appTheme.color),
              right: BorderSide(color: appTheme.color),
              left: _isCompactViewport
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
                height: 44,
                child: ParcotoFieldSurface(child: AutoSuggestBox<String>(
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
                                : Language.FR,                          ) ??
                          '',
                    );
                  }).toList(),
                  onSelected: (item) {
                    setState(() => dairaCont.text = item.value ?? "");
                  },
                )),
              ),
              Text('commune', style: formHintStyle).tr(),
              SizedBox(
                height: 44,
                child: ParcotoFieldSurface(child: AutoSuggestBox<String>(
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
                )),
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
        crossAxisCellCount: _isCompactViewport ? 12 : 4,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: appTheme.color),
              right: _isCompactViewport
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
              ParcotoFieldSurface(child: DatePicker(
                selected: selectedDate,
                onChanged: widget.readOnly
                    ? null
                    : (s) {
                        setState(() {
                          selectedDate = s;
                        });
                      },
              )),
            ],
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 4,
        child: Container(
          decoration: BoxDecoration(
            border: _isCompactViewport
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
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                const Text('Puissance fiscale (CV)', style: TextStyle(fontSize: 12)),
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: appTheme.color),
              left: _isCompactViewport
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: appTheme.color),
              left: BorderSide(color: appTheme.color),
              right: _isCompactViewport
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
                width: double.infinity,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
        child: Container(
          decoration: BoxDecoration(
            border: _isCompactViewport
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
                height: 44,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
        child: Container(
          decoration: BoxDecoration(
            border: _isCompactViewport
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
                height: 44,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: _isCompactViewport
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
                height: 44,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 4,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: _isCompactViewport
                  ? BorderSide.none
                  : BorderSide(color: appTheme.color),
              right: BorderSide(color: appTheme.color),
              left: _isCompactViewport
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
                height: 44,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 3,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: _isCompactViewport
                  ? BorderSide.none
                  : BorderSide(color: appTheme.color),
              left: BorderSide(color: appTheme.color),
              right: _isCompactViewport
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
                height: 44,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 6,
        child: Container(
          decoration: BoxDecoration(
            border: _isCompactViewport
                ? Border(
                    bottom: _isCompactViewport
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
                height: 44,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 3,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: appTheme.color),
              right: BorderSide(color: appTheme.color),
              left: _isCompactViewport
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
                ParcotoFieldSurface(child: AutoSuggestBox<String>(
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
                )),
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
        crossAxisCellCount: _isCompactViewport ? 12 : 3,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: appTheme.color),
              right: _isCompactViewport
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
                ParcotoFieldSurface(child: AutoSuggestBox<String>(
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
                )),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 3,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            border: _isCompactViewport
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
                ParcotoFieldSurface(child: AutoSuggestBox<String>(
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
                )),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 3,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            border: _isCompactViewport
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
                ParcotoFieldSurface(child: AutoSuggestBox<String>(
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
                )),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 3,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: appTheme.color),
              left: _isCompactViewport
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
                ParcotoFieldSurface(child: AutoSuggestBox<String>(
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
                )),
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
                              constraints: _responsiveVehiclePickerConstraints(
                                context,
                                maxWidth: 400,
                                maxHeight: 400,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
                  child: Button(
                    onPressed: widget.readOnly ? null : _selectVehicleMake,
                    child: Row(
                      children: [
                        VehicleMakeLogo(makeId: marque, size: 30),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AutoSizeText(
                            VehicleMakeService.nameFor(marque).isEmpty
                                ? 'nonind'.tr()
                                : VehicleMakeService.nameFor(marque),
                            minFontSize: 5,
                            maxLines: 1,
                          ),
                        ),
                        const Icon(FluentIcons.chevron_down, size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
      crossAxisCellCount: _isCompactViewport ? 12 : 6,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(children: [
              const Text('Puissance moteur (ch)', style: TextStyle(fontSize: 12)),
              ParcotoTextBox(
                enabled: !widget.readOnly, placeholder: 'Ex. 110',
                controller: enginePowerHpController, maxLength: 7,
                placeholderStyle: placeStyle, cursorColor: appTheme.color.darker,
                style: appTheme.writingStyle,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              ),
            ]),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(children: [
              const Text('Puissance moteur (kW)', style: TextStyle(fontSize: 12)),
              ParcotoTextBox(
                enabled: !widget.readOnly, placeholder: 'Ex. 81',
                controller: enginePowerKwController, maxLength: 7,
                placeholderStyle: placeStyle, cursorColor: appTheme.color.darker,
                style: appTheme.writingStyle,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              ),
            ]),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 4,
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
                  child: ParcotoFieldSurface(child: DatePicker(
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
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 12,
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
          constraints: BoxConstraints.tight(
            _responsiveVehiclePickerConstraints(
              context,
              maxWidth: 700,
              maxHeight: 550,
            ).biggest,
          ),
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
    if (autreMat) return;

    var derivedValuesChanged = false;
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
      derivedValuesChanged = true;
    }

    if (matr2.text.isNotEmpty) {
      genre = (int.tryParse(matr2.text) ?? 100) ~/ 100;
      selectedAnnee = DateTime(
        VehiclesUtilities.getAnneeFromMatricule('0000-${matr2.text}-00'),
      );
      derivedValuesChanged = true;
    }

    // Both parts are typed independently, but their derived state only needs
    // one parent rebuild per key event.
    if (derivedValuesChanged && mounted) {
      setState(() {});
    }
  }

  Future<void> _selectVehicleMake() async {
    try {
      await VehicleMakeService.load();
      if (!mounted) return;
      final selected = await showDialog<String>(
        context: context,
        builder: (dialogContext) => _VehicleMakePickerDialog(
          selectedMakeId: marque,
        ),
      );
      if (selected != null && mounted) {
        setState(() => marque = selected);
      }
    } catch (error) {
      if (!mounted) return;
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Impossible de charger le catalogue des marques.'),
          content: Text(error.toString()),
          severity: InfoBarSeverity.error,
        ),
        duration: snackbarShortDuration,
      );
    }
  }

  Future<void> _loadVehicleImageCapabilities() async {
    try {
      final capabilities = await VehicleImageService.capabilities(
        companyId: vehicleServices.companyId,
      );
      if (!mounted) return;
      setState(() {
        _canUploadVehicleImage = capabilities.canUpload;
        _canForceRefreshVehicleImage = capabilities.canForceRefresh;
      });
    } catch (_) {
      // Fail closed: if the server cannot validate the caller's role, hide
      // privileged actions rather than guessing from client-side state.
      if (!mounted) return;
      setState(() {
        _canUploadVehicleImage = false;
        _canForceRefreshVehicleImage = false;
      });
    }
  }

  String _vehicleImageSourceLabel(String source) {
    switch (source) {
      case 'wikimedia_commons':
        return 'Wikimedia Commons';
      case 'trustcar':
        return 'CarAPI TrustCar';
      case 'openverse':
        return 'Openverse';
      case 'carimages':
        return 'CarImagesAPI';
      case 'manual_upload':
        return 'Photo ajoutée par un administrateur';
      case 'shared_cache':
        return 'Catalogue partagé';
      default:
        return source;
    }
  }

  Future<void> _resolveVehicleImage({
    bool showInfo = true,
    bool forceRefresh = false,
  }) async {
    if (widget.readOnly || _resolvingVehicleImage) return;
    try {
      await VehicleMakeService.load();
    } catch (_) {
      // The legacy brand list can still resolve numeric values while offline.
    }
    if (!mounted) return;
    if (forceRefresh && !_canForceRefreshVehicleImage) return;

    final make = VehicleMakeService.nameFor(marque);
    final model = type.text.trim();
    final year = int.tryParse(modelYearController.text.trim());
    final color = _normalizeVehiclePaint(colorController.text);
    if (make.trim().isEmpty || model.isEmpty || year == null) {
      if (mounted) {
        setState(() {
          _vehicleImageMessage =
              'Renseignez la marque, le modèle et l’année modèle.';
        });
      }
      return;
    }

    final loadedVehicleImageMatchesIdentity =
        (widget.vehicle?.imageUrl?.trim().isNotEmpty ?? false) &&
        VehicleMakeService.nameFor(widget.vehicle?.marque) ==
            make &&
        widget.vehicle?.type?.trim() == model &&
        widget.vehicle?.modelYear == year &&
        _normalizeVehiclePaint(widget.vehicle?.color) == color;
    final imageMatchesCurrentIdentity =
        (_resolvedImageMake == make &&
            _resolvedImageModel == model &&
            _resolvedImageYear == year &&
            _resolvedImageColor == color) ||
        loadedVehicleImageMatchesIdentity;

    setState(() {
      _resolvingVehicleImage = true;
      _vehicleImageCandidates = [];
      _vehicleImageMessage = forceRefresh
          ? 'Recherche de nouvelles alternatives. L’image actuelle sera remplacée uniquement après ton choix…'
          : 'Recherche de plusieurs propositions auprès de sources différentes…';
      if (!imageMatchesCurrentIdentity && !forceRefresh) {
        _resolvedImageUrl = null;
        _resolvedImageFileId = null;
        _resolvedImageSource = null;
        _resolvedImageLicense = null;
        _resolvedImageLicenseUrl = null;
        _resolvedImageSourceUrl = null;
        _resolvedImageAttribution = null;
      }
    });

    try {
      final result = await VehicleImageService.searchCandidates(
        companyId: vehicleServices.companyId,
        make: make,
        model: model,
        year: year,
        color: color,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      setState(() {
        _vehicleImageLookupCompleted = true;
        _vehicleImageCandidates = result.candidates;

        if (result.cachedImage != null) {
          final cached = result.cachedImage!;
          _resolvedImageUrl = cached.imageUrl;
          _resolvedImageFileId = cached.fileId;
          _resolvedImageSource = cached.source;
          _resolvedImageLicense = cached.license;
          _resolvedImageLicenseUrl = cached.licenseUrl;
          _resolvedImageSourceUrl = cached.sourceUrl;
          _resolvedImageAttribution = cached.attribution;
          _resolvedImageMake = make;
          _resolvedImageModel = model;
          _resolvedImageYear = year;
          _resolvedImageColor = color;
          _vehicleImageMessage =
              'Image déjà disponible dans le catalogue partagé.';
        } else if (result.candidates.isNotEmpty) {
          _vehicleImageMessage = result.candidates.length >= 2
              ? '${result.candidates.length} propositions trouvées auprès de sources différentes. Vérifiez laquelle représente réellement ce véhicule.'
              : 'Une seule source a fourni une image exploitable. Vérifiez-la avant de la sélectionner.';
          _resolvedImageMake = make;
          _resolvedImageModel = model;
          _resolvedImageYear = year;
          _resolvedImageColor = color;
        } else {
          if (!imageMatchesCurrentIdentity && !forceRefresh) {
            _resolvedImageUrl = null;
            _resolvedImageFileId = null;
            _resolvedImageSource = null;
            _resolvedImageLicense = null;
            _resolvedImageLicenseUrl = null;
            _resolvedImageSourceUrl = null;
            _resolvedImageAttribution = null;
          }
          _vehicleImageMessage = forceRefresh && imageMatchesCurrentIdentity
              ? 'Aucune alternative pertinente trouvée. L’image actuelle est conservée.'
              : 'Aucune image suffisamment pertinente trouvée. Un administrateur peut importer une photo.';
        }
      });

      if (showInfo && mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: Text(
              result.cachedImage != null
                  ? 'Image du catalogue déjà disponible.'
                  : result.candidates.isNotEmpty
                      ? '${result.candidates.length} proposition(s) à comparer.'
                      : 'Aucune image correspondante disponible.',
            ),
            severity: result.cachedImage != null || result.candidates.isNotEmpty
                ? InfoBarSeverity.success
                : InfoBarSeverity.warning,
          ),
          duration: snackbarShortDuration,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _vehicleImageCandidates = [];
        _vehicleImageMessage =
            'La recherche d’image a échoué : ${error.toString()}';
        if (!imageMatchesCurrentIdentity && !forceRefresh) {
          _resolvedImageUrl = null;
          _resolvedImageFileId = null;
          _resolvedImageSource = null;
          _resolvedImageLicense = null;
          _resolvedImageLicenseUrl = null;
          _resolvedImageSourceUrl = null;
          _resolvedImageAttribution = null;
          _vehicleImageLookupCompleted = false;
        }
      });
      if (showInfo) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('La recherche d’image a échoué.'),
            content: Text(error.toString()),
            severity: InfoBarSeverity.error,
          ),
          duration: snackbarShortDuration,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _resolvingVehicleImage = false);
      }
    }
  }

  Future<void> _selectVehicleImageCandidate(
    VehicleImageCandidate candidate,
  ) async {
    if (widget.readOnly || _resolvingVehicleImage) return;

    final make = VehicleMakeService.nameFor(marque);
    final model = type.text.trim();
    final year = int.tryParse(modelYearController.text.trim());
    final color = _normalizeVehiclePaint(colorController.text);
    if (make.trim().isEmpty || model.isEmpty || year == null) return;

    setState(() {
      _resolvingVehicleImage = true;
      _vehicleImageMessage =
          'Enregistrement de la source choisie dans le catalogue partagé…';
    });

    try {
      final result = await VehicleImageService.selectCandidate(
        companyId: vehicleServices.companyId,
        make: make,
        model: model,
        year: year,
        color: color,
        candidate: candidate,
      );
      if (!mounted) return;

      setState(() {
        _vehicleImageCandidates = [];
        _vehicleImageLookupCompleted = true;
        _resolvedImageUrl = result.imageUrl;
        _resolvedImageFileId = result.fileId;
        _resolvedImageSource = result.source;
        _resolvedImageLicense = result.license;
        _resolvedImageLicenseUrl = result.licenseUrl;
        _resolvedImageSourceUrl = result.sourceUrl;
        _resolvedImageAttribution = result.attribution;
        _resolvedImageMake = make;
        _resolvedImageModel = model;
        _resolvedImageYear = year;
        _resolvedImageColor = color;
        _vehicleImageMessage = result.colorFallback
            ? 'Image choisie, mais la couleur n’a pas pu être vérifiée pour cette photo.'
            : 'Image choisie et enregistrée dans le catalogue partagé.';
      });

      displayInfoBar(
        context,
        builder: (context, close) => const InfoBar(
          title: Text('Image enregistrée dans le catalogue partagé.'),
          severity: InfoBarSeverity.success,
        ),
        duration: snackbarShortDuration,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _vehicleImageMessage =
            'Impossible d’enregistrer cette proposition : ${error.toString()}';
      });
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Impossible d’enregistrer cette image.'),
          content: Text(error.toString()),
          severity: InfoBarSeverity.error,
        ),
        duration: snackbarShortDuration,
      );
    } finally {
      if (mounted) setState(() => _resolvingVehicleImage = false);
    }
  }

  Future<void> _pickAndUploadVehicleImage(ImageSource source) async {
    if (widget.readOnly ||
        !_canUploadVehicleImage ||
        !_vehicleImageLookupCompleted ||
        _vehicleImageCandidates.isNotEmpty ||
        _resolvingVehicleImage ||
        (_resolvedImageUrl?.isNotEmpty ?? false)) {
      return;
    }

    final make = VehicleMakeService.nameFor(marque);
    final model = type.text.trim();
    final year = int.tryParse(modelYearController.text.trim());
    final color = _normalizeVehiclePaint(colorController.text);
    if (make.trim().isEmpty || model.isEmpty || year == null) {
      displayInfoBar(
        context,
        builder: (context, close) => const InfoBar(
          title: Text('Renseignez d’abord la marque, le modèle et l’année.'),
          severity: InfoBarSeverity.warning,
        ),
        duration: snackbarShortDuration,
      );
      return;
    }

    try {
      final picked = await _vehicleImagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 82,
        maxWidth: 1600,
        maxHeight: 1200,
      );
      if (picked == null || !mounted) return;

      final extension = picked.name.split('.').last.toLowerCase();
      final mimeType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'jpg' || 'jpeg' => 'image/jpeg',
        _ => '',
      };
      if (mimeType.isEmpty) {
        displayInfoBar(
          context,
          builder: (context, close) => const InfoBar(
            title: Text('Format non pris en charge. Utilisez JPG, PNG ou WebP.'),
            severity: InfoBarSeverity.error,
          ),
          duration: snackbarShortDuration,
        );
        return;
      }

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        displayInfoBar(
          context,
          builder: (context, close) => const InfoBar(
            title: Text('La photo doit faire 5 Mo maximum.'),
            severity: InfoBarSeverity.error,
          ),
          duration: snackbarShortDuration,
        );
        return;
      }

      setState(() {
        _resolvingVehicleImage = true;
        _vehicleImageMessage = 'Envoi de la photo et ajout au catalogue partagé…';
      });

      final result = await VehicleImageService.uploadCustom(
        companyId: vehicleServices.companyId,
        make: make,
        model: model,
        year: year,
        color: color,
        bytes: bytes,
        mimeType: mimeType,
        fileName: picked.name,
      );
      if (!mounted) return;

      setState(() {
        _vehicleImageLookupCompleted = result.found;
        _vehicleImageCandidates = [];
        _resolvedImageUrl = result.imageUrl;
        _resolvedImageFileId = result.fileId;
        _resolvedImageSource = result.source;
        _resolvedImageLicense = result.license;
        _resolvedImageLicenseUrl = result.licenseUrl;
        _resolvedImageSourceUrl = result.sourceUrl;
        _resolvedImageAttribution = result.attribution;
        _resolvedImageMake = make;
        _resolvedImageModel = model;
        _resolvedImageYear = year;
        _resolvedImageColor = color;
        _vehicleImageMessage = result.found
            ? 'Photo ajoutée au catalogue partagé pour ce modèle, cette année et cette couleur.'
            : 'La photo n’a pas pu être ajoutée au catalogue partagé.';
      });

      if (result.found) {
        displayInfoBar(
          context,
          builder: (context, close) => const InfoBar(
            title: Text('Photo ajoutée au catalogue partagé.'),
            severity: InfoBarSeverity.success,
          ),
          duration: snackbarShortDuration,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _vehicleImageMessage = 'Échec de l’ajout de la photo : ${error.toString()}';
      });
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Impossible d’ajouter cette photo.'),
          content: Text(error.toString()),
          severity: InfoBarSeverity.error,
        ),
        duration: snackbarShortDuration,
      );
    } finally {
      if (mounted) {
        setState(() => _resolvingVehicleImage = false);
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

    try {
      await VehicleMakeService.load();
    } catch (_) {
      // Legacy brand indexes remain resolvable while offline.
    }
    if (!mounted) return;

    final currentMake = VehicleMakeService.nameFor(marque);
    final currentModel = type.text.trim();
    final currentYear = int.tryParse(modelYearController.text.trim());
    final currentColor = _normalizeVehiclePaint(colorController.text);
    final imageIdentityChanged = currentMake != (_resolvedImageMake ?? '') ||
        currentModel != (_resolvedImageModel ?? '') ||
        currentYear != _resolvedImageYear ||
        currentColor != (_resolvedImageColor ?? '');

    if (!widget.readOnly &&
        currentMake.isNotEmpty &&
        currentModel.isNotEmpty &&
        currentYear != null &&
        !(_vehicleImageLookupCompleted && !imageIdentityChanged &&
            (_resolvedImageUrl == null || _resolvedImageUrl!.isEmpty)) &&
        ((_resolvedImageUrl == null || _resolvedImageUrl!.isEmpty) ||
            imageIdentityChanged)) {
      await _resolveVehicleImage(showInfo: false);
    }

    if (mounted) {
      setState(() {
        uploading = true;
        errorUploading = false;
      });
      final selectedImageMake = VehicleMakeService.nameFor(marque);
      final selectedImageModel = type.text.trim();
      final selectedImageYear = int.tryParse(modelYearController.text.trim());
      final selectedImageColor = _normalizeVehiclePaint(colorController.text);
      final resolvedImageMatchesCurrentCriteria =
          _resolvedImageMake == selectedImageMake &&
          _resolvedImageModel == selectedImageModel &&
          _resolvedImageYear == selectedImageYear &&
          _resolvedImageColor == selectedImageColor;
      final originalImageMake =
          VehicleMakeService.nameFor(widget.vehicle?.marque);
      final existingImageMatchesCurrentCriteria =
          (widget.vehicle?.imageUrl?.trim().isNotEmpty ?? false) &&
          originalImageMake == selectedImageMake &&
          widget.vehicle?.type?.trim() == selectedImageModel &&
          widget.vehicle?.modelYear == selectedImageYear &&
          _normalizeVehiclePaint(widget.vehicle?.color) == selectedImageColor;
      final useResolvedVehicleImage = resolvedImageMatchesCurrentCriteria;
      final useExistingVehicleImage =
          !useResolvedVehicleImage && existingImageMatchesCurrentCriteria;
      final vehicleCustomFields = Map<String, dynamic>.from(
        widget.vehicle?.customFields ?? const <String, dynamic>{},
      );
      final normalizedVinForMetadata =
          numSer.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
      if (_vinDecodeMetadata != null &&
          _vinDecodeMetadata!['vin'] == normalizedVinForMetadata) {
        vehicleCustomFields['_vehicleVinDecode'] = _vinDecodeMetadata;
      } else {
        final previousVinDecode = vehicleCustomFields['_vehicleVinDecode'];
        if (previousVinDecode is Map &&
            previousVinDecode['vin']?.toString() !=
                normalizedVinForMetadata) {
          vehicleCustomFields.remove('_vehicleVinDecode');
        }
      }
      const imageMetadataKeys = [
        '_vehicleImageSource',
        '_vehicleImageSourceUrl',
        '_vehicleImageLicense',
        '_vehicleImageLicenseUrl',
        '_vehicleImageAttribution',
      ];
      if (useResolvedVehicleImage && _resolvedImageUrl?.isNotEmpty == true) {
        vehicleCustomFields['_vehicleImageSource'] = _resolvedImageSource;
        vehicleCustomFields['_vehicleImageSourceUrl'] = _resolvedImageSourceUrl;
        vehicleCustomFields['_vehicleImageLicense'] = _resolvedImageLicense;
        vehicleCustomFields['_vehicleImageLicenseUrl'] = _resolvedImageLicenseUrl;
        vehicleCustomFields['_vehicleImageAttribution'] = _resolvedImageAttribution;
      } else if (!useExistingVehicleImage) {
        for (final key in imageMetadataKeys) {
          vehicleCustomFields.remove(key);
        }
      }

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
        color: _normalizeVehiclePaint(colorController.text),
        engineDisplacement: int.tryParse(engineDisplacementController.text.trim()),
        enginePowerHp: double.tryParse(enginePowerHpController.text.trim().replaceAll(',', '.')),
        enginePowerKw: double.tryParse(enginePowerKwController.text.trim().replaceAll(',', '.')),
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
        imageFileId: useResolvedVehicleImage
            ? _resolvedImageFileId
            : useExistingVehicleImage
                ? widget.vehicle?.imageFileId
                : null,
        imageUrl: useResolvedVehicleImage
            ? _resolvedImageUrl
            : useExistingVehicleImage
                ? widget.vehicle?.imageUrl
                : null,
        imageSource: useResolvedVehicleImage
            ? _resolvedImageSource
            : useExistingVehicleImage
                ? widget.vehicle?.imageSource
                : null,
        customFields: vehicleCustomFields,
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
        marque: marque,
        matriculePrec: matriculesPrec,
        carrosserie: caross.text,
        charegeUtile: int.tryParse(charg.text),
        createdBy: widget.vehicle?.createdBy ?? DatabaseGetter.me.value?.id,
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
        decision: widget.vehicle?.decision ?? false,
        emplacement: widget.vehicle?.emplacement,
        etat: widget.vehicle?.etat,
        etatactuel: widget.vehicle?.etatactuel ?? 0,
        perimetre: widget.vehicle?.perimetre ?? 0,
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
        widget.onSaved?.call(vehicle);
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
      companyId: DatabaseGetter.activeCompanyId ?? (throw StateError('Aucune entreprise active.')),
    );
    await vehicleServices.repository.updateVehicle(domainVehicle);
  }

  Future<void> createVehicle(Vehicle vehicle) async {
    final now = DateTime.now().toUtc();
    vehicle.createdAt = now;
    vehicle.updatedAt = now;
    final domainVehicle = VehicleMapper.toDomain(
      vehicle,
      companyId: DatabaseGetter.activeCompanyId ?? (throw StateError('Aucune entreprise active.')),
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

class _VehicleMakePickerDialog extends StatefulWidget {
  final String? selectedMakeId;

  const _VehicleMakePickerDialog({this.selectedMakeId});

  @override
  State<_VehicleMakePickerDialog> createState() =>
      _VehicleMakePickerDialogState();
}

class _VehicleMakePickerDialogState extends State<_VehicleMakePickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final makes = VehicleMakeService.search(_query);
    return ContentDialog(
      title: const Text('Choisir une marque'),
      content: SizedBox(
        width: 520,
        height: 540,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextBox(
              controller: _searchController,
              placeholder: 'Rechercher une marque…',
              prefix: const Padding(
                padding: EdgeInsetsDirectional.only(start: 8),
                child: Icon(FluentIcons.search, size: 14),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: makes.isEmpty
                  ? const Center(child: Text('Aucune marque trouvée.'))
                  : ListView.separated(
                      itemCount: makes.length,
                      separatorBuilder: (_, _) => Container(
                        height: 1,
                        color: Colors.grey[30],
                      ),
                      itemBuilder: (context, index) {
                        final make = makes[index];
                        final selected = make.id == widget.selectedMakeId;
                        return Button(
                          onPressed: () => Navigator.of(context).pop(make.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                VehicleMakeLogo(makeId: make.id, size: 34),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        make.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        make.category,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[100],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                   Icon(
                                    FluentIcons.check_mark,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

).hasMatch(vin)) {
      setState(() {
        _vinDecodeMessage =
            'Saisissez un VIN valide de 17 caractères (sans I, O ni Q).';
      });
      return;
    }

    setState(() {
      _decodingVin = true;
      _vinDecodeMessage = 'Interrogation des décodeurs VIN…';
    });

    try {
      final result = await VehicleVinService.decode(
        companyId: vehicleServices.companyId,
        vin: vin,
      );
      if (!mounted) return;

      if (result.status == 'not_found') {
        setState(() {
          _vinDecodeMetadata = null;
          _vinDecodeMessage =
              'Aucune fiche constructeur exploitable n’a été retournée.';
        });
        return;
      }

      try {
        await VehicleMakeService.load();
      } catch (_) {
        // Keep the cached/legacy make catalogue available when offline.
      }

      final data = result.data;
      var populated = 0;

      void fillIfEmpty(TextEditingController controller, dynamic rawValue) {
        final value = rawValue?.toString().trim() ?? '';
        if (controller.text.trim().isEmpty && value.isNotEmpty) {
          controller.text = value;
          populated++;
        }
      }

      final decodedMake = data['make']?.toString().trim() ?? '';
      if ((marque ?? '').trim().isEmpty && decodedMake.isNotEmpty) {
        final normalizedMake = VehicleMakeService.normalize(decodedMake);
        VehicleMake? matchedMake;
        for (final candidate in VehicleMakeService.cached) {
          if (VehicleMakeService.normalize(candidate.name) == normalizedMake ||
              candidate.aliases.any(
                (alias) =>
                    VehicleMakeService.normalize(alias) == normalizedMake,
              )) {
            matchedMake = candidate;
            break;
          }
        }
        marque = matchedMake?.id ??
            VehicleMakeService.canonicalId(decodedMake) ??
            decodedMake;
        populated++;
      }

      fillIfEmpty(type, data['model']);
      fillIfEmpty(trimController, data['trim']);
      fillIfEmpty(modelYearController, data['modelYear']);
      fillIfEmpty(caross, data['body']);
      fillIfEmpty(energie, data['fuel']);
      fillIfEmpty(engineDisplacementController, data['engineDisplacementCc']);
      fillIfEmpty(enginePowerHpController, data['enginePowerHp']);
      fillIfEmpty(enginePowerKwController, data['enginePowerKw']);
      fillIfEmpty(engineCodeController, data['engineCode'] ?? data['engine']);
      fillIfEmpty(transmissionController, data['transmission']);
      fillIfEmpty(driveTypeController, data['drive']);
      fillIfEmpty(doorsController, data['doors']);

      final providerLabel = result.providers.isEmpty
          ? 'source inconnue'
          : result.providers.join(' + ');
      final warningText = result.warnings.isEmpty
          ? ''
          : ' ' + result.warnings.join(' ');

      setState(() {
        _vinDecodeMetadata = {
          'vin': result.vin,
          'status': result.status,
          'providers': result.providers,
          'decodedAt': DateTime.now().toUtc().toIso8601String(),
          'data': result.data,
          'warnings': result.warnings,
        };
        _vinDecodeMessage = result.status == 'decoded'
            ? 'Décodage terminé via ' +
                providerLabel +
                ' : ' +
                populated.toString() +
                ' champ(s) renseigné(s).' +
                warningText
            : 'Décodage partiel via ' +
                providerLabel +
                '. Vérifiez les données manquantes.' +
                warningText;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _vinDecodeMetadata = null;
        _vinDecodeMessage = 'Échec du décodage VIN : ' + error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _decodingVin = false);
      }
    }
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
      crossAxisCellCount: _isCompactViewport ? 12 : 12,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 6,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: _isCompactViewport
                  ? BorderSide.none
                  : BorderSide(color: appTheme.color),
              right: _isCompactViewport
                  ? BorderSide(color: appTheme.color)
                  : BorderSide.none,
              left: _isCompactViewport
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
        crossAxisCellCount: _isCompactViewport ? 12 : 6,
        child: Container(
          height: heightFirst,

          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: appTheme.color),
              left: BorderSide(color: appTheme.color),
              right: _isCompactViewport
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
                dialogSize: _responsiveVehicleCountryDialogSize(context),
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
                height: 44,
                child: ParcotoFieldSurface(child: AutoSuggestBox<String>(
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
                )),
              ),
            ],
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 6,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: _isCompactViewport
                  ? BorderSide.none
                  : BorderSide(color: appTheme.color),
              right: BorderSide(color: appTheme.color),
              left: _isCompactViewport
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
                height: 44,
                child: ParcotoFieldSurface(child: AutoSuggestBox<String>(
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
                                : Language.FR,                          ) ??
                          '',
                    );
                  }).toList(),
                  onSelected: (item) {
                    setState(() => dairaCont.text = item.value ?? "");
                  },
                )),
              ),
              Text('commune', style: formHintStyle).tr(),
              SizedBox(
                height: 44,
                child: ParcotoFieldSurface(child: AutoSuggestBox<String>(
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
                )),
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
        crossAxisCellCount: _isCompactViewport ? 12 : 4,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: appTheme.color),
              right: _isCompactViewport
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
              ParcotoFieldSurface(child: DatePicker(
                selected: selectedDate,
                onChanged: widget.readOnly
                    ? null
                    : (s) {
                        setState(() {
                          selectedDate = s;
                        });
                      },
              )),
            ],
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 4,
        child: Container(
          decoration: BoxDecoration(
            border: _isCompactViewport
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
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                const Text('Puissance fiscale (CV)', style: TextStyle(fontSize: 12)),
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: appTheme.color),
              left: _isCompactViewport
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: appTheme.color),
              left: BorderSide(color: appTheme.color),
              right: _isCompactViewport
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
                width: double.infinity,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
        child: Container(
          decoration: BoxDecoration(
            border: _isCompactViewport
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
                height: 44,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
        child: Container(
          decoration: BoxDecoration(
            border: _isCompactViewport
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
                height: 44,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: _isCompactViewport
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
                height: 44,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 4,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: _isCompactViewport
                  ? BorderSide.none
                  : BorderSide(color: appTheme.color),
              right: BorderSide(color: appTheme.color),
              left: _isCompactViewport
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
                height: 44,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 3,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: _isCompactViewport
                  ? BorderSide.none
                  : BorderSide(color: appTheme.color),
              left: BorderSide(color: appTheme.color),
              right: _isCompactViewport
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
                height: 44,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 6,
        child: Container(
          decoration: BoxDecoration(
            border: _isCompactViewport
                ? Border(
                    bottom: _isCompactViewport
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
                height: 44,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 3,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: appTheme.color),
              right: BorderSide(color: appTheme.color),
              left: _isCompactViewport
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
                ParcotoFieldSurface(child: AutoSuggestBox<String>(
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
                )),
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
        crossAxisCellCount: _isCompactViewport ? 12 : 3,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: appTheme.color),
              right: _isCompactViewport
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
                ParcotoFieldSurface(child: AutoSuggestBox<String>(
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
                )),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 3,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            border: _isCompactViewport
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
                ParcotoFieldSurface(child: AutoSuggestBox<String>(
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
                )),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 3,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            border: _isCompactViewport
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
                ParcotoFieldSurface(child: AutoSuggestBox<String>(
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
                )),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 3,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: appTheme.color),
              left: _isCompactViewport
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
                ParcotoFieldSurface(child: AutoSuggestBox<String>(
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
                )),
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
                              constraints: _responsiveVehiclePickerConstraints(
                                context,
                                maxWidth: 400,
                                maxHeight: 400,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
                  child: Button(
                    onPressed: widget.readOnly ? null : _selectVehicleMake,
                    child: Row(
                      children: [
                        VehicleMakeLogo(makeId: marque, size: 30),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AutoSizeText(
                            VehicleMakeService.nameFor(marque).isEmpty
                                ? 'nonind'.tr()
                                : VehicleMakeService.nameFor(marque),
                            minFontSize: 5,
                            maxLines: 1,
                          ),
                        ),
                        const Icon(FluentIcons.chevron_down, size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
      crossAxisCellCount: _isCompactViewport ? 12 : 6,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(children: [
              const Text('Puissance moteur (ch)', style: TextStyle(fontSize: 12)),
              ParcotoTextBox(
                enabled: !widget.readOnly, placeholder: 'Ex. 110',
                controller: enginePowerHpController, maxLength: 7,
                placeholderStyle: placeStyle, cursorColor: appTheme.color.darker,
                style: appTheme.writingStyle,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              ),
            ]),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
        child: Container(
          height: height,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(border: Border.all(color: appTheme.color)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(children: [
              const Text('Puissance moteur (kW)', style: TextStyle(fontSize: 12)),
              ParcotoTextBox(
                enabled: !widget.readOnly, placeholder: 'Ex. 81',
                controller: enginePowerKwController, maxLength: 7,
                placeholderStyle: placeStyle, cursorColor: appTheme.color.darker,
                style: appTheme.writingStyle,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              ),
            ]),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 2,
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
        crossAxisCellCount: _isCompactViewport ? 12 : 4,
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
                  child: ParcotoFieldSurface(child: DatePicker(
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
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: _isCompactViewport ? 12 : 12,
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
          constraints: BoxConstraints.tight(
            _responsiveVehiclePickerConstraints(
              context,
              maxWidth: 700,
              maxHeight: 550,
            ).biggest,
          ),
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
    if (autreMat) return;

    var derivedValuesChanged = false;
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
      derivedValuesChanged = true;
    }

    if (matr2.text.isNotEmpty) {
      genre = (int.tryParse(matr2.text) ?? 100) ~/ 100;
      selectedAnnee = DateTime(
        VehiclesUtilities.getAnneeFromMatricule('0000-${matr2.text}-00'),
      );
      derivedValuesChanged = true;
    }

    // Both parts are typed independently, but their derived state only needs
    // one parent rebuild per key event.
    if (derivedValuesChanged && mounted) {
      setState(() {});
    }
  }

  Future<void> _selectVehicleMake() async {
    try {
      await VehicleMakeService.load();
      if (!mounted) return;
      final selected = await showDialog<String>(
        context: context,
        builder: (dialogContext) => _VehicleMakePickerDialog(
          selectedMakeId: marque,
        ),
      );
      if (selected != null && mounted) {
        setState(() => marque = selected);
      }
    } catch (error) {
      if (!mounted) return;
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Impossible de charger le catalogue des marques.'),
          content: Text(error.toString()),
          severity: InfoBarSeverity.error,
        ),
        duration: snackbarShortDuration,
      );
    }
  }

  Future<void> _loadVehicleImageCapabilities() async {
    try {
      final capabilities = await VehicleImageService.capabilities(
        companyId: vehicleServices.companyId,
      );
      if (!mounted) return;
      setState(() {
        _canUploadVehicleImage = capabilities.canUpload;
        _canForceRefreshVehicleImage = capabilities.canForceRefresh;
      });
    } catch (_) {
      // Fail closed: if the server cannot validate the caller's role, hide
      // privileged actions rather than guessing from client-side state.
      if (!mounted) return;
      setState(() {
        _canUploadVehicleImage = false;
        _canForceRefreshVehicleImage = false;
      });
    }
  }

  String _vehicleImageSourceLabel(String source) {
    switch (source) {
      case 'wikimedia_commons':
        return 'Wikimedia Commons';
      case 'trustcar':
        return 'CarAPI TrustCar';
      case 'openverse':
        return 'Openverse';
      case 'carimages':
        return 'CarImagesAPI';
      case 'manual_upload':
        return 'Photo ajoutée par un administrateur';
      case 'shared_cache':
        return 'Catalogue partagé';
      default:
        return source;
    }
  }

  Future<void> _resolveVehicleImage({
    bool showInfo = true,
    bool forceRefresh = false,
  }) async {
    if (widget.readOnly || _resolvingVehicleImage) return;
    try {
      await VehicleMakeService.load();
    } catch (_) {
      // The legacy brand list can still resolve numeric values while offline.
    }
    if (!mounted) return;
    if (forceRefresh && !_canForceRefreshVehicleImage) return;

    final make = VehicleMakeService.nameFor(marque);
    final model = type.text.trim();
    final year = int.tryParse(modelYearController.text.trim());
    final color = _normalizeVehiclePaint(colorController.text);
    if (make.trim().isEmpty || model.isEmpty || year == null) {
      if (mounted) {
        setState(() {
          _vehicleImageMessage =
              'Renseignez la marque, le modèle et l’année modèle.';
        });
      }
      return;
    }

    final loadedVehicleImageMatchesIdentity =
        (widget.vehicle?.imageUrl?.trim().isNotEmpty ?? false) &&
        VehicleMakeService.nameFor(widget.vehicle?.marque) ==
            make &&
        widget.vehicle?.type?.trim() == model &&
        widget.vehicle?.modelYear == year &&
        _normalizeVehiclePaint(widget.vehicle?.color) == color;
    final imageMatchesCurrentIdentity =
        (_resolvedImageMake == make &&
            _resolvedImageModel == model &&
            _resolvedImageYear == year &&
            _resolvedImageColor == color) ||
        loadedVehicleImageMatchesIdentity;

    setState(() {
      _resolvingVehicleImage = true;
      _vehicleImageCandidates = [];
      _vehicleImageMessage = forceRefresh
          ? 'Recherche de nouvelles alternatives. L’image actuelle sera remplacée uniquement après ton choix…'
          : 'Recherche de plusieurs propositions auprès de sources différentes…';
      if (!imageMatchesCurrentIdentity && !forceRefresh) {
        _resolvedImageUrl = null;
        _resolvedImageFileId = null;
        _resolvedImageSource = null;
        _resolvedImageLicense = null;
        _resolvedImageLicenseUrl = null;
        _resolvedImageSourceUrl = null;
        _resolvedImageAttribution = null;
      }
    });

    try {
      final result = await VehicleImageService.searchCandidates(
        companyId: vehicleServices.companyId,
        make: make,
        model: model,
        year: year,
        color: color,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      setState(() {
        _vehicleImageLookupCompleted = true;
        _vehicleImageCandidates = result.candidates;

        if (result.cachedImage != null) {
          final cached = result.cachedImage!;
          _resolvedImageUrl = cached.imageUrl;
          _resolvedImageFileId = cached.fileId;
          _resolvedImageSource = cached.source;
          _resolvedImageLicense = cached.license;
          _resolvedImageLicenseUrl = cached.licenseUrl;
          _resolvedImageSourceUrl = cached.sourceUrl;
          _resolvedImageAttribution = cached.attribution;
          _resolvedImageMake = make;
          _resolvedImageModel = model;
          _resolvedImageYear = year;
          _resolvedImageColor = color;
          _vehicleImageMessage =
              'Image déjà disponible dans le catalogue partagé.';
        } else if (result.candidates.isNotEmpty) {
          _vehicleImageMessage = result.candidates.length >= 2
              ? '${result.candidates.length} propositions trouvées auprès de sources différentes. Vérifiez laquelle représente réellement ce véhicule.'
              : 'Une seule source a fourni une image exploitable. Vérifiez-la avant de la sélectionner.';
          _resolvedImageMake = make;
          _resolvedImageModel = model;
          _resolvedImageYear = year;
          _resolvedImageColor = color;
        } else {
          if (!imageMatchesCurrentIdentity && !forceRefresh) {
            _resolvedImageUrl = null;
            _resolvedImageFileId = null;
            _resolvedImageSource = null;
            _resolvedImageLicense = null;
            _resolvedImageLicenseUrl = null;
            _resolvedImageSourceUrl = null;
            _resolvedImageAttribution = null;
          }
          _vehicleImageMessage = forceRefresh && imageMatchesCurrentIdentity
              ? 'Aucune alternative pertinente trouvée. L’image actuelle est conservée.'
              : 'Aucune image suffisamment pertinente trouvée. Un administrateur peut importer une photo.';
        }
      });

      if (showInfo && mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: Text(
              result.cachedImage != null
                  ? 'Image du catalogue déjà disponible.'
                  : result.candidates.isNotEmpty
                      ? '${result.candidates.length} proposition(s) à comparer.'
                      : 'Aucune image correspondante disponible.',
            ),
            severity: result.cachedImage != null || result.candidates.isNotEmpty
                ? InfoBarSeverity.success
                : InfoBarSeverity.warning,
          ),
          duration: snackbarShortDuration,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _vehicleImageCandidates = [];
        _vehicleImageMessage =
            'La recherche d’image a échoué : ${error.toString()}';
        if (!imageMatchesCurrentIdentity && !forceRefresh) {
          _resolvedImageUrl = null;
          _resolvedImageFileId = null;
          _resolvedImageSource = null;
          _resolvedImageLicense = null;
          _resolvedImageLicenseUrl = null;
          _resolvedImageSourceUrl = null;
          _resolvedImageAttribution = null;
          _vehicleImageLookupCompleted = false;
        }
      });
      if (showInfo) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('La recherche d’image a échoué.'),
            content: Text(error.toString()),
            severity: InfoBarSeverity.error,
          ),
          duration: snackbarShortDuration,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _resolvingVehicleImage = false);
      }
    }
  }

  Future<void> _selectVehicleImageCandidate(
    VehicleImageCandidate candidate,
  ) async {
    if (widget.readOnly || _resolvingVehicleImage) return;

    final make = VehicleMakeService.nameFor(marque);
    final model = type.text.trim();
    final year = int.tryParse(modelYearController.text.trim());
    final color = _normalizeVehiclePaint(colorController.text);
    if (make.trim().isEmpty || model.isEmpty || year == null) return;

    setState(() {
      _resolvingVehicleImage = true;
      _vehicleImageMessage =
          'Enregistrement de la source choisie dans le catalogue partagé…';
    });

    try {
      final result = await VehicleImageService.selectCandidate(
        companyId: vehicleServices.companyId,
        make: make,
        model: model,
        year: year,
        color: color,
        candidate: candidate,
      );
      if (!mounted) return;

      setState(() {
        _vehicleImageCandidates = [];
        _vehicleImageLookupCompleted = true;
        _resolvedImageUrl = result.imageUrl;
        _resolvedImageFileId = result.fileId;
        _resolvedImageSource = result.source;
        _resolvedImageLicense = result.license;
        _resolvedImageLicenseUrl = result.licenseUrl;
        _resolvedImageSourceUrl = result.sourceUrl;
        _resolvedImageAttribution = result.attribution;
        _resolvedImageMake = make;
        _resolvedImageModel = model;
        _resolvedImageYear = year;
        _resolvedImageColor = color;
        _vehicleImageMessage = result.colorFallback
            ? 'Image choisie, mais la couleur n’a pas pu être vérifiée pour cette photo.'
            : 'Image choisie et enregistrée dans le catalogue partagé.';
      });

      displayInfoBar(
        context,
        builder: (context, close) => const InfoBar(
          title: Text('Image enregistrée dans le catalogue partagé.'),
          severity: InfoBarSeverity.success,
        ),
        duration: snackbarShortDuration,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _vehicleImageMessage =
            'Impossible d’enregistrer cette proposition : ${error.toString()}';
      });
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Impossible d’enregistrer cette image.'),
          content: Text(error.toString()),
          severity: InfoBarSeverity.error,
        ),
        duration: snackbarShortDuration,
      );
    } finally {
      if (mounted) setState(() => _resolvingVehicleImage = false);
    }
  }

  Future<void> _pickAndUploadVehicleImage(ImageSource source) async {
    if (widget.readOnly ||
        !_canUploadVehicleImage ||
        !_vehicleImageLookupCompleted ||
        _vehicleImageCandidates.isNotEmpty ||
        _resolvingVehicleImage ||
        (_resolvedImageUrl?.isNotEmpty ?? false)) {
      return;
    }

    final make = VehicleMakeService.nameFor(marque);
    final model = type.text.trim();
    final year = int.tryParse(modelYearController.text.trim());
    final color = _normalizeVehiclePaint(colorController.text);
    if (make.trim().isEmpty || model.isEmpty || year == null) {
      displayInfoBar(
        context,
        builder: (context, close) => const InfoBar(
          title: Text('Renseignez d’abord la marque, le modèle et l’année.'),
          severity: InfoBarSeverity.warning,
        ),
        duration: snackbarShortDuration,
      );
      return;
    }

    try {
      final picked = await _vehicleImagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 82,
        maxWidth: 1600,
        maxHeight: 1200,
      );
      if (picked == null || !mounted) return;

      final extension = picked.name.split('.').last.toLowerCase();
      final mimeType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'jpg' || 'jpeg' => 'image/jpeg',
        _ => '',
      };
      if (mimeType.isEmpty) {
        displayInfoBar(
          context,
          builder: (context, close) => const InfoBar(
            title: Text('Format non pris en charge. Utilisez JPG, PNG ou WebP.'),
            severity: InfoBarSeverity.error,
          ),
          duration: snackbarShortDuration,
        );
        return;
      }

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        displayInfoBar(
          context,
          builder: (context, close) => const InfoBar(
            title: Text('La photo doit faire 5 Mo maximum.'),
            severity: InfoBarSeverity.error,
          ),
          duration: snackbarShortDuration,
        );
        return;
      }

      setState(() {
        _resolvingVehicleImage = true;
        _vehicleImageMessage = 'Envoi de la photo et ajout au catalogue partagé…';
      });

      final result = await VehicleImageService.uploadCustom(
        companyId: vehicleServices.companyId,
        make: make,
        model: model,
        year: year,
        color: color,
        bytes: bytes,
        mimeType: mimeType,
        fileName: picked.name,
      );
      if (!mounted) return;

      setState(() {
        _vehicleImageLookupCompleted = result.found;
        _vehicleImageCandidates = [];
        _resolvedImageUrl = result.imageUrl;
        _resolvedImageFileId = result.fileId;
        _resolvedImageSource = result.source;
        _resolvedImageLicense = result.license;
        _resolvedImageLicenseUrl = result.licenseUrl;
        _resolvedImageSourceUrl = result.sourceUrl;
        _resolvedImageAttribution = result.attribution;
        _resolvedImageMake = make;
        _resolvedImageModel = model;
        _resolvedImageYear = year;
        _resolvedImageColor = color;
        _vehicleImageMessage = result.found
            ? 'Photo ajoutée au catalogue partagé pour ce modèle, cette année et cette couleur.'
            : 'La photo n’a pas pu être ajoutée au catalogue partagé.';
      });

      if (result.found) {
        displayInfoBar(
          context,
          builder: (context, close) => const InfoBar(
            title: Text('Photo ajoutée au catalogue partagé.'),
            severity: InfoBarSeverity.success,
          ),
          duration: snackbarShortDuration,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _vehicleImageMessage = 'Échec de l’ajout de la photo : ${error.toString()}';
      });
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Impossible d’ajouter cette photo.'),
          content: Text(error.toString()),
          severity: InfoBarSeverity.error,
        ),
        duration: snackbarShortDuration,
      );
    } finally {
      if (mounted) {
        setState(() => _resolvingVehicleImage = false);
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

    try {
      await VehicleMakeService.load();
    } catch (_) {
      // Legacy brand indexes remain resolvable while offline.
    }
    if (!mounted) return;

    final currentMake = VehicleMakeService.nameFor(marque);
    final currentModel = type.text.trim();
    final currentYear = int.tryParse(modelYearController.text.trim());
    final currentColor = _normalizeVehiclePaint(colorController.text);
    final imageIdentityChanged = currentMake != (_resolvedImageMake ?? '') ||
        currentModel != (_resolvedImageModel ?? '') ||
        currentYear != _resolvedImageYear ||
        currentColor != (_resolvedImageColor ?? '');

    if (!widget.readOnly &&
        currentMake.isNotEmpty &&
        currentModel.isNotEmpty &&
        currentYear != null &&
        !(_vehicleImageLookupCompleted && !imageIdentityChanged &&
            (_resolvedImageUrl == null || _resolvedImageUrl!.isEmpty)) &&
        ((_resolvedImageUrl == null || _resolvedImageUrl!.isEmpty) ||
            imageIdentityChanged)) {
      await _resolveVehicleImage(showInfo: false);
    }

    if (mounted) {
      setState(() {
        uploading = true;
        errorUploading = false;
      });
      final selectedImageMake = VehicleMakeService.nameFor(marque);
      final selectedImageModel = type.text.trim();
      final selectedImageYear = int.tryParse(modelYearController.text.trim());
      final selectedImageColor = _normalizeVehiclePaint(colorController.text);
      final resolvedImageMatchesCurrentCriteria =
          _resolvedImageMake == selectedImageMake &&
          _resolvedImageModel == selectedImageModel &&
          _resolvedImageYear == selectedImageYear &&
          _resolvedImageColor == selectedImageColor;
      final originalImageMake =
          VehicleMakeService.nameFor(widget.vehicle?.marque);
      final existingImageMatchesCurrentCriteria =
          (widget.vehicle?.imageUrl?.trim().isNotEmpty ?? false) &&
          originalImageMake == selectedImageMake &&
          widget.vehicle?.type?.trim() == selectedImageModel &&
          widget.vehicle?.modelYear == selectedImageYear &&
          _normalizeVehiclePaint(widget.vehicle?.color) == selectedImageColor;
      final useResolvedVehicleImage = resolvedImageMatchesCurrentCriteria;
      final useExistingVehicleImage =
          !useResolvedVehicleImage && existingImageMatchesCurrentCriteria;
      final vehicleCustomFields = Map<String, dynamic>.from(
        widget.vehicle?.customFields ?? const <String, dynamic>{},
      );
      const imageMetadataKeys = [
        '_vehicleImageSource',
        '_vehicleImageSourceUrl',
        '_vehicleImageLicense',
        '_vehicleImageLicenseUrl',
        '_vehicleImageAttribution',
      ];
      if (useResolvedVehicleImage && _resolvedImageUrl?.isNotEmpty == true) {
        vehicleCustomFields['_vehicleImageSource'] = _resolvedImageSource;
        vehicleCustomFields['_vehicleImageSourceUrl'] = _resolvedImageSourceUrl;
        vehicleCustomFields['_vehicleImageLicense'] = _resolvedImageLicense;
        vehicleCustomFields['_vehicleImageLicenseUrl'] = _resolvedImageLicenseUrl;
        vehicleCustomFields['_vehicleImageAttribution'] = _resolvedImageAttribution;
      } else if (!useExistingVehicleImage) {
        for (final key in imageMetadataKeys) {
          vehicleCustomFields.remove(key);
        }
      }

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
        color: _normalizeVehiclePaint(colorController.text),
        engineDisplacement: int.tryParse(engineDisplacementController.text.trim()),
        enginePowerHp: double.tryParse(enginePowerHpController.text.trim().replaceAll(',', '.')),
        enginePowerKw: double.tryParse(enginePowerKwController.text.trim().replaceAll(',', '.')),
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
        imageFileId: useResolvedVehicleImage
            ? _resolvedImageFileId
            : useExistingVehicleImage
                ? widget.vehicle?.imageFileId
                : null,
        imageUrl: useResolvedVehicleImage
            ? _resolvedImageUrl
            : useExistingVehicleImage
                ? widget.vehicle?.imageUrl
                : null,
        imageSource: useResolvedVehicleImage
            ? _resolvedImageSource
            : useExistingVehicleImage
                ? widget.vehicle?.imageSource
                : null,
        customFields: vehicleCustomFields,
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
        marque: marque,
        matriculePrec: matriculesPrec,
        carrosserie: caross.text,
        charegeUtile: int.tryParse(charg.text),
        createdBy: widget.vehicle?.createdBy ?? DatabaseGetter.me.value?.id,
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
        decision: widget.vehicle?.decision ?? false,
        emplacement: widget.vehicle?.emplacement,
        etat: widget.vehicle?.etat,
        etatactuel: widget.vehicle?.etatactuel ?? 0,
        perimetre: widget.vehicle?.perimetre ?? 0,
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
        widget.onSaved?.call(vehicle);
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
      companyId: DatabaseGetter.activeCompanyId ?? (throw StateError('Aucune entreprise active.')),
    );
    await vehicleServices.repository.updateVehicle(domainVehicle);
  }

  Future<void> createVehicle(Vehicle vehicle) async {
    final now = DateTime.now().toUtc();
    vehicle.createdAt = now;
    vehicle.updatedAt = now;
    final domainVehicle = VehicleMapper.toDomain(
      vehicle,
      companyId: DatabaseGetter.activeCompanyId ?? (throw StateError('Aucune entreprise active.')),
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

class _VehicleMakePickerDialog extends StatefulWidget {
  final String? selectedMakeId;

  const _VehicleMakePickerDialog({this.selectedMakeId});

  @override
  State<_VehicleMakePickerDialog> createState() =>
      _VehicleMakePickerDialogState();
}

class _VehicleMakePickerDialogState extends State<_VehicleMakePickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final makes = VehicleMakeService.search(_query);
    return ContentDialog(
      title: const Text('Choisir une marque'),
      content: SizedBox(
        width: 520,
        height: 540,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextBox(
              controller: _searchController,
              placeholder: 'Rechercher une marque…',
              prefix: const Padding(
                padding: EdgeInsetsDirectional.only(start: 8),
                child: Icon(FluentIcons.search, size: 14),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: makes.isEmpty
                  ? const Center(child: Text('Aucune marque trouvée.'))
                  : ListView.separated(
                      itemCount: makes.length,
                      separatorBuilder: (_, _) => Container(
                        height: 1,
                        color: Colors.grey[30],
                      ),
                      itemBuilder: (context, index) {
                        final make = makes[index];
                        final selected = make.id == widget.selectedMakeId;
                        return Button(
                          onPressed: () => Navigator.of(context).pop(make.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                VehicleMakeLogo(makeId: make.id, size: 34),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        make.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        make.category,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[100],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                   Icon(
                                    FluentIcons.check_mark,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

