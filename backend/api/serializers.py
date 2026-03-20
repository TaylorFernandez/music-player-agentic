"""
API Serializers for the Music Player application.
Defines how models are serialized/deserialized for REST API endpoints.
"""

from core.models import (
    Album,
    AlbumArtist,
    Artist,
    ChangeRequest,
    Song,
    SongAlbum,
    SongArtist,
    UserProfile,
    UserSong,
)
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator
from rest_framework import serializers

# User and Authentication Serializers


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model."""

    class Meta:
        model = User
        fields = ["id", "username", "email", "first_name", "last_name"]
        read_only_fields = ["id"]


class UserProfileSerializer(serializers.ModelSerializer):
    """Serializer for UserProfile model."""

    user = UserSerializer(read_only=True)

    class Meta:
        model = UserProfile
        fields = ["id", "user", "role", "avatar_url", "created_at", "updated_at"]
        read_only_fields = ["id", "created_at", "updated_at"]


class UserRegistrationSerializer(serializers.Serializer):
    """Serializer for user registration."""

    username = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=8)
    password2 = serializers.CharField(write_only=True)

    def validate_username(self, value):
        """Check if username is already taken."""
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError(
                "A user with this username already exists."
            )
        return value

    def validate_email(self, value):
        """Check if email is already taken."""
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate(self, data):
        """Validate passwords match."""
        if data["password"] != data["password2"]:
            raise serializers.ValidationError({"password2": "Passwords do not match."})
        return data

    def create(self, validated_data):
        """Create user and profile."""
        user = User.objects.create_user(
            username=validated_data["username"],
            email=validated_data["email"],
            password=validated_data["password"],
        )
        UserProfile.objects.create(user=user, role="general")
        return user


class UserSongSerializer(serializers.ModelSerializer):
    """Serializer for UserSong model."""

    song_details = serializers.SerializerMethodField()

    class Meta:
        model = UserSong
        fields = ["id", "user", "song", "song_details", "added_at", "is_favorite"]
        read_only_fields = ["id", "user", "added_at"]

    def get_song_details(self, obj):
        """Return song details using SongSerializer."""
        return SongSerializer(obj.song).data


class LibrarySyncSerializer(serializers.Serializer):
    """Serializer for library synchronization."""

    song_ids = serializers.ListField(child=serializers.IntegerField())

    def validate_song_ids(self, value):
        """Check if songs exist."""
        existing_ids = set(
            Song.objects.filter(id__in=value).values_list("id", flat=True)
        )
        invalid_ids = [sid for sid in value if sid not in existing_ids]
        if invalid_ids:
            raise serializers.ValidationError(f"Invalid song IDs: {invalid_ids}")
        return value


# Artist Serializers


class ArtistSerializer(serializers.ModelSerializer):
    """Serializer for Artist model."""

    song_count = serializers.SerializerMethodField()
    album_count = serializers.SerializerMethodField()

    class Meta:
        model = Artist
        fields = [
            "id",
            "name",
            "image_url",
            "bio",
            "song_count",
            "album_count",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def get_song_count(self, obj):
        """Return count of songs for this artist."""
        return obj.song_set.count()

    def get_album_count(self, obj):
        """Return count of albums for this artist."""
        return obj.album_set.count()


class ArtistSummarySerializer(serializers.ModelSerializer):
    """Simplified serializer for Artist (used in nested relationships)."""

    class Meta:
        model = Artist
        fields = ["id", "name", "image_url"]


# Album Serializers


class SongAlbumSerializer(serializers.ModelSerializer):
    """Serializer for SongAlbum relationship."""

    song_title = serializers.CharField(source="song.title", read_only=True)
    album_title = serializers.CharField(source="album.title", read_only=True)

    class Meta:
        model = SongAlbum
        fields = ["id", "song", "album", "track_number", "song_title", "album_title"]


class AlbumArtistSerializer(serializers.ModelSerializer):
    """Serializer for AlbumArtist relationship."""

    artist_name = serializers.CharField(source="artist.name", read_only=True)
    album_title = serializers.CharField(source="album.title", read_only=True)

    class Meta:
        model = AlbumArtist
        fields = ["id", "album", "artist", "artist_name", "album_title"]


class AlbumSerializer(serializers.ModelSerializer):
    """Serializer for Album model."""

    artists = ArtistSummarySerializer(many=True, read_only=True)
    song_count = serializers.SerializerMethodField()

    class Meta:
        model = Album
        fields = [
            "id",
            "title",
            "album_type",
            "release_date",
            "cover_url",
            "description",
            "artists",
            "song_count",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def get_song_count(self, obj):
        """Return count of songs in this album."""
        return obj.songs.count()


class AlbumSummarySerializer(serializers.ModelSerializer):
    """Simplified serializer for Album (used in nested relationships)."""

    artists = ArtistSummarySerializer(many=True, read_only=True)

    class Meta:
        model = Album
        fields = ["id", "title", "album_type", "cover_url", "artists"]


class AlbumDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for Album including all songs."""

    artists = ArtistSummarySerializer(many=True, read_only=True)
    songs = serializers.SerializerMethodField()

    class Meta:
        model = Album
        fields = [
            "id",
            "title",
            "album_type",
            "release_date",
            "cover_url",
            "description",
            "artists",
            "songs",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def get_songs(self, obj):
        """Return songs with track numbers."""
        from .serializers import SongSummarySerializer

        song_albums = (
            SongAlbum.objects.filter(album=obj)
            .select_related("song")
            .order_by("track_number")
        )
        songs = []
        for sa in song_albums:
            song_data = SongSummarySerializer(sa.song).data
            song_data["track_number"] = sa.track_number
            songs.append(song_data)
        return songs


# Song Serializers


class SongArtistSerializer(serializers.ModelSerializer):
    """Serializer for SongArtist relationship."""

    artist_name = serializers.CharField(source="artist.name", read_only=True)
    artist_image = serializers.URLField(source="artist.image_url", read_only=True)
    role_display = serializers.CharField(source="get_role_display", read_only=True)

    class Meta:
        model = SongArtist
        fields = ["id", "artist", "artist_name", "artist_image", "role", "role_display"]


class SongSerializer(serializers.ModelSerializer):
    """Serializer for Song model."""

    artists = serializers.SerializerMethodField()
    albums = serializers.SerializerMethodField()
    formatted_duration = serializers.CharField(read_only=True)

    class Meta:
        model = Song
        fields = [
            "id",
            "title",
            "duration",
            "formatted_duration",
            "file_hash",
            "lyrics",
            "artwork_url",
            "artists",
            "albums",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def get_artists(self, obj):
        """Return artists with their roles."""
        song_artists = SongArtist.objects.filter(song=obj).select_related("artist")
        return [
            {
                "id": sa.artist.id,
                "name": sa.artist.name,
                "image_url": sa.artist.image_url,
                "role": sa.role,
                "role_display": sa.get_role_display(),
            }
            for sa in song_artists
        ]

    def get_albums(self, obj):
        """Return albums with track numbers."""
        song_albums = SongAlbum.objects.filter(song=obj).select_related("album")
        return [
            {
                "id": sa.album.id,
                "title": sa.album.title,
                "album_type": sa.album.album_type,
                "cover_url": sa.album.cover_url,
                "track_number": sa.track_number,
            }
            for sa in song_albums
        ]


class SongSummarySerializer(serializers.ModelSerializer):
    """Simplified serializer for Song (used in nested relationships)."""

    formatted_duration = serializers.CharField(read_only=True)

    class Meta:
        model = Song
        fields = ["id", "title", "duration", "formatted_duration", "artwork_url"]


class SongDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for Song including all relationships."""

    artists = serializers.SerializerMethodField()
    albums = serializers.SerializerMethodField()
    formatted_duration = serializers.CharField(read_only=True)

    class Meta:
        model = Song
        fields = [
            "id",
            "title",
            "duration",
            "formatted_duration",
            "file_hash",
            "lyrics",
            "artwork_url",
            "artists",
            "albums",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def get_artists(self, obj):
        """Return artists with their roles and full details."""
        song_artists = SongArtist.objects.filter(song=obj).select_related("artist")
        return [
            {
                "id": sa.artist.id,
                "name": sa.artist.name,
                "image_url": sa.artist.image_url,
                "role": sa.role,
                "role_display": sa.get_role_display(),
            }
            for sa in song_artists
        ]

    def get_albums(self, obj):
        """Return albums with full details and track numbers."""
        song_albums = SongAlbum.objects.filter(song=obj).select_related("album")
        return [
            {
                "id": sa.album.id,
                "title": sa.album.title,
                "album_type": sa.album.album_type,
                "cover_url": sa.album.cover_url,
                "track_number": sa.track_number,
                "release_date": sa.album.release_date,
            }
            for sa in song_albums
        ]


class SongLyricsSerializer(serializers.ModelSerializer):
    """Serializer for just song lyrics."""

    class Meta:
        model = Song
        fields = ["id", "title", "lyrics"]


# Song Lookup Serializer


class SongLookupSerializer(serializers.Serializer):
    """Serializer for looking up songs by metadata from MP3 files."""

    title = serializers.CharField(max_length=255, required=False, allow_blank=True)
    artist = serializers.CharField(max_length=255, required=False, allow_blank=True)
    album = serializers.CharField(max_length=255, required=False, allow_blank=True)
    duration = serializers.IntegerField(required=False, allow_null=True)
    file_hash = serializers.CharField(max_length=64, required=False, allow_blank=True)

    def validate_duration(self, value):
        """Validate duration is positive."""
        if value is not None and value < 0:
            raise serializers.ValidationError("Duration must be a positive integer.")
        return value


class SongLookupResultSerializer(serializers.Serializer):
    """Serializer for song lookup results."""

    match_type = serializers.ChoiceField(choices=["exact", "partial", "none"])
    confidence = serializers.FloatField(min_value=0.0, max_value=1.0)
    song = SongDetailSerializer(required=False, allow_null=True)
    suggestions = SongSummarySerializer(many=True, required=False)


# Change Request Serializers


class ChangeRequestSerializer(serializers.ModelSerializer):
    """Serializer for ChangeRequest model."""

    user = UserSerializer(read_only=True)
    reviewed_by = UserSerializer(read_only=True)
    model_type_display = serializers.CharField(
        source="get_model_type_display", read_only=True
    )
    status_display = serializers.CharField(source="get_status_display", read_only=True)
    target_object = serializers.SerializerMethodField()

    class Meta:
        model = ChangeRequest
        fields = [
            "id",
            "user",
            "model_type",
            "model_type_display",
            "model_id",
            "field_name",
            "old_value",
            "new_value",
            "status",
            "status_display",
            "reviewed_by",
            "reviewed_at",
            "notes",
            "target_object",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "user",
            "reviewed_by",
            "reviewed_at",
            "created_at",
            "updated_at",
        ]

    def get_target_object(self, obj):
        """Return summary of the target object."""
        target = obj.get_target_object()
        if target is None:
            return {
                "id": obj.model_id,
                "title": "Deleted",
                "model_type": obj.model_type,
            }

        if isinstance(target, Song):
            return {
                "id": target.id,
                "title": target.title,
                "model_type": "song",
            }
        elif isinstance(target, Album):
            return {
                "id": target.id,
                "title": target.title,
                "model_type": "album",
            }
        elif isinstance(target, Artist):
            return {
                "id": target.id,
                "title": target.name,
                "model_type": "artist",
            }
        return {"id": obj.model_id, "title": "Unknown", "model_type": obj.model_type}


class ChangeRequestCreateSerializer(serializers.Serializer):
    """Serializer for creating change requests."""

    model_type = serializers.ChoiceField(choices=["song", "album", "artist"])
    model_id = serializers.IntegerField()
    field_name = serializers.CharField(max_length=255)
    new_value = serializers.CharField()
    notes = serializers.CharField(required=False, allow_blank=True)

    def validate_model_type(self, value):
        """Validate model type is valid."""
        valid_types = ["song", "album", "artist"]
        if value not in valid_types:
            raise serializers.ValidationError(
                f"Invalid model type. Must be one of: {', '.join(valid_types)}"
            )
        return value

    def validate(self, data):
        """Validate the target object exists."""
        model_type = data["model_type"]
        model_id = data["model_id"]

        model_class = {"song": Song, "album": Album, "artist": Artist}.get(model_type)

        if not model_class.objects.filter(id=model_id).exists():
            raise serializers.ValidationError(
                {
                    "model_id": f"{model_type.capitalize()} with id {model_id} does not exist."
                }
            )

        # Validate field exists on model
        field_name = data["field_name"]
        model_fields = [f.name for f in model_class._meta.get_fields()]
        if field_name not in model_fields:
            raise serializers.ValidationError(
                {"field_name": f"Field '{field_name}' does not exist on {model_type}."}
            )

        return data


class ChangeRequestReviewSerializer(serializers.Serializer):
    """Serializer for reviewing change requests."""

    action = serializers.ChoiceField(choices=["approve", "reject"])
    notes = serializers.CharField(required=False, allow_blank=True)
    edit_before_apply = serializers.BooleanField(required=False, default=False)
    edited_value = serializers.CharField(required=False, allow_blank=True)

    def validate(self, data):
        """Validate edited_value if edit_before_apply is True."""
        if data.get("edit_before_apply") and not data.get("edited_value"):
            raise serializers.ValidationError(
                {
                    "edited_value": "This field is required when edit_before_apply is True."
                }
            )
        return data


# Batch Lookup Serializer (for mobile app)


class BatchSongLookupSerializer(serializers.Serializer):
    """Serializer for batch song lookup requests."""

    songs = SongLookupSerializer(many=True)

    def validate_songs(self, value):
        """Validate songs list is not empty."""
        if not value:
            raise serializers.ValidationError("At least one song is required.")
        if len(value) > 100:
            raise serializers.ValidationError("Maximum 100 songs per batch request.")
        return value


class BatchSongLookupResultSerializer(serializers.Serializer):
    """Serializer for batch song lookup results."""

    results = serializers.ListField(
        child=serializers.DictField(),
        help_text="List of lookup results for each song in the batch.",
    )
