import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/music_models.dart';
import '../services/library_service.dart';
import '../utils/app_theme.dart';

/// Library screen showing albums and artists.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final musicProvider = context.read<MusicProvider>();
    // Try to load local songs from MediaStore first
    if (musicProvider.localTracks.isEmpty && !musicProvider.isScanningLibrary) {
      await musicProvider.scanDeviceLibrary();
    }
    if (musicProvider.albums.isEmpty) {
      await musicProvider.fetchAlbums(refresh: true);
    }
    if (musicProvider.artists.isEmpty) {
      await musicProvider.fetchArtists(refresh: true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: SafeArea(
          child: Text(
            'Library',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(icon: Icon(Icons.music_note), text: 'Songs'),
            Tab(icon: Icon(Icons.album), text: 'Albums'),
            Tab(icon: Icon(Icons.person), text: 'Artists'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final musicProvider = context.read<MusicProvider>();
              musicProvider.scanDeviceLibrary();
              musicProvider.fetchAlbums(refresh: true);
              musicProvider.fetchArtists(refresh: true);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.deepSpaceGradient,
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _SongsTab(),
            _AlbumsTab(),
            _ArtistsTab(),
          ],
        ),
      ),
    );
  }
}

/// Songs tab showing list of discovered songs from MediaStore.
class _SongsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        if (musicProvider.isScanningLibrary && musicProvider.localTracks.isEmpty) {
          return _buildScanningState(context, musicProvider);
        }

        if (musicProvider.localTracks.isEmpty) {
          return _buildEmptySongsState(context, musicProvider);
        }

        return _buildSongsList(context, musicProvider);
      },
    );
  }

  Widget _buildScanningState(BuildContext context, MusicProvider musicProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.sunsetGlowGradient,
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Scanning device library...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${musicProvider.totalFound} songs found',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySongsState(BuildContext context, MusicProvider musicProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.music_note,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No songs found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the scan button to discover music',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              musicProvider.scanDeviceLibrary();
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('Scan Device Library'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList(BuildContext context, MusicProvider musicProvider) {
    return RefreshIndicator(
      onRefresh: () => musicProvider.scanDeviceLibrary(),
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: musicProvider.localTracks.length,
        itemBuilder: (context, index) {
          final track = musicProvider.localTracks[index];
          return _LocalSongCard(track: track);
        },
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
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardDark.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Album artwork or icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppTheme.sunsetGlowGradient,
                    ),
                    child: track.artworkPath != null
                        ? Image.file(
                            File(track.artworkPath!),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.music_note, size: 32, color: Colors.white),
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
                      const SizedBox(height: 4),
                      Text(
                        track.displayAlbum,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white60,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Play button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.sunsetGlowGradient,
                    shape: BoxShape.circle,
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

/// Albums tab showing grid of albums.
class _AlbumsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        if (musicProvider.isLoadingAlbums && musicProvider.albums.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        if (musicProvider.albumsError != null) {
          return _buildErrorState(context, 'albums', musicProvider);
        }

        if (musicProvider.albums.isEmpty) {
          return _buildEmptyState(context, 'albums');
        }

        return _buildAlbumsGrid(context, musicProvider);
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String type, MusicProvider musicProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Error loading $type',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            type == 'albums' ? musicProvider.albumsError! : musicProvider.artistsError!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => type == 'albums'
                ? musicProvider.fetchAlbums(refresh: true)
                : musicProvider.fetchArtists(refresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              type == 'albums' ? Icons.album : Icons.person,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No ${type} found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${type == 'albums' ? 'Albums' : 'Artists'} will appear here when available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsGrid(BuildContext context, MusicProvider musicProvider) {
    return RefreshIndicator(
      onRefresh: () => musicProvider.fetchAlbums(refresh: true),
      color: AppTheme.primaryColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: musicProvider.albums.length,
        itemBuilder: (context, index) {
          final album = musicProvider.albums[index];
          return _AlbumCard(album: album);
        },
      ),
    );
  }
}

/// Artists tab showing list of artists.
class _ArtistsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        if (musicProvider.isLoadingArtists && musicProvider.artists.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        if (musicProvider.artistsError != null) {
          return _buildErrorState(context, 'artists', musicProvider);
        }

        if (musicProvider.artists.isEmpty) {
          return _buildEmptyState(context, 'artists');
        }

        return _buildArtistsList(context, musicProvider);
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String type, MusicProvider musicProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Error loading $type',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            musicProvider.artistsError!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => musicProvider.fetchArtists(refresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No $type found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Artists will appear here when available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsList(BuildContext context, MusicProvider musicProvider) {
    return RefreshIndicator(
      onRefresh: () => musicProvider.fetchArtists(refresh: true),
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: musicProvider.artists.length,
        itemBuilder: (context, index) {
          final artist = musicProvider.artists[index];
          return _ArtistCard(artist: artist);
        },
      ),
    );
  }
}

/// Album card widget displaying album information.
class _AlbumCard extends StatelessWidget {
  final Album album;

  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Album: ${album.title}'),
              duration: const Duration(seconds: 2),
              backgroundColor: AppTheme.cardDark,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album cover
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.sunsetGlowGradient,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: album.coverUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          album.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.album,
                              size: 48,
                              color: Colors.white60,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.album,
                        size: 48,
                        color: Colors.white60,
                      ),
              ),
            ),
            // Album info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    album.mainArtistName ?? 'Various Artists',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Artist card widget displaying artist information.
class _ArtistCard extends StatelessWidget {
  final Artist artist;

  const _ArtistCard({required this.artist});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Artist: ${artist.name}'),
                duration: const Duration(seconds: 2),
                backgroundColor: AppTheme.cardDark,
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardDark.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Artist image
                CircleAvatar(
                  radius: 35,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  backgroundImage: artist.imageUrl != null
                      ? NetworkImage(artist.imageUrl!)
                      : null,
                  child: artist.imageUrl == null
                      ? const Icon(Icons.person, size: 35, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                // Artist info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${artist.albumCount} albums • ${artist.songCount} songs',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
