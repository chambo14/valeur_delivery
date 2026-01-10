import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../network/api_service.dart';
import '../../network/config/dio.dart';
import '../../network/courier_service.dart';
import '../../network/delivery_service.dart';
import '../../network/notification_service.dart';
import '../../network/repository/auth_repository.dart';
import '../../network/repository/courier_repository.dart';
import '../../network/repository/delivery_repository.dart';
  // ✅ NOUVEAU

/// Provider pour DioService (singleton)
final dioServiceProvider = Provider<DioService>((ref) {
  return DioService();
});

/// Provider pour ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  final dioService = ref.read(dioServiceProvider);
  return ApiService(dioService);
});

/// Provider pour DeliveryService (✅ NOUVEAU)
final deliveryServiceProvider = Provider<DeliveryService>((ref) {
  final dioService = ref.read(dioServiceProvider);
  return DeliveryService(dioService);
});

/// Provider pour AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return AuthRepository(apiService);
});

/// Provider pour DeliveryRepository (✅ NOUVEAU)
final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  final deliveryService = ref.read(deliveryServiceProvider);
  return DeliveryRepository(deliveryService);
});

final courierServiceProvider = Provider<CourierService>((ref) {
  final dioService = ref.read(dioServiceProvider);
  return CourierService(dioService);
});

final courierRepositoryProvider = Provider<CourierRepository>((ref) {
  final courierService = ref.read(courierServiceProvider);
  return CourierRepository(courierService);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final dioService = ref.read(dioServiceProvider);
  return NotificationService(dioService);
});