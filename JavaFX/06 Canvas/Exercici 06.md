<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2024</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="./assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

# Exercici 0

## "Connecta 4" amb JavaFX i WebSockets

El joc ha de tenir **cinc vistes**:

1. **Configuració**  
   - Configura l’URL del servidor i el **nom del jugador**.  
   - Botó per **connectar-se** i continuar.
   - Opció per connectar-se automàticament al servidor local
   - Opció per connectar-se automàticament al servidor Proxmox

2. **Selecció de contrincant**  
   - Mostra una **llista de clients disponibles** (connectats però sense partida en curs).  
   - Permet **enviar i acceptar invitacions** per iniciar partida 1v1.

3. **Sala d’espera / Emparellament**  
   - Mostra l’estat **“Esperant contrincant”** o **“Emparellant…”**.  
   - Quan l’altre jugador accepta, passa automàticament a la partida.

4. **Partida (tauler i joc en temps real)**  
   - **Tauler de 7 columnes (A–G) x 6 files (0–5)**.  
   - El tauler es dibuixa dins un **Canvas JavaFX** i es redibuixa cada cop que canvia l’estat.  
   - **Interacció i torns**:  
     - El jugador amb el torn veu el text **“Et toca jugar”**.  
     - L’altre jugador té la interacció **desactivada**.  
   - **Hover i arrossegament**:  
     - Hi ha una serie de fitxes disponibles a la dreta de la finestra, ordenades aleatòriament com si estiguéssin a sobre d'una taula.
     - El jugador ha d'escollir una de les fitxes del seu color i arrossegar-la a sobre d'una columna del tauler, quan aixeca el botó del mouse *"la fitxa cau"* per aquella columna.  
     - L'oponent ha de veure la posició del mouse del jugador contrari en temps real, com arrossega una fitxa i com la deixa caure al tauler.
   - **Animació de caiguda**:  
     - Quan es juga, la fitxa cau animadament fins a la posició lliure més baixa de la columna.  
   - **Condicions de victòria i empat**:  
     - Guanya qui connecta **4 fitxes consecutives** (horitzontals, verticals o diagonals).  
     - Si el tauler s’omple sense guanyador, és **empat**.

5. **Resultat**  
   - Mostra **Guanyador / Perdedor / Empat**.  
   - Botons per **tornar a la selecció de contrincant** o **tancar**.

---

## Representació gràfica i estils

- **Buit**: cel·la blanca amb vora gris suau.  
- **Fitxa vermella ("R")**: cercle vermell intens.  
- **Fitxa groga ("Y")**: cercle groc.  
- **Hover local**: columna ressaltada amb ombra o gradient suau.  
- **Hover remot (contrincant)**: columna ressaltada amb contorn alternatiu.  
- **Quatre en línia (victòria)**: les 4 cel·les guanyadores s’il·luminen amb efecte (ombra/pulsació).  

> Les etiquetes `"R"` i `"Y"` són internes al model; al Canvas només es veuen els colors.

**Important**:

- S'ha de veure com el contrincant mou la fitxa en temps real, fins que la deixa anar a una columna (còmput servidor)
- S'ha de veure l'animació de la fitxa caient a la seva posició (còmput local)

---

## Normes i flux de joc

- El **servidor** gestiona tota la **lògica de joc**:
  - Validació de torns  
  - Caiguda de fitxes  
  - Detecció de **4 en línia** i **empat**  
  - Sincronització d’estat entre clients
- Els **clients**:
  - **Envien esdeveniments** (connectar, convidar, acceptar, **hover**, **jugada**)  
  - **Renderitzen** l’estat rebut del servidor  
  - Fan servir **Canvas + animacions** per a la UI

---

## Protocol (orientatiu) via WebSocket

Esdeveniments mínims (API - JSON):

- `join { name }`
- `lobby.list { players[] }`
- `invite { to }` / `invite.accept { from }` / `invite.decline`
- `game.start { gameId, youAre: "R"|"Y", firstTurn }`
- `game.move { gameId, posX, posY }` *(s’emet mentre el ratolí es mou sense fitxa)*
- `game.drag { gameId, posX, posY }` *(s’emet mentre el ratolí arrossega una fitxa)*
- `game.play { gameId, column }` *(quan s'ha tirat una fitxa per una columna i s'ha d'animar la caiguda)
- `game.state: ha de portar dades ...
  - board, turn, lastMove, status: "playing"|"win"|"draw", winner?
  - l’snapshot complet del taulell (6×7) per resincro­nitzar els taulells a cada jugador
- `game.end { result: "win"|"lose"|"draw" }`
- `error { message }`

---

## Requisits tècnics

- **JavaFX** per a la interfície (Canvas + escenes).  
- **WebSockets** per a la comunicació temps real (client Java; servidor pot ser Java o un altre llenguatge).  
- **Timeline / Animation** de JavaFX per a les caigudes de fitxes.  
- **ExecutorService** opcional per a tasques d’E/S o timers (no bloquejar el fil d’UI).  
- **CSS JavaFX** per estils generals i textos (missatges de torn, resultat, etc.).  
- **Separació clara** entre:
  - **Vista (UI Canvas + JavaFX)**  
  - **Client WS** (gestió de missatges)  
  - **Model** (estat local derivat del servidor)

> **Important!**: La lògica ha d'estar tota al servidor, els clients només han de mostrar l'estat de les dades que intercanvien amb el servidor

---

## Validacions mínimes

- No es pot jugar en una **columna plena**.  
- Només el **jugador amb torn** pot enviar `game.play`.  
- El servidor rebutja jugades **invàlides** i re-emet l’**estat autoritatiu**.  
- En acabar la partida, la vista 4 queda **en lectura** i es mostra la vista 5 (resultat).

---

## Important

- Fes servir el **format MVN habitual** (projecte Maven).  
- Inclou els scripts **`run.ps1`** i **`run.sh`** per compilar i executar fàcilment el client (i, si escau, el servidor).  
- Documenta al `README.md`:
  - Com **arrencar el servidor**  
  - Com **executar el client**  
  - **Ports**, variables d’entorn i dependències
