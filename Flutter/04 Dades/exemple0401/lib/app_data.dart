import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class AppData extends ChangeNotifier {
  String _responseText = "";
  bool _isLoading = false;
  bool _isWaiting = true; // Afegeix aquesta variable
  bool _isInitial = true; // Afegeix aquesta variable
  http.Client? _client;
  IOClient? _ioClient;
  HttpClient? _httpClient;
  StreamSubscription<String>? _streamSubscription; // Afegeix aquesta variable

  String get responseText => _isInitial
      ? "Cal un servidor en funcionament ..."
      : (_isWaiting ? "Esperant ..." : _responseText); // Modifica el getter
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

  Future<void> callStream() async {
    _responseText = "";
    _isInitial = false; // Canvia a false quan es prem un botó
    _isWaiting = true; // Inicialitza a true
    setLoading(true);

    try {
      var request = http.Request(
        'POST',
        Uri.parse('http://localhost:11434/api/generate'),
      );

      request.headers.addAll({'Content-Type': 'application/json'});
      request.body = jsonEncode(
          {'model': 'phi4', 'prompt': 'Why is the sky blue?', 'stream': true});

      var streamedResponse = await _client!.send(request);
      _streamSubscription =
          streamedResponse.stream.transform(utf8.decoder).listen((value) {
        _isWaiting = false; // Canvia a false quan arriba la resposta
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
        _isWaiting = false; // Canvia a false en cas d'error
        setLoading(false);
        notifyListeners();
      }, onDone: () {
        setLoading(false);
      });
    } catch (e) {
      _responseText = "Error during streaming.";
      _isWaiting = false; // Canvia a false en cas d'error
      setLoading(false);
      notifyListeners();
    }
  }

  Future<void> callComplete() async {
    _responseText = "";
    _isInitial = false; // Canvia a false quan es prem un botó
    _isWaiting = true; // Inicialitza a true
    setLoading(true);

    try {
      var response = await _client!.post(
        Uri.parse('http://localhost:11434/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'model': 'phi3', 'prompt': 'Tell me a haiku.', 'stream': false}),
      );

      var jsonResponse = jsonDecode(response.body);
      _responseText = jsonResponse['response'];
      _isWaiting = false; // Canvia a false quan arriba la resposta
      setLoading(false);
      notifyListeners();
    } catch (e) {
      _responseText = "Error during completion.";
      _isWaiting = false; // Canvia a false en cas d'error
      setLoading(false);
      notifyListeners();
    }
  }

  void cancelRequests() {
    _streamSubscription?.cancel(); // Cancel·la la subscripció
    _httpClient?.close(force: true);
    _httpClient = HttpClient();
    _ioClient = IOClient(_httpClient!);
    _client = _ioClient;
    _responseText += "\nRequest cancelled.";
    _isWaiting = false; // Canvia a false quan es cancel·la la petició
    setLoading(false);
    notifyListeners();
  }
}
