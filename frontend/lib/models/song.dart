

/// Model class representing a Song in the music player.
/// Matches the backend Song model structure.
class Song {
  final int id;
  final String title;
  final int duration; // Duration in seconds
  final String fileHash;
  final String? lyrics;
  final String? artworkUrl;
  final List<SongArtist> artists;
  final List<SongAlbum> albums;
  final DateTime createdAt;
  final DateTime updatedAt;

  Song({
    required this.id,
    required this.title,
    required this.duration,
    required this.fileHash,
    this.lyrics,
    this.artworkUrl,
    this.artists = const [],
    this.albums = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Returns duration in MM:SS format
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Returns the main artist name (first artist with role 'main')
  String? get mainArtistName {
    try {
      final mainArtist = artists.firstWhere(
        (artist) => artist.role == 'main',
        orElse: () => artists.first,
      );
      return mainArtist.name;
    } catch (e) {
      return null;
    }
  }

  /// Returns the album name (first album)
  String? get albumName {
    return albums.isNotEmpty ? albums.first.title : null;
  }

  /// Creates a Song from a JSON map
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as int,
      title: json['title'] as String,
      duration: json['duration'] as int,
      fileHash: json['file_hash'] as String,
      lyrics: json['lyrics'] as String?,
      artworkUrl: json['artwork_url'] as String?,
      artists: (json['artists'] as List<dynamic>?)
              ?.map((artist) => SongArtist.fromJson(artist as Map<String, dynamic>))
              .toList() ??
          [],
      albums: (json['albums'] as List<dynamic>?)
              ?.map((album) => SongAlbum.fromJson(album as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts Song to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'duration': duration,
      'file_hash': fileHash,
      'lyrics': lyrics,
      'artwork_url': artworkUrl,
      'artists': artists.map((artist) => artist.toJson()).toList(),
      'albums': albums.map((album) => album.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this Song with given fields replaced
  Song copyWith({
    int? id,
    String? title,
    int? duration,
    String? fileHash,
    String? lyrics,
    String? artworkUrl,
    List<SongArtist>? artists,
    List<SongAlbum>? albums,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      fileHash: fileHash ?? this.fileHash,
      lyrics: lyrics ?? this.lyrics,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      artists: artists ?? this.artists,
      albums: albums ?? this.albums,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Song(id: $id, title: $title, duration: $formattedDuration, artists: ${artists.length}, albums: ${albums.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Song && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Model class representing a Song's Artist relationship
class SongArtist {
  final int id;
  final String name;
  final String? imageUrl;
  final String role; // 'main', 'featured', 'producer', etc.
  final String roleDisplay;

  SongArtist({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.role,
    required this.roleDisplay,
  });

  factory SongArtist.fromJson(Map<String, dynamic> json) {
    return SongArtist(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      role: json['role'] as String,
      roleDisplay: json['role_display'] as String? ?? json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'role': role,
      'role_display': roleDisplay,
    };
  }

  @override
  String toString() => 'SongArtist(id: $id, name: $name, role: $roleDisplay)';
}

/// Model class representing a Song's Album relationship
class SongAlbum {
  final int id;
  final String title;
  final String albumType;
  final String? coverUrl;
  final int? trackNumber;
  final DateTime? releaseDate;

  SongAlbum({
    required this.id,
    required this.title,
    required this.albumType,
    this.coverUrl,
    this.trackNumber,
    this.releaseDate,
  });

  factory SongAlbum.fromJson(Map<String, dynamic> json) {
    return SongAlbum(
      id: json['id'] as int,
      title: json['title'] as String,
      albumType: json['album_type'] as String,
      coverUrl: json['cover_url'] as String?,
      trackNumber: json['track_number'] as int?,
      releaseDate: json['release_date'] != null
          ? DateTime.parse(json['release_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'album_type': albumType,
      'cover_url': coverUrl,
      'track_number': trackNumber,
      'release_date': releaseDate?.toIso8601String(),
    };
  }

  @override
  String toString() => 'SongAlbum(id: $id, title: $title, track: $trackNumber)';
}
