<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2023</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="../assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

# Maquetació

## Planificació de la maquetació (layout)

Abans de començar a programar la interfície, cal organitzar-se i decidir quins continguts són més important, com es relacionen i s’agrupen, tenint en compte:

- Les tasques s’han de completar fàcilment
- Han de ser agradables de fer servir
- Ha de ser senzill aprendre com funcionen
- L’usuari ha de poder desfer errors

<center><img src="./assets/intro.png" style="max-width: 90%; max-height: 250px;" alt="">
<br/></center>
<br/>

## Alineació

Textos, imatges, botons i altres elements s’han d’alinear de manera coherent i deixant expai suficient entre els límits de la pantalla i/o aplicació

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

.image-item-big img:first-child {
    max-height: 500px !important;
}

.image-item div {
    color: #444444;
    text-align: center;
}
</style>
<div class="image-container">
    <div class="image-item">
        <img src="./assets/alignwrong.png" alt="">
        <div>Lectura difícil</div>
    </div>
    <div class="image-item">
        <img src="./assets/alignright.png" alt="">
        <div>Facilitat de lectura</div>
    </div>
</div>
<br/>
<br/>

### Alineació visual

L’alineació visual té en compte com s’organitzen els elements a la pantalla, tenint en compte que són un conjunt global.

L’alineació visual, inclou la separació d’elements segons funcionalitat o contingut, per exemple les toolbars, sidebars, tab bars, …

<center><img src="./assets/visualalign.png" style="max-width: 90%; max-height: 350px;" alt="">
<br/></center>
<br/>
<br/>

## Espaiat

Per fer dissenys nets i entenedors, cal fer un bon ús de les distàncies entre elements.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/spacingwrong.png" alt="">
        <div>Lectura difícil</div>
    </div>
    <div class="image-item">
        <img src="./assets/spacingright.png" alt="">
        <div>Facilitat de lectura</div>
    </div>
</div>
<br/>
<br/>

## Lleis de la proximitat

Les [lleis de la proximitat](https://en.wikipedia.org/wiki/Principles_of_grouping) expliquen com s’han d’espaiar els elements d’una GUI:

- Els elements que estan relacionats, s’han de posar més junts.
- Els elements que no estan relacionats, han d’estar més separats o amb eines visuals excloents entre ells.
- En llistes o grups de dos o més elements, la separació entre ells ha de ser proporcional, si els elements són del mateix tipus.

<center><img src="./assets/proximitylaws.png" style="max-width: 90%; max-height: 350px;" alt="">
<br/></center>
<br/>
<br/>

## Sistema d'espais

Quan es defineix un disseny, és interessant definir quin serà l’espaiat entre elements, i mantenir-lo en tota l’aplicació.

- Mida dels títols, texts, …
- Marges i Paddings dels elements
- Distància entre elements d’un formulari, botons, …

Així es manté una coherència visual i s’assegura que els dissenys 

<center><img src="./assets/spacingsystem.png" style="max-width: 90%; max-height: 350px;" alt="">
<br/></center>
<br/>
<br/>

### Recomanacions

- Intentar que les distàncies siguin iguals o proporcionals als extrems

- Cal que els elements interactius siguin més grans de 48x48 dp i distants d’altres elements interactius

<center><img src="./assets/spacingrecommendations.png" style="max-width: 90%; max-height: 350px;" alt="">
<br/></center>
<br/>
<br/>

A vegades cal que hi hagi **contrast** en les distàncies, és a dir, cal que les distàncies entre elements no siguin similars per marcar una diferència visual.

En els següents dos exemples, es veu com augmentar l’espai entre els ítems de la llista, fa que es vegi millor a quina imatge pertanyen les accions "Download" i "Bookmark"

<div class="image-container">
    <div class="image-item">
        <img src="./assets/spacingcontrastwrong.png" alt="">
        <div>Sense diferenciació d'ítems</div>
    </div>
    <div class="image-item">
        <img src="./assets/spacingcontrastright.png" alt="">
        <div>Amb espaiat entre ítems</div>
    </div>
</div>
<br/>
<br/>

### Espaiat dels títols

Igualment, els títols han de tenir més contrast amb els continguts anteriors.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/spacingtitlewrong.png" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/spacingtitleright.png" alt="">
    </div>
</div>
<br/>
<br/>

### Espaiar per agrupar elements comuns

A vegades, no espaiar elements, fa que quedin agrupats i sigui més fàcil veure la diferència entre seccions i continguts.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/spacinggroupwrong.png" alt="">
        <div>Massa espai entre elements</div>
    </div>
    <div class="image-item">
        <img src="./assets/spacinggroupright.png" alt="">
        <div>Agrupació d'elements</div>
    </div>
</div>
<br/>
<br/>

Compactar continguts, implica tenir en compte que s’ha d’organitzar els elements per ocupar l’espai disponible de manera coherent.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/spacingorganizedwrong.png" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/spacingorganizedright.png" alt="">
    </div>
</div>
<br/>
<br/>


### Espaiar per agrupar seccions

En layouts verticals, on es posen molts continguts en un sol scroll, les seccions han de quedar ben distingides les unes de les altres.

<center><img src="./assets/spacingsections0.png" style="max-width: 90%; max-height: 350px;" alt="">
<br/></center>
<br/>
<br/>

En la mesura del possible, s’ha d’intentar que el contingut visual de cada secció, estigui definit i compactat dins l’espai visible de la pantalla.

De no ser així, ha de quedar clar que hi ha un continuació amb scroll.

<center><img src="./assets/spacingsections1.png" style="max-width: 90%; max-height: 350px;" alt="">
<br/></center>
<br/>
<br/>

### Colors per espaiar seccions

Fer servir diferents colors de fons és una bona manera de mostrar les diferències entres seccions.

<center>
<video width="275" height="480" controls>
  <source src="./assets/colors.mov" type="video/mp4">
  El teu navegador no suporta la reproducció de vídeo.
</video>
</center>

## Scrolls horitzontals

En general, **NO** s’han de fer servir scrolls horitzontals

En cas de posar-los, ha de quedar clar que hi ha més continguts “a la dreta”

També és recomanable posar indicador de posició de l’scroll, indicant la posició actual i els límits

<div class="image-container">
    <div class="image-item">
        <img src="./assets/horizscroll0.png" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/horizscroll1.gif" alt="">
    </div>
</div>
<br/>
<br/>

## Dropdowns amb sentit

Els dropdowns (seccions desplegables), han de ser entenedores.

També han d'incloure una icona que mostri si la secció està plegada o desplegada

<div class="image-container">
    <div class="image-item">
        <img src="./assets/dropdownwrong.png" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/dropdownright.png" alt="">
    </div>
</div>
<br/>
<br/>

## Exercicis

1. Dibuixa un formulari de registre (nom, correu, contrasenya i botó d'enviar) fent servir un sistema d'espais de 8 en 8 (8, 16, 24, 32). Indica cada distància.

2. Fes una captura d'una pantalla de configuració del teu mòbil i marca els grups d'elements. L'espaiat ajuda a veure quins elements van junts?

3. Busca una web o aplicació amb elements mal alineats. Dibuixa com quedaria ben alineada.
