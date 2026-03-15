"""
Unit tests for Core models: Artist, Album, Song, and related models.
"""

from django.contrib.auth.models import User
from django.test import TestCase

from core.models import (
    Album,
    AlbumArtist,
    Artist,
    ChangeRequest,
    Song,
    SongAlbum,
    SongArtist,
    UserProfile,
)


class ArtistModelTest(TestCase):
    """Tests for the Artist model."""

    def setUp(self):
        """Create test data."""
        self.artist = Artist.objects.create(
            name="Test Artist",
            bio="A test artist for testing",
            image_url="https://example.com/artist.jpg",
        )

    def test_artist_creation(self):
        """Test that an artist can be created."""
        self.assertEqual(self.artist.name, "Test Artist")
        self.assertEqual(self.artist.bio, "A test artist for testing")
        self.assertEqual(self.artist.image_url, "https://example.com/artist.jpg")

    def test_artist_str_representation(self):
        """Test string representation of artist."""
        self.assertEqual(str(self.artist), "Test Artist")

    def test_artist_song_count_property(self):
        """Test song_count property."""
        # Initially should be 0
        self.assertEqual(self.artist.song_count, 0)

        # Create a song and add artist
        song = Song.objects.create(
            title="Test Song",
            duration=180,
            file_hash="a" * 64,  # SHA-256 hash
        )
        SongArtist.objects.create(song=song, artist=self.artist, role="main")

        # Should now be 1
        self.assertEqual(self.artist.song_count, 1)

    def test_artist_album_count_property(self):
        """Test album_count property."""
        # Initially should be 0
        self.assertEqual(self.artist.album_count, 0)

        # Create an album and add artist
        album = Album.objects.create(title="Test Album")
        AlbumArtist.objects.create(album=album, artist=self.artist)

        # Should now be 1
        self.assertEqual(self.artist.album_count, 1)

    def test_artist_unique_name(self):
        """Test that artist names must be unique."""
        with self.assertRaises(Exception):  # IntegrityError
            Artist.objects.create(name="Test Artist")

    def test_artist_ordering(self):
        """Test that artists are ordered by name."""
        Artist.objects.create(name="Alpha Artist")
        Artist.objects.create(name="Zeta Artist")

        artists = list(Artist.objects.all())
        # Should be ordered: Alpha, Test, Zeta
        self.assertEqual(artists[0].name, "Alpha Artist")
        self.assertEqual(artists[1].name, "Test Artist")
        self.assertEqual(artists[2].name, "Zeta Artist")


class AlbumModelTest(TestCase):
    """Tests for the Album model."""

    def setUp(self):
        """Create test data."""
        self.artist = Artist.objects.create(name="Test Artist")
        self.album = Album.objects.create(
            title="Test Album",
            album_type="album",
            release_date="2023-01-01",
            cover_url="https://example.com/cover.jpg",
            description="A test album",
        )
        AlbumArtist.objects.create(album=self.album, artist=self.artist)

    def test_album_creation(self):
        """Test that an album can be created."""
        self.assertEqual(self.album.title, "Test Album")
        self.assertEqual(self.album.album_type, "album")
        self.assertEqual(self.album.description, "A test album")

    def test_album_str_representation(self):
        """Test string representation of album."""
        self.assertEqual(str(self.album), "Test Album")

    def test_album_song_count_property(self):
        """Test song_count property."""
        # Initially should be 0
        self.assertEqual(self.album.song_count, 0)

        # Create a song and add to album
        song = Song.objects.create(
            title="Test Song",
            duration=180,
            file_hash="b" * 64,
        )
        SongAlbum.objects.create(song=song, album=self.album, track_number=1)

        # Should now be 1
        self.assertEqual(self.album.song_count, 1)

    def test_album_type_choices(self):
        """Test album type choices."""
        album_types = ["album", "ep", "single", "compilation", "soundtrack"]

        for album_type in album_types:
            album = Album.objects.create(
                title=f"Test {album_type}",
                album_type=album_type,
            )
            self.assertEqual(album.album_type, album_type)
            album.delete()

    def test_album_artist_relationship(self):
        """Test that albums can have multiple artists."""
        artist2 = Artist.objects.create(name="Test Artist 2")
        AlbumArtist.objects.create(album=self.album, artist=artist2)

        # Album should have 2 artists
        self.assertEqual(self.album.artists.count(), 2)
        self.assertIn(self.artist, self.album.artists.all())
        self.assertIn(artist2, self.album.artists.all())

    def test_album_ordering(self):
        """Test that albums are ordered by release date (descending) and title."""
        Album.objects.create(title="Alpha Album", release_date="2023-01-01")
        Album.objects.create(title="Beta Album", release_date="2023-02-01")

        albums = list(Album.objects.all())
        # Should be ordered by release_date descending
        # Beta (Feb) should come before Alpha (Jan)
        # Test Album (Jan) should come after Beta but before Alpha
        self.assertEqual(albums[0].title, "Beta Album")


class SongModelTest(TestCase):
    """Tests for the Song model."""

    def setUp(self):
        """Create test data."""
        self.artist = Artist.objects.create(name="Test Artist")
        self.album = Album.objects.create(title="Test Album")
        self.song = Song.objects.create(
            title="Test Song",
            duration=240,
            file_hash="c" * 64,
            lyrics="Test lyrics\nLine 2\nLine 3",
            artwork_url="https://example.com/artwork.jpg",
        )
        SongArtist.objects.create(song=self.song, artist=self.artist, role="main")
        SongAlbum.objects.create(song=self.song, album=self.album, track_number=1)

    def test_song_creation(self):
        """Test that a song can be created."""
        self.assertEqual(self.song.title, "Test Song")
        self.assertEqual(self.song.duration, 240)
        self.assertEqual(self.song.file_hash, "c" * 64)
        self.assertEqual(self.song.lyrics, "Test lyrics\nLine 2\nLine 3")

    def test_song_str_representation(self):
        """Test string representation of song."""
        self.assertEqual(str(self.song), "Test Song")

    def test_song_formatted_duration(self):
        """Test formatted_duration property."""
        # 240 seconds = 4:00
        self.assertEqual(self.song.formatted_duration, "4:00")

        # Test other durations
        song2 = Song.objects.create(
            title="Short Song",
            duration=30,
            file_hash="d" * 64,
        )
        self.assertEqual(song2.formatted_duration, "0:30")

        song3 = Song.objects.create(
            title="Long Song",
            duration=3661,
            file_hash="e" * 64,
        )
        self.assertEqual(song3.formatted_duration, "61:01")

    def test_song_artist_relationship(self):
        """Test that songs can have multiple artists."""
        artist2 = Artist.objects.create(name="Featured Artist")
        SongArtist.objects.create(song=self.song, artist=artist2, role="featured")

        # Song should have 2 artists
        self.assertEqual(self.song.artists.count(), 2)
        self.assertIn(self.artist, self.song.artists.all())
        self.assertIn(artist2, self.song.artists.all())

    def test_song_album_relationship(self):
        """Test that songs can be in multiple albums."""
        album2 = Album.objects.create(title="Second Album")
        SongAlbum.objects.create(song=self.song, album=album2, track_number=5)

        # Song should be in 2 albums
        self.assertEqual(self.song.albums.count(), 2)
        self.assertIn(self.album, self.song.albums.all())
        self.assertIn(album2, self.song.albums.all())

    def test_song_unique_file_hash(self):
        """Test that file_hash must be unique."""
        with self.assertRaises(Exception):  # IntegrityError
            Song.objects.create(
                title="Duplicate Hash Song",
                duration=180,
                file_hash="c" * 64,  # Same hash as setUp song
            )

    def test_song_ordering(self):
        """Test that songs are ordered by title."""
        Song.objects.create(title="Alpha Song", duration=180, file_hash="f" * 64)
        Song.objects.create(title="Zeta Song", duration=180, file_hash="g" * 64)

        songs = list(Song.objects.all())
        # Should be ordered: Alpha, Test, Zeta
        self.assertEqual(songs[0].title, "Alpha Song")
        self.assertEqual(songs[1].title, "Test Song")
        self.assertEqual(songs[2].title, "Zeta Song")


class SongArtistModelTest(TestCase):
    """Tests for the SongArtist relationship model."""

    def setUp(self):
        """Create test data."""
        self.artist = Artist.objects.create(name="Test Artist")
        self.song = Song.objects.create(
            title="Test Song",
            duration=180,
            file_hash="h" * 64,
        )

    def test_song_artist_creation(self):
        """Test that a SongArtist can be created."""
        song_artist = SongArtist.objects.create(
            song=self.song,
            artist=self.artist,
            role="main",
        )
        self.assertEqual(song_artist.role, "main")
        self.assertEqual(str(song_artist), "Test Artist (Main Artist) - Test Song")

    def test_song_artist_role_choices(self):
        """Test SongArtist role choices."""
        roles = ["main", "featured", "producer", "writer", "composer"]

        for role in roles:
            song = Song.objects.create(
                title=f"Test Song {role}",
                duration=180,
                file_hash=role[0] * 64,
            )
            song_artist = SongArtist.objects.create(
                song=song,
                artist=self.artist,
                role=role,
            )
            self.assertEqual(song_artist.role, role)

    def test_song_artist_unique_constraint(self):
        """Test that song-artist-role combination must be unique."""
        SongArtist.objects.create(
            song=self.song,
            artist=self.artist,
            role="main",
        )

        # Should fail because same song, artist, and role
        with self.assertRaises(Exception):  # IntegrityError
            SongArtist.objects.create(
                song=self.song,
                artist=self.artist,
                role="main",
            )


class SongAlbumModelTest(TestCase):
    """Tests for the SongAlbum relationship model."""

    def setUp(self):
        """Create test data."""
        self.album = Album.objects.create(title="Test Album")
        self.song = Song.objects.create(
            title="Test Song",
            duration=180,
            file_hash="i" * 64,
        )

    def test_song_album_creation(self):
        """Test that a SongAlbum can be created."""
        song_album = SongAlbum.objects.create(
            song=self.song,
            album=self.album,
            track_number=1,
        )
        self.assertEqual(song_album.track_number, 1)
        self.assertEqual(str(song_album), "Test Song on Test Album")

    def test_song_album_unique_constraint(self):
        """Test that song-album combination must be unique."""
        SongAlbum.objects.create(
            song=self.song,
            album=self.album,
            track_number=1,
        )

        # Should fail because same song and album
        with self.assertRaises(Exception):  # IntegrityError
            SongAlbum.objects.create(
                song=self.song,
                album=self.album,
                track_number=2,
            )


class AlbumArtistModelTest(TestCase):
    """Tests for the AlbumArtist relationship model."""

    def setUp(self):
        """Create test data."""
        self.artist = Artist.objects.create(name="Test Artist")
        self.album = Album.objects.create(title="Test Album")

    def test_album_artist_creation(self):
        """Test that an AlbumArtist can be created."""
        album_artist = AlbumArtist.objects.create(
            album=self.album,
            artist=self.artist,
        )
        self.assertEqual(str(album_artist), "Test Artist - Test Album")

    def test_album_artist_unique_constraint(self):
        """Test that album-artist combination must be unique."""
        AlbumArtist.objects.create(
            album=self.album,
            artist=self.artist,
        )

        # Should fail because same album and artist
        with self.assertRaises(Exception):  # IntegrityError
            AlbumArtist.objects.create(
                album=self.album,
                artist=self.artist,
            )


class UserProfileModelTest(TestCase):
    """Tests for the UserProfile model."""

    def setUp(self):
        """Create test data."""
        self.user = User.objects.create_user(
            username="testuser",
            email="test@example.com",
            password="testpass123",
        )
        self.profile = self.user.userprofile

    def test_profile_creation(self):
        """Test that a profile is created automatically."""
        self.assertEqual(self.profile.user, self.user)
        self.assertEqual(self.profile.role, "general")

    def test_profile_str_representation(self):
        """Test string representation of profile."""
        self.assertEqual(str(self.profile), "testuser (General User)")

    def test_profile_role_choices(self):
        """Test profile role choices."""
        roles = ["general", "moderator", "owner"]

        for role in roles:
            user = User.objects.create_user(
                username=f"testuser_{role}",
                email=f"{role}@example.com",
                password="testpass123",
            )
            user.userprofile.role = role
            user.userprofile.save()
            self.assertEqual(user.userprofile.role, role)

    def test_can_moderate_property(self):
        """Test can_moderate property."""
        # General user should not be able to moderate
        self.profile.role = "general"
        self.profile.save()
        self.assertFalse(self.profile.can_moderate)

        # Moderator should be able to moderate
        self.profile.role = "moderator"
        self.profile.save()
        self.assertTrue(self.profile.can_moderate)

        # Owner should be able to moderate
        self.profile.role = "owner"
        self.profile.save()
        self.assertTrue(self.profile.can_moderate)


class ChangeRequestModelTest(TestCase):
    """Tests for the ChangeRequest model."""

    def setUp(self):
        """Create test data."""
        self.user = User.objects.create_user(
            username="testuser",
            email="test@example.com",
            password="testpass123",
        )
        self.song = Song.objects.create(
            title="Test Song",
            duration=180,
            file_hash="j" * 64,
        )

    def test_change_request_creation(self):
        """Test that a change request can be created."""
        request = ChangeRequest.objects.create(
            user=self.user,
            model_type="song",
            model_id=self.song.id,
            field_name="title",
            old_value="Test Song",
            new_value="Updated Song",
            status="pending",
        )
        self.assertEqual(request.status, "pending")
        self.assertEqual(request.field_name, "title")

    def test_change_request_str_representation(self):
        """Test string representation of change request."""
        request = ChangeRequest.objects.create(
            user=self.user,
            model_type="song",
            model_id=self.song.id,
            field_name="title",
            old_value="Test Song",
            new_value="Updated Song",
        )
        expected = f"ChangeRequest #{request.id}: Song {self.song.id}.title"
        self.assertEqual(str(request), expected)

    def test_get_target_object(self):
        """Test get_target_object method."""
        request = ChangeRequest.objects.create(
            user=self.user,
            model_type="song",
            model_id=self.song.id,
            field_name="title",
            old_value="Test Song",
            new_value="Updated Song",
        )

        # Should return the song object
        target = request.get_target_object()
        self.assertEqual(target, self.song)

    def test_change_request_ordering(self):
        """Test that change requests are ordered by created_at descending."""
        request1 = ChangeRequest.objects.create(
            user=self.user,
            model_type="song",
            model_id=self.song.id,
            field_name="title",
            old_value="Test Song",
            new_value="Updated Song 1",
        )

        # Create another request later
        request2 = ChangeRequest.objects.create(
            user=self.user,
            model_type="song",
            model_id=self.song.id,
            field_name="duration",
            old_value="180",
            new_value="200",
        )

        # Most recent should be first
        requests = list(ChangeRequest.objects.all())
        self.assertEqual(requests[0], request2)
        self.assertEqual(requests[1], request1)

    def test_change_request_status_choices(self):
        """Test change request status choices."""
        statuses = ["pending", "approved", "rejected"]

        for status in statuses:
            request = ChangeRequest.objects.create(
                user=self.user,
                model_type="song",
                model_id=self.song.id,
                field_name="title",
                old_value="Test",
                new_value=f"Test {status}",
                status=status,
            )
            self.assertEqual(request.status, status)


class ModelIntegrationTest(TestCase):
    """Integration tests for model relationships."""

    def setUp(self):
        """Create test data."""
        # Create artists
        self.artist1 = Artist.objects.create(name="Artist 1")
        self.artist2 = Artist.objects.create(name="Artist 2")

        # Create album
        self.album = Album.objects.create(
            title="Test Album",
            album_type="album",
        )
        AlbumArtist.objects.create(album=self.album, artist=self.artist1)

        # Create songs
        self.song1 = Song.objects.create(
            title="Song 1",
            duration=180,
            file_hash="k" * 64,
        )
        self.song2 = Song.objects.create(
            title="Song 2",
            duration=240,
            file_hash="l" * 64,
        )

        # Add artists to songs
        SongArtist.objects.create(song=self.song1, artist=self.artist1, role="main")
        SongArtist.objects.create(song=self.song2, artist=self.artist1, role="main")
        SongArtist.objects.create(song=self.song2, artist=self.artist2, role="featured")

        # Add songs to album
        SongAlbum.objects.create(song=self.song1, album=self.album, track_number=1)
        SongAlbum.objects.create(song=self.song2, album=self.album, track_number=2)

    def test_artist_songs_relationship(self):
        """Test artist-songs many-to-many relationship."""
        # Artist 1 should have 2 songs
        self.assertEqual(self.artist1.songs.count(), 2)
        self.assertIn(self.song1, self.artist1.songs.all())
        self.assertIn(self.song2, self.artist1.songs.all())

        # Artist 2 should have 1 song (featured)
        self.assertEqual(self.artist2.songs.count(), 1)
        self.assertIn(self.song2, self.artist2.songs.all())

    def test_artist_albums_relationship(self):
        """Test artist-albums many-to-many relationship."""
        self.assertEqual(self.artist1.albums.count(), 1)
        self.assertIn(self.album, self.artist1.albums.all())

    def test_album_songs_relationship(self):
        """Test album-songs many-to-many relationship."""
        self.assertEqual(self.album.songs.count(), 2)
        self.assertIn(self.song1, self.album.songs.all())
        self.assertIn(self.song2, self.album.songs.all())

    def test_song_artists_relationship(self):
        """Test song-artists many-to-many relationship."""
        self.assertEqual(self.song1.artists.count(), 1)
        self.assertIn(self.artist1, self.song1.artists.all())

        self.assertEqual(self.song2.artists.count(), 2)
        self.assertIn(self.artist1, self.song2.artists.all())
        self.assertIn(self.artist2, self.song2.artists.all())

    def test_cascade_delete_artist(self):
        """Test that deleting artist doesn't delete songs."""
        song_id = self.song1.id
        self.artist1.delete()

        # Song should still exist
        self.assertTrue(Song.objects.filter(id=song_id).exists())

        # But song-artist relationship should be gone
        self.assertEqual(self.song1.artists.count(), 0)

    def test_cascade_delete_album(self):
        """Test that deleting album doesn't delete songs."""
        song_id = self.song1.id
        self.album.delete()

        # Song should still exist
        self.assertTrue(Song.objects.filter(id=song_id).exists())

        # But song-album relationship should be gone
        self.assertEqual(self.song1.albums.count(), 0)

    def test_cascade_delete_song(self):
        """Test that deleting song cascades properly."""
        song_id = self.song1.id
        self.song1.delete()

        # Song should be gone
        self.assertFalse(Song.objects.filter(id=song_id).exists())

        # Relationships should be gone
        self.assertEqual(SongArtist.objects.filter(song_id=song_id).count(), 0)
        self.assertEqual(SongAlbum.objects.filter(song_id=song_id).count(), 0)

        # Artist and album should still exist
        self.assertTrue(Artist.objects.filter(id=self.artist1.id).exists())
        self.assertTrue(Album.objects.filter(id=self.album.id).exists())
