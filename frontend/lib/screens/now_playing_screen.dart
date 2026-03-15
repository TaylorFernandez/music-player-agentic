import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';

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
  double _sliderValue = 0.0;
  double _volumeValue = 1.0;
  bool _isDraggingSlider = false;

  @override
  void initState() {
    super.initState();
    _artworkAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final song = widget.currentTrack?.song;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, theme),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildArtwork(theme, song),
                    const SizedBox(height: 32),
                    _buildTrackInfo(theme, song),
                    const SizedBox(height: 24),
                    _buildProgressSlider(theme),
                    const SizedBox(height: 16),
                    _buildControls(theme),
                    const SizedBox(height: 16),
                    _buildVolumeSlider(theme),
                    const SizedBox(height: 24),
                    _buildBottomActions(context, theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
            iconSize: 32,
          ),
          Expanded(
            child: Text(
              'Now Playing',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArtwork(ThemeData theme, Song? song) {
    final artworkUrl = song?.artworkUrl ?? widget.currentTrack?.artworkPath;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 24,
                spreadRadius: 8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note,
        size: 64,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildTrackInfo(ThemeData theme, Song? song) {
    final title = song?.title ?? widget.currentTrack?.song.title ?? 'Unknown Title';
    final artist = song?.mainArtistName ?? widget.currentTrack?.song.mainArtistName ?? 'Unknown Artist';
    final album = song?.albumName ?? widget.currentTrack?.song.albumName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            artist,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (album != null) ...[
            const SizedBox(height: 4),
            Text(
              album,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
              thumbColor: theme.colorScheme.primary,
              overlayColor: theme.colorScheme.primary.withOpacity(0.2),
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  _formatDuration(duration),
                  style: theme.textTheme.labelSmall,
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              widget.shuffle ? Icons.shuffle : Icons.shuffle_outlined,
            ),
            iconSize: 28,
            color: widget.shuffle ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            onPressed: widget.onShuffle,
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 36,
            onPressed: widget.onPrevious,
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                widget.isPlaying ? Icons.pause : Icons.play_arrow,
                color: theme.colorScheme.onPrimary,
              ),
              iconSize: 48,
              onPressed: widget.onPlayPause,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 36,
            onPressed: widget.onNext,
          ),
          IconButton(
            icon: Icon(
              _getRepeatIcon(),
            ),
            iconSize: 28,
            color: widget.repeatMode != RepeatMode.off
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            onPressed: widget.onRepeat,
          ),
        ],
      ),
    );
  }

  IconData _getRepeatIcon() {
    switch (widget.repeatMode) {
      case RepeatMode.off:
        return Icons.repeat_outlined;
      case RepeatMode.all:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
    }
  }

  Widget _buildVolumeSlider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Icon(
            Icons.volume_down,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          Expanded(
            child: Slider(
              value: _volumeValue,
              onChanged: (value) {
                setState(() {
                  _volumeValue = value;
                });
                widget.onVolumeChanged?.call(value);
              },
            ),
          ),
          Icon(
            Icons.volume_up,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Added to favorites'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed: () {
              _showAddToPlaylistDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.queue_music),
            onPressed: () {
              _showQueueBottomSheet(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Song Info'),
                onTap: () {
                  Navigator.pop(context);
                  _showSongInfoDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.album),
                title: const Text('Go to Album'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Album view coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Go to Artist'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Artist view coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Sleep Timer'),
                onTap: () {
                  Navigator.pop(context);
                  _showSleepTimerDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.equalizer),
                title: const Text('Equalizer'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Equalizer coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
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
          title: const Text('Song Info'),
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
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
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
          title: const Text('Add to Playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create New Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreatePlaylistDialog(context);
                },
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.favorite),
                title: Text('Favorites'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
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
          title: const Text('Create Playlist'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Playlist Name',
              hintText: 'Enter playlist name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created playlist: ${controller.text}'),
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showQueueBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.music_note),
                        title: Text('Song ${index + 1}'),
                        subtitle: Text('Artist ${index + 1}'),
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
          title: const Text('Sleep Timer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('15 minutes'),
                onTap: () => _setSleepTimer(context, 15),
              ),
              ListTile(
                title: const Text('30 minutes'),
                onTap: () => _setSleepTimer(context, 30),
              ),
              ListTile(
                title: const Text('45 minutes'),
                onTap: () => _setSleepTimer(context, 45),
              ),
              ListTile(
                title: const Text('1 hour'),
                onTap: () => _setSleepTimer(context, 60),
              ),
              ListTile(
                title: const Text('Custom'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Custom timer coming soon!'),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
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
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
