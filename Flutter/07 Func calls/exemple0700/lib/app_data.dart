import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'constants.dart';
import 'drawable.dart';

const modelName = 'Qwen36';
const modelUrl = 'https://agents.ieti.site/v1/chat/completions';
const modelKey = 'SERVER_API_KEY';

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
    _createHttpClient();
  }

  void _createHttpClient() {
    _httpClient = HttpClient();
    _ioClient = IOClient(_httpClient!);
    _client = _ioClient;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $modelKey',
      };

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void addDrawable(Drawable drawable) {
    drawables.add(drawable);
    notifyListeners();
  }

  Future<void> callStream({required String question}) async {
    _isInitial = false;
    _responseText = "";
    setLoading(true);

    try {
      final request = http.Request('POST', Uri.parse(modelUrl));

      request.headers.addAll(_headers);
      request.body = jsonEncode({
        'model': modelName,
        'messages': [
          {'role': 'user', 'content': question},
        ],
        'stream': true,
        'reasoning_effort': 'none',
      });

      final streamedResponse = await _client!.send(request);

      if (streamedResponse.statusCode != 200) {
        final error = await streamedResponse.stream.bytesToString();
        _responseText = "Error ${streamedResponse.statusCode}: $error";
        setLoading(false);
        return;
      }

      var buffer = '';

      _streamSubscription =
          streamedResponse.stream.transform(utf8.decoder).listen(
        (value) {
          buffer += value;

          final lines = buffer.split('\n');
          buffer = lines.removeLast();

          for (final line in lines) {
            _processStreamLine(line);
          }
        },
        onError: (error) {
          if (error is http.ClientException &&
              error.message == 'Connection closed while receiving data') {
            _responseText += "\nRequest cancelled.";
          } else {
            _responseText += "\nError during streaming: $error";
          }

          setLoading(false);
        },
        onDone: () {
          if (buffer.trim().isNotEmpty) {
            _processStreamLine(buffer);
          }

          setLoading(false);
        },
      );
    } catch (e) {
      _responseText = "Error during streaming: $e";
      setLoading(false);
    }
  }

  void _processStreamLine(String line) {
    line = line.trim();

    if (line.isEmpty || !line.startsWith('data:')) return;

    final data = line.substring(5).trim();

    if (data == '[DONE]') return;

    try {
      final jsonResponse = jsonDecode(data);
      final choices = jsonResponse['choices'];

      if (choices is! List || choices.isEmpty) return;

      final delta = choices[0]['delta'];
      if (delta is! Map) return;

      final content = delta['content'];

      if (content is String && content.isNotEmpty) {
        _responseText += content;
        notifyListeners();
      }
    } catch (e) {
      print("Invalid stream chunk: $data");
    }
  }

  Future<dynamic> fixJsonInStrings(dynamic data) async {
    if (data is Map<String, dynamic>) {
      final result = <String, dynamic>{};

      for (final entry in data.entries) {
        result[entry.key] = await fixJsonInStrings(entry.value);
      }

      return result;
    }

    if (data is List) {
      return Future.wait(data.map((value) => fixJsonInStrings(value)));
    }

    if (data is String) {
      final trimmed = data.trim();

      if (trimmed.isEmpty) return data;

      try {
        final parsed = jsonDecode(data);
        return fixJsonInStrings(parsed);
      } catch (_) {
        if (_looksLikeJsonCandidate(trimmed)) {
          final repairedJson = await _repairJsonWithAi(trimmed);

          if (repairedJson != null) {
            return fixJsonInStrings(repairedJson);
          }
        }

        return data;
      }
    }

    return data;
  }

  bool _looksLikeJsonCandidate(String value) {
    return value.startsWith('{') ||
        value.startsWith('[') ||
        ((value.contains('{') || value.contains('[')) && value.contains(':'));
  }

  Future<dynamic> _repairJsonWithAi(String rawJson) async {
    final body = {
      'model': modelName,
      'stream': false,
      'reasoning_effort': 'none',
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You repair malformed JSON. Return only valid JSON that preserves the original intent and values as closely as possible.',
        },
        {
          'role': 'user',
          'content':
              'Repair this malformed JSON and return only the fixed JSON:\n$rawJson',
        },
      ],
    };

    try {
      final response = await _client!.post(
        Uri.parse(modelUrl),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) return null;

      final jsonResponse = jsonDecode(response.body);
      final content = _extractMessageContent(jsonResponse);

      if (content == null || content.trim().isEmpty) return null;

      return jsonDecode(content);
    } catch (_) {
      return null;
    }
  }

  dynamic cleanKeys(dynamic value) {
    if (value is Map<String, dynamic>) {
      final result = <String, dynamic>{};

      value.forEach((key, value) {
        result[key.trim()] = cleanKeys(value);
      });

      return result;
    }

    if (value is List) {
      return value.map(cleanKeys).toList();
    }

    return value;
  }

  Future<void> callWithCustomTools({required String userPrompt}) async {
    _isInitial = false;
    setLoading(true);

    final body = {
      'model': modelName,
      'stream': false,
      'reasoning_effort': 'none',
      'messages': [
        {'role': 'user', 'content': userPrompt},
      ],
      'tools': tools,
    };

    try {
      final response = await _client!.post(
        Uri.parse(modelUrl),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }

      final jsonResponse = jsonDecode(response.body);
      final choices = jsonResponse['choices'];

      if (choices is! List || choices.isEmpty) {
        throw Exception("No choices returned by model");
      }

      final message = choices[0]['message'];

      if (message is! Map) {
        throw Exception("Invalid model response");
      }

      final toolCalls = message['tool_calls'];

      if (toolCalls is List) {
        for (final toolCall in toolCalls) {
          if (toolCall is! Map) continue;

          final cleanToolCall = cleanKeys(Map<String, dynamic>.from(toolCall));

          final function = cleanToolCall['function'];

          if (function is Map) {
            await _processFunctionCall(Map<String, dynamic>.from(function));
          }
        }
      } else {
        final content = message['content'];

        if (content is String && content.isNotEmpty) {
          _responseText += "\n$content";
        }
      }

      setLoading(false);
    } catch (e) {
      print("Error during API call: $e");
      _responseText += "\nError during API call: $e";
      setLoading(false);
    }
  }

  String? _extractMessageContent(dynamic jsonResponse) {
    if (jsonResponse is! Map) return null;

    final choices = jsonResponse['choices'];
    if (choices is! List || choices.isEmpty) return null;

    final message = choices[0]['message'];
    if (message is! Map) return null;

    final content = message['content'];
    return content is String ? content : null;
  }

  void cancelRequests() {
    _streamSubscription?.cancel();
    _httpClient?.close(force: true);

    _createHttpClient();

    _responseText += "\nRequest cancelled.";
    setLoading(false);
  }

  double parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;

    return 0.0;
  }

  double _randomBetween(double min, double max) {
    return min + Random().nextDouble() * (max - min);
  }

  Future<void> _processFunctionCall(Map<String, dynamic> functionCall) async {
    final fixedJson = await fixJsonInStrings(functionCall);
    final parametersData = fixedJson['arguments'];

    final parameters = parametersData is Map<String, dynamic>
        ? parametersData
        : <String, dynamic>{};

    String name = fixedJson['name'];
    String infoText = "Draw $name: $parameters";

    print(infoText);
    _responseText = "$_responseText\n$infoText";

    switch (name) {
      case 'draw_circle':
        final dx =
            parameters['x'] != null ? parseDouble(parameters['x']) : 50.0;

        final dy =
            parameters['y'] != null ? parseDouble(parameters['y']) : 50.0;

        final radius = parameters['radius'] != null
            ? parseDouble(parameters['radius'])
            : 10.0;

        addDrawable(Circle(center: Offset(dx, dy), radius: max(0.0, radius)));

        break;

      case 'draw_line':
        final startX = parameters['startX'] != null
            ? parseDouble(parameters['startX'])
            : _randomBetween(10.0, 100.0);

        final startY = parameters['startY'] != null
            ? parseDouble(parameters['startY'])
            : _randomBetween(10.0, 100.0);

        final endX = parameters['endX'] != null
            ? parseDouble(parameters['endX'])
            : _randomBetween(10.0, 100.0);

        final endY = parameters['endY'] != null
            ? parseDouble(parameters['endY'])
            : _randomBetween(10.0, 100.0);

        addDrawable(
          Line(start: Offset(startX, startY), end: Offset(endX, endY)),
        );

        break;

      case 'draw_rectangle':
        if (parameters['topLeftX'] != null &&
            parameters['topLeftY'] != null &&
            parameters['bottomRightX'] != null &&
            parameters['bottomRightY'] != null) {
          final topLeftX = parseDouble(parameters['topLeftX']);
          final topLeftY = parseDouble(parameters['topLeftY']);
          final bottomRightX = parseDouble(parameters['bottomRightX']);
          final bottomRightY = parseDouble(parameters['bottomRightY']);

          addDrawable(
            Rectangle(
              topLeft: Offset(topLeftX, topLeftY),
              bottomRight: Offset(bottomRightX, bottomRightY),
            ),
          );
        } else {
          print("Missing rectangle properties: $parameters");
        }

        break;

      default:
        print("Unknown function call: ${fixedJson['name']}");
    }
  }
}
