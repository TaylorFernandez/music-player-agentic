import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/music_models.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/library_service.dart';

// Re-export RepeatMode from audio_player_service for convenience
export '../services/audio_player_service.dart' show RepeatMode;

/// Provider for managing music library and playback state.
/// Handles fetching songs, albums, artists from the API and
/// manages the current playback queue.
class MusicProvider extends ChangeNotifier {
  final ApiService? _apiService;
  final AudioPlayerService? _audioPlayerService;
  final LibraryService? _libraryService;

  // Music Library State
  List<Song> _songs = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];

  // Pagination State
  int _currentPage = 1;
  bool _hasMoreSongs = true;
  bool _hasMoreAlbums = true;
  bool _hasMoreArtists = true;

  // Playback State
  Song? _currentSong;
  LocalTrack? _currentLocalTrack;
  List<Song> _playlist = [];
  final List<LocalTrack> _localPlaylist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _shuffle = false;
  RepeatMode _repeatMode = RepeatMode.off;
  Duration _position = Duration.zero;
  Duration? _duration;

  // Loading States
  bool _isLoadingSongs = false;
  bool _isLoadingAlbums = false;
  bool _isLoadingArtists = false;
  bool _isLoadingMore = false;

  // Error States
  String? _songsError;
  String? _albumsError;
  String? _artistsError;

  // Search State
  String _searchQuery = '';
  List<Song> _searchResults = [];
  bool _isSearching = false;

  MusicProvider({
    ApiService? apiService,
    AudioPlayerService? audioPlayerService,
    LibraryService? libraryService,
  })  : _apiService = apiService,
        _audioPlayerService = audioPlayerService,
        _libraryService = libraryService {
    _initializeAudioPlayer();
  }

  /// Initialize audio player listeners
  void _initializeAudioPlayer() {
    final audioPlayer = _audioPlayerService;
    if (audioPlayer == null) return;

    // Listen to position changes
    audioPlayer.player.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    // Listen to duration changes
    audioPlayer.player.durationStream.listen((duration) {
      _duration = duration;
      notifyListeners();
    });

    // Listen to player state changes
    audioPlayer.player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
  }

  // Getters
  List<Song> get songs => _songs;
  List<Album> get albums => _albums;
  List<Artist> get artists => _artists;
  List<LocalTrackInfo> get localTracks => _libraryService?.tracks ?? [];
  List<LocalTrackInfo> get favorites => _libraryService?.favorites ?? [];
  List<UserPlaylist> get playlists => _libraryService?.playlists ?? [];
  Song? get currentSong => _currentSong;
  LocalTrack? get currentLocalTrack => _currentLocalTrack;
  List<Song> get playlist => _playlist;
  List<LocalTrack> get localPlaylist => _localPlaylist;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get shuffle => _shuffle;
  RepeatMode get repeatMode => _repeatMode;
  Duration get position => _position;
  Duration? get duration => _duration;
  bool get isLoadingSongs => _isLoadingSongs;
  bool get isLoadingAlbums => _isLoadingAlbums;
  bool get isLoadingArtists => _isLoadingArtists;
  bool get isLoadingMore => _isLoadingMore;
  String? get songsError => _songsError;
  String? get albumsError => _albumsError;
  String? get artistsError => _artistsError;
  String get searchQuery => _searchQuery;
  List<Song> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  bool get hasMoreSongs => _hasMoreSongs;
  bool get hasMoreAlbums => _hasMoreAlbums;
  bool get hasMoreArtists => _hasMoreArtists;
  bool get isScanningLibrary => _libraryService?.isScanning ?? false;
  double get scanProgress => _libraryService?.scanProgress ?? 0.0;
  int get totalFound => _libraryService?.totalFound ?? 0;
  int get totalScanned => _libraryService?.totalScanned ?? 0;

  // ============================================================
  // Song Methods
  // ============================================================

  /// Fetch paginated list of songs
  Future<void> fetchSongs({bool refresh = false}) async {
    if (_isLoadingSongs) return;

    if (refresh) {
      _currentPage = 1;
      _hasMoreSongs = true;
      _songs.clear();
    }

    _isLoadingSongs = true;
    _songsError = null;
    notifyListeners();

    try {
      if (_apiService == null) {
        throw Exception('API service not initialized');
      }

      final api = _apiService;
      final result = await api.fetchSongs(
        page: _currentPage,
        pageSize: 20,
      );

      if (result != null && result['data'] != null) {
        final List<dynamic> results = result['data']['results'] ?? [];
        final newSongs = results
            .map((json) => Song.fromJson(json as Map<String, dynamic>))
            .toList();

        if (refresh) {
          _songs = newSongs;
        } else {
          _songs.addAll(newSongs);
        }

        // Check if there are more pages
        _hasMoreSongs = result['data']['next'] != null;
        if (_hasMoreSongs) {
          _currentPage++;
        }
      } else {
        _hasMoreSongs = false;
      }
    } catch (e) {
      _songsError = 'Failed to load songs: ${e.toString()}';
      debugPrint('Error fetching songs: $e');
    } finally {
      _isLoadingSongs = false;
      notifyListeners();
    }
  }

  /// Fetch more songs (pagination)
  Future<void> fetchMoreSongs() async {
    if (_isLoadingMore || !_hasMoreSongs) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      await fetchSongs();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Fetch a single song by ID
  Future<Song?> fetchSong(int id) async {
    try {
      final api = _apiService;
      if (api == null) return null;
      return await api.fetchSong(id);
    } catch (e) {
      debugPrint('Error fetching song: $e');
      return null;
    }
  }

  /// Search songs by query
  Future<void> searchSongs(String query) async {
    if (query.isEmpty) {
      _searchResults.clear();
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchQuery = query;
    notifyListeners();

    try {
      if (_apiService == null) {
        throw Exception('API service not initialized');
      }

      final api = _apiService;
      final result = await api.fetchSongs(
        page: 1,
        pageSize: 50,
        search: query,
      );

      if (result != null && result['data'] != null) {
        final List<dynamic> results = result['data']['results'] ?? [];
        _searchResults = results
            .map((json) => Song.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error searching songs: $e');
      _searchResults.clear();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchQuery = '';
    _searchResults.clear();
    notifyListeners();
  }

  // ============================================================
  // Album Methods
  // ============================================================

  /// Fetch paginated list of albums
  Future<void> fetchAlbums({bool refresh = false}) async {
    if (_isLoadingAlbums) return;

    if (refresh) {
      _currentPage = 1;
      _hasMoreAlbums = true;
      _albums.clear();
    }

    _isLoadingAlbums = true;
    _albumsError = null;
    notifyListeners();

    try {
      if (_apiService == null) {
        throw Exception('API service not initialized');
      }

      final api = _apiService;
      final result = await api.fetchAlbums(
        page: _currentPage,
        pageSize: 20,
      );

      if (result != null && result['data'] != null) {
        final List<dynamic> results = result['data']['results'] ?? [];
        final newAlbums = results
            .map((json) => Album.fromJson(json as Map<String, dynamic>))
            .toList();

        if (refresh) {
          _albums = newAlbums;
        } else {
          _albums.addAll(newAlbums);
        }

        _hasMoreAlbums = result['data']['next'] != null;
        if (_hasMoreAlbums) {
          _currentPage++;
        }
      } else {
        _hasMoreAlbums = false;
      }
    } catch (e) {
      _albumsError = 'Failed to load albums: ${e.toString()}';
      debugPrint('Error fetching albums: $e');
    } finally {
      _isLoadingAlbums = false;
      notifyListeners();
    }
  }

  /// Fetch a single album by ID
  Future<Album?> fetchAlbum(int id) async {
    try {
      final api = _apiService;
      if (api == null) return null;
      return await api.fetchAlbum(id);
    } catch (e) {
      debugPrint('Error fetching album: $e');
      return null;
    }
  }

  // ============================================================
  // Artist Methods
  // ============================================================

  /// Fetch paginated list of artists
  Future<void> fetchArtists({bool refresh = false}) async {
    if (_isLoadingArtists) return;

    if (refresh) {
      _currentPage = 1;
      _hasMoreArtists = true;
      _artists.clear();
    }

    _isLoadingArtists = true;
    _artistsError = null;
    notifyListeners();

    try {
      if (_apiService == null) {
        throw Exception('API service not initialized');
      }

      final api = _apiService;
      final result = await api.fetchArtists(
        page: _currentPage,
        pageSize: 20,
      );

      if (result != null && result['data'] != null) {
        final List<dynamic> results = result['data']['results'] ?? [];
        final newArtists = results
            .map((json) => Artist.fromJson(json as Map<String, dynamic>))
            .toList();

        if (refresh) {
          _artists = newArtists;
        } else {
          _artists.addAll(newArtists);
        }

        _hasMoreArtists = result['data']['next'] != null;
        if (_hasMoreArtists) {
          _currentPage++;
        }
      } else {
        _hasMoreArtists = false;
      }
    } catch (e) {
      _artistsError = 'Failed to load artists: ${e.toString()}';
      debugPrint('Error fetching artists: $e');
    } finally {
      _isLoadingArtists = false;
      notifyListeners();
    }
  }

  /// Fetch a single artist by ID
  Future<ArtistDetail?> fetchArtist(int id) async {
    try {
      final api = _apiService;
      if (api == null) return null;
      return await api.fetchArtist(id);
    } catch (e) {
      debugPrint('Error fetching artist: $e');
      return null;
    }
  }

  // ============================================================
  // Playback Methods
  // ============================================================

  /// Set current song
  void setCurrentSong(Song song) {
    _currentSong = song;
    notifyListeners();
  }

  /// Play a local track from file system
  Future<void> playLocalFile(String filePath) async {
    final audioPlayer = _audioPlayerService;
    if (audioPlayer == null) return;

    final track = _libraryService?.getTrackByPath(filePath);
    if (track == null) return;

    await audioPlayer.playTrack(0);
    _currentLocalTrack = LocalTrack(
      song: Song(
        id: track.serverSongId ?? 0,
        title: track.title ?? track.fileName,
        duration: track.duration ?? 0,
        fileHash: track.fileHash,
        createdAt: track.addedAt,
        updatedAt: track.lastModified,
      ),
      localPath: track.filePath,
      artworkPath: track.artworkPath,
    );
    _isPlaying = true;
    notifyListeners();
  }

  /// Scan local library for music files using MediaStore (automatic discovery).
  /// Discovers all songs from the device's internal music database.
  Future<List<LocalTrackInfo>> scanDeviceLibrary({
    bool matchWithServer = true,
    void Function(int current, int total, String path)? onProgress,
  }) async {
    final library = _libraryService;
    if (library == null) return [];
    final tracks = await library.scanDeviceLibrary(
      matchWithServer: matchWithServer,
      onProgress: onProgress,
    );

    // Sync with server if logged in
    await syncLibrary();

    notifyListeners();
    return tracks;
  }

  /// Scan local library for music files from a specific directory
  Future<List<LocalTrackInfo>> scanLibrary(
    String directoryPath, {
    bool recursive = true,
    bool matchWithServer = true,
    void Function(int current, int total, String path)? onProgress,
  }) async {
    final library = _libraryService;
    if (library == null) return [];
    final tracks = await library.scanDirectory(
      directoryPath,
      recursive: recursive,
      matchWithServer: matchWithServer,
      onProgress: onProgress,
    );

    // Sync with server if logged in
    await syncLibrary();

    notifyListeners();
    return tracks;
  }

  /// Sync local library with the server.
  Future<Map<String, dynamic>> syncLibrary() async {
    final library = _libraryService;
    if (library == null) return {'success': false, 'error': 'Library service not initialized'};

    final result = await library.syncWithServer();
    if (result['success'] == true) {
      notifyListeners();
    }
    return result;
  }

  /// Get all discovered local songs from MediaStore.
  List<LocalTrackInfo> getLocalSongs() {
    return _libraryService?.getDiscoveredSongs() ?? [];
  }

  /// Get discovered albums from MediaStore.
  Future<List<Map<String, dynamic>>> getLocalAlbums() async {
    return await _libraryService?.getDiscoveredAlbums() ?? [];
  }

  /// Get discovered artists from MediaStore.
  Future<List<Map<String, dynamic>>> getLocalArtists() async {
    return await _libraryService?.getDiscoveredArtists() ?? [];
  }

  /// Check if device library has been scanned.
  bool get hasScannedDeviceLibrary => _libraryService?.tracks.isNotEmpty == true;

  /// Get formatted position string (MM:SS)
  String get formattedPosition {
    final minutes = _position.inMinutes;
    final seconds = _position.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get formatted duration string (MM:SS)
  String get formattedDuration {
    if (_duration == null) return '--:--';
    final minutes = _duration!.inMinutes;
    final seconds = _duration!.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get playback progress (0.0 to 1.0)
  double get progress {
    if (_duration == null || _duration!.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration!.inMilliseconds;
  }

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    final audioPlayer = _audioPlayerService;
    if (audioPlayer == null) return;
    await audioPlayer.seek(position);
    _position = position;
    notifyListeners();
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    final audioPlayer = _audioPlayerService;
    if (audioPlayer == null) return;
    await audioPlayer.setVolume(volume);
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    final audioPlayer = _audioPlayerService;
    if (audioPlayer == null) return;
    await audioPlayer.setSpeed(speed);
  }

  /// Play a specific song from the playlist
  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    if (playlist != null) {
      _playlist = playlist;
      _currentIndex = playlist.indexWhere((s) => s.id == song.id);
    } else if (!_playlist.contains(song)) {
      _playlist.insert(0, song);
      _currentIndex = 0;
    }

    _currentSong = song;
    _isPlaying = true;
    notifyListeners();
  }

  /// Pause playback
  Future<void> pause() async {
    final audioPlayer = _audioPlayerService;
    if (audioPlayer != null) {
      await audioPlayer.pause();
    }
    _isPlaying = false;
    notifyListeners();
  }

  /// Resume playback
  Future<void> resume() async {
    final audioPlayer = _audioPlayerService;
    if (audioPlayer != null) {
      await audioPlayer.play();
    } else if (_currentSong != null) {
      _isPlaying = true;
      notifyListeners();
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_currentSong == null) {
      if (_songs.isNotEmpty) {
        await playSong(_songs.first, playlist: _songs);
      }
    } else if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Play next song in playlist
  Future<void> next() async {
    final audioPlayer = _audioPlayerService;
    if (audioPlayer != null) {
      await audioPlayer.next();
      _updateCurrentTrack();
      return;
    }

    if (_playlist.isEmpty || _currentIndex < 0) return;

    if (_shuffle) {
      // Shuffle mode: play random song
      final randomIndex = (_currentIndex + 1) % _playlist.length;
      _currentIndex = randomIndex;
    } else {
      // Normal mode: play next song
      _currentIndex++;

      if (_currentIndex >= _playlist.length) {
        if (_repeatMode == RepeatMode.all) {
          _currentIndex = 0;
        } else {
          _currentIndex = _playlist.length - 1;
          _isPlaying = false;
        }
      }
    }

    if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
      _currentSong = _playlist[_currentIndex];
      notifyListeners();
    }
  }

  /// Play previous song in playlist
  Future<void> previous() async {
    final audioPlayer = _audioPlayerService;
    if (audioPlayer != null) {
      await audioPlayer.previous();
      _updateCurrentTrack();
      return;
    }

    if (_playlist.isEmpty || _currentIndex < 0) return;

    _currentIndex--;

    if (_currentIndex < 0) {
      if (_repeatMode == RepeatMode.all) {
        _currentIndex = _playlist.length - 1;
      } else {
        _currentIndex = 0;
      }
    }

    _currentSong = _playlist[_currentIndex];
    notifyListeners();
  }

  /// Update current track from audio player
  void _updateCurrentTrack() {
    final audioPlayer = _audioPlayerService;
    if (audioPlayer == null) return;

    final track = audioPlayer.currentTrack;
    if (track != null) {
      _currentLocalTrack = track;
      _currentSong = track.song;
      notifyListeners();
    }
  }

  /// Toggle shuffle mode
  Future<void> toggleShuffle() async {
    final audioPlayer = _audioPlayerService;
    if (audioPlayer != null) {
      await audioPlayer.toggleShuffle();
    }
    _shuffle = !_shuffle;
    notifyListeners();
  }

  /// Toggle repeat mode
  void toggleRepeat() {
    final audioPlayer = _audioPlayerService;
    if (audioPlayer != null) {
      audioPlayer.toggleRepeat();
      _repeatMode = audioPlayer.repeatMode;
    } else {
      switch (_repeatMode) {
        case RepeatMode.off:
          _repeatMode = RepeatMode.one;
          break;
        case RepeatMode.one:
          _repeatMode = RepeatMode.all;
          break;
        case RepeatMode.all:
          _repeatMode = RepeatMode.off;
          break;
      }
    }
    notifyListeners();
  }

  /// Clear current playlist
  Future<void> clearPlaylist() async {
    final audioPlayer = _audioPlayerService;
    if (audioPlayer != null) {
      audioPlayer.clearPlaylist();
    }
    _playlist.clear();
    _localPlaylist.clear();
    _currentIndex = -1;
    _currentSong = null;
    _currentLocalTrack = null;
    _isPlaying = false;
    notifyListeners();
  }

  /// Add song to playlist
  void addToPlaylist(Song song) {
    if (!_playlist.contains(song)) {
      _playlist.add(song);
      notifyListeners();
    }
  }

  /// Remove song from playlist
  void removeFromPlaylist(int index) {
    if (index >= 0 && index < _playlist.length) {
      _playlist.removeAt(index);

      if (_currentIndex >= index) {
        _currentIndex--;
      }

      if (_playlist.isEmpty) {
        _currentSong = null;
        _isPlaying = false;
      } else if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
        _currentSong = _playlist[_currentIndex];
      }

      notifyListeners();
    }
  }

  // ============================================================
  // Utility Methods
  // ============================================================

  /// Clear all errors
  void clearErrors() {
    _songsError = null;
    _albumsError = null;
    _artistsError = null;
    notifyListeners();
  }

  /// Reset all state
  void reset() {
    _songs.clear();
    _albums.clear();
    _artists.clear();
    _currentSong = null;
    _currentLocalTrack = null;
    _playlist.clear();
    _localPlaylist.clear();
    _currentIndex = -1;
    _isPlaying = false;
    _shuffle = false;
    _repeatMode = RepeatMode.off;
    _position = Duration.zero;
    _duration = null;
    _currentPage = 1;
    _hasMoreSongs = true;
    _hasMoreAlbums = true;
    _hasMoreArtists = true;
    _searchQuery = '';
    _searchResults.clear();
    clearErrors();
    notifyListeners();
  }

  /// Dispose of resources
  @override
  void dispose() {
    _audioPlayerService?.dispose();
    super.dispose();
  }
}
