import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Provider for managing authentication state in the music player app.
/// Handles user login, registration, logout, and maintains auth state.
class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentUser;

  AuthProvider(this._apiService);

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get username => _currentUser?['username'];
  String? get userEmail => _currentUser?['email'];
  String? get userRole => _currentUser?['role'];

  /// Check if user is already authenticated on app start
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isAuth = await _apiService.isAuthenticated();
      _isAuthenticated = isAuth;

      if (isAuth) {
        // Fetch current user data
        final userData = await _apiService.getCurrentUser();
        _currentUser = userData;
      }
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.register(
        username: username,
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        _isAuthenticated = true;
        _currentUser = result['user'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with username and password
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.login(
        username: username,
        password: password,
      );

      if (result['success'] == true) {
        _isAuthenticated = true;
        _currentUser = result['user'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
    } catch (e) {
      // Even if logout fails on server, clear local state
      debugPrint('Logout error: $e');
    } finally {
      _isAuthenticated = false;
      _currentUser = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear any error messages
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Update user profile (if supported by API)
  Future<bool> updateProfile({
    String? email,
    String? avatarUrl,
  }) async {
    // This would be implemented if the API supports profile updates
    // For now, just return true
    return true;
  }

  /// Check if user has a specific role
  bool hasRole(String role) {
    return _currentUser?['role'] == role;
  }

  /// Check if user is owner
  bool get isOwner => hasRole('owner');

  /// Check if user is moderator
  bool get isModerator => hasRole('moderator');

  /// Check if user can moderate content
  bool get canModerate => isOwner || isModerator;
}
