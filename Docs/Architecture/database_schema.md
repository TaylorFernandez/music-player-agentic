
# Database Schema

## Overview
This document outlines the complete database schema for the Music Player application using Django models. The schema supports three main entities (Song, Album, Artist) with many-to-many relationships, a user system with role-based access control, and a moderation workflow for data changes.

## Models

### 1. Artist
Represents a music artist or group.

```python
from django.db import models

class Artist(models.Model):
    name = models.CharField(max_length=255, unique=True)
    image = models.ImageField(upload_to='artists/', blank=True, null=True)
    bio = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']
        indexes = [
            models.Index(fields=['name']),
        ]

    def __str__(self):
        return self.name
```

### 2. Album
Represents a music album, EP, or single.

```python
class Album(models.Model):
    ALBUM_TYPE_CHOICES = [
        ('album', 'Album'),
        ('ep', 'EP'),
        ('single', 'Single'),
        ('compilation', 'Compilation'),
        ('soundtrack', 'Soundtrack'),
    ]

    title = models.CharField(max_length=255)
    album_type = models.CharField(max_length=20, choices=ALBUM_TYPE_CHOICES, default='album')
    release_date = models.DateField(blank=True, null=True)
    cover_art = models.ImageField(upload_to='album_covers/', blank=True, null=True)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Many-to-many relationship with Artist through AlbumArtist
    artists = models.ManyToManyField('Artist', through='AlbumArtist')

    class Meta:
        ordering = ['-release_date', 'title']
        indexes = [
            models.Index(fields=['title']),
            models.Index(fields=['release_date']),
        ]

    def __str__(self):
        return self.title
```

### 3. Song
Represents a single audio track.

```python
class Song(models.Model):
    title = models.CharField(max_length=255)
    duration = models.IntegerField(help_text='Duration in seconds')
    file_hash = models.CharField(max_length=64, unique=True, 
                                 help_text='SHA-256 hash of audio file for deduplication')
    lyrics = models.TextField(blank=True)
    artwork = models.ImageField(upload_to='song_artwork/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Many-to-many relationships
    albums = models.ManyToManyField('Album', through='SongAlbum')
    artists = models.ManyToManyField('Artist', through='SongArtist')

    class Meta:
        ordering = ['title']
        indexes = [
            models.Index(fields=['title']),
            models.Index(fields=['file_hash']),
        ]

    def __str__(self):
        return self.title
```

### 4. AlbumArtist (Relationship Model)
Defines the many-to-many relationship between Album and Artist.

```python
class AlbumArtist(models.Model):
    album = models.ForeignKey('Album', on_delete=models.CASCADE)
    artist = models.ForeignKey('Artist', on_delete=models.CASCADE)

    class Meta:
        unique_together = ['album', 'artist']
        verbose_name = 'Album Artist'
        verbose_name_plural = 'Album Artists'

    def __str__(self):
        return f'{self.artist.name} - {self.album.title}'
```

### 5. SongAlbum (Relationship Model)
Defines the many-to-many relationship between Song and Album, including track number.

```python
class SongAlbum(models.Model):
    song = models.ForeignKey('Song', on_delete=models.CASCADE)
    album = models.ForeignKey('Album', on_delete=models.CASCADE)
    track_number = models.IntegerField(blank=True, null=True)

    class Meta:
        unique_together = ['song', 'album']
        ordering = ['album', 'track_number']
        verbose_name = 'Song Album'
        verbose_name_plural = 'Song Albums'

    def __str__(self):
        return f'{self.song.title} on {self.album.title}'
```

### 6. SongArtist (Relationship Model)
Defines the many-to-many relationship between Song and Artist, with role information.

```python
class SongArtist(models.Model):
    ROLE_CHOICES = [
        ('main', 'Main Artist'),
        ('featured', 'Featured Artist'),
        ('producer', 'Producer'),
        ('writer', 'Writer'),
        ('composer', 'Composer'),
    ]

    song = models.ForeignKey('Song', on_delete=models.CASCADE)
    artist = models.ForeignKey('Artist', on_delete=models.CASCADE)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='main')

    class Meta:
        unique_together = ['song', 'artist', 'role']
        verbose_name = 'Song Artist'
        verbose_name_plural = 'Song Artists'

    def __str__(self):
        return f'{self.artist.name} ({self.get_role_display()}) - {self.song.title}'
```

### 7. UserProfile (Extends Django User)
Extends the built-in Django User model with additional role and profile information.

```python
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver

class UserProfile(models.Model):
    ROLE_CHOICES = [
        ('general', 'General User'),
        ('moderator', 'Moderator'),
        ('owner', 'Owner'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='general')
    avatar = models.ImageField(upload_to='avatars/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['role']),
        ]

    def __str__(self):
        return f'{self.user.username} ({self.get_role_display()})'

# Signal to create UserProfile automatically when User is created
@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance)

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    instance.userprofile.save()
```

### 8. ChangeRequest
Tracks all proposed changes to Song, Album, or Artist data for moderation.

```python
class ChangeRequest(models.Model):
    MODEL_TYPE_CHOICES = [
        ('song', 'Song'),
        ('album', 'Album'),
        ('artist', 'Artist'),
    ]
    
    STATUS_CHOICES = [
        ('pending', 'Pending Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='change_requests')
    model_type = models.CharField(max_length=20, choices=MODEL_TYPE_CHOICES)
    model_id = models.IntegerField(help_text='ID of the Song, Album, or Artist being modified')
    field_name = models.CharField(max_length=255, help_text='Name of the field being changed')
    old_value = models.TextField(blank=True, help_text='Current value of the field')
    new_value = models.TextField(help_text='Proposed new value')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    reviewed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, 
                                    related_name='reviewed_change_requests')
    reviewed_at = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True, help_text='Moderator comments')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'created_at']),
            models.Index(fields=['model_type', 'model_id']),
            models.Index(fields=['user', 'created_at']),
        ]

    def __str__(self):
        return f'ChangeRequest #{self.id}: {self.get_model_type_display()} {self.model_id}.{self.field_name}'

    def get_target_object(self):
        """Returns the actual object being modified"""
        if self.model_type == 'song':
            return Song.objects.filter(id=self.model_id).first()
        elif self.model_type == 'album':
            return Album.objects.filter(id=self.model_id).first()
        elif self.model_type == 'artist':
            return Artist.objects.filter(id=self.model_id).first()
        return None
```

## Relationships Summary

1. **Album ↔ Artist**: Many-to-many via `AlbumArtist`
2. **Song ↔ Album**: Many-to-many via `SongAlbum` (with track_number)
3. **Song ↔ Artist**: Many-to-many via `SongArtist` (with role)
4. **User ↔ ChangeRequest**: One-to-many (User submits many ChangeRequests)
5. **User ↔ ChangeRequest**: Many-to-one (Moderator reviews many ChangeRequests)

## Database Constraints

### Unique Constraints
- `Artist.name` must be unique
- `Song.file_hash` must be unique (audio file deduplication)
- `AlbumArtist`: (`album`, `artist`) combination must be unique
- `SongAlbum`: (`song`, `album`) combination must be unique
- `SongArtist`: (`song`, `artist`, `role`) combination must be unique
- `UserProfile.user`: One-to-one with Django User

### Indexes
All foreign keys are automatically indexed by Django. Additional indexes:
- `Artist.name` for fast searching
- `Album.title` and `release_date` for sorting/filtering
- `Song.title` and `file_hash` for searching/matching
- `ChangeRequest.status`, `model_type`, `user` for efficient moderation queries

## Moderation Workflow

1. **General User** submits change → Creates `ChangeRequest` with status='pending'
2. **Moderator** reviews request → Updates status to 'approved' or 'rejected'
3. If approved:
   - System applies change to target model
   - `ChangeRequest.reviewed_by` and `reviewed_at` are set
4. If rejected:
   - Change is not applied
   - Moderator adds notes explaining rejection
5. **Owner** can bypass review by setting `skip_review=True` in API (not stored in model)

## Notes

1. The `file_hash` field in Song is critical for matching local MP3 files with server data without uploading actual files.
2. Image fields use Django's `ImageField` with upload directories; in production, consider using a CDN or object storage.
3. The `ChangeRequest` model stores both old and new values for audit trail.
4. All models include `created_at` and `updated_at` timestamps for tracking.
5. The `UserProfile` is automatically created via Django signals when a User is created.
