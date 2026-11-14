import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/serializables/vehicle/vehicle.dart';
import 'package:parc_oto/serializables/vehicle/document_vehicle.dart';
import 'package:parc_oto/providers/vehicle_provider.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';

class VehicleDetailsPage extends StatefulWidget {
  final Vehicle vehicle;
  final VoidCallback? onEdit;
  const VehicleDetailsPage({super.key, required this.vehicle, this.onEdit});
  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  int selected = 0;
  bool _requestedDocuments = false;
  Vehicle get v => widget.vehicle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requestedDocuments) {
      _requestedDocuments = true;
      final provider = context.read<VehicleProvider>();
      if (!VehicleProvider.downloadedDocuments &&
          !VehicleProvider.downloadingDocuments) {
        provider.refreshDocuments();
      }
    }
  }

  static const sections = [
    ('Vue générale', FluentIcons.car),
    ('Identification', FluentIcons.people),
    ('Spécifications', FluentIcons.car),
    ('Affectation', FluentIcons.people),
    ('GPS', FluentIcons.car),
    ('Maintenance', FluentIcons.repair),
    ('Documents', FluentIcons.document),
    ('Historique', FluentIcons.document),
    ('Finances', FluentIcons.money),
  ];

  String val(String? s) =>
      s == null || s.trim().isEmpty ? 'Non renseigné' : s.trim();
  String n(num? x, [String suffix = '']) =>
      x == null ? 'Non renseigné' : '$x$suffix';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppTheme>();
    final accent = FluentTheme.of(context).accentColor;
    final model = [val(v.marque), val(v.type), v.modelYear?.toString() ?? '']
        .where((e) => e != 'Non renseigné' && e.isNotEmpty)
        .join(' ');
    return Container(
      color: app.backGroundColor,
      child: Column(
        children: [
          _header(accent, model.isEmpty ? 'Fiche véhicule' : model),
          _navigation(accent),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
              child: _content(accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(Color accent, String model) => Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
        decoration: BoxDecoration(
          color: FluentTheme.of(context).micaBackgroundColor,
          border: Border(bottom: BorderSide(color: Colors.grey[30])),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 650;
            final identity = Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.matricule,
                    style: const TextStyle(
                        fontSize: 23, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(model,
                      style:
                          TextStyle(color: Colors.grey[100], fontSize: 13)),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    children: [
                      _chip(val(v.etat), accent),
                      if (v.fleetNumber?.isNotEmpty == true)
                        _chip('Flotte ${v.fleetNumber!}', accent),
                      if (v.service) _chip('Véhicule de service', accent),
                    ],
                  ),
                ],
              ),
            );
            final actions = widget.onEdit == null
                ? const SizedBox.shrink()
                : Button(
                    onPressed: widget.onEdit,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.edit, size: 14),
                        SizedBox(width: 7),
                        Text('Modifier'),
                      ],
                    ),
                  );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _vehicleAvatar(accent),
                const SizedBox(width: 16),
                if (compact)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [identity, const SizedBox(height: 10), actions],
                    ),
                  )
                else ...[
                  identity,
                  const SizedBox(width: 14),
                  actions,
                ],
              ],
            );
          },
        ),
      );

  Widget _vehicleAvatar(Color accent) {
    final imageUrl = v.imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 76,
        height: 76,
        color: accent.withValues(alpha: .10),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(FluentIcons.car, size: 34, color: accent),
              )
            : Icon(FluentIcons.car, size: 34, color: accent),
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

  Widget _navigation(Color accent) => Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration:
            BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[30]))),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: sections.length,
          separatorBuilder: (_, _) => const SizedBox(width: 5),
          itemBuilder: (context, i) {
            final active = selected == i;
            return Button(
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                backgroundColor: WidgetStateProperty.all(
                    active ? accent.withValues(alpha: .12) : Colors.transparent),
                foregroundColor:
                    WidgetStateProperty.all(active ? accent : null),
              ),
              onPressed: () => setState(() => selected = i),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(sections[i].$2, size: 14),
                  const SizedBox(width: 7),
                  Text(sections[i].$1,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500)),
                ],
              ),
            );
          },
        ),
      );

  Widget _content(Color accent) {
    switch (selected) {
      case 0:
        return _overview(accent);
      case 1:
        return _section('Identification',
            'Identité administrative et informations principales', [
          _group('Immatriculation', [
            _field('Immatriculation', v.matricule),
            _field('Anciennes immatriculations', v.matriculePrec?.join(', ')),
            _field('Pays', v.pays),
            _field('Date carte grise', _date(v.date)),
            _field('Numéro carte grise', v.numero),
            _field('Numéro de série / VIN', v.numeroSerie)
          ]),
          _group('Identité du véhicule', [
            _field('Marque', v.marque),
            _field('Modèle / type', v.type),
            _field('Finition', v.trim),
            _field('Année modèle', v.modelYear?.toString()),
            _field('Mise en circulation', v.anneeUtil?.toString()),
            _field('Couleur', v.color),
            _field('Carrosserie', v.carrosserie)
          ]),
          _group('Adresse administrative', [
            _field('Wilaya', v.wilaya?.toString()),
            _field('Daïra', v.daira),
            _field('Commune', v.commune),
            _field('Adresse', v.adresse)
          ]),
        ]);
      case 2:
        return _section(
            'Spécifications techniques',
            'Motorisation, transmission, dimensions et capacités', [
          _group('Motorisation', [
            _field('Énergie', v.energie),
            _field('Puissance', v.puissance == null ? null : '${v.puissance} ch'),
            _field('Cylindrée',
                v.engineDisplacement == null ? null : '${v.engineDisplacement} cm³'),
            _field('Code moteur', v.engineCode)
          ]),
          _group('Transmission', [
            _field('Transmission', v.transmission),
            _field('Boîte', v.gearbox),
            _field('Roues motrices', v.driveType)
          ]),
          _group('Dimensions & capacité', [
            _field('Portes', v.doors?.toString()),
            _field('Places', v.placesAssises?.toString()),
            _field('Poids total',
                v.poidsTotal == null ? null : '${v.poidsTotal} kg'),
            _field('Charge utile',
                v.charegeUtile == null ? null : '${v.charegeUtile} kg'),
            _field('Longueur',
                v.lengthMm == null ? null : '${v.lengthMm} mm'),
            _field('Largeur', v.widthMm == null ? null : '${v.widthMm} mm'),
            _field('Hauteur', v.heightMm == null ? null : '${v.heightMm} mm')
          ]),
        ]);
      case 3:
        return _section(
            'Affectation & organisation',
            'Rattachement administratif et conducteur associé', [
          _group('Organisation', [
            _field('Appartenance', v.appartenance),
            _field('Filiale', v.filliale),
            _field('Direction', v.direction),
            _field('Département', v.departement),
            _field('Périmètre', v.perimetre.toString()),
            _field('Emplacement', v.emplacement)
          ]),
          _group('Propriétaire', [
            _field('Nom', v.nom),
            _field('Prénom', v.prenom),
            _field('Profession', v.profession)
          ]),
          _group('Conducteur', [
            _field('Matricule conducteur', v.matriculeConducteur),
            _field('Appartenance conducteur', v.appartenanceconducteur)
          ]),
        ]);
      case 4:
        return _empty(
            FluentIcons.car,
            'Aucune position GPS disponible',
            'La dernière position apparaîtra ici lorsqu’un conducteur autorisé aura transmis sa position depuis Parcoto Mobile.',
            'Suivi GPS non encore activé');
      case 5:
        return _empty(
            FluentIcons.repair,
            'Aucune donnée de maintenance structurée',
            'Les entretiens, interventions, ordres de réparation et prochaines échéances seront regroupés ici.',
            'Module maintenance à connecter');
      case 6:
        return _documentsSection(accent);
      case 7:
        return _empty(
            FluentIcons.document,
            'Historique détaillé indisponible',
            'Les changements d’affectation, de statut, relevés kilométriques et événements seront présentés chronologiquement.',
            'Historique véhicule à structurer');
      default:
        return _section(
            'Finances & cycle de vie',
            'Acquisition, garantie et suivi kilométrique', [
          _group('Acquisition', [
            _field('Mode', v.acquisitionType),
            _field('Date', _date(v.acquisitionDate)),
            _field('Prix d’achat',
                v.purchasePrice == null ? null : '${v.purchasePrice} DA'),
            _field('Fournisseur', v.supplier),
            _field('Fin de garantie', _date(v.warrantyEndDate))
          ]),
          _group('Kilométrage', [
            _field('Kilométrage actuel',
                v.currentMileage == null ? null : '${v.currentMileage} km'),
            _field('Prochaine révision',
                v.nextServiceMileage == null ? null : '${v.nextServiceMileage} km')
          ]),
        ]);
    }
  }

  Widget _overview(Color accent) {
    final documents = VehicleProvider.documentsVehicules.values.where((doc) =>
        doc.vehicle == v.id || doc.vehiclemat == v.matricule).toList();
    final expiring = documents.where((doc) {
      final date = doc.dateExpiration;
      if (date == null) return false;
      final today = DateTime.now();
      return !date.isBefore(DateTime(today.year, today.month, today.day));
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Vue générale',
            'Synthèse du véhicule, de son affectation et des informations de suivi'),
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;
          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _group('Informations du véhicule', [
                _field('Immatriculation', v.matricule),
                _field('Marque', v.marque),
                _field('Modèle', v.type),
                _field('Année modèle',
                    v.modelYear?.toString() ?? v.anneeUtil?.toString()),
                _field('VIN / numéro de série', v.numeroSerie),
                _field('Énergie', v.energie),
                _field('Couleur', v.color),
                _field('Catégorie', v.carrosserie),
              ]),
              _group('Affectation', [
                _field('Filiale', v.filliale),
                _field('Direction', v.direction),
                _field('Département', v.departement),
                _field('Conducteur', [
                  v.prenom,
                  v.nom
                ].where((e) => e?.trim().isNotEmpty == true).join(' ')),
                _field('Matricule conducteur', v.matriculeConducteur),
                _field('Emplacement', v.emplacement),
              ]),
              _group('Informations administratives', [
                _field('Date carte grise', _date(v.date)),
                _field('Pays', v.pays),
                _field('Wilaya', v.wilaya?.toString()),
                _field('Commune', v.commune),
                _field('Adresse', v.adresse),
              ]),
            ],
          );
          final right = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _panel(
                'État du véhicule',
                FluentIcons.info,
                accent,
                [
                  Row(
                    children: [
                      Expanded(
                          child: _statusValue('Statut', val(v.etat), accent)),
                      Expanded(
                          child: _statusValue(
                              'Type', v.service ? 'Service' : 'Flotte', accent)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _statusValue('Numéro de flotte', val(v.fleetNumber), accent),
                ],
              ),
              _panel(
                'Kilométrage & entretien',
                FluentIcons.car,
                accent,
                [
                  _statusValue('Kilométrage actuel',
                      n(v.currentMileage, ' km'), accent),
                  const SizedBox(height: 13),
                  _statusValue('Prochaine révision',
                      n(v.nextServiceMileage, ' km'), accent),
                  const SizedBox(height: 9),
                  Text(
                    'Les échéances de maintenance seront calculées à partir des relevés et interventions réellement enregistrés.',
                    style: TextStyle(
                        color: Colors.grey[100], fontSize: 11, height: 1.4),
                  ),
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
                              'Enregistrés', documents.length.toString(), accent)),
                      Expanded(
                          child: _statusValue(
                              'Avec échéance', expiring.toString(), accent)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: HyperlinkButton(
                      onPressed: () => setState(() => selected = 6),
                      child: const Text('Consulter les documents'),
                    ),
                  ),
                ],
              ),
              _panel(
                'Localisation',
                FluentIcons.car,
                accent,
                [
                  _statusValue('Dernière position', 'Non disponible', accent),
                  const SizedBox(height: 7),
                  Text(
                    'Aucune donnée GPS réelle n’est actuellement associée à ce véhicule.',
                    style: TextStyle(
                        color: Colors.grey[100], fontSize: 11, height: 1.4),
                  ),
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
        }),
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

  Widget _documentsSection(Color accent) {
    final provider = context.watch<VehicleProvider>();
    final documents = VehicleProvider.documentsVehicules.values.where((doc) {
      return doc.vehicle == v.id || doc.vehiclemat == v.matricule;
    }).toList()
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
        Row(
          children: [
            _documentSummary('Documents enregistrés', documents.length.toString(),
                FluentIcons.document, accent),
            const SizedBox(width: 12),
            _documentSummary(
                'Avec expiration',
                documents.where((d) => d.dateExpiration != null).length.toString(),
                FluentIcons.calendar,
                accent),
          ],
        ),
        const SizedBox(height: 16),
        if (documents.isEmpty)
          _empty(
            FluentIcons.document,
            'Aucun document enregistré pour ce véhicule',
            'Les documents associés à cette immatriculation apparaîtront ici dès leur création dans la gestion documentaire.',
            'Aucun document trouvé',
          )
        else
          ...documents.map((document) => _documentTile(document, accent)),
        Align(
          alignment: Alignment.centerRight,
          child: Button(
            onPressed: VehicleProvider.downloadingDocuments
                ? null
                : () => provider.refreshDocuments(),
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
          String label, String value, IconData icon, Color accent) =>
      Expanded(
        child: Container(
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
                        style:
                            TextStyle(color: Colors.grey[100], fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
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
        ? 'Aucune échéance'
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
            final cols = c.maxWidth > 720 ? 3 : c.maxWidth > 430 ? 2 : 1;
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
          Text(label,
              style: TextStyle(color: Colors.grey[100], fontSize: 11)),
          const SizedBox(height: 5),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      );
}
