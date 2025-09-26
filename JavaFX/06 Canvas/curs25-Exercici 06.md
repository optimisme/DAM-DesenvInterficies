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

Fes el joc de **"Enfonsa la flota"** amb JavaFX i WebSockets.

El joc ha de tenir tres vistes:

- La primera vista configura el servidor al que s'ha de connectar el client i el nom del jugador
- La primera vista configura el servidor al que s'ha de connectar el client i el nom del jugador
- La segona vista escull un contrincant a partir d'una llista de clients disponibles (clients que estàn connectats al servidor però no estàn jugant)
- La tercera vista permet definir la posició dels vaixells
- La quarta vista serà per jugar contra el jugador remot:

    El jugador que té el torn veu un text que diu. "Et toca jugar"

    El jugador que no té el torn té totes les posicions desactivades

    El jugador que no té el torn veu sobre quina posició té el contrincant el mouse, perquè aquesta canvia visiblement de color.

- La quinta vista mostra el resultat.

Les caselles han de ser botons simples, el canvi de color s'ha de fer amb els estils de JavaFX. Les lletres dels botons són:

- "": Un text buit per un botó amb el que no s'ha interactuat. 
- "V": Un botó que té un troç de vaixell nostre. Botó verd.
- "T": Un botó que té un botó que hem encertat de l'adversari. 
- "A": Un botó que hem intentat endevinar però on l'adversari no hi té res.

- "": Botó de color blanc.
- "V": Botó de color verd.
- "T": Botó de color taronja, o vermell quan el vaixell està enfonsat.
- "A": Botó blau.

Les graelles hauràn de ser:

- Horitzontals de la A a la J
- Verticals del 0 al 9

Els vaixells són:

- 1 de 5 espais (Porta avions)
- 1 de 4 espais (Cuirassat)
- 2 de 3 espais (Creuers)
- 2 de 2 espais (Submarí)

La lògica de joc la gestiona el servidor, els clients només mostren l'estat del joc i envien els events.