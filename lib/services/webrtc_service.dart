import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../config/webrtc_config.dart';

typedef OnIceCandidateCallback = void Function(RTCIceCandidate candidate);
typedef OnConnectionStateCallback = void Function(RTCPeerConnectionState state);
typedef OnIceConnectionStateCallback = void Function(RTCIceConnectionState state);
typedef OnRemoteStreamCallback = void Function(MediaStream stream);

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  OnIceCandidateCallback? onIceCandidate;
  OnConnectionStateCallback? onConnectionStateChange;
  OnIceConnectionStateCallback? onIceConnectionStateChange;
  OnRemoteStreamCallback? onRemoteStream;

  bool _isMicMuted = false;
  bool _isVideoOff = false;
  bool _isFrontCamera = true;
  bool _isRemoteDescriptionSet = false;

  final List<RTCIceCandidate> _bufferedCandidates = [];

  bool get isMicMuted => _isMicMuted;
  bool get isVideoOff => _isVideoOff;
  bool get isFrontCamera => _isFrontCamera;

  bool get hasRemoteVideo {
    if (remoteRenderer.srcObject == null) return false;
    return remoteRenderer.srcObject!.getVideoTracks().isNotEmpty;
  }

  Future<void> initializeRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> startLocalMedia() async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia(WebRTCConfig.mediaConstraints);
      _localStream = stream;
      localRenderer.srcObject = _localStream;
      _isMicMuted = false;
      _isVideoOff = false;
      _isFrontCamera = true;
      try {
        await Helper.setSpeakerphoneOn(true);
      } catch (e) {
        debugPrint('[WebRTC] Note: Could not set speakerphone: $e');
      }
    } catch (e) {
      debugPrint('[WebRTC] Error acquiring local media: $e');
      rethrow;
    }
  }

  Future<void> createPeerConnectionInstance({Map<String, dynamic>? customIceConfig}) async {
    final iceConfig = customIceConfig ?? WebRTCConfig.defaultIceServers;
    _isRemoteDescriptionSet = false;
    _bufferedCandidates.clear();

    _peerConnection = await createPeerConnection(
      iceConfig,
      WebRTCConfig.peerConnectionConstraints,
    );

    // Add local tracks to peer connection
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    // ICE Candidate generation
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        onIceCandidate?.call(candidate);
      }
    };

    // Remote Stream Reception (Native Android WebRTC callback)
    _peerConnection!.onAddStream = (MediaStream stream) {
      debugPrint('[WebRTC] onAddStream received: ID=${stream.id}, audio=${stream.getAudioTracks().length}, video=${stream.getVideoTracks().length}');
      _remoteStream = stream;
      remoteRenderer.srcObject = _remoteStream;
      onRemoteStream?.call(_remoteStream!);
    };

    // Remote Track Reception (Unified Plan callback)
    _peerConnection!.onTrack = (RTCTrackEvent event) async {
      debugPrint('[WebRTC] onTrack received: kind=${event.track.kind}, streams=${event.streams.length}');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        onRemoteStream?.call(_remoteStream!);
      } else {
        // Fallback when streams list is empty in Unified Plan
        _remoteStream ??= await createLocalMediaStream('remote_stream_${DateTime.now().millisecondsSinceEpoch}');
        _remoteStream!.addTrack(event.track);
        remoteRenderer.srcObject = _remoteStream;
        onRemoteStream?.call(_remoteStream!);
      }
    };

    // Connection states
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('[WebRTC] PeerConnectionState: $state');
      onConnectionStateChange?.call(state);
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('[WebRTC] IceConnectionState: $state');
      onIceConnectionStateChange?.call(state);
    };
  }

  Future<RTCSessionDescription> createOffer() async {
    if (_peerConnection == null) throw Exception('PeerConnection not initialized');
    final offer = await _peerConnection!.createOffer(WebRTCConfig.sdpConstraints);
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer() async {
    if (_peerConnection == null) throw Exception('PeerConnection not initialized');
    final answer = await _peerConnection!.createAnswer(WebRTCConfig.sdpConstraints);
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  Future<void> setRemoteDescription(String sdp, String type) async {
    if (_peerConnection == null) throw Exception('PeerConnection not initialized');
    final description = RTCSessionDescription(sdp, type);
    await _peerConnection!.setRemoteDescription(description);
    _isRemoteDescriptionSet = true;
    debugPrint('[WebRTC] Remote description set ($type). Flushing buffered candidates (${_bufferedCandidates.length})...');

    // Flush any buffered candidates that arrived prior to remote description
    for (final candidate in _bufferedCandidates) {
      try {
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        debugPrint('[WebRTC] Error adding buffered candidate: $e');
      }
    }
    _bufferedCandidates.clear();
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) return;
    if (candidate.candidate == null || candidate.candidate!.trim().isEmpty) {
      debugPrint('[WebRTC] Skipping empty ICE candidate');
      return;
    }

    if (_isRemoteDescriptionSet) {
      try {
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        debugPrint('[WebRTC] Error adding ICE candidate: $e');
      }
    } else {
      debugPrint('[WebRTC] Remote description not set yet. Buffering ICE candidate.');
      _bufferedCandidates.add(candidate);
    }
  }

  void toggleMicrophone() {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        _isMicMuted = !_isMicMuted;
        for (var track in audioTracks) {
          track.enabled = !_isMicMuted;
        }
      }
    }
  }

  void toggleCamera() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        _isVideoOff = !_isVideoOff;
        for (var track in videoTracks) {
          track.enabled = !_isVideoOff;
        }
      }
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        final track = videoTracks[0];
        try {
          await Helper.switchCamera(track);
          _isFrontCamera = !_isFrontCamera;
        } catch (e) {
          debugPrint('[WebRTC] Failed to switch camera: $e');
        }
      }
    }
  }

  Future<void> disposeMediaAndConnection() async {
    try {
      _bufferedCandidates.clear();
      _isRemoteDescriptionSet = false;

      // Stop all tracks in local stream
      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          await track.stop();
        }
        await _localStream!.dispose();
        _localStream = null;
      }

      // Clear renderers
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;

      // Close peer connection
      if (_peerConnection != null) {
        await _peerConnection!.close();
        await _peerConnection!.dispose();
        _peerConnection = null;
      }

      _remoteStream = null;
      debugPrint('[WebRTC] Resources cleanly released.');
    } catch (e) {
      debugPrint('[WebRTC] Error during cleanup: $e');
    }
  }

  Future<void> fullDispose() async {
    await disposeMediaAndConnection();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
  }
}
