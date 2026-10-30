import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/call_provider.dart';

class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Incoming call badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.emeraldAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.emeraldAccent.withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.ring_volume, color: Colors.emeraldAccent, size: 18),
                          SizedBox(width: 8),
                          Text('مكالمة فيديو واردة...', style: TextStyle(color: Colors.emeraldAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Caller avatar
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.25),
                            blurRadius: 30,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person, size: 80, color: Colors.white),
                    ),
                    const SizedBox(height: 28),

                    // Caller name
                    Text(
                      provider.remotePeerName ?? 'متصل مجهول',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'مكالمة فيديو عبر الشبكة المحلية (Wi-Fi)',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 64),

                    // Action buttons: Reject vs Accept
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Reject button
                        Column(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(22),
                                elevation: 8,
                              ),
                              onPressed: () => provider.rejectIncomingCall(),
                              child: const Icon(Icons.call_end, size: 36, color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            const Text('رفض', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),

                        // Accept button
                        Column(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(22),
                                elevation: 8,
                              ),
                              onPressed: () => provider.acceptIncomingCall(),
                              child: const Icon(Icons.videocam_rounded, size: 36, color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            const Text('قبول بالفيديو', style: TextStyle(color: Colors.emeraldAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
