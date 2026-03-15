import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'metadata_service.dart';
import 'song_matching_service.dart';
import 'api_service.dart';

/// Model class representing a local track in the music library.
class LocalTrackInfo {
  final String filePath;
  final String fileName;
  final String? title;
  final String? artist;
  final String? album;
  final int? duration;
  final String? artworkPath;
  final String fileHash;
  final int fileSize;
  final DateTime lastModified;
  final DateTime addedAt;
  final int? serverSongId;
  final double? matchConfidence;
  final bool isFavorite;
  final int playCount;
  final DateTime? lastPlayedAt;

  LocalTrackInfo({
    required this.filePath,
    required this.fileName,
    this.title,
    this.artist,
    this.album,
    this.duration,
    this.artworkPath,
    required this.fileHash,
    required this.fileSize,
    required this.lastModified,
    required this.addedAt,
    this.serverSongId,
    this.matchConfidence,
    this.isFavorite = false,
    this.playCount = 0,
    this.lastPlayedAt,
  });

  /// Returns the display title (title or filename)
  String get displayTitle => title ?? fileName;

  /// Returns the display artist (artist or "Unknown Artist")
  String get displayArtist => artist ?? 'Unknown Artist';

  /// Returns the display album (album or "Unknown Album")
  String get displayAlbum => album ?? 'Unknown Album';

  /// Returns formatted duration (MM:SS)
  String get formattedDuration {
    if (duration == null) return '--:--';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Returns true if the track has a server match
  bool get hasServerMatch => serverSongId != null && matchConfidence != null && matchConfidence! >= 0.7;

  /// Creates a copy with updated fields
  LocalTrackInfo copyWith({
    String? filePath,
    String? fileName,
    String? title,
    String? artist,
    String? album,
    int? duration,
    String? artworkPath,
    String? fileHash,
    int? fileSize,
    DateTime? lastModified,
    DateTime? addedAt,
    int? serverSongId,
    double? matchConfidence,
    bool? isFavorite,
    int? playCount,
    DateTime? lastPlayedAt,
  }) {
    return LocalTrackInfo(
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      artworkPath: artworkPath ?? this.artworkPath,
      fileHash: fileHash ?? this.fileHash,
      fileSize: fileSize ?? this.fileSize,
      lastModified: lastModified ?? this.lastModified,
      addedAt: addedAt ?? this.addedAt,
      serverSongId: serverSongId ?? this.serverSongId,
      matchConfidence: matchConfidence ?? this.matchConfidence,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  /// Creates from extracted metadata
  factory LocalTrackInfo.fromMetadata(ExtractedMetadata metadata, {int? serverSongId, double? matchConfidence}) {
    return LocalTrackInfo(
      filePath: metadata.filePath,
      fileName: metadata.fileName,
      title: metadata.title,
      artist: metadata.artist,
      album: metadata.album,
      duration: metadata.duration,
      artworkPath: metadata.artwork?.isNotEmpty == true ? metadata.filePath : null,
      fileHash: metadata.fileHash,
      fileSize: metadata.fileSize,
      lastModified: metadata.lastModified,
      addedAt: DateTime.now(),
      serverSongId: serverSongId,
      matchConfidence: matchConfidence,
    );
  }

  /// Converts to a map for serialization
  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'fileName': fileName,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'artworkPath': artworkPath,
      'fileHash': fileHash,
      'fileSize': fileSize,
      'lastModified': lastModified.toIso8601String(),
      'addedAt': addedAt.toIso8601String(),
      'serverSongId': serverSongId,
      'matchConfidence': matchConfidence,
      'isFavorite': isFavorite,
      'playCount': playCount,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
    };
  }

  /// Creates from a map
  factory LocalTrackInfo.fromJson(Map<String, dynamic> json) {
    return LocalTrackInfo(
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      duration: json['duration'] as int?,
      artworkPath: json['artworkPath'] as String?,
      fileHash: json['fileHash'] as String,
      fileSize: json['fileSize'] as int,
      lastModified: DateTime.parse(json['lastModified'] as String),
      addedAt: DateTime.parse(json['addedAt'] as String),
      serverSongId: json['serverSongId'] as int?,
      matchConfidence: json['matchConfidence'] as double?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      playCount: json['playCount'] as int? ?? 0,
      lastPlayedAt: json['lastPlayedAt'] != null ? DateTime.parse(json['lastPlayedAt'] as String) : null,
    );
  }
}

/// Model class representing a user-created playlist.
class UserPlaylist {
  final String id;
  final String name;
  final String? description;
  final List<String> trackPaths;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPlaylist({
    required this.id,
    required this.name,
    this.description,
    this.trackPaths = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy with updated fields
  UserPlaylist copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? trackPaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      trackPaths: trackPaths ?? this.trackPaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts to a map for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'trackPaths': trackPaths,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates from a map
  factory UserPlaylist.fromJson(Map<String, dynamic> json) {
    return UserPlaylist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      trackPaths: List<String>.from(json['trackPaths'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Service for managing the local music library.
/// Handles scanning directories, caching metadata, and managing playlists.
class LibraryService extends ChangeNotifier {
  final MetadataService _metadataService;
  final SongMatchingService _songMatchingService;
  final ApiService? _apiService;

  // Library state
  final Map<String, LocalTrackInfo> _tracks = {};
  final Map<String, UserPlaylist> _playlists = {};
  final Set<String> _favoritePaths = {};

  // Scan state
  bool _isScanning = false;
  double _scanProgress = 0.0;
  String? _currentScanPath;
  int _totalScanned = 0;
  int _totalFound = 0;

  // Cached directories
  final List<String> _watchedDirectories = [];

  // Getters
  List<LocalTrackInfo> get tracks => _tracks.values.toList();
  List<LocalTrackInfo> get favorites => _tracks.values.where((t) => t.isFavorite).toList();
  List<UserPlaylist> get playlists => _playlists.values.toList();
  bool get isScanning => _isScanning;
  double get scanProgress => _scanProgress;
  String? get currentScanPath => _currentScanPath;
  int get totalScanned => _totalScanned;
  int get totalFound => _totalFound;
  List<String> get watchedDirectories => List.unmodifiable(_watchedDirectories);

  LibraryService({
    MetadataService? metadataService,
    SongMatchingService? songMatchingService,
    ApiService? apiService,
  })  : _metadataService = metadataService ?? MetadataService(),
        _songMatchingService = songMatchingService ?? SongMatchingService(apiService: apiService ?? ApiService()),
        _apiService = apiService;

  /// Initialize the library service
  Future<void> initialize() async {
    await _loadLibrary();
    await _loadPlaylists();
    await _loadFavorites();
  }

  /// Check and request storage permissions
  Future<bool> checkPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return true;
    }
    return true; // Desktop platforms don't need permission
  }

  /// Scan a directory for music files
  Future<List<LocalTrackInfo>> scanDirectory(
    String directoryPath, {
    bool recursive = true,
    bool matchWithServer = true,
    void Function(int current, int total, String path)? onProgress,
  }) async {
    if (_isScanning) {
      return [];
    }

    _isScanning = true;
    _scanProgress = 0.0;
    _totalScanned = 0;
    _totalFound = 0;
    notifyListeners();

    try {
      // Check permissions
      if (!await checkPermissions()) {
        _isScanning = false;
        notifyListeners();
        return [];
      }

      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        _isScanning = false;
        notifyListeners();
        return [];
      }

      // Get all audio files
      final files = <File>[];
      await for (final entity in directory.list(recursive: recursive)) {
        if (entity is File && _metadataService.isSupportedAudioFile(entity.path)) {
          files.add(entity);
        }
      }

      _totalFound = files.length;
      final results = <LocalTrackInfo>[];

      // Process each file
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        _currentScanPath = file.path;
        _scanProgress = (i + 1) / files.length;
        _totalScanned = i + 1;
        notifyListeners();

        onProgress?.call(i + 1, files.length, file.path);

        // Extract metadata
        final metadata = await _metadataService.extractMetadata(file);
        if (metadata == null) continue;

        // Check if we already have this track
        final existingTrack = _tracks[metadata.fileHash];
        if (existingTrack != null) {
          // Update existing track if file still exists
          if (await File(existingTrack.filePath).exists()) {
            results.add(existingTrack);
            continue;
          }
        }

        // Match with server if requested
        int? serverSongId;
        double? matchConfidence;

        if (matchWithServer && _apiService != null) {
          final matchResult = await _songMatchingService.matchMetadata(
            metadata: metadata,
            useServerLookup: true,
          );
          serverSongId = matchResult.matchedSong?.id;
          matchConfidence = matchResult.confidence;
        }

        // Create track info
        final trackInfo = LocalTrackInfo.fromMetadata(
          metadata,
          serverSongId: serverSongId,
          matchConfidence: matchConfidence,
        );

        // Add to library
        _tracks[metadata.fileHash] = trackInfo;
        results.add(trackInfo);
      }

      // Save updated library
      await _saveLibrary();

      // Add to watched directories if not already there
      if (!_watchedDirectories.contains(directoryPath)) {
        _watchedDirectories.add(directoryPath);
        await _saveWatchedDirectories();
      }

      _isScanning = false;
      _currentScanPath = null;
      notifyListeners();

      return results;
    } catch (e) {
      debugPrint('Error scanning directory: $e');
      _isScanning = false;
      _currentScanPath = null;
      notifyListeners();
      return [];
    }
  }

  /// Get a track by file hash
  LocalTrackInfo? getTrackByHash(String fileHash) {
    return _tracks[fileHash];
  }

  /// Get a track by file path
  LocalTrackInfo? getTrackByPath(String filePath) {
    for (final track in _tracks.values) {
      if (track.filePath == filePath) {
        return track;
      }
    }
    return null;
  }

  /// Get all tracks by artist
  List<LocalTrackInfo> getTracksByArtist(String artist) {
    return _tracks.values.where((track) {
      return track.artist?.toLowerCase().contains(artist.toLowerCase()) ?? false;
    }).toList();
  }

  /// Get all tracks by album
  List<LocalTrackInfo> getTracksByAlbum(String album) {
    return _tracks.values.where((track) {
      return track.album?.toLowerCase().contains(album.toLowerCase()) ?? false;
    }).toList();
  }

  /// Search tracks by query
  List<LocalTrackInfo> searchTracks(String query) {
    final normalizedQuery = query.toLowerCase();
    return _tracks.values.where((track) {
      return track.title?.toLowerCase().contains(normalizedQuery) ??
          track.artist?.toLowerCase().contains(normalizedQuery) ??
          track.album?.toLowerCase().contains(normalizedQuery) ??
          track.fileName.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String filePath) async {
    final track = getTrackByPath(filePath);
    if (track == null) return;

    final updatedTrack = track.copyWith(isFavorite: !track.isFavorite);
    _tracks[track.fileHash] = updatedTrack;

    if (updatedTrack.isFavorite) {
      _favoritePaths.add(filePath);
    } else {
      _favoritePaths.remove(filePath);
    }

    await _saveLibrary();
    await _saveFavorites();
    notifyListeners();
  }

  /// Increment play count
  Future<void> incrementPlayCount(String filePath) async {
    final track = getTrackByPath(filePath);
    if (track == null) return;

    final updatedTrack = track.copyWith(
      playCount: track.playCount + 1,
      lastPlayedAt: DateTime.now(),
    );
    _tracks[track.fileHash] = updatedTrack;

    await _saveLibrary();
    notifyListeners();
  }

  /// Create a new playlist
  Future<UserPlaylist> createPlaylist(String name, {String? description}) async {
    final playlist = UserPlaylist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      trackPaths: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _playlists[playlist.id] = playlist;
    await _savePlaylists();
    notifyListeners();

    return playlist;
  }

  /// Update a playlist
  Future<void> updatePlaylist(UserPlaylist playlist) async {
    final updatedPlaylist = playlist.copyWith(updatedAt: DateTime.now());
    _playlists[playlist.id] = updatedPlaylist;
    await _savePlaylists();
    notifyListeners();
  }

  /// Delete a playlist
  Future<void> deletePlaylist(String playlistId) async {
    _playlists.remove(playlistId);
    await _savePlaylists();
    notifyListeners();
  }

  /// Add track to playlist
  Future<void> addTrackToPlaylist(String playlistId, String filePath) async {
    final playlist = _playlists[playlistId];
    if (playlist == null) return;

    if (!playlist.trackPaths.contains(filePath)) {
      final updatedPaths = [...playlist.trackPaths, filePath];
      final updatedPlaylist = playlist.copyWith(
        trackPaths: updatedPaths,
        updatedAt: DateTime.now(),
      );
      _playlists[playlistId] = updatedPlaylist;
      await _savePlaylists();
      notifyListeners();
    }
  }

  /// Remove track from playlist
  Future<void> removeTrackFromPlaylist(String playlistId, String filePath) async {
    final playlist = _playlists[playlistId];
    if (playlist == null) return;

    final updatedPaths = playlist.trackPaths.where((path) => path != filePath).toList();
    final updatedPlaylist = playlist.copyWith(
      trackPaths: updatedPaths,
      updatedAt: DateTime.now(),
    );
    _playlists[playlistId] = updatedPlaylist;
    await _savePlaylists();
    notifyListeners();
  }

  /// Get tracks in a playlist
  List<LocalTrackInfo> getPlaylistTracks(String playlistId) {
    final playlist = _playlists[playlistId];
    if (playlist == null) return [];

    return playlist.trackPaths
        .map((path) => getTrackByPath(path))
        .whereType<LocalTrackInfo>()
        .toList();
  }

  /// Remove a track from the library
  Future<void> removeTrack(String filePath) async {
    final track = getTrackByPath(filePath);
    if (track == null) return;

    _tracks.remove(track.fileHash);
    _favoritePaths.remove(filePath);

    // Remove from all playlists
    for (final playlistId in _playlists.keys) {
      await removeTrackFromPlaylist(playlistId, filePath);
    }

    await _saveLibrary();
    await _saveFavorites();
    notifyListeners();
  }

  /// Clear the entire library
  Future<void> clearLibrary() async {
    _tracks.clear();
    _playlists.clear();
    _favoritePaths.clear();
    _watchedDirectories.clear();

    await _saveLibrary();
    await _savePlaylists();
    await _saveFavorites();
    await _saveWatchedDirectories();

    notifyListeners();
  }

  /// Rescan all watched directories
  Future<List<LocalTrackInfo>> rescanAll({
    bool matchWithServer = true,
    void Function(int current, int total, String path)? onProgress,
  }) async {
    final allResults = <LocalTrackInfo>[];

    for (final directory in _watchedDirectories) {
      final results = await scanDirectory(
        directory,
        recursive: true,
        matchWithServer: matchWithServer,
        onProgress: onProgress,
      );
      allResults.addAll(results);
    }

    return allResults;
  }

  // Private methods for persistence

  Future<void> _loadLibrary() async {
    try {
      final file = await _getLibraryFile();
      if (!await file.exists()) return;

      final content = await file.readAsString();
      final lines = content.split('\n');

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('|');
        if (parts.length >= 3) {
          final track = LocalTrackInfo(
            filePath: parts[1],
            fileName: parts[2],
            fileHash: parts[0],
            fileSize: 0,
            lastModified: DateTime.now(),
            addedAt: DateTime.now(),
          );
          _tracks[track.fileHash] = track;
        }
      }
    } catch (e) {
      debugPrint('Error loading library: $e');
    }
  }

  Future<void> _saveLibrary() async {
    try {
      final file = await _getLibraryFile();
      final lines = <String>[];

      for (final track in _tracks.values) {
        lines.add('${track.fileHash}|${track.filePath}|${track.fileName}');
      }

      await file.writeAsString(lines.join('\n'));
    } catch (e) {
      debugPrint('Error saving library: $e');
    }
  }

  Future<void> _loadPlaylists() async {
    try {
      final file = await _getPlaylistsFile();
      if (!await file.exists()) return;

      final content = await file.readAsString();
      final lines = content.split('\n');

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('|');
        if (parts.length >= 3) {
          final playlist = UserPlaylist(
            id: parts[0],
            name: parts[1],
            trackPaths: parts.length > 2 ? parts[2].split(',') : [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _playlists[playlist.id] = playlist;
        }
      }
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    }
  }

  Future<void> _savePlaylists() async {
    try {
      final file = await _getPlaylistsFile();
      final lines = <String>[];

      for (final playlist in _playlists.values) {
        lines.add('${playlist.id}|${playlist.name}|${playlist.trackPaths.join(',')}');
      }

      await file.writeAsString(lines.join('\n'));
    } catch (e) {
      debugPrint('Error saving playlists: $e');
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final file = await _getFavoritesFile();
      if (!await file.exists()) return;

      final content = await file.readAsString();
      final paths = content.split('\n').where((p) => p.isNotEmpty);

      for (final path in paths) {
        _favoritePaths.add(path);
        final track = getTrackByPath(path);
        if (track != null) {
          _tracks[track.fileHash] = track.copyWith(isFavorite: true);
        }
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final file = await _getFavoritesFile();
      await file.writeAsString(_favoritePaths.join('\n'));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  Future<void> _saveWatchedDirectories() async {
    try {
      final file = await _getWatchedDirsFile();
      await file.writeAsString(_watchedDirectories.join('\n'));
    } catch (e) {
      debugPrint('Error saving watched directories: $e');
    }
  }

  Future<File> _getLibraryFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/music_library.txt');
  }

  Future<File> _getPlaylistsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/playlists.txt');
  }

  Future<File> _getFavoritesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/favorites.txt');
  }

  Future<File> _getWatchedDirsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/watched_dirs.txt');
  }
}
