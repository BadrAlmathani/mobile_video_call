import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../providers/call_provider.dart';

class ActiveCallScreen extends StatelessWidget {
  const ActiveCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Remote Video (Full Screen Background)
              _buildRemoteVideoView(provider),

              // 2. Floating Local Camera Preview (Picture-in-Picture in Top-Right)
              Positioned(
                top: 48,
                left: 16, // RTL layout places PiP on the left
                child: _buildLocalPipPreview(provider),
              ),

              // 3. Top Call Info Overlay (Duration & ICE Status)
              Positioned(
                top: 48,
                right: 16,
                child: _buildTopCallHeader(provider),
              ),

              // 4. Bottom Controls Floating Pill
              Positioned(
                bottom: 32,
                left: 20,
                right: 20,
                child: _buildBottomControlToolbar(provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRemoteVideoView(CallProvider provider) {
    // Check if remote stream is assigned
    final hasRemoteVideo = provider.remoteRenderer.srcObject != null &&
        provider.remoteRenderer.srcObject!.getVideoTracks().isNotEmpty;

    if (hasRemoteVideo) {
      return RTCVideoView(
        provider.remoteRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    }

    // Waiting for video or audio-only fallback
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.emeraldAccent.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.emeraldAccent.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.videocam_rounded, size: 72, color: Colors.emeraldAccent),
            ),
            const SizedBox(height: 20),
            Text(
              provider.remotePeerName ?? 'الطرف الآخر',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.emeraldAccent),
                ),
                SizedBox(width: 10),
                Text('جارٍ استقبال مسار الفيديو البعيد...', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalPipPreview(CallProvider provider) {
    return Container(
      width: 110,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.emeraldAccent.withOpacity(0.6), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 12, spreadRadius: 2),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!provider.isVideoOff && provider.localRenderer.srcObject != null)
            RTCVideoView(
              provider.localRenderer,
              mirror: provider.isFrontCamera,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            Container(
              color: const Color(0xFF1E293B),
              child: const Center(
                child: Icon(Icons.videocam_off_rounded, color: Colors.grey, size: 32),
              ),
            ),
          
          // Badge on PiP
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('أنت', style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCallHeader(CallProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                provider.formattedDuration,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi, size: 12, color: Colors.emeraldAccent),
              const SizedBox(width: 4),
              Text(
                'شبكة محلية Wi-Fi',
                style: TextStyle(fontSize: 10, color: Colors.grey[300]),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomControlToolbar(CallProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.92),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 20, spreadRadius: 4),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute Mic toggle
          _buildToolButton(
            icon: provider.isMicMuted ? Icons.mic_off : Icons.mic,
            label: provider.isMicMuted ? 'مكتوم' : 'الميكروفون',
            color: provider.isMicMuted ? Colors.redAccent : Colors.white,
            bgColor: provider.isMicMuted ? Colors.redAccent.withOpacity(0.2) : Colors.white12,
            onPressed: () => provider.toggleMicrophone(),
          ),

          // Camera On/Off toggle
          _buildToolButton(
            icon: provider.isVideoOff ? Icons.videocam_off : Icons.videocam,
            label: provider.isVideoOff ? 'مغلقة' : 'الكاميرا',
            color: provider.isVideoOff ? Colors.redAccent : Colors.white,
            bgColor: provider.isVideoOff ? Colors.redAccent.withOpacity(0.2) : Colors.white12,
            onPressed: () => provider.toggleCamera(),
          ),

          // Switch Front/Back camera
          _buildToolButton(
            icon: Icons.flip_camera_ios,
            label: 'تبديل',
            color: Colors.white,
            bgColor: Colors.white12,
            onPressed: () => provider.switchCamera(),
          ),

          // End Call button (Prominent Red)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
              elevation: 4,
            ),
            onPressed: () => provider.endCall(),
            child: const Icon(Icons.call_end, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
