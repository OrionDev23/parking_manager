import 'dart:convert';

import '../../../domain/entities/vehicle.dart';

/// Converts the domain vehicle into the legacy columns accepted by the
/// current Appwrite `vehicle` table.
///
/// `createdBy` is retained losslessly in the JSON payload. The legacy
/// `user_creation` column is deliberately not written: its live Appwrite
/// limit is 30 characters, while Appwrite user IDs may be 36 characters.
/// Truncating an identity would corrupt the audit reference.
class VehicleRowSerializer {
  const VehicleRowSerializer._();

  static Map<String, dynamic> toRow(Vehicle vehicle) => {
    'companyId': vehicle.companyId,
    'siteId': vehicle.siteId,
    'matricule': vehicle.registration,
    'martricule_etrang': vehicle.foreignRegistration,
    'wilaya': vehicle.wilaya,
    'commune': vehicle.commune,
    'daira': vehicle.daira,
    'adresse': vehicle.address,
    'date': vehicle.registrationDate?.millisecondsSinceEpoch,
    'quittance': vehicle.receiptAmount,
    'numero': vehicle.receiptNumber,
    'nom': vehicle.ownerLastName,
    'prenom': vehicle.ownerFirstName,
    'profession': vehicle.ownerProfession,
    'numero_serie': vehicle.serialNumber,
    'type': vehicle.type,
    'marque': vehicle.brand,
    'genre': vehicle.genre,
    'charge_utile': vehicle.usefulLoad,
    'poids_total': vehicle.totalWeight,
    'place_assises': vehicle.seats,
    'puissance': vehicle.fiscalPower,
    'energie': vehicle.energy,
    'carrosserie': vehicle.body,
    'annee_util': vehicle.usageYear,
    'matricule_prec': vehicle.previousRegistrations,
    // Do not write legacy user_creation (string max 30).
    // The complete createdBy value remains in payload below.
    'pays': vehicle.country,
    'etat': vehicle.state,
    'etatactuel': vehicle.currentState,
    'filliale': vehicle.subsidiary,
    'departement': vehicle.department,
    'direction': vehicle.direction,
    'appartenance': vehicle.ownership,
    'appartenanceconducteur': vehicle.driverOwnership,
    'service': vehicle.service,
    'matriculeConducteur': vehicle.driverRegistration,
    'lourd': vehicle.heavy,
    'decision': vehicle.decision,
    'emplacement': vehicle.location,
    'perimetre': vehicle.perimeter,
    // Preserve the complete local-first model for round-tripping.
    'payload': jsonEncode(vehicle.toMap()),
  };
}
