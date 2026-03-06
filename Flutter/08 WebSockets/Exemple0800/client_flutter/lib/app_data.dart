import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'network_config.dart';
import 'utils_websockets.dart';

class AppData extends ChangeNotifier {
  // Atributs per gestionar la connexió
  final WebSocketsHandler _wsHandler = WebSocketsHandler();
  NetworkConfig networkConfig;
  bool isConnected = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectDelay = Duration(seconds: 3);

  // Atributs per gestionar el joc
  Map<String, dynamic> gameData = {}; // Dades de 'game_data.json'
  Map<String, ui.Image> imagesCache = {}; // Imatges
  Map<String, dynamic> gameState = {}; // Estat rebut del servidor
  dynamic playerData; // Apuntador al jugador (a gameState)
  String playerName;

  AppData({NetworkConfig initialConfig = NetworkConfig.defaults})
    : networkConfig = initialConfig,
      playerName = initialConfig.playerName {
    _init();
  }

  void updateNetworkConfig(NetworkConfig nextConfig) {
    networkConfig = nextConfig;
    playerName = nextConfig.playerName;
    disconnect();
    _reconnectAttempts = 0;
    _connectToWebSocket();
  }

  Future<void> _init() async {
    await _loadGameData("assets/flag_game/game_data.json");
    _connectToWebSocket();
    notifyListeners();
  }

  // Connectar amb el servidor (amb reintents si falla)
  void _connectToWebSocket() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        print("S'ha assolit el màxim d'intents de reconnexió.");
      }
      return;
    }

    isConnected = false;
    notifyListeners();

    _wsHandler.connectToServer(
      networkConfig.serverHost,
      networkConfig.serverPort,
      _onWebSocketMessage,
      useSecureSocket: networkConfig.useSecureWebSocket,
      onError: _onWebSocketError,
      onDone: _onWebSocketClosed,
    );

    isConnected = true;
    _reconnectAttempts = 0;
    notifyListeners();
  }

  // Tractar un missatge rebut des del servidor
  void _onWebSocketMessage(String message) {
    try {
      var data = jsonDecode(message);
      if (data["type"] == "update") {
        // Guardar les dades de l'estat de la partida
        gameState = {}..addAll(data["gameState"]);
        String? playerId = _wsHandler.socketId;
        if (playerId != null && gameState["players"] is List) {
          // Guardar les dades del propi jugador
          playerData = getPlayerData(playerId);
        }
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error processant missatge WebSocket: $e");
      }
    }
  }

  // Tractar els errors de connexió
  void _onWebSocketError(dynamic error) {
    if (kDebugMode) {
      print("Error de WebSocket: $error");
    }
    isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  // Tractar les desconnexions
  void _onWebSocketClosed() {
    if (kDebugMode) {
      print("WebSocket tancat. Intentant reconnectar...");
    }
    isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  // Programar una reconnexió (en cas que hagi fallat)
  void _scheduleReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      if (kDebugMode) {
        print(
          "Intent de reconnexió #$_reconnectAttempts en ${_reconnectDelay.inSeconds} segons...",
        );
      }
      Future.delayed(_reconnectDelay, () {
        _connectToWebSocket();
      });
    } else {
      if (kDebugMode) {
        print(
          "No es pot reconnectar al servidor després de $_maxReconnectAttempts intents.",
        );
      }
    }
  }

  // Filtrar les dades del propi jugador (fent servir l'id de player)
  dynamic getPlayerData(String playerId) {
    return (gameState["players"] as List).firstWhere(
      (player) => player["id"] == playerId,
      orElse: () => {},
    );
  }

  // Desconnectar-se del servidor
  void disconnect() {
    _wsHandler.disconnectFromServer();
    isConnected = false;
    notifyListeners();
  }

  // Enviar un missatge al servidor
  void sendMessage(String message) {
    if (isConnected) {
      _wsHandler.sendMessage(message);
    }
  }

  // Obté una imatge de 'assets' (si no la té ja en caché)
  Future<ui.Image> getImage(String assetName) async {
    if (!imagesCache.containsKey(assetName)) {
      final ByteData data = await rootBundle.load('assets/$assetName');
      final Uint8List bytes = data.buffer.asUint8List();
      imagesCache[assetName] = await decodeImage(bytes);
    }
    return imagesCache[assetName]!;
  }

  Future<ui.Image> decodeImage(Uint8List bytes) {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) => completer.complete(img));
    return completer.future;
  }

  Future<void> _loadGameData([
    String filePath = 'assets/flag_game/game_data.json',
  ]) async {
    try {
      final jsonString = await rootBundle.loadString(filePath);
      gameData = jsonDecode(jsonString);

      final Set<String> imageFiles = {};
      for (var level in gameData['levels']) {
        for (var layer in level['layers']) {
          if (layer['tilesSheetFile'] != null) {
            imageFiles.add(layer['tilesSheetFile']);
          }
        }
        for (var sprite in level['sprites']) {
          if (sprite['imageFile'] != null) {
            imageFiles.add(sprite['imageFile']);
          }
        }
      }

      for (var imageFile in imageFiles) {
        await getImage('flag_game/$imageFile');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error carregant els assets del joc: $e");
      }
    }
  }
}
