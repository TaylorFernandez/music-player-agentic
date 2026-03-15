from core.models import (
    Album,
    Artist,
    ChangeRequest,
    Song,
    SongAlbum,
    SongArtist,
    UserProfile,
)
from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.contrib.auth.mixins import LoginRequiredMixin
from django.db.models import Q
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse_lazy
from django.utils import timezone
from django.views.generic import (
    CreateView,
    DeleteView,
    DetailView,
    ListView,
    UpdateView,
)

# ============================================================
# Home View
# ============================================================


def home(request):
    """Home page view."""
    context = {
        "song_count": Song.objects.count(),
        "album_count": Album.objects.count(),
        "artist_count": Artist.objects.count(),
        "recent_songs": Song.objects.order_by("-created_at")[:5],
        "recent_albums": Album.objects.order_by("-created_at")[:5],
    }
    return render(request, "web/home.html", context)


# ============================================================
# Dashboard View
# ============================================================


@login_required
def dashboard(request):
    """User dashboard view."""
    user_profile = request.user.userprofile

    context = {
        "user_profile": user_profile,
        "pending_requests": ChangeRequest.objects.filter(status="pending").count()
        if user_profile.can_moderate
        else 0,
        "my_requests": ChangeRequest.objects.filter(user=request.user).order_by(
            "-created_at"
        )[:5],
    }

    if user_profile.can_moderate:
        context["pending_requests_list"] = ChangeRequest.objects.filter(
            status="pending"
        ).order_by("-created_at")[:10]

    return render(request, "web/dashboard.html", context)


# ============================================================
# Song Views
# ============================================================


class SongListView(ListView):
    """List all songs with search and filtering."""

    model = Song
    template_name = "web/songs/song_list.html"
    context_object_name = "songs"
    paginate_by = 25

    def get_queryset(self):
        queryset = (
            Song.objects.all().select_related().prefetch_related("artists", "albums")
        )

        # Search filter
        search = self.request.GET.get("search")
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) | Q(artists__name__icontains=search)
            ).distinct()

        # Artist filter
        artist_id = self.request.GET.get("artist")
        if artist_id:
            queryset = queryset.filter(artists__id=artist_id).distinct()

        # Album filter
        album_id = self.request.GET.get("album")
        if album_id:
            queryset = queryset.filter(albums__id=album_id).distinct()

        # Sort
        sort = self.request.GET.get("sort", "title")
        if sort == "title":
            queryset = queryset.order_by("title")
        elif sort == "-title":
            queryset = queryset.order_by("-title")
        elif sort == "created":
            queryset = queryset.order_by("-created_at")
        elif sort == "duration":
            queryset = queryset.order_by("duration")

        return queryset

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["search"] = self.request.GET.get("search", "")
        context["artists"] = Artist.objects.all().order_by("name")
        context["albums"] = Album.objects.all().order_by("title")
        context["selected_artist"] = self.request.GET.get("artist", "")
        context["selected_album"] = self.request.GET.get("album", "")
        context["sort"] = self.request.GET.get("sort", "title")
        return context


class SongDetailView(DetailView):
    """Detail view for a single song."""

    model = Song
    template_name = "web/songs/song_detail.html"
    context_object_name = "song"


@login_required
def song_create(request):
    """Create a new song (with moderation for general users)."""
    if request.method == "POST":
        # Get form data
        title = request.POST.get("title")
        duration = request.POST.get("duration")
        lyrics = request.POST.get("lyrics", "")
        file_hash = request.POST.get("file_hash", "")
        artwork_url = request.POST.get("artwork_url", "")

        # Check user role
        user_profile = request.user.userprofile

        if user_profile.role == "owner":
            # Owner can create directly
            song = Song.objects.create(
                title=title,
                duration=int(duration) if duration else 0,
                lyrics=lyrics,
                file_hash=file_hash,
                artwork_url=artwork_url if artwork_url else None,
            )

            # Add artists
            artist_ids = request.POST.getlist("artists")
            for i, artist_id in enumerate(artist_ids):
                role = "main" if i == 0 else "featured"
                SongArtist.objects.create(song=song, artist_id=artist_id, role=role)

            # Add albums
            album_ids = request.POST.getlist("albums")
            track_numbers = request.POST.getlist("track_numbers")
            for i, album_id in enumerate(album_ids):
                track_number = track_numbers[i] if i < len(track_numbers) else None
                SongAlbum.objects.create(
                    song=song,
                    album_id=album_id,
                    track_number=int(track_number) if track_number else None,
                )

            messages.success(request, "Song created successfully!")
            return redirect("web:song_detail", pk=song.id)
        else:
            # General users and moderators create change requests
            ChangeRequest.objects.create(
                user=request.user,
                model_type="song",
                model_id=0,  # New song
                field_name="title",
                old_value="",
                new_value=title,
                status="pending",
                notes=f"New song creation request. Duration: {duration}, Artists: {request.POST.getlist('artists')}",
            )
            messages.info(
                request, "Your song creation request has been submitted for review."
            )
            return redirect("web:song_list")

    context = {
        "artists": Artist.objects.all().order_by("name"),
        "albums": Album.objects.all().order_by("title"),
    }
    return render(request, "web/songs/song_form.html", context)


@login_required
def song_edit(request, pk):
    """Edit an existing song (with moderation for general users)."""
    song = get_object_or_404(Song, pk=pk)
    user_profile = request.user.userprofile

    if request.method == "POST":
        field = request.POST.get("field")
        new_value = request.POST.get("new_value")

        if user_profile.role == "owner":
            # Owner can edit directly
            if field == "title":
                song.title = new_value
            elif field == "duration":
                song.duration = int(new_value)
            elif field == "lyrics":
                song.lyrics = new_value
            elif field == "artwork_url":
                song.artwork_url = new_value

            song.save()
            messages.success(request, "Song updated successfully!")
            return redirect("web:song_detail", pk=song.id)
        else:
            # Create change request
            old_value = getattr(song, field) if hasattr(song, field) else ""

            ChangeRequest.objects.create(
                user=request.user,
                model_type="song",
                model_id=song.id,
                field_name=field,
                old_value=str(old_value),
                new_value=new_value,
                status="pending",
            )
            messages.info(request, "Your change request has been submitted for review.")
            return redirect("web:song_detail", pk=song.id)

    context = {
        "song": song,
    }
    return render(request, "web/songs/song_edit.html", context)


# ============================================================
# Album Views
# ============================================================


class AlbumListView(ListView):
    """List all albums with search and filtering."""

    model = Album
    template_name = "web/albums/album_list.html"
    context_object_name = "albums"
    paginate_by = 25

    def get_queryset(self):
        queryset = Album.objects.all().prefetch_related("artists", "songs")

        # Search filter
        search = self.request.GET.get("search")
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) | Q(artists__name__icontains=search)
            ).distinct()

        # Artist filter
        artist_id = self.request.GET.get("artist")
        if artist_id:
            queryset = queryset.filter(artists__id=artist_id).distinct()

        # Album type filter
        album_type = self.request.GET.get("type")
        if album_type:
            queryset = queryset.filter(album_type=album_type)

        # Sort
        sort = self.request.GET.get("sort", "title")
        if sort == "title":
            queryset = queryset.order_by("title")
        elif sort == "date":
            queryset = queryset.order_by("-release_date")
        elif sort == "created":
            queryset = queryset.order_by("-created_at")

        return queryset

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["search"] = self.request.GET.get("search", "")
        context["artists"] = Artist.objects.all().order_by("name")
        context["selected_artist"] = self.request.GET.get("artist", "")
        context["selected_type"] = self.request.GET.get("type", "")
        context["sort"] = self.request.GET.get("sort", "title")
        context["album_types"] = [
            ("album", "Album"),
            ("ep", "EP"),
            ("single", "Single"),
            ("compilation", "Compilation"),
            ("soundtrack", "Soundtrack"),
        ]
        return context


class AlbumDetailView(DetailView):
    """Detail view for a single album."""

    model = Album
    template_name = "web/albums/album_detail.html"
    context_object_name = "album"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["songs"] = self.object.songs.all().order_by("songalbum__track_number")
        return context


# ============================================================
# Artist Views
# ============================================================


class ArtistListView(ListView):
    """List all artists with search."""

    model = Artist
    template_name = "web/artists/artist_list.html"
    context_object_name = "artists"
    paginate_by = 25

    def get_queryset(self):
        queryset = Artist.objects.all()

        # Search filter
        search = self.request.GET.get("search")
        if search:
            queryset = queryset.filter(name__icontains=search)

        # Sort
        sort = self.request.GET.get("sort", "name")
        if sort == "name":
            queryset = queryset.order_by("name")
        elif sort == "songs":
            queryset = queryset.order_by("-song_count")
        elif sort == "albums":
            queryset = queryset.order_by("-album_count")

        return queryset

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["search"] = self.request.GET.get("search", "")
        context["sort"] = self.request.GET.get("sort", "name")
        return context


class ArtistDetailView(DetailView):
    """Detail view for a single artist."""

    model = Artist
    template_name = "web/artists/artist_detail.html"
    context_object_name = "artist"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["albums"] = self.object.albums.all().order_by("-release_date")
        context["songs"] = self.object.songs.all().order_by("title")
        return context


# ============================================================
# Moderation Views
# ============================================================


class ChangeRequestListView(LoginRequiredMixin, ListView):
    """List change requests for moderation."""

    model = ChangeRequest
    template_name = "web/moderation/change_request_list.html"
    context_object_name = "change_requests"
    paginate_by = 25

    def get_queryset(self):
        user_profile = self.request.user.userprofile

        if user_profile.can_moderate:
            # Moderators and owners can see all pending requests
            queryset = ChangeRequest.objects.all()
        else:
            # General users can only see their own requests
            queryset = ChangeRequest.objects.filter(user=self.request.user)

        # Status filter
        status = self.request.GET.get("status")
        if status:
            queryset = queryset.filter(status=status)

        # Model type filter
        model_type = self.request.GET.get("model_type")
        if model_type:
            queryset = queryset.filter(model_type=model_type)

        return queryset.order_by("-created_at")

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["user_profile"] = self.request.user.userprofile
        context["selected_status"] = self.request.GET.get("status", "")
        context["selected_model"] = self.request.GET.get("model_type", "")
        context["statuses"] = ["pending", "approved", "rejected"]
        context["model_types"] = ["song", "album", "artist"]
        return context


@login_required
def change_request_review(request, pk):
    """Review and approve/reject a change request."""
    if not request.user.userprofile.can_moderate:
        messages.error(request, "You do not have permission to review change requests.")
        return redirect("web:change_request_list")

    change_request = get_object_or_404(ChangeRequest, pk=pk)

    if request.method == "POST":
        action = request.POST.get("action")
        notes = request.POST.get("notes", "")

        if action == "approve":
            # Apply the change
            model_class = {
                "song": Song,
                "album": Album,
                "artist": Artist,
            }.get(change_request.model_type)

            if model_class:
                if change_request.model_id == 0:
                    # Creating new object - handled differently
                    pass
                else:
                    # Update existing object
                    obj = model_class.objects.filter(id=change_request.model_id).first()
                    if obj:
                        setattr(
                            obj, change_request.field_name, change_request.new_value
                        )
                        obj.save()

            change_request.status = "approved"
            change_request.reviewed_by = request.user
            change_request.reviewed_at = timezone.now()
            change_request.notes = notes
            change_request.save()

            messages.success(request, "Change request approved!")

        elif action == "reject":
            change_request.status = "rejected"
            change_request.reviewed_by = request.user
            change_request.reviewed_at = timezone.now()
            change_request.notes = notes
            change_request.save()

            messages.info(request, "Change request rejected.")

        return redirect("web:change_request_list")

    context = {
        "change_request": change_request,
    }
    return render(request, "web/moderation/change_request_review.html", context)


# ============================================================
# Profile Views
# ============================================================


@login_required
def profile(request):
    """User profile view."""
    user_profile = request.user.userprofile

    if request.method == "POST":
        # Update profile
        new_role = request.POST.get("role")
        if new_role and user_profile.role == "owner":
            # Only owners can change roles
            user_profile.role = new_role
            user_profile.save()
            messages.success(request, "Profile updated successfully!")
        return redirect("web:profile")

    context = {
        "user_profile": user_profile,
        "my_requests": ChangeRequest.objects.filter(user=request.user).order_by(
            "-created_at"
        )[:10],
    }
    return render(request, "web/profile.html", context)


# ============================================================
# Search View
# ============================================================


def search(request):
    """Global search view."""
    query = request.GET.get("q", "")

    songs = []
    albums = []
    artists = []

    if query:
        songs = Song.objects.filter(title__icontains=query)[:10]
        albums = Album.objects.filter(title__icontains=query)[:10]
        artists = Artist.objects.filter(name__icontains=query)[:10]

    context = {
        "query": query,
        "songs": songs,
        "albums": albums,
        "artists": artists,
    }
    return render(request, "web/search.html", context)
