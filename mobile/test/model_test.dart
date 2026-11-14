import 'package:flutter_test/flutter_test.dart';
import 'package:cineora/data/models/movie_model.dart';
import 'package:cineora/data/models/playback_auth_model.dart';
import 'package:cineora/data/models/user_model.dart';

void main() {
  group('CINEORA Model Parsing Tests', () {
    test('MovieSummary.fromJson correctly deserializes payload', () {
      final json = {
        'id': 'm1',
        'title': 'Mắt Biếc',
        'originalTitle': 'Dreamy Eyes',
        'slug': 'mat-biec',
        'posterUrl': 'https://example.com/poster.jpg',
        'backdropUrl': 'https://example.com/backdrop.jpg',
        'releaseYear': 2019,
        'duration': 117,
        'type': 'MOVIE',
        'ratingAverage': 8.4,
        'ratingCount': 1500,
        'viewCount': 120000,
        'genres': [
          {'id': 'g1', 'name': 'Lãng Mạn', 'slug': 'lang-man'}
        ],
      };

      final movie = MovieSummary.fromJson(json);

      expect(movie.id, 'm1');
      expect(movie.title, 'Mắt Biếc');
      expect(movie.releaseYear, 2019);
      expect(movie.ratingAverage, 8.4);
      expect(movie.genres.length, 1);
      expect(movie.genres.first.name, 'Lãng Mạn');
    });

    test('PlaybackAuthResponse.fromJson correctly parses signed stream', () {
      final json = {
        'playbackSessionId': 'session-123',
        'playbackUrl': 'https://cdn.cineora.tv/hls/test.m3u8?token=sig',
        'drm': {'type': 'NONE'},
        'resumePositionSeconds': 120,
        'maxResolution': '1080p',
        'expiresAt': '2026-11-14T12:00:00Z',
        'subtitles': [
          {
            'id': 'sub-1',
            'language': 'vi',
            'label': 'Tiếng Việt',
            'format': 'VTT',
            'url': 'https://cdn.cineora.tv/sub.vtt',
            'isDefault': true,
          }
        ],
      };

      final auth = PlaybackAuthResponse.fromJson(json);

      expect(auth.playbackSessionId, 'session-123');
      expect(auth.playbackUrl, contains('token=sig'));
      expect(auth.resumePositionSeconds, 120);
      expect(auth.subtitles.length, 1);
      expect(auth.subtitles.first.label, 'Tiếng Việt');
    });

    test('UserModel.fromJson parses user profile with active subscription', () {
      final json = {
        'id': 'u1',
        'email': 'user@cineora.tv',
        'displayName': 'Nguyễn Văn A',
        'role': 'USER',
        'subscription': {
          'planId': 'PLAN_PREMIUM_MONTHLY',
          'planName': 'Premium Tháng',
          'status': 'ACTIVE',
          'expiresAt': '2026-12-31T23:59:59Z',
          'maxResolution': '4K Ultra HD',
          'maxStreams': 2,
        },
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'u1');
      expect(user.displayName, 'Nguyễn Văn A');
      expect(user.subscription, isNotNull);
      expect(user.subscription!.planId, 'PLAN_PREMIUM_MONTHLY');
      expect(user.subscription!.maxStreams, 2);
    });
  });
}
