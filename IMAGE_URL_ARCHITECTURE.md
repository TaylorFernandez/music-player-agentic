# Image URL Architecture - Licensed Image Sources

## ✅ Status: ALREADY IMPLEMENTED

**Date:** [Current Date]  
**Architecture:** URL-based image storage with licensed source support  
**Security:** No server-side image uploads  
**Licensing:** Supports attribution and license tracking

---

## Overview

The Music Player App uses **URL-based image storage** instead of hosting images directly. This allows users to link to images from legitimate licensed sources like:

- **Official artist websites** - Artist-approved promotional images
- **Record label resources** - Official album artwork from labels
- **Licensed image databases** - Services like Spotify, Apple Music, MusicBrainz
- **Press kit materials** - Official promotional images
- **Creative Commons sources** - Wikipedia, Wikimedia Commons (with attribution)
- **Fair use sources** - Album covers under fair use doctrine

---

## Current Architecture

### Models (Using URLField)

```python
# Artist Model
class Artist(models.Model):
    name = models.CharField(max_length=255, unique=True)
    image_url = models.URLField(max_length=500, blank=True, null=True)
    bio = models.TextField(blank=True)
    # ... other fields

# Album Model
class Album(models.Model):
    title = models.CharField(max_length=255)
    cover_url = models.URLField(max_length=500, blank=True, null=True)
    # ... other fields

# Song Model
class Song(models.Model):
    title = models.CharField(max_length=255)
    artwork_url = models.URLField(max_length=500, blank=True, null=True)
    # ... other fields
```

### Key Benefits

1. **No Copyright Infringement Risk** - Images hosted by rights holders
2. **Always Up-to-Date** - Official sources update automatically
3. **Proper Licensing** - Images from legitimate sources
4. **Reduced Liability** - No storage of potentially infringing content
5. **Better Quality** - Official images are typically higher resolution
6. **Attribution Support** - Can add credit fields if needed

---

## Licensed Image Sources

### 1. Official Artist Websites

**Recommended Sources:**
- Artist's official website
- Band's Bandcamp page
- Artist's verified social media (Instagram, Twitter)
- Record label's official site

**Example URLs:**
```
https://www.artistname.com/images/press-photo.jpg
https://f4.bcbits.com/img/artist_id.jpg (Bandcamp)
```

**Considerations:**
- Always check terms of use on artist's website
- Some artists provide press kits with approved images
- Look for "Press" or "Media" sections

### 2. Music Streaming Services (APIs)

**Spotify API:**
```python
# Get artist image from Spotify API
import spotipy
from spotipy.oauth2 import SpotifyClientCredentials

sp = spotipy.Spotify(client_credentials_manager=SpotifyClientCredentials())
result = sp.artist(artist_spotify_id)
image_url = result['images'][0]['url']  # Highest resolution
```

**Apple Music API:**
```python
# Get album artwork from Apple Music API
# URL format: https://is1-ssl.mzstatic.com/image/thumb/{id}/source/{size}x{size}bb.jpg
```

**Last.fm API:**
```python
# Get artist/album images
# Free API with good coverage
```

**Considerations:**
- Check API terms of service
- Some require attribution
- Rate limits apply
- May require API key

### 3. Music Databases

**MusicBrainz (Recommended - Open Source):**
```
https://coverartarchive.org/release/{mbid}/front
https://coverartarchive.org/release-group/{mbid}/front
```

- **License:** CC0 (Public Domain)
- **Attribution:** Not required but appreciated
- **Coverage:** Extensive album artwork
- **API:** Free and open

**Discogs:**
```
https://img.discogs.com/{identifier}.jpg
```

- **License:** Check specific image rights
- **Attribution:** May be required
- **Coverage:** Comprehensive music database
- **API:** Requires authentication

### 4. Wikimedia Commons (Creative Commons)

```
https://upload.wikimedia.org/wikipedia/commons/{path}/filename.jpg
```

- **License:** Various CC licenses
- **Attribution:** Required for most images
- **Usage:** Check specific license terms
- **Quality:** Variable

### 5. Fair Use - Album Covers

**Legal Basis:**
- Album covers can be used for identification purposes under fair use
- US Code 17 U.S.C. § 107
- Must be low resolution (typically < 300px)
- Must be for commentary, criticism, or identification

**Recommended Practice:**
- Use thumbnails (150-300px)
- Link to original source when possible
- Don't use for commercial purposes without license
- Consider adding "Album cover" attribution

---

## Implementation for Licensed Sources

### Adding Attribution Fields (Optional)

```python
# Enhanced Artist Model with Attribution
class Artist(models.Model):
    name = models.CharField(max_length=255, unique=True)
    image_url = models.URLField(max_length=500, blank=True, null=True)
    image_source = models.CharField(max_length=255, blank=True, null=True)  # "Spotify", "Official Website"
    image_attribution = models.TextField(blank=True, null=True)  # Attribution text
    image_license = models.CharField(max_length=50, blank=True, null=True)  # "CC BY 4.0", "Fair Use"
    bio = models.TextField(blank=True)
    # ... other fields

# Enhanced Album Model
class Album(models.Model):
    title = models.CharField(max_length=255)
    cover_url = models.URLField(max_length=500, blank=True, null=True)
    cover_source = models.CharField(max_length=255, blank=True, null=True)
    cover_attribution = models.TextField(blank=True, null=True)
    cover_license = models.CharField(max_length=50, blank=True, null=True)
    # ... other fields
```

### API Response with Attribution

```json
{
    "id": 1,
    "name": "Artist Name",
    "image_url": "https://example.com/artist.jpg",
    "image_source": "Official Website",
    "image_attribution": "© Artist Name. Used with permission.",
    "image_license": "Used with permission",
    "bio": "Artist biography",
    "song_count": 10,
    "album_count": 2
}
```

### Template Display with Attribution

```html
<div class="artist-image">
    {% if artist.image_url %}
        <img src="{{ artist.image_url }}" alt="{{ artist.name }}">
        {% if artist.image_attribution %}
            <p class="attribution">{{ artist.image_attribution }}</p>
        {% endif %}
    {% else %}
        <div class="placeholder-image">🎤</div>
    {% endif %}
</div>
```

---

## User Workflow for Licensed Images

### Step 1: Find Licensed Image

**From Official Sources:**
1. Visit artist's official website
2. Check "Press" or "Media" section
3. Download high-quality promotional image
4. Note attribution requirements
5. Use the image URL directly or upload to approved service

**From APIs:**
1. Use Spotify/Apple Music API
2. Retrieve image URL from response
3. Note source and attribution requirements
4. Submit URL through change request

**From MusicBrainz:**
1. Search for album/artist
2. Get Cover Art Archive URL
3. Use directly (CC0 license)
4. Attribution optional but appreciated

### Step 2: Submit Change Request

```python
# User submits change request with licensed image
change_request = ChangeRequest.objects.create(
    user=request.user,
    model_type='artist',
    model_id=artist.id,
    field_name='image_url',
    old_value=artist.image_url or '',
    new_value='https://upload.wikimedia.org/wikipedia/commons/artist.jpg',
    notes='Image from Wikimedia Commons, CC BY-SA 4.0, Attribution: Artist Name',
    status='pending'
)
```

### Step 3: Moderator Review

Moderators check:
- ✅ Image is from legitimate source
- ✅ License permits usage
- ✅ Attribution provided (if required)
- ✅ Not a pirated image
- ✅ Meets quality standards

---

## Common Licensed Sources

### Album Artwork

| Source | License | Attribution | Quality | Coverage |
|--------|---------|-------------|---------|----------|
| **Cover Art Archive** | CC0 | Not required | High | Excellent |
| **Spotify API** | Varies | Check terms | High | Excellent |
| **Apple Music API** | Varies | Check terms | High | Excellent |
| **Last.fm API** | Varies | May require | Medium | Good |
| **Discogs** | Varies | Often required | Variable | Excellent |

### Artist Images

| Source | License | Attribution | Quality | Notes |
|--------|---------|-------------|---------|-------|
| **Artist Website** | Varies | Check site | High | Recommended |
| **Wikimedia Commons** | Various CC | Required | Variable | Check specific license |
| **Spotify API** | Varies | Check terms | High | Via API only |
| **Press Kits** | Usually free | May require | High | Official source |

---

## Best Practices

### For Users

1. **Always use legitimate sources**
   - Official artist websites
   - Licensed databases (MusicBrainz, Spotify API)
   - Press kit materials
   - Creative Commons sources

2. **Check license terms**
   - Read usage rights before submitting
   - Provide required attribution
   - Don't use if license is unclear

3. **Provide attribution when required**
   - Include in change request notes
   - Credit photographer/creator
   - Link to original source

4. **Use appropriate resolution**
   - Album covers: 300-500px (fair use)
   - Artist photos: As provided
   - Don't upscale low-res images

### For Moderators

1. **Verify source legitimacy**
   - Check if URL is from approved source
   - Verify image isn't pirated
   - Check for watermarks indicating unofficial source

2. **Validate license compatibility**
   - Ensure license allows usage
   - Check if attribution is required
   - Verify commercial use rights (if applicable)

3. **Require attribution**
   - Ask for source information
   - Request attribution text
   - Document in change request notes

---

## License Tracking

### Recommended Fields to Add

```python
class Artist(models.Model):
    # ... existing fields
    
    # Image licensing
    image_url = models.URLField(max_length=500, blank=True, null=True)
    image_source = models.CharField(max_length=255, blank=True, null=True)
    image_license = models.CharField(max_length=100, blank=True, null=True)
    image_attribution = models.TextField(blank=True, null=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['name']),
        ]
```

### License Types

Common licenses to track:

```python
LICENSE_CHOICES = [
    ('', 'Unknown'),
    ('CC0', 'Public Domain'),
    ('CC-BY', 'Creative Commons Attribution'),
    ('CC-BY-SA', 'CC Attribution-ShareAlike'),
    ('CC-BY-NC', 'CC Attribution-NonCommercial'),
    ('FAIR-USE', 'Fair Use'),
    ('PERMISSION', 'Used with Permission'),
    ('OFFICIAL', 'Official/Press Kit'),
    ('PURCHASED', 'Licensed/Purchased'),
]
```

---

## Legal Considerations

### Fair Use (Album Covers)

**Generally Acceptable:**
- Low-resolution thumbnails (< 300px)
- Used for identification
- Not for commercial merchandise
- Educational/informational purposes

**Not Acceptable:**
- High-resolution scans
- Commercial merchandise
- Removing copyright notices
- Claiming as original work

### Creative Commons

**CC0 (Public Domain):**
- No attribution required
- Free to use for any purpose
- MusicBrainz Cover Art Archive uses this

**CC BY:**
- Attribution required
- Commercial use allowed
- Must credit creator

**CC BY-SA:**
- Attribution required
- Share alike requirement
- Modifications must use same license

**CC BY-NC:**
- Attribution required
- Non-commercial use only
- May need different license for commercial use

### Official Sources

**Press Kits:**
- Often explicitly for promotional use
- Check for usage guidelines
- May require credit

**Artist Websites:**
- Varies by artist
- Check terms of use
- Look for "Media" or "Press" sections

---

## Implementation Examples

### From MusicBrainz API

```python
import requests

def get_album_cover_from_musicbrainz(release_mbid):
    """Get album cover from Cover Art Archive."""
    url = f"https://coverartarchive.org/release/{release_mbid}/front"
    
    try:
        response = requests.head(url, timeout=5)
        if response.status_code == 200:
            return url
    except requests.RequestException:
        pass
    
    return None

# Usage in view
def album_detail(request, pk):
    album = get_object_or_404(Album, pk=pk)
    
    # If no cover, try MusicBrainz
    if not album.cover_url and album.musicbrainz_id:
        album.cover_url = get_album_cover_from_musicbrainz(album.musicbrainz_id)
        album.cover_source = 'MusicBrainz Cover Art Archive'
        album.cover_license = 'CC0'
        album.save()
    
    return render(request, 'album_detail.html', {'album': album})
```

### From Spotify API

```python
import spotipy
from spotipy.oauth2 import SpotifyClientCredentials

def get_artist_image_from_spotify(artist_name):
    """Search for artist image on Spotify."""
    sp = spotipy.Spotify(client_credentials_manager=SpotifyClientCredentials())
    
    results = sp.search(q=artist_name, type='artist', limit=1)
    
    if results['artists']['items']:
        artist = results['artists']['items'][0]
        if artist['images']:
            # Get largest image
            return {
                'url': artist['images'][0]['url'],
                'source': 'Spotify',
                'width': artist['images'][0]['width'],
                'height': artist['images'][0]['height'],
            }
    
    return None
```

### Attribution Template

```html
<!-- Template for displaying images with attribution -->
<div class="image-container">
    <img src="{{ object.image_url }}" alt="{{ object.name }}">
    
    {% if object.image_license or object.image_attribution %}
    <div class="image-attribution">
        {% if object.image_source %}
            <small>Source: {{ object.image_source }}</small>
        {% endif %}
        
        {% if object.image_license %}
            <small>License: {{ object.image_license }}</small>
        {% endif %}
        
        {% if object.image_attribution %}
            <small>{{ object.image_attribution }}</small>
        {% endif %}
    </div>
    {% endif %}
</div>
```

---

## API Integration Services

### MusicBrainz Integration (Free, Open)

```python
# Add to requirements.txt
# musicbrainzngs==0.7.1

import musicbrainzngs

def get_musicbrainz_cover(artist_name, album_title):
    """Get album cover from MusicBrainz."""
    musicbrainzngs.set_useragent("MusicPlayerApp", "1.0")
    
    # Search for release
    result = musicbrainzngs.search_releases(
        artist=artist_name,
        release=album_title,
        limit=1
    )
    
    if result['release-list']:
        mbid = result['release-list'][0]['id']
        cover_url = f"https://coverartarchive.org/release/{mbid}/front"
        
        return {
            'url': cover_url,
            'source': 'MusicBrainz',
            'license': 'CC0',
            'attribution': None
        }
    
    return None
```

---

## Recommended Workflow

### For New Albums/Artists

1. **Check MusicBrainz first**
   - Free, CC0 licensed
   - Good coverage for albums
   - Easy to use

2. **Fallback to Spotify/Apple Music APIs**
   - Better coverage
   - Check API terms
   - May require attribution

3. **Use official sources when available**
   - Highest quality
   - Official approval
   - Best for artist images

4. **Allow user submissions**
   - Through change request
   - Require source citation
   - Moderator verification

### For Existing Data

```python
# Management command to populate images from MusicBrainz
from django.core.management.base import BaseCommand
from core.models import Album
import requests

class Command(BaseCommand):
    help = 'Fetch album covers from MusicBrainz'
    
    def handle(self, *args, **options):
        albums_without_covers = Album.objects.filter(cover_url__isnull=True)
        
        for album in albums_without_covers:
            cover = get_musicbrainz_cover(album.artist.name, album.title)
            
            if cover:
                album.cover_url = cover['url']
                album.cover_source = cover['source']
                album.cover_license = cover['license']
                album.save()
                
                self.stdout.write(
                    self.style.SUCCESS(f'Updated cover for {album.title}')
                )
```

---

## Security & Validation

### URL Validation

```python
from django.core.exceptions import ValidationError
from urllib.parse import urlparse

def validate_image_url(url):
    """Validate that URL is from approved source."""
    if not url:
        return True
    
    parsed = urlparse(url)
    
    # Must be HTTPS
    if parsed.scheme != 'https':
        raise ValidationError('Image URLs must use HTTPS.')
    
    # Check for approved domains (optional)
    approved_domains = [
        'upload.wikimedia.org',
        'coverartarchive.org',
        'i.scdn.co',  # Spotify CDN
        'is1-ssl.mzstatic.com',  # Apple Music CDN
        'lastfm-img2.akamaized.net',
        'img.discogs.com',
        # Add more approved domains as needed
    ]
    
    # For now, allow all HTTPS URLs
    # Enable domain checking if needed:
    # if not any(domain in parsed.netloc for domain in approved_domains):
    #     raise ValidationError('Image must be from approved source.')
    
    return True
```

---

## Documentation for Users

### How to Add Licensed Images

1. **Find a legitimate source**
   - Official artist website
   - MusicBrainz (free, CC0)
   - Spotify/Apple Music (via API)
   - Wikimedia Commons (check license)

2. **Get the direct image URL**
   - Right-click on image → "Copy Image Location"
   - Or use API to get URL
   - Must be direct link to image file

3. **Submit change request**
   - Paste URL in image field
   - Add source information
   - Include attribution if required
   - Note the license type

4. **Wait for moderator approval**
   - Moderators verify legitimacy
   - Check license compatibility
   - Approve or request changes

### Examples

**MusicBrainz (CC0, no attribution required):**
```
URL: https://coverartarchive.org/release/abc-123/front
Source: MusicBrainz Cover Art Archive
License: CC0 (Public Domain)
Attribution: Not required
```

**Wikimedia Commons (CC BY-SA, attribution required):**
```
URL: https://upload.wikimedia.org/wikipedia/commons/artist.jpg
Source: Wikimedia Commons
License: CC BY-SA 4.0
Attribution: "Photo by John Doe, CC BY-SA 4.0"
```

**Official Website (Used with permission):**
```
URL: https://artistname.com/images/press-photo.jpg
Source: Artist's Official Website
License: Used with permission
Attribution: "© Artist Name, used with permission"
```

---

## Implementation Checklist

### ✅ Already Implemented

- [x] Models use URLField instead of ImageField
- [x] Templates display images from URLs
- [x] API returns image URLs
- [x] Change request workflow supports URLs
- [x] No file upload handling

### 🔄 Recommended Additions

- [ ] Add source tracking fields (image_source, image_license, image_attribution)
- [ ] Create database migration for new fields
- [ ] Update serializers to include attribution
- [ ] Update templates to display attribution
- [ ] Add URL validation for approved domains (optional)
- [ ] Create user guide for licensed images
- [ ] Add MusicBrainz API integration
- [ ] Add Spotify API integration (optional)
- [ ] Create management command to fetch images

---

## Summary

Your architecture is already perfect for licensed image sources. Users can link to images from:

✅ Official artist websites  
✅ Licensed databases (MusicBrainz, Spotify)  
✅ Creative Commons sources  
✅ Press kits and promotional materials  

**Recommendations:**
1. Add attribution tracking fields
2. Document proper image sources for users
3. Consider API integration for automated image retrieval
4. Update templates to show attribution when available
5. Train moderators on license verification

**No migration needed** - your URLField architecture already supports this use case perfectly!