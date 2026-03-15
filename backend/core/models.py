"""
Core models for the Music Player application.
Includes Artist, Album, Song models and their relationships.
"""

from django.contrib.auth.models import User
from django.db import models


class Artist(models.Model):
    """Represents a music artist or group."""

    name = models.CharField(max_length=255, unique=True)
    image_url = models.URLField(max_length=500, blank=True, null=True)
    bio = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]
        indexes = [
            models.Index(fields=["name"]),
        ]

    def __str__(self):
        return self.name

    @property
    def song_count(self):
        """Returns the number of songs by this artist."""
        return self.songs.count()

    @property
    def album_count(self):
        """Returns the number of albums by this artist."""
        return self.albums.count()


class Album(models.Model):
    """Represents a music album, EP, or single."""

    ALBUM_TYPE_CHOICES = [
        ("album", "Album"),
        ("ep", "EP"),
        ("single", "Single"),
        ("compilation", "Compilation"),
        ("soundtrack", "Soundtrack"),
    ]

    title = models.CharField(max_length=255)
    album_type = models.CharField(
        max_length=20, choices=ALBUM_TYPE_CHOICES, default="album"
    )
    release_date = models.DateField(blank=True, null=True)
    cover_url = models.URLField(max_length=500, blank=True, null=True)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Many-to-many relationship with Artist through AlbumArtist
    artists = models.ManyToManyField(
        "Artist", through="AlbumArtist", related_name="albums"
    )

    class Meta:
        ordering = ["-release_date", "title"]
        indexes = [
            models.Index(fields=["title"]),
            models.Index(fields=["release_date"]),
        ]

    def __str__(self):
        return self.title

    @property
    def song_count(self):
        """Returns the number of songs in this album."""
        return self.songs.count()


class Song(models.Model):
    """Represents a single audio track."""

    title = models.CharField(max_length=255)
    duration = models.IntegerField(help_text="Duration in seconds")
    file_hash = models.CharField(
        max_length=64,
        unique=True,
        help_text="SHA-256 hash of audio file for deduplication",
    )
    lyrics = models.TextField(blank=True)
    artwork_url = models.URLField(max_length=500, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Many-to-many relationships
    albums = models.ManyToManyField("Album", through="SongAlbum", related_name="songs")
    artists = models.ManyToManyField(
        "Artist", through="SongArtist", related_name="songs"
    )

    class Meta:
        ordering = ["title"]
        indexes = [
            models.Index(fields=["title"]),
            models.Index(fields=["file_hash"]),
        ]

    def __str__(self):
        return self.title

    @property
    def formatted_duration(self):
        """Returns duration in MM:SS format."""
        minutes = self.duration // 60
        seconds = self.duration % 60
        return f"{minutes}:{seconds:02d}"


# Relationship Models


class AlbumArtist(models.Model):
    """Defines the many-to-many relationship between Album and Artist."""

    album = models.ForeignKey("Album", on_delete=models.CASCADE)
    artist = models.ForeignKey("Artist", on_delete=models.CASCADE)

    class Meta:
        unique_together = ["album", "artist"]
        verbose_name = "Album Artist"
        verbose_name_plural = "Album Artists"

    def __str__(self):
        return f"{self.artist.name} - {self.album.title}"


class SongAlbum(models.Model):
    """Defines the many-to-many relationship between Song and Album."""

    song = models.ForeignKey("Song", on_delete=models.CASCADE)
    album = models.ForeignKey("Album", on_delete=models.CASCADE)
    track_number = models.IntegerField(blank=True, null=True)

    class Meta:
        unique_together = ["song", "album"]
        ordering = ["album", "track_number"]
        verbose_name = "Song Album"
        verbose_name_plural = "Song Albums"

    def __str__(self):
        return f"{self.song.title} on {self.album.title}"


class SongArtist(models.Model):
    """Defines the many-to-many relationship between Song and Artist."""

    ROLE_CHOICES = [
        ("main", "Main Artist"),
        ("featured", "Featured Artist"),
        ("producer", "Producer"),
        ("writer", "Writer"),
        ("composer", "Composer"),
    ]

    song = models.ForeignKey("Song", on_delete=models.CASCADE)
    artist = models.ForeignKey("Artist", on_delete=models.CASCADE)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default="main")

    class Meta:
        unique_together = ["song", "artist", "role"]
        verbose_name = "Song Artist"
        verbose_name_plural = "Song Artists"

    def __str__(self):
        return f"{self.artist.name} ({self.get_role_display()}) - {self.song.title}"


# User and Moderation Models


class UserProfile(models.Model):
    """Extends the built-in User model with role information."""

    ROLE_CHOICES = [
        ("general", "General User"),
        ("moderator", "Moderator"),
        ("owner", "Owner"),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default="general")
    avatar_url = models.URLField(max_length=500, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=["role"]),
        ]

    def __str__(self):
        return f"{self.user.username} ({self.get_role_display()})"

    @property
    def can_moderate(self):
        """Returns True if user can moderate content."""
        return self.role in ["moderator", "owner"]


class ChangeRequest(models.Model):
    """Tracks proposed changes to Song, Album, or Artist data for moderation."""

    MODEL_TYPE_CHOICES = [
        ("song", "Song"),
        ("album", "Album"),
        ("artist", "Artist"),
    ]

    STATUS_CHOICES = [
        ("pending", "Pending Review"),
        ("approved", "Approved"),
        ("rejected", "Rejected"),
    ]

    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="change_requests"
    )
    model_type = models.CharField(max_length=20, choices=MODEL_TYPE_CHOICES)
    model_id = models.IntegerField(
        help_text="ID of the Song, Album, or Artist being modified"
    )
    field_name = models.CharField(
        max_length=255, help_text="Name of the field being changed"
    )
    old_value = models.TextField(blank=True, help_text="Current value of the field")
    new_value = models.TextField(help_text="Proposed new value")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    reviewed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="reviewed_change_requests",
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True, help_text="Moderator comments")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["status", "created_at"]),
            models.Index(fields=["model_type", "model_id"]),
            models.Index(fields=["user", "created_at"]),
        ]

    def __str__(self):
        return f"ChangeRequest #{self.id}: {self.get_model_type_display()} {self.model_id}.{self.field_name}"

    def get_target_object(self):
        """Returns the actual object being modified."""
        if self.model_type == "song":
            return Song.objects.filter(id=self.model_id).first()
        elif self.model_type == "album":
            return Album.objects.filter(id=self.model_id).first()
        elif self.model_type == "artist":
            return Artist.objects.filter(id=self.model_id).first()
        return None
