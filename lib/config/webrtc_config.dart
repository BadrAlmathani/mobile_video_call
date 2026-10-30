import 'package:shared_preferences/shared_preferences.dart';

class WebRTCConfig {
  static const String defaultHost = '192.168.1.10'; // Default placeholder, user configures actual IP
  static const int defaultPort = 8000;
  
  static const String keyServerHost = 'key_server_host';
  static const String keyServerPort = 'key_server_port';
  static const String keyUserId = 'key_user_id';
  static const String keyDisplayName = 'key_display_name';

  // WebRTC ICE Servers Configuration:
  // In local Wi-Fi, Direct LAN Host candidates connect without external servers.
  // Google public STUN is added for NAT discovery if needed.
  // Ready to plug in Coturn TURN credentials for future WAN/Internet migration.
  static Map<String, dynamic> defaultIceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  // PeerConnection constraints
  static final Map<String, dynamic> peerConnectionConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  // Media constraints for local camera and mic
  static final Map<String, dynamic> mediaConstraints = {
    'audio': {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
    },
    'video': {
      'mandatory': {
        'minWidth': '640',
        'minHeight': '480',
        'minFrameRate': '30',
      },
      'facingMode': 'user',
      'optional': [],
    }
  };

  static Future<String> getServerHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyServerHost) ?? defaultHost;
  }

  static Future<int> getServerPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyServerPort) ?? defaultPort;
  }

  static Future<void> saveServerSettings(String host, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyServerHost, host.trim());
    await prefs.setInt(keyServerPort, port);
  }

  static String getWebSocketUrl(String host, int port, String userId, String displayName) {
    final cleanHost = host.replaceAll('http://', '').replaceAll('https://', '').replaceAll('ws://', '').replaceAll('wss://', '').trim();
    return 'ws://$cleanHost:$port/ws/$userId?name=${Uri.encodeComponent(displayName)}&device=AndroidApp';
  }

  static String getHealthUrl(String host, int port) {
    final cleanHost = host.replaceAll('http://', '').replaceAll('https://', '').replaceAll('ws://', '').replaceAll('wss://', '').trim();
    return 'http://$cleanHost:$port/health';
  }
}
