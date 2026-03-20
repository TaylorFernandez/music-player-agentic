import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/song.dart';
import '../models/music_models.dart';

/// API Service for communicating with the Django backend.
/// Handles authentication, token management, and all API calls.
class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage;
  final String baseUrl;

  ApiService({
    this.baseUrl = 'http://localhost:8000/api',
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors for authentication and error handling
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to requests (except login/register)
        if (!_isAuthEndpoint(options.path)) {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Token $token';
          }
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 Unauthorized - token expired
        if (error.response?.statusCode == 401) {
          // Clear stored token
          await _storage.delete(key: 'auth_token');
          await _storage.delete(key: 'refresh_token');

          // Could implement token refresh here if using JWT
        }
        return handler.next(error);
      },
    ));
  }

  /// Check if endpoint is an auth endpoint (doesn't require token)
  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
           path.contains('/auth/register') ||
           path.contains('/auth/google');
  }

  // ============================================================
  // Authentication Endpoints
  // ============================================================

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register/',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'password2': password,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data['data'];
        return {
          'success': true,
          'user': data,
        };
      }
      return {
        'success': false,
        'error': response.data['error'] ?? 'Registration failed',
      };
    } on DioException catch (e) {
      return _handleError(e, 'Registration failed');
    }
  }

  /// Login with username and password
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login/',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];

        // Store token securely
        if (data['token'] != null) {
          await _storage.write(key: 'auth_token', value: data['token']);
        }

        // Store user info
        await _storage.write(key: 'user_id', value: data['user_id'].toString());
        await _storage.write(key: 'username', value: data['username']);
        await _storage.write(key: 'user_role', value: data['role'] ?? 'general');

        return {
          'success': true,
          'user': data,
        };
      }
      return {
        'success': false,
        'error': response.data['error'] ?? 'Login failed',
      };
    } on DioException catch (e) {
      return _handleError(e, 'Login failed');
    }
  }

  /// Logout the current user
  Future<bool> logout() async {
    try {
      await _dio.post('/auth/logout/');

      // Clear stored tokens
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'user_id');
      await _storage.delete(key: 'username');
      await _storage.delete(key: 'user_role');

      return true;
    } on DioException {
      // Even if API call fails, clear local storage
      await _storage.deleteAll();
      return false;
    }
  }

  /// Get current user information
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me/');

      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  /// Get stored user role
  Future<String?> getUserRole() async {
    return await _storage.read(key: 'user_role');
  }

  // ============================================================
  // Song Endpoints
  // ============================================================

  /// Fetch paginated list of songs
  Future<Map<String, dynamic>?> fetchSongs({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? artistId,
    int? albumId,
    String? sort,
    String? order,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (search != null) queryParams['search'] = search;
      if (artistId != null) queryParams['artist_id'] = artistId;
      if (albumId != null) queryParams['album_id'] = albumId;
      if (sort != null) queryParams['sort'] = sort;
      if (order != null) queryParams['order'] = order;

      final response = await _dio.get('/songs/', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Fetch a single song by ID
  Future<Song?> fetchSong(int id) async {
    try {
      final response = await _dio.get('/songs/$id/');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return Song.fromJson(data);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Lookup a song by metadata from MP3 file
  Future<Map<String, dynamic>?> lookupSong({
    String? title,
    String? artist,
    String? album,
    int? duration,
    String? fileHash,
  }) async {
    try {
      final response = await _dio.post('/songs/lookup/', data: {
        if (title != null) 'title': title,
        if (artist != null) 'artist': artist,
        if (album != null) 'album': album,
        if (duration != null) 'duration': duration,
        if (fileHash != null) 'file_hash': fileHash,
      });

      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Batch lookup songs (for mobile app sync)
  Future<List<Map<String, dynamic>>> batchLookupSongs(
    List<Map<String, dynamic>> songs,
  ) async {
    try {
      final response = await _dio.post('/songs/batch_lookup/', data: {
        'songs': songs,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return List<Map<String, dynamic>>.from(data['results']);
      }
      return [];
    } on DioException {
      return [];
    }
  }

  /// Get lyrics for a song
  Future<String?> fetchLyrics(int songId) async {
    try {
      final response = await _dio.get('/songs/$songId/lyrics/');

      if (response.statusCode == 200) {
        return response.data['data']['lyrics'];
      }
      return null;
    } on DioException {
      return null;
    }
  }

  // ============================================================
  // Library Sync Endpoints
  // ============================================================

  /// Sync local library song IDs with server
  Future<Map<String, dynamic>> syncLibrary(List<int> songIds) async {
    try {
      final response = await _dio.post(
        '/library/sync/',
        data: {
          'song_ids': songIds,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }
      return {
        'success': false,
        'error': response.data['error'] ?? 'Sync failed',
      };
    } on DioException catch (e) {
      return _handleError(e, 'Sync failed');
    }
  }

  /// Fetch songs in user's personal library
  Future<Map<String, dynamic>?> fetchUserLibrary({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/library/',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } on DioException {
      return null;
    }
  }

  // ============================================================
  // Album Endpoints
  // ============================================================

  /// Fetch paginated list of albums
  Future<Map<String, dynamic>?> fetchAlbums({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? artistId,
    String? albumType,
    int? year,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (search != null) queryParams['search'] = search;
      if (artistId != null) queryParams['artist_id'] = artistId;
      if (albumType != null) queryParams['album_type'] = albumType;
      if (year != null) queryParams['year'] = year;

      final response = await _dio.get('/albums/', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Fetch a single album by ID
  Future<Album?> fetchAlbum(int id) async {
    try {
      final response = await _dio.get('/albums/$id/');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return Album.fromJson(data);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  // ============================================================
  // Artist Endpoints
  // ============================================================

  /// Fetch paginated list of artists
  Future<Map<String, dynamic>?> fetchArtists({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sort,
    String? order,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (search != null) queryParams['search'] = search;
      if (sort != null) queryParams['sort'] = sort;
      if (order != null) queryParams['order'] = order;

      final response = await _dio.get('/artists/', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Fetch a single artist by ID with full discography
  Future<ArtistDetail?> fetchArtist(int id) async {
    try {
      final response = await _dio.get('/artists/$id/');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return ArtistDetail.fromJson(data);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  // ============================================================
  // Helper Methods
  // ============================================================

  /// Handle Dio errors and return user-friendly messages
  Map<String, dynamic> _handleError(DioException e, String defaultMessage) {
    String errorMessage = defaultMessage;

    if (e.response != null) {
      // Server responded with error status
      final data = e.response!.data;
      if (data is Map && data.containsKey('error')) {
        if (data['error'] is String) {
          errorMessage = data['error'];
        } else if (data['error'] is Map) {
          // Validation errors
          final errors = data['error'] as Map;
          errorMessage = errors.values.first.toString();
        }
      } else if (data is Map && data.containsKey('detail')) {
        errorMessage = data['detail'].toString();
      }
    } else {
      // Network error
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection.';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'No internet connection.';
          break;
        default:
          errorMessage = 'An unexpected error occurred.';
      }
    }

    return {
      'success': false,
      'error': errorMessage,
    };
  }

  /// Test connection to the backend
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/');
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  /// Update base URL (for switching between dev/prod)
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }
}
