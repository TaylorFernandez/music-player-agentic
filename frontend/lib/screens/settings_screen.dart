import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';
import 'content_screen.dart';

/// Settings screen for app configuration and user preferences.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  bool _autoPlay = true;
  double _crossfadeDuration = 2.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // TODO: Load settings from shared preferences
    // For now, use default values
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: AppTheme.cardDark,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: SafeArea(
          child: Text(
            'Settings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.deepSpaceGradient,
        ),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // User Profile Section
                if (authProvider.isAuthenticated) ...[
                  _buildUserProfileSection(authProvider, context),
                  const SizedBox(height: 8),
                ],
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 16),

                // Account Section
                _buildSectionHeader('Account'),
                const SizedBox(height: 8),
                if (authProvider.isAuthenticated) ...[
                  _buildSettingsTile(
                    icon: Icons.person,
                    title: 'Profile',
                    subtitle: 'Manage your profile information',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.security,
                    title: 'Privacy & Security',
                    subtitle: 'Manage your privacy settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContentScreen(
                            title: 'Privacy & Security',
                            content: 'Privacy and security configuration options will appear here.',
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  _buildSettingsTile(
                    icon: Icons.login,
                    title: 'Login',
                    subtitle: 'Sign in to sync your data',
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AuthScreen(),
                        ),
                      );

                      if (result == true && mounted) {
                        setState(() {});
                      }
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 16),

                // Appearance Section
                _buildSectionHeader('Appearance'),
                const SizedBox(height: 8),
                _buildSettingsTile(
                  icon: Icons.palette,
                  title: 'Theme',
                  subtitle: _getThemeModeText(),
                  onTap: () => _showThemeDialog(),
                ),
                _buildSwitchTile(
                  icon: Icons.dark_mode,
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme',
                  value: _themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    setState(() {
                      _themeMode = value ? ThemeMode.dark : ThemeMode.light;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 16),

                // Playback Section
                _buildSectionHeader('Playback'),
                const SizedBox(height: 8),
                _buildSwitchTile(
                  icon: Icons.play_circle,
                  title: 'Auto-play',
                  subtitle: 'Automatically play similar songs',
                  value: _autoPlay,
                  onChanged: (value) {
                    setState(() {
                      _autoPlay = value;
                    });
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.swap_horiz,
                  title: 'Crossfade',
                  subtitle: '${_crossfadeDuration.toInt()} seconds',
                  onTap: () => _showCrossfadeDialog(),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 16),

                // Notifications Section
                _buildSectionHeader('Notifications'),
                const SizedBox(height: 8),
                _buildSwitchTile(
                  icon: Icons.notifications,
                  title: 'Enable Notifications',
                  subtitle: 'Receive updates about new releases',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 16),

                // About Section
                _buildSectionHeader('About'),
                const SizedBox(height: 8),
                _buildSettingsTile(
                  icon: Icons.info,
                  title: 'About Music Player',
                  subtitle: 'Version 1.0.0',
                  onTap: () => _showAboutDialog(),
                ),
                _buildSettingsTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContentScreen(
                          title: 'Privacy Policy',
                          content: 'Our privacy policy details how we handle your data. We do not store your MP3 files; we only use metadata to enhance your music experience.',
                        ),
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.description,
                  title: 'Terms of Service',
                  subtitle: 'Read our terms of service',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContentScreen(
                          title: 'Terms of Service',
                          content: 'By using this app, you agree to our terms of service. This app is for personal music playback and metadata enrichment.',
                        ),
                      ),
                    );
                  },
                ),
                // Logout Button
                if (authProvider.isAuthenticated) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showLogoutDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor.withOpacity(0.2),
                        foregroundColor: AppTheme.errorColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildUserProfileSection(AuthProvider authProvider, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppTheme.sunsetGlowGradient,
              shape: BoxShape.circle,
            ),
            child: authProvider.currentUser?['avatar_url'] != null
                ? ClipOval(
                    child: Image.network(
                      authProvider.currentUser!['avatar_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, size: 32, color: Colors.white);
                      },
                    ),
                  )
                : const Icon(Icons.person, size: 32, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.currentUser?['username'] ?? 'User',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.currentUser?['email'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    authProvider.userRole?.toUpperCase() ?? 'GENERAL',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryColor,
              activeTrackColor: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeModeText() {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Choose Theme', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System default', style: TextStyle(color: Colors.white)),
              value: ThemeMode.system,
              groupValue: _themeMode,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                setState(() {
                  _themeMode = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light', style: TextStyle(color: Colors.white)),
              value: ThemeMode.light,
              groupValue: _themeMode,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                setState(() {
                  _themeMode = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark', style: TextStyle(color: Colors.white)),
              value: ThemeMode.dark,
              groupValue: _themeMode,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                setState(() {
                  _themeMode = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCrossfadeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Crossfade Duration', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set the crossfade duration between songs',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) {
                return SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
                    thumbColor: AppTheme.primaryColor,
                    overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _crossfadeDuration,
                    min: 0,
                    max: 12,
                    divisions: 12,
                    label: '${_crossfadeDuration.toInt()} sec',
                    onChanged: (value) {
                      setState(() {
                        _crossfadeDuration = value;
                      });
                    },
                  ),
                );
              },
            ),
            Text(
              '${_crossfadeDuration.toInt()} seconds',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Crossfade set to ${_crossfadeDuration.toInt()} seconds'),
                  backgroundColor: AppTheme.cardDark,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About Music Player', style: TextStyle(color: Colors.white)),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Music Player App',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text('Version: 1.0.0', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 16),
              Text(
                'An intelligent MP3 player that connects to a server to enrich '
                'your music experience. The app uses metadata from local MP3 files '
                'to identify songs and retrieve additional information from a '
                'centralized database.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text('• Basic MP3 playback', style: TextStyle(color: Colors.white70)),
              Text('• Server integration for metadata', style: TextStyle(color: Colors.white70)),
              Text('• Lyrics and artwork display', style: TextStyle(color: Colors.white70)),
              Text('• Playlist management', style: TextStyle(color: Colors.white70)),
              Text('• Role-based access control', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }
}
