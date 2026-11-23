import 'package:country_code_picker/country_code_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/serializables/vehicle/vehicle.dart';
import 'package:parc_oto/serializables/vehicle/document_vehicle.dart';
import 'package:parc_oto/serializables/vehicle/state.dart';
import 'package:parc_oto/serializables/reparation/reparation.dart';
import 'package:parc_oto/serializables/reparation/fiche_reception.dart';
import 'package:parc_oto/providers/vehicle_provider.dart';
import 'package:parc_oto/providers/repair_provider.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';

import '../../../core/services/vehicle_make_service.dart';
import '../../../utilities/algeria_lists.dart';
import '../../../utilities/vehicle_detail_formatters.dart';
import '../../../utilities/vehicle_util.dart';
import '../../../ui/design_system/parcoto_tokens.dart';

class VehicleDetailsPage extends StatefulWidget {
  final Vehicle vehicle;
  final VoidCallback? onEdit;
  final VoidCallback? onBack;
  const VehicleDetailsPage({
    super.key,
    required this.vehicle,
    this.onEdit,
    this.onBack,
  });
  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  bool _requestedDocuments = false;
  bool _requestedMaintenance = false;
  bool _loadingMaintenance = false;
  bool _requestedHistory = false;
  bool _loadingHistory = false;
  bool _historyLoadFailed = false;
  bool _maintenanceLoadFailed = false;
  bool _documentsLoadFailed = false;
  bool _makeCatalogRequested = false;
  List<Etat> _vehicleStates = [];
  List<FicheReception> _receptionSheets = [];
  int _selectedSectionIndex = 0;
  int _vehicleLoadGeneration = 0;
  final ScrollController _contentScrollController = ScrollController();
  Vehicle get v => widget.vehicle;
  String get _normalizedRegistration => v.matricule.trim().toUpperCase();

  bool _matchesVehicleDocument(DocumentVehicle document) {
    final linkedVehicleId = document.vehicle?.trim();
    final linkedRegistration = document.vehiclemat?.trim().toUpperCase();
    return linkedVehicleId == v.id ||
        (linkedRegistration != null &&
            linkedRegistration.isNotEmpty &&
            linkedRegistration == _normalizedRegistration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDocuments();
    _loadVehicleMakeCatalog();
    _loadHistory();
  }

  @override
  void didUpdateWidget(covariant VehicleDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicle.id == widget.vehicle.id) return;

    _vehicleLoadGeneration++;
    _selectedSectionIndex = 0;
    _requestedDocuments = false;
    _requestedMaintenance = false;
    _loadingMaintenance = false;
    _requestedHistory = false;
    _loadingHistory = false;
    _historyLoadFailed = false;
    _maintenanceLoadFailed = false;
    _documentsLoadFailed = false;
    _vehicleStates = [];
    _receptionSheets = [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_contentScrollController.hasClients) {
        _contentScrollController.jumpTo(0);
      }
      _loadDocuments();
      _loadHistory();
    });
  }

  Future<void> _loadDocuments({bool force = false}) async {
    if (_requestedDocuments && !force) return;
    _requestedDocuments = true;
    _documentsLoadFailed = false;

    try {
      final provider = context.read<VehicleProvider>();
      if (VehicleProvider.downloadingDocuments) {
        await _waitForLoading(
          () => VehicleProvider.downloadingDocuments,
          'documents',
        );
      }
      if (!mounted) return;

      if (!VehicleProvider.downloadedDocuments) {
        await provider.refreshDocuments();
      }
      if (!mounted) return;

      final failed = !VehicleProvider.downloadedDocuments &&
          !VehicleProvider.downloadingDocuments;
      setState(() => _documentsLoadFailed = failed);
      if (failed) _requestedDocuments = false;
    } catch (error) {
      if (!mounted) return;
      debugPrint('[Vehicle details] documents load failed: $error');
      setState(() => _documentsLoadFailed = true);
      _requestedDocuments = false;
    }
  }

  Future<void> _loadVehicleMakeCatalog() async {
    if (_makeCatalogRequested) return;
    _makeCatalogRequested = true;
    try {
      await VehicleMakeService.load();
      if (mounted) setState(() {});
    } catch (error) {
      // The local legacy catalogue remains available as a display fallback.
      debugPrint('[Vehicle details] make catalogue unavailable: $error');
    }
  }

  Future<void> _waitForLoading(
    bool Function() isLoading,
    String resource,
  ) async {
    for (var attempt = 0; attempt < 200 && isLoading(); attempt++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }
    if (isLoading()) {
      throw StateError('Timed out while waiting for $resource to load.');
    }
  }

  void _ensureSectionDataLoaded(int index) {
    switch (index) {
      case 0:
        _loadDocuments();
        _loadHistory();
        break;
      case 5:
        _loadDocuments();
        break;
      case 6:
        _loadMaintenance();
        break;
      case 7:
        _loadHistory();
        break;
    }
  }

  String val(String? s) =>
      s == null || s.trim().isEmpty ? 'Non renseigné' : s.trim();
  String n(num? x, [String suffix = '']) => x == null
      ? 'Non renseigné'
      : '${VehicleDetailFormatters.formatNumber(x)}$suffix';

  String? _countryName(String? rawCode) {
    final code = rawCode?.trim() ?? '';
    if (code.isEmpty) return null;

    try {
      final country = CountryCode.fromCountryCode(code.toUpperCase());
      final localizedName = country.localize(context).name?.trim();
      if (localizedName != null && localizedName.isNotEmpty) {
        return localizedName;
      }
    } catch (error) {
      debugPrint('[Vehicle details] country code "$code" could not be resolved: $error');
    }

    return code.toUpperCase();
  }

  String? _wilayaName(int? code) {
    if (code == null) return null;

    final name = AlgeriaList().getWilayaByNum(code.toString())?.trim();
    if (name != null && name.isNotEmpty) return name;

    // Keep unknown codes explicit. Never present a code as if it were a name.
    return 'Wilaya $code (nom indisponible dans le référentiel local)';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppTheme>();
    final accent = FluentTheme.of(context).accentColor;
    final makeName = VehicleMakeService.nameFor(VehicleMakeService.canonicalId(v.marque));
    final model = [
      makeName,
      v.type?.trim() ?? '',
      v.modelYear?.toString() ?? '',
    ].where((value) => value.isNotEmpty).join(' ');
    final compact = MediaQuery.sizeOf(context).width < ParcotoTokens.mobileBreakpoint;

    return Container(
      color: app.backGroundColor,
      child: Column(
        children: [
          _header(accent, model.isEmpty ? 'Fiche véhicule' : model),
          _buildSectionNavigation(compact: compact),
          Expanded(
            child: SingleChildScrollView(
              controller: _contentScrollController,
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 22,
                18,
                compact ? 12 : 22,
                28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: _content(accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectSection(int index) {
    if (index == _selectedSectionIndex) return;
    setState(() => _selectedSectionIndex = index);
    if (_contentScrollController.hasClients) {
      _contentScrollController.jumpTo(0);
    }
    _ensureSectionDataLoaded(index);
  }

  Widget _buildSectionNavigation({
    required bool compact,
  }) {
    const sections = <({String label, IconData icon})>[
      (label: 'Aperçu', icon: FluentIcons.view_dashboard),
      (label: 'Identification', icon: FluentIcons.info),
      (label: 'Caractéristiques', icon: FluentIcons.settings),
      (label: 'Affectation', icon: FluentIcons.account_management),
      (label: 'Localisation', icon: FluentIcons.car),
      (label: 'Documents', icon: FluentIcons.document_set),
      (label: 'Maintenance', icon: FluentIcons.repair),
      (label: 'Historique', icon: FluentIcons.document),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 22,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).micaBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey[30]),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < sections.length; index++) ...[
              if (index > 0) const SizedBox(width: 7),
              if (_selectedSectionIndex == index)
                FilledButton(
                  key: ValueKey('vehicle-section-$index'),
                  onPressed: () => _selectSection(index),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sections[index].icon, size: 13),
                      const SizedBox(width: 7),
                      Text(sections[index].label),
                    ],
                  ),
                )
              else
                Button(
                  key: ValueKey('vehicle-section-$index'),
                  onPressed: () => _selectSection(index),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sections[index].icon, size: 13),
                      const SizedBox(width: 7),
                      Text(sections[index].label),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(Color accent, String model) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < ParcotoTokens.tabletBreakpoint;
        final identity = Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FICHE VÉHICULE',
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                v.matricule,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 20 : 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                model.isEmpty ? 'Modèle non renseigné' : model,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[100],
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              if (v.etatactuel != null) ...[
                const SizedBox(height: 8),
                _chip(
                  VehiclesUtilities.getEtatName(v.etatactuel!).tr(),
                  accent,
                ),
              ],
            ],
          ),
        );

        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.onBack != null)
              Button(
                onPressed: widget.onBack,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.back, size: 13),
                    SizedBox(width: 7),
                    Text('Retour au parc'),
                  ],
                ),
              ),
            if (widget.onEdit != null)
              FilledButton(
                onPressed: widget.onEdit,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.edit, size: 14),
                    SizedBox(width: 7),
                    Text('Modifier'),
                  ],
                ),
              ),
          ],
        );

        return Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 22,
            compact ? 12 : 18,
            compact ? 12 : 22,
            compact ? 14 : 18,
          ),
          decoration: BoxDecoration(
            color: FluentTheme.of(context).micaBackgroundColor,
            border: Border(bottom: BorderSide(color: Colors.grey[30])),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _vehicleAvatar(accent, compact: true),
                        const SizedBox(width: 12),
                        identity,
                      ],
                    ),
                    const SizedBox(height: 12),
                    actions,
                  ],
                )
              : Row(
                  children: [
                    _vehicleAvatar(accent, compact: false),
                    const SizedBox(width: 18),
                    identity,
                    const SizedBox(width: 14),
                    actions,
                  ],
                ),
        );
      },
    );
  }

  Widget _vehicleAvatar(Color accent, {required bool compact}) {
    final imageUrl = v.imageUrl?.trim();
    final width = compact ? 88.0 : 148.0;
    final height = compact ? 82.0 : 104.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .10),
          border: Border.all(color: accent.withValues(alpha: .12)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(FluentIcons.car, size: 36, color: accent),
              )
            : Icon(FluentIcons.car, size: 36, color: accent),
      ),
    );
  }

  String _date(Object? value) {
    if (value == null) return 'Non renseigné';
    final date =
        value is DateTime ? value : DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _chip(String text, Color accent) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
      );

  Future<void> _loadHistory() async {
    if (_requestedHistory || _loadingHistory) return;
    _requestedHistory = true;
    _loadingHistory = true;
    _historyLoadFailed = false;
    final generation = _vehicleLoadGeneration;
    final vehicleId = v.id;
    final registration = v.matricule.trim();
    setState(() {});

    try {
      final provider = context.read<VehicleProvider>();
      if (VehicleProvider.downloadingStates) {
        await _waitForLoading(
          () => VehicleProvider.downloadingStates,
          'vehicle history',
        );
      }
      if (!mounted || generation != _vehicleLoadGeneration) return;

      if (!VehicleProvider.downloadedStates) {
        await provider.refreshStates();
      }
      if (!mounted || generation != _vehicleLoadGeneration) return;
      if (!VehicleProvider.downloadedStates) {
        throw StateError('Vehicle history could not be loaded from Appwrite.');
      }

      final states = VehicleProvider.etats.values.where((state) =>
          state.vehicle == vehicleId ||
          state.vehicleMat.trim() == registration).toList()
        ..sort((a, b) {
          final aDate = a.date ?? a.updatedAt ?? a.createdAt;
          final bDate = b.date ?? b.updatedAt ?? b.createdAt;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

      if (!mounted || generation != _vehicleLoadGeneration) return;
      setState(() {
        _vehicleStates = states;
        _loadingHistory = false;
        _historyLoadFailed = false;
      });
    } catch (error) {
      if (!mounted || generation != _vehicleLoadGeneration) return;
      debugPrint('[Vehicle details] history load failed: $error');
      setState(() {
        _loadingHistory = false;
        _historyLoadFailed = true;
      });
      _requestedHistory = false;
    }
  }

  Future<void> _loadMaintenance() async {
    if (_requestedMaintenance || _loadingMaintenance) return;
    _requestedMaintenance = true;
    _loadingMaintenance = true;
    _maintenanceLoadFailed = false;
    final generation = _vehicleLoadGeneration;
    final registration = v.matricule.trim();
    setState(() {});

    try {
      // Reuse the dashboard-owned provider instead of creating an unmanaged
      // ChangeNotifier instance for this page.
      final repairProvider = context.read<RepairProvider>();
      if (RepairProvider.downloadingReparations) {
        await _waitForLoading(
          () => RepairProvider.downloadingReparations,
          'repair orders',
        );
      }
      if (!mounted || generation != _vehicleLoadGeneration) return;

      if (!RepairProvider.downloadedReparations) {
        await repairProvider.refreshReparations();
      }
      if (!mounted || generation != _vehicleLoadGeneration) return;

      await RepairProvider.downloadFicheReparations();
      if (!mounted || generation != _vehicleLoadGeneration) return;

      final normalizedRegistration = registration.toUpperCase();
      final sheets = RepairProvider.repPerVeh.entries
          .where((entry) =>
              entry.key == v.id ||
              entry.key.trim().toUpperCase() == normalizedRegistration)
          .expand((entry) => entry.value)
          .toList()
        ..sort((a, b) => b.dateEntre.compareTo(a.dateEntre));

      final couldNotVerify = !RepairProvider.downloadedReparations &&
          RepairProvider.reparations.isEmpty &&
          !RepairProvider.receptionSheetsVerified &&
          sheets.isEmpty;
      if (couldNotVerify) {
        throw StateError('Maintenance data could not be verified.');
      }

      setState(() {
        _receptionSheets = sheets;
        _loadingMaintenance = false;
        _maintenanceLoadFailed = false;
      });
    } catch (error) {
      if (!mounted || generation != _vehicleLoadGeneration) return;
      debugPrint('[Vehicle details] maintenance load failed: $error');
      setState(() {
        _loadingMaintenance = false;
        _maintenanceLoadFailed = true;
      });
      _requestedMaintenance = false;
    }
  }

  Widget _content(Color accent) {
    switch (_selectedSectionIndex) {
      case 0:
        return _overview(accent);
      case 1:
        return _section(
          'Identification',
          'Immatriculation, carte grise et titulaire',
          [
            _group('Identification du véhicule', [
              _field('Immatriculation principale', v.matricule),
              _field('Pays d’immatriculation', _countryName(v.pays)),
              _field(
                'Immatriculation étrangère',
                v.matriculeEtrang ? 'Oui' : 'Non',
              ),
              _field(
                'Anciennes immatriculations',
                v.matriculePrec?.join(', '),
              ),
              _field('VIN / numéro de série', v.numeroSerie),
            ]),
            _group('Document d’immatriculation', [
              _field('Date enregistrée sur la fiche', _date(v.date)),
              _field('Numéro / référence du document', v.numero),
              _field(
                'Montant de quittance (unité non documentée)',
                v.quittance == null
                    ? null
                    : VehicleDetailFormatters.formatNumber(v.quittance!),
              ),
            ]),
            _group('Adresse administrative', [
              _field('Wilaya', _wilayaName(v.wilaya)),
              _field('Daïra', v.daira),
              _field('Commune', v.commune),
              _field('Adresse', v.adresse),
            ]),
            _group('Titulaire de la carte grise', [
              _field('Nom', v.nom),
              _field('Prénom', v.prenom),
              _field('Profession', v.profession),
            ]),
          ],
        );
      case 2:
        return _section(
          'Caractéristiques techniques',
          'Identité du véhicule, motorisation, transmission, dimensions et capacités',
          [
            _group('Identité constructeur et classification', [
              _field(
                'Marque',
                VehicleMakeService.nameFor(
                  VehicleMakeService.canonicalId(v.marque),
                ),
              ),
              _field('Modèle / type', v.type),
              _field('Finition', v.trim),
              _field('Année modèle', v.modelYear?.toString()),
              _field(
                'Année d’utilisation (champ historique)',
                v.anneeUtil?.toString(),
              ),
              _field(
                'Genre administratif',
                VehicleDetailFormatters.genreLabel(v.genre)?.tr(),
              ),
              _field('Carrosserie', v.carrosserie),
              _field(
                'Couleur',
                VehicleDetailFormatters.paintLabel(v.color),
              ),
            ]),
            _group('Motorisation', [
              _field('Énergie', v.energie),
              _field(
                'Cylindrée',
                v.engineDisplacement == null
                    ? null
                    : '${VehicleDetailFormatters.formatNumber(v.engineDisplacement!)} cm³',
              ),
              _field(
                'Puissance fiscale',
                v.puissance == null ? null : '${v.puissance} CV',
              ),
              _field(
                'Puissance moteur (ch)',
                v.enginePowerHp == null ? null : '${v.enginePowerHp} ch',
              ),
              _field(
                'Puissance moteur (kW)',
                v.enginePowerKw == null ? null : '${v.enginePowerKw} kW',
              ),
              _field('Code moteur', v.engineCode),
            ]),
            _group('Transmission', [
              _field('Transmission', v.transmission),
              _field('Boîte de vitesses', v.gearbox),
              _field('Roues motrices', v.driveType),
            ]),
            _group('Dimensions et capacité', [
              _field('Nombre de portes', v.doors?.toString()),
              _field('Places assises', v.placesAssises?.toString()),
              _field(
                'Poids total',
                v.poidsTotal == null ? null : '${v.poidsTotal} kg',
              ),
              _field(
                'Charge utile',
                v.charegeUtile == null ? null : '${v.charegeUtile} kg',
              ),
              _field(
                'Longueur',
                v.lengthMm == null ? null : '${v.lengthMm} mm',
              ),
              _field(
                'Largeur',
                v.widthMm == null ? null : '${v.widthMm} mm',
              ),
              _field(
                'Hauteur',
                v.heightMm == null ? null : '${v.heightMm} mm',
              ),
              _field(
                'Indicateur véhicule lourd (legacy)',
                v.lourd ? 'Oui' : null,
              ),
            ]),
          ],
        );
      case 3:
        return _section(
          'Affectation et organisation',
          'Conducteur, rattachement organisationnel et état opérationnel',
          [
            _group('Conducteur', [
              _field('Matricule conducteur', v.matriculeConducteur),
              _field('Appartenance conducteur (legacy)', v.appartenanceconducteur),
            ]),
            _group('Rattachement organisationnel (valeurs legacy)', [
              _field('Appartenance', v.appartenance),
              _field('Filiale', v.filliale),
              _field('Direction', v.direction),
              _field('Département', v.departement),
              _field(
                'Code de périmètre legacy',
                v.perimetre == 0 ? null : v.perimetre.toString(),
              ),
            ]),
            _group('État et usage', [
              _field(
                'État opérationnel',
                v.etatactuel == null
                    ? null
                    : VehiclesUtilities.getEtatName(v.etatactuel!).tr(),
              ),
              _field('Ancienne valeur « état »', v.etat),
              _field('Type d’usage', v.service ? 'Véhicule de service' : 'Usage non précisé'),
              _field('Emplacement historique', v.emplacement),
            ]),
          ],
        );
      case 4:
        return _gpsParkingSection(accent);
      case 5:
        return _documentsSection(accent);
      case 6:
        return _maintenanceSection(accent);
      case 7:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _historySection(accent),
            _section(
              'Acquisition et garantie',
              'Informations d’acquisition actuellement enregistrées sur la fiche',
              [
                _group('Acquisition', [
                  _field('Mode', v.acquisitionType),
                  _field('Date', _date(v.acquisitionDate)),
                  _field('Prix d’achat', v.purchasePrice == null ? null : '${v.purchasePrice} DA'),
                  _field('Fournisseur', v.supplier),
                  _field('Fin de garantie', _date(v.warrantyEndDate)),
                  _field('Numéro de flotte', v.fleetNumber),
                ]),
                _group('Métadonnées de la fiche', [
                  _field('Créée le', _date(v.createdAt)),
                  _field('Modifiée le', _date(v.updatedAt)),
                ]),
              ],
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _gpsParkingSection(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Géolocalisation & stationnement',
          'Position et emplacement du véhicule dans le parc',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= ParcotoTokens.mobileBreakpoint;
            final cardWidth = twoColumns
                ? (constraints.maxWidth - 14) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _panel(
                    'Suivi GPS',
                    FluentIcons.car,
                    accent,
                    [
                      _statusValue(
                        'Dernière position reçue',
                        'Aucune donnée GPS disponible',
                        accent,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Le suivi GPS n’est pas encore connecté à une source de position pour ce véhicule.',
                        style: TextStyle(
                          color: Colors.grey[100],
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _panel(
                    'Parking & emplacement',
                    FluentIcons.car,
                    accent,
                    [
                      _statusValue(
                        'Emplacement historique',
                        val(v.emplacement),
                        accent,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cette valeur provient de l’ancien champ texte « emplacement » ; elle ne confirme pas une place de parking normalisée.',
                        style: TextStyle(
                          color: Colors.grey[100],
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }


  Widget _overview(Color accent) {
    final documents = VehicleProvider.documentsVehicules.values
        .where(_matchesVehicleDocument)
        .toList();
    final documentsWithDeadline =
        documents.where((doc) => doc.dateExpiration != null).length;
    final documentsUnavailable = _documentsLoadFailed ||
        (!VehicleProvider.downloadedDocuments &&
            !VehicleProvider.downloadingDocuments);
    final documentsCountValue = documentsUnavailable
        ? 'Indisponible'
        : VehicleProvider.downloadingDocuments
            ? 'Chargement…'
            : documents.length.toString();
    final documentsDeadlineValue = documentsUnavailable
        ? '—'
        : VehicleProvider.downloadingDocuments
            ? '—'
            : documentsWithDeadline.toString();
    final latestActivity =
        _vehicleStates.isEmpty ? null : _vehicleStates.first;
    final makeName = VehicleMakeService.nameFor(VehicleMakeService.canonicalId(v.marque));
    final currentStatus = v.etatactuel == null
        ? 'Non renseigné'
        : VehiclesUtilities.getEtatName(v.etatactuel!).tr();

    final identityFields = <_VehicleField>[
      _field('Immatriculation', v.matricule),
      _field('Marque', makeName),
      _field('Modèle', v.type),
      _field('Année modèle', v.modelYear?.toString()),
      _field('VIN / numéro de série', v.numeroSerie),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Vue générale',
          'Les informations essentielles du véhicule et les éléments nécessitant une attention',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= ParcotoTokens.tabletBreakpoint;
            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _group('Identité du véhicule', identityFields),
                _sectionShortcut('Voir l’identification', 1),
                _group('Affectation connue', [
                  _field('Matricule conducteur', v.matriculeConducteur),
                  _field('Filiale', v.filliale),
                  _field('Direction', v.direction),
                  _field('Département', v.departement),
                  // Emplacement legacy is shown only in Localisation.
                ]),
                _sectionShortcut('Voir l’affectation', 3),
              ],
            );
            final right = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _panel(
                  'État et usage',
                  FluentIcons.info,
                  accent,
                  [
                    _statusValue('État opérationnel', currentStatus, accent),
                    const SizedBox(height: 12),
                    _statusValue(
                      'Type d’usage',
                      v.service ? 'Véhicule de service' : 'Usage non précisé',
                      accent,
                    ),
                    if (v.etat?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      _statusValue(
                        'Valeur historique « état »',
                        v.etat!.trim(),
                        accent,
                      ),
                    ],
                    _sectionShortcut('Voir l’affectation', 3),
                  ],
                ),
                _panel(
                  'Documents',
                  FluentIcons.document,
                  accent,
                  [
                    Row(
                      children: [
                        Expanded(
                          child: _statusValue(
                            'Documents enregistrés',
                            documentsCountValue,
                            accent,
                          ),
                        ),
                        Expanded(
                          child: _statusValue(
                            'Avec échéance',
                            documentsDeadlineValue,
                            accent,
                          ),
                        ),
                      ],
                    ),
                    if (_documentsLoadFailed)
                      _retryNotice(
                        'Les documents n’ont pas pu être vérifiés.',
                        () => _loadDocuments(force: true),
                      ),
                    const SizedBox(height: 9),
                    Text(
                      'Les dates et métadonnées sont détaillées dans la rubrique Documents.',
                      style: TextStyle(
                        color: Colors.grey[100],
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    _sectionShortcut('Voir les documents', 5),
                  ],
                ),
                _panel(
                  'Kilométrage enregistré',
                  FluentIcons.car,
                  accent,
                  [
                    _statusValue(
                      'Valeur enregistrée',
                      n(v.currentMileage, ' km'),
                      accent,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La date et la source de cette valeur ne sont pas disponibles dans la fiche actuelle.',
                      style: TextStyle(
                        color: Colors.grey[100],
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    if (v.nextServiceMileage != null) ...[
                      const SizedBox(height: 9),
                      _statusValue(
                        'Seuil de révision legacy',
                        n(v.nextServiceMileage, ' km'),
                        accent,
                      ),
                    ],
                    _sectionShortcut('Voir la maintenance', 6),
                  ],
                ),
                _panel(
                  'Localisation',
                  FluentIcons.car,
                  accent,
                  [
                    _statusValue(
                      'Dernière position',
                      'Aucune position GPS reçue',
                      accent,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Aucune source GPS réelle n’est actuellement associée à ce véhicule.',
                      style: TextStyle(
                        color: Colors.grey[100],
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    _sectionShortcut('Voir la localisation', 4),
                  ],
                ),
                _panel(
                  'Activité récente',
                  FluentIcons.document,
                  accent,
                  [
                    if (_loadingHistory && latestActivity == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: ProgressRing(),
                        ),
                      )
                    else if (_historyLoadFailed)
                      _retryNotice(
                        'L’activité récente n’a pas pu être chargée.',
                        _loadHistory,
                      )
                    else if (latestActivity == null)
                      _emptyInline('Aucun événement enregistré pour ce véhicule')
                    else ...[
                      _statusValue(
                        'Dernier changement enregistré',
                        'État ${latestActivity.type}',
                        accent,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _date(
                          latestActivity.date ??
                              latestActivity.updatedAt ??
                              latestActivity.createdAt,
                        ),
                        style: TextStyle(
                          color: Colors.grey[100],
                          fontSize: 11,
                        ),
                      ),
                      if (latestActivity.remarque?.trim().isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            latestActivity.remarque!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[100],
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                    _sectionShortcut('Voir l’historique complet', 7),
                  ],
                ),
              ],
            );

            if (!wide) return Column(children: [left, right]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: left),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: right),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _panel(
          String title, IconData icon, Color accent, List<Widget> children) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: FluentTheme.of(context).micaBackgroundColor,
          border: Border.all(color: Colors.grey[30]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: accent, size: 16),
              const SizedBox(width: 9),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );

  Widget _statusValue(String label, String value, Color accent) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[100], fontSize: 11)),
          const SizedBox(height: 5),
          Text(value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      );

  Widget _sectionShortcut(String label, int sectionIndex) => Align(
        alignment: Alignment.centerRight,
        child: Button(
          onPressed: () => _selectSection(sectionIndex),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              const SizedBox(width: 6),
              const Icon(FluentIcons.chevron_right, size: 11),
            ],
          ),
        ),
      );

  Widget _historySection(Color accent) {
    if (_loadingHistory && _vehicleStates.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(36), child: ProgressRing()));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Historique du véhicule',
            'Événements de statut enregistrés dans le registre des états Parcoto'),
        _panel('Changements d’état', FluentIcons.document, accent, [
          if (_historyLoadFailed)
            _retryNotice(
              'Impossible de charger l’historique. Vérifiez la connexion puis réessayez.',
              _loadHistory,
            ),
          if (_vehicleStates.isEmpty && !_historyLoadFailed)
            _emptyInline('Aucun changement d’état enregistré pour ce véhicule')
          else
            ..._vehicleStates.map((state) => Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(FluentIcons.chevron_right, color: accent, size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('État ${state.type}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(
                        '${_date(state.date ?? state.updatedAt ?? state.createdAt)}'
                        '${state.ordreNum == null ? '' : ' • Ordre #${state.ordreNum}'}',
                        style: TextStyle(color: Colors.grey[100], fontSize: 11)),
                      if (state.remarque?.trim().isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(state.remarque!,
                              style: const TextStyle(fontSize: 12)),
                        ),
                    ],
                  )),
                ],
              ),
            )),
        ]),
        if (_loadingHistory)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: ProgressRing()),
          ),
      ],
    );
  }

  Widget _maintenanceSection(Color accent) {
    final repairs = RepairProvider.reparations.values.where((repair) =>
        repair.vehiculemat?.trim().toUpperCase() == _normalizedRegistration ||
        repair.vehicule == v.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final sheets = _receptionSheets;
    final totalCost = sheets.fold<double>(
        0, (sum, sheet) => sum + (sheet.reparationCost ?? 0));

    if (_loadingMaintenance && repairs.isEmpty && sheets.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(36), child: ProgressRing()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Maintenance & interventions',
            'Interventions et fiches de réception réellement enregistrées pour ce véhicule'),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= ParcotoTokens.tabletBreakpoint
              ? 3
              : constraints.maxWidth >= ParcotoTokens.mobileBreakpoint
                  ? 2
                  : 1;
          final width =
              (constraints.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            _metric(width, FluentIcons.repair, 'Ordres de réparation',
                repairs.length.toString(), accent),
            _metric(width, FluentIcons.document, 'Fiches de réception',
                sheets.length.toString(), accent),
            _metric(width, FluentIcons.money, 'Coût enregistré',
                '${totalCost.toStringAsFixed(2)} DA', accent),
          ]);
        }),
        const SizedBox(height: 20),
        if (_maintenanceLoadFailed)
          _retryNotice(
            'Certaines données de maintenance n’ont pas pu être vérifiées. Réessayez le chargement.',
            _loadMaintenance,
          ),
        _panel('Ordres de réparation', FluentIcons.repair, accent, [
          if (repairs.isEmpty && !_maintenanceLoadFailed)
            _emptyInline('Aucun ordre de réparation associé à ce véhicule')
          else if (repairs.isNotEmpty)
            ...repairs.map((repair) => _repairRow(repair, accent)),
        ]),
        _panel('Fiches de réception', FluentIcons.document, accent, [
          if (sheets.isEmpty && !_maintenanceLoadFailed)
            _emptyInline('Aucune fiche de réception trouvée pour cette immatriculation')
          else if (sheets.isNotEmpty)
            ...sheets.map((sheet) => _receptionRow(sheet, accent)),
        ]),
        if (_loadingMaintenance)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: ProgressRing()),
          ),
      ],
    );
  }

  Widget _repairRow(Reparation repair, Color accent) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(children: [
      Icon(FluentIcons.repair, color: accent, size: 17),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ordre #${repair.numero}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text('${_date(repair.date)} • ${repair.prestatairenom ?? 'Prestataire non renseigné'}',
            style: TextStyle(color: Colors.grey[100], fontSize: 11)),
        if (repair.remarque?.trim().isNotEmpty == true)
          Text(repair.remarque!, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[100], fontSize: 11)),
      ])),
      _chip(repair.etat == 2 ? 'Terminé' : repair.etat == 1 ? 'En cours' : 'En attente', accent),
    ]),
  );

  Widget _receptionRow(FicheReception sheet, Color accent) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(children: [
      Icon(FluentIcons.document, color: accent, size: 17),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Fiche de réception #${sheet.numero}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text('Entrée : ${_date(sheet.dateEntre)}'
            '${sheet.dateSortie == null ? ' • Toujours ouverte' : ' • Sortie : ${_date(sheet.dateSortie)}'}',
            style: TextStyle(color: Colors.grey[100], fontSize: 11)),
        if (sheet.kilometrage != null)
          Text('Kilométrage : ${sheet.kilometrage} km',
              style: TextStyle(color: Colors.grey[100], fontSize: 11)),
        if (sheet.remarque?.trim().isNotEmpty == true)
          Text(sheet.remarque!, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[100], fontSize: 11)),
      ])),
      if (sheet.reparationCost != null)
        Text('${sheet.reparationCost!.toStringAsFixed(2)} DA',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _emptyInline(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(message,
        style: TextStyle(color: Colors.grey[100], fontSize: 12)),
  );

  Widget _retryNotice(String message, VoidCallback onRetry) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: .08),
      border: Border.all(color: Colors.orange.withValues(alpha: .28)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            message,
            style: TextStyle(color: Colors.grey[100], fontSize: 12),
          ),
        ),
        Button(
          onPressed: onRetry,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FluentIcons.refresh, size: 12),
              SizedBox(width: 6),
              Text('Réessayer'),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _documentsSection(Color accent) {
    context.watch<VehicleProvider>();
    final documents = VehicleProvider.documentsVehicules.values
        .where(_matchesVehicleDocument)
        .toList()
      ..sort((a, b) {
        final aDate = a.dateExpiration;
        final bDate = b.dateExpiration;
        if (aDate == null && bDate == null) return a.nom.compareTo(b.nom);
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });

    if (VehicleProvider.downloadingDocuments && documents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: ProgressRing(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Documents du véhicule',
          'Documents administratifs et dates d’expiration enregistrés dans Parcoto',
        ),
        if (_documentsLoadFailed)
          _retryNotice(
            'Impossible de récupérer les documents du véhicule. Réessayez le chargement.',
            () => _loadDocuments(force: true),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 440;
            final cardWidth = twoColumns
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _documentSummary(
                    'Documents enregistrés',
                    documents.length.toString(),
                    FluentIcons.document,
                    accent,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _documentSummary(
                    'Avec échéance',
                    documents.where((d) => d.dateExpiration != null).length.toString(),
                    FluentIcons.calendar,
                    accent,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        if (documents.isEmpty && !_documentsLoadFailed)
          _empty(
            FluentIcons.document,
            'Aucun document enregistré pour ce véhicule',
            'Les documents associés à cette immatriculation apparaîtront ici dès leur création dans la gestion documentaire.',
            'Aucun document trouvé',
          )
        else if (documents.isNotEmpty)
          ...documents.map((document) => _documentTile(document, accent)),
        Align(
          alignment: Alignment.centerRight,
          child: Button(
            onPressed: VehicleProvider.downloadingDocuments
                ? null
                : () => _loadDocuments(force: true),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(FluentIcons.refresh, size: 13),
                const SizedBox(width: 7),
                Text(VehicleProvider.downloadingDocuments
                    ? 'Actualisation…'
                    : 'Actualiser'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Note : la version actuelle conserve les métadonnées du document. '
          'Aucun fichier joint n’est encore référencé dans ce modèle.',
          style: TextStyle(color: Colors.grey[100], fontSize: 11),
        ),
      ],
    );
  }

  Widget _documentSummary(
    String label,
    String value,
    IconData icon,
    Color accent,
  ) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[30]),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(color: Colors.grey[100], fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _documentTile(DocumentVehicle document, Color accent) {
    final expiration = document.dateExpiration;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = expiration == null
        ? null
        : DateTime(expiration.year, expiration.month, expiration.day);
    final expired = expiryDay != null && expiryDay.isBefore(today);
    final daysRemaining = expiryDay?.difference(today).inDays;
    final status = expiration == null
        ? 'Échéance inconnue'
        : expired
            ? 'Expiré'
            : daysRemaining == 0
                ? 'Expire aujourd’hui'
                : daysRemaining != null && daysRemaining <= 30
                    ? 'Expire bientôt'
                    : 'Valide';
    final statusColor =
        expired || (daysRemaining != null && daysRemaining <= 30)
            ? Colors.orange
            : accent;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).micaBackgroundColor,
        border: Border.all(color: Colors.grey[30]),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(FluentIcons.document, color: accent, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(document.nom,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(
                  expiration == null
                      ? 'Date d’expiration non renseignée'
                      : 'Expiration : ${_date(expiration)}',
                  style: TextStyle(color: Colors.grey[100], fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _chip(status, statusColor),
        ],
      ),
    );
  }

  Widget _section(String title, String desc, List<Widget> groups) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_heading(title, desc), ...groups],
      );

  Widget _heading(String title, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(desc,
                style: TextStyle(color: Colors.grey[100], fontSize: 12)),
          ],
        ),
      );

  Widget _group(String title, List<_VehicleField> fields) {
    final visible = fields.where((f) => f.hasValue).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).micaBackgroundColor,
        border: Border.all(color: Colors.grey[30]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth >= ParcotoTokens.tabletBreakpoint
                ? 3
                : c.maxWidth >= ParcotoTokens.mobileBreakpoint
                    ? 2
                    : 1;
            final w = (c.maxWidth - (cols - 1) * 18) / cols;
            return Wrap(
              spacing: 18,
              runSpacing: 16,
              children: visible.map((f) => SizedBox(width: w, child: f)).toList(),
            );
          }),
        ],
      ),
    );
  }

  _VehicleField _field(String label, String? raw) =>
      _VehicleField(label, val(raw));
  
  Widget _metric(double width, IconData icon, String label, String data, Color accent) =>
      Container(
        width: width,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: FluentTheme.of(context).micaBackgroundColor,
          border: Border.all(color: Colors.grey[30]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[100], fontSize: 11)),
              const SizedBox(height: 5),
              Text(data, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          )),
        ]),
      );

  Widget _empty(IconData icon, String title, String desc, String status) =>
      Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Column(
            children: [
              Icon(icon, size: 38, color: Colors.grey[100]),
              const SizedBox(height: 18),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[100], height: 1.5)),
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                    color: Colors.grey[20],
                    borderRadius: BorderRadius.circular(20)),
                child: Text(status,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
  @override
  void dispose() {
    _contentScrollController.dispose();
    super.dispose();
  }
}

class _VehicleField extends StatelessWidget {
  final String label;
  final String value;
  const _VehicleField(this.label, this.value);
  bool get hasValue => value != 'Non renseigné';
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[100],
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 5),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      );
}
