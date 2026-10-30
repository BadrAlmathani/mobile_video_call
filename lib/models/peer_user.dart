class PeerUser {
  final String userId;
  final String displayName;
  final String deviceInfo;
  final String status; // 'idle' | 'ringing' | 'in_call'

  PeerUser({
    required this.userId,
    required this.displayName,
    required this.deviceInfo,
    required this.status,
  });

  factory PeerUser.fromJson(Map<String, dynamic> json) {
    return PeerUser(
      userId: json['user_id'] ?? '',
      displayName: json['display_name'] ?? 'مستخدم',
      deviceInfo: json['device_info'] ?? 'هاتف أندرويد',
      status: json['status'] ?? 'idle',
    );
  }

  bool get isIdle => status == 'idle';
  bool get isBusy => status != 'idle';
}
