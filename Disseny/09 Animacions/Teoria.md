<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2023</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="../assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

# Animacions

Les **animacions** són canvis als objectes o elements cada cert temps, per crear una sensació de moviment.

Es pot animar:

- La posició
- El color
- La mida
- La forma
- … (tot el què es pot canviar matemàticament)

## Frames per segon FPS

Cada imatge d’una animació s’anomena Frame

Una animació està formada per diversos frames

La quantitat de frames que podem mostrar cada segon són els FPS

Com més alta és la quantitat de FPS, més suau es veu l’animació

<center>
<video width="275" height="480" controls autoplay loop>
  <source src="./assets/fps.mov" type="video/mp4">
  El teu navegador no suporta la reproducció de vídeo.
</video>
</center>

## Vídeos vs Animacions

Un **vídeo** és una seqüència d’imatges pre-definida (.mov,  mp4), també tenen pre-definit els FPS als que s’han de mostrar. No es poden “inventar” frames per augmentar els FPS.

Una **animació** defineix les propietats que s’han de canviar i <u>en quin temps s’ha de fer aquest canvi</u>, el nombre de FPS depèn de la capacitat de procés de l’equip i pot variar segons les circumstàncies. 

Una animació **NO** defineix el nombre de FPS, s’entén que sempre serà el més alt possible.

## Paràmetres d’animació

Les animacions es defineixen a partir de:

- Retard (temps que triga a iniciar-se l’animació)
- El valor d’inici (posició inicial, color inicial, mida inicial, …)
- El valor final
- El temps que dura l’animació (pot ser en ms, segons, …)
- Tipus de repetició (si s’executa 1 cop, N cops o infinites vegades)
- Tipus de direcció (si s’inverteix l’inici i el final)
- La funció de transició

### Funció de transició

La funció de transició, defineix com progressa l’animació durant el temps establert.

Normalment, hi ha diversos tipus pre-definits. Per exemple, una funció ‘linear’ és aquella en què tots els valors intermedis són proporcionals al temps que falta per acabar.

<center>
<div>
<img src="./assets/transitionfunction.gif" style="max-width: 90%; max-height: 350px;" alt="">
<img src="./assets/transitionchart.png" style="max-width: 90%; max-height: 350px;" alt="">
</div>
<br/></center>
<br/>
<br/>

## Importància de les animacions

Les animacions permeten simular experiències físiques quan s’interactua amb els objectes virtuals de les pantalles.
Ajuden a millorar l’experiència d’usuari i fer que les interfícies siguin més atractives. 

Les més habituals són:

- Micro-interaccions
- Progrés
- Navegació
- Storytelling

### Micro-interaccions

Informen que una acció s’ha completat, i si s’ha realitzat o no amb èxit.

<center><img src="./assets/micro.gif" style="max-width: 90%; max-height: 350px;" alt="">
<br/></center>
<br/>
<br/>

### Progrés

Animacions que informen de l’estat en què progressa una acció.

- Són determinades si es pot estimar quan acabarà l’acció
- Són indeterminades si no es pot saber quan acabarà

<style>
.image-container {
    display: flex;
    justify-content: space-between;
    width: 100%;
}

.image-item {
    display: flex;
    flex-grow: 1;
    flex-direction: column;
    padding: 0px;
    display: flex;
    justify-content: center;
    align-items: center;
}

.image-item img {
    max-height: 450px;
    height: auto;
    width: auto;
    max-width: 90%;

}

.image-item-small img:first-child {
    max-height: 50px !important;
}

.image-item-big img:first-child {
    max-height: 500px !important;
}

.image-item div {
    color: #444444;
    text-align: center;
}
</style>
<div class="image-container">
    <div class="image-item image-item-small">
        <img src="./assets/progress1.gif" alt="">
        <div>Determinat</div>
    </div>
    <div class="image-item image-item-small">
        <img src="./assets/progress0.gif" alt="">
        <div>Indeterminat</div>
    </div>
</div>
<br/>
<br/>

### Navegació

Les animacions de navegació ajuden a guiar l’usuari a través de la interfície, bé sigui canviant de vistes o mostrant diàlegs.

<div class="image-container">
    <div class="image-item image-item-big">
        <img src="./assets/navigation0.gif" alt="">
        <div>Determinat</div>
    </div>
    <div class="image-item image-item-big">
        <img src="./assets/navigation1.gif" alt="">
        <div>Indeterminat</div>
    </div>
</div>
<br/>
<br/>

### Storytelling

Són aquelles animacions que no estan relacionades amb la interfície, també poden ser decoratives.

Ajuden a millorar l’experiència d’usuari i la relació amb la marca **(branding)**.

<center><img src="./assets/storytelling.gif" style="max-width: 90%; max-height: 350px;" alt="">
<br/></center>
<br/>
<br/>

## Exercicis

1. Digues quin tipus d'animació és cadascuna (micro-interacció, progrés, navegació o storytelling):
    - Un cor que s'omple en fer *m'agrada*
    - Una barra de descàrrega
    - Una pantalla que entra des de la dreta
    - Una mascota que saluda a la pantalla de benvinguda

2. Quin indicador de progrés faries servir, determinat o indeterminat, per a: descarregar un arxiu de 200 MB, i una cerca que no se sap quant trigarà?

3. Grava amb la càmera lenta del mòbil l'animació d'obrir una aplicació. Quant dura? Comença i acaba a la mateixa velocitat, o accelera i frena?
