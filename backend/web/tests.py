"""
Tests for web views.
Tests the moderation system, role-based access control, and change request workflow.
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
)
from django.contrib.auth.models import User
from django.test import Client, TestCase
from django.urls import reverse


class HomeViewTest(TestCase):
    """Tests for the home page view."""

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
        # Create test data
        artist = Artist.objects.create(name="Test Artist")
        album = Album.objects.create(title="Test Album")
        song = Song.objects.create(title="Test Song", duration=180, file_hash="a" * 64)

        response = self.client.get(reverse("web:home"))
        self.assertIn("song_count", response.context)
        self.assertIn("album_count", response.context)
        self.assertIn("artist_count", response.context)


class DashboardViewTest(TestCase):
    """Tests for the dashboard view."""

    def setUp(self):
        """Create test user."""
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )

    def test_dashboard_view_requires_login(self):
        """Test that dashboard requires authentication."""
        response = self.client.get(reverse("web:dashboard"))
        self.assertNotEqual(response.status_code, 200)

    def test_dashboard_view_status_code(self):
        """Test that dashboard returns 200 for authenticated user."""
        self.client.login(username="testuser", password="testpass123")
        response = self.client.get(reverse("web:dashboard"))
        self.assertEqual(response.status_code, 200)

    def test_dashboard_view_template(self):
        """Test that dashboard uses correct template."""
        self.client.login(username="testuser", password="testpass123")
        response = self.client.get(reverse("web:dashboard"))
        self.assertTemplateUsed(response, "web/dashboard.html")

    def test_dashboard_view_context(self):
        """Test that dashboard has correct context."""
        self.client.login(username="testuser", password="testpass123")
        response = self.client.get(reverse("web:dashboard"))
        self.assertIn("user_profile", response.context)


class ChangeRequestListViewTest(TestCase):
    """Tests for the change request list view."""

    def setUp(self):
        """Create test data."""
        # Create users with different roles
        self.general_user = User.objects.create_user(
            username="general", email="general@example.com", password="testpass123"
        )
        self.general_profile = self.general_user.userprofile
        self.general_profile.role = "general"
        self.general_profile.save()

        self.moderator_user = User.objects.create_user(
            username="moderator",
            email="moderator@example.com",
            password="testpass123",
        )
        self.moderator_profile = self.moderator_user.userprofile
        self.moderator_profile.role = "moderator"
        self.moderator_profile.save()

        self.owner_user = User.objects.create_user(
            username="owner", email="owner@example.com", password="testpass123"
        )
        self.owner_profile = self.owner_user.userprofile
        self.owner_profile.role = "owner"
        self.owner_profile.save()

        # Create test objects
        self.artist = Artist.objects.create(name="Test Artist")
        self.album = Album.objects.create(title="Test Album")
        self.song = Song.objects.create(
            title="Test Song", duration=180, file_hash="a" * 64
        )

        # Create change requests
        self.pending_request = ChangeRequest.objects.create(
            user=self.general_user,
            model_type="artist",
            model_id=self.artist.id,
            field_name="name",
            old_value="Test Artist",
            new_value="Updated Artist",
            status="pending",
        )

        self.approved_request = ChangeRequest.objects.create(
            user=self.general_user,
            model_type="album",
            model_id=self.album.id,
            field_name="title",
            old_value="Test Album",
            new_value="Updated Album",
            status="approved",
            reviewed_by=self.moderator_user,
        )

        self.rejected_request = ChangeRequest.objects.create(
            user=self.moderator_user,
            model_type="song",
            model_id=self.song.id,
            field_name="title",
            old_value="Test Song",
            new_value="Rejected Song",
            status="rejected",
            reviewed_by=self.owner_user,
        )

    def test_change_request_list_requires_login(self):
        """Test that change request list requires authentication."""
        response = self.client.get(reverse("web:change_request_list"))
        self.assertNotEqual(response.status_code, 200)

    def test_change_request_list_view_status_code(self):
        """Test that change request list returns 200 for authenticated user."""
        self.client.login(username="general", password="testpass123")
        response = self.client.get(reverse("web:change_request_list"))
        self.assertEqual(response.status_code, 200)

    def test_change_request_list_view_template(self):
        """Test that change request list uses correct template."""
        self.client.login(username="general", password="testpass123")
        response = self.client.get(reverse("web:change_request_list"))
        self.assertTemplateUsed(response, "web/moderation/change_request_list.html")

    def test_general_user_sees_own_requests(self):
        """Test that general users only see their own requests."""
        self.client.login(username="general", password="testpass123")
        response = self.client.get(reverse("web:change_request_list"))
        change_requests = response.context["change_requests"]

        # General user should see their own requests
        for cr in change_requests:
            self.assertEqual(cr.user, self.general_user)

    def test_moderator_sees_all_requests(self):
        """Test that moderators can see all requests."""
        self.client.login(username="moderator", password="testpass123")
        response = self.client.get(reverse("web:change_request_list"))
        change_requests = response.context["change_requests"]

        # Moderator should see all requests
        self.assertEqual(change_requests.count(), 3)

    def test_owner_sees_all_requests(self):
        """Test that owners can see all requests."""
        self.client.login(username="owner", password="testpass123")
        response = self.client.get(reverse("web:change_request_list"))
        change_requests = response.context["change_requests"]

        # Owner should see all requests
        self.assertEqual(change_requests.count(), 3)

    def test_status_filter(self):
        """Test that status filter works correctly."""
        self.client.login(username="moderator", password="testpass123")

        # Filter by pending status
        response = self.client.get(
            reverse("web:change_request_list") + "?status=pending"
        )
        change_requests = response.context["change_requests"]

        for cr in change_requests:
            self.assertEqual(cr.status, "pending")

    def test_model_type_filter(self):
        """Test that model type filter works correctly."""
        self.client.login(username="moderator", password="testpass123")

        # Filter by artist type
        response = self.client.get(
            reverse("web:change_request_list") + "?model_type=artist"
        )
        change_requests = response.context["change_requests"]

        for cr in change_requests:
            self.assertEqual(cr.model_type, "artist")

    def test_combined_filters(self):
        """Test that combined filters work correctly."""
        self.client.login(username="moderator", password="testpass123")

        # Filter by pending status and song type
        response = self.client.get(
            reverse("web:change_request_list") + "?status=pending&model_type=artist"
        )
        change_requests = response.context["change_requests"]

        for cr in change_requests:
            self.assertEqual(cr.status, "pending")
            self.assertEqual(cr.model_type, "artist")

    def test_change_request_list_view_context(self):
        """Test that change request list has correct context."""
        self.client.login(username="moderator", password="testpass123")
        response = self.client.get(reverse("web:change_request_list"))

        self.assertIn("user_profile", response.context)
        self.assertIn("selected_status", response.context)
        self.assertIn("selected_model", response.context)
        self.assertIn("statuses", response.context)
        self.assertIn("model_types", response.context)

    def test_change_request_list_displays_requests(self):
        """Test that change request list displays requests."""
        self.client.login(username="moderator", password="testpass123")
        response = self.client.get(reverse("web:change_request_list"))

        # Check that requests are in context
        self.assertIn("change_requests", response.context)
        self.assertContains(response, self.pending_request.field_name)
        self.assertContains(response, self.approved_request.field_name)
        self.assertContains(response, self.rejected_request.field_name)


class ChangeRequestReviewViewTest(TestCase):
    """Tests for the change request review view."""

    def setUp(self):
        """Create test data."""
        # Create users with different roles
        self.general_user = User.objects.create_user(
            username="general", email="general@example.com", password="testpass123"
        )
        self.general_profile = self.general_user.userprofile
        self.general_profile.role = "general"
        self.general_profile.save()

        self.moderator_user = User.objects.create_user(
            username="moderator",
            email="moderator@example.com",
            password="testpass123",
        )
        self.moderator_profile = self.moderator_user.userprofile
        self.moderator_profile.role = "moderator"
        self.moderator_profile.save()

        self.owner_user = User.objects.create_user(
            username="owner", email="owner@example.com", password="testpass123"
        )
        self.owner_profile = self.owner_user.userprofile
        self.owner_profile.role = "owner"
        self.owner_profile.save()

        # Create test objects
        self.artist = Artist.objects.create(name="Test Artist")
        self.album = Album.objects.create(title="Test Album")
        self.song = Song.objects.create(
            title="Test Song", duration=180, file_hash="a" * 64
        )

        # Create pending change requests
        self.artist_request = ChangeRequest.objects.create(
            user=self.general_user,
            model_type="artist",
            model_id=self.artist.id,
            field_name="name",
            old_value="Test Artist",
            new_value="Updated Artist Name",
            status="pending",
        )

        self.album_request = ChangeRequest.objects.create(
            user=self.general_user,
            model_type="album",
            model_id=self.album.id,
            field_name="title",
            old_value="Test Album",
            new_value="Updated Album Title",
            status="pending",
        )

        self.song_request = ChangeRequest.objects.create(
            user=self.general_user,
            model_type="song",
            model_id=self.song.id,
            field_name="title",
            old_value="Test Song",
            new_value="Updated Song Title",
            status="pending",
        )

    def test_review_requires_moderator(self):
        """Test that only moderators can review requests."""
        # General user should be denied
        self.client.login(username="general", password="testpass123")
        response = self.client.get(
            reverse("web:change_request_review", kwargs={"pk": self.artist_request.id})
        )
        # Should redirect or show error
        self.assertNotEqual(response.status_code, 200)

    def test_review_view_status_code(self):
        """Test that review view returns 200 for moderator."""
        self.client.login(username="moderator", password="testpass123")
        response = self.client.get(
            reverse("web:change_request_review", kwargs={"pk": self.artist_request.id})
        )
        self.assertEqual(response.status_code, 200)

    def test_review_view_template(self):
        """Test that review view uses correct template."""
        self.client.login(username="moderator", password="testpass123")
        response = self.client.get(
            reverse("web:change_request_review", kwargs={"pk": self.artist_request.id})
        )
        self.assertTemplateUsed(response, "web/moderation/change_request_review.html")

    def test_review_view_context(self):
        """Test that review view has correct context."""
        self.client.login(username="moderator", password="testpass123")
        response = self.client.get(
            reverse("web:change_request_review", kwargs={"pk": self.artist_request.id})
        )
        self.assertIn("change_request", response.context)
        self.assertEqual(response.context["change_request"], self.artist_request)

    def test_approve_artist_change(self):
        """Test approving an artist change request."""
        self.client.login(username="moderator", password="testpass123")

        # Approve the request
        response = self.client.post(
            reverse("web:change_request_review", kwargs={"pk": self.artist_request.id}),
            {"action": "approve", "notes": "Approved by moderator"},
        )

        # Should redirect after approval
        self.assertEqual(response.status_code, 302)

        # Check that the artist was updated
        self.artist.refresh_from_db()
        self.assertEqual(self.artist.name, "Updated Artist Name")

        # Check that the change request was updated
        self.artist_request.refresh_from_db()
        self.assertEqual(self.artist_request.status, "approved")
        self.assertEqual(self.artist_request.reviewed_by, self.moderator_user)
        self.assertEqual(self.artist_request.notes, "Approved by moderator")

    def test_approve_album_change(self):
        """Test approving an album change request."""
        self.client.login(username="moderator", password="testpass123")

        # Approve the request
        response = self.client.post(
            reverse("web:change_request_review", kwargs={"pk": self.album_request.id}),
            {"action": "approve", "notes": "Approved"},
        )

        # Should redirect after approval
        self.assertEqual(response.status_code, 302)

        # Check that the album was updated
        self.album.refresh_from_db()
        self.assertEqual(self.album.title, "Updated Album Title")

        # Check that the change request was updated
        self.album_request.refresh_from_db()
        self.assertEqual(self.album_request.status, "approved")

    def test_approve_song_change(self):
        """Test approving a song change request."""
        self.client.login(username="moderator", password="testpass123")

        # Approve the request
        response = self.client.post(
            reverse("web:change_request_review", kwargs={"pk": self.song_request.id}),
            {"action": "approve", "notes": "Approved"},
        )

        # Should redirect after approval
        self.assertEqual(response.status_code, 302)

        # Check that the song was updated
        self.song.refresh_from_db()
        self.assertEqual(self.song.title, "Updated Song Title")

        # Check that the change request was updated
        self.song_request.refresh_from_db()
        self.assertEqual(self.song_request.status, "approved")

    def test_reject_change_request(self):
        """Test rejecting a change request."""
        self.client.login(username="moderator", password="testpass123")

        # Reject the request
        response = self.client.post(
            reverse("web:change_request_review", kwargs={"pk": self.artist_request.id}),
            {"action": "reject", "notes": "Invalid data"},
        )

        # Should redirect after rejection
        self.assertEqual(response.status_code, 302)

        # Check that the artist was NOT updated
        self.artist.refresh_from_db()
        self.assertEqual(self.artist.name, "Test Artist")

        # Check that the change request was updated
        self.artist_request.refresh_from_db()
        self.assertEqual(self.artist_request.status, "rejected")
        self.assertEqual(self.artist_request.reviewed_by, self.moderator_user)
        self.assertEqual(self.artist_request.notes, "Invalid data")

    def test_owner_can_review(self):
        """Test that owners can also review requests."""
        self.client.login(username="owner", password="testpass123")
        response = self.client.get(
            reverse("web:change_request_review", kwargs={"pk": self.artist_request.id})
        )
        self.assertEqual(response.status_code, 200)

    def test_review_nonexistent_request(self):
        """Test reviewing a nonexistent request returns 404."""
        self.client.login(username="moderator", password="testpass123")
        response = self.client.get(
            reverse("web:change_request_review", kwargs={"pk": 9999})
        )
        self.assertEqual(response.status_code, 404)

    def test_review_already_processed_request(self):
        """Test reviewing an already processed request."""
        # First, approve the request
        self.client.login(username="moderator", password="testpass123")
        self.client.post(
            reverse("web:change_request_review", kwargs={"pk": self.artist_request.id}),
            {"action": "approve", "notes": "First approval"},
        )

        # Try to approve again
        response = self.client.post(
            reverse("web:change_request_review", kwargs={"pk": self.artist_request.id}),
            {"action": "approve", "notes": "Second approval"},
        )

        # Should still work (no restriction on re-reviewing)
        # But this might be something to handle in the future


class UserProfileTest(TestCase):
    """Tests for UserProfile model and role-based access."""

    def setUp(self):
        """Create test users."""
        self.general_user = User.objects.create_user(
            username="general", email="general@example.com", password="testpass123"
        )
        self.moderator_user = User.objects.create_user(
            username="moderator",
            email="moderator@example.com",
            password="testpass123",
        )
        self.owner_user = User.objects.create_user(
            username="owner", email="owner@example.com", password="testpass123"
        )

        # Update profiles
        self.general_user.userprofile.role = "general"
        self.general_user.userprofile.save()

        self.moderator_user.userprofile.role = "moderator"
        self.moderator_user.userprofile.save()

        self.owner_user.userprofile.role = "owner"
        self.owner_user.userprofile.save()

    def test_profile_auto_creation(self):
        """Test that UserProfile is created automatically."""
        new_user = User.objects.create_user(
            username="newuser", email="new@example.com", password="testpass123"
        )
        self.assertTrue(hasattr(new_user, "userprofile"))
        self.assertEqual(new_user.userprofile.role, "general")

    def test_general_user_permissions(self):
        """Test general user permissions."""
        self.assertFalse(self.general_user.userprofile.can_moderate)

    def test_moderator_permissions(self):
        """Test moderator permissions."""
        self.assertTrue(self.moderator_user.userprofile.can_moderate)

    def test_owner_permissions(self):
        """Test owner permissions."""
        self.assertTrue(self.owner_user.userprofile.can_moderate)

    def test_role_choices(self):
        """Test role choices."""
        roles = ["general", "moderator", "owner"]
        for role in roles:
            user = User.objects.create_user(
                username=f"user_{role}",
                email=f"{role}@example.com",
                password="testpass123",
            )
            user.userprofile.role = role
            user.userprofile.save()
            self.assertEqual(user.userprofile.role, role)


class ChangeRequestModelTest(TestCase):
    """Tests for ChangeRequest model methods."""

    def setUp(self):
        """Create test data."""
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )

        self.artist = Artist.objects.create(name="Test Artist")
        self.album = Album.objects.create(title="Test Album")
        self.song = Song.objects.create(
            title="Test Song", duration=180, file_hash="a" * 64
        )

    def test_get_target_object_song(self):
        """Test get_target_object for song."""
        request = ChangeRequest.objects.create(
            user=self.user,
            model_type="song",
            model_id=self.song.id,
            field_name="title",
            old_value="Test Song",
            new_value="Updated Song",
        )
        self.assertEqual(request.get_target_object(), self.song)

    def test_get_target_object_album(self):
        """Test get_target_object for album."""
        request = ChangeRequest.objects.create(
            user=self.user,
            model_type="album",
            model_id=self.album.id,
            field_name="title",
            old_value="Test Album",
            new_value="Updated Album",
        )
        self.assertEqual(request.get_target_object(), self.album)

    def test_get_target_object_artist(self):
        """Test get_target_object for artist."""
        request = ChangeRequest.objects.create(
            user=self.user,
            model_type="artist",
            model_id=self.artist.id,
            field_name="name",
            old_value="Test Artist",
            new_value="Updated Artist",
        )
        self.assertEqual(request.get_target_object(), self.artist)

    def test_get_target_object_nonexistent(self):
        """Test get_target_object for nonexistent object."""
        request = ChangeRequest.objects.create(
            user=self.user,
            model_type="song",
            model_id=9999,
            field_name="title",
            old_value="Old",
            new_value="New",
        )
        self.assertIsNone(request.get_target_object())

    def test_change_request_ordering(self):
        """Test that change requests are ordered by created_at descending."""
        import time

        request1 = ChangeRequest.objects.create(
            user=self.user,
            model_type="artist",
            model_id=self.artist.id,
            field_name="name",
            old_value="Test Artist",
            new_value="Update 1",
        )

        time.sleep(0.01)  # Small delay to ensure different timestamps

        request2 = ChangeRequest.objects.create(
            user=self.user,
            model_type="artist",
            model_id=self.artist.id,
            field_name="name",
            old_value="Test Artist",
            new_value="Update 2",
        )

        requests = list(ChangeRequest.objects.all())
        self.assertEqual(requests[0], request2)
        self.assertEqual(requests[1], request1)
