import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../services/collaboration_service.dart';
import '../models/user_model.dart';
import '../models/mission_model.dart';
import 'auth_provider.dart';
import 'package:dio/dio.dart';

class MissionComment {
  final int id;
  final int missionId;
  final int userId;
  final String content;
  final bool isPinned;
  final DateTime createdAt;
  final String userName;

  MissionComment({
    required this.id,
    required this.missionId,
    required this.userId,
    required this.content,
    required this.isPinned,
    required this.createdAt,
    required this.userName,
  });

  factory MissionComment.fromJson(Map<String, dynamic> json) {
    return MissionComment(
      id: json['id'],
      missionId: json['missionId'],
      userId: json['userId'],
      content: json['content'],
      isPinned: json['isPinned'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      userName: json['user']?['name'] ?? 'Unknown',
    );
  }
}

class MissionChecklistItem {
  final int id;
  final int missionId;
  final String content;
  final bool isCompleted;
  final int? completedBy;

  MissionChecklistItem({
    required this.id,
    required this.missionId,
    required this.content,
    required this.isCompleted,
    this.completedBy,
  });

  factory MissionChecklistItem.fromJson(Map<String, dynamic> json) {
    return MissionChecklistItem(
      id: json['id'],
      missionId: json['missionId'],
      content: json['content'],
      isCompleted: json['isCompleted'] ?? false,
      completedBy: json['completedBy'],
    );
  }
}

class CollaborationProvider with ChangeNotifier {
  final CollaborationService _service = CollaborationService();

  // Expose socket for direct usage
  io.Socket? get socket => _service.socket;

  AuthProvider _authProvider;
  AuthProvider get authProvider => _authProvider;
  final String baseUrl;

  List<Map<String, dynamic>> activeUsers = [];
  List<MissionComment> comments = [];
  List<MissionChecklistItem> checklist = [];
  bool isConnected = false;
  String? lastError;
  int? currentMissionId;

  CollaborationProvider({
    required AuthProvider authProvider,
    required this.baseUrl,
  }) : _authProvider = authProvider {
    _service.eventStream.listen(_handleSocketEvent);
  }

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
  }

  void _handleSocketEvent(Map<String, dynamic> event) {
    debugPrint('CollaborationProvider: Received event type: ${event['type']}');
    switch (event['type']) {
      case 'connection':
        isConnected = event['status'] == 'connected';
        if (isConnected) lastError = null;
        debugPrint('CollaborationProvider: Connection status: $isConnected');
        if (isConnected && currentMissionId != null) {
          debugPrint(
            'CollaborationProvider: Auto-joining room $currentMissionId on connection',
          );
          _service.joinMission(currentMissionId!);
        }
        notifyListeners();
        break;
      case 'connection_error':
        isConnected = false;
        lastError = event['error'];
        debugPrint('CollaborationProvider: Connection error: $lastError');
        notifyListeners();
        break;
      case 'presence_update':
        activeUsers = List<Map<String, dynamic>>.from(event['data']);
        notifyListeners();
        break;
      case 'new_comment':
        debugPrint('CollaborationProvider: New comment received');
        comments.insert(0, MissionComment.fromJson(event['data']));
        notifyListeners();
        break;
      case 'comment_updated':
        final updatedComment = MissionComment.fromJson(event['data']);
        final index = comments.indexWhere((c) => c.id == updatedComment.id);
        if (index != -1) {
          comments[index] = updatedComment;
          notifyListeners();
        }
        break;
      case 'checklist_item_added':
        debugPrint('CollaborationProvider: New checklist item received');
        checklist.add(MissionChecklistItem.fromJson(event['data']));
        notifyListeners();
        break;
      case 'checklist_item_updated':
        final updatedItem = MissionChecklistItem.fromJson(event['data']);
        final index = checklist.indexWhere((i) => i.id == updatedItem.id);
        if (index != -1) {
          checklist[index] = updatedItem;
          notifyListeners();
        }
        break;
      case 'live_update':
        debugPrint(
          'CollaborationProvider: Live update received: ${event['data']['type']}',
        );
        // We can choose to store this in a separate list for a "Live Feed"
        // For now, we'll just notify that something changed.
        notifyListeners();
        break;
    }
  }

  Future<void> initBoard(int missionId) async {
    debugPrint(
      'CollaborationProvider: Initializing board for mission $missionId',
    );
    currentMissionId = missionId;
    activeUsers = [];
    comments = [];
    checklist = [];

    // Fetch initial state via REST
    try {
      final token = authProvider.token;
      debugPrint(
        'CollaborationProvider: Fetching initial state from $baseUrl/api/missions/$missionId/board',
      );

      final response = await Dio().get(
        '$baseUrl/api/missions/$missionId/board',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => true,
        ),
      );

      debugPrint(
        'CollaborationProvider: REST response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        comments = (data['comments'] as List)
            .map((c) => MissionComment.fromJson(c))
            .toList();
        checklist = (data['checklist'] as List)
            .map((i) => MissionChecklistItem.fromJson(i))
            .toList();
        debugPrint(
          'CollaborationProvider: Loaded ${comments.length} comments and ${checklist.length} items',
        );
      } else {
        debugPrint(
          'CollaborationProvider: Failed to load board data: ${response.data}',
        );
      }
    } catch (e) {
      debugPrint('CollaborationProvider: REST Error: $e');
    }

    if (!isConnected) {
      debugPrint('CollaborationProvider: Connecting socket to $baseUrl');
      _service.connect(baseUrl, authProvider.token!);
    }

    debugPrint('CollaborationProvider: Joining mission room $missionId');
    _service.joinMission(missionId);
    notifyListeners();
  }

  void leaveBoard() {
    if (currentMissionId != null) {
      _service.leaveMission(currentMissionId!);
      currentMissionId = null;
    }
  }

  Future<void> sendComment(String content) async {
    if (currentMissionId == null) {
      debugPrint('CollaborationProvider Error: currentMissionId is null');
      return;
    }
    final completer = Completer<void>();
    bool timedOut = false;

    final timer = Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        timedOut = true;
        completer.completeError('Request timed out');
      }
    });

    debugPrint(
      'CollaborationProvider: Sending comment to mission $currentMissionId',
    );
    _service.sendComment(currentMissionId!, content, (response) {
      if (timedOut) return;
      timer.cancel();

      debugPrint('CollaborationProvider: Received send_comment ack: $response');
      if (response != null && response['success'] == true) {
        completer.complete();
      } else {
        completer.completeError(response?['error'] ?? 'Failed to send comment');
      }
    });
    return completer.future;
  }

  Future<void> togglePin(int commentId, bool isPinned) async {
    if (currentMissionId == null) return;

    final completer = Completer<void>();
    _service.togglePin(currentMissionId!, commentId, isPinned, (response) {
      if (response != null && response['success'] == true) {
        completer.complete();
      } else {
        completer.completeError(response?['error'] ?? 'Failed to toggle pin');
      }
    });
    return completer.future;
  }

  Future<void> addChecklistItem(String content) async {
    if (currentMissionId == null) return;

    final completer = Completer<void>();
    bool timedOut = false;

    final timer = Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        timedOut = true;
        completer.completeError('Request timed out');
      }
    });

    debugPrint(
      'CollaborationProvider: Adding checklist item to mission $currentMissionId',
    );
    _service.addChecklistItem(currentMissionId!, content, (response) {
      if (timedOut) return;
      timer.cancel();

      debugPrint(
        'CollaborationProvider: Received add_checklist_item ack: $response',
      );
      if (response != null && response['success'] == true) {
        completer.complete();
      } else {
        completer.completeError(response?['error'] ?? 'Failed to add task');
      }
    });
    return completer.future;
  }

  Future<void> toggleChecklistItem(int itemId, bool isCompleted) async {
    if (currentMissionId == null) return;

    final completer = Completer<void>();
    _service.toggleChecklistItem(currentMissionId!, itemId, isCompleted, (
      response,
    ) {
      if (response != null && response['success'] == true) {
        completer.complete();
      } else {
        completer.completeError(response?['error'] ?? 'Failed to update task');
      }
    });
    return completer.future;
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
