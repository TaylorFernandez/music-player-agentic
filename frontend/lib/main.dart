import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/api_service.dart';
import 'services/audio_player_service.dart';
import 'services/library_service.dart';
import 'services/metadata_service.dart';
import 'services/song_matching_service.dart';
import 'providers/auth_provider.dart';
import 'providers/music_provider.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize services
  final apiService = ApiService(
    baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api',
  );

  final audioPlayerService = AudioPlayerService();
  await audioPlayerService.initialize();

  final metadataService = MetadataService();
  final songMatchingService = SongMatchingService(
    apiService: apiService,
    metadataService: metadataService,
  );

  final libraryService = LibraryService(
    metadataService: metadataService,
    songMatchingService: songMatchingService,
    apiService: apiService,
  );
  await libraryService.initialize();

  runApp(MusicPlayerApp(
    apiService: apiService,
    audioPlayerService: audioPlayerService,
    libraryService: libraryService,
  ));
}

class MusicPlayerApp extends StatelessWidget {
  final ApiService apiService;
  final AudioPlayerService audioPlayerService;
  final LibraryService libraryService;

  const MusicPlayerApp({
    super.key,
    required this.apiService,
    required this.audioPlayerService,
    required this.libraryService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<AudioPlayerService>.value(value: audioPlayerService),
        ChangeNotifierProvider<LibraryService>.value(value: libraryService),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(apiService),
        ),
        ChangeNotifierProvider<MusicProvider>(
          create: (context) => MusicProvider(
            apiService: apiService,
            audioPlayerService: audioPlayerService,
            libraryService: libraryService,
          ),
        ),
      ],
      child: MaterialApp(
        title: dotenv.env['APP_NAME'] ?? 'Music Player',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme, // Default to dark
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LibraryScreen(),
    const SearchScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Use addPostFrameCallback to avoid calling notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final musicProvider = context.read<MusicProvider>();

      await authProvider.checkAuthStatus();

      // Trigger library sync if authenticated
      if (authProvider.isAuthenticated) {
        debugPrint('User is authenticated, triggering library sync...');
        await musicProvider.syncLibrary();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
