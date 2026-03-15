import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:music_player_app/services/api_service.dart';
import 'package:music_player_app/services/audio_player_service.dart';
import 'package:music_player_app/services/library_service.dart';
import 'package:music_player_app/services/metadata_service.dart';
import 'package:music_player_app/services/song_matching_service.dart';
import 'package:music_player_app/main.dart';

void main() {
  testWidgets('Music Player App smoke test', (WidgetTester tester) async {
    // Create mock services for testing
    final apiService = ApiService(baseUrl: 'http://localhost:8000/api');
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

    // Build our app and trigger a frame.
    await tester.pumpWidget(MusicPlayerApp(
      apiService: apiService,
      audioPlayerService: audioPlayerService,
      libraryService: libraryService,
    ));

    // Verify that the app loads without errors.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify that the main screen is displayed.
    expect(find.byType(MainScreen), findsOneWidget);

    // Verify that the bottom navigation bar is present.
    expect(find.byType(NavigationBar), findsOneWidget);

    // Verify that the home destination is present.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
