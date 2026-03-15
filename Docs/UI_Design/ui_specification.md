# UI Design Specification

## Overview
This document outlines the user interface design for both the Flutter mobile application and the Django web interface. The design must ensure consistency across platforms while providing platform-specific optimizations.

## Design Principles
- **Consistency**: Use consistent color schemes, typography, and component styles across mobile and web.
- **Accessibility**: Follow WCAG 2.1 guidelines for contrast, keyboard navigation, and screen reader compatibility.
- **Responsive Design**: Ensure the web interface works on all screen sizes and the mobile app adapts to different phone sizes.
- **User-Centric**: Prioritize ease of use and intuitive navigation for both casual listeners and power users.

## Flutter App UI Design

### Color Scheme
- **Primary Color**: #6200EE (deep purple)
- **Secondary Color**: #03DAC6 (teal)
- **Background**: #FFFFFF (light mode), #121212 (dark mode)
- **Surface**: #F5F5F5 (light mode), #1E1E1E (dark mode)
- **Error**: #B00020
- **On Primary**: #FFFFFF
- **On Secondary**: #000000

### Typography
- **Font Family**: Roboto (default for Material Design)
- **Headline 1**: 96sp, light
- **Headline 2**: 60sp, light
- **Headline 3**: 48sp, regular
- **Headline 4**: 34sp, regular
- **Headline 5**: 24sp, regular
- **Headline 6**: 20sp, medium
- **Body 1**: 16sp, regular
- **Body 2**: 14sp, regular
- **Caption**: 12sp, regular
- **Button**: 14sp, medium (all caps)

### Screens

#### 1. Library Screen
- **Purpose**: Browse local music library (songs, albums, artists)
- **Layout**: Tabbed view (Songs, Albums, Artists) with a top search bar
- **Components**:
  - ListView with custom tiles for each entity
  - Each tile shows: artwork, title, subtitle (artist/album info), duration for songs
  - Floating Action Button for creating new playlists
- **Navigation**: Tap on item to go to detail or start playback

#### 2. Now Playing Screen
- **Purpose**: Display current song with playback controls and lyrics
- **Layout**: Full-screen artwork with overlay controls
- **Components**:
  - Album artwork (full-bleed)
  - Song title, artist, album (displayed over artwork)
  - Progress slider with current time and duration
  - Playback controls (shuffle, previous, play/pause, next, repeat)
  - Lyrics section (scrollable, synchronized if available)
  - Favorite button, queue button, more options (overflow menu)
- **Navigation**: Swipe down to minimize or access queue

#### 3. Playlist Screen
- **Purpose**: Create, edit, and manage playlists
- **Layout**: List of playlists with option to create new
- **Components**:
  - GridView for playlist covers (user can assign image)
  - Create New Playlist card
  - Inside a playlist: list of songs with drag handles for reordering
  - Edit mode: delete songs, change playlist details

#### 4. Search Screen
- **Purpose**: Search local library and server database
- **Layout**: Search bar at top with results below
- **Components**:
  - Search bar with real-time suggestions
  - Filter chips (Local, Server, Songs, Albums, Artists)
  - Results grouped by type
  - Each result tile similar to library screen

#### 5. Settings Screen
- **Purpose**: App configuration and user account management
- **Layout**: List of settings categories
- **Sections**:
  - Account: Login/Logout, user info, role indicator
  - Playback: Audio quality, crossfade, equalizer
  - Library: Scan settings, cache management
  - Notifications: Enable/disable push notifications
  - About: App version, privacy policy, terms of service

### Navigation
- **Bottom Navigation Bar**: For main sections (Library, Now Playing, Playlist, Search, Settings)
- **Navigation Drawer**: For user account, app settings, and help
- **App Bar**: Contextual title and actions for each screen

### Components
- **Music Tile**: Standardized tile for songs/albums/artists
- **Playback Controls**: Reusable widget for mini-player (at bottom of screen when not in Now Playing)
- **Seek Bar**: Custom slider with time labels
- **Lyrics Viewer**: Scrollable text with highlighting for current line
- **Artwork Circle**: Circular image for album/artist images

### Theming and Branding
- **Logo**: A stylized musical note combined with a cloud or server icon (representing the server integration)
- **App Icon**: Use logo on a primary color background
- **Favicon**: Same as app icon, scaled for web
- **Splash Screen**: Logo centered with primary color background

## Web Interface Design

### Color Scheme
- **Primary Color**: #6200EE (deep purple) – matches Flutter app
- **Secondary Color**: #03DAC6 (teal)
- **Background**: #F8F9FA (light gray)
- **Card Background**: #FFFFFF
- **Text Primary**: #212529
- **Text Secondary**: #6C757D
- **Border**: #DEE2E6

### Typography
- **Font Family**: Inter, sans-serif (modern, clean)
- **Heading 1**: 3.5rem, 700
- **Heading 2**: 2.5rem, 700
- **Heading 3**: 2rem, 600
- **Heading 4**: 1.5rem, 600
- **Body**: 1rem, 400 (line-height: 1.5)
- **Small**: 0.875rem, 400

### Pages

#### 1. Login Page
- **Purpose**: User authentication (username/password, Google SSO)
- **Layout**: Centered card on full-screen background
- **Components**:
  - Logo at top
  - Tabs for Login and Register (if allowed)
  - Form fields with validation
  - Social login buttons
  - Links to forgot password, terms, etc.

#### 2. Dashboard
- **Purpose**: Overview of database and moderation queue
- **Layout**: Sidebar navigation with main content area
- **Components**:
  - Statistics cards (total songs, albums, artists, pending changes)
  - Recent activity feed
  - Quick links to common actions

#### 3. Song Management
- **Purpose**: View, edit, and approve song data
- **Layout**: Data table with filtering and search
- **Components**:
  - Advanced search and filter bar
  - Data table with columns: Title, Artist, Album, Duration, Actions
  - Row actions: View, Edit, Delete (with permissions)
  - Pagination controls

#### 4. Album Management
- **Purpose**: View, edit, and approve album data
- **Layout**: Similar to song management
- **Components**:
  - Data table: Title, Artists, Type, Release Date, Song Count
  - Card view option for visual browsing (album covers)

#### 5. Artist Management
- **Purpose**: View, edit, and approve artist data
- **Layout**: Similar to song management
- **Components**:
  - Data table: Name, Song Count, Album Count
  - Option to view artist details with discography

#### 6. Moderation Queue
- **Purpose**: Review user-submitted changes
- **Layout**: Split view: list of change requests on left, detail on right
- **Components**:
  - Change request list with priority indicators
  - Detail view showing old vs. new values side-by-side
  - Action buttons: Approve, Reject, Edit and Approve
  - Notes textarea for moderator comments

#### 7. User Management (Owner Only)
- **Purpose**: Manage user roles and permissions
- **Layout**: Data table of users
- **Components**:
  - Table: Username, Email, Role, Joined Date, Actions
  - Role change dropdown inline
  - Deactivation toggle

### Navigation
- **Sidebar**: Persistent left sidebar with navigation links and user info
- **Top Bar**: Breadcrumbs, search, notifications, user menu
- **Footer**: Copyright, links to privacy policy, terms

### Components
- **Data Table**: Sortable, filterable, paginated
- **Card**: For dashboard statistics and visual browsing
- **Modal**: For forms and confirmations
- **Alert**: For success/error messages
- **Badge**: For status indicators (pending, approved, rejected)

### Theming and Branding
- **Logo**: Same as Flutter app for consistency
- **Favicon**: Same as app icon
- **Page Title**: "Music Player Admin" for dashboard, specific titles for other pages

## Consistency Across Platforms
- **Logo and Favicon**: Use identical assets
- **Color Palette**: Use the same primary and secondary colors
- **Typography**: While font families differ (Roboto for Flutter, Inter for web), maintain similar scale and weights
- **Iconography**: Use Material Icons for both (Flutter uses Material Icons, web can use Material Icons via CDN)

## Responsive Design
- **Flutter App**: Designed for mobile screens, but should support tablet layouts with adaptive components
- **Web Interface**: Use Bootstrap 5 grid system for responsive breakpoints:
  - Mobile: < 768px (single column, stacked)
  - Tablet: 768px - 992px (two columns where appropriate)
  - Desktop: > 992px (full sidebar and multi-column layouts)

## Accessibility
- **Color Contrast**: Ensure all text meets WCAG AA standards (4.5:1 for normal text)
- **Keyboard Navigation**: All interactive elements accessible via tab key
- **Screen Readers**: Use semantic HTML and ARIA labels in web; Flutter's Semantics widget for mobile
- **Focus Indicators**: Visible focus rings for all interactive elements

## Notes on Existing Templates
The project includes UI design templates in the `UI Design Templates` folder:
- **Backend/login screen.webp**: Likely design for the web login page
- **Backend/site dashboard.webp**: Likely design for the web dashboard
- **Frontend/login screen.webp**: Likely design for the Flutter app login screen
- **Frontend/lyrics and player.webp**: Likely design for the now playing screen with lyrics
- **Frontend/musicplayer.png**: Likely design for the main music player interface

These templates should be used as reference during implementation to match the intended visual design.

## Implementation Guidelines
1. Use Flutter's Material Design components for the mobile app.
2. Use Bootstrap 5 components for the web interface, with custom CSS to match the color scheme.
3. Implement dark mode for both platforms (Flutter: ThemeData.dark, web: CSS prefers-color-scheme).
4. Ensure all images are optimized for fast loading.
5. Use vector graphics (SVG) for icons where possible.

## Next Steps
1. Create high-fidelity mockups for each screen/page based on this specification.
2. Develop a design system component library for both platforms.
3. Implement the Flutter app UI following Material Design guidelines.
4. Implement the web UI using Django templates and Bootstrap.
5. Conduct usability testing with representative users.

---
*Last Updated: [Date]*
*Document Version: 1.0*