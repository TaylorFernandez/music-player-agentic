import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Model class representing extracted metadata from an audio file.
class ExtractedMetadata {
  final String filePath;
  final String fileName;
  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final int? duration; // in seconds
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final String? genre;
  final Uint8List? artwork;
  final String fileHash;
  final int fileSize;
  final DateTime lastModified;

  ExtractedMetadata({
    required this.filePath,
    required this.fileName,
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.duration,
    this.trackNumber,
    this.discNumber,
    this.year,
    this.genre,
    this.artwork,
    required this.fileHash,
    required this.fileSize,
    required this.lastModified,
  });

  /// Returns true if the metadata has minimal required info for matching
  bool get hasMinimumInfo => title != null || artist != null || album != null;

  /// Returns a display title (uses filename if no title in metadata)
  String get displayTitle => title ?? fileName;

  /// Returns a display artist (uses "Unknown Artist" if no artist)
  String get displayArtist => artist ?? 'Unknown Artist';

  /// Returns a display album (uses "Unknown Album" if no album)
  String get displayAlbum => album ?? 'Unknown Album';

  /// Returns formatted duration (MM:SS)
  String get formattedDuration {
    if (duration == null) return '--:--';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Converts metadata to a map for API matching requests
  Map<String, dynamic> toMatchingMap() {
    return {
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (duration != null) 'duration': duration,
      'file_hash': fileHash,
    };
  }

  @override
  String toString() {
    return 'ExtractedMetadata(title: $title, artist: $artist, album: $album, duration: $formattedDuration)';
  }
}

/// Service for extracting metadata from audio files.
/// Parses ID3 tags from MP3 files to extract song information.
class MetadataService {
  /// Supported audio file extensions
  static const supportedExtensions = [
    '.mp3',
    '.m4a',
    '.flac',
    '.wav',
    '.ogg',
    '.aac'
  ];

  /// Check if a file is a supported audio file
  bool isSupportedAudioFile(String filePath) {
    final extension = p.extension(filePath).toLowerCase();
    return supportedExtensions.contains(extension);
  }

  /// Calculate SHA-256 hash of a file for deduplication
  Future<String> _calculateFileHash(File file) async {
    try {
      final fileLength = await file.length();

      if (fileLength <= 2 * 1024 * 1024) {
        // Small file: hash entire content
        final bytes = await file.readAsBytes();
        final digest = sha256.convert(bytes);
        return digest.toString();
      }

      // Large file: hash first and last chunks + size for efficiency
      final randomAccessFile = await file.open();
      try {
        final firstChunk = await randomAccessFile.read(1024 * 1024);
        await randomAccessFile.setPosition(fileLength - 1024 * 1024);
        final lastChunk = await randomAccessFile.read(1024 * 1024);

        final combinedBytes = <int>[
          ...firstChunk,
          ...lastChunk,
          ...fileLength.toString().codeUnits,
        ];

        final digest = sha256.convert(combinedBytes);
        return digest.toString();
      } finally {
        await randomAccessFile.close();
      }
    } catch (e) {
      // Fallback: hash file path and modification time
      final stat = await file.stat();
      final fallbackInput =
          '${file.path}:${stat.size}:${stat.modified.millisecondsSinceEpoch}';
      return sha256.convert(fallbackInput.codeUnits).toString();
    }
  }

  /// Extract metadata from an audio file
  Future<ExtractedMetadata?> extractMetadata(File file) async {
    try {
      if (!isSupportedAudioFile(file.path)) {
        return null;
      }

      final stat = await file.stat();
      final fileHash = await _calculateFileHash(file);
      final fileName = p.basenameWithoutExtension(file.path);

      // Parse ID3 tags from MP3 file
      final metadata = await _parseId3Tags(file);

      return ExtractedMetadata(
        filePath: file.path,
        fileName: fileName,
        title: metadata['title'],
        artist: metadata['artist'],
        album: metadata['album'],
        albumArtist: metadata['album_artist'],
        duration: metadata['duration'] as int?,
        trackNumber: metadata['track_number'] as int?,
        discNumber: metadata['disc_number'] as int?,
        year: metadata['year'] as int?,
        genre: metadata['genre'],
        artwork: metadata['artwork'] as Uint8List?,
        fileHash: fileHash,
        fileSize: stat.size,
        lastModified: stat.modified,
      );
    } catch (e) {
      // If metadata extraction fails, return basic info with filename
      try {
        final stat = await file.stat();
        final fileHash = await _calculateFileHash(file);
        final fileName = p.basenameWithoutExtension(file.path);

        return ExtractedMetadata(
          filePath: file.path,
          fileName: fileName,
          title: fileName, // Use filename as title fallback
          fileHash: fileHash,
          fileSize: stat.size,
          lastModified: stat.modified,
        );
      } catch (_) {
        return null;
      }
    }
  }

  /// Extract metadata from a file path
  Future<ExtractedMetadata?> extractMetadataFromPath(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }
      return await extractMetadata(file);
    } catch (e) {
      return null;
    }
  }

  /// Extract metadata from multiple files
  Future<List<ExtractedMetadata>> extractMetadataFromFiles(
      List<File> files) async {
    final results = <ExtractedMetadata>[];

    for (final file in files) {
      final metadata = await extractMetadata(file);
      if (metadata != null) {
        results.add(metadata);
      }
    }

    return results;
  }

  /// Extract metadata from all audio files in a directory
  Future<List<ExtractedMetadata>> extractMetadataFromDirectory(
    Directory directory, {
    bool recursive = true,
    void Function(int current, int total)? onProgress,
  }) async {
    final results = <ExtractedMetadata>[];

    try {
      // Get all audio files in the directory
      final entities = await directory.list(recursive: recursive).toList();
      final audioFiles = entities
          .whereType<File>()
          .where((file) => isSupportedAudioFile(file.path))
          .toList();

      final total = audioFiles.length;

      for (var i = 0; i < audioFiles.length; i++) {
        final metadata = await extractMetadata(audioFiles[i]);
        if (metadata != null) {
          results.add(metadata);
        }

        onProgress?.call(i + 1, total);
      }
    } catch (e) {
      // Return whatever we have
    }

    return results;
  }

  /// Extract artwork from an audio file
  Future<Uint8List?> extractArtwork(File file) async {
    try {
      if (!isSupportedAudioFile(file.path)) {
        return null;
      }

      final metadata = await extractMetadata(file);
      return metadata?.artwork;
    } catch (e) {
      return null;
    }
  }

  /// Check if a file has embedded artwork
  Future<bool> hasArtwork(File file) async {
    try {
      if (!isSupportedAudioFile(file.path)) {
        return false;
      }

      final metadata = await extractMetadata(file);
      return metadata?.artwork != null && metadata!.artwork!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get the duration of an audio file in seconds
  Future<int?> getDuration(File file) async {
    try {
      if (!isSupportedAudioFile(file.path)) {
        return null;
      }

      final metadata = await extractMetadata(file);
      return metadata?.duration;
    } catch (e) {
      return null;
    }
  }

  /// Calculate confidence score for metadata quality
  /// Returns a score from 0.0 to 1.0
  double calculateMetadataQuality(ExtractedMetadata metadata) {
    double score = 0.0;

    // Title is most important (0.4 points)
    if (metadata.title != null && metadata.title!.isNotEmpty) {
      score += 0.4;
    }

    // Artist is important (0.3 points)
    if (metadata.artist != null && metadata.artist!.isNotEmpty) {
      score += 0.3;
    }

    // Album is nice to have (0.15 points)
    if (metadata.album != null && metadata.album!.isNotEmpty) {
      score += 0.15;
    }

    // Duration is useful (0.1 points)
    if (metadata.duration != null && metadata.duration! > 0) {
      score += 0.1;
    }

    // Track number is bonus (0.05 points)
    if (metadata.trackNumber != null && metadata.trackNumber! > 0) {
      score += 0.05;
    }

    return score;
  }

  /// Compare two metadata objects and return a match score
  /// Returns a score from 0.0 to 1.0 indicating how similar they are
  double compareMetadata(ExtractedMetadata a, ExtractedMetadata b) {
    double score = 0.0;
    int comparisons = 0;

    // Compare titles
    if (a.title != null && b.title != null) {
      comparisons++;
      if (_normalizeString(a.title) == _normalizeString(b.title)) {
        score += 1.0;
      } else if (_calculateSimilarity(a.title!, b.title!) > 0.8) {
        score += 0.5;
      }
    }

    // Compare artists
    if (a.artist != null && b.artist != null) {
      comparisons++;
      if (_normalizeString(a.artist) == _normalizeString(b.artist)) {
        score += 1.0;
      } else if (_calculateSimilarity(a.artist!, b.artist!) > 0.8) {
        score += 0.5;
      }
    }

    // Compare albums
    if (a.album != null && b.album != null) {
      comparisons++;
      if (_normalizeString(a.album) == _normalizeString(b.album)) {
        score += 1.0;
      } else if (_calculateSimilarity(a.album!, b.album!) > 0.8) {
        score += 0.5;
      }
    }

    // Compare durations (within 5 seconds tolerance)
    if (a.duration != null && b.duration != null) {
      comparisons++;
      if ((a.duration! - b.duration!).abs() <= 5) {
        score += 1.0;
      } else if ((a.duration! - b.duration!).abs() <= 10) {
        score += 0.5;
      }
    }

    return comparisons > 0 ? score / comparisons : 0.0;
  }

  /// Parse ID3 tags from an MP3 file
  Future<Map<String, dynamic>> _parseId3Tags(File file) async {
    final result = <String, dynamic>{};

    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return result;

      // Check for ID3v2 header
      if (bytes.length >= 10 &&
          bytes[0] == 0x49 &&
          bytes[1] == 0x44 &&
          bytes[2] == 0x33) {
        // "ID3"
        final id3Data = _parseId3v2(bytes);
        result.addAll(id3Data);
      }

      // Check for ID3v1 tag at end of file (last 128 bytes)
      if (bytes.length >= 128) {
        final id3v1Start = bytes.length - 128;
        if (bytes[id3v1Start] == 0x54 &&
            bytes[id3v1Start + 1] == 0x41 &&
            bytes[id3v1Start + 2] == 0x47) {
          // "TAG"
          final id3v1Data = _parseId3v1(bytes.sublist(id3v1Start));
          // ID3v2 takes precedence, so only add if not already set
          for (final entry in id3v1Data.entries) {
            if (!result.containsKey(entry.key) || result[entry.key] == null) {
              result[entry.key] = entry.value;
            }
          }
        }
      }

      // Try to get duration from file size estimation
      final duration = _estimateDuration(bytes.length);
      if (duration != null && !result.containsKey('duration')) {
        result['duration'] = duration;
      }
    } catch (e) {
      // Silently fail and return empty result
    }

    return result;
  }

  /// Parse ID3v2 tags
  Map<String, dynamic> _parseId3v2(Uint8List bytes) {
    final result = <String, dynamic>{};

    try {
      // ID3v2 header: "ID3" + version (2 bytes) + flags (1 byte) + size (4 bytes synchsafe)
      final majorVersion = bytes[3];
      final flags = bytes[5];

      // Synchsafe integer for size
      int size = 0;
      for (int i = 6; i < 10; i++) {
        size = (size << 7) | (bytes[i] & 0x7F);
      }

      int offset = 10;

      // Check for extended header
      if ((flags & 0x40) != 0 && offset + 4 <= bytes.length) {
        int extSize = 0;
        for (int i = 0; i < 4; i++) {
          extSize = (extSize << 8) | bytes[offset + i];
        }
        offset += extSize;
      }

      // Parse frames
      while (offset < 10 + size && offset < bytes.length - 10) {
        String frameId;
        int frameSize;

        if (majorVersion >= 3) {
          // ID3v2.3 and ID3v2.4: 4-byte frame ID, 4-byte size
          if (offset + 8 > bytes.length) break;
          frameId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
          frameSize = 0;
          for (int i = 0; i < 4; i++) {
            frameSize = (frameSize << 8) | bytes[offset + 4 + i];
          }
          offset += 8;
        } else {
          // ID3v2.2: 3-byte frame ID, 3-byte size
          if (offset + 6 > bytes.length) break;
          frameId = String.fromCharCodes(bytes.sublist(offset, offset + 3));
          frameSize = 0;
          for (int i = 0; i < 3; i++) {
            frameSize = (frameSize << 8) | bytes[offset + 3 + i];
          }
          offset += 6;
        }

        // Check for valid frame ID
        if (frameId.startsWith('\x00') ||
            frameSize <= 0 ||
            frameSize > bytes.length) {
          break;
        }

        // Extract frame data
        if (offset + frameSize > bytes.length) {
          break;
        }

        final frameData = bytes.sublist(offset, offset + frameSize);

        // Parse based on frame ID
        _parseFrame(frameId, frameData, result, majorVersion);

        offset += frameSize;
      }
    } catch (e) {
      // Silently fail
    }

    return result;
  }

  /// Parse individual ID3v2 frame
  void _parseFrame(String frameId, Uint8List frameData,
      Map<String, dynamic> result, int version) {
    try {
      String? text;

      // Common frame IDs (ID3v2.3/v2.4)
      if (frameId == 'TIT2' || frameId == 'TT2') {
        text = _decodeText(frameData);
        if (text != null) result['title'] = text;
      } else if (frameId == 'TPE1' || frameId == 'TP1') {
        text = _decodeText(frameData);
        if (text != null) result['artist'] = text;
      } else if (frameId == 'TALB' || frameId == 'TAL') {
        text = _decodeText(frameData);
        if (text != null) result['album'] = text;
      } else if (frameId == 'TPE2' || frameId == 'TP2') {
        text = _decodeText(frameData);
        if (text != null) result['album_artist'] = text;
      } else if (frameId == 'TRCK' || frameId == 'TRK') {
        text = _decodeText(frameData);
        if (text != null) {
          final trackParts = text.split('/');
          result['track_number'] = int.tryParse(trackParts[0]);
        }
      } else if (frameId == 'TPOS' || frameId == 'TPA') {
        text = _decodeText(frameData);
        if (text != null) {
          final discParts = text.split('/');
          result['disc_number'] = int.tryParse(discParts[0]);
        }
      } else if (frameId == 'TYER' || frameId == 'TDRC' || frameId == 'TYE') {
        text = _decodeText(frameData);
        if (text != null) {
          // Extract year from date string
          final yearMatch = RegExp(r'\d{4}').firstMatch(text);
          if (yearMatch != null) {
            result['year'] = int.tryParse(yearMatch.group(0)!);
          }
        }
      } else if (frameId == 'TCON' || frameId == 'TCO') {
        text = _decodeText(frameData);
        if (text != null) result['genre'] = text;
      } else if (frameId == 'APIC' || frameId == 'PIC') {
        // Extract artwork
        final artwork = _extractArtwork(frameData);
        if (artwork != null) result['artwork'] = artwork;
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Decode text from frame data
  String? _decodeText(Uint8List frameData) {
    if (frameData.isEmpty) return null;

    try {
      final encoding = frameData[0];
      int start = 1;

      List<int> textBytes;

      if (encoding == 0) {
        // ISO-8859-1 / Latin-1
        textBytes = frameData.sublist(start);
        // Find null terminator
        final nullIndex = textBytes.indexOf(0);
        if (nullIndex >= 0) {
          textBytes = textBytes.sublist(0, nullIndex);
        }
        return String.fromCharCodes(textBytes);
      } else if (encoding == 1) {
        // UTF-16 with BOM
        if (frameData.length > 2) {
          start = 3; // Skip encoding + BOM
        }
        textBytes = frameData.sublist(start);
        // Find null terminator (double null)
        int nullIndex = -1;
        for (int i = 0; i < textBytes.length - 1; i += 2) {
          if (textBytes[i] == 0 && textBytes[i + 1] == 0) {
            nullIndex = i;
            break;
          }
        }
        if (nullIndex >= 0) {
          textBytes = textBytes.sublist(0, nullIndex);
        }
        return String.fromCharCodes(textBytes);
      } else if (encoding == 2) {
        // UTF-16BE
        textBytes = frameData.sublist(start);
        final nullIndex = textBytes.indexOf(0);
        if (nullIndex >= 0) {
          textBytes = textBytes.sublist(0, nullIndex);
        }
        return String.fromCharCodes(textBytes);
      } else if (encoding == 3) {
        // UTF-8
        textBytes = frameData.sublist(start);
        final nullIndex = textBytes.indexOf(0);
        if (nullIndex >= 0) {
          textBytes = textBytes.sublist(0, nullIndex);
        }
        return String.fromCharCodes(textBytes);
      }

      // Fallback: try UTF-8
      return String.fromCharCodes(frameData.sublist(1));
    } catch (e) {
      return null;
    }
  }

  /// Extract artwork from APIC frame
  Uint8List? _extractArtwork(Uint8List frameData) {
    try {
      if (frameData.isEmpty) return null;

      final encoding = frameData[0];
      int offset = 1;

      // Skip MIME type (null-terminated)
      while (offset < frameData.length && frameData[offset] != 0) {
        offset++;
      }
      offset++; // Skip null terminator

      // Skip picture type (1 byte)
      if (offset < frameData.length) {
        offset++;
      }

      // Skip description (null-terminated)
      while (offset < frameData.length && frameData[offset] != 0) {
        offset++;
      }
      offset++; // Skip null terminator

      // Handle double null for UTF-16
      if (encoding == 1 || encoding == 2) {
        while (offset < frameData.length && frameData[offset] == 0) {
          offset++;
        }
      }

      // Rest is image data
      if (offset < frameData.length) {
        return frameData.sublist(offset);
      }
    } catch (e) {
      // Silently fail
    }

    return null;
  }

  /// Parse ID3v1 tags
  Map<String, dynamic> _parseId3v1(Uint8List bytes) {
    final result = <String, dynamic>{};

    try {
      // ID3v1 structure: TAG (3 bytes) + title (30) + artist (30) + album (30) + year (4) + comment (28/30) + genre (1)
      if (bytes.length < 128) return result;

      final title = String.fromCharCodes(bytes.sublist(3, 33)).trim();
      final artist = String.fromCharCodes(bytes.sublist(33, 63)).trim();
      final album = String.fromCharCodes(bytes.sublist(63, 93)).trim();
      final year = String.fromCharCodes(bytes.sublist(93, 97)).trim();

      if (title.isNotEmpty) result['title'] = title;
      if (artist.isNotEmpty) result['artist'] = artist;
      if (album.isNotEmpty) result['album'] = album;
      if (year.isNotEmpty) result['year'] = int.tryParse(year);

      // Genre is the last byte
      final genreIndex = bytes[127];
      final genres = _getGenreList();
      if (genreIndex < genres.length) {
        result['genre'] = genres[genreIndex];
      }
    } catch (e) {
      // Silently fail
    }

    return result;
  }

  /// Get standard ID3v1 genre list
  List<String> _getGenreList() {
    return [
      'Blues',
      'Classic Rock',
      'Country',
      'Dance',
      'Disco',
      'Funk',
      'Grunge',
      'Hip-Hop',
      'Jazz',
      'Metal',
      'New Age',
      'Oldies',
      'Other',
      'Pop',
      'R&B',
      'Rap',
      'Reggae',
      'Rock',
      'Techno',
      'Industrial',
      'Alternative',
      'Ska',
      'Death Metal',
      'Pranks',
      'Soundtrack',
      'Euro-Techno',
      'Ambient',
      'Trip-Hop',
      'Vocal',
      'Jazz+Funk',
      'Fusion',
      'Trance',
      'Classical',
      'Instrumental',
      'Acid',
      'House',
      'Game',
      'Sound Clip',
      'Gospel',
      'Noise',
      'AlternRock',
      'Bass',
      'Soul',
      'Punk',
      'Space',
      'Meditative',
      'Instrumental Pop',
      'Instrumental Rock',
      'Ethnic',
      'Gothic',
      'Darkwave',
      'Techno-Industrial',
      'Electronic',
      'Pop-Folk',
      'Eurodance',
      'Dream',
      'Southern Rock',
      'Comedy',
      'Cult',
      'Gangsta',
      'Top 40',
      'Christian Rap',
      'Pop/Funk',
      'Jungle',
      'Native American',
      'Cabaret',
      'New Wave',
      'Psychadelic',
      'Rave',
      'Showtunes',
      'Trailer',
      'Lo-Fi',
      'Tribal',
      'Acid Punk',
      'Acid Jazz',
      'Polka',
      'Retro',
      'Musical',
      'Rock & Roll',
      'Hard Rock',
      'Folk',
      'Folk-Rock',
      'National Folk',
      'Swing',
      'Fast Fusion',
      'Bebob',
      'Latin',
      'Revival',
      'Celtic',
      'Bluegrass',
      'Avantgarde',
      'Gothic Rock',
      'Progressive Rock',
      'Psychedelic Rock',
      'Symphonic Rock',
      'Slow Rock',
      'Big Band',
      'Chorus',
      'Easy Listening',
      'Acoustic',
      'Humour',
      'Speech',
      'Chanson',
      'Opera',
      'Chamber Music',
      'Sonata',
      'Symphony',
      'Booty Bass',
      'Primus',
      'Porn Groove',
      'Satire',
      'Slow Jam',
      'Club',
      'Tango',
      'Samba',
      'Folklore',
      'Ballad',
      'Power Ballad',
      'Rhythmic Soul',
      'Freestyle',
      'Duet',
      'Punk Rock',
      'Drum Solo',
      'A capella',
      'Euro-House',
      'Dance Hall',
      'Goa',
      'Drum & Bass',
      'Club-House',
      'Hardcore Techno',
      'Terror',
      'Indie',
      'BritPop',
      'Negerpunk',
      'Polsk Punk',
      'Beat',
      'Christian Gangsta Rap',
      'Heavy Metal',
      'Black Metal',
      'Crossover',
      'Contemporary Christian',
      'Christian Rock',
      'Merengue',
      'Salsa',
      'Thrash Metal',
      'Anime',
      'JPop',
      'Synthpop',
    ];
  }

  /// Estimate duration from file size (rough approximation for MP3)
  int? _estimateDuration(int fileSize) {
    try {
      // Estimate based on common bitrates (128kbps = ~16KB/s)
      // This is a rough estimate - actual duration should come from proper parsing
      const bitrateBytesPerSecond = 128 * 1024 / 8;
      final estimatedDuration = (fileSize / bitrateBytesPerSecond).round();
      return estimatedDuration > 0 ? estimatedDuration : null;
    } catch (e) {
      return null;
    }
  }

  /// Normalize a string for comparison
  String _normalizeString(String? input) {
    if (input == null) return '';
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Calculate similarity between two strings (Levenshtein-based)
  double _calculateSimilarity(String a, String b) {
    final normalizedA = _normalizeString(a);
    final normalizedB = _normalizeString(b);

    if (normalizedA == normalizedB) return 1.0;
    if (normalizedA.isEmpty || normalizedB.isEmpty) return 0.0;

    // Check if one contains the other
    if (normalizedA.contains(normalizedB) ||
        normalizedB.contains(normalizedA)) {
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
