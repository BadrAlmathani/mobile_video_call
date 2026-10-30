import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/peer_user.dart';
import '../models/signaling_message.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class SignalingService {
  WebSocketChannel? _channel;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  String? _currentUrl;
  String? _myUserId;
  String? _myDisplayName;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _usersController = StreamController<List<PeerUser>>.broadcast();
  final _messageController = StreamController<SignalingMessage>.broadcast();

  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  Stream<List<PeerUser>> get usersStream => _usersController.stream;
  Stream<SignalingMessage> get messageStream => _messageController.stream;
  ConnectionStatus get status => _status;

  void connect({
    required String wsUrl,
    required String userId,
    required String displayName,
  }) {
    _currentUrl = wsUrl;
    _myUserId = userId;
    _myDisplayName = displayName;

    _disconnectInternal();
    _updateStatus(ConnectionStatus.connecting);

    try {
      debugPrint('[Signaling] Connecting to: $wsUrl');
      final uri = Uri.parse(wsUrl);
      _channel = IOWebSocketChannel.connect(
        uri,
        pingInterval: const Duration(seconds: 15),
      );

      _channel!.stream.listen(
        (data) => _onMessageReceived(data),
        onDone: () => _onDisconnected(),
        onError: (err) => _onError(err),
        cancelOnError: true,
      );

      _updateStatus(ConnectionStatus.connected);
      _startHeartbeat();
    } catch (e) {
      debugPrint('[Signaling] Connection failed: $e');
      _onError(e);
    }
  }

  void _onMessageReceived(dynamic data) {
    try {
      final decoded = json.decode(data as String) as Map<String, dynamic>;
      final msg = SignalingMessage.fromJson(decoded);

      if (msg.type == 'user_list' && msg.payload != null) {
        final list = (msg.payload!['users'] as List? ?? [])
            .map((u) => PeerUser.fromJson(Map<String, dynamic>.from(u)))
            .where((u) => u.userId != _myUserId)
            .toList();
        _usersController.add(list);
      } else if (msg.type == 'pong') {
        // Heartbeat ACK
      } else {
        _messageController.add(msg);
      }
    } catch (e) {
      debugPrint('[Signaling] Error parsing incoming message: $e');
    }
  }

  void sendMessage(SignalingMessage message) {
    if (_channel != null && _status == ConnectionStatus.connected) {
      try {
        final jsonStr = json.encode(message.toJson());
        _channel!.sink.add(jsonStr);
      } catch (e) {
        debugPrint('[Signaling] Error sending message: $e');
      }
    } else {
      debugPrint('[Signaling] Cannot send message, WebSocket not connected.');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (_status == ConnectionStatus.connected) {
        sendMessage(SignalingMessage(type: 'ping', senderId: _myUserId));
      }
    });
  }

  void _onDisconnected() {
    debugPrint('[Signaling] WebSocket closed.');
    _disconnectInternal();
    _updateStatus(ConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _onError(dynamic error) {
    debugPrint('[Signaling] WebSocket error: $error');
    _disconnectInternal();
    _updateStatus(ConnectionStatus.error);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_currentUrl != null && _myUserId != null && _myDisplayName != null) {
      _reconnectTimer = Timer(const Duration(seconds: 4), () {
        debugPrint('[Signaling] Attempting auto-reconnect...');
        connect(
          wsUrl: _currentUrl!,
          userId: _myUserId!,
          displayName: _myDisplayName!,
        );
      });
    }
  }

  void _disconnectInternal() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void disconnect() {
    _currentUrl = null;
    _reconnectTimer?.cancel();
    _disconnectInternal();
    _updateStatus(ConnectionStatus.disconnected);
  }

  void _updateStatus(ConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(_status);
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _usersController.close();
    _messageController.close();
  }
}
