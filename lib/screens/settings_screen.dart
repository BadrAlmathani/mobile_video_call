import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/webrtc_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();

  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final host = await WebRTCConfig.getServerHost();
    final port = await WebRTCConfig.getServerPort();
    setState(() {
      _hostController.text = host;
      _portController.text = port.toString();
    });
  }

  Future<void> _testConnection() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? WebRTCConfig.defaultPort;

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final url = WebRTCConfig.getHealthUrl(host, port);
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ips = (data['local_ips'] as List? ?? []).join(', ');
        setState(() {
          _testSuccess = true;
          _testResult = 'تم الاتصال بالسيرفر بنجاح!\nالحالة: ${data['status']}\nعناوين السيرفر: $ips';
        });
      } else {
        setState(() {
          _testSuccess = false;
          _testResult = 'فشل الاتصال: كود الرد ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testResult = 'تعذر الوصول إلى $url\nتأكد من أن السيرفر يعمل وجدار الحماية يسمح بالمنفذ $port.';
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _save() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? WebRTCConfig.defaultPort;

    await WebRTCConfig.saveServerSettings(host, port);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('إعدادات الاتصال والشبكة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.router_rounded, color: Colors.emeraldAccent, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'يجب أن يكون الهاتف والكمبيوتر متصلين بنفس شبكة Wi-Fi المحلية.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Host IPv4 Field
            TextField(
              controller: _hostController,
              keyboardType: TextInputType.url,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'عنوان IP للكمبيوتر (IPv4)',
                hintText: 'مثال: 192.168.1.50',
                hintStyle: TextStyle(color: Colors.grey[600]),
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                prefixIcon: const Icon(Icons.computer, color: Colors.emeraldAccent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Port Field
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'منفذ السيرفر (Port)',
                hintText: '8000',
                hintStyle: TextStyle(color: Colors.grey[600]),
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                prefixIcon: const Icon(Icons.numbers, color: Colors.emeraldAccent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Test button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.emeraldAccent,
                side: const BorderSide(color: Colors.emeraldAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isTesting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.emeraldAccent))
                  : const Icon(Icons.network_check_rounded),
              label: const Text('فحص الاتصال بالسيرفر الآن'),
              onPressed: _isTesting ? null : _testConnection,
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _testSuccess ? Colors.emerald.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _testSuccess ? Colors.emeraldAccent : Colors.redAccent),
                ),
                child: Text(
                  _testResult!,
                  style: TextStyle(
                    color: _testSuccess ? Colors.emeraldAccent : Colors.redAccent,
                    fontSize: 13,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _save,
              child: const Text('حفظ الإعدادات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
