import 'package:flutter/foundation.dart';
import '../models/song.dart';
import 'api_service.dart';
import 'metadata_service.dart';

/// Model class representing a match result for a local file.
class SongMatchResult {
  final ExtractedMetadata localMetadata;
  final Song? matchedSong;
  final String matchType; // 'exact', 'partial', 'none'
  final double confidence;
  final List<Song> suggestions;
  final String? errorMessage;

  SongMatchResult({
    required this.localMetadata,
    this.matchedSong,
    required this.matchType,
    required this.confidence,
    this.suggestions = const [],
    this.errorMessage,
  });

  /// Returns true if there's a high confidence match
  bool get hasMatch => matchType == 'exact' || (matchType == 'partial' && confidence >= 0.7);

  /// Returns true if there's any match (even low confidence)
  bool get hasPartialMatch => matchType != 'none' && confidence >= 0.5;

  /// Returns the display title (matched song or local metadata)
  String get displayTitle => matchedSong?.title ?? localMetadata.displayTitle;

  /// Returns the display artist (matched song or local metadata)
  String get displayArtist => matchedSong?.mainArtistName ?? localMetadata.displayArtist;

  /// Returns the display album (matched song or local metadata)
  String get displayAlbum => matchedSong?.albumName ?? localMetadata.displayAlbum;

  /// Returns the artwork URL (matched song or local artwork)
  String? get artworkUrl => matchedSong?.artworkUrl;

  @override
  String toString() {
    return 'SongMatchResult(matchType: $matchType, confidence: ${confidence.toStringAsFixed(2)}, title: $displayTitle)';
  }
}

/// Service for matching local audio files with songs in the server database.
/// Uses metadata extraction and API lookups to find the best match.
class SongMatchingService {
  final ApiService _apiService;
  final MetadataService _metadataService;

  SongMatchingService({
    required ApiService apiService,
    MetadataService? metadataService,
  })  : _apiService = apiService,
        _metadataService = metadataService ?? MetadataService();

  /// Match a single local file with the server database.
  /// Returns a SongMatchResult with match details.
  Future<SongMatchResult> matchLocalFile({
    required String filePath,
    bool useServerLookup = true,
  }) async {
    try {
      // Extract metadata from the local file
      final metadata = await _metadataService.extractMetadataFromPath(filePath);

      if (metadata == null) {
        return SongMatchResult(
          localMetadata: ExtractedMetadata(
            filePath: filePath,
            fileName: filePath.split('/').last,
            fileHash: '',
            fileSize: 0,
            lastModified: DateTime.now(),
          ),
          matchType: 'none',
          confidence: 0.0,
          errorMessage: 'Failed to extract metadata from file',
        );
      }

      return await matchMetadata(
        metadata: metadata,
        useServerLookup: useServerLookup,
      );
    } catch (e) {
      return SongMatchResult(
        localMetadata: ExtractedMetadata(
          filePath: filePath,
          fileName: filePath.split('/').last,
          fileHash: '',
          fileSize: 0,
          lastModified: DateTime.now(),
        ),
        matchType: 'none',
        confidence: 0.0,
        errorMessage: 'Error matching file: ${e.toString()}',
      );
    }
  }

  /// Match extracted metadata with the server database.
  /// Returns a SongMatchResult with match details.
  Future<SongMatchResult> matchMetadata({
    required ExtractedMetadata metadata,
    bool useServerLookup = true,
  }) async {
    try {
      // First, try to match by file hash (exact match)
      if (metadata.fileHash.isNotEmpty && useServerLookup) {
        final hashMatch = await _lookupByFileHash(metadata.fileHash);
        if (hashMatch != null) {
          return SongMatchResult(
            localMetadata: metadata,
            matchedSong: hashMatch,
            matchType: 'exact',
            confidence: 1.0,
          );
        }
      }

      // Try to match by metadata on server
      if (useServerLookup && metadata.hasMinimumInfo) {
        final serverResult = await _lookupOnServer(metadata);
        if (serverResult != null) {
          return serverResult;
        }
      }

      // No server match found - return local metadata only
      return SongMatchResult(
        localMetadata: metadata,
        matchType: 'none',
        confidence: 0.0,
      );
    } catch (e) {
      return SongMatchResult(
        localMetadata: metadata,
        matchType: 'none',
        confidence: 0.0,
        errorMessage: 'Error matching metadata: ${e.toString()}',
      );
    }
  }

  /// Look up a song by file hash on the server.
  Future<Song?> _lookupByFileHash(String fileHash) async {
    try {
      final result = await _apiService.lookupSong(fileHash: fileHash);

      if (result != null && result['match_type'] == 'exact') {
        final songData = result['song'];
        if (songData != null) {
          return Song.fromJson(songData);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error looking up by file hash: $e');
      return null;
    }
  }

  /// Look up a song by metadata on the server.
  Future<SongMatchResult?> _lookupOnServer(ExtractedMetadata metadata) async {
    try {
      final result = await _apiService.lookupSong(
        title: metadata.title,
        artist: metadata.artist,
        album: metadata.album,
        duration: metadata.duration,
        fileHash: metadata.fileHash.isNotEmpty ? metadata.fileHash : null,
      );

      if (result == null) {
        return null;
      }

      final matchType = result['match_type'] as String? ?? 'none';
      final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
      final songData = result['song'] as Map<String, dynamic>?;
      final suggestionsData = result['suggestions'] as List<dynamic>?;

      Song? matchedSong;
      if (songData != null) {
        matchedSong = Song.fromJson(songData);
      }

      List<Song> suggestions = [];
      if (suggestionsData != null) {
        suggestions = suggestionsData
            .map((s) => Song.fromJson(s as Map<String, dynamic>))
            .toList();
      }

      return SongMatchResult(
        localMetadata: metadata,
        matchedSong: matchedSong,
        matchType: matchType,
        confidence: confidence,
        suggestions: suggestions,
      );
    } catch (e) {
      debugPrint('Error looking up on server: $e');
      return null;
    }
  }

  /// Batch match multiple local files with the server database.
  /// Returns a list of SongMatchResults for each file.
  Future<List<SongMatchResult>> batchMatchLocalFiles({
    required List<String> filePaths,
    void Function(int current, int total)? onProgress,
    bool useServerLookup = true,
  }) async {
    final results = <SongMatchResult>[];

    for (var i = 0; i < filePaths.length; i++) {
      final result = await matchLocalFile(
        filePath: filePaths[i],
        useServerLookup: useServerLookup,
      );
      results.add(result);

      onProgress?.call(i + 1, filePaths.length);
    }

    return results;
  }

  /// Batch match multiple metadata objects with the server database.
  /// Uses the batch lookup API for efficiency.
  Future<List<SongMatchResult>> batchMatchMetadata({
    required List<ExtractedMetadata> metadataList,
    bool useServerLookup = true,
  }) async {
    if (!useServerLookup || metadataList.isEmpty) {
      return metadataList.map((m) => SongMatchResult(
        localMetadata: m,
        matchType: 'none',
        confidence: 0.0,
      )).toList();
    }

    try {
      // Prepare batch lookup request
      final songsData = metadataList.map((m) => m.toMatchingMap()).toList();

      // Call batch lookup API
      final results = await _apiService.batchLookupSongs(songsData);

      // Match results with original metadata
      final matchResults = <SongMatchResult>[];

      for (var i = 0; i < metadataList.length; i++) {
        final metadata = metadataList[i];

        if (i < results.length) {
          final result = results[i];
          final matchType = result['match_type'] as String? ?? 'none';
          final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
          final songId = result['song_id'] as int?;

          Song? matchedSong;
          if (songId != null && confidence >= 0.7) {
            // Fetch full song details
            matchedSong = await _apiService.fetchSong(songId);
          }

          matchResults.add(SongMatchResult(
            localMetadata: metadata,
            matchedSong: matchedSong,
            matchType: matchType,
            confidence: confidence,
          ));
        } else {
          matchResults.add(SongMatchResult(
            localMetadata: metadata,
            matchType: 'none',
            confidence: 0.0,
          ));
        }
      }

      return matchResults;
    } catch (e) {
      debugPrint('Error in batch match: $e');
      // Return no-match results for all
      return metadataList.map((m) => SongMatchResult(
        localMetadata: m,
        matchType: 'none',
        confidence: 0.0,
        errorMessage: 'Batch lookup failed',
      )).toList();
    }
  }

  /// Sync local library with server database.
  /// Returns a map of file paths to match results.
  Future<Map<String, SongMatchResult>> syncLibrary({
    required List<String> filePaths,
    void Function(int current, int total)? onProgress,
    bool useServerLookup = true,
  }) async {
    final results = <String, SongMatchResult>{};

    // Extract metadata from all files first
    final metadataList = <ExtractedMetadata>[];
    for (var i = 0; i < filePaths.length; i++) {
      final metadata = await _metadataService.extractMetadataFromPath(filePaths[i]);
      if (metadata != null) {
        metadataList.add(metadata);
      }
      onProgress?.call(i + 1, filePaths.length);
    }

    // Batch match with server
    if (useServerLookup && metadataList.isNotEmpty) {
      final matchResults = await batchMatchMetadata(
        metadataList: metadataList,
        useServerLookup: useServerLookup,
      );

      for (var i = 0; i < metadataList.length && i < matchResults.length; i++) {
        results[metadataList[i].filePath] = matchResults[i];
      }
    } else {
      // No server lookup - just create no-match results
      for (final metadata in metadataList) {
        results[metadata.filePath] = SongMatchResult(
          localMetadata: metadata,
          matchType: 'none',
          confidence: 0.0,
        );
      }
    }

    return results;
  }

  /// Calculate match quality between local metadata and a song.
  /// Returns a score from 0.0 to 1.0.
  double calculateMatchQuality(ExtractedMetadata local, Song server) {
    double score = 0.0;
    int comparisons = 0;

    // Compare title (most important)
    if (local.title != null && local.title!.isNotEmpty) {
      comparisons++;
      if (_normalizeString(local.title) == _normalizeString(server.title)) {
        score += 1.0;
      } else if (_calculateSimilarity(local.title!, server.title) > 0.8) {
        score += 0.7;
      }
    }

    // Compare artist
    if (local.artist != null && local.artist!.isNotEmpty) {
      comparisons++;
      final serverArtist = server.mainArtistName;
      if (serverArtist != null) {
        if (_normalizeString(local.artist) == _normalizeString(serverArtist)) {
          score += 1.0;
        } else if (_calculateSimilarity(local.artist!, serverArtist) > 0.8) {
          score += 0.7;
        }
      }
    }

    // Compare album
    if (local.album != null && local.album!.isNotEmpty) {
      comparisons++;
      final serverAlbum = server.albumName;
      if (serverAlbum != null) {
        if (_normalizeString(local.album) == _normalizeString(serverAlbum)) {
          score += 1.0;
        } else if (_calculateSimilarity(local.album!, serverAlbum) > 0.8) {
          score += 0.7;
        }
      }
    }

    // Compare duration (within 5 seconds tolerance)
    if (local.duration != null) {
      comparisons++;
      final durationDiff = (local.duration! - server.duration).abs();
      if (durationDiff <= 2) {
        score += 1.0;
      } else if (durationDiff <= 5) {
        score += 0.8;
      } else if (durationDiff <= 10) {
        score += 0.5;
      }
    }

    return comparisons > 0 ? score / comparisons : 0.0;
  }

  /// Normalize a string for comparison.
  String _normalizeString(String? input) {
    if (input == null) return '';
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Calculate similarity between two strings (Levenshtein-based).
  double _calculateSimilarity(String a, String b) {
    final normalizedA = _normalizeString(a);
    final normalizedB = _normalizeString(b);

    if (normalizedA == normalizedB) return 1.0;
    if (normalizedA.isEmpty || normalizedB.isEmpty) return 0.0;

    // Check if one contains the other
    if (normalizedA.contains(normalizedB) || normalizedB.contains(normalizedA)) {
      return 0.8;
    }

    // Levenshtein distance
    final matrix = List.generate(
      normalizedA.length + 1,
      (_) => List.filled(normalizedB.length + 1, 0),
    );

    for (int i = 0; i <= normalizedA.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= normalizedB.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= normalizedA.length; i++) {
      for (int j = 1; j <= normalizedB.length; j++) {
        final cost = normalizedA[i - 1] == normalizedB[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    final distance = matrix[normalizedA.length][normalizedB.length];
    final maxLength = normalizedA.length > normalizedB.length
        ? normalizedA.length
        : normalizedB.length;

    return 1.0 - (distance / maxLength);
  }
}
