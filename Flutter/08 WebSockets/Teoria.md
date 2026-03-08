<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2023</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="./assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

# WebSockets

Documentació:

- [WebSockets](https://docs.flutter.dev/cookbook/networking/web-sockets)

Els **WebSockets** són una tecnologia que permet mantenir **una connexió oberta i contínua entre el navegador i el servidor** perquè es puguin enviar dades **en temps real en ambdues direccions**.

Les principals característiques són:

* la connexió **queda oberta**
* **client i servidor poden enviar missatges quan vulguin**
* no cal fer noves peticions cada vegada

Els WebSockets són ideals per a jocs multijugador perquè permeten comunicació immediata i contínua entre els jugadors i el servidor.


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

## Servidor

A la part del servidor NodeJS, els websockets es gestionen amb:

- **ws.init**: per inicialitzar el servidor de websockets
- **ws.onConnection**: per gestionar les connexions entrants
- **ws.onMessage**: per gestionar els missatges entrants
- **ws.onClose**: per gestionar les connexions tancades
- **socket.send**: per enviar un missatge només al client del socket actual
- **ws.broadcast**: per enviar un missatge a tots els clients connectats
- **ws.end**: per tancar el servidor de websockets

```javascript
const webSockets = require('./utilsWebSockets.js');
const ws = new webSockets();

// Gestionar WebSockets
ws.init(httpServer, port);

ws.onConnection = (socket, id) => {
    if (debug) console.log("WebSocket client connected: " + id);
    game.addClient(id);
    socket.send(JSON.stringify({ type: "initial", initialState: game.getInitialState() }));
    socket.send(JSON.stringify({ type: "gameplay", gameState: game.getGameplayState() }));
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

Per optimitzar l'enviament de les dades, s’envia l’estat inicial només quan cal, i l’estat de joc en un format més compacte”.

```javascript
function broadcastGameState() {
  // Send initial state only if there is a new one to send, otherwise just send the gameplay state
  const initialState = game.consumeInitialState();
  if (initialState) {
    ws.broadcast(JSON.stringify({ type: 'initial', initialState }));
  }
  ws.broadcast(JSON.stringify({ type: 'gameplay', gameState: game.getGameplayState() }));
}
```

### Dades del joc

La informació de la pantalla està a la carpeta **'assets'** i ha de ser igual entre el servidor. Cal fer la còpia manualment abans d'iniciar el servidor o cada vegada que es modifiquin les dades:

```javascript
bash getAssets.sh
```

### Bucle de joc i lògica

El servidor executa un bucle que actualitza l'estat del joc a intervals regulars (objectiu 60 FPS) i envia les actualitzacions als clients. Cal definir la funció 'run' de l'objecte 'GameLoop':

```javascript
gameLoop.run = (fps) => {
    game.updateGame(fps);
    broadcastGameState();
};
```

La lògica del joc es gestiona a través de 'GameLogic'. El servidor és autoritari ja que el client no decideix l’estat del joc, el client només envia intencions (register, direction, ...) i el servidor calcula moviment, col·lisions, compte enrere, joies i guanyador.

Per tal d'evitar enviar totes les dades del joc cada vegada, 'initialState' només s'envia quan cal si 'initialStateDirty' és true (per exemple es torna enviar al reiniciar la partida):

```javascript
// Send initial state only once
consumeInitialState() {
    if (!this.initialStateDirty) {
        return null;
    }
    this.initialStateDirty = false;
    return this.getInitialState();
}
```

Les dades del joc s'envien optimitzades, per exemple, només s'envia si les joies estàn visibles o amagades amb un array de 0,1 (i no s'envia tota la informació de cada joia)

```javascript
gemVisibility: this.gems.map((gem) => (gem.visible ? 1 : 0)),
```

> **Nota**: El motiu d'aquesta optimització és evitar enviar grans quantitats de dades innecessàries. La xarxa local no té capacitat infinita i així el joc accepta més jugadors simultanis reduint la latència.

Així queden els dos enviaments:

- **initial**:
    * level name
    * player list base data
    * gem definitions

- **gameplay**: 
    * positions
    * scores
    * match phase
    * countdown
    * visible gems (array de 0,1)
    * moving layers/zones

### Paràmetres de configuració i web de 'Admin'

Per tal de gestionar el reinici de la partida, hi ha disponible la pàgina 'public/admin.html', el seu password es configura a l'arxiu 'config.env' 

```text
PORT=3000
DEBUG_WS=0
WEB_ADMIN_PASSWORD=admin
```

I s'hi accedeix amb:

[http://localhost:3000/admin.html](http://localhost:3000/admin.html)

[https://nomUsuari.ieti.site/admin.html](https://nomUsuari.ieti.site/admin.html)

## Client

Al cantó del client la configuració de la xarxa es centralitza a 'NetworkConfig':

```dart
class NetworkConfig {
  static const String remoteServer = 'nomUsuari.ieti.site';
```

Durant la partida el funcionament per part del client és:

- **Entrada de dades**: es llegeix el teclat però enlloc de moure el jugador directament, el client envia la direcció actual al servidor.

- **Recepció de dades**: el client rep les actualitzacions del servidor a través de "AppData" i dibuixa l'estat del joc a la pantalla.

### Avantatges del model servidor autoritari

- Tots els clients veuen un **món consistent**.
- Evita el *"cheating"* perquè el servidor és l'únic que decideix l'estat del joc.
- Les regles del joc estan **centralitzades**.
- **Clients més simples**, ja que només s'encarreguen de renderitzar i enviar les intencions del jugador.
