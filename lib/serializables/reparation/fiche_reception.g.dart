// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fiche_reception.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FicheReception _$FicheReceptionFromJson(Map<String, dynamic> json) =>
    FicheReception(
      id: json[r'$id'] as String,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
      mobile: json['mobile'] as bool? ?? false,
      numero: (json['numero'] as num).toInt(),
      anneeUtil: (json['anneeUtil'] as num?)?.toInt(),
      couleur: json['couleur'] as String?,
      dateEntre: dateFromIntJsonNonNull((json['dateEntre'] as num).toInt()),
      dateSortie: dateFromIntJson((json['dateSortie'] as num?)?.toInt()),
      etatActuel: etatFromJson(json['etatActuel'] as String?),
      gaz: (json['gaz'] as num?)?.toInt(),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => (e as num?)?.toInt())
              .toList() ??
          const [null, null, null, null],
      kilometrage: (json['kilometrage'] as num?)?.toInt(),
      modele: json['modele'] as String?,
      nchassi: json['nchassi'] as String?,
      nmoteur: json['nmoteur'] as String?,
      remarque: json['remarque'] as String?,
      type: (json['type'] as num?)?.toInt(),
      vehicule: json['vehicule'] as String?,
      entretien: entretienFromJson(json['entretien'] as String?),
      vehiculemat: json['vehiculemat'] as String?,
      marque: json['marque'] as String?,
      matriculeConducteur: json['matriculeConducteur'] as String?,
      prenomConducteur: json['prenomConducteur'] as String?,
      nomConducteur: json['nomConducteur'] as String?,
      showImages: json['showImages'] as bool? ?? true,
      showEntretien: json['showEntretien'] as bool? ?? true,
      showEtat: json['showEtat'] as bool? ?? true,
      reparation: json['reparation'] as String?,
      reparationCost: (json['reparationCost'] as num?)?.toDouble(),
    )
      ..search = json['search'] as String?
      ..reparationNumero = (json['reparationNumero'] as num?)?.toInt();

Map<String, dynamic> _$FicheReceptionToJson(FicheReception instance) =>
    <String, dynamic>{
      'vehicule': instance.vehicule,
      'vehiculemat': instance.vehiculemat,
      'type': instance.type,
      'dateEntre': dateToIntJson(instance.dateEntre),
      'dateSortie': dateToIntJson(instance.dateSortie),
      'numero': instance.numero,
      'gaz': instance.gaz,
      'kilometrage': instance.kilometrage,
      'nmoteur': instance.nmoteur,
      'nchassi': instance.nchassi,
      'couleur': instance.couleur,
      'remarque': instance.remarque,
      'marque': instance.marque,
      'search': instance.search,
      'nomConducteur': instance.nomConducteur,
      'prenomConducteur': instance.prenomConducteur,
      'matriculeConducteur': instance.matriculeConducteur,
      'images': instance.images,
      'etatActuel': etatVehiculeToJson(instance.etatActuel),
      'entretien': entretienToJson(instance.entretien),
      'anneeUtil': instance.anneeUtil,
      'modele': instance.modele,
      'reparation': instance.reparation,
      'reparationNumero': instance.reparationNumero,
      'reparationCost': instance.reparationCost,
      'mobile': instance.mobile,
      'showImages': instance.showImages,
      'showEntretien': instance.showEntretien,
      'showEtat': instance.showEtat,
    };
