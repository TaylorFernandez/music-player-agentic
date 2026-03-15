"""
URL configuration for the Music Player API.
Defines all REST API endpoints for songs, albums, artists, authentication, and moderation.
"""

from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AlbumViewSet,
    ArtistViewSet,
    ChangeRequestViewSet,
    CurrentUserView,
    LoginView,
    LogoutView,
    RegisterView,
    SongViewSet,
    UserViewSet,
)

# Create a router for ViewSets
router = DefaultRouter()

# Register ViewSets with the router
router.register(r"songs", SongViewSet, basename="song")
router.register(r"albums", AlbumViewSet, basename="album")
router.register(r"artists", ArtistViewSet, basename="artist")
router.register(
    r"moderation/change-requests", ChangeRequestViewSet, basename="change-request"
)
router.register(r"users", UserViewSet, basename="user")

# URL patterns
urlpatterns = [
    # Authentication endpoints
    path("auth/register/", RegisterView.as_view(), name="register"),
    path("auth/login/", LoginView.as_view(), name="login"),
    path("auth/logout/", LogoutView.as_view(), name="logout"),
    path("auth/me/", CurrentUserView.as_view(), name="current-user"),
    # Include router URLs (songs, albums, artists, moderation, users)
    path("", include(router.urls)),
]

# Note: Additional URL patterns for specific actions:
# - Songs:
#   - POST /api/songs/lookup/ - Lookup song by metadata
#   - POST /api/songs/batch_lookup/ - Batch lookup songs
#   - GET /api/songs/{id}/lyrics/ - Get song lyrics
# - Albums:
#   - Standard CRUD operations
# - Artists:
#   - Standard CRUD operations
# - Moderation:
#   - POST /api/moderation/change-requests/create_request/ - Create change request
#   - POST /api/moderation/change-requests/{id}/review/ - Review change request
#   - GET /api/moderation/change-requests/history/ - Get moderation history
# - Users:
#   - PUT /api/users/{id}/role/ - Update user role (owner only)
