import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;
  final SecureStorageService storageService;

  AuthRepository({required this.apiClient, required this.storageService});

  Future<UserModel> login({required String email, required String password}) async {
    final response = await apiClient.dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );

    final data = response.data;
    await storageService.saveTokens(
      accessToken: data['tokens']['accessToken'],
      refreshToken: data['tokens']['refreshToken'],
    );

    return UserModel.fromJson(data['user']);
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await apiClient.dio.post(
      ApiConstants.register,
      data: {'email': email, 'password': password, 'displayName': displayName},
    );

    final data = response.data;
    await storageService.saveTokens(
      accessToken: data['tokens']['accessToken'],
      refreshToken: data['tokens']['refreshToken'],
    );

    return UserModel.fromJson(data['user']);
  }

  Future<UserModel?> getMe() async {
    final token = await storageService.getAccessToken();
    if (token == null) return null;

    try {
      final response = await apiClient.dio.get(ApiConstants.me);
      return UserModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await apiClient.dio.post(ApiConstants.logout);
    } catch (_) {}
    await storageService.clearTokens();
  }
}
