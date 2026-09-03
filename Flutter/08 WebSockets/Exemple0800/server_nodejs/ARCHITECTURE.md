# Architecture


## Project Structure

```
server_nodejs/
    ├── server/
    │   ├── app.js              # Entry point — Express + WebSocket orchestration
    │   ├── gameLogic.js        # Core game engine (physics, collision, gems, players)
    │   ├── utilsGameLoop.js    # 60 FPS game loop scheduler
    │   ├── utilsWebSockets.js  # WebSocket server wrapper
    │   ├── utilsGameMessages.js# Message queue with backpressure
    │   ├── multiplayerLevelData.js # JSON-based level/data loader
    │   └── assets/levels/      # Level definitions (game_data.json, tilemaps)
    ├── public/
    │   ├── index.html          # Game client (HTML5 canvas / CanvaKit)
    │   ├── admin.html          # Admin panel
    │   └── canvaskit/          # WebGL canvas rendering
    └── package.json            # NPM dependencies (express, ws, uuid)
```

## Components

### Server-Side

| Module | Description |
|--------|-------------|
| `app.js` | Main entry point. Express HTTP server, WebSocket initialization, game loop start, admin API. |
| `gameLogic.js` | Core game engine. Manages player physics, collision detection, gem collection, game phases (waiting → playing → finished). |
| `utilsWebSockets.js` | WebSocket server wrapper. Handles client connections, message routing, and broadcasting. |
| `utilsGameMessages.js` | Per-client message queues with backpressure control. Supports reliable and replaceable messages. |
| `utilsGameLoop.js` | Fixed 60 FPS game loop scheduler using `setTimeout`-based timing. |
| `multiplayerLevelData.js` | Level data loader. Parses JSON-based level definitions including zones, paths, sprites, and animation clips. |

### Client-Side

| File | Description |
|------|-------------|
| `public/index.html` | Game client rendered via CanvaKit (WebGL canvas). |
| `public/admin.html` | Admin panel for match control. |

## Architecture Diagram

```mermaid
graph TB
    subgraph Client["Client Browser"]
        IC[index.html<br/>Game Client]
        AH[admin.html<br/>Admin Panel]
    end

    subgraph Server["Node.js Server"]
        APP[app.js<br/>Entry Point]:::entry
        EXPRESS[Express HTTP<br/>Server]
        WS[WebSocket<br/>Server]
        GLOOP[GameLoop<br/>60 FPS Loop]:::core
        GLOGIC[GameLogic<br/>Game Engine]:::core
        GMESG[GameMessages<br/>Message Queue]:::core
        WSUTIL[WebSockets<br/>Wrapper]:::core
        LEVEL[MultiplayerLevelData<br/>Level Loader]:::core

        subgraph Levels["Level Data (JSON)"]
            GAME_DATA[game_data.json]
            ZONES[zones/*.json]
            PATHS[paths/*.json]
            TILEMAPS[tilemaps/*.json]
            ANIM[animations.json]
        end

        subgraph Public["Static Files"]
            CANVAS[CanvaKit / WebGL]
            ICONS[Icons / Assets]
        end
    end

    IC <-->|WebSocket| WS
    AH <-->|HTTP REST| EXPRESS

    APP --> EXPRESS
    APP --> WS
    APP --> GLOOP
    APP --> GMESG

    WS --> WSUTIL
    WSUTIL -->|onConnection| GLOGIC
    WSUTIL -->|onMessage| GLOGIC
    WSUTIL -->|onClose| GLOGIC

    GLOOP -->|run(fps)| GLOGIC

    GLOGIC --> GMESG
    GMESG -->|flush| WSUTIL
    GLOGIC --> LEVEL
    LEVEL --> GAME_DATA
    LEVEL --> ZONES
    LEVEL --> PATHS
    LEVEL --> TILEMAPS
    LEVEL --> ANIM

    EXPRESS -->|static| Public
    Public --> CANVAS

    classDef entry fill:#00ff88,stroke:#003300,stroke-width:2px,color:#000
    classDef core fill:#334433,stroke:#00ff88,stroke-width:1px,color:#fff
```

## Data Flow

```mermaid
sequenceDiagram
    participant C as Client<br/>(Browser)
    participant W as WebSocket Server
    participant G as GameLogic
    participant M as GameMessages
    participant L as LevelData

    C->>W: Connect (WebSocket)
    W->>G: addClient(id)
    G->>L: Load level (zones, sprites, paths)
    W-->>C: welcome message + ID

    C->>W: direction message
    W->>G: handleMessage(id, msg)

    loop 60 FPS
        G->>G: updateGame(fps)
        G->>G: advance environment
        G->>G: apply physics & collision
        G->>G: collect gems
    end

    G-->>W: broadcast state
    W->>M: enqueueReplaceable(snapshot)
    W->>M: enqueueReplaceable(gameplay)
    M->>W: flushClient(socket)
    W-->>C: gameplay state update
```

## Object Relationships

```mermaid
classDiagram
    class GameLogic {
        Map players
        Game gem[]
        string phase
        number tickCounter
        addClient(id) Player
        removeClient(id)
        handleMessage(id, msg) bool
        updateGame(fps)
        getSnapshotState() State
        getGameplayState() State
        spawnGems()
        movePlayerWithWallCollisions()
        collectTouchedGems()
    }

    class GameMessages {
        Map~string,Queue~ clientQueues
        number backpressureThreshold
        addClient(id)
        enqueueReplaceable(socket, id, key, msg)
        enqueueReliable(socket, id, msg)
        flushAll()
        flushClient(socket, id) bool
    }

    class WebSockets {
        Map~Socket,Metadata~ socketsClients
        WebSocket.Server ws
        init(httpServer, port)
        send(socket, msg) bool
        broadcast(msg)
        forEachClient(callback)
        hasBackpressure(socket, threshold) bool
    }

    class GameLoop {
        bool running
        number currentFPS
        start()
        stop()
        loop()
        run(fps) virtual
    }

    class LevelData {
        string levelName
        number worldWidth
        number worldHeight
        Layer[] layers
        Zone[] zones
        Sprite[] sprites
        Path[] paths
        PathBinding[] pathBindings
        AnimationClip[] animationClips
        Cell[] gemCells
    }

    class Player {
        string id
        string name
        number x, y
        number width, height
        string direction
        string facing
        bool moving
        number score
        number gemsCollected
        number velocityX, velocityY
        string animationId
        number frameIndex
        bool flipX, flipY
    }

    class Gem {
        string id
        string type
        number x, y
        number width, height
        number value
        bool visible
    }

    GameLogic "1" *-- "0..*" Player
    GameLogic "1" *-- "0..*" Gem
    GameLogic --> LevelData : loads from
    GameLogic --> GameMessages : uses
    GameMessages --> WebSockets : uses
    GameLoop --> GameLogic : calls run()
    GameMessages "1" --* "0..*" MessageQueue

    note for GameLogic "Core game engine:\n- Player physics\n- Collision detection\n- Gem collection\n- Game phases"
    note for WebSockets "WebSocket management:\n- Client connections\n- Broadcasting\n- Backpressure"
    note for GameMessages "Per-client queues:\n- Reliable messages\n- Replaceable messages\n- Backpressure threshold"
    note for GameLoop "Fixed 60 FPS:\n- setTimeout scheduler\n- FPS measurement"
    note for LevelData "JSON level system:\n- Tile maps\n- Zones (walls, ice, sand)\n- Paths & animations\n- Gem placement cells"
```

## Game States

```mermaid
stateDiagram-v2
    [*] --> Waiting
    Waiting --> Playing : lobby timer expires
    Playing --> Finished : all gems collected
    Finished --> Waiting : restartMatch()
    Waiting --> Waiting : client joins

    Playing --> Playing : updateGame(fps)
    Playing --> Waiting : last client disconnects

    note right of Waiting
        Lobby countdown (60s)
        Players join & position
        Gems spawned
    end note

    note right of Playing
        Physics update (60 FPS)
        Collision detection
        Gem collection
        State broadcast
    end note

    note right of Finished
        Winner determined
        By score (desc)
        Then gems collected
    end note
```

## Message Types (Client → Server)

| Type | Description |
|------|-------------|
| `welcome` | Server sends client ID on connect |
| `newClient` | Broadcast when a new client connects |
| `direction` | Client movement input (up, down, left, right + diagonals) |
| `register` | Client registration with player name |
| `restartMatch` | Request to restart the match (from admin) |
| `snapshot` | Full state (players + gems) |
| `gameplay` | Per-player state (position, score, animations) |
| `disconnected` | Client disconnected notification |

## Level System

Levels are defined in JSON files under `server_nodejs/server/assets/levels/`:

| File | Content |
|------|---------|
| `game_data.json` | Level config: viewport, sprites, layers, gem zone |
| `zones/*.json` | Zone definitions (walls, ice, sand, moving platforms) |
| `paths/*.json` | Path definitions for animated elements |
| `tilemaps/*.json` | Tile map grids for rendering layers |
| `animations.json` | Animation clips with frames, hitboxes, FPS |

### Zone Types

- **Wall** (`mur` / `wall`): Blocks player movement
- **Ice** (`ice` / `gel` / `hielo`): Low friction, high deceleration
- **Sand** (`sand` / `sorra` / `arena`): Speed reduction (48%)

### Gem Types

| Type | Count | Value |
|------|-------|-------|
| blue | 500 | 1 |
| green | 250 | 2 |
| yellow | 100 | 3 |
| purple | 50 | 5 |

## Deployment

The server is designed for deployment on a **Proxmox** virtual environment:

- HTTP server on port 3000 (configurable via `PORT` env)
- Admin password via `WEB_ADMIN_PASSWORD` env
- WebSocket for real-time multiplayer
- Level data loaded from JSON files at startup

See `proxmox/TeoriaProxmox.md` for detailed deployment instructions.

## Dependencies

| Package | Purpose |
|---------|--------|
| `express` | HTTP server and static file serving |
| `ws` | WebSocket server |
| `uuid` | Unique client ID generation |
