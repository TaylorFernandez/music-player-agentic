import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/audio_player_service.dart';

/// Mini player widget that displays at the bottom of the screen.
/// Shows current track info and basic playback controls.
class MiniPlayerWidget extends StatelessWidget {
  final LocalTrack? currentTrack;
  final bool isPlaying;
  final Duration position;
  final Duration? duration;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onTap;

  const MiniPlayerWidget({
    super.key,
    this.currentTrack,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final progress = duration != null && duration!.inMilliseconds > 0
        ? position.inMilliseconds / duration!.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              minHeight: 2,
            ),

            // Player content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // Artwork
                  _buildArtwork(theme),

                  const SizedBox(width: 12),

                  // Track info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentTrack!.song.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (currentTrack!.song.mainArtistName != null)
                          Text(
                            currentTrack!.song.mainArtistName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Playback controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: onPrevious,
                        iconSize: 24,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: onPlayPause,
                        iconSize: 32,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: onNext,
                        iconSize: 24,
                        visualDensity: VisualDensity.compact,
                      ),
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

  Widget _buildArtwork(ThemeData theme) {
    final artworkUrl = currentTrack?.song.artworkUrl;
    final localArtworkPath = currentTrack?.artworkPath;

    Widget artwork;

    if (artworkUrl != null && artworkUrl.isNotEmpty) {
      artwork = CachedNetworkImage(
        imageUrl: artworkUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 48,
          height: 48,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.music_note,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        errorWidget: (context, url, error) => _buildDefaultArtwork(theme),
      );
    } else if (localArtworkPath != null && localArtworkPath.isNotEmpty) {
      artwork = Image.network(
        localArtworkPath,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultArtwork(theme),
      );
    } else {
      artwork = _buildDefaultArtwork(theme);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: artwork,
    );
  }

  Widget _buildDefaultArtwork(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note,
        color: theme.colorScheme.onSurfaceVariant,
        size: 24,
      ),
    );
  }
}
