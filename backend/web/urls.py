"""
URL configuration for the web app.
This will handle the web interface (Django templates) for the music player.
"""

from django.urls import path

from . import views

app_name = "web"

urlpatterns = [
    # Home page
    path("", views.home, name="home"),
    # Dashboard
    path("dashboard/", views.dashboard, name="dashboard"),
    # User Library
    path("library/", views.library, name="library"),
    # Song management
    path("songs/", views.SongListView.as_view(), name="song_list"),
    path("songs/<int:pk>/", views.SongDetailView.as_view(), name="song_detail"),
    path("songs/create/", views.song_create, name="song_create"),
    path("songs/<int:pk>/edit/", views.song_edit, name="song_edit"),
    # Album management
    path("albums/", views.AlbumListView.as_view(), name="album_list"),
    path("albums/<int:pk>/", views.AlbumDetailView.as_view(), name="album_detail"),
    # Artist management
    path("artists/", views.ArtistListView.as_view(), name="artist_list"),
    path("artists/<int:pk>/", views.ArtistDetailView.as_view(), name="artist_detail"),
    # Moderation
    path(
        "moderation/", views.ChangeRequestListView.as_view(), name="change_request_list"
    ),
    path(
        "moderation/<int:pk>/review/",
        views.change_request_review,
        name="change_request_review",
    ),
    # User profile
    path("profile/", views.profile, name="profile"),
    # Global search
    path("search/", views.search, name="search"),
]
