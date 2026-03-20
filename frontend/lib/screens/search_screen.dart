import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/song.dart';
import '../utils/app_theme.dart';

/// Search screen for finding songs, albums, and artists.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'songs', 'albums', 'artists'

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      context.read<MusicProvider>().clearSearch();
      return;
    }

    setState(() {
      _searchQuery = query;
    });

    context.read<MusicProvider>().searchSongs(query);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchQuery = '';
    context.read<MusicProvider>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: SafeArea(
          child: Text(
            'Search',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.deepSpaceGradient,
        ),
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search songs, albums, artists...',
                  hintStyle: TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.cardDark.withOpacity(0.8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onSubmitted: _performSearch,
                textInputAction: TextInputAction.search,
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Songs', 'songs'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Albums', 'albums'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Artists', 'artists'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Search results
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: AppTheme.cardDark.withOpacity(0.6),
      selectedColor: AppTheme.primaryColor.withOpacity(0.3),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.white24,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return _buildEmptyState();
    }

    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        if (musicProvider.isSearching) {
          return _buildLoadingState();
        }

        if (musicProvider.searchResults.isEmpty) {
          return _buildNoResultsState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: musicProvider.searchResults.length,
          itemBuilder: (context, index) {
            final song = musicProvider.searchResults[index];
            return _SearchResultCard(song: song);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.sunsetGlowGradient.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Search for music',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find your favorite songs, albums, and artists',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.sunsetGlowGradient,
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Searching...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
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
              Icons.search_off,
              size: 48,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Search result card widget.
class _SearchResultCard extends StatelessWidget {
  final Song song;

  const _SearchResultCard({required this.song});

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
                // Album artwork
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppTheme.sunsetGlowGradient,
                    ),
                    child: song.artworkUrl != null
                        ? Image.network(
                            song.artworkUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.music_note, size: 32, color: Colors.white);
                            },
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
                      const SizedBox(height: 4),
                      Text(
                        song.albumName ?? 'Unknown Album',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white60,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Duration and play button
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        song.formattedDuration,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppTheme.sunsetGlowGradient,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                        onPressed: () {
                          context.read<MusicProvider>().playSong(song);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
