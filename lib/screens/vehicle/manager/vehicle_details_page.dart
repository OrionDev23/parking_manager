import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/serializables/vehicle/vehicle.dart';
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
  Vehicle get v => widget.vehicle;
  static const sections = [
    ('Vue d’ensemble', FluentIcons.car),
    ('Identification', FluentIcons.people),
    ('Caractéristiques', FluentIcons.car),
    ('Affectation', FluentIcons.people),
    ('GPS & localisation', FluentIcons.car),
    ('Maintenance', FluentIcons.repair),
    ('Documents', FluentIcons.document),
    ('Historique', FluentIcons.document),
    ('Finances', FluentIcons.money),
  ];
  String val(String? s) => s == null || s.trim().isEmpty ? 'Non renseigné' : s.trim();
  String n(num? x, [String suffix = '']) => x == null ? 'Non renseigné' : '$x$suffix';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppTheme>();
    final accent = FluentTheme.of(context).accentColor;
    final model = [val(v.marque), val(v.type), v.modelYear?.toString() ?? '']
        .where((e) => e != 'Non renseigné' && e.isNotEmpty).join(' ');
    return Container(color: app.backGroundColor, child: Column(children: [
      _header(accent, model.isEmpty ? 'Fiche véhicule' : model),
      _navigation(accent),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28), child: _content(accent))),
    ]));
  }

  Widget _header(Color accent, String model) => Container(
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[30]))),
    child: Row(children: [
      _vehicleAvatar(accent),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(v.matricule, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4), Text(model, style: TextStyle(color: Colors.grey[100], fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          _chip(val(v.etat), accent),
          if (v.fleetNumber?.isNotEmpty == true) _chip('Flotte ${v.fleetNumber!}', accent),
          if (v.service) _chip('Véhicule de service', accent),
        ]),
      ])),
      if (widget.onEdit != null) Button(onPressed: widget.onEdit, child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(FluentIcons.edit, size: 14), SizedBox(width: 7), Text('Modifier'),
      ])),
    ]),
  );

  Widget _vehicleAvatar(Color accent) {
    final imageUrl = v.imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 76,
        height: 76,
        color: accent.withValues(alpha: .10),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(FluentIcons.car, size: 34, color: accent),
              )
            : Icon(FluentIcons.car, size: 34, color: accent),
      ),
    );
  }

  String _date(Object? value) {
    if (value == null) return 'Non renseigné';
    final date = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return day + '/' + month + '/' + date.year.toString();
  }

  Widget _chip(String text, Color accent) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: accent.withValues(alpha: .10), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)));

  Widget _navigation(Color accent) => Container(
    height: 58, padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[30]))),
    child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(width: 5),
      itemBuilder: (context, i) {
        final active = selected == i;
        return Button(
          style: ButtonStyle(
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            backgroundColor: WidgetStateProperty.all(active ? accent.withValues(alpha: .12) : Colors.transparent),
            foregroundColor: WidgetStateProperty.all(active ? accent : null)),
          onPressed: () => setState(() => selected = i),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(sections[i].$2, size: 14), const SizedBox(width: 7),
            Text(sections[i].$1, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          ]));
      }));

  Widget _content(Color accent) {
    switch (selected) {
      case 0: return _overview(accent);
      case 1: return _section('Identification', 'Identité administrative et informations principales', [
        _group('Immatriculation', [
          _field('Immatriculation', v.matricule), _field('Anciennes immatriculations', v.matriculePrec?.join(', ')),
          _field('Pays', v.pays), _field('Date carte grise', _date(v.date)),
          _field('Numéro carte grise', v.numero), _field('Numéro de série / VIN', v.numeroSerie)]),
        _group('Identité du véhicule', [
          _field('Marque', v.marque), _field('Modèle / type', v.type), _field('Finition', v.trim),
          _field('Année modèle', v.modelYear?.toString()), _field('Mise en circulation', v.anneeUtil?.toString()),
          _field('Couleur', v.color), _field('Carrosserie', v.carrosserie)]),
        _group('Adresse administrative', [
          _field('Wilaya', v.wilaya?.toString()), _field('Daïra', v.daira),
          _field('Commune', v.commune), _field('Adresse', v.adresse)]),
      ]);
      case 2: return _section('Caractéristiques techniques', 'Motorisation, transmission, dimensions et capacités', [
        _group('Motorisation', [
          _field('Énergie', v.energie), _field('Puissance', v.puissance == null ? null : '${v.puissance} ch'),
          _field('Cylindrée', v.engineDisplacement == null ? null : '${v.engineDisplacement} cm³'),
          _field('Code moteur', v.engineCode)]),
        _group('Transmission', [
          _field('Transmission', v.transmission), _field('Boîte', v.gearbox), _field('Roues motrices', v.driveType)]),
        _group('Dimensions & capacité', [
          _field('Portes', v.doors?.toString()), _field('Places', v.placesAssises?.toString()),
          _field('Poids total', v.poidsTotal == null ? null : '${v.poidsTotal} kg'),
          _field('Charge utile', v.charegeUtile == null ? null : '${v.charegeUtile} kg'),
          _field('Longueur', v.lengthMm == null ? null : '${v.lengthMm} mm'),
          _field('Largeur', v.widthMm == null ? null : '${v.widthMm} mm'),
          _field('Hauteur', v.heightMm == null ? null : '${v.heightMm} mm')]),
      ]);
      case 3: return _section('Affectation & organisation', 'Rattachement administratif et conducteur associé', [
        _group('Organisation', [
          _field('Appartenance', v.appartenance), _field('Filiale', v.filliale),
          _field('Direction', v.direction), _field('Département', v.departement),
          _field('Périmètre', v.perimetre.toString()), _field('Emplacement', v.emplacement)]),
        _group('Propriétaire', [
          _field('Nom', v.nom), _field('Prénom', v.prenom), _field('Profession', v.profession)]),
        _group('Conducteur', [
          _field('Matricule conducteur', v.matriculeConducteur),
          _field('Appartenance conducteur', v.appartenanceconducteur)]),
      ]);
      case 4: return _empty(FluentIcons.car, 'Aucune position GPS disponible',
        'La dernière position apparaîtra ici lorsqu’un conducteur autorisé aura transmis sa position depuis Parcoto Mobile.',
        'Suivi GPS non encore activé');
      case 5: return _empty(FluentIcons.repair, 'Aucune donnée de maintenance structurée',
        'Les entretiens, interventions, ordres de réparation et prochaines échéances seront regroupés ici.',
        'Module maintenance à connecter');
      case 6: return _empty(FluentIcons.document, 'Aucun document affiché',
        'Les cartes grises, assurances, contrôles techniques, factures et autres pièces seront accessibles ici.',
        'Gestion documentaire à connecter');
      case 7: return _empty(FluentIcons.document, 'Historique détaillé indisponible',
        'Les changements d’affectation, de statut, relevés kilométriques et événements seront présentés chronologiquement.',
        'Historique véhicule à structurer');
      default: return _section('Finances & cycle de vie', 'Acquisition, garantie et suivi kilométrique', [
        _group('Acquisition', [
          _field('Mode', v.acquisitionType), _field('Date', _date(v.acquisitionDate)),
          _field('Prix d’achat', v.purchasePrice == null ? null : '${v.purchasePrice} DA'),
          _field('Fournisseur', v.supplier), _field('Fin de garantie', _date(v.warrantyEndDate))]),
        _group('Kilométrage', [
          _field('Kilométrage actuel', v.currentMileage == null ? null : '${v.currentMileage} km'),
          _field('Prochaine révision', v.nextServiceMileage == null ? null : '${v.nextServiceMileage} km')]),
      ]);
    }
  }

  Widget _overview(Color accent) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _heading('Vue d’ensemble', 'Les informations essentielles de ce véhicule'),
    LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 900 ? 4 : c.maxWidth > 560 ? 2 : 1;
      final w = (c.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        _metric(w, FluentIcons.car, 'Kilométrage', n(v.currentMileage, ' km'), accent),
        _metric(w, FluentIcons.people, 'Conducteur', val(v.matriculeConducteur), accent),
        _metric(w, FluentIcons.car, 'Localisation', val(v.commune), accent),
        _metric(w, FluentIcons.repair, 'Prochaine révision', n(v.nextServiceMileage, ' km'), accent),
      ]);
    }),
    const SizedBox(height: 18),
    _group('Profil du véhicule', [
      _field('Marque', v.marque), _field('Modèle', v.type),
      _field('Année', v.modelYear?.toString() ?? v.anneeUtil?.toString()),
      _field('Énergie', v.energie), _field('Numéro de série', v.numeroSerie), _field('Couleur', v.color)]),
    _group('Affectation actuelle', [
      _field('Filiale', v.filliale), _field('Direction', v.direction),
      _field('Département', v.departement),
      _field('Conducteur', [v.prenom, v.nom].where((e) => e?.isNotEmpty == true).join(' '))]),
    _group('Informations complémentaires', [
      _field('Date de création', _date(v.createdAt)),
      _field('Dernière modification', _date(v.updatedAt)),
      _field('Numéro de flotte', v.fleetNumber), _field('État administratif', v.etat)]),
  ]);

  Widget _section(String title, String desc, List<Widget> groups) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_heading(title, desc), ...groups]);

  Widget _heading(String title, String desc) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4), Text(desc, style: TextStyle(color: Colors.grey[100], fontSize: 12))]));

  Widget _group(String title, List<_VehicleField> fields) {
    final visible = fields.where((f) => f.hasValue).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: FluentTheme.of(context).micaBackgroundColor,
        border: Border.all(color: Colors.grey[30]), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 720 ? 3 : c.maxWidth > 430 ? 2 : 1;
          final w = (c.maxWidth - (cols - 1) * 18) / cols;
          return Wrap(spacing: 18, runSpacing: 16,
            children: visible.map((f) => SizedBox(width: w, child: f)).toList());
        }),
      ]));
  }

  _VehicleField _field(String label, String? raw) => _VehicleField(label, val(raw));

  Widget _metric(double width, IconData icon, String label, String data, Color accent) => Container(
    width: width, padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(border: Border.all(color: Colors.grey[30]), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(icon, color: accent, size: 20), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.grey[100], fontSize: 11)),
        const SizedBox(height: 5), Text(data, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))]))]));

  Widget _empty(IconData icon, String title, String desc, String status) => Center(
    child: Container(constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(children: [
        Icon(icon, size: 38, color: Colors.grey[100]), const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8), Text(desc, textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[100], height: 1.5)),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: Colors.grey[20], borderRadius: BorderRadius.circular(20)),
          child: Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
      ])));
}

class _VehicleField extends StatelessWidget {
  final String label;
  final String value;
  const _VehicleField(this.label, this.value);
  bool get hasValue => value != 'Non renseigné';
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(color: Colors.grey[100], fontSize: 11)),
    const SizedBox(height: 5), Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
  ]);
}
