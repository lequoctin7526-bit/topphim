import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/playback_auth_model.dart';

class CineoraPlayerScreen extends ConsumerStatefulWidget {
  final String episodeId;
  final String movieTitle;
  final String episodeTitle;

  const CineoraPlayerScreen({
    super.key,
    required this.episodeId,
    required this.movieTitle,
    required this.episodeTitle,
  });

  @override
  ConsumerState<CineoraPlayerScreen> createState() => _CineoraPlayerScreenState();
}

class _CineoraPlayerScreenState extends ConsumerState<CineoraPlayerScreen> {
  VideoPlayerController? _videoController;
  PlaybackAuthResponse? _authData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showControls = true;
  bool _isControlsLocked = false;
  Timer? _hideTimer;
  Timer? _heartbeatTimer;

  // Selected tracks
  String _selectedSubtitle = 'vi';
  String _selectedQuality = 'Auto';

  @override
  void initState() {
    super.initState();
    // Enter landscape full screen cinema mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _initializePlayback();
  }

  Future<void> _initializePlayback() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final playbackRepo = ref.read(playbackRepositoryProvider);
    final storage = ref.read(storageServiceProvider);
    final deviceId = await storage.getOrCreateDeviceId();

    try {
      // 1. Authorize playback with backend entitlement check
      final auth = await playbackRepo.authorizePlayback(
        episodeId: widget.episodeId,
        deviceId: deviceId,
      );

      _authData = auth;

      // 2. Initialize video player with signed HLS stream URL
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(auth.playbackUrl),
      );

      await _videoController!.initialize();

      // 3. Resume from previous position if available
      if (auth.resumePositionSeconds > 0) {
        await _videoController!.seekTo(Duration(seconds: auth.resumePositionSeconds));
      }

      await _videoController!.play();

      _videoController!.addListener(_videoListener);

      // 4. Start periodic 10s heartbeat
      _startHeartbeat(auth.playbackSessionId);

      _startHideTimer();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().contains('403')
              ? 'Nội dung bị giới hạn số thiết bị hoặc không thuộc vùng cấp phép tại Việt Nam'
              : 'Không thể kết nối máy chủ phát video. Vui lòng kiểm tra mạng và thử lại.';
        });
      }
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startHeartbeat(String sessionId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_videoController != null && _videoController!.value.isInitialized) {
        final positionSec = _videoController!.value.position.inSeconds;
        final durationSec = _videoController!.value.duration.inSeconds;

        ref.read(playbackRepositoryProvider).sendHeartbeat(
              playbackSessionId: sessionId,
              positionSeconds: positionSec,
              durationSeconds: durationSec > 0 ? durationSec : 1,
            );
      }
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && !_isControlsLocked) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls && !_isControlsLocked) {
      _startHideTimer();
    }
  }

  void _seekBy(int seconds) {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    final currentPos = _videoController!.value.position;
    final newPos = currentPos + Duration(seconds: seconds);
    _videoController!.seekTo(newPos);
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _heartbeatTimer?.cancel();

    // Close session gracefully
    if (_authData != null && _videoController != null && _videoController!.value.isInitialized) {
      ref.read(playbackRepositoryProvider).closeSession(
            playbackSessionId: _authData!.playbackSessionId,
            positionSeconds: _videoController!.value.position.inSeconds,
            durationSeconds: _videoController!.value.duration.inSeconds,
          );
    }

    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();

    // Restore portrait UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Player Core
            Center(
              child: _videoController != null && _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : const SizedBox.shrink(),
            ),

            // Loading Spinner
            if (_isLoading)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Đang xác thực quyền xem và kết nối CDN...',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

            // Error Display Overlay
            if (_errorMessage != null)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 48),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: _initializePlayback,
                            child: const Text('Thử lại'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => context.pop(),
                            child: const Text('Quay lại'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Controls Overlay
            if (_showControls && !_isLoading && _errorMessage == null)
              _buildControlsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    final position = _videoController?.value.position ?? Duration.zero;
    final duration = _videoController?.value.duration ?? Duration.zero;
    final isPlaying = _videoController?.value.isPlaying ?? false;

    return Container(
      color: Colors.black.withOpacity(0.55),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.movieTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        if (widget.episodeTitle.isNotEmpty)
                          Text(
                            widget.episodeTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  // Lock Button
                  IconButton(
                    icon: Icon(
                      _isControlsLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                      color: _isControlsLocked ? AppColors.primary : Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isControlsLocked = !_isControlsLocked;
                      });
                    },
                  ),
                  // Settings (Subtitles & Quality)
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    onPressed: _showSettingsDialog,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Center Rewind / Play / Forward
            if (!_isControlsLocked)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 40),
                    onPressed: () => _seekBy(-10),
                  ),
                  const SizedBox(width: 36),
                  GestureDetector(
                    onTap: () {
                      if (_videoController == null) return;
                      setState(() {
                        if (isPlaying) {
                          _videoController!.pause();
                        } else {
                          _videoController!.play();
                        }
                      });
                      _startHideTimer();
                    },
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary,
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 40),
                    onPressed: () => _seekBy(10),
                  ),
                ],
              ),

            const Spacer(),

            // Bottom Progress Bar & Time
            if (!_isControlsLocked)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: AppColors.primary,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                        min: 0.0,
                        max: duration.inMilliseconds.toDouble(),
                        onChanged: (val) {
                          _videoController?.seekTo(Duration(milliseconds: val.toInt()));
                          _startHideTimer();
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(_formatDuration(duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cài đặt phát video',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Subtitle selector
                  const Text('Phụ đề', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tiếng Việt'),
                        selected: _selectedSubtitle == 'vi',
                        onSelected: (val) {
                          setState(() => _selectedSubtitle = 'vi');
                          setModalState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('English'),
                        selected: _selectedSubtitle == 'en',
                        onSelected: (val) {
                          setState(() => _selectedSubtitle = 'en');
                          setModalState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Tắt'),
                        selected: _selectedSubtitle == 'off',
                        onSelected: (val) {
                          setState(() => _selectedSubtitle = 'off');
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Quality selector
                  const Text('Chất lượng video', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['Auto (Tự động)', '1080p Full HD', '720p HD', '480p'].map((q) {
                      return ChoiceChip(
                        label: Text(q),
                        selected: _selectedQuality == q,
                        onSelected: (val) {
                          setState(() => _selectedQuality = q);
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
