import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService storageService;

  ApiClient({required this.storageService}) {
    final baseUrl = Platform.isIOS ? ApiConstants.iosLocalBaseUrl : ApiConstants.defaultBaseUrl;

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storageService.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final deviceId = await storageService.getOrCreateDeviceId();
          options.headers['X-Device-Id'] = deviceId;
          return handler.next(options);
        },
        onError: (DioException err, handler) async {
          // Automatic token refresh on 401 Unauthorized
          if (err.response?.statusCode == 401 && !err.requestOptions.path.contains('/auth/')) {
            try {
              final refreshToken = await storageService.getRefreshToken();
              if (refreshToken != null) {
                final refreshResponse = await dio.post(
                  ApiConstants.refresh,
                  data: {'refreshToken': refreshToken},
                );

                if (refreshResponse.statusCode == 200) {
                  final newAccessToken = refreshResponse.data['accessToken'];
                  final newRefreshToken = refreshResponse.data['refreshToken'];

                  await storageService.saveTokens(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                  );

                  // Retry the original request
                  final retryOptions = err.requestOptions;
                  retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  final retryResponse = await dio.fetch(retryOptions);
                  return handler.resolve(retryResponse);
                }
              }
            } catch (e) {
              await storageService.clearTokens();
            }
          }
          return handler.next(err);
        },
      ),
    );
  }
}
