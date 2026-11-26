import 'package:country_code_picker/country_code_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/serializables/conducteur/conducteur.dart';
import 'package:parc_oto/serializables/vehicle/vehicle.dart';
import 'package:parc_oto/serializables/vehicle/document_vehicle.dart';
import 'package:parc_oto/serializables/vehicle/state.dart';
import 'package:parc_oto/serializables/reparation/reparation.dart';
import 'package:parc_oto/serializables/reparation/fiche_reception.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/providers/driver_provider.dart';
import 'package:parc_oto/providers/vehicle_provider.dart';
import 'package:parc_oto/providers/repair_provider.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';

import '../../../core/services/vehicle_make_service.dart';
import '../../../screens/entreprise/entreprise.dart';
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
  bool _requestedDrivers = false;
  bool _loadingDrivers = false;
  bool _driversLoadFailed = false;
  bool _maintenanceLoadFailed = false;
  bool _documentsLoadFailed = false;
  bool _makeCatalogRequested = false;
  List<Etat> _vehicleStates = [];
  List<FicheReception> _receptionSheets = [];
  int _selectedSectionIndex = 0;
  int _vehicleLoadGeneration = 0;
  final ScrollController _contentScrollController = ScrollController();
  Vehicle get v => widget.vehicle;
  bool _matchesVehicleDocument(DocumentVehicle document) {
    final linkedVehicleId = document.vehicle?.trim();
    return linkedVehicleId == v.id ||
        VehicleDetailFormatters.sameRegistration(
          document.vehiclemat,
          v.matricule,
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDocuments();
    _loadVehicleMakeCatalog();
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDrivers();
    });
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
    _requestedDrivers = false;
    _loadingDrivers = false;
    _driversLoadFailed = false;
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
      _loadDrivers();
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

      if (force || !VehicleProvider.downloadedDocuments) {
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
        _loadDrivers();
        break;
      case 3:
        _loadDrivers();
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
      case 8:
        break;
    }
  }

  String val(String? s) =>
      s == null || s.trim().isEmpty ? 'vehicle_not_provided'.tr() : s.trim();
  String n(num? x, [String suffix = '']) => x == null
      ? 'vehicle_not_provided'.tr()
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

  String? _wilayaName(int? code) => VehicleDetailFormatters.wilayaName(
        code,
        languageCode: context.locale.languageCode,
      );

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
          _header(accent, model.isEmpty ? 'vehicle_details_title'.tr() : model),
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
    final sections = <({String label, IconData icon})>[
      (label: 'vehicle_details_overview'.tr(), icon: FluentIcons.view_dashboard),
      (label: 'vehicle_details_identification'.tr(), icon: FluentIcons.info),
      (label: 'vehicle_details_characteristics'.tr(), icon: FluentIcons.settings),
      (label: 'vehicle_details_assignment'.tr(), icon: FluentIcons.account_management),
      (label: 'vehicle_details_location'.tr(), icon: FluentIcons.car),
      (label: 'documents'.tr(), icon: FluentIcons.document_set),
      (label: 'vehicle_details_maintenance'.tr(), icon: FluentIcons.repair),
      (label: 'vehicle_details_history'.tr(), icon: FluentIcons.document),
      (label: 'vehicle_details_acquisition'.tr(), icon: FluentIcons.shopping_cart),
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
                'vehicle_details_kicker'.tr(),
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
                model.isEmpty ? 'vehicle_details_model_missing'.tr() : model,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.back, size: 13),
                    SizedBox(width: 7),
                    Text('vehicle_details_back_to_fleet'.tr()),
                  ],
                ),
              ),
            if (widget.onEdit != null)
              FilledButton(
                onPressed: widget.onEdit,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.edit, size: 14),
                    SizedBox(width: 7),
                    Text('mod'.tr()),
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
    if (value == null) return 'vehicle_not_provided'.tr();
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

  Future<void> _loadDrivers({bool force = false}) async {
    if (_loadingDrivers || (_requestedDrivers && !force)) return;
    _requestedDrivers = true;
    _loadingDrivers = true;
    _driversLoadFailed = false;
    final generation = _vehicleLoadGeneration;
    setState(() {});

    try {
      final provider = context.read<DriverProvider>();
      if (DriverProvider.downloadingConducteurs) {
        await _waitForLoading(
          () => DriverProvider.downloadingConducteurs,
          'drivers',
        );
      }
      if (!mounted || generation != _vehicleLoadGeneration) return;

      if (!DriverProvider.downloadedConducteurs) {
        await provider.refreshConducteurs();
      }
      if (!mounted || generation != _vehicleLoadGeneration) return;
      if (!DriverProvider.downloadedConducteurs) {
        throw StateError('Drivers could not be loaded for the active company.');
      }

      setState(() {
        _loadingDrivers = false;
        _driversLoadFailed = false;
      });
    } catch (error) {
      if (!mounted || generation != _vehicleLoadGeneration) return;
      debugPrint('[Vehicle details] driver lookup failed: $error');
      setState(() {
        _loadingDrivers = false;
        _driversLoadFailed = true;
      });
      _requestedDrivers = false;
    }
  }

  String? _resolveOrganisationLabel(
    String? rawValue,
    String Function(String?) resolver,
  ) {
    final raw = rawValue?.trim() ?? '';
    if (raw.isEmpty) return null;

    final activeCompanyId = DatabaseGetter.activeCompanyId;
    final companyProfile = MyEntrepriseState.p;
    if (activeCompanyId == null ||
        companyProfile == null ||
        companyProfile.id != activeCompanyId) {
      return raw;
    }

    try {
      final resolved = resolver(raw).trim();
      return resolved.isNotEmpty ? resolved : raw;
    } catch (error) {
      // Company parameters can be unavailable during initial tenant bootstrap.
      debugPrint('[Vehicle details] organisation label resolution failed: $error');
      return raw;
    }
  }

  List<Conducteur> _driversMatchingVehicleRegistration() {
    if (VehicleDetailFormatters.normalizeRegistration(
      v.matriculeConducteur,
    ).isEmpty) {
      return const [];
    }

    return DriverProvider.conducteurs.values
        .where(
          (driver) => VehicleDetailFormatters.sameRegistration(
            driver.matricule,
            v.matriculeConducteur,
          ),
        )
        .toList(growable: false);
  }

  Widget _assignmentSection(Color accent) {
    final driverRegistration = v.matriculeConducteur?.trim() ?? '';
    final matchingDrivers = _driversMatchingVehicleRegistration();

    return _section(
      'vehicle_assignment_title'.tr(),
      'vehicle_assignment_description'.tr(),
      [
        _panel('vehicle_details_assigned_driver'.tr(), FluentIcons.people, accent, [
          if (driverRegistration.isEmpty)
            _emptyInline('vehicle_assignment_no_driver_registration'.tr())
          else ...[
            _statusValue('vehicle_assignment_registration_label'.tr(), driverRegistration, accent),
            const SizedBox(height: 10),
            if (_loadingDrivers && matchingDrivers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: ProgressRing(),
                ),
              )
            else if (_driversLoadFailed)
              _retryNotice(
                'vehicle_assignment_verify_failed'.tr(),
                () => _loadDrivers(force: true),
              )
            else if (!DriverProvider.downloadedConducteurs)
              _emptyInline('vehicle_assignment_driver_directory_unavailable'.tr())
            else if (matchingDrivers.length == 1) ...[
              if (matchingDrivers.single.getName().trim().isNotEmpty)
                _statusValue(
                  'chauffeur'.tr(),
                  matchingDrivers.single.getName().trim(),
                  accent,
                )
              else
                _emptyInline(
                  'vehicle_assignment_driver_name_missing'.tr(),
                ),
              const SizedBox(height: 8),
              _statusValue(
                'vehicle_assignment_driver_status'.tr(),
                DriverProvider.getEtat(matchingDrivers.single.etat).tr(),
                accent,
              ),
            ]
            else if (matchingDrivers.isEmpty)
              _emptyInline(
                'vehicle_assignment_no_match'.tr()
                'vehicle_assignment_historical_note'.tr(),
              )
            else
              _emptyInline(
                'vehicle_assignment_multiple_matches'.tr()
                'vehicle_assignment_ambiguous_name_hidden'.tr(),
              ),
          ],
        ]),
        _group('vehicle_assignment_organization_group'.tr(), [
          _field(
            'appartenance'.tr(),
            _resolveOrganisationLabel(
              v.appartenance,
              VehiclesUtilities.getAppartenance,
            ),
          ),
          _field(
            'filiale'.tr(),
            _resolveOrganisationLabel(
              v.filliale,
              VehiclesUtilities.getAppartenance,
            ),
          ),
          _field(
            'vehicle_field_direction'.tr(),
            _resolveOrganisationLabel(
              v.direction,
              VehiclesUtilities.getDirection,
            ),
          ),
          _field(
            'departement'.tr(),
            _resolveOrganisationLabel(
              v.departement,
              VehiclesUtilities.getDepartment,
            ),
          ),
          _field(
            'vehicle_field_perimeter'.tr(),
            VehiclesUtilities.getPerimetre(v.perimetre).tr(),
          ),
          _field(
            'vehicle_assignment_driver_belonging_legacy'.tr(),
            _resolveOrganisationLabel(
              v.appartenanceconducteur,
              VehiclesUtilities.getAppartenance,
            ),
          ),
        ]),
        _group('vehicle_details_status_usage'.tr(), [
          _field(
            'vehicle_details_operational_status'.tr(),
            v.etatactuel == null
                ? null
                : VehiclesUtilities.getEtatName(v.etatactuel!).tr(),
          ),
          _field(
            'Type d’usage',
            v.service
                ? 'vehicle_service_use'.tr()
                : 'vehicle_function_use'.tr(),
          ),
        ]),
      ],
    );
  }

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
          VehicleDetailFormatters.sameRegistration(
            state.vehicleMat,
            registration,
          )).toList()
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

      final sheets = RepairProvider.repPerVeh.entries
          .where((entry) =>
              entry.key == v.id ||
              VehicleDetailFormatters.sameRegistration(
                entry.key,
                registration,
              ))
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
          'vehicle_details_identification'.tr(),
          'vehicle_identification_description'.tr(),
          [
            _group('vehicle_identification_group'.tr(), [
              _field('vehicle_field_primary_registration'.tr(), v.matricule),
              _field('vehicle_field_registration_country'.tr(), _countryName(v.pays)),
              _field(
                'vehicle_field_foreign_registration'.tr(),
                v.matriculeEtrang ? 'oui'.tr() : 'non'.tr(),
              ),
              _field(
                'vehicle_field_previous_registrations'.tr(),
                v.matriculePrec?.join(', '),
              ),
              _field('vehicle_field_vin'.tr(), v.numeroSerie),
            ]),
            _group('vehicle_registration_document_group'.tr(), [
              _field('vehicle_field_recorded_date'.tr(), _date(v.date)),
              _field('vehicle_field_document_reference'.tr(), v.numero),
              _field(
                'vehicle_field_receipt_amount'.tr(),
                v.quittance == null
                    ? null
                    : VehicleDetailFormatters.formatNumber(v.quittance!),
              ),
            ]),
            _group('vehicle_administrative_address_group'.tr(), [
              _field('Wilaya', _wilayaName(v.wilaya)),
              _field('daira'.tr(), v.daira),
              _field('Commune', v.commune),
              _field('Adresse', v.adresse),
            ]),
            _group('vehicle_registration_holder_group'.tr(), [
              _field('Nom', v.nom),
              _field('Prénom', v.prenom),
              _field('Profession', v.profession),
            ]),
          ],
        );
      case 2:
        return _section(
          'vehicle_characteristics_title'.tr(),
          'vehicle_characteristics_description'.tr(),
          [
            _group('vehicle_characteristics_identity_group'.tr(), [
              _field(
                'Marque',
                VehicleMakeService.nameFor(
                  VehicleMakeService.canonicalId(v.marque),
                ),
              ),
              _field('vehicle_field_model_type'.tr(), v.type),
              _field('vehicle_field_trim'.tr(), v.trim),
              _field('vehicle_field_model_year'.tr(), v.modelYear?.toString()),
              _field(
                'vehicle_field_legacy_usage_year'.tr(),
                v.anneeUtil?.toString(),
              ),
              _field(
                'vehicle_field_administrative_genre'.tr(),
                VehicleDetailFormatters.genreLabel(v.genre)?.tr(),
              ),
              _field('vehicle_field_body_type'.tr(), v.carrosserie),
              _field(
                'vehicle_field_paint_color'.tr(),
                VehicleDetailFormatters.paintLabel(v.color),
              ),
            ]),
            _group('vehicle_characteristics_engine_group'.tr(), [
              _field('Énergie', v.energie),
              _field(
                'vehicle_field_engine_displacement'.tr(),
                v.engineDisplacement == null
                    ? null
                    : '${VehicleDetailFormatters.formatNumber(v.engineDisplacement!)} cm³',
              ),
              _field(
                'vehicle_field_fiscal_power'.tr(),
                v.puissance == null ? null : '${v.puissance} CV',
              ),
              _field(
                'vehicle_field_engine_power_hp'.tr(),
                v.enginePowerHp == null ? null : '${v.enginePowerHp} ch',
              ),
              _field(
                'vehicle_field_engine_power_kw'.tr(),
                v.enginePowerKw == null ? null : '${v.enginePowerKw} kW',
              ),
              _field('vehicle_field_engine_code'.tr(), v.engineCode),
            ]),
            _group('vehicle_characteristics_transmission_group'.tr(), [
              _field('vehicle_characteristics_transmission_group'.tr(), v.transmission),
              _field('vehicle_field_gearbox'.tr(), v.gearbox),
              _field('vehicle_field_drive_type'.tr(), v.driveType),
            ]),
            _group('vehicle_characteristics_dimensions_group'.tr(), [
              _field('vehicle_field_door_count'.tr(), v.doors?.toString()),
              _field('vehicle_field_seating_capacity'.tr(), v.placesAssises?.toString()),
              _field(
                'vehicle_field_total_weight'.tr(),
                v.poidsTotal == null ? null : '${v.poidsTotal} kg',
              ),
              _field(
                'vehicle_field_payload'.tr(),
                v.charegeUtile == null ? null : '${v.charegeUtile} kg',
              ),
              _field(
                'vehicle_field_length'.tr(),
                v.lengthMm == null ? null : '${v.lengthMm} mm',
              ),
              _field(
                'vehicle_field_width'.tr(),
                v.widthMm == null ? null : '${v.widthMm} mm',
              ),
              _field(
                'vehicle_field_height'.tr(),
                v.heightMm == null ? null : '${v.heightMm} mm',
              ),
              _field(
                'vehicle_field_heavy_vehicle_legacy'.tr(),
                v.lourd ? 'oui'.tr() : null,
              ),
            ]),
          ],
        );
      case 3:
        return _assignmentSection(accent);
      case 4:
        return _gpsParkingSection(accent);
      case 5:
        return _documentsSection(accent);
      case 6:
        return _maintenanceSection(accent);
      case 7:
        return _historySection(accent);
      case 8:
        return _section(
          'vehicle_acquisition_title'.tr(),
          'vehicle_acquisition_description'.tr(),
          [
            _group('vehicle_details_acquisition'.tr(), [
              _field('vehicle_acquisition_mode'.tr(), v.acquisitionType),
              _field('Date', _date(v.acquisitionDate)),
              _field(
                'vehicle_acquisition_purchase_price'.tr(),
                v.purchasePrice == null
                    ? null
                    : '${VehicleDetailFormatters.formatNumber(v.purchasePrice!)} DA',
              ),
              _field('Fournisseur', v.supplier),
              _field('vehicle_acquisition_warranty_end'.tr(), _date(v.warrantyEndDate)),
              _field('vehicle_acquisition_fleet_number'.tr(), v.fleetNumber),
            ]),
            _group('vehicle_record_metadata_group'.tr(), [
              _field('vehicle_record_created_at'.tr(), _date(v.createdAt)),
              _field('vehicle_record_updated_at'.tr(), _date(v.updatedAt)),
            ]),
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
          'vehicle_location_parking_title'.tr(),
          'vehicle_location_parking_description'.tr(),
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
                    'vehicle_gps_tracking_title'.tr(),
                    FluentIcons.car,
                    accent,
                    [
                      _statusValue(
                        'vehicle_gps_last_position_received'.tr(),
                        'vehicle_gps_no_data'.tr(),
                        accent,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'vehicle_gps_unconnected_source'.tr(),
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
                    'vehicle_parking_title'.tr(),
                    FluentIcons.car,
                    accent,
                    [
                      _statusValue(
                        'vehicle_parking_legacy_location'.tr(),
                        val(v.emplacement),
                        accent,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'vehicle_parking_legacy_warning'.tr(),
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
    final driversForVehicle = _driversMatchingVehicleRegistration();
    final assignedDriverName = driversForVehicle.length == 1
        ? driversForVehicle.single.getName().trim()
        : null;
    final makeName = VehicleMakeService.nameFor(VehicleMakeService.canonicalId(v.marque));
    final currentStatus = v.etatactuel == null
        ? 'vehicle_not_provided'.tr()
        : VehiclesUtilities.getEtatName(v.etatactuel!).tr();

    final identityFields = <_VehicleField>[
      _field('Immatriculation', v.matricule),
      _field('Marque', makeName),
      _field('Modèle', v.type),
      _field('vehicle_field_model_year'.tr(), v.modelYear?.toString()),
      _field('vehicle_field_vin'.tr(), v.numeroSerie),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'vehicle_details_overview'.tr(),
          'vehicle_details_overview_description'.tr(),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= ParcotoTokens.tabletBreakpoint;
            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _group('vehicle_details_vehicle_identity'.tr(), identityFields),
                _sectionShortcut('vehicle_details_show_identification'.tr(), 1),
                _group('vehicle_details_known_assignment'.tr(), [
                  _field('vehicle_details_driver_registration'.tr(), v.matriculeConducteur),
                  _field('vehicle_details_assigned_driver'.tr(), assignedDriverName),
                  _field(
                    'Filiale',
                    _resolveOrganisationLabel(
                      v.filliale,
                      VehiclesUtilities.getAppartenance,
                    ),
                  ),
                  _field(
                    'Direction',
                    _resolveOrganisationLabel(
                      v.direction,
                      VehiclesUtilities.getDirection,
                    ),
                  ),
                  _field(
                    'Département',
                    _resolveOrganisationLabel(
                      v.departement,
                      VehiclesUtilities.getDepartment,
                    ),
                  ),
                  // Emplacement legacy is shown only in Localisation.
                ]),
                _sectionShortcut('vehicle_details_show_assignment'.tr(), 3),
              ],
            );
            final right = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _panel(
                  'vehicle_details_status_usage'.tr(),
                  FluentIcons.info,
                  accent,
                  [
                    _statusValue('vehicle_details_operational_status'.tr(), currentStatus, accent),
                    const SizedBox(height: 12),
                    _statusValue(
                      'Type d’usage',
                      v.service ? 'vehicle_service_use'.tr() : 'vehicle_function_use'.tr(),
                      accent,
                    ),
                    _sectionShortcut('vehicle_details_show_assignment'.tr(), 3),
                  ],
                ),
                _panel(
                  'documents'.tr(),
                  FluentIcons.document,
                  accent,
                  [
                    Row(
                      children: [
                        Expanded(
                          child: _statusValue(
                            'vehicle_details_registered_documents'.tr(),
                            documentsCountValue,
                            accent,
                          ),
                        ),
                        Expanded(
                          child: _statusValue(
                            'vehicle_details_with_deadline'.tr(),
                            documentsDeadlineValue,
                            accent,
                          ),
                        ),
                      ],
                    ),
                    if (_documentsLoadFailed)
                      _retryNotice(
                        'vehicle_details_documents_unverified'.tr(),
                        () => _loadDocuments(force: true),
                      ),
                    const SizedBox(height: 9),
                    Text(
                      'vehicle_details_documents_info'.tr(),
                      style: TextStyle(
                        color: Colors.grey[100],
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    _sectionShortcut('vehicle_details_show_documents'.tr(), 5),
                  ],
                ),
                _panel(
                  'vehicle_details_recorded_mileage'.tr(),
                  FluentIcons.car,
                  accent,
                  [
                    _statusValue(
                      'vehicle_details_recorded_value'.tr(),
                      n(v.currentMileage, ' km'),
                      accent,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'vehicle_details_mileage_source_missing'.tr(),
                      style: TextStyle(
                        color: Colors.grey[100],
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    if (v.nextServiceMileage != null) ...[
                      const SizedBox(height: 9),
                      _statusValue(
                        'vehicle_details_next_service'.tr(),
                        n(v.nextServiceMileage, ' km'),
                        accent,
                      ),
                    ],
                    _sectionShortcut('vehicle_details_show_maintenance'.tr(), 6),
                  ],
                ),
                _panel(
                  'vehicle_details_location'.tr(),
                  FluentIcons.car,
                  accent,
                  [
                    _statusValue(
                      'vehicle_details_last_position'.tr(),
                      'vehicle_details_no_gps_position'.tr(),
                      accent,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'vehicle_details_no_gps_source'.tr(),
                      style: TextStyle(
                        color: Colors.grey[100],
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    _sectionShortcut('vehicle_details_show_location'.tr(), 4),
                  ],
                ),
                _panel(
                  'vehicle_details_recent_activity'.tr(),
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
                        'vehicle_details_recent_activity_failed'.tr(),
                        _loadHistory,
                      )
                    else if (latestActivity == null)
                      _emptyInline('vehicle_details_no_recent_event'.tr())
                    else ...[
                      _statusValue(
                        'vehicle_details_last_change'.tr(),
                        VehiclesUtilities.getEtatName(latestActivity.type).tr(),
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
                    _sectionShortcut('vehicle_details_show_full_history'.tr(), 7),
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
                      Text(
                        VehiclesUtilities.getEtatName(state.type).tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_date(state.date ?? state.updatedAt ?? state.createdAt)}'
                        '${state.ordreNum == null ? '' : ' • Ordre #${state.ordreNum}'}',
                        style: TextStyle(color: Colors.grey[100], fontSize: 11)),
                      if (state.type == 2 &&
                          state.valeur != null &&
                          state.valeur! > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Montant de réparation : ${VehicleDetailFormatters.formatNumber(state.valeur!)} DA',
                            style: TextStyle(
                              color: Colors.grey[100],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      if (state.remarque?.trim().isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            state.remarque!,
                            style: const TextStyle(fontSize: 12),
                          ),
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
        VehicleDetailFormatters.sameRegistration(
          repair.vehiculemat,
          v.matricule,
        ) ||
        repair.vehicule == v.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final sheets = _receptionSheets;
    final recordedCosts = sheets
        .where((sheet) => sheet.reparationCost != null)
        .map((sheet) => sheet.reparationCost!)
        .toList(growable: false);
    final totalCost = recordedCosts.fold<double>(0, (sum, value) => sum + value);
    final costLabel = recordedCosts.isEmpty
        ? 'vehicle_not_provided'.tr()
        : '${VehicleDetailFormatters.formatNumber(totalCost)} DA';

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
                costLabel, accent),
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

  Widget _repairRow(Reparation repair, Color accent) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 460;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ordre #${repair.numero}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_date(repair.date)} • ${repair.prestatairenom ?? 'Prestataire non renseigné'}',
                style: TextStyle(color: Colors.grey[100], fontSize: 11),
              ),
              if (repair.remarque?.trim().isNotEmpty == true)
                Text(
                  repair.remarque!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[100], fontSize: 11),
                ),
            ],
          );
          final statusColor = repair.etat == 2
              ? Colors.green
              : repair.etat == 1
                  ? accent
                  : repair.etat == null || repair.etat == 0
                      ? Colors.orange
                      : Colors.grey[100];
          final status = _chip(
            VehicleDetailFormatters.repairStatusKey(repair.etat).tr(),
            statusColor,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(FluentIcons.repair, color: accent, size: 17),
                          const SizedBox(width: 10),
                          Expanded(child: details),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: status,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(FluentIcons.repair, color: accent, size: 17),
                      const SizedBox(width: 10),
                      Expanded(child: details),
                      const SizedBox(width: 10),
                      status,
                    ],
                  ),
          );
        },
      );

  Widget _receptionRow(FicheReception sheet, Color accent) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 460;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fiche de réception #${sheet.numero}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Entrée : ${_date(sheet.dateEntre)}'
                '${sheet.dateSortie == null ? ' • Toujours ouverte' : ' • Sortie : ${_date(sheet.dateSortie)}'}',
                style: TextStyle(color: Colors.grey[100], fontSize: 11),
              ),
              if (sheet.kilometrage != null)
                Text(
                  'Kilométrage : ${sheet.kilometrage} km',
                  style: TextStyle(color: Colors.grey[100], fontSize: 11),
                ),
              if (sheet.remarque?.trim().isNotEmpty == true)
                Text(
                  sheet.remarque!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[100], fontSize: 11),
                ),
            ],
          );
          final cost = sheet.reparationCost == null
              ? null
              : Text(
                  '${VehicleDetailFormatters.formatNumber(sheet.reparationCost!)} DA',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );

          return Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(FluentIcons.document, color: accent, size: 17),
                          const SizedBox(width: 10),
                          Expanded(child: details),
                        ],
                      ),
                      if (cost != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: cost,
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Icon(FluentIcons.document, color: accent, size: 17),
                      const SizedBox(width: 10),
                      Expanded(child: details),
                      if (cost != null) ...[
                        const SizedBox(width: 10),
                        cost,
                      ],
                    ],
                  ),
          );
        },
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
                    'vehicle_details_registered_documents'.tr(),
                    documents.length.toString(),
                    FluentIcons.document,
                    accent,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _documentSummary(
                    'vehicle_details_with_deadline'.tr(),
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
    final statusColor = expiration == null
        ? Colors.grey[100]
        : expired
            ? Colors.red
            : daysRemaining != null && daysRemaining <= 30
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final leading = Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(FluentIcons.document, color: accent, size: 19),
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.nom.trim().isEmpty
                    ? 'Document sans nom'
                    : document.nom,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                expiration == null
                    ? 'Date d’expiration non renseignée'
                    : 'Expiration : ${_date(expiration)}',
                style: TextStyle(color: Colors.grey[100], fontSize: 11),
              ),
            ],
          );
          final statusBadge = _chip(status, statusColor);

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leading,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: statusBadge,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(child: details),
              const SizedBox(width: 10),
              statusBadge,
            ],
          );
        },
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
  bool get hasValue => value != 'vehicle_not_provided'.tr();
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
