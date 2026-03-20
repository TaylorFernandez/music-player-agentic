# Plan: Library Sync Integration

This plan outlines the integration of automatic library metadata synchronization between the Flutter mobile application and the Django backend.

## 1. Backend Updates (Django)

### Model Changes
- Add a new model `UserSong` in `core/models.py`.
  - `user`: ForeignKey to `User`.
  - `song`: ForeignKey to `Song`.
  - `added_at`: DateTimeField.
  - `is_favorite`: BooleanField (optional, can sync with local favorites).
  - Unique constraint on `(user, song)`.

### API Updates
- Create a new endpoint `/api/library/sync/` in `api/views.py`.
  - **POST**: Accepts a list of `song_ids`.
  - Logic: Add or update the `UserSong` associations for the authenticated user.
  - **GET**: Returns the list of songs associated with the authenticated user.

### Web Interface Updates
- Update the **Dashboard** view to show the user's library count and a link to their library.
- Create a new **My Library** view and template (`web/library.html`) that lists the songs linked via `UserSong`.

## 2. Frontend Updates (Flutter)

### API Service
- Add `Future<bool> syncUserLibrary(List<int> songIds)` to `ApiService.dart`.

### Library Service
- Add `Future<void> syncWithServer()` method.
  - Check if `AuthProvider.isAuthenticated` is true.
  - Collect all `serverSongId`s from `_tracks`.
  - Call `apiService.syncUserLibrary(songIds)`.
- Trigger `syncWithServer()` automatically:
  - After a successful login.
  - After a full library scan (if logged in).
  - On application startup (if logged in).

### State Management
- Update `MusicProvider.dart` to expose a `syncLibrary()` method that uses `LibraryService`.

## 3. Integration & Testing

### Test Cases
- **Backend:** 
  - Verify `UserSong` creation via API.
  - Ensure users can only see their own library associations.
  - Test batch synchronization with 100+ songs.
- **Frontend:**
  - Verify sync is triggered after login.
  - Ensure sync only sends metadata (IDs/hashes) and never audio data.
  - Test offline behavior (queuing sync until connection is restored).

## 4. Security & Privacy
- Synchronization must require an active authentication token.
- User library data should be private to the account holder and accessible to moderators/owners for administrative purposes only.

---
**Status:** DRAFT (Awaiting Directive)
