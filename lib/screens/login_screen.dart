import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/webrtc_config.dart';
import '../providers/call_provider.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userIdController = TextEditingController();
  final _displayNameController = TextEditingController();
  String _serverHost = WebRTCConfig.defaultHost;
  int _serverPort = WebRTCConfig.defaultPort;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverHost = prefs.getString(WebRTCConfig.keyServerHost) ??
          WebRTCConfig.defaultHost;
      _serverPort =
          prefs.getInt(WebRTCConfig.keyServerPort) ?? WebRTCConfig.defaultPort;
      _userIdController.text =
          prefs.getString(WebRTCConfig.keyUserId) ?? 'phone_a';
      _displayNameController.text =
          prefs.getString(WebRTCConfig.keyDisplayName) ?? 'الهاتف الأول (أ)';
    });
  }

  void _selectPreset(String id, String name) {
    setState(() {
      _userIdController.text = id;
      _displayNameController.text = name;
    });
  }

  Future<void> _handleConnect() async {
    final userId = _userIdController.text.trim();
    final displayName = _displayNameController.text.trim();

    if (userId.isEmpty || displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال معرّف واسم المستخدم')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(WebRTCConfig.keyUserId, userId);
    await prefs.setString(WebRTCConfig.keyDisplayName, displayName);

    if (mounted) {
      final callProvider = Provider.of<CallProvider>(context, listen: false);
      callProvider.connectSignaling(
        host: _serverHost,
        port: _serverPort,
        userId: userId,
        displayName: displayName,
      );

      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            myUserId: userId,
            myDisplayName: displayName,
            serverHost: _serverHost,
            serverPort: _serverPort,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('دخول مكالمات WebRTC',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.greenAccent),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadSavedSettings();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header icon & banner
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.greenAccent.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.videocam_rounded,
                    size: 56, color: Colors.greenAccent),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'اتصال فيديو محلي عبر Wi-Fi',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'سيرفر الإشارات: http://$_serverHost:$_serverPort',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
            const SizedBox(height: 32),

            // Quick device selection presets
            const Text(
              'اختر دور هذا الهاتف:',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _userIdController.text == 'phone_a'
                          ? const Color(0xFF059669)
                          : const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _userIdController.text == 'phone_a'
                              ? Colors.greenAccent
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    onPressed: () =>
                        _selectPreset('phone_a', 'الهاتف الأول (أ)'),
                    child: const Text('الهاتف الأول (أ)',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _userIdController.text == 'phone_b'
                          ? const Color(0xFF059669)
                          : const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _userIdController.text == 'phone_b'
                              ? Colors.greenAccent
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    onPressed: () =>
                        _selectPreset('phone_b', 'الهاتف الثاني (ب)'),
                    child: const Text('الهاتف الثاني (ب)',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form inputs
            TextField(
              controller: _userIdController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'معرّف الهاتف (User ID)',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                prefixIcon:
                    const Icon(Icons.fingerprint, color: Colors.greenAccent),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _displayNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'اسم الظهور (Display Name)',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                prefixIcon: const Icon(Icons.person, color: Colors.greenAccent),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 28),

            // Connect button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _handleConnect,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text('تسجيل الدخول والاتصال بالسيرفر',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // IP helper card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amberAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'تأكد أن الهاتف والكمبيوتر متصلان بنفس شبكة Wi-Fi، واضغط على أيقونة الإعدادات ⚙️ لتعديل عنوان IP الخاص بالكمبيوتر.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
