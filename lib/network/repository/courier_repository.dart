import 'package:dartz/dartz.dart';
import '../../data/models/courier/courier_profile_response.dart';
import '../courier_service.dart';

class CourierRepository {
  final CourierService courierService;

  CourierRepository(this.courierService);

  Future<Either<String, CourierProfileResponse>> getProfile() async {
    return await courierService.getProfile();
  }
}