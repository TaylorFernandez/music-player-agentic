#!/usr/bin/env python3
"""
Test script to verify Pillow installation and functionality.
"""

import os
import sys

from PIL import Image, ImageDraw, ImageFont


def test_pillow_installation():
    """Test that Pillow is installed correctly."""
    print("=" * 60)
    print("Testing Pillow Installation")
    print("=" * 60)

    try:
        print(f"✓ Pillow version: {Image.__version__}")
        print(f"✓ PIL module imported successfully")
        return True
    except ImportError as e:
        print(f"✗ Failed to import Pillow: {e}")
        return False


def test_image_creation():
    """Test creating a new image."""
    print("\n" + "=" * 60)
    print("Testing Image Creation")
    print("=" * 60)

    try:
        # Create a simple test image
        img = Image.new("RGB", (100, 100), color="red")
        print(f"✓ Created new image: {img.size} {img.mode}")
        return True
    except Exception as e:
        print(f"✗ Failed to create image: {e}")
        return False


def test_image_drawing():
    """Test drawing on an image."""
    print("\n" + "=" * 60)
    print("Testing Image Drawing")
    print("=" * 60)

    try:
        # Create image and draw on it
        img = Image.new("RGB", (200, 200), color="white")
        draw = ImageDraw.Draw(img)

        # Draw a rectangle
        draw.rectangle([50, 50, 150, 150], fill="blue", outline="black")
        print(f"✓ Drew rectangle on image")

        # Draw text (if possible)
        try:
            draw.text((60, 100), "Test", fill="white")
            print(f"✓ Drew text on image")
        except:
            print(f"⚠ Text drawing skipped (no default font)")

        return True
    except Exception as e:
        print(f"✗ Failed to draw on image: {e}")
        return False


def test_image_formats():
    """Test different image formats."""
    print("\n" + "=" * 60)
    print("Testing Image Formats")
    print("=" * 60)

    formats = ["JPEG", "PNG", "GIF", "BMP", "WEBP"]
    img = Image.new("RGB", (50, 50), color="green")

    success_count = 0
    for fmt in formats:
        try:
            # Try to save in this format
            from io import BytesIO

            buffer = BytesIO()
            img.save(buffer, format=fmt)
            print(f"✓ {fmt} format supported")
            success_count += 1
        except Exception as e:
            print(f"✗ {fmt} format failed: {e}")

    return success_count == len(formats)


def test_image_resize():
    """Test image resizing."""
    print("\n" + "=" * 60)
    print("Testing Image Resize")
    print("=" * 60)

    try:
        # Create large image
        large_img = Image.new("RGB", (1000, 1000), color="blue")
        print(f"✓ Created large image: {large_img.size}")

        # Resize using thumbnail
        img_copy = large_img.copy()
        img_copy.thumbnail((500, 500))
        print(f"✓ Resized with thumbnail: {img_copy.size}")

        # Resize using resize
        resized = large_img.resize((200, 200))
        print(f"✓ Resized with resize: {resized.size}")

        return True
    except Exception as e:
        print(f"✗ Failed to resize image: {e}")
        return False


def test_image_filters():
    """Test image filters."""
    print("\n" + "=" * 60)
    print("Testing Image Filters")
    print("=" * 60)

    try:
        from PIL import ImageFilter

        # Create test image
        img = Image.new("RGB", (100, 100), color="red")

        # Apply blur filter
        blurred = img.filter(ImageFilter.BLUR)
        print(f"✓ Applied blur filter")

        # Apply sharpen filter
        sharpened = img.filter(ImageFilter.SHARPEN)
        print(f"✓ Applied sharpen filter")

        return True
    except Exception as e:
        print(f"✗ Failed to apply filters: {e}")
        return False


def test_color_modes():
    """Test different color modes."""
    print("\n" + "=" * 60)
    print("Testing Color Modes")
    print("=" * 60)

    modes = ["RGB", "RGBA", "L", "LA", "P"]
    success_count = 0

    for mode in modes:
        try:
            if mode == "RGBA":
                img = Image.new(mode, (50, 50), color=(255, 0, 0, 128))
            elif mode in ["L", "LA"]:
                img = Image.new(mode, (50, 50), color=128)
            elif mode == "P":
                img = Image.new(mode, (50, 50))
            else:
                img = Image.new(mode, (50, 50), color="red")

            print(f"✓ {mode} mode supported")
            success_count += 1
        except Exception as e:
            print(f"✗ {mode} mode failed: {e}")

    return success_count == len(modes)


def test_image_conversion():
    """Test image format conversions."""
    print("\n" + "=" * 60)
    print("Testing Image Conversions")
    print("=" * 60)

    try:
        # Create RGBA image
        rgba_img = Image.new("RGBA", (100, 100), color=(255, 0, 0, 128))
        print(f"✓ Created RGBA image")

        # Convert to RGB
        rgb_img = rgba_img.convert("RGB")
        print(f"✓ Converted to RGB")

        # Convert to grayscale
        gray_img = rgba_img.convert("L")
        print(f"✓ Converted to grayscale")

        return True
    except Exception as e:
        print(f"✗ Failed to convert image: {e}")
        return False


def test_django_image_field():
    """Test if Django ImageField can be used."""
    print("\n" + "=" * 60)
    print("Testing Django ImageField Compatibility")
    print("=" * 60)

    try:
        from django.core.files.uploadedfile import SimpleUploadedFile
        from PIL import Image

        # Create a test image in memory
        img = Image.new("RGB", (100, 100), color="blue")
        from io import BytesIO

        buffer = BytesIO()
        img.save(buffer, format="JPEG")
        buffer.seek(0)

        # Create SimpleUploadedFile
        uploaded_file = SimpleUploadedFile(
            "test.jpg", buffer.read(), content_type="image/jpeg"
        )

        print(f"✓ Created Django-compatible uploaded file")
        print(f"  - Filename: {uploaded_file.name}")
        print(f"  - Size: {uploaded_file.size} bytes")
        print(f"  - Content type: {uploaded_file.content_type}")

        return True
    except Exception as e:
        print(f"✗ Failed to create Django file: {e}")
        return False


def run_all_tests():
    """Run all tests and report results."""
    print("\n" + "=" * 60)
    print("PILLOW FUNCTIONALITY TEST SUITE")
    print("=" * 60 + "\n")

    tests = [
        ("Pillow Installation", test_pillow_installation),
        ("Image Creation", test_image_creation),
        ("Image Drawing", test_image_drawing),
        ("Image Formats", test_image_formats),
        ("Image Resize", test_image_resize),
        ("Image Filters", test_image_filters),
        ("Color Modes", test_color_modes),
        ("Image Conversion", test_image_conversion),
        ("Django ImageField", test_django_image_field),
    ]

    results = []
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"\n✗ Test '{test_name}' crashed: {e}")
            results.append((test_name, False))

    # Print summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)

    passed = sum(1 for _, result in results if result)
    total = len(results)

    for test_name, result in results:
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"{status} - {test_name}")

    print("\n" + "=" * 60)
    print(f"Results: {passed}/{total} tests passed ({(passed / total) * 100:.0f}%)")
    print("=" * 60 + "\n")

    if passed == total:
        print("✓ All tests passed! Pillow is working correctly.")
        print("✓ Ready to use ImageField in Django models.")
        return 0
    else:
        print(f"✗ {total - passed} test(s) failed.")
        print("⚠ Some features may not work as expected.")
        return 1


if __name__ == "__main__":
    sys.exit(run_all_tests())
