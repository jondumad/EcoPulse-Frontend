import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class CollaborationService {
  io.Socket? _socket;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  void connect(String baseUrl, String token) {
    if (_socket != null && _socket!.connected) {
      debugPrint('CollaborationService: Already connected, skipping.');
      return;
    }

    if (_socket != null) {
      debugPrint('CollaborationService: Socket exists, disposing old instance.');
      _socket!.dispose();
    }

    debugPrint('CollaborationService: Attempting to connect to $baseUrl');
    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket']) // Force websocket for better reliability
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('CollaborationService: CONNECTED successfully to $baseUrl');
      _eventController.add({'type': 'connection', 'status': 'connected'});
    });

    _socket!.onDisconnect((data) {
      debugPrint('CollaborationService: DISCONNECTED: $data');
      _eventController.add({'type': 'connection', 'status': 'disconnected'});
    });

    _socket!.onConnectError((err) {
      debugPrint('CollaborationService: CONNECTION ERROR: $err');
      _eventController.add({
        'type': 'connection_error',
        'error': err.toString(),
      });
    });

    _socket!.onConnectTimeout((data) {
      debugPrint('CollaborationService: CONNECTION TIMEOUT: $data');
    });

    _socket!.onError((err) {
      debugPrint('CollaborationService: SOCKET ERROR: $err');
    });

    _socket!.on('error', (err) {
      debugPrint('CollaborationService: PROTOCOL ERROR: $err');
    });

    // Listen to standard events from the protocol
    _socket!.on(
      'presence_update',
      (data) => _eventController.add({'type': 'presence_update', 'data': data}),
    );
    _socket!.on(
      'new_comment',
      (data) => _eventController.add({'type': 'new_comment', 'data': data}),
    );
    _socket!.on(
      'comment_updated',
      (data) => _eventController.add({'type': 'comment_updated', 'data': data}),
    );
    _socket!.on(
      'checklist_item_added',
      (data) =>
          _eventController.add({'type': 'checklist_item_added', 'data': data}),
    );
    _socket!.on(
      'checklist_item_updated',
      (data) => _eventController.add({
        'type': 'checklist_item_updated',
        'data': data,
      }),
    );

    _socket!.connect();
  }

  void joinMission(int missionId) {
    debugPrint('CollaborationService: Emitting join_mission for $missionId');
    _socket?.emit('join_mission', {'missionId': missionId});
  }

  void leaveMission(int missionId) {
    debugPrint('CollaborationService: Emitting leave_mission for $missionId');
    _socket?.emit('leave_mission', {'missionId': missionId});
  }

  void sendComment(int missionId, String content) {
    debugPrint('CollaborationService: Emitting send_comment');
    _socket?.emit('send_comment', {'missionId': missionId, 'content': content});
  }

  void togglePin(int missionId, int commentId, bool isPinned) {
    debugPrint('CollaborationService: Emitting toggle_pin');
    _socket?.emit('toggle_pin', {
      'missionId': missionId,
      'commentId': commentId,
      'isPinned': isPinned,
    });
  }

  void addChecklistItem(int missionId, String content) {
    debugPrint('CollaborationService: Emitting add_checklist_item');
    _socket?.emit('add_checklist_item', {
      'missionId': missionId,
      'content': content,
    });
  }

  void toggleChecklistItem(int missionId, int itemId, bool isCompleted) {
    debugPrint('CollaborationService: Emitting toggle_checklist_item');
    _socket?.emit('toggle_checklist_item', {
      'missionId': missionId,
      'itemId': itemId,
      'isCompleted': isCompleted,
    });
  }

  void dispose() {
    _socket?.dispose();
    _eventController.close();
  }
}
