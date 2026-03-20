import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/song.dart';
import '../services/library_service.dart';
import '../utils/app_theme.dart';
import 'library_screen.dart';

/// Home screen showing recently played songs and recommendations.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isShowingScanOverlay = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final musicProvider = context.read<MusicProvider>();

    // Auto-scan device library if local tracks are empty
    if (musicProvider.localTracks.isEmpty && !musicProvider.isScanningLibrary) {
      setState(() => _isShowingScanOverlay = true);
      await musicProvider.scanDeviceLibrary();
      setState(() => _isShowingScanOverlay = false);
    }

    // Also fetch songs from server if empty
    if (musicProvider.songs.isEmpty) {
      await musicProvider.fetchSongs(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: SafeArea(
              child: Text(
                'Music Player',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  foreground: Paint()..shader = AppTheme.auroraGradient.createShader(
                    const Rect.fromLTWH(0, 0, 200, 70),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: () {
                  context.read<MusicProvider>().scanDeviceLibrary();
                  context.read<MusicProvider>().fetchSongs(refresh: true);
                },
              ),
            ],
          ),
          body: Consumer<MusicProvider>(
            builder: (context, musicProvider, child) {
              if (musicProvider.isLoadingSongs && musicProvider.songs.isEmpty && musicProvider.localTracks.isEmpty) {
                return _buildLoadingState(context);
              }

              if (musicProvider.songsError != null) {
                return _buildErrorState(context, musicProvider);
              }

              if (musicProvider.songs.isEmpty && musicProvider.localTracks.isEmpty) {
                return _buildEmptyState(context, musicProvider);
              }

              return _buildContent(context, musicProvider);
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              // Navigate to Library tab via bottom navigation
              // Navigate to Library tab via bottom navigation
              // Find the MainScreen state by looking for any state with bottom navigation
              final navigator = Navigator.of(context);
              // Go back to home and then navigate to library
              // Alternative: use a callback or event system
              // For now, just navigate to the library screen directly
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LibraryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.library_music),
            label: const Text('Library'),
            backgroundColor: AppTheme.primaryColor,
          ),
        ),
        // Scan overlay
        if (_isShowingScanOverlay)
          _buildScanOverlay(context),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.deepSpaceGradient,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.sunsetGlowGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Loading your music...',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, MusicProvider musicProvider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.deepSpaceGradient,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.errorColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline,
                size: 56,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error loading songs',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                musicProvider.songsError!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => musicProvider.fetchSongs(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, MusicProvider musicProvider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.deepSpaceGradient,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.auroraGradient.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.library_music,
                size: 64,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No songs found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add some music to get started!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                musicProvider.scanDeviceLibrary();
              },
              icon: const Icon(Icons.folder_open, size: 28),
              label: const Text('Scan Device Library'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanOverlay(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.deepSpaceGradient,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: AppTheme.sunsetGlowGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Discovering your music...',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Consumer<MusicProvider>(
              builder: (context, mp, _) => Text(
                '${mp.totalFound} songs found',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MusicProvider musicProvider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.deepSpaceGradient,
      ),
      child: RefreshIndicator(
        onRefresh: () => Future.wait([
          musicProvider.scanDeviceLibrary(),
          musicProvider.fetchSongs(refresh: true),
        ]),
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      musicProvider.localTracks.isNotEmpty
                          ? 'Your Music'
                          : 'Recently Played',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${musicProvider.localTracks.isNotEmpty ? musicProvider.localTracks.length : musicProvider.songs.length} songs',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (musicProvider.localTracks.isNotEmpty) {
                      final track = musicProvider.localTracks[index];
                      return _LocalSongCard(track: track);
                    } else {
                      final song = musicProvider.songs[index];
                      return _SongCard(song: song);
                    }
                  },
                  childCount: musicProvider.localTracks.isNotEmpty
                      ? musicProvider.localTracks.length
                      : musicProvider.songs.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}

/// Local song card widget displaying discovered song information.
class _LocalSongCard extends StatelessWidget {
  final LocalTrackInfo track;

  const _LocalSongCard({required this.track});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final musicProvider = context.read<MusicProvider>();
            musicProvider.playLocalFile(track.filePath);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                // Album artwork or icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: AppTheme.sunsetGlowGradient,
                    ),
                    child: track.artworkPath != null
                        ? Image.file(
                            File(track.artworkPath!),
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.music_note, size: 35, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                // Song info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.displayTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.displayArtist,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          track.formattedDuration,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Play button
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppTheme.sunsetGlowGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    onPressed: () {
                      final musicProvider = context.read<MusicProvider>();
                      musicProvider.playLocalFile(track.filePath);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Song card widget displaying song information.
class _SongCard extends StatelessWidget {
  final Song song;

  const _SongCard({required this.song});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final musicProvider = context.read<MusicProvider>();
            musicProvider.playSong(song);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                // Album artwork
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: AppTheme.sunsetGlowGradient,
                    ),
                    child: song.artworkUrl != null
                        ? Image.network(
                            song.artworkUrl!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.music_note, size: 35, color: Colors.white);
                            },
                          )
                        : const Icon(Icons.music_note, size: 35, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                // Song info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.mainArtistName ?? 'Unknown Artist',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          song.formattedDuration,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Play button
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppTheme.sunsetGlowGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    onPressed: () {
                      final musicProvider = context.read<MusicProvider>();
                      musicProvider.playSong(song);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
