class PlaybackAuthResponse {
  final String playbackSessionId;
  final String playbackUrl;
  final DrmConfig? drm;
  final List<SubtitleTrack> subtitles;
  final List<AudioTrackItem> audioTracks;
  final int resumePositionSeconds;
  final String maxResolution;
  final String expiresAt;

  PlaybackAuthResponse({
    required this.playbackSessionId,
    required this.playbackUrl,
    this.drm,
    this.subtitles = const [],
    this.audioTracks = const [],
    this.resumePositionSeconds = 0,
    this.maxResolution = '1080p',
    required this.expiresAt,
  });

  factory PlaybackAuthResponse.fromJson(Map<String, dynamic> json) {
    return PlaybackAuthResponse(
      playbackSessionId: json['playbackSessionId'] ?? '',
      playbackUrl: json['playbackUrl'] ?? '',
      drm: json['drm'] != null ? DrmConfig.fromJson(json['drm']) : null,
      subtitles: (json['subtitles'] as List<dynamic>?)
              ?.map((s) => SubtitleTrack.fromJson(s))
              .toList() ??
          [],
      audioTracks: (json['audioTracks'] as List<dynamic>?)
              ?.map((a) => AudioTrackItem.fromJson(a))
              .toList() ??
          [],
      resumePositionSeconds: json['resumePositionSeconds'] ?? 0,
      maxResolution: json['maxResolution'] ?? '1080p',
      expiresAt: json['expiresAt'] ?? '',
    );
  }
}

class DrmConfig {
  final String type; // NONE, WIDEVINE, FAIRPLAY, CLEARKEY
  final String? licenseServerUrl;
  final String? certificateUrl;

  DrmConfig({
    required this.type,
    this.licenseServerUrl,
    this.certificateUrl,
  });

  factory DrmConfig.fromJson(Map<String, dynamic> json) {
    return DrmConfig(
      type: json['type'] ?? 'NONE',
      licenseServerUrl: json['licenseServerUrl'],
      certificateUrl: json['certificateUrl'],
    );
  }
}

class SubtitleTrack {
  final String id;
  final String language;
  final String label;
  final String format;
  final String url;
  final bool isDefault;

  SubtitleTrack({
    required this.id,
    required this.language,
    required this.label,
    required this.format,
    required this.url,
    this.isDefault = false,
  });

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) {
    return SubtitleTrack(
      id: json['id'] ?? '',
      language: json['language'] ?? 'vi',
      label: json['label'] ?? 'Tiếng Việt',
      format: json['format'] ?? 'VTT',
      url: json['url'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }
}

class AudioTrackItem {
  final String id;
  final String language;
  final String label;
  final bool isDefault;

  AudioTrackItem({
    required this.id,
    required this.language,
    required this.label,
    this.isDefault = false,
  });

  factory AudioTrackItem.fromJson(Map<String, dynamic> json) {
    return AudioTrackItem(
      id: json['id'] ?? '',
      language: json['language'] ?? 'vi',
      label: json['label'] ?? 'Gốc',
      isDefault: json['isDefault'] ?? false,
    );
  }
}
