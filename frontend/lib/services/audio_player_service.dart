import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import '../models/song.dart';

/// Model class representing a track in the playlist.
/// Contains both the Song model and the local file path for playback.
class LocalTrack {
  final Song song;
  final String localPath;
  final String? artworkPath;
  final Duration? duration;

  LocalTrack({
    required this.song,
    required this.localPath,
    this.artworkPath,
    this.duration,
  });

  /// Creates a LocalTrack from extracted metadata and matched song
  factory LocalTrack.fromMetadata({
    required Song song,
    required String localPath,
    String? artworkPath,
  }) {
    return LocalTrack(
      song: song,
      localPath: localPath,
      artworkPath: artworkPath,
      duration: Duration(seconds: song.duration),
    );
  }
}

/// Service for handling audio playback using just_audio.
/// Manages the audio player, playlist queue, and playback state.
class AudioPlayerService extends ChangeNotifier {
  late final AudioPlayer _player;
  late final AudioSession _session;

  // Playlist state
  final List<LocalTrack> _playlist = [];
  int _currentIndex = -1;
  LocalTrack? _currentTrack;

  // Shuffle state
  bool _shuffle = false;
  List<int> _shuffleOrder = [];
  int _shuffleIndex = -1;

  // Repeat mode
  RepeatMode _repeatMode = RepeatMode.off;

  // Loading state
  bool _isLoading = false;
  String? _errorMessage;

  // Stream subscriptions
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _currentIndexSubscription;

  // Getters
  AudioPlayer get player => _player;
  List<LocalTrack> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  LocalTrack? get currentTrack => _currentTrack;
  bool get shuffle => _shuffle;
  RepeatMode get repeatMode => _repeatMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Initialize the audio player service
  Future<void> initialize() async {
    // Create audio player
    _player = AudioPlayer();

    // Configure audio session
    _session = await AudioSession.instance;
    await _session.configure(const AudioSessionConfiguration.music());

    // Listen to player state changes
    _playerStateSubscription = _player.playerStateStream.listen(_onPlayerStateChanged);
    _positionSubscription = _player.positionStream.listen(_onPositionChanged);
    _durationSubscription = _player.durationStream.listen(_onDurationChanged);
    _currentIndexSubscription = _player.currentIndexStream.listen(_onCurrentIndexChanged);

    notifyListeners();
  }

  /// Handle player state changes
  void _onPlayerStateChanged(PlayerState state) {
    if (state.processingState == ProcessingState.completed) {
      _onTrackCompleted();
    }
    notifyListeners();
  }

  /// Handle position changes
  void _onPositionChanged(Duration position) {
    notifyListeners();
  }

  /// Handle duration changes
  void _onDurationChanged(Duration? duration) {
    notifyListeners();
  }

  /// Handle current index changes (for ConcatenatingAudioSource)
  void _onCurrentIndexChanged(int? index) {
    if (index != null && index != _currentIndex) {
      _currentIndex = index;
      if (index >= 0 && index < _playlist.length) {
        _currentTrack = _playlist[index];
      }
      notifyListeners();
    }
  }

  /// Handle track completion
  void _onTrackCompleted() {
    if (_repeatMode == RepeatMode.one) {
      // Repeat one: seek to beginning and continue playing
      _player.seek(Duration.zero);
      _player.play();
    } else {
      // Play next track or stop
      next();
    }
  }

  /// Add a track to the playlist
  void addToPlaylist(LocalTrack track) {
    _playlist.add(track);
    _shuffleOrder = List.generate(_playlist.length, (i) => i);
    notifyListeners();
  }

  /// Add multiple tracks to the playlist
  void addAllToPlaylist(List<LocalTrack> tracks) {
    _playlist.addAll(tracks);
    _shuffleOrder = List.generate(_playlist.length, (i) => i);
    notifyListeners();
  }

  /// Remove a track from the playlist
  void removeFromPlaylist(int index) {
    if (index < 0 || index >= _playlist.length) return;

    _playlist.removeAt(index);

    // Update shuffle order
    _shuffleOrder = List.generate(_playlist.length, (i) => i);

    // Update current index if needed
    if (_currentIndex >= index && _currentIndex > 0) {
      _currentIndex--;
    }

    // Update current track
    if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
      _currentTrack = _playlist[_currentIndex];
    } else {
      _currentTrack = null;
    }

    notifyListeners();
  }

  /// Clear the entire playlist
  void clearPlaylist() {
    _playlist.clear();
    _shuffleOrder.clear();
    _currentIndex = -1;
    _shuffleIndex = -1;
    _currentTrack = null;
    _player.stop();
    notifyListeners();
  }

  /// Play a specific track from the playlist
  Future<void> playTrack(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final track = _playlist[index];
      final filePath = track.localPath;

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      // Set audio source
      final audioSource = AudioSource.uri(Uri.file(filePath));
      await _player.setAudioSource(audioSource);

      _currentIndex = index;
      _currentTrack = track;

      // Start playback
      await _player.play();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to play track: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Play the current track (resume if paused)
  Future<void> play() async {
    if (_currentTrack == null && _playlist.isNotEmpty) {
      await playTrack(0);
    } else {
      await _player.play();
    }
  }

  /// Pause playback
  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
    _currentIndex = -1;
    _currentTrack = null;
    notifyListeners();
  }

  /// Seek to a specific position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Seek to next track
  Future<void> next() async {
    if (_playlist.isEmpty) return;

    if (_shuffle) {
      // Shuffle mode: play next track in shuffle order
      _shuffleIndex++;
      if (_shuffleIndex >= _shuffleOrder.length) {
        if (_repeatMode == RepeatMode.all) {
          _shuffleIndex = 0;
          // Regenerate shuffle order
          _shuffleOrder.shuffle();
        } else {
          _shuffleIndex = _shuffleOrder.length - 1;
          return;
        }
      }
      final actualIndex = _shuffleOrder[_shuffleIndex];
      await playTrack(actualIndex);
    } else {
      // Normal mode: play next track
      int nextIndex = _currentIndex + 1;
      if (nextIndex >= _playlist.length) {
        if (_repeatMode == RepeatMode.all) {
          nextIndex = 0;
        } else {
          return;
        }
      }
      await playTrack(nextIndex);
    }
  }

  /// Seek to previous track
  Future<void> previous() async {
    if (_playlist.isEmpty) return;

    // If current position > 3 seconds, restart current track
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    if (_shuffle) {
      // Shuffle mode: play previous track in shuffle order
      _shuffleIndex--;
      if (_shuffleIndex < 0) {
        if (_repeatMode == RepeatMode.all) {
          _shuffleIndex = _shuffleOrder.length - 1;
        } else {
          _shuffleIndex = 0;
          await _player.seek(Duration.zero);
          return;
        }
      }
      final actualIndex = _shuffleOrder[_shuffleIndex];
      await playTrack(actualIndex);
    } else {
      // Normal mode: play previous track
      int prevIndex = _currentIndex - 1;
      if (prevIndex < 0) {
        if (_repeatMode == RepeatMode.all) {
          prevIndex = _playlist.length - 1;
        } else {
          await _player.seek(Duration.zero);
          return;
        }
      }
      await playTrack(prevIndex);
    }
  }

  /// Toggle shuffle mode
  Future<void> toggleShuffle() async {
    _shuffle = !_shuffle;

    if (_shuffle) {
      // Generate shuffle order
      _shuffleOrder = List.generate(_playlist.length, (i) => i);
      _shuffleOrder.shuffle();

      // Find current track in shuffle order
      final currentTrackIndex = _currentIndex;
      _shuffleIndex = _shuffleOrder.indexOf(currentTrackIndex);
    } else {
      // Reset to normal order
      _shuffleOrder = List.generate(_playlist.length, (i) => i);
      _shuffleIndex = _currentIndex;
    }

    notifyListeners();
  }

  /// Set shuffle mode
  void setShuffle(bool enabled) {
    if (_shuffle != enabled) {
      toggleShuffle();
    }
  }

  /// Toggle repeat mode
  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
  }

  /// Set repeat mode
  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
    notifyListeners();
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
    notifyListeners();
  }

  /// Get current volume
  double get volume => _player.volume;

  /// Set playback speed (0.25 to 4.0)
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed.clamp(0.25, 4.0));
    notifyListeners();
  }

  /// Get current playback speed
  double get speed => _player.speed;

  /// Play a list of tracks
  Future<void> playAll(List<LocalTrack> tracks, {int startIndex = 0}) async {
    clearPlaylist();
    addAllToPlaylist(tracks);
    if (_playlist.isNotEmpty) {
      await playTrack(startIndex.clamp(0, _playlist.length - 1));
    }
  }

  /// Get formatted position string (MM:SS)
  String get formattedPosition {
    final position = _player.position;
    final minutes = position.inMinutes;
    final seconds = position.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get formatted duration string (MM:SS)
  String? get formattedDuration {
    final duration = _player.duration;
    if (duration == null) return null;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progress {
    final duration = _player.duration;
    final position = _player.position;
    if (duration == null || duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  /// Seek to progress percentage (0.0 to 1.0)
  Future<void> seekToProgress(double progress) async {
    final duration = _player.duration;
    if (duration == null) return;
    final position = Duration(milliseconds: (progress * duration.inMilliseconds).round());
    await seek(position);
  }

  /// Dispose of the audio player
  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}

/// Enum for repeat modes
enum RepeatMode {
  off,
  one,
  all,
}
