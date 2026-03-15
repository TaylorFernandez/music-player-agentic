# Flutter App Deployment Guide - Music Player

## Complete Setup and Deployment Guide

This guide covers setting up, building, and deploying the Music Player Flutter app to Android devices (Pixel 10 Pro XL and others).

---

## Prerequisites

### 1. Java Development Kit (JDK)

**Required:** JDK 17 or higher

#### Install on Linux (Bazzite/Fedora):
```bash
# Install OpenJDK 17
sudo dnf install java-17-openjdk java-17-openjdk-devel

# Or using apt (Ubuntu/Debian)
sudo apt update
sudo apt install openjdk-17-jdk

# Verify installation
java -version
javac -version
```

#### Set JAVA_HOME:
```bash
# Add to ~/.bashrc or ~/.zshrc
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Apply changes
source ~/.bashrc
```

### 2. Android SDK

**Required:** Android SDK Platform 35 (for Pixel 10 Pro XL)

#### Install via Android Studio:
1. Open Android Studio
2. Go to Settings → Appearance & Behavior → System Settings → Android SDK
3. Install:
   - Android SDK Platform 35
   - Android SDK Build-Tools 35
   - Android SDK Platform-Tools
   - Android SDK Command-line Tools

#### Install via Command Line:
```bash
# Install Android SDK Command Line Tools
sdkmanager --install "platforms;android-35"
sdkmanager --install "build-tools;35.0.0"
sdkmanager --install "platform-tools"
```

### 3. Flutter SDK

**Required:** Flutter 3.24.5 or higher

```bash
# Verify Flutter installation
flutter doctor -v

# Should show:
# [✓] Flutter (Channel stable, 3.24.5)
# [✓] Android toolchain (Android SDK version 35)
# [✓] Android Studio
```

---

## Environment Variables Configuration

### Flutter Environment File (.env)

The app uses `flutter_dotenv` to load environment variables from `.env` file.

#### Development Environment (.env.development):
```bash
# API Configuration
API_BASE_URL=http://10.0.2.2:8000/api
API_TIMEOUT=30000

# App Configuration
APP_NAME=Music Player Dev
APP_VERSION=1.0.0
ENVIRONMENT=development

# Debug Settings
DEBUG_MODE=true
ENABLE_LOGGING=true
LOG_LEVEL=debug

# Feature Flags
ENABLE_OFFLINE_MODE=true
ENABLE_METADATA_EXTRACTION=true
ENABLE_SONG_MATCHING=true

# Authentication
ENABLE_AUTH=true
AUTH_TIMEOUT=60000

# Platform Specific
PLATFORM=android
DEVICE_NAME=Pixel_10_Pro_XL
```

#### Production Environment (.env.production):
```bash
# API Configuration
API_BASE_URL=https://your-domain.com/api
API_TIMEOUT=30000

# App Configuration
APP_NAME=Music Player
APP_VERSION=1.0.0
ENVIRONMENT=production

# Debug Settings
DEBUG_MODE=false
LOG_LEVEL=error
```

### Important Notes:

**For Physical Android Device:**
- Use your computer's local network IP: `http://192.168.1.XXX:8000/api`
- Or use Android emulator special IP: `http://10.0.2.2:8000/api`

**To Find Your Local IP:**
```bash
# Linux/Mac
ip addr show | grep inet
# or
ifconfig | grep inet

# Look for something like:
# inet 192.168.1.100
```

---

## Build Configuration

### Android Build Settings (android/app/build.gradle)

```gradle
android {
    namespace = "com.musicplayer.music_player_app"
    compileSdk = 35  // Updated for Pixel 10 Pro XL
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.musicplayer.music_player_app"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.debug
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Gradle Settings (android/settings.gradle)

```gradle
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.1.0" apply false
    id "org.jetbrains.kotlin.android" version "1.9.0" apply false
}

// Force Java 17 for all subprojects
gradle.beforeProject { project ->
    project.plugins.withId('com.android.application') {
        project.android.compileOptions {
            sourceCompatibility JavaVersion.VERSION_17
            targetCompatibility JavaVersion.VERSION_17
        }
    }
    project.plugins.withId('com.android.library') {
        project.android.compileOptions {
            sourceCompatibility JavaVersion.VERSION_17
            targetCompatibility JavaVersion.VERSION_17
        }
    }
}
```

---

## Deployment Steps

### Step 1: Setup Environment

```bash
# Navigate to frontend directory
cd "/var/home/taylor/Desktop/music player app - agentic/frontend"

# Copy environment file
cp .env.development .env

# Verify .env file exists
ls -la .env
```

### Step 2: Install Dependencies

```bash
# Get Flutter dependencies
flutter pub get

# Clean previous builds
flutter clean
```

### Step 3: Verify Setup

```bash
# Check Flutter doctor
flutter doctor -v

# Should show all green checkmarks
```

### Step 4: Connect Device

**For USB Connection:**
```bash
# Enable USB debugging on your Android device
# Settings → Developer Options → USB Debugging

# Verify device is connected
flutter devices

# Should show:
# Pixel 10 Pro XL (mobile) • 58270DLCQ002HY • android-arm64 • Android 16 (API 36)
```

**For Wireless Connection:**
```bash
# Connect device to same WiFi network
# Enable wireless debugging on device
# Settings → Developer Options → Wireless Debugging

# Pair device
adb pair <device-ip>:<pairing-port>

# Connect device
adb connect <device-ip>:<connect-port>

# Verify connection
flutter devices
```

### Step 5: Build APK

#### Debug Build (Faster, includes debugging):
```bash
flutter build apk --debug
```

#### Release Build (Optimized, smaller):
```bash
flutter build apk --release
```

#### App Bundle (For Play Store):
```bash
flutter build appbundle --release
```

### Step 6: Run on Device

#### Debug Mode:
```bash
# Run directly on connected device
flutter run -d <device-id>

# Or specify device name
flutter run -d 58270DLCQ002HY

# Hot reload enabled - changes appear instantly
```

#### Release Mode:
```bash
# Run optimized version
flutter run -d <device-id> --release

# No hot reload - must restart to see changes
```

### Step 7: Install APK Manually

```bash
# Install built APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Or using Flutter
flutter install
```

---

## Starting the Backend

### Step 1: Start Django Server

```bash
# Navigate to backend directory
cd "/var/home/taylor/Desktop/music player app - agentic/backend"

# Activate virtual environment
source venv/bin/activate

# Run migrations (if needed)
python manage.py migrate

# Start server
python manage.py runserver 0.0.0.0:8000

# Server will be available at:
# http://localhost:8000 (on same machine)
# http://192.168.1.XXX:8000 (on local network)
```

### Step 2: Verify Backend is Running

```bash
# Test API endpoint
curl http://localhost:8000/

# Should return HTML response

# Test API endpoint
curl http://localhost:8000/api/

# Should return JSON response
```

### Step 3: Update Flutter .env

```bash
# For Android emulator
API_BASE_URL=http://10.0.2.2:8000/api

# For physical device on same network
API_BASE_URL=http://192.168.1.XXX:8000/api
```

---

## Common Issues and Solutions

### Issue 1: Java Not Found

**Error:** `JAVA_HOME is not set and no 'java' command could be found`

**Solution:**
```bash
# Install Java 17
sudo dnf install java-17-openjdk java-17-openjdk-devel

# Set JAVA_HOME in ~/.bashrc
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Verify
java -version
```

### Issue 2: Android SDK Not Found

**Error:** `Android SDK not found`

**Solution:**
```bash
# Set ANDROID_HOME
echo 'export ANDROID_HOME=$HOME/Android/Sdk' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/emulator' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.bashrc
source ~/.bashrc

# Install SDK components
sdkmanager --install "platforms;android-35"
sdkmanager --install "build-tools;35.0.0"
```

### Issue 3: Gradle Build Failed

**Error:** `Gradle task assembleRelease failed with exit code 1`

**Solution:**
```bash
# Clean Gradle cache
cd android
./gradlew clean

# Clear Flutter cache
cd ..
flutter clean

# Remove .gradle folder
rm -rf ~/.gradle/caches/

# Try building again
flutter pub get
flutter build apk --release
```

### Issue 4: Device Not Detected

**Error:** `No devices detected`

**Solution:**
```bash
# Restart ADB server
adb kill-server
adb start-server

# Check USB connection
adb devices

# If wireless debugging
adb connect <device-ip>:<port>

# Verify with Flutter
flutter devices
```

### Issue 5: Network Connection Refused

**Error:** `Connection refused` or `Failed to connect to backend`

**Solution:**
```bash
# Check if Django is running
ps aux | grep manage.py

# Check Django server port
netstat -tlnp | grep 8000

# For Android emulator, use special IP
API_BASE_URL=http://10.0.2.2:8000/api

# For physical device, use computer's local IP
# Find your IP:
ip addr show | grep "inet " | grep -v 127.0.0.1

# Update .env file
# API_BASE_URL=http://192.168.1.XXX:8000/api
```

### Issue 6: Build Version Mismatch

**Error:** `The plugin flutter_plugin_android_lifecycle requires Android SDK version 35`

**Solution:**
```bash
# Update compileSdk in android/app/build.gradle
android {
    compileSdk = 35
    targetSdk = 35
    // ...
}

# Update compileOptions to Java 17
compileOptions {
    sourceCompatibility JavaVersion.VERSION_17
    targetCompatibility JavaVersion.VERSION_17
}
```

### Issue 7: Permission Denied

**Error:** `Permission denied` when running Flutter

**Solution:**
```bash
# Grant execute permission to gradlew
chmod +x android/gradlew

# Fix Flutter permissions
flutter pub cache repair
```

---

## Build Optimization

### Reduce APK Size

1. **Enable ProGuard:**
```gradle
// android/app/build.gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

2. **Use App Bundle:**
```bash
# Build app bundle (smaller than APK)
flutter build appbundle --release

# Upload to Play Store
# File: build/app/outputs/bundle/release/app-release.aab
```

3. **Split APKs by ABI:**
```bash
# Build split APKs
flutter build apk --split-per-abi --release

# Produces:
# app-armeabi-v7a-release.apk
# app-arm64-v8a-release.apk
# app-x86_64-release.apk
```

### Performance Tips

1. **Use Release Mode for Testing:**
```bash
flutter run --release
```

2. **Enable R8 Compiler:**
```gradle
// android/gradle.properties
android.enableR8=true
```

3. **Use Const Widgets:**
```dart
// Use const constructors where possible
const Text('Hello World')
const Icon(Icons.play_arrow)
```

---

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Device Tests
```bash
# Run tests on connected device
flutter test --device-id=<device-id>
```

---

## Deployment Checklist

### Pre-Deployment
- [ ] Java 17+ installed
- [ ] Android SDK Platform 35 installed
- [ ] Flutter SDK configured
- [ ] Environment variables set (.env file)
- [ ] Backend server running
- [ ] Device connected and recognized
- [ ] Clean build (`flutter clean`)

### Build Process
- [ ] Get dependencies (`flutter pub get`)
- [ ] Analyze code (`flutter analyze`)
- [ ] Run tests (`flutter test`)
- [ ] Build APK (`flutter build apk --release`)
- [ ] Verify APK size (< 50MB recommended)
- [ ] Test on device (`flutter run --release`)

### Post-Deployment
- [ ] Verify app launches
- [ ] Test API connectivity
- [ ] Test all major features
- [ ] Check performance
- [ ] Test offline functionality
- [ ] Test on different devices

---

## Quick Commands Reference

```bash
# Start backend server
cd backend && source venv/bin/activate && python manage.py runserver 0.0.0.0:8000

# Build APK (debug)
cd frontend && flutter build apk --debug

# Build APK (release)
cd frontend && flutter build apk --release

# Run on device (debug)
cd frontend && flutter run -d <device-id>

# Run on device (release)
cd frontend && flutter run -d <device-id> --release

# Clean everything
cd frontend && flutter clean && rm -rf ~/.gradle/caches/

# Check connected devices
flutter devices

# View logs
flutter logs

# Take screenshot
flutter screenshot

# Install APK manually
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Environment Variables Reference

### Development (.env)
```bash
# Backend API URL
# Use 10.0.2.2 for Android emulator
# Use your local IP for physical device
API_BASE_URL=http://10.0.2.2:8000/api

# Or for physical device
API_BASE_URL=http://192.168.1.100:8000/api
```

### Production (.env)
```bash
# Production server URL
API_BASE_URL=https://your-domain.com/api

# Disable debug
DEBUG_MODE=false
```

---

## Troubleshooting Steps

### General Troubleshooting
1. Run `flutter doctor -v` and fix all issues
2. Run `flutter clean`
3. Delete `~/.gradle/caches/`
4. Run `flutter pub get`
5. Restart your computer
6. Try building again

### Log Analysis
```bash
# View Flutter build logs
flutter build apk --verbose

# View Gradle logs
cd android && ./gradlew assembleRelease --info

# View ADB logs
adb logcat | grep -i flutter
```

---

## Additional Resources

- **Flutter Documentation:** https://docs.flutter.dev/
- **Android Studio Setup:** https://developer.android.com/studio
- **Flutter Deployment:** https://docs.flutter.dev/deployment/android
- **Gradle Build Configuration:** https://docs.gradle.org/current/userguide/build_environment.html

---

**Document Version:** 1.0
**Last Updated:** [Current Date]
**Device Tested:** Pixel 10 Pro XL (Android 16, API 36)
**Flutter Version:** 3.24.5+
**Java Version:** OpenJDK 17+