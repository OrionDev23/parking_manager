import 'permission.dart';

abstract final class PermissionCatalog {
  static const all = <Permission>[
    Permission(id: 'dashboard.view', label: 'Voir le tableau de bord', module: 'dashboard', action: 'view'),
    Permission(id: 'vehicles.view', label: 'Voir les véhicules', module: 'vehicles', action: 'view'),
    Permission(id: 'vehicles.create', label: 'Créer des véhicules', module: 'vehicles', action: 'create'),
    Permission(id: 'vehicles.update', label: 'Modifier les véhicules', module: 'vehicles', action: 'update'),
    Permission(id: 'vehicles.delete', label: 'Supprimer des véhicules', module: 'vehicles', action: 'delete'),
    Permission(id: 'vehicles.import', label: 'Importer des véhicules', module: 'vehicles', action: 'import'),
    Permission(id: 'drivers.view', label: 'Voir les conducteurs', module: 'drivers', action: 'view'),
    Permission(id: 'drivers.create', label: 'Créer des conducteurs', module: 'drivers', action: 'create'),
    Permission(id: 'drivers.update', label: 'Modifier les conducteurs', module: 'drivers', action: 'update'),
    Permission(id: 'drivers.delete', label: 'Supprimer des conducteurs', module: 'drivers', action: 'delete'),
    Permission(id: 'stock.view', label: 'Voir le stock', module: 'stock', action: 'view'),
    Permission(id: 'stock.manage', label: 'Gérer le stock', module: 'stock', action: 'manage'),
    Permission(id: 'repairs.view', label: 'Voir les réparations', module: 'repairs', action: 'view'),
    Permission(id: 'repairs.manage', label: 'Gérer les réparations', module: 'repairs', action: 'manage'),
    Permission(id: 'planning.view', label: 'Voir le planning', module: 'planning', action: 'view'),
    Permission(id: 'planning.manage', label: 'Gérer le planning', module: 'planning', action: 'manage'),
    Permission(id: 'reception.view', label: 'Voir les réceptions', module: 'reception', action: 'view'),
    Permission(id: 'reception.manage', label: 'Gérer les réceptions', module: 'reception', action: 'manage'),
    Permission(id: 'clients.view', label: 'Voir les clients', module: 'clients', action: 'view'),
    Permission(id: 'clients.manage', label: 'Gérer les clients', module: 'clients', action: 'manage'),
    Permission(id: 'company.view', label: 'Voir l’entreprise', module: 'company', action: 'view'),
    Permission(id: 'company.manage', label: 'Gérer l’entreprise', module: 'company', action: 'manage'),
    Permission(id: 'users.view', label: 'Voir les utilisateurs', module: 'users', action: 'view'),
    Permission(id: 'users.manage', label: 'Gérer les utilisateurs', module: 'users', action: 'manage'),
    Permission(id: 'teams.view', label: 'Voir les équipes', module: 'teams', action: 'view'),
    Permission(id: 'teams.manage', label: 'Gérer les équipes', module: 'teams', action: 'manage'),
    Permission(id: 'permissions.manage', label: 'Gérer les accès', module: 'permissions', action: 'manage'),
    Permission(id: 'activity.view', label: 'Voir les activités', module: 'activity', action: 'view'),
    Permission(id: 'backup.manage', label: 'Gérer les sauvegardes', module: 'backup', action: 'manage'),
  ];

  static const presets = <String, Set<String>>{
    'Administrateur': {'*'},
    'Gestionnaire': {
      'dashboard.view',
      'vehicles.view',
      'vehicles.create',
      'vehicles.update',
      'drivers.view',
      'drivers.create',
      'drivers.update',
      'stock.view',
      'stock.manage',
      'repairs.view',
      'repairs.manage',
      'planning.view',
      'planning.manage',
      'reception.view',
      'reception.manage',
      'clients.view',
      'clients.manage',
      'activity.view',
    },
    'Réception': {
      'dashboard.view',
      'vehicles.view',
      'vehicles.create',
      'vehicles.update',
      'reception.view',
      'reception.manage',
      'clients.view',
      'clients.manage',
    },
    'Atelier': {
      'dashboard.view',
      'vehicles.view',
      'repairs.view',
      'repairs.manage',
      'stock.view',
      'stock.manage',
      'drivers.view',
    },
    'Lecture seule': {
      'dashboard.view',
      'vehicles.view',
      'drivers.view',
      'stock.view',
      'repairs.view',
      'planning.view',
      'reception.view',
      'clients.view',
      'activity.view',
    },
  };

  static Set<String> preset(String name) {
    final permissions = presets[name];
    if (permissions == null) return <String>{};
    if (permissions.contains('*')) return all.map((permission) => permission.id).toSet();
    return {...permissions};
  }

  static Permission? find(String id) {
    for (final permission in all) {
      if (permission.id == id) return permission;
    }
    return null;
  }
}
