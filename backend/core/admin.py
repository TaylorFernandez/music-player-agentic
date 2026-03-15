"""
Admin interface configuration for the Music Player application.
Provides comprehensive admin panels for all models with search,
filters, and inline editing capabilities.
"""

from django.contrib import admin
from django.utils.html import format_html

from .models import (
    Album,
    AlbumArtist,
    Artist,
    ChangeRequest,
    Song,
    SongAlbum,
    SongArtist,
    UserProfile,
)

# Inline classes for relationships


class AlbumArtistInline(admin.TabularInline):
    """Inline editor for Album-Artist relationships."""

    model = AlbumArtist
    extra = 1
    autocomplete_fields = ["artist"]


class SongArtistInline(admin.TabularInline):
    """Inline editor for Song-Artist relationships."""

    model = SongArtist
    extra = 1
    autocomplete_fields = ["artist"]


class SongAlbumInline(admin.TabularInline):
    """Inline editor for Song-Album relationships."""

    model = SongAlbum
    extra = 1
    autocomplete_fields = ["album", "song"]


# Main Model Admins


@admin.register(Artist)
class ArtistAdmin(admin.ModelAdmin):
    """Admin interface for Artist model."""

    list_display = [
        "name",
        "image_preview",
        "album_count",
        "song_count",
        "created_at",
        "updated_at",
    ]
    search_fields = ["name", "bio"]
    readonly_fields = ["created_at", "updated_at", "image_preview_large"]
    ordering = ["name"]

    fieldsets = (
        ("Artist Information", {"fields": ("name", "bio", "image_url")}),
        (
            "Images",
            {
                "fields": ("image_preview_large",),
                "classes": ("collapse",),
            },
        ),
        (
            "Timestamps",
            {
                "fields": ("created_at", "updated_at"),
                "classes": ("collapse",),
            },
        ),
    )

    def image_preview(self, obj):
        """Display small image preview in list view."""
        if obj.image_url:
            return format_html(
                '<img src="{}" style="max-width: 50px; max-height: 50px; border-radius: 5px;" />',
                obj.image_url,
            )
        return "-"

    image_preview.short_description = "Image"

    def image_preview_large(self, obj):
        """Display larger image preview in detail view."""
        if obj.image_url:
            return format_html(
                '<img src="{}" style="max-width: 200px; max-height: 200px; border-radius: 10px;" />',
                obj.image_url,
            )
        return "No image"

    image_preview_large.short_description = "Image Preview"

    def album_count(self, obj):
        """Count of albums for this artist."""
        return obj.album_set.count()

    album_count.short_description = "Albums"

    def song_count(self, obj):
        """Count of songs for this artist."""
        return obj.song_set.count()

    song_count.short_description = "Songs"


@admin.register(Album)
class AlbumAdmin(admin.ModelAdmin):
    """Admin interface for Album model."""

    list_display = [
        "title",
        "album_type",
        "cover_preview",
        "release_date",
        "artist_names",
        "song_count_display",
        "created_at",
    ]
    list_filter = ["album_type", "release_date"]
    search_fields = ["title", "description", "artists__name"]
    date_hierarchy = "release_date"
    readonly_fields = ["created_at", "updated_at", "cover_preview_large"]
    ordering = ["-release_date", "title"]
    inlines = [AlbumArtistInline]

    fieldsets = (
        (
            "Album Information",
            {"fields": ("title", "album_type", "release_date", "description")},
        ),
        ("Cover Art", {"fields": ("cover_url", "cover_preview_large")}),
        (
            "Timestamps",
            {
                "fields": ("created_at", "updated_at"),
                "classes": ("collapse",),
            },
        ),
    )

    def cover_preview(self, obj):
        """Display small cover preview in list view."""
        if obj.cover_url:
            return format_html(
                '<img src="{}" style="max-width: 50px; max-height: 50px; border-radius: 5px;" />',
                obj.cover_url,
            )
        return "-"

    cover_preview.short_description = "Cover"

    def cover_preview_large(self, obj):
        """Display larger cover preview in detail view."""
        if obj.cover_url:
            return format_html(
                '<img src="{}" style="max-width: 200px; max-height: 200px; border-radius: 10px;" />',
                obj.cover_url,
            )
        return "No cover"

    cover_preview_large.short_description = "Cover Preview"

    def artist_names(self, obj):
        """Display artist names as comma-separated list."""
        return ", ".join([artist.name for artist in obj.artists.all()[:3]])

    artist_names.short_description = "Artists"

    def song_count_display(self, obj):
        """Display number of songs in album."""
        return obj.songs.count()

    song_count_display.short_description = "Songs"


@admin.register(Song)
class SongAdmin(admin.ModelAdmin):
    """Admin interface for Song model."""

    list_display = [
        "title",
        "duration_display",
        "artwork_preview",
        "artist_names",
        "album_count",
        "has_lyrics",
        "created_at",
    ]
    list_filter = ["created_at", "updated_at"]
    search_fields = ["title", "artists__name", "albums__title", "file_hash"]
    readonly_fields = [
        "created_at",
        "updated_at",
        "duration_display",
        "artwork_preview_large",
    ]
    ordering = ["title"]
    inlines = [SongArtistInline, SongAlbumInline]

    fieldsets = (
        (
            "Song Information",
            {"fields": ("title", "duration", "file_hash")},
        ),
        (
            "Artwork",
            {
                "fields": ("artwork_url", "artwork_preview_large"),
                "classes": ("collapse",),
            },
        ),
        (
            "Lyrics",
            {
                "fields": ("lyrics",),
                "classes": ("collapse",),
            },
        ),
        (
            "Timestamps",
            {
                "fields": ("created_at", "updated_at"),
                "classes": ("collapse",),
            },
        ),
    )

    def duration_display(self, obj):
        """Display formatted duration."""
        return obj.formatted_duration

    duration_display.short_description = "Duration"
    duration_display.admin_order_field = "duration"

    def artwork_preview(self, obj):
        """Display small artwork preview in list view."""
        if obj.artwork_url:
            return format_html(
                '<img src="{}" style="max-width: 50px; max-height: 50px; border-radius: 5px;" />',
                obj.artwork_url,
            )
        return "-"

    artwork_preview.short_description = "Artwork"

    def artwork_preview_large(self, obj):
        """Display larger artwork preview in detail view."""
        if obj.artwork_url:
            return format_html(
                '<img src="{}" style="max-width: 200px; max-height: 200px; border-radius: 10px;" />',
                obj.artwork_url,
            )
        return "No artwork"

    artwork_preview_large.short_description = "Artwork Preview"

    def artist_names(self, obj):
        """Display artist names as comma-separated list."""
        main_artists = [
            sa.artist.name
            for sa in obj.songartist_set.filter(role="main")
            .select_related("artist")
            .all()[:3]
        ]
        return ", ".join(main_artists)

    artist_names.short_description = "Artists"

    def album_count(self, obj):
        """Display number of albums this song appears on."""
        return obj.albums.count()

    album_count.short_description = "Albums"

    def has_lyrics(self, obj):
        """Display whether song has lyrics."""
        return bool(obj.lyrics)

    has_lyrics.short_description = "Has Lyrics"
    has_lyrics.boolean = True


@admin.register(AlbumArtist)
class AlbumArtistAdmin(admin.ModelAdmin):
    """Admin interface for Album-Artist relationship."""

    list_display = ["id", "album", "artist"]
    list_filter = ["album__album_type"]
    search_fields = ["album__title", "artist__name"]
    autocomplete_fields = ["album", "artist"]

    def get_model_perms(self, request):
        """Hide from admin menu, accessible through Album/Artist inlines."""
        return {}


@admin.register(SongAlbum)
class SongAlbumAdmin(admin.ModelAdmin):
    """Admin interface for Song-Album relationship."""

    list_display = ["id", "song", "album", "track_number"]
    list_filter = ["album"]
    search_fields = ["song__title", "album__title"]
    autocomplete_fields = ["song", "album"]

    def get_model_perms(self, request):
        """Hide from admin menu, accessible through Song/Album inlines."""
        return {}


@admin.register(SongArtist)
class SongArtistAdmin(admin.ModelAdmin):
    """Admin interface for Song-Artist relationship."""

    list_display = ["id", "song", "artist", "role"]
    list_filter = ["role"]
    search_fields = ["song__title", "artist__name"]
    autocomplete_fields = ["song", "artist"]

    def get_model_perms(self, request):
        """Hide from admin menu, accessible through Song inlines."""
        return {}


class UserProfileInline(admin.StackedInline):
    """Inline editor for UserProfile within User admin."""

    model = UserProfile
    can_delete = False
    verbose_name_plural = "User Profile"
    fk_name = "user"
    fields = ["role", "avatar_url"]


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    """Admin interface for UserProfile model."""

    list_display = ["user", "role", "avatar_preview", "created_at"]
    list_filter = ["role", "created_at"]
    search_fields = ["user__username", "user__email"]
    readonly_fields = ["created_at", "updated_at", "avatar_preview_large"]
    ordering = ["-created_at"]

    fieldsets = (
        ("User Information", {"fields": ("user", "role")}),
        ("Avatar", {"fields": ("avatar_url", "avatar_preview_large")}),
        (
            "Timestamps",
            {
                "fields": ("created_at", "updated_at"),
                "classes": ("collapse",),
            },
        ),
    )

    def avatar_preview(self, obj):
        """Display small avatar preview in list view."""
        if obj.avatar_url:
            return format_html(
                '<img src="{}" style="max-width: 50px; max-height: 50px; border-radius: 50%;" />',
                obj.avatar_url,
            )
        return "-"

    avatar_preview.short_description = "Avatar"

    def avatar_preview_large(self, obj):
        """Display larger avatar preview in detail view."""
        if obj.avatar_url:
            return format_html(
                '<img src="{}" style="max-width: 200px; max-height: 200px; border-radius: 50%;" />',
                obj.avatar_url,
            )
        return "No avatar"

    avatar_preview_large.short_description = "Avatar Preview"


@admin.register(ChangeRequest)
class ChangeRequestAdmin(admin.ModelAdmin):
    """Admin interface for ChangeRequest model (moderation workflow)."""

    list_display = [
        "id",
        "user",
        "model_type",
        "model_id",
        "field_name",
        "status",
        "reviewed_by",
        "created_at",
    ]
    list_filter = ["status", "model_type", "created_at"]
    search_fields = ["user__username", "field_name", "old_value", "new_value"]
    readonly_fields = [
        "user",
        "model_type",
        "model_id",
        "field_name",
        "old_value",
        "new_value",
        "created_at",
        "updated_at",
        "target_object_link",
    ]
    date_hierarchy = "created_at"
    ordering = ["-created_at"]

    fieldsets = (
        (
            "Request Information",
            {
                "fields": (
                    "user",
                    "status",
                    "model_type",
                    "model_id",
                    "target_object_link",
                )
            },
        ),
        (
            "Change Details",
            {
                "fields": ("field_name", "old_value", "new_value"),
            },
        ),
        (
            "Review Information",
            {
                "fields": ("reviewed_by", "reviewed_at", "notes"),
            },
        ),
        (
            "Timestamps",
            {
                "fields": ("created_at", "updated_at"),
                "classes": ("collapse",),
            },
        ),
    )

    def target_object_link(self, obj):
        """Display a link to the target object."""
        target = obj.get_target_object()
        if target:
            url = f"/admin/core/{obj.model_type}/{obj.model_id}/change/"
            return format_html(
                '<a href="{}">View {}</a>',
                url,
                obj.get_model_type_display(),
            )
        return f"{obj.get_model_type_display()} (ID: {obj.model_id}) - May be deleted"

    target_object_link.short_description = "Target Object"

    actions = ["approve_requests", "reject_requests"]

    def approve_requests(self, request, queryset):
        """Bulk approve change requests."""
        from django.utils import timezone

        count = 0
        for change_request in queryset.filter(status="pending"):
            change_request.status = "approved"
            change_request.reviewed_by = request.user
            change_request.reviewed_at = timezone.now()
            change_request.save()
            count += 1
        self.message_user(request, f"Successfully approved {count} change request(s).")

    approve_requests.short_description = "Approve selected change requests"

    def reject_requests(self, request, queryset):
        """Bulk reject change requests."""
        from django.utils import timezone

        count = 0
        for change_request in queryset.filter(status="pending"):
            change_request.status = "rejected"
            change_request.reviewed_by = request.user
            change_request.reviewed_at = timezone.now()
            change_request.save()
            count += 1
        self.message_user(request, f"Successfully rejected {count} change request(s).")

    reject_requests.short_description = "Reject selected change requests"

    def has_add_permission(self, request):
        """Change requests should only be created through the API."""
        return False

    def has_change_permission(self, request, obj=None):
        """Only allow changing status and notes."""
        return True

    def get_readonly_fields(self, request, obj=None):
        """Make all fields readonly except status and notes for moderators."""
        readonly = list(self.readonly_fields)
        if obj and obj.status != "pending":
            # Already reviewed, make status readonly too
            readonly.append("status")
        return readonly
