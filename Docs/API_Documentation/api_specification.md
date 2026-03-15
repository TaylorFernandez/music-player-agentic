# API Specification

## Overview
This document outlines the REST API for the Music Player application. The API follows RESTful conventions and uses JSON for request/response data. All endpoints are prefixed with `/api/`.

### Base URL
```
http://localhost:8000/api/  # Development
https://api.example.com/api/  # Production
```

### Authentication
- **Session-based**: For web interface (Django templates)
- **Token-based**: For mobile app (Flutter)
- **JWT optional**: For stateless authentication

All API endpoints (except public ones) require authentication via:
1. `Authorization: Bearer <token>` header (for token auth)
2. Session cookie (for web interface)

### Response Format
Successful responses:
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional message"
}
```

Error responses:
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": { ... }  // Optional additional details
  }
}
```

### Common Status Codes
- `200 OK`: Successful request
- `201 Created`: Resource created successfully
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Authentication required
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

## Endpoints

### Authentication

#### 1. Register User
**POST** `/auth/register/`

Creates a new user account.

**Request Body:**
```json
{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "securepassword123",
  "password2": "securepassword123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user_id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "role": "general"
  },
  "message": "Registration successful"
}
```

#### 2. Login (Username/Password)
**POST** `/auth/login/`

Authenticates user with username and password.

**Request Body:**
```json
{
  "username": "johndoe",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user_id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "role": "general",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

#### 3. Google SSO Login
**POST** `/auth/google/`

Authenticates user using Google OAuth2.

**Request Body:**
```json
{
  "access_token": "google_access_token_here"
}
```

**Response:** Same as username/password login

#### 4. Logout
**POST** `/auth/logout/`

Invalidates the current session/token.

**Response:**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

#### 5. Get Current User
**GET** `/auth/me/`

Returns information about the currently authenticated user.

**Response:**
```json
{
  "success": true,
  "data": {
    "user_id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "role": "general",
    "avatar_url": "https://example.com/media/avatars/user1.jpg"
  }
}
```

### Songs

#### 1. List Songs
**GET** `/songs/`

Returns a paginated list of songs. Supports filtering, searching, and sorting.

**Query Parameters:**
- `page`: Page number (default: 1)
- `page_size`: Items per page (default: 20, max: 100)
- `search`: Search in title and artist names
- `artist_id`: Filter by artist
- `album_id`: Filter by album
- `sort`: Sort field (title, duration, created_at)
- `order`: Sort order (asc, desc)

**Response:**
```json
{
  "success": true,
  "data": {
    "count": 1250,
    "next": "http://localhost:8000/api/songs/?page=2",
    "previous": null,
    "results": [
      {
        "id": 1,
        "title": "Bohemian Rhapsody",
        "duration": 354,
        "file_hash": "a1b2c3d4e5f6...",
        "lyrics": "Is this the real life? Is this just fantasy?...",
        "artwork_url": "https://example.com/media/song_artwork/1.jpg",
        "artists": [
          {
            "id": 1,
            "name": "Queen",
            "role": "main"
          }
        ],
        "albums": [
          {
            "id": 1,
            "title": "A Night at the Opera",
            "track_number": 1
          }
        ],
        "created_at": "2023-10-01T12:00:00Z",
        "updated_at": "2023-10-01T12:00:00Z"
      }
    ]
  }
}
```

#### 2. Get Song Details
**GET** `/songs/{id}/`

Returns detailed information about a specific song.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "title": "Bohemian Rhapsody",
    "duration": 354,
    "file_hash": "a1b2c3d4e5f6...",
    "lyrics": "Full lyrics here...",
    "artwork_url": "https://example.com/media/song_artwork/1.jpg",
    "artists": [
      {
        "id": 1,
        "name": "Queen",
        "image_url": "https://example.com/media/artists/1.jpg",
        "role": "main"
      }
    ],
    "albums": [
      {
        "id": 1,
        "title": "A Night at the Opera",
        "album_type": "album",
        "cover_url": "https://example.com/media/album_covers/1.jpg",
        "track_number": 1,
        "release_date": "1975-11-21"
      }
    ],
    "created_at": "2023-10-01T12:00:00Z",
    "updated_at": "2023-10-01T12:00:00Z"
  }
}
```

#### 3. Lookup Song by Metadata
**POST** `/songs/lookup/`

Attempts to find a song in the database using metadata extracted from an MP3 file.

**Request Body:**
```json
{
  "title": "Bohemian Rhapsody",
  "artist": "Queen",
  "duration": 354,
  "file_hash": "a1b2c3d4e5f6...",
  "album": "A Night at the Opera"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "match_type": "exact",  // "exact", "partial", or "none"
    "confidence": 0.95,
    "song": {
      "id": 1,
      "title": "Bohemian Rhapsody",
      // ... full song details
    },
    "suggestions": [
      // Array of similar songs if not exact match
    ]
  }
}
```

#### 4. Update Song (with moderation)
**PUT** `/songs/{id}/`

Updates song information. For general users, creates a change request. For moderators/owners, may apply directly.

**Request Body:**
```json
{
  "title": "Updated Song Title",
  "lyrics": "Updated lyrics...",
  "skip_review": false  // Owners only: bypass moderation
}
```

**Response (General User):**
```json
{
  "success": true,
  "data": {
    "change_request_id": 42,
    "status": "pending",
    "message": "Change submitted for moderator review"
  }
}
```

**Response (Moderator/Owner with skip_review=false):**
```json
{
  "success": true,
  "data": {
    "change_request_id": 42,
    "status": "pending",
    "message": "Change submitted for second moderator review"
  }
}
```

**Response (Owner with skip_review=true):**
```json
{
  "success": true,
  "data": {
    "song": {
      "id": 1,
      "title": "Updated Song Title",
      // ... updated song details
    },
    "message": "Changes applied directly"
  }
}
```

#### 5. Get Song Lyrics
**GET** `/songs/{id}/lyrics/`

Returns just the lyrics for a song.

**Response:**
```json
{
  "success": true,
  "data": {
    "song_id": 1,
    "title": "Bohemian Rhapsody",
    "lyrics": "Is this the real life? Is this just fantasy?..."
  }
}
```

### Albums

#### 1. List Albums
**GET** `/albums/`

Returns a paginated list of albums.

**Query Parameters:**
- `page`, `page_size`, `search`: Same as songs
- `artist_id`: Filter by artist
- `album_type`: Filter by album type
- `year`: Filter by release year

**Response:**
```json
{
  "success": true,
  "data": {
    "count": 250,
    "next": "http://localhost:8000/api/albums/?page=2",
    "previous": null,
    "results": [
      {
        "id": 1,
        "title": "A Night at the Opera",
        "album_type": "album",
        "release_date": "1975-11-21",
        "cover_url": "https://example.com/media/album_covers/1.jpg",
        "description": "Fifth studio album by Queen...",
        "artist_count": 1,
        "song_count": 12,
        "artists": [
          {
            "id": 1,
            "name": "Queen"
          }
        ],
        "created_at": "2023-10-01T12:00:00Z",
        "updated_at": "2023-10-01T12:00:00Z"
      }
    ]
  }
}
```

#### 2. Get Album Details
**GET** `/albums/{id}/`

Returns detailed information about an album including all songs.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "title": "A Night at the Opera",
    "album_type": "album",
    "release_date": "1975-11-21",
    "cover_url": "https://example.com/media/album_covers/1.jpg",
    "description": "Fifth studio album by Queen...",
    "artists": [
      {
        "id": 1,
        "name": "Queen",
        "image_url": "https://example.com/media/artists/1.jpg"
      }
    ],
    "songs": [
      {
        "id": 1,
        "title": "Bohemian Rhapsody",
        "duration": 354,
        "track_number": 1,
        "artists": [
          {
            "id": 1,
            "name": "Queen",
            "role": "main"
          }
        ]
      },
      // ... more songs
    ],
    "created_at": "2023-10-01T12:00:00Z",
    "updated_at": "2023-10-01T12:00:00Z"
  }
}
```

#### 3. Update Album
**PUT** `/albums/{id}/`

Similar to song update endpoint with moderation workflow.

### Artists

#### 1. List Artists
**GET** `/artists/`

Returns a paginated list of artists.

**Query Parameters:**
- `page`, `page_size`, `search`: Same as songs
- `sort`: name, created_at, song_count

**Response:**
```json
{
  "success": true,
  "data": {
    "count": 500,
    "next": "http://localhost:8000/api/artists/?page=2",
    "previous": null,
    "results": [
      {
        "id": 1,
        "name": "Queen",
        "image_url": "https://example.com/media/artists/1.jpg",
        "song_count": 150,
        "album_count": 15,
        "created_at": "2023-10-01T12:00:00Z",
        "updated_at": "2023-10-01T12:00:00Z"
      }
    ]
  }
}
```

#### 2. Get Artist Details
**GET** `/artists/{id}/`

Returns detailed information about an artist including discography.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Queen",
    "image_url": "https://example.com/media/artists/1.jpg",
    "bio": "British rock band formed in London in 1970...",
    "albums": [
      {
        "id": 1,
        "title": "A Night at the Opera",
        "album_type": "album",
        "release_date": "1975-11-21",
        "cover_url": "https://example.com/media/album_covers/1.jpg",
        "song_count": 12
      },
      // ... more albums
    ],
    "songs": [
      {
        "id": 1,
        "title": "Bohemian Rhapsody",
        "duration": 354,
        "albums": [
          {
            "id": 1,
            "title": "A Night at the Opera",
            "track_number": 1
          }
        ]
      },
      // ... more songs
    ],
    "created_at": "2023-10-01T12:00:00Z",
    "updated_at": "2023-10-01T12:00:00Z"
  }
}
```

#### 3. Update Artist
**PUT** `/artists/{id}/`

Similar to song update endpoint with moderation workflow.

### Moderation

#### 1. List Change Requests
**GET** `/moderation/change-requests/`

Returns change requests for moderation. Moderators and owners only.

**Query Parameters:**
- `status`: Filter by status (pending, approved, rejected)
- `user_id`: Filter by submitting user
- `model_type`: Filter by model type
- `page`, `page_size`: Pagination

**Response:**
```json
{
  "success": true,
  "data": {
    "count": 25,
    "next": "http://localhost:8000/api/moderation/change-requests/?page=2",
    "previous": null,
    "results": [
      {
        "id": 42,
        "user": {
          "id": 2,
          "username": "musicfan123",
          "role": "general"
        },
        "model_type": "song",
        "model_id": 1,
        "field_name": "lyrics",
        "old_value": "Original lyrics...",
        "new_value": "Corrected lyrics...",
        "status": "pending",
        "created_at": "2023-10-05T10:30:00Z",
        "target_object": {
          "id": 1,
          "title": "Bohemian Rhapsody",
          "model_type": "song"
        }
      }
    ]
  }
}
```

#### 2. Review Change Request
**POST** `/moderation/change-requests/{id}/review/`

Approve or reject a change request. Moderators and owners only.

**Request Body:**
```json
{
  "action": "approve",  // or "reject"
  "notes": "Lyrics correction looks accurate",
  "edit_before_apply": false,
  "edited_value": ""  // Optional: modified value if edit_before_apply is true
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "change_request_id": 42,
    "status": "approved",
    "applied": true,
    "message": "Change request approved and applied"
  }
}
```

#### 3. Get Moderation History
**GET** `/moderation/history/`

Returns history of moderated changes.

**Query Parameters:**
- `user_id`: Filter by submitting user
- `reviewed_by`: Filter by moderator
- `date_from`, `date_to`: Date range filter

### Users (Owner Only)

#### 1. List Users
**GET** `/users/`

Returns list of users. Owners only.

**Query Parameters:**
- `role`: Filter by role
- `search`: Search username or email

#### 2. Update User Role
**PUT** `/users/{id}/role/`

Updates a user's role. Owners only.

**Request Body:**
```json
{
  "role": "moderator"
}
```

## Rate Limiting
- Public endpoints: 100 requests/hour per IP
- Authenticated endpoints: 1000 requests/hour per user
- Moderation endpoints: 500 requests/hour per user

## WebSocket Endpoints (Optional for Real-time)

### 1. Now Playing Updates
**WS** `/ws/now-playing/`

Broadcasts currently playing song to connected clients.

### 2. Moderation Notifications
**WS** `/ws/moderation/`

Sends real-time notifications about new change requests to moderators.

## Mobile App Specific Endpoints

### 1. Batch Song Lookup
**POST** `/mobile/batch-lookup/`

Allows mobile app to look up multiple songs at once for initial sync.

**Request Body:**
```json
{
  "songs": [
    {
      "title": "Song 1",
      "artist": "Artist 1",
      "duration": 180,
      "file_hash": "hash1"
    },
    {
      "title": "Song 2",
      "artist": "Artist 2",
      "duration": 240,
      "file_hash": "hash2"
    }
  ]
}
```

### 2. Device Registration
**POST** `/mobile/device/`

Registers a mobile device for push notifications.

**Request Body:**
```json
{
  "device_id": "unique_device_identifier",
  "platform": "ios",  // or "android"
  "push_token": "apns_or_fcm_token"
}
```

## Error Codes

### Authentication Errors
- `AUTH001`: Invalid credentials
- `AUTH002`: Account disabled
- `AUTH003`: Token expired
- `AUTH004`: Insufficient permissions

### Validation Errors
- `VAL001`: Required field missing
- `VAL002`: Invalid field format
- `VAL003`: Field value too long/short
- `VAL004`: Unique constraint violation

### Business Logic Errors
- `BIZ001`: Change request already processed
- `BIZ002`: Cannot moderate own change request
- `BIZ003`: Song already exists with same hash
- `BIZ004`: Cannot delete referenced record

## Versioning
API version is included in the URL path:
- Current version: `/api/v1/`
- Future versions: `/api/v2/`, etc.

Backwards compatibility maintained for at least 6 months after new version release.