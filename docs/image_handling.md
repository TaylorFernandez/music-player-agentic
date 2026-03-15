# Image Handling with Pillow

## Overview

This document explains how to set up and use Pillow for image handling in the Music Player application. Pillow is the Python Imaging Library (PIL) fork that provides image processing capabilities.

## Why Pillow?

The Music Player application needs to handle image uploads for:
- Album artwork (cover images)
- Artist profile images
- User avatars
- Song artwork

Instead of storing only URLs to external images, we can now upload and process images directly.

## Installation

### Prerequisites

Pillow requires system-level image libraries. Install them first:

#### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install -y \
    libjpeg-dev \
    zlib1g-dev \
    libpng-dev \
    libtiff5-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libwebp-dev
```

#### Fedora/RHEL/CentOS

```bash
sudo dnf install -y \
    libjpeg-devel \
    zlib-devel \
    libpng-devel \
    libtiff-devel \
    freetype-devel \
    lcms2-devel \
    libwebp-devel
```

#### macOS (using Homebrew)

```bash
brew install \
    libjpeg \
    zlib \
    libpng \
    libtiff \
    freetype \
    little-cms \
    webp
```

### Python Package

#### Development

```bash
cd backend
source venv/bin/activate
pip install Pillow==11.0.0
```

#### Production

```bash
pip install -r requirements-prod.txt
```

Pillow is already included in `requirements-prod.txt`.

### Verify Installation

```bash
python -c "from PIL import Image; print('Pillow version:', Image.__version__)"
```

## Django Configuration

### Settings

Update `backend/musicplayer/settings.py`:

```python
# Media files (User uploads)
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# File upload settings
FILE_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024  # 10 MB
DATA_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024  # 10 MB

# Image upload settings
MAX_IMAGE_SIZE = (1920, 1920)  # Max dimensions
THUMBNAIL_SIZE = (300, 300)
IMAGE_QUALITY = 85
```

For production (`backend/musicplayer/settings_prod.py`):

```python
# Use different storage backend for production
DEFAULT_FILE_STORAGE = 'django.core.files.storage.FileSystemStorage'

# Or use cloud storage (S3, Azure, etc.)
# DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'

# Media files served by web server
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
```

### URL Configuration

Add media URL to `backend/musicplayer/urls.py`:

```python
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    # ... your URL patterns here
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(
        settings.MEDIA_URL,
        document_root=settings.MEDIA_ROOT
    )
```

## Model Updates

### Updated Models

Update `backend/core/models.py` to use `ImageField`:

```python
from django.db import models
from PIL import Image
import os

def artwork_upload_path(instance, filename):
    """Generate upload path for album artwork."""
    return f'artwork/{instance.__class__.__name__.lower()}/{filename}'

def artist_image_upload_path(instance, filename):
    """Generate upload path for artist images."""
    return f'artists/{instance.id}/{filename}'

def user_avatar_upload_path(instance, filename):
    """Generate upload path for user avatars."""
    return f'avatars/{instance.user.id}/{filename}'


class Artist(models.Model):
    """Represents a music artist or group."""
    
    name = models.CharField(max_length=255, unique=True)
    image = models.ImageField(
        upload_to=artist_image_upload_path,
        blank=True,
        null=True,
        help_text="Artist profile image"
    )
    image_url = models.URLField(max_length=500, blank=True, null=True)
    bio = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        """Override save to process image."""
        super().save(*args, **kwargs)
        
        if self.image:
            # Resize image
            img = Image.open(self.image.path)
            if img.height > 1920 or img.width > 1920:
                output_size = (1920, 1920)
                img.thumbnail(output_size)
                img.save(self.image.path, quality=85)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class Album(models.Model):
    """Represents a music album, EP, or single."""
    
    ALBUM_TYPE_CHOICES = [
        ('album', 'Album'),
        ('ep', 'EP'),
        ('single', 'Single'),
        ('compilation', 'Compilation'),
        ('soundtrack', 'Soundtrack'),
    ]

    title = models.CharField(max_length=255)
    album_type = models.CharField(
        max_length=20, 
        choices=ALBUM_TYPE_CHOICES, 
        default='album'
    )
    release_date = models.DateField(blank=True, null=True)
    cover = models.ImageField(
        upload_to=artwork_upload_path,
        blank=True,
        null=True,
        help_text="Album cover artwork"
    )
    cover_url = models.URLField(max_length=500, blank=True, null=True)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    artists = models.ManyToManyField('Artist', through='AlbumArtist')

    def save(self, *args, **kwargs):
        """Override save to process cover image."""
        super().save(*args, **kwargs)
        
        if self.cover:
            # Resize image
            img = Image.open(self.cover.path)
            if img.height > 1920 or img.width > 1920:
                output_size = (1920, 1920)
                img.thumbnail(output_size)
                img.save(self.cover.path, quality=85)

    class Meta:
        ordering = ["-release_date", "title"]

    def __str__(self):
        return self.title


class Song(models.Model):
    """Represents a single audio track."""
    
    title = models.CharField(max_length=255)
    duration = models.IntegerField(help_text="Duration in seconds")
    file_hash = models.CharField(
        max_length=64,
        unique=True,
        help_text="SHA-256 hash of audio file for deduplication"
    )
    lyrics = models.TextField(blank=True)
    artwork = models.ImageField(
        upload_to=artwork_upload_path,
        blank=True,
        null=True,
        help_text="Song artwork"
    )
    artwork_url = models.URLField(max_length=500, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    albums = models.ManyToManyField('Album', through='SongAlbum')
    artists = models.ManyToManyField('Artist', through='SongArtist')

    def save(self, *args, **kwargs):
        """Override save to process artwork."""
        super().save(*args, **kwargs)
        
        if self.artwork:
            # Resize image
            img = Image.open(self.artwork.path)
            if img.height > 1920 or img.width > 1920:
                output_size = (1920, 1920)
                img.thumbnail(output_size)
                img.save(self.artwork.path, quality=85)

    class Meta:
        ordering = ["title"]

    def __str__(self):
        return self.title


class UserProfile(models.Model):
    """Extends the built-in User model with role information."""
    
    ROLE_CHOICES = [
        ('general', 'General User'),
        ('moderator', 'Moderator'),
        ('owner', 'Owner'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='general')
    avatar = models.ImageField(
        upload_to=user_avatar_upload_path,
        blank=True,
        null=True,
        help_text="User avatar image"
    )
    avatar_url = models.URLField(max_length=500, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        """Override save to process avatar."""
        super().save(*args, **kwargs)
        
        if self.avatar:
            # Resize to square thumbnail
            img = Image.open(self.avatar.path)
            if img.height > 300 or img.width > 300:
                output_size = (300, 300)
                img.thumbnail(output_size)
                img.save(self.avatar.path, quality=85)

    class Meta:
        indexes = [
            models.Index(fields=["role"]),
        ]

    def __str__(self):
        return f"{self.user.username} ({self.get_role_display()})"
```

## Image Processing Utilities

Create `backend/core/utils.py`:

```python
"""
Image processing utilities for the Music Player application.
"""
import os
from io import BytesIO
from PIL import Image
from django.core.files.uploadedfile import InMemoryUploadedFile
from django.conf import settings


def process_image(image_file, max_size=(1920, 1920), quality=85):
    """
    Process uploaded image: resize and optimize.
    
    Args:
        image_file: Uploaded image file
        max_size: Maximum dimensions (width, height)
        quality: JPEG quality (1-100)
    
    Returns:
        Processed image file
    """
    try:
        # Open image
        img = Image.open(image_file)
        
        # Convert to RGB if necessary
        if img.mode in ('RGBA', 'LA', 'P'):
            background = Image.new('RGB', img.size, (255, 255, 255))
            if img.mode == 'P':
                img = img.convert('RGBA')
            background.paste(img, mask=img.split()[-1] if img.mode in ('RGBA', 'LA') else None)
            img = background
        
        # Resize if necessary
        if img.height > max_size[1] or img.width > max_size[0]:
            img.thumbnail(max_size, Image.Resampling.LANCZOS)
        
        # Save to BytesIO
        output = BytesIO()
        img.save(output, format='JPEG', quality=quality, optimize=True)
        output.seek(0)
        
        # Create new InMemoryUploadedFile
        return InMemoryUploadedFile(
            output,
            'ImageField',
            os.path.splitext(image_file.name)[0] + '.jpg',
            'image/jpeg',
            output.getbuffer().nbytes,
            None
        )
    except Exception as e:
        raise ValueError(f"Error processing image: {e}")


def create_thumbnail(image_file, size=(300, 300)):
    """
    Create a square thumbnail from image.
    
    Args:
        image_file: Original image file
        size: Thumbnail size (width, height)
    
    Returns:
        Thumbnail image file
    """
    try:
        img = Image.open(image_file)
        
        # Convert to RGB
        if img.mode in ('RGBA', 'LA', 'P'):
            background = Image.new('RGB', img.size, (255, 255, 255))
            if img.mode == 'P':
                img = img.convert('RGBA')
            background.paste(img, mask=img.split()[-1] if img.mode in ('RGBA', 'LA') else None)
            img = background
        
        # Create square thumbnail
        # First, crop to square
        width, height = img.size
        if width != height:
            # Crop to center square
            size = min(width, height)
            left = (width - size) // 2
            top = (height - size) // 2
            right = left + size
            bottom = top + size
            img = img.crop((left, top, right, bottom))
        
        # Resize
        img.thumbnail(size, Image.Resampling.LANCZOS)
        
        # Save to BytesIO
        output = BytesIO()
        img.save(output, format='JPEG', quality=85, optimize=True)
        output.seek(0)
        
        return InMemoryUploadedFile(
            output,
            'ImageField',
            os.path.splitext(image_file.name)[0] + '_thumb.jpg',
            'image/jpeg',
            output.getbuffer().nbytes,
            None
        )
    except Exception as e:
        raise ValueError(f"Error creating thumbnail: {e}")


def validate_image(image_file, max_size_mb=10):
    """
    Validate uploaded image file.
    
    Args:
        image_file: Uploaded file
        max_size_mb: Maximum file size in MB
    
    Returns:
        True if valid, raises ValueError if not
    """
    # Check file size
    if image_file.size > max_size_mb * 1024 * 1024:
        raise ValueError(f"File size must be less than {max_size_mb} MB")
    
    # Check file type
    valid_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp']
    ext = os.path.splitext(image_file.name)[1].lower()
    if ext not in valid_extensions:
        raise ValueError(f"File must be an image (valid extensions: {', '.join(valid_extensions)})")
    
    # Check if it's actually an image
    try:
        img = Image.open(image_file)
        img.verify()  # Verify it's an image
        image_file.seek(0)  # Reset file pointer
    except Exception:
        raise ValueError("File is not a valid image")
    
    return True


def get_image_dimensions(image_file):
    """
    Get dimensions of an image file.
    
    Args:
        image_file: Image file
    
    Returns:
        Tuple of (width, height)
    """
    try:
        img = Image.open(image_file)
        return img.size
    except Exception:
        return (0, 0)


def optimize_image(image_file, quality=85):
    """
    Optimize image for web display.
    
    Args:
        image_file: Image file
        quality: JPEG quality (1-100)
    
    Returns:
        Optimized image file
    """
    try:
        img = Image.open(image_file)
        
        # Convert to RGB
        if img.mode in ('RGBA', 'LA', 'P'):
            background = Image.new('RGB', img.size, (255, 255, 255))
            if img.mode == 'P':
                img = img.convert('RGBA')
            background.paste(img, mask=img.split()[-1] if img.mode in ('RGBA', 'LA') else None)
            img = background
        
        # Save optimized
        output = BytesIO()
        img.save(output, format='JPEG', quality=quality, optimize=True, progressive=True)
        output.seek(0)
        
        return InMemoryUploadedFile(
            output,
            'ImageField',
            os.path.splitext(image_file.name)[0] + '.jpg',
            'image/jpeg',
            output.getbuffer().nbytes,
            None
        )
    except Exception as e:
        raise ValueError(f"Error optimizing image: {e}")
```

## Forms

Create `backend/core/forms.py`:

```python
"""
Forms for handling image uploads.
"""
from django import forms
from .models import Artist, Album, Song, UserProfile
from .utils import validate_image


class ArtistForm(forms.ModelForm):
    """Form for creating/editing artists with image upload."""
    
    class Meta:
        model = Artist
        fields = ['name', 'image', 'bio']
    
    def clean_image(self):
        """Validate uploaded image."""
        image = self.cleaned_data.get('image')
        if image:
            validate_image(image, max_size_mb=5)
        return image


class AlbumForm(forms.ModelForm):
    """Form for creating/editing albums with cover upload."""
    
    class Meta:
        model = Album
        fields = ['title', 'album_type', 'release_date', 'cover', 'description']
        widgets = {
            'release_date': forms.DateInput(attrs={'type': 'date'}),
        }
    
    def clean_cover(self):
        """Validate uploaded cover image."""
        cover = self.cleaned_data.get('cover')
        if cover:
            validate_image(cover, max_size_mb=10)
        return cover


class SongForm(forms.ModelForm):
    """Form for creating/editing songs with artwork upload."""
    
    class Meta:
        model = Song
        fields = ['title', 'duration', 'artwork', 'lyrics', 'file_hash']
    
    def clean_artwork(self):
        """Validate uploaded artwork."""
        artwork = self.cleaned_data.get('artwork')
        if artwork:
            validate_image(artwork, max_size_mb=10)
        return artwork


class UserProfileForm(forms.ModelForm):
    """Form for editing user profile with avatar upload."""
    
    class Meta:
        model = UserProfile
        fields = ['avatar', 'role']
    
    def clean_avatar(self):
        """Validate uploaded avatar."""
        avatar = self.cleaned_data.get('avatar')
        if avatar:
            validate_image(avatar, max_size_mb=2)
        return avatar
```

## Views

Update views to handle image uploads:

```python
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib import messages
from .forms import ArtistForm, AlbumForm, SongForm
from .models import Artist, Album, Song


def artist_create(request):
    """Create a new artist with image upload."""
    if request.method == 'POST':
        form = ArtistForm(request.POST, request.FILES)
        if form.is_valid():
            artist = form.save(commit=False)
            # Image is automatically saved by ImageField
            artist.save()
            messages.success(request, f'Artist "{artist.name}" created successfully!')
            return redirect('web:artist_detail', pk=artist.id)
    else:
        form = ArtistForm()
    
    return render(request, 'web/artists/artist_form.html', {'form': form})


def artist_edit(request, pk):
    """Edit an existing artist."""
    artist = get_object_or_404(Artist, pk=pk)
    
    if request.method == 'POST':
        form = ArtistForm(request.POST, request.FILES, instance=artist)
        if form.is_valid():
            # Delete old image if new one uploaded
            if 'image' in request.FILES and artist.image:
                artist.image.delete(save=False)
            artist = form.save()
            messages.success(request, f'Artist "{artist.name}" updated successfully!')
            return redirect('web:artist_detail', pk=artist.id)
    else:
        form = ArtistForm(instance=artist)
    
    return render(request, 'web/artists/artist_edit.html', {'form': form, 'artist': artist})


# Similar views for Album and Song...
```

## Migration

Create and run migrations:

```bash
cd backend
source venv/bin/activate

# Create migrations
python manage.py makemigrations core

# Apply migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic
```

## Testing Image Uploads

### Manual Testing

1. Start development server:
   ```bash
   python manage.py runserver
   ```

2. Go to Admin interface: http://localhost:8000/admin/

3. Try creating an Artist, Album, or Song with an image

4. Verify image appears in `backend/media/artwork/` directory

5. Check image is displayed correctly in templates

### Automated Testing

Create `backend/core/tests/test_images.py`:

```python
"""
Tests for image upload and processing.
"""
import os
from django.test import TestCase
from django.core.files.uploadedfile import SimpleUploadedFile
from PIL import Image
from io import BytesIO
from core.models import Artist, Album, Song
from core.utils import process_image, create_thumbnail, validate_image


def create_test_image(width=100, height=100):
    """Create a test image file."""
    img = Image.new('RGB', (width, height), color='red')
    output = BytesIO()
    img.save(output, 'JPEG')
    output.seek(0)
    return SimpleUploadedFile(
        "test_image.jpg",
        output.read(),
        content_type="image/jpeg"
    )


class ImageUploadTest(TestCase):
    """Test image upload functionality."""
    
    def test_artist_image_upload(self):
        """Test artist image upload."""
        image = create_test_image()
        artist = Artist.objects.create(
            name="Test Artist",
            image=image
        )
        self.assertTrue(artist.image)
        self.assertTrue(os.path.exists(artist.image.path))
    
    def test_album_cover_upload(self):
        """Test album cover upload."""
        image = create_test_image()
        album = Album.objects.create(
            title="Test Album",
            cover=image
        )
        self.assertTrue(album.cover)
        self.assertTrue(os.path.exists(album.cover.path))
    
    def test_image_resize(self):
        """Test that large images are resized."""
        # Create large image
        large_image = create_test_image(width=3000, height=3000)
        artist = Artist.objects.create(
            name="Large Image Artist",
            image=large_image
        )
        
        # Check image was resized
        img = Image.open(artist.image.path)
        self.assertLessEqual(img.width, 1920)
        self.assertLessEqual(img.height, 1920)
    
    def test_image_validation(self):
        """Test image validation."""
        # Test valid image
        valid_image = create_test_image()
        self.assertTrue(validate_image(valid_image))
        
        # Test invalid file type (would need to create actual invalid file)
        # This is a simplified test
    
    def test_thumbnail_creation(self):
        """Test thumbnail creation."""
        image = create_test_image(width=500, height=500)
        thumbnail = create_thumbnail(image, size=(100, 100))
        
        # Open thumbnail
        img = Image.open(thumbnail)
        self.assertEqual(img.size, (100, 100))
```

Run tests:

```bash
pytest core/tests/test_images.py -v
```

## Production Considerations

### File Storage

For production, consider using cloud storage:

#### AWS S3

```bash
pip install django-storages boto3
```

```python
# settings_prod.py
AWS_STORAGE_BUCKET_NAME = 'your-bucket-name'
AWS_S3_REGION_NAME = 'us-east-1'
AWS_ACCESS_KEY_ID = os.environ.get('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY')

DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
```

#### Azure Blob Storage

```bash
pip install django-storages azure-storage-blob
```

```python
# settings_prod.py
AZURE_ACCOUNT_NAME = 'your-account-name'
AZURE_ACCOUNT_KEY = os.environ.get('AZURE_ACCOUNT_KEY')
AZURE_CONTAINER = 'media'

DEFAULT_FILE_STORAGE = 'storages.backends.azure_storage.AzureStorage'
```

### Image Optimization

For better performance:

1. **Use WebP format** (modern browsers)
2. **Implement lazy loading** in templates
3. **Use CDN** for serving images
4. **Generate multiple sizes** for responsive design
5. **Implement caching** headers

### Security

1. **Validate file types** before processing
2. **Limit file size** (10MB recommended)
3. **Use secure file names** (Django does this automatically)
4. **Scan for viruses** (use ClamAV or similar)
5. **Set proper permissions** on media directory

## Troubleshooting

### Common Issues

#### Issue: `Pillow` installation fails

**Solution:**
```bash
# Install system dependencies first
sudo apt-get install libjpeg-dev zlib1g-dev

# Then reinstall Pillow
pip uninstall Pillow
pip install Pillow
```

#### Issue: Image upload returns "image not valid"

**Solution:**
- Check file extension is allowed
- Verify file size is under limit
- Ensure PIL can open the file

#### Issue: Images not displaying

**Solution:**
- Check MEDIA_URL and MEDIA_ROOT settings
- Verify media directory permissions (755)
- Check if serving media files in development
- Use `collectstatic` in production

#### Issue: Memory errors with large images

**Solution:**
```python
# Use Image.open() in chunks
from PIL import ImageFile
ImageFile.MAX_IMAGE_SIZE = 25 * 1024 * 1024  # 25 MB
```

### Debug Commands

```bash
# Check media directory permissions
ls -la backend/media/

# Test Pillow installation
python -c "from PIL import Image; print(Image.__version__)"

# Test image processing
python manage.py shell
>>> from core.utils import create_thumbnail
>>> from django.core.files.uploadedfile import SimpleUploadedFile
>>> # Create test image and process

# Check file permissions
python manage.py findstatic --verbosity=2
```

## Best Practices

1. **Always validate** uploaded files
2. **Resize large images** before saving
3. **Use progressive JPEGs** for faster loading
4. **Implement file naming** conventions
5. **Clean up old images** when updating
6. **Use caching** for frequently accessed images
7. **Monitor storage** usage
8. **Backup media** directory regularly

## Additional Resources

- [Pillow Documentation](https://pillow.readthedocs.io/)
- [Django ImageField Documentation](https://docs.djangoproject.com/en/stable/ref/models/fields/#imagefield)
- [Django File Uploads](https://docs.djangoproject.com/en/stable/topics/http/file-uploads/)
- [Image Optimization Best Practices](https://developer.mozilla.org/en-US/docs/Learn/Performance/Images)

## Support

If you encounter issues:

1. Check Pillow is installed: `python -c "from PIL import Image; print(Image.__version__)"`
2. Verify file permissions: `ls -la media/`
3. Check Django logs: `tail -f logs/django.log`
4. Test image manually: Open in image editor
5. Review file size: Large images may timeout
6. Check system dependencies: All image libraries installed