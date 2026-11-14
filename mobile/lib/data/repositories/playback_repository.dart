import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/playback_auth_model.dart';

class PlaybackRepository {
  final ApiClient apiClient;

  PlaybackRepository({required this.apiClient});

  Future<PlaybackAuthResponse> authorizePlayback({
    required String episodeId,
    required String deviceId,
  }) async {
    final response = await apiClient.dio.post(
      ApiConstants.playbackAuthorize,
      data: {
        'episodeId': episodeId,
        'deviceId': deviceId,
      },
    );

    return PlaybackAuthResponse.fromJson(response.data);
  }

  Future<void> sendHeartbeat({
    required String playbackSessionId,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    await apiClient.dio.post(
      ApiConstants.playbackHeartbeat,
      data: {
        'playbackSessionId': playbackSessionId,
        'positionSeconds': positionSeconds,
        'durationSeconds': durationSeconds,
      },
    );
  }

  Future<void> closeSession({
    required String playbackSessionId,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    await apiClient.dio.post(
      ApiConstants.playbackClose,
      data: {
        'playbackSessionId': playbackSessionId,
        'positionSeconds': positionSeconds,
        'durationSeconds': durationSeconds,
      },
    );
  }
}
