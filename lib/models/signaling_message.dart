class SignalingMessage {
  final String type;
  final String? senderId;
  final String? receiverId;
  final String? sessionId;
  final String? displayName;
  final bool? accepted;
  final String? reason;
  final String? sdp;
  final String? sdpType;
  final Map<String, dynamic>? candidate;
  final Map<String, dynamic>? payload;
  final double? timestamp;

  SignalingMessage({
    required this.type,
    this.senderId,
    this.receiverId,
    this.sessionId,
    this.displayName,
    this.accepted,
    this.reason,
    this.sdp,
    this.sdpType,
    this.candidate,
    this.payload,
    this.timestamp,
  });

  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    return SignalingMessage(
      type: json['type'] as String,
      senderId: json['sender_id'] as String?,
      receiverId: json['receiver_id'] as String?,
      sessionId: json['session_id'] as String?,
      displayName: json['display_name'] as String?,
      accepted: json['accepted'] as bool?,
      reason: json['reason'] as String?,
      sdp: json['sdp'] as String?,
      sdpType: json['sdp_type'] as String?,
      candidate: json['candidate'] != null ? Map<String, dynamic>.from(json['candidate']) : null,
      payload: json['payload'] != null ? Map<String, dynamic>.from(json['payload']) : null,
      timestamp: (json['timestamp'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'type': type};
    if (senderId != null) data['sender_id'] = senderId;
    if (receiverId != null) data['receiver_id'] = receiverId;
    if (sessionId != null) data['session_id'] = sessionId;
    if (displayName != null) data['display_name'] = displayName;
    if (accepted != null) data['accepted'] = accepted;
    if (reason != null) data['reason'] = reason;
    if (sdp != null) data['sdp'] = sdp;
    if (sdpType != null) data['sdp_type'] = sdpType;
    if (candidate != null) data['candidate'] = candidate;
    if (payload != null) data['payload'] = payload;
    if (timestamp != null) data['timestamp'] = timestamp;
    return data;
  }
}
