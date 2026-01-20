class ApiEndPoints {
  static const login = "/auth/login";
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/users/change-password';

  // ✅ Delivery endpoints
  static const String deliveries = '/deliveries';
  static const String deliveryDetail = '/deliveries'; // + /{id}
  static const String updateDeliveryStatus = '/deliveries'; // + /{id}/status

  static const String myDeliveries = '/mobile/courier/orders';  // ✅ NOUVEAU
  static const String updateAssignmentStatus = '/courier/assignments';
  static const String history = '/mobile/courier/orders/history';
  static const String orderDetail = '/mobile/courier/orders'; // + /{order_uuid}
  static const String acceptOrRejectOrder = '/mobile/courier/orders';
  static const String deliveriesToday = '/mobile/courier/orders/today';
  static const String notifications = '/notifications/user';
  static const String readNotfication = '/notifications';
  static const String ordersSummary = '/mobile/courier/orders/summary';
  static const String courierLocationUpdate = '/couriers';


  // ✅ Profile endpoints
  static const String courierProfile = '/mobile/courier/me';
  static const String updateProfile = '/profile/update';

  // ✅ Location endpoints
  static const String updateLocation = '/location/update';
  static const String activeDeliveries = '/deliveries/active';


}
