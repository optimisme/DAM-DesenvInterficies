import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'drawable.dart';

class AppData extends ChangeNotifier {
  String _responseText = "";
  bool _isLoading = false;
  bool _isWaiting = true;
  bool _isInitial = true;
  http.Client? _client;
  IOClient? _ioClient;
  HttpClient? _httpClient;
  StreamSubscription<String>? _streamSubscription;

  final List<Drawable> drawables = [];

  String get responseText => _isInitial
      ? "Cal un servidor en funcionament ..."
      : (_isWaiting ? "Esperant ..." : _responseText);
  bool get isLoading => _isLoading;

  AppData() {
    _httpClient = HttpClient();
    _ioClient = IOClient(_httpClient!);
    _client = _ioClient;
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void addDrawable(Drawable drawable) {
    drawables.add(drawable);
    notifyListeners();
  }

  Future<void> callStream({required String question}) async {
    _responseText = "";
    _isInitial = false;
    _isWaiting = true;
    setLoading(true);

    try {
      var request = http.Request(
        'POST',
        Uri.parse('http://localhost:11434/api/generate'),
      );

      request.headers.addAll({'Content-Type': 'application/json'});
      request.body =
          jsonEncode({'model': 'llama3.2', 'prompt': question, 'stream': true});

      var streamedResponse = await _client!.send(request);
      _streamSubscription =
          streamedResponse.stream.transform(utf8.decoder).listen((value) {
        _isWaiting = false;
        var jsonResponse = jsonDecode(value);
        _responseText += jsonResponse['response'];
        notifyListeners();
      }, onError: (error) {
        if (error is http.ClientException &&
            error.message == 'Connection closed while receiving data') {
          _responseText += "\nRequest cancelled.";
        } else {
          _responseText = "Error during streaming: $error";
        }
        _isWaiting = false;
        setLoading(false);
        notifyListeners();
      }, onDone: () {
        setLoading(false);
      });
    } catch (e) {
      _responseText = "Error during streaming.";
      _isWaiting = false;
      setLoading(false);
      notifyListeners();
    }
  }

  Future<void> callComplete({required String question}) async {
    _responseText = "";
    _isInitial = false;
    _isWaiting = true;
    setLoading(true);

    try {
      var response = await _client!.post(
        Uri.parse('http://localhost:11434/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'model': 'llama3.2', 'prompt': question, 'stream': false}),
      );

      var jsonResponse = jsonDecode(response.body);
      _responseText = jsonResponse['response'];
      _isWaiting = false;
      setLoading(false);
      notifyListeners();
    } catch (e) {
      _responseText = "Error during completion.";
      _isWaiting = false;
      setLoading(false);
      notifyListeners();
    }
  }

  void cancelRequests() {
    _streamSubscription?.cancel();
    _httpClient?.close(force: true);
    _httpClient = HttpClient();
    _ioClient = IOClient(_httpClient!);
    _client = _ioClient;
    _responseText += "\nRequest cancelled.";
    _isWaiting = false;
    setLoading(false);
    notifyListeners();
  }

  Future<void> callWithCustomTools({required String userPrompt}) async {
    const apiUrl = 'http://localhost:11434/api/chat';

    final tools = [
      {
        "type": "function",
        "function": {
          "name": "draw_line",
          "description": "Dibuixa una línia entre dos punts",
          "parameters": {
            "type": "object",
            "properties": {
              "start": {
                "type": "object",
                "properties": {
                  "x": {"type": "number"},
                  "y": {"type": "number"}
                },
                "required": ["x", "y"]
              },
              "end": {
                "type": "object",
                "properties": {
                  "x": {"type": "number"},
                  "y": {"type": "number"}
                },
                "required": ["x", "y"]
              }
            },
            "required": ["start", "end"]
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "draw_circle",
          "description": "Dibuixa un cercle amb un radi determinat",
          "parameters": {
            "type": "object",
            "properties": {
              "center": {
                "type": "object",
                "properties": {
                  "x": {"type": "number"},
                  "y": {"type": "number"}
                },
                "required": ["x", "y"]
              },
              "radius": {"type": "number"}
            },
            "required": ["center", "radius"]
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "draw_rectangle",
          "description":
              "Dibuixa un rectangle definit per les coordenades superior-esquerra i inferior-dreta",
          "parameters": {
            "type": "object",
            "properties": {
              "top_left": {
                "type": "object",
                "properties": {
                  "x": {"type": "number"},
                  "y": {"type": "number"}
                },
                "required": ["x", "y"]
              },
              "bottom_right": {
                "type": "object",
                "properties": {
                  "x": {"type": "number"},
                  "y": {"type": "number"}
                },
                "required": ["x", "y"]
              }
            },
            "required": ["top_left", "bottom_right"]
          }
        }
      }
    ];

    final schema = jsonEncode({
      "type": "object",
      "properties": {
        "tool_calls": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "function": {
                "type": "object",
                "properties": {
                  "name": {"type": "string"},
                  "arguments": {"type": "object"}
                },
                "required": ["name", "arguments"]
              }
            },
            "required": ["function"]
          }
        }
      },
      "required": ["tool_calls"]
    });

    final body = {
      "model": "llama3.2",
      "stream": false,
      "messages": [
        {"role": "user", "content": userPrompt}
      ],
      "tools": tools,
      "format": schema
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print(response.body);
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['message'] != null &&
            jsonResponse['message']['tool_calls'] != null) {
          final toolCalls =
              jsonResponse['message']['tool_calls'] as List<dynamic>;
          for (final toolCall in toolCalls) {
            if (toolCall['function'] != null) {
              _processFunctionCall(toolCall['function']);
            }
          }
        }
      } else {
        throw Exception("Error: ${response.body}");
      }
    } catch (e) {
      print("Error during API call: $e");
    }
  }

  void _processFunctionCall(Map<String, dynamic> functionCall) {
    final parameters = functionCall['arguments'];
    switch (functionCall['name']) {
      case 'draw_line':
        if (parameters['start'] != null && parameters['end'] != null) {
          final start = _parsePoint(parameters['start']);
          final end = _parsePoint(parameters['end']);
          if (start != null && end != null) {
            addDrawable(Line(start: start, end: end));
          }
        }
        break;

      case 'draw_circle':
        if (parameters['center'] != null && parameters['radius'] != null) {
          final center = _parsePoint(parameters['center']);
          final radius = _parseNumber(parameters['radius']);
          if (center != null && radius != null) {
            addDrawable(Circle(center: center, radius: radius));
          }
        }
        break;

      case 'draw_rectangle':
        if (parameters['top_left'] != null &&
            parameters['bottom_right'] != null) {
          final topLeft = _parsePoint(parameters['top_left']);
          final bottomRight = _parsePoint(parameters['bottom_right']);
          if (topLeft != null && bottomRight != null) {
            addDrawable(Rectangle(topLeft: topLeft, bottomRight: bottomRight));
          }
        }
        break;

      default:
        print("Unknown function call: ${functionCall['name']}");
    }
  }

  // Funció per convertir punts
  Offset? _parsePoint(dynamic point) {
    if (point is Map<String, dynamic>) {
      return Offset(point['x']?.toDouble() ?? 0, point['y']?.toDouble() ?? 0);
    } else if (point is String) {
      // Converteix cadenes com "[20, 50]" a objectes
      final regex = RegExp(r'\[(\d+),\s*(\d+)\]');
      final match = regex.firstMatch(point);
      if (match != null) {
        return Offset(
            double.parse(match.group(1)!), double.parse(match.group(2)!));
      }
    }
    return null;
  }

  // Funció per convertir nombres
  double? _parseNumber(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
