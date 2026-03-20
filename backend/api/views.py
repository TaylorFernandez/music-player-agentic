"""
API Views for the Music Player application.
Provides REST API endpoints for songs, albums, artists, and moderation.
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
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.db.models import Q
from django.utils import timezone
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page
from rest_framework import status, viewsets
from rest_framework.authtoken.models import Token
from rest_framework.decorators import action
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import AllowAny, IsAdminUser, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers import (
    AlbumDetailSerializer,
    AlbumSerializer,
    ArtistSerializer,
    ArtistSummarySerializer,
    BatchSongLookupResultSerializer,
    BatchSongLookupSerializer,
    ChangeRequestCreateSerializer,
    ChangeRequestReviewSerializer,
    ChangeRequestSerializer,
    LibrarySyncSerializer,
    SongDetailSerializer,
    SongLookupResultSerializer,
    SongLookupSerializer,
    SongLyricsSerializer,
    SongSerializer,
    UserProfileSerializer,
    UserRegistrationSerializer,
    UserSerializer,
    UserSongSerializer,
)

# Custom Permissions


class IsOwnerOrModerator(AllowAny):
    """
    Custom permission to only allow owners or moderators to access certain endpoints.
    Inherits from AllowAny for general access logic, but checks user role.
    """

    def has_permission(self, request, view):
        """Check if user has owner or moderator role."""
        if not request.user.is_authenticated:
            return False
        try:
            profile = request.user.userprofile
            return profile.role in ["owner", "moderator"]
        except UserProfile.DoesNotExist:
            return False


class IsOwner(AllowAny):
    """
    Custom permission to only allow owners to access certain endpoints.
    """

    def has_permission(self, request, view):
        """Check if user has owner role."""
        if not request.user.is_authenticated:
            return False
        try:
            profile = request.user.userprofile
            return profile.role == "owner"
        except UserProfile.DoesNotExist:
            return False


# Pagination


class StandardPagination(PageNumberPagination):
    """Standard pagination for all endpoints."""

    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100


# Mixins for common functionality


class ModerateActionMixin:
    """Mixin to handle moderation workflow for create/update operations."""

    def _handle_moderated_update(self, instance, validated_data, skip_review=False):
        """
        Handle update with moderation workflow.
        - General users: Creates change request
        - Moderators: Creates change request for another moderator to review
        - Owners with skip_review=True: Applies directly
        """
        user = self.request.user
        profile = user.userprofile

        # Determine model type
        model_type = self._get_model_type(instance)

        # Check if user can skip review
        if skip_review and profile.role == "owner":
            # Apply changes directly
            for field, value in validated_data.items():
                setattr(instance, field, value)
            instance.save()
            return {"success": True, "applied_directly": True, "instance": instance}

        # Create change requests for each field
        change_requests = []
        for field, new_value in validated_data.items():
            old_value = getattr(instance, field, "")
            if str(old_value) != str(new_value):
                change_request = ChangeRequest.objects.create(
                    user=user,
                    model_type=model_type,
                    model_id=instance.id,
                    field_name=field,
                    old_value=str(old_value),
                    new_value=str(new_value),
                    status="pending",
                )
                change_requests.append(change_request)

        if not change_requests:
            return {"success": True, "no_changes": True, "instance": instance}

        return {
            "success": True,
            "change_request_ids": [cr.id for cr in change_requests],
            "status": "pending",
            "message": "Changes submitted for review",
            "instance": instance,
        }

    def _get_model_type(self, instance):
        """Get model type string for an instance."""
        model_map = {
            Song: "song",
            Album: "album",
            Artist: "artist",
        }
        return model_map.get(type(instance), "unknown")


# Authentication Views


class RegisterView(APIView):
    """Handle user registration."""

    permission_classes = [AllowAny]

    def post(self, request):
        """Register a new user."""
        serializer = UserRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response(
                {
                    "success": True,
                    "data": {
                        "user_id": user.id,
                        "username": user.username,
                        "email": user.email,
                        "role": "general",
                    },
                    "message": "Registration successful",
                },
                status=status.HTTP_201_CREATED,
            )
        return Response(
            {"success": False, "error": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST,
        )


class LoginView(APIView):
    """Handle user login."""

    permission_classes = [AllowAny]

    def post(self, request):
        """Authenticate user and return session/token."""
        username = request.data.get("username")
        password = request.data.get("password")

        if not username or not password:
            return Response(
                {"success": False, "error": "Username and password are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = authenticate(username=username, password=password)
        if user:
            login(request, user)

            # Get or create auth token for the user
            token, _ = Token.objects.get_or_create(user=user)

            profile = user.userprofile
            return Response(
                {
                    "success": True,
                    "data": {
                        "user_id": user.id,
                        "username": user.username,
                        "email": user.email,
                        "role": profile.role,
                        "token": token.key,
                    },
                    "message": "Login successful",
                }
            )
        return Response(
            {"success": False, "error": "Invalid credentials."},
            status=status.HTTP_401_UNAUTHORIZED,
        )


class LogoutView(APIView):
    """Handle user logout."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        """Logout the current user."""
        logout(request)
        return Response({"success": True, "message": "Logged out successfully"})


class CurrentUserView(APIView):
    """Return information about the currently authenticated user."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Get current user information."""
        user = request.user
        profile = user.userprofile
        return Response(
            {
                "success": True,
                "data": {
                    "user_id": user.id,
                    "username": user.username,
                    "email": user.email,
                    "role": profile.role,
                    "avatar_url": profile.avatar_url,
                },
            }
        )


# ViewSets


class SongViewSet(ModerateActionMixin, viewsets.ModelViewSet):
    """
    API endpoint for songs.
    Allows CRUD operations with moderation workflow for updates.
    """

    queryset = Song.objects.all().order_by("title")
    serializer_class = SongSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = StandardPagination
    lookup_field = "id"

    def get_serializer_class(self):
        """Use detailed serializer for retrieve action."""
        if self.action == "retrieve":
            return SongDetailSerializer
        return SongSerializer

    def get_queryset(self):
        """Filter queryset based on query parameters."""
        queryset = Song.objects.all().order_by("title")

        # Search filter
        search = self.request.query_params.get("search")
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) | Q(artists__name__icontains=search)
            ).distinct()

        # Artist filter
        artist_id = self.request.query_params.get("artist_id")
        if artist_id:
            queryset = queryset.filter(artists__id=artist_id).distinct()

        # Album filter
        album_id = self.request.query_params.get("album_id")
        if album_id:
            queryset = queryset.filter(albums__id=album_id).distinct()

        # Sorting
        sort = self.request.query_params.get("sort", "title")
        order = self.request.query_params.get("order", "asc")

        valid_sorts = ["title", "duration", "created_at", "updated_at"]
        if sort in valid_sorts:
            prefix = "-" if order == "desc" else ""
            queryset = queryset.order_by(f"{prefix}{sort}")

        return queryset.select_related()

    @method_decorator(cache_page(60 * 5))  # Cache for 5 minutes
    def list(self, request, *args, **kwargs):
        """List songs with caching."""
        return super().list(request, *args, **kwargs)

    def retrieve(self, request, *args, **kwargs):
        """Retrieve single song with full details."""
        instance = self.get_object()
        serializer = SongDetailSerializer(instance)
        return Response({"success": True, "data": serializer.data})

    def create(self, request, *args, **kwargs):
        """Create a new song (requires authentication)."""
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            song = serializer.save()
            return Response(
                {"success": True, "data": SongDetailSerializer(song).data},
                status=status.HTTP_201_CREATED,
            )
        return Response(
            {"success": False, "error": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST,
        )

    def update(self, request, *args, **kwargs):
        """Update song with moderation workflow."""
        partial = kwargs.get("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)

        if serializer.is_valid():
            validated_data = serializer.validated_data
            skip_review = request.data.get("skip_review", False)

            result = self._handle_moderated_update(
                instance, validated_data, skip_review
            )

            if result.get("applied_directly"):
                return Response(
                    {
                        "success": True,
                        "data": SongDetailSerializer(instance).data,
                        "message": "Changes applied directly",
                    }
                )
            elif result.get("no_changes"):
                return Response(
                    {
                        "success": True,
                        "data": SongDetailSerializer(instance).data,
                        "message": "No changes detected",
                    }
                )
            else:
                return Response(
                    {
                        "success": True,
                        "data": {
                            "change_request_ids": result["change_request_ids"],
                            "status": "pending",
                            "message": "Change submitted for moderator review",
                        },
                    }
                )
        return Response(
            {"success": False, "error": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST,
        )

    @action(detail=False, methods=["post"])
    def lookup(self, request):
        """
        Lookup a song by metadata from an MP3 file.
        Attempts to find a matching song in the database.
        """
        serializer = SongLookupSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {"success": False, "error": serializer.errors},
                status=status.HTTP_400_BAD_REQUEST,
            )

        data = serializer.validated_data
        title = data.get("title", "")
        artist_name = data.get("artist", "")
        album_name = data.get("album", "")
        duration = data.get("duration")
        file_hash = data.get("file_hash")

        # Try to find by file_hash first (exact match)
        if file_hash:
            song = Song.objects.filter(file_hash=file_hash).first()
            if song:
                result_serializer = SongLookupResultSerializer(
                    {
                        "match_type": "exact",
                        "confidence": 1.0,
                        "song": song,
                    }
                )
                return Response({"success": True, "data": result_serializer.data})

        # Try to match by title and artist
        query = Q()
        if title:
            query &= Q(title__icontains=title)
        if artist_name:
            query &= Q(artists__name__icontains=artist_name)

        songs = Song.objects.filter(query).distinct() if query else Song.objects.none()

        # Score matches
        scored_songs = []
        for song in songs:
            score = 0.0
            max_score = 100.0

            if title and title.lower() == song.title.lower():
                score += 40
            elif title and title.lower() in song.title.lower():
                score += 20

            # Check artist match
            song_artists = [sa.artist.name.lower() for sa in song.songartist_set.all()]
            if artist_name:
                if artist_name.lower() in song_artists:
                    score += 30
                elif any(artist_name.lower() in a for a in song_artists):
                    score += 15

            # Check duration match (within 2 seconds tolerance)
            if duration and song.duration:
                duration_diff = abs(duration - song.duration)
                if duration_diff <= 2:
                    score += 20
                elif duration_diff <= 5:
                    score += 10

            # Check album match
            if album_name:
                song_albums = [a.title.lower() for a in song.albums.all()]
                if album_name.lower() in song_albums:
                    score += 10

            confidence = score / max_score if max_score > 0 else 0
            scored_songs.append((song, confidence))

        # Sort by confidence
        scored_songs.sort(key=lambda x: x[1], reverse=True)

        if scored_songs and scored_songs[0][1] >= 0.7:
            # High confidence match
            result_serializer = SongLookupResultSerializer(
                {
                    "match_type": "exact" if scored_songs[0][1] >= 0.9 else "partial",
                    "confidence": scored_songs[0][1],
                    "song": scored_songs[0][0],
                    "suggestions": [s[0] for s in scored_songs[1:6] if s[1] >= 0.3],
                }
            )
        elif scored_songs:
            # Low confidence - return suggestions
            result_serializer = SongLookupResultSerializer(
                {
                    "match_type": "partial",
                    "confidence": scored_songs[0][1],
                    "song": scored_songs[0][0] if scored_songs[0][1] >= 0.5 else None,
                    "suggestions": [s[0] for s in scored_songs[:5]],
                }
            )
        else:
            # No match
            result_serializer = SongLookupResultSerializer(
                {
                    "match_type": "none",
                    "confidence": 0.0,
                    "song": None,
                    "suggestions": [],
                }
            )

        return Response({"success": True, "data": result_serializer.data})

    @action(detail=True, methods=["get"])
    def lyrics(self, request, pk=None):
        """Get lyrics for a specific song."""
        song = self.get_object()
        serializer = SongLyricsSerializer(song)
        return Response({"success": True, "data": serializer.data})

    @action(detail=False, methods=["post"])
    def batch_lookup(self, request):
        """
        Batch lookup songs by metadata.
        Allows mobile app to look up multiple songs at once.
        """
        serializer = BatchSongLookupSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {"success": False, "error": serializer.errors},
                status=status.HTTP_400_BAD_REQUEST,
            )

        songs_data = serializer.validated_data["songs"]
        results = []

        for song_data in songs_data:
            # Use the lookup logic for each song
            lookup_serializer = SongLookupSerializer(data=song_data)
            if lookup_serializer.is_valid():
                # Perform lookup (simplified version)
                lookup_data = lookup_serializer.validated_data
                file_hash = lookup_data.get("file_hash")

                if file_hash:
                    song = Song.objects.filter(file_hash=file_hash).first()
                    if song:
                        results.append(
                            {
                                "match_type": "exact",
                                "confidence": 1.0,
                                "song_id": song.id,
                                "song_title": song.title,
                            }
                        )
                        continue

                # Try title + artist match
                title = lookup_data.get("title", "")
                artist_name = lookup_data.get("artist", "")

                if title or artist_name:
                    query = Q()
                    if title:
                        query &= Q(title__icontains=title)
                    if artist_name:
                        query &= Q(artists__name__icontains=artist_name)

                    song = Song.objects.filter(query).distinct().first()
                    if song:
                        results.append(
                            {
                                "match_type": "partial",
                                "confidence": 0.8,
                                "song_id": song.id,
                                "song_title": song.title,
                            }
                        )
                        continue

                results.append(
                    {"match_type": "none", "confidence": 0.0, "song_id": None}
                )
            else:
                results.append(
                    {
                        "match_type": "none",
                        "confidence": 0.0,
                        "error": lookup_serializer.errors,
                    }
                )

        return Response({"success": True, "data": {"results": results}})


class AlbumViewSet(ModerateActionMixin, viewsets.ModelViewSet):
    """
    API endpoint for albums.
    Allows CRUD operations with moderation workflow for updates.
    """

    queryset = Album.objects.all().order_by("-release_date", "title")
    serializer_class = AlbumSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = StandardPagination
    lookup_field = "id"

    def get_serializer_class(self):
        """Use detailed serializer for retrieve action."""
        if self.action == "retrieve":
            return AlbumDetailSerializer
        return AlbumSerializer

    def get_queryset(self):
        """Filter queryset based on query parameters."""
        queryset = Album.objects.all().order_by("-release_date", "title")

        # Search filter
        search = self.request.query_params.get("search")
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search)
                | Q(description__icontains=search)
                | Q(artists__name__icontains=search)
            ).distinct()

        # Artist filter
        artist_id = self.request.query_params.get("artist_id")
        if artist_id:
            queryset = queryset.filter(artists__id=artist_id).distinct()

        # Album type filter
        album_type = self.request.query_params.get("album_type")
        if album_type:
            queryset = queryset.filter(album_type=album_type)

        # Year filter
        year = self.request.query_params.get("year")
        if year:
            queryset = queryset.filter(release_date__year=year)

        return queryset.prefetch_related("artists")

    @method_decorator(cache_page(60 * 5))  # Cache for 5 minutes
    def list(self, request, *args, **kwargs):
        """List albums with caching."""
        return super().list(request, *args, **kwargs)

    def retrieve(self, request, *args, **kwargs):
        """Retrieve single album with full details."""
        instance = self.get_object()
        serializer = AlbumDetailSerializer(instance)
        return Response({"success": True, "data": serializer.data})

    def update(self, request, *args, **kwargs):
        """Update album with moderation workflow."""
        partial = kwargs.get("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)

        if serializer.is_valid():
            validated_data = serializer.validated_data
            skip_review = request.data.get("skip_review", False)

            result = self._handle_moderated_update(
                instance, validated_data, skip_review
            )

            if result.get("applied_directly"):
                return Response(
                    {
                        "success": True,
                        "data": AlbumDetailSerializer(instance).data,
                        "message": "Changes applied directly",
                    }
                )
            elif result.get("no_changes"):
                return Response(
                    {
                        "success": True,
                        "data": AlbumDetailSerializer(instance).data,
                        "message": "No changes detected",
                    }
                )
            else:
                return Response(
                    {
                        "success": True,
                        "data": {
                            "change_request_ids": result["change_request_ids"],
                            "status": "pending",
                            "message": "Change submitted for moderator review",
                        },
                    }
                )
        return Response(
            {"success": False, "error": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST,
        )


class ArtistViewSet(ModerateActionMixin, viewsets.ModelViewSet):
    """
    API endpoint for artists.
    Allows CRUD operations with moderation workflow for updates.
    """

    queryset = Artist.objects.all().order_by("name")
    serializer_class = ArtistSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = StandardPagination
    lookup_field = "id"

    def get_serializer_class(self):
        """Use detailed serializer for retrieve action."""
        if self.action == "retrieve":
            return ArtistSerializer
        return ArtistSerializer

    def get_queryset(self):
        """Filter queryset based on query parameters."""
        queryset = Artist.objects.all().order_by("name")

        # Search filter
        search = self.request.query_params.get("search")
        if search:
            queryset = queryset.filter(
                Q(name__icontains=search) | Q(bio__icontains=search)
            )

        return queryset.prefetch_related("song_set", "album_set")

    @method_decorator(cache_page(60 * 5))  # Cache for 5 minutes
    def list(self, request, *args, **kwargs):
        """List artists with caching."""
        return super().list(request, *args, **kwargs)

    def retrieve(self, request, *args, **kwargs):
        """Retrieve single artist with discography."""
        instance = self.get_object()

        # Get albums for this artist
        albums = Album.objects.filter(artists=instance).order_by("-release_date")

        # Get songs for this artist
        songs = Song.objects.filter(artists=instance).distinct().order_by("title")

        artist_serializer = ArtistSerializer(instance)
        albums_serializer = AlbumSummarySerializer(albums, many=True)
        songs_serializer = SongSerializer(songs, many=True)

        return Response(
            {
                "success": True,
                "data": {
                    **artist_serializer.data,
                    "albums": albums_serializer.data,
                    "songs": songs_serializer.data,
                },
            }
        )

    def update(self, request, *args, **kwargs):
        """Update artist with moderation workflow."""
        partial = kwargs.get("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)

        if serializer.is_valid():
            validated_data = serializer.validated_data
            skip_review = request.data.get("skip_review", False)

            result = self._handle_moderated_update(
                instance, validated_data, skip_review
            )

            if result.get("applied_directly"):
                return Response(
                    {
                        "success": True,
                        "data": ArtistSerializer(instance).data,
                        "message": "Changes applied directly",
                    }
                )
            elif result.get("no_changes"):
                return Response(
                    {
                        "success": True,
                        "data": ArtistSerializer(instance).data,
                        "message": "No changes detected",
                    }
                )
            else:
                return Response(
                    {
                        "success": True,
                        "data": {
                            "change_request_ids": result["change_request_ids"],
                            "status": "pending",
                            "message": "Change submitted for moderator review",
                        },
                    }
                )
        return Response(
            {"success": False, "error": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST,
        )


class ChangeRequestViewSet(viewsets.ModelViewSet):
    """
    API endpoint for change requests (moderation workflow).
    Only moderators and owners can access these endpoints.
    """

    queryset = ChangeRequest.objects.all().order_by("-created_at")
    serializer_class = ChangeRequestSerializer
    permission_classes = [IsAuthenticated, IsOwnerOrModerator]
    pagination_class = StandardPagination
    lookup_field = "id"

    def get_queryset(self):
        """Filter queryset based on query parameters."""
        queryset = ChangeRequest.objects.all().order_by("-created_at")

        # Status filter
        status_filter = self.request.query_params.get("status")
        if status_filter:
            queryset = queryset.filter(status=status_filter)

        # User filter
        user_id = self.request.query_params.get("user_id")
        if user_id:
            queryset = queryset.filter(user__id=user_id)

        # Model type filter
        model_type = self.request.query_params.get("model_type")
        if model_type:
            queryset = queryset.filter(model_type=model_type)

        return queryset.select_related("user", "reviewed_by")

    def list(self, request, *args, **kwargs):
        """List change requests."""
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        serializer = self.get_serializer(page, many=True)
        return self.get_paginated_response(serializer.data)

    @action(detail=False, methods=["post"])
    def create_request(self, request):
        """Create a new change request."""
        serializer = ChangeRequestCreateSerializer(data=request.data)
        if serializer.is_valid():
            data = serializer.validated_data
            model_class = {"song": Song, "album": Album, "artist": Artist}.get(
                data["model_type"]
            )
            instance = model_class.objects.filter(id=data["model_id"]).first()

            if not instance:
                return Response(
                    {"success": False, "error": "Object not found"},
                    status=status.HTTP_404_NOT_FOUND,
                )

            old_value = getattr(instance, data["field_name"], "")

            change_request = ChangeRequest.objects.create(
                user=request.user,
                model_type=data["model_type"],
                model_id=data["model_id"],
                field_name=data["field_name"],
                old_value=str(old_value),
                new_value=data["new_value"],
                status="pending",
                notes=data.get("notes", ""),
            )

            return Response(
                {
                    "success": True,
                    "data": ChangeRequestSerializer(change_request).data,
                    "message": "Change request created successfully",
                },
                status=status.HTTP_201_CREATED,
            )
        return Response(
            {"success": False, "error": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST,
        )

    @action(detail=True, methods=["post"])
    def review(self, request, pk=None):
        """Review (approve or reject) a change request."""
        change_request = self.get_object()

        if change_request.status != "pending":
            return Response(
                {"success": False, "error": "Change request already processed"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Moderators can't approve their own requests
        if change_request.user == request.user:
            profile = request.user.userprofile
            if profile.role != "owner":
                return Response(
                    {
                        "success": False,
                        "error": "Cannot review your own change request",
                    },
                    status=status.HTTP_403_FORBIDDEN,
                )

        serializer = ChangeRequestReviewSerializer(data=request.data)
        if serializer.is_valid():
            data = serializer.validated_data
            action_type = data["action"]
            notes = data.get("notes", "")
            edit_before_apply = data.get("edit_before_apply", False)
            edited_value = data.get("edited_value", "")

            if action_type == "approve":
                # Get the final value to apply
                final_value = (
                    edited_value if edit_before_apply else change_request.new_value
                )

                # Apply the change
                model_class = {
                    "song": Song,
                    "album": Album,
                    "artist": Artist,
                }.get(change_request.model_type)

                instance = model_class.objects.filter(
                    id=change_request.model_id
                ).first()
                if instance:
                    setattr(instance, change_request.field_name, final_value)
                    instance.save()

                change_request.status = "approved"
                change_request.reviewed_by = request.user
                change_request.reviewed_at = timezone.now()
                if notes:
                    change_request.notes = notes
                change_request.save()

                return Response(
                    {
                        "success": True,
                        "data": {
                            "change_request_id": change_request.id,
                            "status": "approved",
                            "applied": True,
                            "message": "Change request approved and applied",
                        },
                    }
                )
            else:
                # Reject
                change_request.status = "rejected"
                change_request.reviewed_by = request.user
                change_request.reviewed_at = timezone.now()
                if notes:
                    change_request.notes = notes
                change_request.save()

                return Response(
                    {
                        "success": True,
                        "data": {
                            "change_request_id": change_request.id,
                            "status": "rejected",
                            "message": "Change request rejected",
                        },
                    }
                )
        return Response(
            {"success": False, "error": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST,
        )

    @action(detail=False, methods=["get"])
    def history(self, request):
        """Get history of moderated changes."""
        queryset = ChangeRequest.objects.filter(
            status__in=["approved", "rejected"]
        ).order_by("-reviewed_at")

        # Filter by user
        user_id = request.query_params.get("user_id")
        if user_id:
            queryset = queryset.filter(user__id=user_id)

        # Filter by reviewer
        reviewed_by = request.query_params.get("reviewed_by")
        if reviewed_by:
            queryset = queryset.filter(reviewed_by__id=reviewed_by)

        # Date range filter
        date_from = request.query_params.get("date_from")
        date_to = request.query_params.get("date_to")
        if date_from:
            queryset = queryset.filter(reviewed_at__date__gte=date_from)
        if date_to:
            queryset = queryset.filter(reviewed_at__date__lte=date_to)

        page = self.paginate_queryset(queryset)
        serializer = self.get_serializer(page, many=True)
        return self.get_paginated_response(serializer.data)


class UserViewSet(viewsets.ModelViewSet):
    """
    API endpoint for users.
    Only owners can access user management endpoints.
    """

    queryset = User.objects.all().order_by("-date_joined")
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated, IsOwner]
    pagination_class = StandardPagination
    lookup_field = "id"

    def get_queryset(self):
        """Filter queryset based on query parameters."""
        queryset = User.objects.all().order_by("-date_joined")

        # Role filter
        role = self.request.query_params.get("role")
        if role:
            queryset = queryset.filter(userprofile__role=role)

        # Search filter
        search = self.request.query_params.get("search")
        if search:
            queryset = queryset.filter(
                Q(username__icontains=search) | Q(email__icontains=search)
            )

        return queryset.select_related("userprofile")

    def list(self, request, *args, **kwargs):
        """List users."""
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)

        users_data = []
        for user in page:
            user_data = UserSerializer(user).data
            user_data["role"] = user.userprofile.role
            user_data["avatar_url"] = user.userprofile.avatar_url
            users_data.append(user_data)

        return self.get_paginated_response(users_data)

    @action(detail=True, methods=["put"])
    def role(self, request, pk=None):
        """Update a user's role."""
        user = self.get_object()
        role = request.data.get("role")

        if role not in ["general", "moderator", "owner"]:
            return Response(
                {"success": False, "error": "Invalid role"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        profile = user.userprofile
        profile.role = role
        profile.save()

        return Response(
            {
                "success": True,
                "data": {
                    "user_id": user.id,
                    "username": user.username,
                    "role": role,
                },
                "message": "Role updated successfully",
            }
        )


class UserSongViewSet(viewsets.ModelViewSet):
    """
    API endpoint for user's personal song library.
    Allows users to sync and manage their personal collection.
    """

    serializer_class = UserSongSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = StandardPagination

    def get_queryset(self):
        """Return songs in current user's library."""
        return UserSong.objects.filter(user=self.request.user).select_related("song")

    def perform_create(self, serializer):
        """Associate song with current user."""
        serializer.save(user=self.request.user)

    @action(detail=False, methods=["post"])
    def sync(self, request):
        """
        Sync local library metadata with the server.
        Accepts a list of song IDs and ensures they are in the user's library.
        """
        serializer = LibrarySyncSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {"success": False, "error": serializer.errors},
                status=status.HTTP_400_BAD_REQUEST,
            )

        song_ids = serializer.validated_data["song_ids"]
        user = request.user

        # Get existing song IDs in user library
        existing_song_ids = set(
            UserSong.objects.filter(user=user, song_id__in=song_ids).values_list(
                "song_id", flat=True
            )
        )

        # Identify new song IDs to add
        new_song_ids = [sid for sid in song_ids if sid not in existing_song_ids]

        # Bulk create new UserSong associations
        user_songs = [UserSong(user=user, song_id=sid) for sid in new_song_ids]
        UserSong.objects.bulk_create(user_songs)

        return Response(
            {
                "success": True,
                "data": {
                    "added_count": len(new_song_ids),
                    "total_count": UserSong.objects.filter(user=user).count(),
                },
                "message": f"Successfully synced {len(new_song_ids)} new songs to library.",
            }
        )
