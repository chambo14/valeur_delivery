import 'package:dartz/dartz.dart';

import '../../data/models/login_request.dart';
import '../../data/models/login_response.dart';
import '../api_service.dart';


class AuthRepository {
  final ApiService apiService;

  AuthRepository(this.apiService);

  Future<Either<String, LoginResponse>> login({
    required String identifier,
    required String password,
  }) async {
    final request = LoginRequest(
      identifier: identifier,
      password: password,
    );

    return await apiService.loginUser(request);
  }

  Future<Either<String, bool>> logout() async {
    return await apiService.logoutUser();
  }

  Future<Either<String, String>> forgotPassword(String phone) async {
    return await apiService.forgotPassword(phone);
  }

  Future<Either<String, String>> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    return await apiService.resetPassword(
      phone: phone,
      code: code,
      newPassword: newPassword,
    );
  }

  Future<Either<String, String>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await apiService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}