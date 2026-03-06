'use strict';
const fs = require('fs');
const gameData = JSON.parse(fs.readFileSync("server/flag_game/game_data.json", "utf8"));
const gameLevel = gameData.levels[0];

const COLORS = ['green', 'blue', 'orange', 'red', 'purple'];
const TICK_FPS = 25;
const FOCUS_WIDTH = 1000;
const FOCUS_HEIGHT = 500;
const FRICTION_FLOOR = 350;
const FRICTION_ICE = 50;
const MOVEMENT_SPEED = 100;
const PLAYER_WIDTH = 32;
const PLAYER_HEIGHT = 32;

const DIRECTIONS = {
    "up":         { dx: 0, dy: -1 },
    "upLeft":     { dx: -1, dy: -1 },
    "left":       { dx: -1, dy: 0 },
    "downLeft":   { dx: -1, dy: 1 },
    "down":       { dx: 0, dy: 1 },
    "downRight":  { dx: 1, dy: 1 },
    "right":      { dx: 1, dy: 0 },
    "upRight":    { dx: 1, dy: -1 },
    "none":       { dx: 0, dy: 0 }
};
 
class GameLogic {
    constructor() {
        this.players = new Map();
        this.tickCounter = 0;
    }

    // Es connecta un client/jugador
    addClient(id) {
        let pos = this.getValidPosition();
        let color = this.getAvailableColor();

        this.players.set(id, {
            id,
            x: pos.x,
            y: pos.y,
            width: PLAYER_WIDTH,
            height: PLAYER_HEIGHT,
            speedX: 0,
            speedY: 0,
            direction: "none",
            color,
            onIce: false
        });
        this.flagOwnerId = "";

        return this.players.get(id);
    }

    // Es desconnecta un client/jugador
    removeClient(id) {
        this.players.delete(id);
    }

    // Tractar un missatge d'un client/jugador
    handleMessage(id, msg) {
        try {
            let obj = JSON.parse(msg);
            if (!obj.type) return;
            switch (obj.type) {
            case "direction":
                if (this.players.has(id) && DIRECTIONS[obj.value]) {
                    this.players.get(id).direction = obj.value;
                }
                break;
            default:
                break;
            }
        } catch (error) {}
    }

    // Blucle de joc (funció que s'executa contínuament)
    updateGame(fps) {
        let deltaTime = 1 / fps;

        this.tickCounter = (this.tickCounter + 1) % TICK_FPS;

        this.players.forEach(player => {
            let moveVector = DIRECTIONS[player.direction];
            
            // Check if player is on ice
            player.onIce = false;
            if (gameLevel && gameLevel.zones) {
                gameLevel.zones.forEach(zone => {
                    if (zone.type === "ice" && this.areRectsColliding(
                        player.x, player.y, player.width, player.height, 
                        zone.x, zone.y, zone.width, zone.height)) {
                        player.onIce = true;
                    }
                });
            }
            
            // Apply movement and friction based on surface
            const friction = player.onIce ? FRICTION_ICE : FRICTION_FLOOR;
            
            // Handle X movement
            if (moveVector.dx !== 0) {
                player.speedX = moveVector.dx * MOVEMENT_SPEED;
            } else {
                if (player.speedX > 0) {
                    player.speedX = Math.max(0, player.speedX - friction * deltaTime);
                } else if (player.speedX < 0) {
                    player.speedX = Math.min(0, player.speedX + friction * deltaTime);
                }
            }
            
            // Handle Y movement
            if (moveVector.dy !== 0) {
                player.speedY = moveVector.dy * MOVEMENT_SPEED;
            } else {
                if (player.speedY > 0) {
                    player.speedY = Math.max(0, player.speedY - friction * deltaTime);
                } else if (player.speedY < 0) {
                    player.speedY = Math.min(0, player.speedY + friction * deltaTime);
                }
            }
            
            // Calculate next position
            let nextX = player.x + player.speedX * deltaTime;
            let nextY = player.y + player.speedY * deltaTime;
            
            // Check collisions with floor areas (unwalkable)
            let canMoveX = true;
            let canMoveY = true;
            
            if (gameLevel && gameLevel.zones) {
                gameLevel.zones.forEach(zone => {
                    if (zone.type === "stone") {
                        // Check X collision
                        if (this.areRectsColliding(
                            nextX, player.y, player.width, player.height,
                            zone.x, zone.y, zone.width, zone.height)) {
                            canMoveX = false;
                        }
                        
                        // Check Y collision
                        if (this.areRectsColliding(
                            player.x, nextY, player.width, player.height,
                            zone.x, zone.y, zone.width, zone.height)) {
                            canMoveY = false;
                        }
                    }
                });
            }
            
            // Apply movement if allowed
            if (canMoveX) {
                player.x = nextX;
            } else {
                player.speedX = 0;
            }
            
            if (canMoveY) {
                player.y = nextY;
            } else {
                player.speedY = 0;
            }
            
            // Check flag collision
            if (this.flagOwnerId == "") {
                let flag = gameLevel.sprites.find(sprite => sprite.type === 'flag');
                if (flag) {
                    let flgCollisionX = flag.x - flag.width / 2;
                    let flgCollisionY = flag.y - flag.height / 2;
                    if (this.areRectsColliding(
                        nextX, player.y, player.width / 2, player.height / 2, 
                        flgCollisionX, flgCollisionY, flag.width, flag.height)) {
                        this.flagOwnerId = player.id;
                    }
                }
            }            
        });
    }

    // Obtenir una posició on no hi h ha ni objectes ni jugadors
    // Obtenir una posició on no hi ha ni objectes ni jugadors
    getValidPosition() {
        // Definir els límits de posició
        const minX = 100;
        const minY = 100;
        const maxX = FOCUS_WIDTH - 100;
        const maxY = FOCUS_HEIGHT - 100;
        
        // Intent màxim per evitar un bucle infinit
        const maxAttempts = 50;
        let attempts = 0;
        
        while (attempts < maxAttempts) {
            // Generar una posició aleatòria dins els límits
            let x = minX + Math.random() * (maxX - minX);
            let y = minY + Math.random() * (maxY - minY);
            
            // Comprovar si la posició col·lisiona amb alguna zona de pedra
            let isValidPosition = true;
            
            if (gameLevel && gameLevel.zones) {
                for (const zone of gameLevel.zones) {
                    if (zone.type === "stone" && this.areRectsColliding(
                        x, y, PLAYER_WIDTH, PLAYER_HEIGHT,
                        zone.x, zone.y, zone.width, zone.height)) {
                        isValidPosition = false;
                        break;
                    }
                }
            }
            
            // Si la posició és vàlida, retornar-la
            if (isValidPosition) {
                return { x, y };
            }
            
            attempts++;
        }
        
        // Si després de varios intents no trobem posició vàlida, tornem un punt central segur
        // (assumint que el centre del mapa no sigui una pedra)
        return { 
            x: (minX + maxX) / 2, 
            y: (minY + maxY) / 2 
        };
    }
    
    // Obtenir un color aleatori que no ha estat escollit abans
    getAvailableColor() {
        let assignedColors = new Set(Array.from(this.players.values()).map(player => player.color));
        let availableColors = COLORS.filter(color => !assignedColors.has(color));
        return availableColors.length > 0 
          ? availableColors[Math.floor(Math.random() * availableColors.length)]
          : COLORS[Math.floor(Math.random() * COLORS.length)];
    }

    // Detectar dos rectangles es sobreposen
    areRectsColliding(r0x, r0y, r0w, r0h, r1x, r1y, r1w, r1h) {
        return (
          r0x < r1x + r1w &&
          r0x + r0w > r1x &&
          r0y < r1y + r1h &&
          r0y + r0h > r1y
        );
    }
    
    // Retorna l'estat del joc (per enviar-lo als clients/jugadors)
    getGameState() {
        return {
            tickCounter: this.tickCounter,
            level: "Level 0",
            players: Array.from(this.players.values()),
            flagOwnerId: this.flagOwnerId
        };
    }
}

module.exports = GameLogic;