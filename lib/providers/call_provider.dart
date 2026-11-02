import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/webrtc_config.dart';
import '../models/peer_user.dart';
import '../models/signaling_message.dart';
import '../services/signaling_service.dart';
import '../services/webrtc_service.dart';

enum CallState {
  idle,
  outgoingRinging,
  incomingRinging,
  connected,
  ended,
}

class CallProvider with ChangeNotifier {
  final SignalingService _signaling = SignalingService();
  final WebRTCService _webrtc = WebRTCService();

  StreamSubscription? _signalingMsgSub;
  StreamSubscription? _signalingStatusSub;
  StreamSubscription? _usersSub;
  Timer? _callDurationTimer;

  CallState _callState = CallState.idle;
  String? _activeSessionId;
  String? _remotePeerId;
  String? _remotePeerName;
  String? _callStatusMessage;
  int _callDurationSeconds = 0;

  List<PeerUser> _onlineUsers = [];
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  RTCPeerConnectionState? _peerConnectionState;
  RTCIceConnectionState? _iceConnectionState;

  // Getters
  CallState get callState => _callState;
  String? get activeSessionId => _activeSessionId;
  String? get remotePeerId => _remotePeerId;
  String? get remotePeerName => _remotePeerName;
  String? get callStatusMessage => _callStatusMessage;
  int get callDurationSeconds => _callDurationSeconds;
  List<PeerUser> get onlineUsers => _onlineUsers;
  ConnectionStatus get connectionStatus => _connectionStatus;
  RTCPeerConnectionState? get peerConnectionState => _peerConnectionState;
  RTCIceConnectionState? get iceConnectionState => _iceConnectionState;

  RTCVideoRenderer get localRenderer => _webrtc.localRenderer;
  RTCVideoRenderer get remoteRenderer => _webrtc.remoteRenderer;
  bool get hasRemoteVideo => _webrtc.hasRemoteVideo;
  bool get isMicMuted => _webrtc.isMicMuted;
  bool get isVideoOff => _webrtc.isVideoOff;
  bool get isFrontCamera => _webrtc.isFrontCamera;

  String get formattedDuration {
    final minutes = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> initialize() async {
    await _webrtc.initializeRenderers();

    _webrtc.onRemoteStream = (stream) {
      debugPrint('[CallProvider] Remote stream callback received! Video tracks: ${stream.getVideoTracks().length}');
      notifyListeners();
    };

    _webrtc.onIceCandidate = (candidate) {
      if (_activeSessionId != null && _remotePeerId != null) {
        _signaling.sendMessage(SignalingMessage(
          type: 'ice_candidate',
          sessionId: _activeSessionId,
          receiverId: _remotePeerId,
          candidate: candidate.toMap(),
        ));
      }
    };

    _webrtc.onConnectionStateChange = (state) {
      _peerConnectionState = state;
      notifyListeners();
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _callStatusMessage = 'انقطع الاتصال بالطرف الآخر';
        notifyListeners();
      }
    };

    _webrtc.onIceConnectionStateChange = (state) {
      _iceConnectionState = state;
      notifyListeners();
    };

    _signalingStatusSub = _signaling.statusStream.listen((status) {
      _connectionStatus = status;
      notifyListeners();
    });

    _usersSub = _signaling.usersStream.listen((users) {
      _onlineUsers = users;
      notifyListeners();
    });

    _signalingMsgSub = _signaling.messageStream.listen(_handleIncomingSignalingMessage);
  }

  void connectSignaling({
    required String host,
    required int port,
    required String userId,
    required String displayName,
  }) {
    final wsUrl = WebRTCConfig.getWebSocketUrl(host, port, userId, displayName);
    _signaling.connect(
      wsUrl: wsUrl,
      userId: userId,
      displayName: displayName,
    );
  }

  Future<bool> checkAndRequestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus.isGranted && micStatus.isGranted) {
      return true;
    } else {
      _callStatusMessage = 'يرجى منح أذونات الكاميرا والميكروفون للمتابعة';
      notifyListeners();
      return false;
    }
  }

  Future<void> startCall(PeerUser callee) async {
    final hasPermissions = await checkAndRequestPermissions();
    if (!hasPermissions) return;

    _remotePeerId = callee.userId;
    _remotePeerName = callee.displayName;
    _callState = CallState.outgoingRinging;
    _callStatusMessage = 'جارٍ الاتصال بـ ${callee.displayName}...';
    notifyListeners();

    _signaling.sendMessage(SignalingMessage(
      type: 'call_request',
      receiverId: callee.userId,
    ));
  }

  Future<void> acceptIncomingCall() async {
    final hasPermissions = await checkAndRequestPermissions();
    if (!hasPermissions) {
      rejectIncomingCall();
      return;
    }

    try {
      _callStatusMessage = 'جارٍ إعداد الاتصال...';
      notifyListeners();

      await _webrtc.startLocalMedia();
      await _webrtc.createPeerConnectionInstance();

      _signaling.sendMessage(SignalingMessage(
        type: 'call_response',
        sessionId: _activeSessionId,
        receiverId: _remotePeerId,
        accepted: true,
      ));

      _callState = CallState.connected;
      _startCallTimer();
      _callStatusMessage = 'المكالمة متصلة';
      notifyListeners();
    } catch (e) {
      debugPrint('[CallProvider] Error accepting call: $e');
      _callStatusMessage = 'فشل قبول المكالمة: $e';
      endCall();
    }
  }

  void rejectIncomingCall() {
    if (_activeSessionId != null && _remotePeerId != null) {
      _signaling.sendMessage(SignalingMessage(
        type: 'call_response',
        sessionId: _activeSessionId,
        receiverId: _remotePeerId,
        accepted: false,
        reason: 'تم رفض المكالمة من قبل المستخدم',
      ));
    }
    _resetCallState();
  }

  Future<void> endCall() async {
    if (_activeSessionId != null) {
      _signaling.sendMessage(SignalingMessage(
        type: 'call_ended',
        sessionId: _activeSessionId,
        receiverId: _remotePeerId,
        reason: 'تم إنهاء المكالمة',
      ));
    }
    await _resetCallState();
  }

  void toggleMicrophone() {
    _webrtc.toggleMicrophone();
    notifyListeners();
  }

  void toggleCamera() {
    _webrtc.toggleCamera();
    notifyListeners();
  }

  Future<void> switchCamera() async {
    await _webrtc.switchCamera();
    notifyListeners();
  }

  Future<void> _handleIncomingSignalingMessage(SignalingMessage msg) async {
    switch (msg.type) {
      case 'call_ringing':
        _activeSessionId = msg.sessionId;
        _callStatusMessage = 'رنين عند الطرف الآخر...';
        notifyListeners();
        break;

      case 'call_request':
        if (_callState == CallState.idle) {
          _activeSessionId = msg.sessionId;
          _remotePeerId = msg.senderId;
          _remotePeerName = msg.displayName ?? 'مستخدم غير معروف';
          _callState = CallState.incomingRinging;
          _callStatusMessage = 'مكالمة واردة من $_remotePeerName';
          notifyListeners();
        } else {
          // Reject as busy if already in call
          _signaling.sendMessage(SignalingMessage(
            type: 'call_busy',
            sessionId: msg.sessionId,
            receiverId: msg.senderId,
          ));
        }
        break;

      case 'call_response':
        if (msg.accepted == true) {
          _activeSessionId = msg.sessionId;
          _callState = CallState.connected;
          _callStatusMessage = 'تم قبول المكالمة، جارٍ التفاوض...';
          _startCallTimer();
          notifyListeners();

          // Caller initiates WebRTC offer
          await _webrtc.startLocalMedia();
          await _webrtc.createPeerConnectionInstance();
          final offer = await _webrtc.createOffer();

          _signaling.sendMessage(SignalingMessage(
            type: 'offer',
            sessionId: _activeSessionId,
            receiverId: _remotePeerId,
            sdp: offer.sdp,
            sdpType: offer.type,
          ));
        }
        break;

      case 'call_rejected':
        _callStatusMessage = msg.reason ?? 'تم رفض المكالمة';
        notifyListeners();
        Future.delayed(const Duration(seconds: 2), () => _resetCallState());
        break;

      case 'call_busy':
        _callStatusMessage = 'الطرف الآخر مشغول في مكالمة أخرى';
        notifyListeners();
        Future.delayed(const Duration(seconds: 2), () => _resetCallState());
        break;

      case 'call_timeout':
        _callStatusMessage = 'لم يتم الرد على المكالمة (انتهت المهلة)';
        notifyListeners();
        Future.delayed(const Duration(seconds: 2), () => _resetCallState());
        break;

      case 'offer':
        if (msg.sdp != null) {
          await _webrtc.setRemoteDescription(msg.sdp!, msg.sdpType ?? 'offer');
          final answer = await _webrtc.createAnswer();
          _signaling.sendMessage(SignalingMessage(
            type: 'answer',
            sessionId: _activeSessionId,
            receiverId: _remotePeerId,
            sdp: answer.sdp,
            sdpType: answer.type,
          ));
        }
        break;

      case 'answer':
        if (msg.sdp != null) {
          await _webrtc.setRemoteDescription(msg.sdp!, msg.sdpType ?? 'answer');
        }
        break;

      case 'ice_candidate':
        if (msg.candidate != null) {
          final candMap = msg.candidate!;
          final candStr = candMap['candidate'] as String?;
          if (candStr == null || candStr.trim().isEmpty) {
            debugPrint('[CallProvider] Skipping empty or end-of-candidates ICE candidate');
            break;
          }
          final sdpMid = candMap['sdpMid'] as String?;
          final rawMLine = candMap['sdpMLineIndex'] ?? candMap['sdpMlineIndex'];
          final int? sdpMLineIndex = rawMLine is int
              ? rawMLine
              : (rawMLine != null ? int.tryParse(rawMLine.toString()) : null);

          final candidate = RTCIceCandidate(
            candStr,
            sdpMid,
            sdpMLineIndex,
          );
          await _webrtc.addIceCandidate(candidate);
        }
        break;

      case 'call_ended':
        _callStatusMessage = msg.reason ?? 'انتهت المكالمة';
        notifyListeners();
        await _resetCallState();
        break;
    }
  }

  void _startCallTimer() {
    _callDurationTimer?.cancel();
    _callDurationSeconds = 0;
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDurationSeconds++;
      notifyListeners();
    });
  }

  Future<void> _resetCallState() async {
    _callDurationTimer?.cancel();
    _callDurationTimer = null;
    _callDurationSeconds = 0;
    _activeSessionId = null;
    _remotePeerId = null;
    _remotePeerName = null;
    _callState = CallState.idle;
    _peerConnectionState = null;
    _iceConnectionState = null;
    await _webrtc.disposeMediaAndConnection();
    notifyListeners();
  }

  @override
  void dispose() {
    _signalingMsgSub?.cancel();
    _signalingStatusSub?.cancel();
    _usersSub?.cancel();
    _callDurationTimer?.cancel();
    _signaling.dispose();
    _webrtc.fullDispose();
    super.dispose();
  }
}
