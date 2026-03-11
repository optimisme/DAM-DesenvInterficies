<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2023</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="./assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

[https://www.youtube.com/watch?v=2DtpyLtDXgc](https://www.youtube.com/watch?v=2DtpyLtDXgc)

# WebSockets

Documentació:

- [WebSockets](https://docs.flutter.dev/cookbook/networking/web-sockets)

Els **WebSockets** són una tecnologia que permet mantenir **una connexió oberta i contínua entre el navegador i el servidor** perquè es puguin enviar dades **en temps real en ambdues direccions**.

Les principals característiques són:

- la connexió **queda oberta**
- **client i servidor poden enviar missatges quan vulguin**
- no cal fer noves peticions cada vegada

Els WebSockets són ideals per a jocs multijugador perquè permeten comunicació immediata i contínua entre els jugadors i el servidor.

## Estats de connexió

Creem un [enum](https://dart.dev/language/enums) per definir els possibles estats de la connexió del socket:

```dart
enum ConnectionStatus {
  disconnected,
  disconnecting,
  connecting,
  connected,
}
```

Els `enum` són un tipus de classe especial que permet definir una quantitat coneguda de valors constants. En aquest cas, els diferents estats d’una connexió.

## Servidor

A la part del servidor NodeJS, els WebSockets es gestionen amb:

- **ws.init**: inicialitza el servidor de websockets
- **ws.onConnection**: gestiona les connexions entrants
- **ws.onMessage**: gestiona els missatges entrants
- **ws.onClose**: gestiona les desconnexions
- **ws.send**: envia un missatge només a un client concret
- **ws.broadcast**: envia un missatge a tots els clients connectats
- **ws.forEachClient**: recorre tots els clients connectats per enviar missatges personalitzats
- **ws.end**: tanca el servidor de websockets

```javascript
const webSockets = require('./utilsWebSockets.js');
const ws = new webSockets();

// Gestionar WebSockets
ws.init(httpServer, port);

ws.onConnection = (socket, id) => {
    if (debug) console.log("WebSocket client connected: " + id);
    game.addClient(id);

    ws.send(socket, JSON.stringify({
      type: 'snapshot',
      snapshot: game.getSnapshotState()
    }));

    sendGameplayStateToClient(socket, id, {
      includeOtherPlayers: true,
      includeGems: true
    });
};

ws.onMessage = (socket, id, msg) => {
    if (debug) console.log(`New message from ${id}: ${msg.substring(0, 32)}...`);
    const stateChanged = game.handleMessage(id, msg);
    if (stateChanged) {
        broadcastGameState();
    }
};

ws.onClose = (socket, id) => {
    if (debug) console.log("WebSocket client disconnected: " + id);
    game.removeClient(id);
    ws.broadcast(JSON.stringify({ type: "disconnected", from: "server" }));
};
```

### Dades del joc

La informació de la pantalla està a la carpeta `assets` i ha de ser igual al client i al servidor. Cal fer la còpia manualment abans d'iniciar el servidor o cada vegada que es modifiquin les dades:

```bash
bash getAssets.sh
```

### Bucle de joc i lògica

El servidor executa un bucle que actualitza l'estat del joc a intervals regulars. El bucle intenta mantenir una cadència alta d'actualització, però si temporalment no es pot calcular correctament l'FPS real, es fa servir `TARGET_FPS_FALLBACK = 30` com a valor de seguretat per calcular el `dt`.

```javascript
gameLoop.run = (fps) => {
    game.updateGame(fps);
    broadcastGameState();
};
```

La lògica del joc es gestiona a través de `GameLogic`. El servidor és autoritari: el client no decideix l’estat del joc, només envia intencions (`register`, `direction`, `restartMatch`) i el servidor calcula moviment, col·lisions, compte enrere, joies i guanyador.

Per evitar enviar dades estàtiques repetidament, el servidor només torna a enviar el `snapshot` quan cal:

```javascript
consumeSnapshotState() {
    if (!this.initialStateDirty) {
        return null;
    }
    this.initialStateDirty = false;
    return this.getSnapshotState();
}
```

L’estat dinàmic s’envia amb missatges `gameplay` personalitzats per a cada client:

```javascript
function broadcastGameState() {
  const snapshot = game.consumeSnapshotState();
  const includeOtherPlayers = snapshot ? true : gameplayBroadcastIndex % 2 === 0;
  const includeGems = snapshot ? true : !includeOtherPlayers;

  if (snapshot) {
    ws.broadcast(JSON.stringify({ type: 'snapshot', snapshot }));
  }

  ws.forEachClient((socket, id) => {
    sendGameplayStateToClient(socket, id, {
      includeOtherPlayers,
      includeGems
    });
  });

  gameplayBroadcastIndex = (gameplayBroadcastIndex + 1) % 2;
}
```

Això permet reduir el trànsit de xarxa perquè cada missatge `gameplay`:

- sempre inclou les dades del jugador actual (`selfPlayer`)
- intercala les dades de la resta de jugadors (`otherPlayers`)
- intercala les joies visibles (`gems`)

> **Nota**: El motiu d’aquesta optimització és evitar enviar grans quantitats de dades innecessàries. Això redueix la latència i permet suportar més jugadors simultanis.

### Paràmetres de configuració i web d'admin

Per tal de gestionar el reinici de la partida, hi ha disponible la pàgina `public/admin.html`. La seva contrasenya es configura a l'arxiu `config.env`.

```text
PORT=3000
DEBUG_WS=0
WEB_ADMIN_PASSWORD=admin
```

S'hi accedeix amb:

[http://localhost:3000/admin.html](http://localhost:3000/admin.html)

[https://nomUsuari.ieti.site/admin.html](https://nomUsuari.ieti.site/admin.html)

## Missatges del protocol

Ara el protocol queda així:

- **welcome**
  - id del client assignat pel servidor

- **snapshot**
  - nom del nivell
  - dades base dels jugadors
  - definició de les joies

- **gameplay**
  - fase de partida
  - compte enrere
  - joies restants
  - guanyador
  - capes i zones mòbils
  - `selfPlayer` sempre
  - `otherPlayers` en missatges alterns
  - `gems` en missatges alterns

## Client

Al cantó del client la configuració de xarxa es centralitza a `NetworkConfig`:

```dart
class NetworkConfig {
  static const String remoteServer = 'nomUsuari.ieti.site';
}
```

Durant la partida, el client funciona així:

- **Entrada de dades**: es llegeix el teclat però, en lloc de moure directament el jugador, s’envia la direcció actual al servidor.
- **Recepció de dades**: `AppData` rep els missatges `snapshot` i `gameplay`.
- **Renderitzat**: el client dibuixa l’estat rebut del servidor.

El client fusiona els missatges parcials de `gameplay`, de manera que pot actualitzar sempre el jugador local i, de forma intercalada, la resta de jugadors o les joies.

### Avantatges del model servidor autoritari

- Tots els clients veuen un **món consistent**.
- Evita el *cheating* perquè el servidor és l'únic que decideix l'estat del joc.
- Les regles del joc estan **centralitzades**.
- **Clients més simples**, ja que només s'encarreguen de renderitzar i enviar les intencions del jugador.
