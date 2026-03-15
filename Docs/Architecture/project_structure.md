# Project Structure

## Overview
This document outlines the recommended project structure for the Music Player application. The project is divided into three main components: Backend (Django), Frontend (Flutter), and Documentation. This structure ensures separation of concerns, maintainability, and scalability.

## Root Directory Structure
```
music-player-app/
├── backend/                 # Django backend project
├── frontend/                # Flutter mobile application
├── docs/                   # Project documentation (already created)
├── docker-compose.yml      # Docker configuration for development
├── README.md               # Project overview and setup instructions
└── .gitignore              # Git ignore rules
```

## Backend (Django) Structure
```
backend/
├── manage.py
├── requirements.txt
├── requirements-dev.txt
├── .env.example           # Example environment variables
├── docker-compose.yml    # Backend-specific Docker setup
├── Dockerfile
├── musicplayer/
│   ├── __init__.py
│   ├── settings.py       # Django settings (split by environment)
│   ├── urls.py           # Main URL configuration
│   ├── wsgi.py
│   └── asgi.py
├── apps/
│   ├── __init__.py
│   ├── accounts/         # User authentication and profiles
│   │   ├── __init__.py
│   │   ├── admin.py
│   │   ├── apps.py
│   │   ├── models.py     # UserProfile, etc.
│   │   ├── views.py
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   ├── permissions.py # Custom permissions for roles
│   │   ├── signals.py    # UserProfile signals
│   │   └── tests/
│   ├── music/            # Core music models and logic
│   │   ├── __init__.py
│   │   ├── admin.py
│   │   ├── apps.py
│   │   ├── models.py     # Song, Album, Artist, relationship models
│   │   ├── views.py      # Web views (for Django templates)
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   ├── managers.py   # Custom model managers
│   │   ├── utils.py      # Helper functions (e.g., metadata extraction)
│   │   ├── constants.py  # Constants (album types, roles, etc.)
│   │   └── tests/
│   ├── api/              # REST API (Django REST Framework)
│   │   ├── __init__.py
│   │   ├── viewsets.py   # ViewSets for Song, Album, Artist
│   │   ├── serializers.py
│   │   ├── urls.py       # API routing
│   │   ├── permissions.py # API permissions
│   │   ├── pagination.py # Custom pagination classes
│   │   ├── filters.py    # Filter classes for viewsets
│   │   └── tests/
│   ├── moderation/        # Change request and moderation system
│   │   ├── __init__.py
│   │   ├── admin.py
│   │   ├── apps.py
│   │   ├── models.py     # ChangeRequest model
│   │   ├── views.py      # Moderation views (web and API)
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   ├── signals.py    # Signals for change request status updates
│   │   └── tests/
│   └── web/              # Django templates and static files for web interface
│       ├── __init__.py
│       ├── apps.py
│       ├── views.py      # Web views (dashboard, management pages)
│       ├── urls.py
│       ├── templates/    # Django HTML templates
│       │   ├── base.html
│       │   ├── dashboard.html
│       │   ├── login.html
│       │   ├── song_list.html
│       │   ├── album_list.html
│       │   ├── artist_list.html
│       │   ├── moderation_queue.html
│       │   └── user_management.html
│       └── static/
│           ├── css/
│           ├── js/
│           ├── images/
│           └── favicon.ico
├── media/                # User-uploaded files (ignored in git)
├── static/               # Collected static files
└── scripts/              # Deployment and utility scripts
    ├── deploy.sh
    ├── backup_db.sh
    └── load_fixtures.sh
```

## Frontend (Flutter) Structure
```
frontend/
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── README.md
├── android/              # Android-specific files
├── ios/                  # iOS-specific files
├── lib/
│   ├── main.dart         # Application entry point
│   ├── app.dart          # Main app widget
│   ├── routes.dart       # Route definitions
│   ├── models/           # Data models (matching API responses)
│   │   ├── song.dart
│   │   ├── album.dart
│   │   ├── artist.dart
│   │   ├── user.dart
│   │   ├── change_request.dart
│   │   └── api_response.dart
│   ├── services/         # Business logic and API calls
│   │   ├── api_service.dart      # Base API service
│   │   ├── auth_service.dart     # Authentication service
│   │   ├── music_service.dart    # Music data service
│   │   ├── moderation_service.dart
│   │   ├── local_storage.dart    # Local data (Hive, SharedPreferences)
│   │   ├── metadata_extractor.dart # MP3 metadata reading
│   │   └── audio_player_service.dart # Audio playback
│   ├── providers/        # State management (Riverpod/Provider)
│   │   ├── auth_provider.dart
│   │   ├── music_provider.dart
│   │   ├── player_provider.dart
│   │   ├── theme_provider.dart
│   │   └── app_provider.dart
│   ├── screens/          # Screen widgets
│   │   ├── library/
│   │   │   ├── library_screen.dart
│   │   │   ├── songs_screen.dart
│   │   │   ├── albums_screen.dart
│   │   │   └── artists_screen.dart
│   │   ├── player/
│   │   │   ├── now_playing_screen.dart
│   │   │   └── mini_player.dart
│   │   ├── playlist/
│   │   │   ├── playlists_screen.dart
│   │   │   ├── playlist_detail_screen.dart
│   │   │   └── edit_playlist_screen.dart
│   │   ├── search/
│   │   │   ├── search_screen.dart
│   │   │   └── search_results_screen.dart
│   │   ├── settings/
│   │   │   ├── settings_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   └── profile_screen.dart
│   │   └── moderation/   # Moderation screens (for moderators/owners)
│   │       ├── change_requests_screen.dart
│   │       └── change_request_detail_screen.dart
│   ├── widgets/          # Reusable UI components
│   │   ├── common/
│   │   │   ├── app_bar.dart
│   │   │   ├── bottom_nav_bar.dart
│   │   │   ├── drawer.dart
│   │   │   ├── loading_indicator.dart
│   │   │   └── error_widget.dart
│   │   ├── music/
│   │   │   ├── song_tile.dart
│   │   │   ├── album_card.dart
│   │   │   ├── artist_card.dart
│   │   │   ├── playback_controls.dart
│   │   │   ├── seek_bar.dart
│   │   │   └── lyrics_viewer.dart
│   │   └── forms/
│   │       ├── text_field.dart
│   │       ├── dropdown.dart
│   │       └── button.dart
│   ├── utils/            # Utilities and helpers
│   │   ├── constants.dart   # App constants (colors, strings, etc.)
│   │   ├── extensions.dart  # Dart extensions
│   │   ├── validators.dart  # Form validators
│   │   ├── date_formatter.dart
│   │   ├── file_picker.dart
│   │   └── logger.dart
│   └── theme/            # App theming
│       ├── app_theme.dart
│       ├── colors.dart
│       ├── text_styles.dart
│       └── app_icons.dart
├── assets/
│   ├── images/           # Images and icons
│   │   ├── logo.png
│   │   ├── logo_dark.png
│   │   ├── placeholder_album.png
│   │   └── placeholder_artist.png
│   ├── icons/            # Custom icons (if any)
│   └── fonts/            # Custom fonts
└── test/                 # Unit and widget tests
    ├── widget_test.dart
    ├── unit_test.dart
    └── mocks/
```

## Documentation Structure (Already Created)
```
docs/
├── Plans/
│   └── development_plan.md
├── Architecture/
│   ├── database_schema.md
│   ├── api_specification.md
│   └── project_structure.md
├── API_Documentation/
│   └── api_specification.md
├── UI_Design/
│   └── ui_specification.md
├── Testing/
│   ├── test_cases.md
│   └── manual_testing.md
├── Deployment/
│   ├── setup_guide.md
│   └── production_checklist.md
└── Meeting_Notes/        # For future meeting notes
    └── README.md
```

## Development Environment Setup

### Backend Setup
1. Create a virtual environment: `python -m venv venv`
2. Install dependencies: `pip install -r backend/requirements.txt`
3. Set up environment variables (copy `.env.example` to `.env` and configure)
4. Run migrations: `python manage.py migrate`
5. Create a superuser: `python manage.py createsuperuser`
6. Run the development server: `python manage.py runserver`

### Frontend Setup
1. Install Flutter SDK (version 3.x or higher)
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run`

### Database
- PostgreSQL is required for production. For development, you can use SQLite or PostgreSQL.
- Update the Django settings to use the appropriate database.

## Deployment Considerations
- Use Docker for containerization of the backend.
- The Flutter app can be built for Android and iOS using the respective build systems.
- The web interface (Django templates) is served by the backend and should be behind a web server (Nginx) in production.

## Notes
- The `media/` directory in the backend should be excluded from version control and served via a media server or CDN in production.
- The Flutter app uses a state management solution (Riverpod recommended) for scalability.
- API versioning is implemented in the backend (e.g., `/api/v1/`).
- All sensitive configuration (API keys, database passwords) should be stored in environment variables.

This structure is designed to be modular and scalable. Each Django app is focused on a specific domain, and the Flutter app follows a feature-based organization within the `lib/` directory.