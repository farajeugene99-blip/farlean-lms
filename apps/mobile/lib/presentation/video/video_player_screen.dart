import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../core/auth/role_guard.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/video_item.dart';
import '../../repositories/video_repository.dart';
import '../../services/ai_service.dart';
import '../../services/auth_provider.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final VideoItem? initialVideo;
  final VideoRepository? videoRepository;
  final AiService? aiService;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    this.initialVideo,
    this.videoRepository,
    this.aiService,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoRepository _videoRepository;
  late final AiService _aiService;
  VideoItem? _video;
  bool _isLoading = true;
  String? _errorMessage;
  String? _errorKey;
  String? _errorParam;

  void _setError(String key, [String? param]) {
    setState(() {
      _errorKey = key;
      _errorParam = param;
      _isLoading = false;
    });
  }

  String _resolveErrorMessage(AppLocalizations l10n) {
    if (_errorKey != null) {
      switch (_errorKey) {
        case 'not_found':
          return l10n.videoNotFound;
        case 'load_failed':
          return l10n.videoLoadFailed(_errorParam ?? '');
        case 'youtube_invalid':
          return l10n.videoYoutubeUrlInvalid;
        case 'cloudinary_failed':
          return l10n.videoPlaybackFailed(_errorParam ?? '');
      }
    }
    return _errorMessage ?? l10n.videoNotFound;
  }

  // YouTube Controller
  YoutubePlayerController? _youtubeController;

  // Cloudinary / Direct Video Controller
  VideoPlayerController? _cloudinaryController;
  bool _isCloudinaryPlaying = false;

  @override
  void initState() {
    super.initState();
    _videoRepository = widget.videoRepository ?? VideoRepository();
    _aiService = widget.aiService ?? AiService();
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
      _errorKey = null;
      _errorParam = null;
    });

    try {
      final video = await _videoRepository.getVideo(widget.videoId);
      if (!mounted) return;

      if (video == null) {
        _setError('not_found');
        return;
      }

      _video = video;
      _initializePlayer(video);
    } catch (e) {
      if (mounted) {
        _setError('load_failed', e.toString());
      }
    }
  }

  void _initializePlayer(VideoItem video) {
    if (video.provider == VideoProvider.youtube) {
      final videoId = YoutubePlayerController.convertUrlToId(video.url);
      if (videoId == null) {
        _setError('youtube_invalid');
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
            _setError('cloudinary_failed', error.toString());
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
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        body: LoadingIndicator(message: l10n.videoLoadingPlayer),
      );
    }

    if (_video == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.meetingModuleVideoTitle)),
        body: ErrorView(
          message: _resolveErrorMessage(l10n),
          onRetry: _loadVideo,
        ),
      );
    }

    final video = _video!;
    final authProvider = context.watch<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.meetingModuleVideoTitle),
        actions: [
          if (isStaff)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: l10n.videoEditTitle,
              onPressed: _showEditVideoDialog,
            ),
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
              child: _errorKey != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              _resolveErrorMessage(l10n),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  : (video.provider == VideoProvider.youtube
                      ? YoutubePlayer(
                          controller: _youtubeController!,
                        )
                      : _buildCloudinaryPlayer()),
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
                  video.title.isNotEmpty ? video.title : l10n.videoIntegratedTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.videoSourceUrlLabel(video.url),
                  style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                ),
                if (video.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.videoDescLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: context.borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        video.description,
                        style: TextStyle(fontSize: 13, height: 1.4, color: context.textPrimaryColor),
                      ),
                    ),
                  ),
                ],
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

  Future<void> _showEditVideoDialog() async {
    final video = _video;
    if (video == null) return;
    final l10n = AppLocalizations.of(context);

    final titleCtrl = TextEditingController(text: video.title);
    final descCtrl = TextEditingController(text: video.description);
    final formKey = GlobalKey<FormState>();
    bool isDrafting = false;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.videoEditTitle),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.videoTitleLabel,
                        hintText: 'Contoh: Penjelasan State Management',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(l10n.videoDescLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: isDrafting
                              ? null
                              : () async {
                                  setDialogState(() => isDrafting = true);
                                  try {
                                    final draft = await _aiService.generateVideoDescription(
                                      title: titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : 'Video Pembelajaran',
                                      existingDescription: descCtrl.text.trim(),
                                    );
                                    if (ctx.mounted) {
                                      setDialogState(() {
                                        descCtrl.text = draft;
                                        isDrafting = false;
                                      });
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(content: Text(l10n.aiVideoDraftSuccess), backgroundColor: AppTheme.success),
                                      );
                                    }
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      setDialogState(() => isDrafting = false);
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
                                      );
                                    }
                                  }
                                },
                          icon: isDrafting
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.auto_awesome_rounded, size: 16),
                          label: Text(l10n.aiVideoDraftBtn, style: const TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Tuliskan deskripsi atau rangkuman video...',
                      ),
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.btnCancel)),
            ElevatedButton(
              onPressed: () async {
                final updatedVideo = video.copyWith(
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
                try {
                  await _videoRepository.updateVideo(updatedVideo);
                  if (mounted) {
                    setState(() => _video = updatedVideo);
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
                    );
                  }
                }
              },
              child: Text(l10n.btnSave),
            ),
          ],
        ),
      ),
    );

    titleCtrl.dispose();
    descCtrl.dispose();

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.videoEditSuccess), backgroundColor: AppTheme.success),
      );
    }
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
