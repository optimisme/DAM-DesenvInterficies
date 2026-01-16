<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2023</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="./assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

<br/>
<center><img src="./assets/dartlogo.png" style="max-height: 75px" alt="">
<br/></center>
<br/>
<br/>

# WebSockets

Documentació:

- [WebSockets](https://docs.flutter.dev/cookbook/networking/web-sockets)

## Estats de connexió

Creem un "[enum](https://dart.dev/language/enums)" per definir els possibles estats de la connexió del socket:

```dart
enum ConnectionStatus {
  disconnected,
  disconnecting,
  connecting,
  connected,
}
```

Els ‘enum’ són un tipus de classe especial, que permet definir una quantitat coneguda de valors constants. En aquest cas, els diferents estats d’una connexió.

## Connexió amb el servidor

El client de sockets té dos punts de connexió amb el servidor:

- **stream**: punt pel que rebem les dades des del servidor
- **sink**: punt pel que enviem les dades cap al servidor

```dart
// Punt de recepció de dades ‘stream’
_socketClient!.stream.listen(
    (message) {
        final data = jsonDecode(message);
        notifyListeners();
    }


// Punt d’enviament de dades ‘sink’
_socketClient!.sink.add(jsonEncode(message));
```

Per connectar amb el servidor cal la IP i el Port

- Definim què fer quan rebem un missatge
- Com que els missatges són en format JSON els transformem a objectes Flutter
- Per cada tipus de missatge fem una acció diferent
- Per enviar missatges al servidor, preparem l’objecte a enviar.
- El transformem a una cadena de text tipus JSON
- S’envia amb *sink.add*

```dart
void connectToServer() async {

  connectionStatus = ConnectionStatus.connecting;
  notifyListeners();

    // ToDO
}
```
