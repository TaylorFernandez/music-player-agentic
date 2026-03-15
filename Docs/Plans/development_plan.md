# Music Player App - Development Plan

## Project Overview

This project aims to create an intelligent MP3 player that connects to a server to enrich the user's music experience. The core concept is that the app does NOT store actual MP3 files but uses metadata from local MP3 files to identify songs and retrieve additional information from a centralized database.

### Key Features:
1. **Basic MP3 Player**: Playback, playlist management, and standard music player controls
2. **Server Integration**: Connect to a Django backend to fetch enriched song data (lyrics, artwork, artist bios, etc.)
3. **Multi-Platform**: Flutter app for mobile, Django web interface for data management
4. **Role-Based Access Control**: Three user roles (General User, Moderator, Owner) with progressive permissions
5. **Moderation System**: All user-submitted changes require moderator approval (except owner-optional)

## Technology Stack

### Backend
- **Framework**: Django 4.x
- **Database**: PostgreSQL
- **Authentication**: Django Allauth (for username/password and Google SSO)
- **API**: Django REST Framework (DRF)
- **Templating**: Django Templates for web interface

### Frontend (Mobile)
- **Framework**: Flutter 3.x (Dart)
- **Audio Playback**: just_audio or audioplayers package
- **Metadata Reading**: mp3_info or similar package
- **HTTP Client**: Dio or http package

### Infrastructure
- **Version Control**: Git
- **Containerization**: Docker (optional for development)
- **Deployment**: TBD (could be Heroku, AWS, or similar)

## Architecture Design

### High-Level Architecture
```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Flutter App   │────▶│   Django API    │────▶│   PostgreSQL     │
│   (Mobile)      │◀────│   (Backend)     │◀────│   (Database)     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │
         │                       │
         │               ┌─────────────────┐
         └───────────────│   Web Interface │
                         │   (Django       │
                         │    Templates)   │
                         └─────────────────┘
```

### Component Breakdown
1. **Mobile App (Flutter)**: Provides music playback and basic UI, sends metadata to server
2. **Backend API (Django REST Framework)**: Handles business logic, data retrieval, and user management
3. **Database (PostgreSQL)**: Stores song, album, artist data and user change requests
4. **Web Interface (Django Templates)**: Admin panel for data management and moderation

## Database Schema

### Core Entities

#### Artist
- `id` (Primary Key)
- `name` (String, unique)
- `image` (ImageField or URL)
- `bio` (TextField)
- `created_at` (DateTime)
- `updated_at` (DateTime)

#### Album
- `id` (Primary Key)
- `title` (String)
- `album_type` (ChoiceField: Album, EP, Single, etc.)
- `release_date` (Date, nullable)
- `cover_art` (ImageField or URL)
- `description` (TextField)
- `created_at` (DateTime)
- `updated_at` (DateTime)

#### Song
- `id` (Primary Key)
- `title` (String)
- `duration` (Integer, in seconds)
- `file_hash` (CharField, for identifying duplicate songs)
- `lyrics` (TextField)
- `artwork` (ImageField or URL, song-specific)
- `created_at` (DateTime)
- `updated_at` (DateTime)

### Relationship Tables

#### AlbumArtists (Many-to-Many)
- `album_id` (ForeignKey to Album)
- `artist_id` (ForeignKey to Artist)

#### SongAlbums (Many-to-Many)
- `song_id` (ForeignKey to Song)
- `album_id` (ForeignKey to Album)
- `track_number` (Integer, nullable)

#### SongArtists (Many-to-Many)
- `song_id` (ForeignKey to Song)
- `artist_id` (ForeignKey to Artist)
- `role` (ChoiceField: Main, Featured, Producer, etc.)

### User Management & Moderation

#### UserProfile (extends Django User)
- `user` (OneToOne to User)
- `role` (ChoiceField: general, moderator, owner)
- `avatar` (ImageField, optional)

#### ChangeRequest
- `id` (Primary Key)
- `user` (ForeignKey to User)
- `model_type` (ChoiceField: song, album, artist)
- `model_id` (Integer)
- `field_name` (String)
- `old_value` (TextField)
- `new_value` (TextField)
- `status` (ChoiceField: pending, approved, rejected)
- `reviewed_by` (ForeignKey to User, nullable)
- `reviewed_at` (DateTime, nullable)
- `created_at` (DateTime)
- `notes` (TextField, for moderator comments)

## Backend API Design

### Authentication Endpoints
- `POST /api/auth/register/` - User registration
- `POST /api/auth/login/` - Username/password login
- `POST /api/auth/google/` - Google SSO
- `POST /api/auth/logout/` - Logout
- `GET /api/auth/me/` - Current user info

### Song Endpoints
- `GET /api/songs/` - List all songs (with filtering)
- `GET /api/songs/{id}/` - Get song details
- `POST /api/songs/lookup/` - Lookup song by metadata (title, artist, duration hash)
- `PUT /api/songs/{id}/` - Update song (requires moderation)
- `GET /api/songs/{id}/lyrics/` - Get song lyrics

### Album Endpoints
- `GET /api/albums/` - List all albums
- `GET /api/albums/{id}/` - Get album details with songs
- `PUT /api/albums/{id}/` - Update album (requires moderation)

### Artist Endpoints
- `GET /api/artists/` - List all artists
- `GET /api/artists/{id}/` - Get artist details with discography
- `PUT /api/artists/{id}/` - Update artist (requires moderation)

### Moderation Endpoints
- `GET /api/moderation/change-requests/` - List pending change requests
- `POST /api/moderation/change-requests/{id}/review/` - Approve/reject change request
- `GET /api/moderation/history/` - View moderation history

## Flutter App Design

### Core Features
1. **Local Music Scanning**: Scan device for MP3 files, extract metadata
2. **Audio Playback**: Play, pause, next, previous, seek, shuffle, repeat
3. **Playlist Management**: Create, edit, delete playlists
4. **Server Sync**: Match local songs with server database
5. **Offline Mode**: Basic playback without server connection

### UI Screens
1. **Library Screen**: List of songs, albums, artists
2. **Now Playing Screen**: Current song with controls, lyrics display
3. **Playlist Screen**: Create and manage playlists
4. **Search Screen**: Search local and server database
5. **Settings Screen**: App preferences, login/logout

### Key Packages
- `just_audio` or `audioplayers` for audio playback
- `file_picker` for selecting music files
- `flutter_secure_storage` for storing tokens
- `dio` for HTTP requests
- `provider` or `riverpod` for state management
- `cached_network_image` for artwork

## Web Interface Design

### Pages
1. **Login Page**: User authentication
2. **Dashboard**: Overview of songs, albums, artists
3. **Song Management**: View, edit, approve song data
4. **Album Management**: View, edit, approve album data
5. **Artist Management**: View, edit, approve artist data
6. **Moderation Queue**: Review user-submitted changes
7. **User Management**: Manage user roles (owner-only)

### Design Guidelines
- Use Django template inheritance for consistent layout
- Bootstrap 5 for responsive design
- Custom CSS for branding
- Match logo and favicon with mobile app

## Authentication and Authorization

### User Roles
1. **General User** (unauthenticated or logged in):
   - View all song/album/artist data
   - Submit change requests (requires moderation)
   - Basic MP3 player functionality

2. **Moderator**:
   - All general user permissions
   - Approve/reject/edit change requests
   - Direct edits still require second moderator review

3. **Owner**:
   - All moderator permissions
   - Make direct changes without review (optional)
   - Manage user roles

### Implementation Details
- Use Django's built-in permission system
- Custom middleware for role-based access
- JWT or session-based authentication for API
- OAuth2 for Google SSO integration

## Development Phases

### Phase 1: Foundation (Week 1-2)
- Set up Django project with PostgreSQL
- Create basic models (Song, Album, Artist)
- Implement authentication system
- Set up Flutter project structure
- Basic audio playback in Flutter

### Phase 2: Core Functionality (Week 3-4)
- Implement metadata extraction in Flutter
- Create API endpoints for data retrieval
- Build basic web interface for data viewing
- Implement song matching logic (local ↔ server)

### Phase 3: User Features (Week 5-6)
- Playlist management in Flutter
- Search functionality (local and server)
- Lyrics display
- User profile management

### Phase 4: Moderation System (Week 7-8)
- Change request model and API
- Moderation interface in web app
- Notification system for pending reviews
- Role-based access control

### Phase 5: Polish & Testing (Week 9-10)
- UI/UX refinements
- Logo and branding consistency
- Error handling and edge cases
- Performance optimization
- Documentation

## File Organization in Docs

```
Docs/
├── Plans/
│   └── development_plan.md (this file)
├── Architecture/
│   ├── database_diagram.md
│   └── api_specification.md
├── UI_Design/
│   ├── flutter_wireframes.md
│   └── web_wireframes.md
├── API_Documentation/
│   ├── endpoints.md
│   └── authentication_flow.md
├── Testing/
│   ├── test_cases.md
│   └── manual_testing.md
└── Deployment/
    ├── setup_guide.md
    └── production_checklist.md
```

## Next Steps

1. Create detailed database schema with Django models
2. Set up development environment (virtualenv, Flutter SDK)
3. Begin implementing Phase 1 components
4. Regular progress updates in Docs folder

## Notes and Considerations

1. **Privacy**: The app never uploads actual MP3 files, only metadata
2. **Performance**: Cache server responses in Flutter app for offline use
3. **Scalability**: Database indexing on frequently queried fields
4. **Legal**: Ensure compliance with music licensing for lyrics/artwork
5. **Accessibility**: Follow WCAG guidelines for web and mobile interfaces

---
*Last Updated: [Date]*
*Project Status: Planning Phase*