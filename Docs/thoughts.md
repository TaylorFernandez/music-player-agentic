# Architectural Thoughts - Library Sync Integration

## Objective
Implement a system where a logged-in user's local MP3 metadata (identified via file hashes) is synchronized with the Django backend. This allows users to see "their media" on the web interface as required by the project goals.

## Constraints
- **NO MP3 FILES:** We must never upload or store the actual audio data.
- **Privacy:** Sync should only happen when logged in.
- **Performance:** Batch operations are necessary for large libraries.
- **Moderation:** If a user has a song that doesn't exist on the server, they should be able to "request" its addition (existing moderation flow).

## Components to Add/Modify

### 1. Backend (Django)
- **New Model:** `UserLibrary` or `UserSong` to link `User` to `Song`.
- **API Endpoint:** `POST /api/library/sync/` to accept a list of song IDs or hashes.
- **Web View:** Update the dashboard or add a `/library/` page to display the authenticated user's associated songs.

### 2. Frontend (Flutter)
- **LibraryService Update:** Add logic to detect login state and trigger a sync.
- **Sync Logic:** 
    1. Filter local tracks that have a `serverSongId`.
    2. Send these IDs to the new sync endpoint.
    3. (Optional) For tracks without a `serverSongId`, provide an option to submit them to the global database via the existing moderation system.

### 3. Data Flow
- User logs in -> Flutter app scans local library -> App filters matched songs -> App sends IDs to Server -> Server creates/updates associations -> Web interface reflects the user's library.
