"""
Unit tests for Web views: home, dashboard, songs, albums, artists, moderation.
"""

from django.contrib.auth.models import User
from django.test import Client, TestCase
from django.urls import reverse

from core.models import Album, Artist, ChangeRequest, Song, SongAlbum, SongArtist


class HomeViewTest(TestCase):
    """Tests for the home page view."""

    def setUp(self):
        """Create test data."""
        self.client = Client()
        self.artist = Artist.objects.create(name="Test Artist")
        self.song = Song.objects.create(
            title="Test Song",
            duration=180,
            file_hash="a" * 64,
        )
        SongArtist.objects.create(song=self.song, artist=self.artist, role="main")
        self.album = Album.objects.create(title="Test Album")
        self.user = User.objects.create_user(
            username="testuser",
            email="test@example.com",
            password="testpass123",
        )

    def test_home_view_status_code(self):
        """Test that home page returns 200."""
        response = self.client.get(reverse("web:home"))
        self.assertEqual(response.status_code, 200)

    def test_home_view_template(self):
        """Test that home page uses correct template."""
        response = self.client.get(reverse("web:home"))
        self.assertTemplateUsed(response, "web/home.html")

    def test_home_view_context(self):
        """Test that home page has correct context."""
        response = self.client.get(reverse("web:home"))
        self.assertIn("song_count", response.context)
        self.assertIn("album_count", response.context)
        self.assertIn("artist_count", response.context)
        self.assertIn("recent_songs", response.context)
        self.assertIn("recent_albums", response.context)

    def test_home_view_displays_stats(self):
        """Test that home page displays statistics."""
        response = self.client.get(reverse("web:home"))
        self.assertEqual(response.context["song_count"], 1)
        self.assertEqual(response.context["album_count"], 1)
        self.assertEqual(response.context["artist_count"], 1)


class DashboardViewTest(TestCase):
    """Tests for the dashboard view."""

    def setUp(self):
        """Create test data."""
        self.client = Client()
        self.user = User.objects.create_user(
            username="testuser",
            email="test@example.com",
            password="testpass123",
        )
        self.client.login(username="testuser", password="testpass123")

    def test_dashboard_view_requires_login(self):
        """Test that dashboard requires authentication."""
        client = Client()
        response = client.get(reverse("web:dashboard"))
        self.assertNotEqual(response.status_code, 200)

    def test_dashboard_view_status_code(self):
        """Test that dashboard returns 200 for authenticated user."""
        response = self.client.get(reverse("web:dashboard"))
        self.assertEqual(response.status_code, 200)

    def test_dashboard_view_template(self):
        """Test that dashboard uses correct template."""
        response = self.client.get(reverse("web:dashboard"))
        self.assertTemplateUsed(response, "web/dashboard.html")

    def test_dashboard_view_context(self):
        """Test that dashboard has correct context."""
        response = self.client.get(reverse("web:dashboard"))
        self.assertIn("user_profile", response.context)
        self.assertIn("my_requests", response.context)


class SongListViewTest(TestCase):
    """Tests for the song list view."""

    def setUp(self):
        """Create test data."""
        self.client = Client()
        self.artist = Artist.objects.create(name="Test Artist")
        self.song1 = Song.objects.create(
            title="Alpha Song",
            duration=180,
            file_hash="a" * 64,
        )
        self.song2 = Song.objects.create(
            title="Beta Song",
            duration=240,
            file_hash="b" * 64,
        )
        SongArtist.objects.create(song=self.song1, artist=self.artist, role="main")
        SongArtist.objects.create(song=self.song2, artist=self.artist, role="main")

    def test_song_list_view_status_code(self):
        """Test that song list returns 200."""
        response = self.client.get(reverse("web:song_list"))
        self.assertEqual(response.status_code, 200)

    def test_song_list_view_template(self):
        """Test that song list uses correct template."""
        response = self.client.get(reverse("web:song_list"))
        self.assertTemplateUsed(response, "web/songs/song_list.html")

    def test_song_list_view_context(self):
        """Test that song list has correct context."""
        response = self.client.get(reverse("web:song_list"))
        self.assertIn("songs", response.context)
        self.assertIn("artists", response.context)
        self.assertIn("albums", response.context)

    def test_song_list_displays_songs(self):
        """Test that song list displays songs."""
        response = self.client.get(reverse("web:song_list"))
        self.assertEqual(len(response.context["songs"]), 2)

    def test_song_list_search_filter(self):
        """Test that song list can be searched."""
        response = self.client.get(reverse("web:song_list"), {"search": "Alpha"})
        self.assertEqual(len(response.context["songs"]), 1)
        self.assertEqual(response.context["songs"][0].title, "Alpha Song")

    def test_song_list_artist_filter(self):
        """Test that song list can be filtered by artist."""
        response = self.client.get(reverse("web:song_list"), {"artist": self.artist.id})
        self.assertEqual(len(response.context["songs"]), 2)

    def test_song_list_sorting(self):
        """Test that song list can be sorted."""
        response = self.client.get(reverse("web:song_list"), {"sort": "-title"})
        songs = list(response.context["songs"])
        self.assertEqual(songs[0].title, "Beta Song")
        self.assertEqual(songs[1].title, "Alpha Song")

    def test_song_list_pagination(self):
        """Test that song list is paginated."""
        # Create more songs
        for i in range(30):
            Song.objects.create(
                title=f"Song {i}",
                duration=180,
                file_hash=f"{i:02d}"
                * 32,  # Creates 64-char hash (e.g., "0000..." or "0101...")
            )

        response = self.client.get(reverse("web:song_list"))
        self.assertIn("songs", response.context)
        # Default pagination is 25
        self.assertEqual(len(response.context["songs"]), 25)


class SongDetailViewTest(TestCase):
    """Tests for the song detail view."""

    def setUp(self):
        """Create test data."""
        self.client = Client()
        self.artist = Artist.objects.create(name="Test Artist")
        self.album = Album.objects.create(title="Test Album")
        self.song = Song.objects.create(
            title="Test Song",
            duration=180,
            file_hash="a" * 64,
            lyrics="Test lyrics",
        )
        SongArtist.objects.create(song=self.song, artist=self.artist, role="main")
        SongAlbum.objects.create(song=self.song, album=self.album, track_number=1)

    def test_song_detail_view_status_code(self):
        """Test that song detail returns 200."""
        response = self.client.get(
            reverse("web:song_detail", kwargs={"pk": self.song.id})
        )
        self.assertEqual(response.status_code, 200)

    def test_song_detail_view_template(self):
        """Test that song detail uses correct template."""
        response = self.client.get(
            reverse("web:song_detail", kwargs={"pk": self.song.id})
        )
        self.assertTemplateUsed(response, "web/songs/song_detail.html")

    def test_song_detail_view_context(self):
        """Test that song detail has correct context."""
        response = self.client.get(
            reverse("web:song_detail", kwargs={"pk": self.song.id})
        )
        self.assertIn("song", response.context)
        self.assertEqual(response.context["song"], self.song)

    def test_song_detail_displays_info(self):
        """Test that song detail displays song information."""
        response = self.client.get(
            reverse("web:song_detail", kwargs={"pk": self.song.id})
        )
        self.assertContains(response, self.song.title)
        self.assertContains(response, self.artist.name)
        self.assertContains(response, self.album.title)

    def test_song_detail_404_for_nonexistent(self):
        """Test that song detail returns 404 for nonexistent song."""
        response = self.client.get(reverse("web:song_detail", kwargs={"pk": 999}))
        self.assertEqual(response.status_code, 404)


class AlbumListViewTest(TestCase):
    """Tests for the album list view."""

    def setUp(self):
        """Create test data."""
        self.client = Client()
        self.artist = Artist.objects.create(name="Test Artist")
        self.album1 = Album.objects.create(
            title="Alpha Album",
            album_type="album",
        )
        self.album2 = Album.objects.create(
            title="Beta Album",
            album_type="ep",
        )
        from core.models import AlbumArtist

        AlbumArtist.objects.create(album=self.album1, artist=self.artist)
        AlbumArtist.objects.create(album=self.album2, artist=self.artist)

    def test_album_list_view_status_code(self):
        """Test that album list returns 200."""
        response = self.client.get(reverse("web:album_list"))
        self.assertEqual(response.status_code, 200)

    def test_album_list_view_template(self):
        """Test that album list uses correct template."""
        response = self.client.get(reverse("web:album_list"))
        self.assertTemplateUsed(response, "web/albums/album_list.html")

    def test_album_list_view_context(self):
        """Test that album list has correct context."""
        response = self.client.get(reverse("web:album_list"))
        self.assertIn("albums", response.context)
        self.assertIn("artists", response.context)

    def test_album_list_displays_albums(self):
        """Test that album list displays albums."""
        response = self.client.get(reverse("web:album_list"))
        self.assertEqual(len(response.context["albums"]), 2)

    def test_album_list_search_filter(self):
        """Test that album list can be searched."""
        response = self.client.get(reverse("web:album_list"), {"search": "Alpha"})
        self.assertEqual(len(response.context["albums"]), 1)
        self.assertEqual(response.context["albums"][0].title, "Alpha Album")

    def test_album_list_type_filter(self):
        """Test that album list can be filtered by type."""
        response = self.client.get(reverse("web:album_list"), {"type": "album"})
        self.assertEqual(len(response.context["albums"]), 1)


class AlbumDetailViewTest(TestCase):
    """Tests for the album detail view."""

    def setUp(self):
        """Create test data."""
        self.client = Client()
        self.artist = Artist.objects.create(name="Test Artist")
        self.album = Album.objects.create(
            title="Test Album",
            album_type="album",
        )
        from core.models import AlbumArtist

        AlbumArtist.objects.create(album=self.album, artist=self.artist)
        self.song1 = Song.objects.create(
            title="Song 1",
            duration=180,
            file_hash="a" * 64,
        )
        self.song2 = Song.objects.create(
            title="Song 2",
            duration=240,
            file_hash="b" * 64,
        )
        SongArtist.objects.create(song=self.song1, artist=self.artist, role="main")
        SongArtist.objects.create(song=self.song2, artist=self.artist, role="main")
        SongAlbum.objects.create(song=self.song1, album=self.album, track_number=1)
        SongAlbum.objects.create(song=self.song2, album=self.album, track_number=2)

    def test_album_detail_view_status_code(self):
        """Test that album detail returns 200."""
        response = self.client.get(
            reverse("web:album_detail", kwargs={"pk": self.album.id})
        )
        self.assertEqual(response.status_code, 200)

    def test_album_detail_view_template(self):
        """Test that album detail uses correct template."""
        response = self.client.get(
            reverse("web:album_detail", kwargs={"pk": self.album.id})
        )
        self.assertTemplateUsed(response, "web/albums/album_detail.html")

    def test_album_detail_view_context(self):
        """Test that album detail has correct context."""
        response = self.client.get(
            reverse("web:album_detail", kwargs={"pk": self.album.id})
        )
        self.assertIn("album", response.context)
        self.assertIn("songs", response.context)
        self.assertEqual(response.context["album"], self.album)

    def test_album_detail_displays_tracks(self):
        """Test that album detail displays track listing."""
        response = self.client.get(
            reverse("web:album_detail", kwargs={"pk": self.album.id})
        )
        self.assertContains(response, self.song1.title)
        self.assertContains(response, self.song2.title)


class ArtistListViewTest(TestCase):
    """Tests for the artist list view."""

    def setUp(self):
        """Create test data."""
        self.client = Client()
        self.artist1 = Artist.objects.create(name="Alpha Artist")
        self.artist2 = Artist.objects.create(name="Beta Artist")

    def test_artist_list_view_status_code(self):
        """Test that artist list returns 200."""
        response = self.client.get(reverse("web:artist_list"))
        self.assertEqual(response.status_code, 200)

    def test_artist_list_view_template(self):
        """Test that artist list uses correct template."""
        response = self.client.get(reverse("web:artist_list"))
        self.assertTemplateUsed(response, "web/artists/artist_list.html")

    def test_artist_list_view_context(self):
        """Test that artist list has correct context."""
        response = self.client.get(reverse("web:artist_list"))
        self.assertIn("artists", response.context)

    def test_artist_list_displays_artists(self):
        """Test that artist list displays artists."""
        response = self.client.get(reverse("web:artist_list"))
        self.assertEqual(len(response.context["artists"]), 2)

    def test_artist_list_search_filter(self):
        """Test that artist list can be searched."""
        response = self.client.get(reverse("web:artist_list"), {"search": "Alpha"})
        self.assertEqual(len(response.context["artists"]), 1)
        self.assertEqual(response.context["artists"][0].name, "Alpha Artist")


class ArtistDetailViewTest(TestCase):
    """Tests for the artist detail view."""

    def setUp(self):
        """Create test data."""
        self.client = Client()
        self.artist = Artist.objects.create(
            name="Test Artist",
            bio="A test artist",
        )
        self.album = Album.objects.create(title="Test Album")
        from core.models import AlbumArtist

        AlbumArtist.objects.create(album=self.album, artist=self.artist)
        self.song1 = Song.objects.create(
            title="Song 1",
            duration=180,
            file_hash="a" * 64,
        )
        self.song2 = Song.objects.create(
            title="Song 2",
            duration=240,
            file_hash="b" * 64,
        )
        SongArtist.objects.create(song=self.song1, artist=self.artist, role="main")
        SongArtist.objects.create(song=self.song2, artist=self.artist, role="main")

    def test_artist_detail_view_status_code(self):
        """Test that artist detail returns 200."""
        response = self.client.get(
            reverse("web:artist_detail", kwargs={"pk": self.artist.id})
        )
        self.assertEqual(response.status_code, 200)

    def test_artist_detail_view_template(self):
        """Test that artist detail uses correct template."""
        response = self.client.get(
            reverse("web:artist_detail", kwargs={"pk": self.artist.id})
        )
        self.assertTemplateUsed(response, "web/artists/artist_detail.html")

    def test_artist_detail_view_context(self):
        """Test that artist detail has correct context."""
        response = self.client.get(
            reverse("web:artist_detail", kwargs={"pk": self.artist.id})
        )
        self.assertIn("artist", response.context)
        self.assertIn("albums", response.context)
        self.assertIn("songs", response.context)
        self.assertEqual(response.context["artist"], self.artist)

    def test_artist_detail_displays_info(self):
        """Test that artist detail displays artist information."""
        response = self.client.get(
            reverse("web:artist_detail", kwargs={"pk": self.artist.id})
        )
        self.assertContains(response, self.artist.name)
        self.assertContains(response, self.artist.bio)


class ChangeRequestListViewTest(TestCase):
    """Tests for the change request list view."""

    def setUp(self):
        """Create test data."""
        self.client = Client()
        self.user = User.objects.create_user(
            username="testuser",
            email="test@example.com",
            password="testpass123",
        )
        self.song = Song.objects.create(
            title="Test Song",
            duration=180,
            file_hash="a" * 64,
        )
        self.client.login(username="testuser", password="testpass123")

    def test_change_request_list_requires_login(self):
        """Test that change request list requires authentication."""
        client = Client()
        response = client.get(reverse("web:change_request_list"))
        self.assertNotEqual(response.status_code, 200)

    def test_change_request_list_view_status_code(self):
        """Test that change request list returns 200."""
        response = self.client.get(reverse("web:change_request_list"))
        self.assertEqual(response.status_code, 200)

    def test_change_request_list_view_template(self):
        """Test that change request list uses correct template."""
        response = self.client.get(reverse("web:change_request_list"))
        self.assertTemplateUsed(response, "web/moderation/change_request_list.html")

    def test_change_request_list_view_context(self):
        """Test that change request list has correct context."""
        response = self.client.get(reverse("web:change_request_list"))
        self.assertIn("change_requests", response.context)
        self.assertIn("user_profile", response.context)

    def test_change_request_list_displays_requests(self):
        """Test that change request list displays requests."""
        ChangeRequest.objects.create(
            user=self.user,
            model_type="song",
            model_id=self.song.id,
            field_name="title",
            old_value="Test Song",
            new_value="Updated Song",
        )
        response = self.client.get(reverse("web:change_request_list"))
        self.assertEqual(len(response.context["change_requests"]), 1)


class SearchViewTest(TestCase):
    """Tests for the search view."""

    def setUp(self):
        """Create test data."""
        self.client = Client()
        self.artist = Artist.objects.create(name="Test Artist")
        self.album = Album.objects.create(title="Test Album")
        self.song = Song.objects.create(
            title="Test Song",
            duration=180,
            file_hash="a" * 64,
        )
        SongArtist.objects.create(song=self.song, artist=self.artist, role="main")

    def test_search_view_status_code(self):
        """Test that search returns 200."""
        response = self.client.get(reverse("web:search"))
        self.assertEqual(response.status_code, 200)

    def test_search_view_template(self):
        """Test that search uses correct template."""
        response = self.client.get(reverse("web:search"))
        self.assertTemplateUsed(response, "web/search.html")

    def test_search_with_query(self):
        """Test that search works with query parameter."""
        response = self.client.get(reverse("web:search"), {"q": "Test"})
        self.assertIn("songs", response.context)
        self.assertIn("albums", response.context)
        self.assertIn("artists", response.context)

    def test_search_finds_song(self):
        """Test that search finds songs."""
        response = self.client.get(reverse("web:search"), {"q": "Test Song"})
        self.assertEqual(len(response.context["songs"]), 1)

    def test_search_finds_album(self):
        """Test that search finds albums."""
        response = self.client.get(reverse("web:search"), {"q": "Test Album"})
        self.assertEqual(len(response.context["albums"]), 1)

    def test_search_finds_artist(self):
        """Test that search finds artists."""
        response = self.client.get(reverse("web:search"), {"q": "Test Artist"})
        self.assertEqual(len(response.context["artists"]), 1)
