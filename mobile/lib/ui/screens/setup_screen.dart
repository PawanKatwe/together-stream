import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../services/update_service.dart';
import 'room_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _urlController = TextEditingController(text: AppConfig.tokenServerUrl);

  @override
  void initState() {
    super.initState();
    _initDefaultsAndCheckUpdates();
  }

  Future<void> _initDefaultsAndCheckUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('token_server_url');
    // If empty or pointing to obsolete localhost / trycloudflare test tunnel, auto-reset to 24/7 Render cloud
    if (saved == null || saved.isEmpty || saved.contains('trycloudflare') || saved.contains('localhost')) {
      _urlController.text = AppConfig.tokenServerUrl;
      await prefs.setString('token_server_url', AppConfig.tokenServerUrl);
    } else {
      _urlController.text = saved;
    }

    // Check for updates
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final update = await UpdateService.checkForUpdate();
      if (update != null && mounted) {
        UpdateService.showUpdateDialog(context, update);
      }
    });
  }

  Future<void> _selectIdentity(String identity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_identity', identity);
    await prefs.setString('token_server_url', _urlController.text.trim());

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RoomScreen(
          myIdentity: identity,
          serverUrl: _urlController.text.trim(),
        ),
      ),
    );
  }

  void _showServerSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Token Server Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'https://together-stream.onrender.com',
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Save URL'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _urlController.text = AppConfig.tokenServerUrl;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Reset to Cloud (onrender.com)',
                    style: TextStyle(color: AppTheme.primaryRose),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Checking for updates...')),
                    );
                    final update = await UpdateService.checkForUpdate();
                    if (!mounted) return;
                    if (update != null) {
                      UpdateService.showUpdateDialog(context, update);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('TogetherStream is up to date (v${UpdateService.currentVersion}) ❤️'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('Check for Updates'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TogetherStream'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.textSecondary),
            onPressed: _showServerSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Heart Brand Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRose.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 48,
                  color: AppTheme.primaryRose,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Our Cinema',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Who is using this phone today?',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 40),

              // Pawan Card
              _UserChoiceCard(
                name: AppConfig.userPawan,
                subtitle: 'Realme 9 Pro+',
                avatarColor: AppTheme.primaryRose,
                onTap: () => _selectIdentity(AppConfig.userPawan),
              ),
              const SizedBox(height: 16),

              // Priya Card
              _UserChoiceCard(
                name: AppConfig.userPriya,
                subtitle: 'Realme 9',
                avatarColor: AppTheme.lavenderAccent,
                onTap: () => _selectIdentity(AppConfig.userPriya),
              ),
              const SizedBox(height: 32),

              Text(
                'Private Room: ${AppConfig.roomName}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserChoiceCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final Color avatarColor;
  final VoidCallback onTap;

  const _UserChoiceCard({
    required this.name,
    required this.subtitle,
    required this.avatarColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: avatarColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: avatarColor.withOpacity(0.2),
              child: Text(
                name[0],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: avatarColor,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'I am $name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: avatarColor.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}
