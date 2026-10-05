<div style="display: flex; width: 100%;">
   <div style="flex: 1; padding: 0px;">
       <p>© Albert Palacios Jiménez, 2024</p>
   </div>
   <div style="flex: 1; padding: 0px; text-align: right;">
       <img src="./assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
   </div>
</div>
<br/>

# Exercici 0 (en grups de 2 a través del Proxy)

Fes un joc de **"Tanks"** multijugador amb **JavaFX, Canvas i WebSockets**, inspirat en el joc de tancs de *Wii Play*.

Video [Tanks, Wii Play!](https://www.youtube.com/watch?v=orLxrg51xL8)

El joc serà per a **dos jugadors** connectats al mateix servidor.

La lògica de la partida la gestiona el servidor. Els clients envien les accions dels jugadors i mostren gràficament l'estat rebut del servidor.

## Vistes

El joc ha de tenir quatre vistes:

- La primera vista configura el servidor al qual s'ha de connectar el client i el nom del jugador.
- La segona vista espera que un contrincant es connecti al servidor i mostra un compte enrrera per començar la partida
- La tercera vista permet jugar la partida.
- La quarta vista mostra el resultat de la partida i permet tornar a la llista de jugadors disponibles.

## Vista de joc

La partida s'ha de dibuixar sobre un **Canvas de JavaFX**.

Cada jugador controla un tanc.

Cada tanc ha de tenir:

- Una posició `X` i `Y`.
- Una direcció de moviment.
- Una torreta que pot apuntar independentment de la direcció del tanc.
- Un nombre determinat de vides.

Els dos jugadors han de veure el mateix escenari i la mateixa posició dels tancs, projectils i obstacles.

## Moviment del tanc

El jugador controla el seu tanc amb les **fletxes del teclat**:

- `↑`: moure el tanc amunt.
- `↓`: moure el tanc avall.
- `←`: girar el tanc cap a l'esquerra.
- `→`: girar el tanc cap a la dreta.

El moviment ha de ser continu mentre la tecla estigui premuda.

El tanc no pot:

- Travessar les parets.
- Sortir dels límits de l'escenari.
- Travessar l'altre tanc.

La detecció de col·lisions s'ha de gestionar al servidor.

## Torreta

La direcció de l'objectiu es controla amb el **mouse**.

L'objectiu ha d'apuntar sempre cap a la posició actual del cursor dins del Canvas.

Per tant, la direcció del cos del tanc i la direcció de la torreta poden ser diferents.

Els altres jugadors han de veure també l'orientació actual de la torreta del contrincant.

## Disparar

El jugador dispara fent **click amb el mouse** sobre el Canvas.

Quan es dispara:

- El projectil apareix direcció l'objectiu.
- El projectil es mou en la direcció on apunta l'objectiu.
- El projectil continua avançant fins que impacta o desapareix.
- El servidor calcula el moviment i les col·lisions del projectil.

Un jugador no pot disparar un nombre il·limitat de projectils simultàniament.

Per exemple, cada jugador pot tenir un màxim de **3 projectils actius**, quan estàn visibles desapareix l'apuntador de l'objectiu. 

## Projectils

Els projectils han de tenir moviment animat.

Un projectil desapareix quan:

- Impacta contra un tanc.
- Supera el seu temps màxim de vida.
- Surt de l'escenari.

Quan un projectil impacta contra un tanc:

- El tanc perd una vida.
- Es mostra una petita animació d'impacte.
- El projectil desapareix.

Opcionalment, els projectils poden **rebotar una vegada contra les parets** abans de desaparèixer.

## Parets i obstacles

Els escenaris han de tenir **parets rectangulars** que funcionen com a obstacles.

Les parets:

- No es poden travessar amb els tancs.
- Bloquegen els projectils.
- S'han de dibuixar sobre el Canvas.

La detecció de col·lisions entre:

- tanc i paret,
- tanc i tanc,
- projectil i paret,
- projectil i tanc

la gestiona el servidor.

## Escenaris

El joc ha de tenir com a mínim **3 escenaris diferents**.

Cada escenari ha de tenir una distribució diferent de parets i obstacles.

Per exemple:

### Escenari 1 — Arena

Un escenari senzill amb quatre obstacles al centre i espais amplis per moure's.

### Escenari 2 — Passadissos

Un escenari format per diverses parets que creen passadissos estrets.

### Escenari 3 — Laberint

Un escenari amb més parets i diversos camins possibles entre els dos extrems.

Cada partida ha d'escollir un escenari.

Pot ser:

- Aleatori.
- Escollit pel servidor.
- Escollit pels jugadors abans de començar.

Els dos clients han de rebre del servidor quin escenari s'està utilitzant.

## Animacions

El Canvas ha de mostrar animacions suaus.

Com a mínim s'ha d'animar:

- El moviment dels tancs.
- La rotació dels tancs.
- La rotació de les torretes.
- El moviment dels projectils.
- Els impactes dels projectils.

Es pot utilitzar `AnimationTimer` per actualitzar i dibuixar l'estat del joc.

## Estat de la partida

A la vista de joc s'ha de mostrar:

- El nom dels dos jugadors.
- Les vides de cada jugador.
- El nombre de projectils actius.
- L'escenari actual.

Per exemple:

```text
Albert ♥♥♥                     Marc ♥♥
Projectils: 1                  Projectils: 2
```

## Final de la partida

Cada jugador comença amb **3 vides**.

Quan un jugador arriba a `0` vides:

- La partida acaba.
- El servidor determina el guanyador.
- Els dos clients passen a la vista de resultat.

La vista de resultat ha de mostrar:

- El jugador guanyador.
- El jugador perdedor.
- Una opció per tornar a la llista de jugadors disponibles.

## Comunicació amb WebSockets

La lògica principal del joc l'ha de gestionar el servidor.

Els clients envien events com:

```text
MOVE_FORWARD
MOVE_BACKWARD
TURN_LEFT
TURN_RIGHT
STOP_MOVE
AIM
FIRE
```

Per l'acció `AIM` es pot enviar la posició del mouse:

```json
{
    "type": "AIM",
    "x": 520,
    "y": 240
}
```

El servidor manté l'estat real de:

- Els jugadors.
- Els tancs.
- Les posicions.
- Les orientacions.
- Les vides.
- Els projectils.
- Les parets.
- Les col·lisions.
- L'escenari.
- El resultat de la partida.

Els clients **no decideixen si una col·lisió o un impacte són vàlids**.

Els clients només:

- Capturen els events de teclat i mouse.
- Els envien al servidor.
- Reben l'estat de la partida.
- Dibuixen aquest estat al Canvas.

## Important

No cal utilitzar imatges per representar els tancs.

Els tancs es poden dibuixar directament sobre el Canvas utilitzant formes simples:

- Rectangle per al cos.
- Rectangle o línia per al canó.
- Cercles per a les rodes o detalls.

La rotació del tanc i de la torreta s'ha de calcular a partir dels angles corresponents.

## Entrega

Ha de ser un repositori compartit pels dos alumnes del grup.

S'ha d'entregar la URL del repositori de GitHub al Moodle.

S'ha de presentar presencialment de manera individual, caldrà respondre les preguntes i no es podrà dir: "això ho va fer el meu company"