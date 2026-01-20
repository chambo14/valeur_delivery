// models/navigation/navigation_type.dart

enum NavigationType {
  pickup,    // Récupération du colis
  delivery,  // Livraison au client
}

extension NavigationTypeExtension on NavigationType {
  String get displayName {
    switch (this) {
      case NavigationType.pickup:
        return 'Récupération';
      case NavigationType.delivery:
        return 'Livraison';
    }
  }

  String get actionText {
    switch (this) {
      case NavigationType.pickup:
        return 'Récupérer le colis';
      case NavigationType.delivery:
        return 'Livrer le colis';
    }
  }

  String get completionText {
    switch (this) {
      case NavigationType.pickup:
        return 'Colis récupéré';
      case NavigationType.delivery:
        return 'Colis livré';
    }
  }

  bool get isPickup => this == NavigationType.pickup;
  bool get isDelivery => this == NavigationType.delivery;
}