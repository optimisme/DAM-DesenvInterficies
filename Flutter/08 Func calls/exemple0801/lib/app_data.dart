import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'constants.dart';
import 'drawable.dart';

class AppData extends ChangeNotifier {
  String _responseText = "";
  bool _isLoading = false;
  bool _isInitial = true;
  http.Client? _client;
  IOClient? _ioClient;
  HttpClient? _httpClient;
  StreamSubscription<String>? _streamSubscription;

  final List<Drawable> drawables = [];

  String get responseText =>
      _isInitial ? "..." : (_isLoading ? "Esperant ..." : _responseText);

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
        setLoading(false);
        notifyListeners();
      }, onDone: () {
        setLoading(false);
      });
    } catch (e) {
      _responseText = "Error during streaming.";
      setLoading(false);
      notifyListeners();
    }
  }

  Future<void> callWithCustomTools({required String userPrompt}) async {
    const apiUrl = 'http://localhost:11434/api/chat';

    _responseText = "";
    _isInitial = false;
    setLoading(true);

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
        setLoading(false);
      } else {
        setLoading(false);
        throw Exception("Error: ${response.body}");
      }
    } catch (e) {
      print("Error during API call: $e");
      setLoading(false);
    }
  }

  void cancelRequests() {
    _streamSubscription?.cancel();
    _httpClient?.close(force: true);
    _httpClient = HttpClient();
    _ioClient = IOClient(_httpClient!);
    _client = _ioClient;
    _responseText += "\nRequest cancelled.";
    setLoading(false);
    notifyListeners();
  }

  // Posa els paràmetres JSON rebuts de la IA en un format estàndard
  Map<String, dynamic> normalizeParameters(Map<String, dynamic> parameters) {
    final normalized = <String, dynamic>{};

    parameters.forEach((key, value) {
      if (value is String) {
        try {
          // Si és un JSON dins d'una cadena, el deserialitzem
          final parsed = jsonDecode(value);
          if (parsed is Map<String, dynamic>) {
            normalized[key] = normalizeParameters(parsed);
          } else if (parsed is List && parsed.length == 2) {
            normalized[key] = {
              "x": parsed[0].toDouble(),
              "y": parsed[1].toDouble()
            };
          } else if (parsed is num) {
            normalized[key] = parsed.toDouble();
          } else {
            normalized[key] = parsed;
          }
        } catch (_) {
          // Deixa la cadena tal qual si no es pot deserialitzar
          normalized[key] = value;
        }
      } else if (value is num) {
        // Converteix qualsevol valor numèric a double
        normalized[key] = value.toDouble();
      } else if (value is Map<String, dynamic>) {
        // Normalitzem els objectes aniuats
        normalized[key] = normalizeParameters(value);
      } else {
        // Altres tipus (llistes, booleans, etc.)
        normalized[key] = value;
      }
    });

    return normalized;
  }

  void _processFunctionCall(Map<String, dynamic> functionCall) {
    final parameters = normalizeParameters(functionCall['arguments']);

    switch (functionCall['name']) {
      case 'draw_line':
        if (parameters['start'] != null && parameters['end'] != null) {
          final start =
              Offset(parameters['start']['x'], parameters['start']['y']);
          final end = Offset(parameters['end']['x'], parameters['end']['y']);
          addDrawable(Line(start: start, end: end));
        }
        break;

      case 'draw_circle':
        if (parameters['center'] != null && parameters['radius'] != null) {
          final center =
              Offset(parameters['center']['x'], parameters['center']['y']);
          final radius = parameters['radius'];
          addDrawable(Circle(center: center, radius: radius));
        }
        break;

      case 'draw_rectangle':
        if (parameters['top_left'] != null &&
            parameters['bottom_right'] != null) {
          final topLeft =
              Offset(parameters['top_left']['x'], parameters['top_left']['y']);
          final bottomRight = Offset(
              parameters['bottom_right']['x'], parameters['bottom_right']['y']);
          addDrawable(Rectangle(topLeft: topLeft, bottomRight: bottomRight));
        }
        break;

      default:
        print("Unknown function call: ${functionCall['name']}");
    }
  }
}
