/// Model class representing an Album in the music player.
/// Matches the backend Album model structure.
class Album {
  final int id;
  final String title;
  final String
      albumType; // 'album', 'ep', 'single', 'compilation', 'soundtrack'
  final DateTime? releaseDate;
  final String? coverUrl;
  final String? description;
  final List<AlbumArtist> artists;
  final int songCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Album({
    required this.id,
    required this.title,
    required this.albumType,
    this.releaseDate,
    this.coverUrl,
    this.description,
    this.artists = const [],
    this.songCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Returns the album type display name
  String get albumTypeDisplay {
    const typeMap = {
      'album': 'Album',
      'ep': 'EP',
      'single': 'Single',
      'compilation': 'Compilation',
      'soundtrack': 'Soundtrack',
    };
    return typeMap[albumType] ?? albumType;
  }

  /// Returns the year of release
  int? get year {
    return releaseDate?.year;
  }

  /// Returns the main artist name (first artist)
  String? get mainArtistName {
    return artists.isNotEmpty ? artists.first.name : null;
  }

  /// Creates an Album from a JSON map
  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as int,
      title: json['title'] as String,
      albumType: json['album_type'] as String,
      releaseDate: json['release_date'] != null
          ? DateTime.parse(json['release_date'] as String)
          : null,
      coverUrl: json['cover_url'] as String?,
      description: json['description'] as String?,
      artists: (json['artists'] as List<dynamic>?)
              ?.map((artist) =>
                  AlbumArtist.fromJson(artist as Map<String, dynamic>))
              .toList() ??
          [],
      songCount: json['song_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts Album to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'album_type': albumType,
      'release_date': releaseDate?.toIso8601String(),
      'cover_url': coverUrl,
      'description': description,
      'artists': artists.map((artist) => artist.toJson()).toList(),
      'song_count': songCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this Album with given fields replaced
  Album copyWith({
    int? id,
    String? title,
    String? albumType,
    DateTime? releaseDate,
    String? coverUrl,
    String? description,
    List<AlbumArtist>? artists,
    int? songCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      albumType: albumType ?? this.albumType,
      releaseDate: releaseDate ?? this.releaseDate,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      artists: artists ?? this.artists,
      songCount: songCount ?? this.songCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Album(id: $id, title: $title, type: $albumTypeDisplay, artists: ${artists.length}, songs: $songCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Album && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Model class representing an Album's Artist relationship
class AlbumArtist {
  final int id;
  final String name;
  final String? imageUrl;

  AlbumArtist({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory AlbumArtist.fromJson(Map<String, dynamic> json) {
    return AlbumArtist(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
    };
  }

  @override
  String toString() => 'AlbumArtist(id: $id, name: $name)';
}

/// Model class representing an Artist in the music player.
/// Matches the backend Artist model structure.
class Artist {
  final int id;
  final String name;
  final String? imageUrl;
  final String? bio;
  final int songCount;
  final int albumCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Artist({
    required this.id,
    required this.name,
    this.imageUrl,
    this.bio,
    this.songCount = 0,
    this.albumCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an Artist from a JSON map
  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      bio: json['bio'] as String?,
      songCount: json['song_count'] as int? ?? 0,
      albumCount: json['album_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts Artist to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'bio': bio,
      'song_count': songCount,
      'album_count': albumCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this Artist with given fields replaced
  Artist copyWith({
    int? id,
    String? name,
    String? imageUrl,
    String? bio,
    int? songCount,
    int? albumCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      songCount: songCount ?? this.songCount,
      albumCount: albumCount ?? this.albumCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Artist(id: $id, name: $name, albums: $albumCount, songs: $songCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Artist && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Model class representing an Artist with full discography
class ArtistDetail extends Artist {
  final List<Album> albums;
  final List<SimpleSong> songs;

  ArtistDetail({
    required super.id,
    required super.name,
    super.imageUrl,
    super.bio,
    super.songCount,
    super.albumCount,
    required super.createdAt,
    required super.updatedAt,
    this.albums = const [],
    this.songs = const [],
  });

  factory ArtistDetail.fromJson(Map<String, dynamic> json) {
    final artist = Artist.fromJson(json);
    return ArtistDetail(
      id: artist.id,
      name: artist.name,
      imageUrl: artist.imageUrl,
      bio: artist.bio,
      songCount: artist.songCount,
      albumCount: artist.albumCount,
      createdAt: artist.createdAt,
      updatedAt: artist.updatedAt,
      albums: (json['albums'] as List<dynamic>?)
              ?.map((album) => Album.fromJson(album as Map<String, dynamic>))
              .toList() ??
          [],
      songs: (json['songs'] as List<dynamic>?)
              ?.map((song) => SimpleSong.fromJson(song as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['albums'] = albums.map((album) => album.toJson()).toList();
    json['songs'] = songs.map((song) => song.toJson()).toList();
    return json;
  }
}

/// Simplified Song model for nested use in other models
class SimpleSong {
  final int id;
  final String title;
  final int duration;
  final String formattedDuration;
  final String? artworkUrl;

  SimpleSong({
    required this.id,
    required this.title,
    required this.duration,
    required this.formattedDuration,
    this.artworkUrl,
  });

  factory SimpleSong.fromJson(Map<String, dynamic> json) {
    return SimpleSong(
      id: json['id'] as int,
      title: json['title'] as String,
      duration: json['duration'] as int,
      formattedDuration: json['formatted_duration'] as String? ??
          _formatDuration(json['duration'] as int),
      artworkUrl: json['artwork_url'] as String?,
    );
  }

  static String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'duration': duration,
      'formatted_duration': formattedDuration,
      'artwork_url': artworkUrl,
    };
  }
}
