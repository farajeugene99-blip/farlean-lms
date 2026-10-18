import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/video_item.dart';
import '../../repositories/video_repository.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final VideoItem? initialVideo;
  final VideoRepository? videoRepository;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    this.initialVideo,
    this.videoRepository,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoRepository _videoRepository;
  VideoItem? _video;
  bool _isLoading = true;
  String? _errorMessage;

  // YouTube Controller
  YoutubePlayerController? _youtubeController;

  // Cloudinary / Direct Video Controller
  VideoPlayerController? _cloudinaryController;
  bool _isCloudinaryPlaying = false;

  @override
  void initState() {
    super.initState();
    _videoRepository = widget.videoRepository ?? VideoRepository();
    _video = widget.initialVideo;
    if (_video == null) {
      _loadVideo();
    } else {
      _initializePlayer(_video!);
    }
  }

  @override
  void dispose() {
    _youtubeController?.close();
    _cloudinaryController?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final video = await _videoRepository.getVideo(widget.videoId);
      if (!mounted) return;

      if (video == null) {
        setState(() {
          _errorMessage = 'Video pembelajaran tidak ditemukan.';
          _isLoading = false;
        });
        return;
      }

      _video = video;
      _initializePlayer(video);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat video: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _initializePlayer(VideoItem video) {
    if (video.provider == VideoProvider.youtube) {
      final videoId = YoutubePlayerController.convertUrlToId(video.url);
      if (videoId == null) {
        setState(() {
          _errorMessage = 'URL video YouTube tidak valid.';
          _isLoading = false;
        });
        return;
      }

      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
        ),
      );

      setState(() => _isLoading = false);
    } else {
      // Cloudinary / direct MP4
      _cloudinaryController = VideoPlayerController.networkUrl(Uri.parse(video.url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Gagal memutar video Cloudinary: $error';
              _isLoading = false;
            });
          }
        });

      _cloudinaryController?.addListener(() {
        if (mounted && _cloudinaryController != null) {
          final isPlaying = _cloudinaryController!.value.isPlaying;
          if (isPlaying != _isCloudinaryPlaying) {
            setState(() => _isCloudinaryPlaying = isPlaying);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Memuat pemutar video...'),
      );
    }

    if (_errorMessage != null || _video == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Video Pembelajaran')),
        body: ErrorView(
          message: _errorMessage ?? 'Video tidak ditemukan.',
          onRetry: _loadVideo,
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    final video = _video!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.meetingModuleVideoTitle),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.primaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              video.provider.value.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: context.primaryColor,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Player Container
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: video.provider == VideoProvider.youtube
                  ? YoutubePlayer(
                      controller: _youtubeController!,
                    )
                  : _buildCloudinaryPlayer(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.videoProviderLabel(video.provider.value),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (video.duration != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        l10n.videoDurationLabel(video.duration! ~/ 60, video.duration! % 60),
                        style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.videoIntegratedTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.videoSourceUrlLabel(video.url),
                  style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: context.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.videoStorageNote,
                            style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudinaryPlayer() {
    final controller = _cloudinaryController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        VideoPlayer(controller),
        // Overlay Controls
        GestureDetector(
          onTap: () {
            setState(() {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
            });
          },
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: AnimatedOpacity(
                opacity: controller.value.isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: AppTheme.primary,
              bufferedColor: Colors.white24,
              backgroundColor: Colors.black26,
            ),
          ),
        ),
      ],
    );
  }
}
