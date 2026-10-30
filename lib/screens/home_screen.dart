import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/peer_user.dart';
import '../providers/call_provider.dart';
import '../services/signaling_service.dart';
import 'active_call_screen.dart';
import 'incoming_call_screen.dart';
import 'outgoing_call_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final String myUserId;
  final String myDisplayName;
  final String serverHost;
  final int serverPort;

  const HomeScreen({
    super.key,
    required this.myUserId,
    required this.myDisplayName,
    required this.serverHost,
    required this.serverPort,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, provider, child) {
        // Automatic state-driven navigation transitions
        if (provider.callState == CallState.outgoingRinging) {
          return const OutgoingCallScreen();
        } else if (provider.callState == CallState.incomingRinging) {
          return const IncomingCallScreen();
        } else if (provider.callState == CallState.connected) {
          return const ActiveCallScreen();
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            elevation: 2,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(myDisplayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('ID: $myUserId', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            actions: [
              _buildConnectionBadge(provider.connectionStatus),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              provider.connectSignaling(
                host: serverHost,
                port: serverPort,
                userId: myUserId,
                displayName: myDisplayName,
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Server connection card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.wifi, color: Colors.blueAccent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('سيرفر الإشارات المحلي', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('ws://$serverHost:$serverPort/ws', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Peers section title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الأجهزة المتصلة على نفس الشبكة:',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      '(${provider.onlineUsers.length} جهاز)',
                      style: const TextStyle(fontSize: 13, color: Colors.emeraldAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Peers list
                if (provider.onlineUsers.isEmpty)
                  _buildEmptyPeersCard(context)
                else
                  ...provider.onlineUsers.map((peer) => _buildPeerCard(context, peer, provider)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionBadge(ConnectionStatus status) {
    Color color;
    String label;
    switch (status) {
      case ConnectionStatus.connected:
        color = Colors.emeraldAccent;
        label = 'متصل';
        break;
      case ConnectionStatus.connecting:
        color = Colors.amberAccent;
        label = 'جارٍ الاتصال';
        break;
      default:
        color = Colors.redAccent;
        label = 'غير متصل';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyPeersCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Icon(Icons.phonelink_ring_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'لا يوجد أجهزة أخرى متصلة حالياً',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'افتح التطبيق على الهاتف الثاني وتأكد من اتصاله بنفس شبكة Wi-Fi وسيرفر الإشارات المحلي ليظهر هنا فوراً.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerCard(BuildContext context, PeerUser peer, CallProvider provider) {
    final isIdle = peer.isIdle;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isIdle ? Colors.emeraldAccent.withOpacity(0.2) : Colors.amberAccent.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isIdle ? const Color(0xFF059669).withOpacity(0.2) : Colors.amber.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_android_rounded,
              color: isIdle ? Colors.emeraldAccent : Colors.amberAccent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.displayName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isIdle ? Colors.emeraldAccent : Colors.amberAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isIdle ? 'جاهز للمكالمة' : 'مشغول في مكالمة',
                      style: TextStyle(
                        fontSize: 12,
                        color: isIdle ? Colors.emeraldAccent : Colors.amberAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isIdle ? const Color(0xFF10B981) : Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
            label: const Text('اتصال', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: isIdle ? () => provider.startCall(peer) : null,
          ),
        ],
      ),
    );
  }
}
