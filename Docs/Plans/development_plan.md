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

## Database Schema

### Core Entities

#### Artist
- `id` (Primary Key)
- `name` (String, unique)
- `image` (ImageField or URL)
- `bio` (TextField)

#### Album
- `id` (Primary Key)
- `title` (String)
- `album_type` (ChoiceField: Album, EP, Single, etc.)
- `release_date` (Date, nullable)
- `cover_art` (ImageField or URL)
- `description` (TextField)

#### Song
- `id` (Primary Key)
- `title` (String)
- `duration` (Integer, in seconds)
- `file_hash` (CharField)
- `lyrics` (TextField)
- `artwork` (ImageField or URL)

### User Management & Moderation

#### UserProfile (extends Django User)
- `user` (OneToOne to User)
- `role` (ChoiceField: general, moderator, owner)

#### ChangeRequest
- `id` (Primary Key)
- `user` (ForeignKey to User)
- `model_type` (ChoiceField: song, album, artist)
- `model_id` (Integer)
- `field_name` (String)
- `old_value` (TextField)
- `new_value` (TextField)
- `status` (ChoiceField: pending, approved, rejected)

## Development Phases

### Phase 1: Foundation (Completed)
- Set up Django project with PostgreSQL
- Create basic models (Song, Album, Artist)
- Implement authentication system
- Set up Flutter project structure
- Basic audio playback in Flutter

### Phase 2: Core Functionality (Completed)
- Implement metadata extraction in Flutter
- Create API endpoints for data retrieval
- Build basic web interface for data viewing
- Implement song matching logic (local ↔ server)

### Phase 3: User Features (Completed)
- Playlist management in Flutter
- Search functionality (local and server)
- Lyrics display
- User profile management

### Phase 4: Moderation System (Completed)
- Change request model and API
- Moderation interface in web app
- Role-based access control

### Phase 5: Initial Polish & Testing (Completed)
- UI/UX refinements
- Error handling and edge cases
- Performance optimization

### Phase 6: Feature Completion (Current)
- **Backend (Web Interface)**:
    - Implement web-based playback functionality for Songs, Albums, and Artists.
    - Implement the "Add Song" form and processing logic.
    - Complete the moderation logic for creating new objects (handling `model_id == 0`).
- **Frontend (Mobile App)**:
    - Implement the User Profile screen.
    - Implement Privacy Settings, Privacy Policy, and Terms of Service screens.
    - Implement the "Share" functionality in the Now Playing screen.

### Phase 7: UI Redesign (Visual Overhaul)
- **Frontend Redesign**:
    - Implement a full UI overhaul based on `UI Design Templates/Frontend`.
    - Apply the modern dark/gradient aesthetic seen in `lyrics and player.webp` and `musicplayer.png`.
    - Revamp the login experience based on `login screen.webp`.
- **Backend Redesign**:
    - Redesign the Django web interface based on `UI Design Templates/Backend`.
    - Implement the new Dashboard layout from `site dashboard.webp`.
    - Apply the professional styling to the login screen from `login screen.webp`.
- **Branding**:
    - Ensure logo and favicon consistency across both platforms as per project requirements.

### Phase 8: Final Validation & Delivery
- Comprehensive testing of all new features.
- Final visual audit against design templates.
- Bug fixing and performance tuning.
- Final documentation update.

## UI Design Reference

### Mobile (Flutter)
Designs located in `./UI Design Templates/Frontend/`:
- `login screen.webp`: Modern login interface with centered logo.
- `lyrics and player.webp`: High-fidelity player view with integrated lyrics.
- `musicplayer.png`: Main library and player navigation interface.

### Web (Django)
Designs located in `./UI Design Templates/Backend/`:
- `login screen.webp`: Clean, centered login form.
- `site dashboard.webp`: Sidebar-driven dashboard with data visualizations and management tables.

---
*Last Updated: March 19, 2026*
*Project Status: Phase 6 - Feature Completion*
