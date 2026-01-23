import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

enum SessionRole { user, assistant, system }

class SessionEntry {
  final SessionRole role;
  final String content;
  final DateTime timestamp;

  SessionEntry({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AppData extends ChangeNotifier {
  bool _isLoading = false;
  http.Client? _client;
  IOClient? _ioClient;
  HttpClient? _httpClient;
  static const String _serverUrl = 'http://localhost:3000/chat';
  late final String _sessionId;
  final List<SessionEntry> _session = [];

  bool get isLoading => _isLoading;
  List<SessionEntry> get session => List.unmodifiable(_session);

  AppData() {
    final rng = Random();
    _sessionId =
        'flutter-${DateTime.now().microsecondsSinceEpoch}-${rng.nextInt(1 << 32)}';
    _httpClient = HttpClient();
    _ioClient = IOClient(_httpClient!);
    _client = _ioClient;
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _addEntry(SessionRole role, String content) {
    if (content.trim().isEmpty) {
      return;
    }
    _session.add(SessionEntry(role: role, content: content.trim()));
  }

  Future<void> callWithCustomTools({required String userPrompt}) async {
    setLoading(true);
    _addEntry(SessionRole.user, userPrompt);
    notifyListeners();

    final body = {"message": userPrompt};

    try {
      final response = await _client!.post(
        Uri.parse(_serverUrl),
        headers: {
          "Content-Type": "application/json",
          "x-session-id": _sessionId,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final message = jsonResponse['message']?.toString() ?? "";
        _addEntry(SessionRole.assistant, message);
        setLoading(false);
        notifyListeners();
      } else {
        setLoading(false);
        throw Exception("Error: ${response.body}");
      }
    } catch (e) {
      print("Error during API call: $e");
      _addEntry(SessionRole.system, "Error contacting server.");
      setLoading(false);
      notifyListeners();
    }
  }

  void cancelRequests() {
    _httpClient?.close(force: true);
    _httpClient = HttpClient();
    _ioClient = IOClient(_httpClient!);
    _client = _ioClient;
    _addEntry(SessionRole.system, "Request cancelled.");
    setLoading(false);
    notifyListeners();
  }
}
