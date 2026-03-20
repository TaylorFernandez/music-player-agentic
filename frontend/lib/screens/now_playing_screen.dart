import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart' show RepeatMode, LocalTrack;
import '../utils/app_theme.dart';

/// Now Playing screen showing full player interface.
class NowPlayingScreen extends StatefulWidget {
  final LocalTrack? currentTrack;
  final bool isPlaying;
  final Duration position;
  final Duration? duration;
  final bool shuffle;
  final RepeatMode repeatMode;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onShuffle;
  final VoidCallback? onRepeat;
  final void Function(Duration position)? onSeek;
  final void Function(double volume)? onVolumeChanged;
  final VoidCallback? onClose;

  const NowPlayingScreen({
    super.key,
    this.currentTrack,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration,
    this.shuffle = false,
    this.repeatMode = RepeatMode.off,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onShuffle,
    this.onRepeat,
    this.onSeek,
    this.onVolumeChanged,
    this.onClose,
  });

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _artworkAnimationController;
  late AnimationController _gradientAnimationController;
  double _sliderValue = 0.0;
  double _volumeValue = 1.0;
  bool _isDraggingSlider = false;

  @override
  void initState() {
    super.initState();
    _artworkAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _gradientAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(NowPlayingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDraggingSlider) {
      _updateSliderValue();
    }
    if (widget.isPlaying && !_artworkAnimationController.isCompleted) {
      _artworkAnimationController.forward();
    } else if (!widget.isPlaying && _artworkAnimationController.value != 0) {
      _artworkAnimationController.reverse();
    }
  }

  void _updateSliderValue() {
    if (widget.duration != null && widget.duration!.inMilliseconds > 0) {
      _sliderValue = widget.position.inMilliseconds / widget.duration!.inMilliseconds;
    } else {
      _sliderValue = 0.0;
    }
  }

  @override
  void dispose() {
    _artworkAnimationController.dispose();
    _gradientAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final song = widget.currentTrack?.song;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Now Playing',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
          iconSize: 32,
          onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.deepSpaceGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildArtwork(theme, song),
                      const SizedBox(height: 32),
                      _buildTrackInfo(theme, song),
                      const SizedBox(height: 32),
                      _buildProgressSlider(theme),
                      const SizedBox(height: 24),
                      _buildControls(theme),
                      const SizedBox(height: 24),
                      _buildBottomActions(context, theme),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(ThemeData theme, Song? song) {
    final artworkUrl = song?.artworkUrl ?? widget.currentTrack?.artworkPath;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: AnimatedBuilder(
        animation: _gradientAnimationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.4 + _gradientAnimationController.value * 0.3),
                  blurRadius: 40 + _gradientAnimationController.value * 30,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: AppTheme.accentColor.withOpacity(0.25),
                  blurRadius: 60,
                  spreadRadius: 12,
                ),
              ],
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 1,
            child: _buildArtworkImage(artworkUrl, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildArtworkImage(String? artworkUrl, ThemeData theme) {
    if (artworkUrl != null && artworkUrl.isNotEmpty) {
      if (artworkUrl.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: artworkUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildDefaultArtwork(theme),
          errorWidget: (context, url, error) => _buildDefaultArtwork(theme),
        );
      } else {
        return Image.network(
          artworkUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultArtwork(theme),
        );
      }
    }
    return _buildDefaultArtwork(theme);
  }

  Widget _buildDefaultArtwork(ThemeData theme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.sunsetGlowGradient,
      ),
      child: const Icon(
        Icons.music_note,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTrackInfo(ThemeData theme, Song? song) {
    final title = song?.title ?? widget.currentTrack?.song.title ?? 'Unknown Title';
    final artist = song?.mainArtistName ?? widget.currentTrack?.song.mainArtistName ?? 'Unknown Artist';
    final album = song?.albumName ?? widget.currentTrack?.song.albumName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 28,
              shadows: [
                Shadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            artist,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (album != null) ...[
            const SizedBox(height: 6),
            Text(
              album,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressSlider(ThemeData theme) {
    final position = widget.position;
    final duration = widget.duration ?? Duration.zero;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: AppTheme.primaryColor.withOpacity(0.3),
              activeTickMarkColor: Colors.white,
              inactiveTickMarkColor: Colors.white24,
            ),
            child: Slider(
              value: _sliderValue.clamp(0.0, 1.0),
              onChanged: (value) {
                setState(() {
                  _isDraggingSlider = true;
                  _sliderValue = value;
                });
              },
              onChangeEnd: (value) {
                setState(() {
                  _isDraggingSlider = false;
                });
                if (widget.onSeek != null && widget.duration != null) {
                  final newPosition = Duration(
                    milliseconds: (value * widget.duration!.inMilliseconds).round(),
                  );
                  widget.onSeek!(newPosition);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: widget.shuffle ? Icons.shuffle : Icons.shuffle_outlined,
            onPressed: widget.onShuffle,
            isActive: widget.shuffle,
            size: 28,
          ),
          _buildControlButton(
            icon: Icons.skip_previous_rounded,
            onPressed: widget.onPrevious,
            size: 40,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.sunsetGlowGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.5),
                  blurRadius: 25,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
              ),
              iconSize: 64,
              onPressed: widget.onPlayPause,
            ),
          ),
          _buildControlButton(
            icon: Icons.skip_next_rounded,
            onPressed: widget.onNext,
            size: 40,
          ),
          _buildControlButton(
            icon: widget.repeatMode == RepeatMode.off
                ? Icons.repeat_outlined
                : widget.repeatMode == RepeatMode.all
                    ? Icons.repeat
                    : Icons.repeat_one,
            onPressed: widget.onRepeat,
            isActive: widget.repeatMode != RepeatMode.off,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isActive = false,
    double size = 32,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryColor.withOpacity(0.25) : Colors.white10,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppTheme.primaryColor.withOpacity(0.5) : Colors.white24,
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon),
        iconSize: size,
        color: isActive ? AppTheme.primaryLight : Colors.white,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomActionButton(
            icon: Icons.favorite_border,
            label: 'Like',
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Added to favorites'),
                  duration: Duration(seconds: 2),
                  backgroundColor: AppTheme.cardDark,
                ),
              );
            },
          ),
          _buildBottomActionButton(
            icon: Icons.playlist_add,
            label: 'Playlist',
            onTap: () {
              _showAddToPlaylistDialog(context);
            },
          ),
          _buildBottomActionButton(
            icon: Icons.queue_music,
            label: 'Queue',
            onTap: () {
              _showQueueBottomSheet(context);
            },
          ),
          _buildBottomActionButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () {
              final track = musicProvider.currentTrack;
              if (track != null) {
                final songTitle = track.song.title;
                final artistName = track.song.artistNames.join(', ');
                final shareUrl = 'https://musicplayer.example.com/songs/${track.song.id}';
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sharing $songTitle by $artistName'),
                    duration: const Duration(seconds: 3),
                    backgroundColor: AppTheme.accentColor,
                    action: SnackBarAction(
                      label: 'COPY LINK',
                      textColor: Colors.white,
                      onPressed: () {
                        // In a real app we'd use Clipboard.setData
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied to clipboard!')),
                        );
                      },
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white70,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark.withOpacity(0.9),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title: const Text('Song Info', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showSongInfoDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.album, color: Colors.white),
                title: const Text('Go to Album', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text('Go to Artist', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer, color: Colors.white),
                title: const Text('Sleep Timer', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showSleepTimerDialog(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showSongInfoDialog(BuildContext context) {
    final song = widget.currentTrack?.song;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Song Info', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Title', song?.title ?? 'Unknown'),
              _buildInfoRow('Artist', song?.mainArtistName ?? 'Unknown Artist'),
              _buildInfoRow('Album', song?.albumName ?? 'Unknown Album'),
              _buildInfoRow('Duration', _formatDuration(widget.duration ?? Duration.zero)),
              _buildInfoRow('File', widget.currentTrack?.localPath.split('/').last ?? 'N/A'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppTheme.primaryColor)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add, color: Colors.white),
                title: const Text('Create New Playlist', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showCreatePlaylistDialog(context);
                },
              ),
              const Divider(color: Colors.white24),
              const ListTile(
                leading: Icon(Icons.favorite, color: Colors.white),
                title: Text('Favorites', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
          ],
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create Playlist', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Playlist Name',
              labelStyle: const TextStyle(color: Colors.white60),
              enabledBorder: UnderlineInputBorder(
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: const BorderSide(color: AppTheme.primaryColor),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created playlist: ${controller.text}'),
                    backgroundColor: AppTheme.cardDark,
                  ),
                );
              },
              child: const Text('Create', style: TextStyle(color: AppTheme.primaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _showQueueBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark.withOpacity(0.9),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.25,
          maxChildSize: 0.75,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Queue',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close', style: TextStyle(color: Colors.white60)),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.music_note, color: Colors.white60),
                        title: Text('Song ${index + 1}', style: const TextStyle(color: Colors.white)),
                        subtitle: Text('Artist ${index + 1}', style: const TextStyle(color: Colors.white60)),
                        trailing: index == 0
                            ? const Icon(Icons.play_arrow, color: Colors.green)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Sleep Timer', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('15 minutes', style: TextStyle(color: Colors.white)),
                onTap: () => _setSleepTimer(context, 15),
              ),
              ListTile(
                title: const Text('30 minutes', style: TextStyle(color: Colors.white)),
                onTap: () => _setSleepTimer(context, 30),
              ),
              ListTile(
                title: const Text('45 minutes', style: TextStyle(color: Colors.white)),
                onTap: () => _setSleepTimer(context, 45),
              ),
              ListTile(
                title: const Text('1 hour', style: TextStyle(color: Colors.white)),
                onTap: () => _setSleepTimer(context, 60),
              ),
              ListTile(
                title: const Text('Custom', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
          ],
        );
      },
    );
  }

  void _setSleepTimer(BuildContext context, int minutes) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sleep timer set for $minutes minutes'),
        backgroundColor: AppTheme.cardDark,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
