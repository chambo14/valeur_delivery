import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:valeur_delivery/network/config/token_service.dart';
import 'package:valeur_delivery/network/config/url.dart';
import 'package:valeur_delivery/screens/authentification/login_screen.dart';

import '../../main.dart';
import 'app_logger.dart';

class DioService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Url.baseUrl,
      connectTimeout: const Duration(seconds: 30), // 🔹 Augmenté pour upload
      receiveTimeout: const Duration(seconds: 30), // 🔹 Augmenté pour upload
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  DioService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 🔹 Ajouter le token automatiquement via TokenService
          final token = await TokenService.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
            AppLogger.debug("🔑 [DioService] Token ajouté à la requête");
          }

          AppLogger.info("➡️ [DioService] ${options.method} => ${options.path}");
          if (options.data != null && options.data is! FormData) {
            AppLogger.debug("   - Data: ${options.data}");
          } else if (options.data is FormData) {
            AppLogger.debug("   - FormData envoyé");
          }
          if (options.queryParameters.isNotEmpty) {
            AppLogger.debug("   - Query: ${options.queryParameters}");
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.info("✅ [DioService] ${response.statusCode} => ${response.requestOptions.path}");
          AppLogger.debug("   - Response: ${response.data}");
          handler.next(response);
        },
        onError: (DioException e, handler) async {
          AppLogger.error("❌ [DioService] ${e.response?.statusCode ?? 'NO_STATUS'} => ${e.requestOptions.path}");
          AppLogger.error("   - Message: ${e.message}");

          if (e.response?.data != null) {
            AppLogger.error("   - Response: ${e.response?.data}");
          }

          // 🔹 Gestion automatique du token expiré
          if (e.response?.statusCode == 401) {
            AppLogger.warning("🔒 [DioService] Token expiré - Déconnexion automatique");

            await TokenService.deleteToken();

            // 🔁 Éviter plusieurs appels de redirection
            if (navigatorKey.currentState != null) {
              navigatorKey.currentState!.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => LoginScreen()),
                    (route) => false,
              );
            }
          }

          handler.next(e);
        },
      ),
    );
  }

  // --- GET ---
  Future<Response> get(
      String endpoint, {
        Map<String, dynamic>? queryParams,
        Options? options,
      }) async {
    try {
      return await _dio.get(endpoint, queryParameters: queryParams, options: options);
    } on DioException {
      rethrow;
    }
  }

  // --- POST ---
  Future<Response> post(
      String endpoint,
      dynamic data, {
        Options? options,
      }) async {
    try {
      return await _dio.post(endpoint, data: data, options: options);
    } on DioException {
      rethrow;
    }
  }

  // --- POST avec FormData (pour upload de fichiers) ---
  Future<Response> postFormData(
      String endpoint,
      FormData formData, {
        Options? options,
        ProgressCallback? onSendProgress,
      }) async {
    try {
      AppLogger.info("📸 [DioService] POST FormData");

      return await _dio.post(
        endpoint,
        data: formData,
        options: options ?? Options(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onSendProgress,
      );
    } on DioException {
      rethrow;
    }
  }

  // --- POST Multipart (méthode simplifiée pour cas courants) ---
  Future<Response> postMultipart(
      String endpoint, {
        Map<String, dynamic>? fields,
        File? mainImage,
        List<File>? images,
        Options? options,
        ProgressCallback? onSendProgress,
      }) async {
    try {
      FormData formData = FormData.fromMap({
        if (fields != null) ...fields,
        if (mainImage != null)
          "main_image": await MultipartFile.fromFile(
            mainImage.path,
            filename: mainImage.path.split("/").last,
          ),
        if (images != null && images.isNotEmpty)
          "images": await Future.wait(
            images.map((f) => MultipartFile.fromFile(
              f.path,
              filename: f.path.split("/").last,
            )),
          ),
      });

      AppLogger.info("📸 [DioService] POST Multipart avec images");

      return await _dio.post(
        endpoint,
        data: formData,
        options: options ?? Options(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onSendProgress,
      );
    } on DioException {
      rethrow;
    }
  }

  // --- PUT ---
  Future<Response> put(
      String endpoint,
      dynamic data, {
        Options? options,
      }) async {
    try {
      return await _dio.put(endpoint, data: data, options: options);
    } on DioException {
      rethrow;
    }
  }

  // --- PATCH ---
  Future<Response> patch(
      String endpoint,
      dynamic data, {
        Options? options,
      }) async {
    try {
      return await _dio.patch(endpoint, data: data, options: options);
    } on DioException {
      rethrow;
    }
  }

  // --- DELETE ---
  Future<Response> delete(String endpoint, {Options? options}) async {
    try {
      return await _dio.delete(endpoint, options: options);
    } on DioException {
      rethrow;
    }
  }

  // --- Token d'authentification manuel (optionnel) ---
  void setToken(String token) {
    _dio.options.headers["Authorization"] = "Bearer $token";
    AppLogger.info("🔑 [DioService] Token défini manuellement");
  }
}