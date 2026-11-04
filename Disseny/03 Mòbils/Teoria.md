<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2023</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="../assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

# UI en dispositius mòbils

## L’escriptori de dispositius mòbils

Els dispositius mòbils prenen el concepte d’escriptori, però amaguen el sistema d’arxius per seguretat.

El nou paradigma, es basa en aplicacions que accedeixen a carpetes d’arxius específiques (la pròpia de l’aplicació, fotografies, documents, …)

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
    max-height: 250px;
    height: auto;
    width: auto;
    max-width: 90%;

}

.image-item div {
    color: #444444;
    text-align: center;
}
</style>
<div class="image-container">
    <div class="image-item">
        <img src="./assets/desktoppalm.png" alt="">
        <div>Palm Pilot, 1997</div>
    </div>
    <div class="image-item">
        <img src="./assets/desktopiphone.png" alt="">
        <div>iPhone, 2007</div>
    </div>
</div>
<br/>

**Nota:** També s'hereta el *"dock"* estil OSX

### Interacció, gestures

La interacció es realitza de manera tàctil, és a dir, hi ha una connexió directa entre l’entrada i els elements de la pantalla. 

Aquest fet, va introduir una nova manera d’interactuar amb els elements anomenada “gestures”:

- Tap: tocar la pantalla i aixecar el dit ràpid
- Double tap: tocar la pantalla dos cops de manera ràpida
- Drag: tocar la pantalla moure el dit en una direcció i aixecar-lo
- Pinch: Pessigar la pantalla amb dos dits
- Zoom: El contrari que ‘pinch’, separar els dits
- Panning: Tocar la pantalla amb un dit, moure’l sense aixecar-lo

<center><img src="./assets/gestures.png" style="max-width: 90%;" alt="">
<br/></center>
<br/>

[Handling gesture events](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/HandlingEvents/HandlingEvents.html)

### Finestres en dispositius mòbils

En general, la falta d’espai visual dels dispositius mòbils, fa que les aplicacions s’executin a pantalla completa.

A més, les diferents accions s’organitzen en sub-vistes creant una sensació de navegació.

Generalment hi ha una manera estàndard de tornar enrere cap a la vista anterior, que es manté per totes les aplicacions del sistema operatiu.

<center><img src="./assets/mobilewindows.gif" style="max-height: 400px;" alt="">
<br/></center>
<br/>

### Disseny de storyboards

La quantitat de sub-vistes, i la seva relació (la manera de navegar entre aquestes), es pot fer complexa ràpidament.

Per aquest motiu quan es dissenya l’aplicació, es fa un “storyboard” amb totes les pantalles, i definint la navegació entre elles.

<center><img src="./assets/storyboards.png" style="max-width: 90%;max-height: 400px;" alt="">
<br/></center>
<br/> 

### Superposició de capes, shadows

Quan s’han de sobreposar elements, cal marcar bé els límits entre aquests. Bé sigui perquè es mostren diàlegs, o perquè es mouen elements per la pantalla. 

La guia de material design (Android), fa aquesta separació amb l'**[elevació](https://m3.material.io/styles/elevation/overview)**: ombres i, a Material 3, també un canvi de to en el color de fons.

Com més ombra, més elevació i per tant més separació visual entre elements.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/shadows0.png" alt="">
        <div>Ombra en mostrar el menú</div>
    </div>
    <div class="image-item">
        <img src="./assets/shadows1.gif" alt="">
        <div>Ombra en arrossegar</div>
    </div>
</div>
<br/>

<div class="image-container">
    <div class="image-item">
        <img src="./assets/shadows2.png" alt="">
        <div>Bon ús d'ombres, per ressaltar un pop-over o botons</div>
    </div>
    <div class="image-item">
        <img src="./assets/shadows3.png" alt="">
        <div>Mal ús, elements amb ombres sobreposades a altres</div>
    </div>
</div>
<br/>

### Superposició de capes, glassmorphism

Algunes aplicacions, combinen les ombres amb **[glassmorphism](https://platzi.com/tutoriales/1640-frontend-developer-2019/9482-glassmorphism/)**. 
Amb aquesta tècnica, la separació visual s’aconsegueix a partir de superfícies transparents amb el fons desenfocat.

Crea l’efecte d’un vidre congelat, *frozenglass*

<div class="image-container">
    <div class="image-item">
        <img src="./assets/glass0.gif" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/glass1.png" alt="">
    </div>
</div>
<br/>

### ListView i navegació en dispositius mòbils

La manera natural de navegar entre sub-vistes en dispositius mòbils és a través de llistes i pantalles informatives o formularis.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/listview0.png" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/listview1.png" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/listview2.png" alt="">
    </div>
</div>
<br/>

### GridView, disposició dins d'una vista

A vegades, una graella és una opció més adequada que una llista per mostrar un conjunt de ítems.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/grid0.png" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/grid1.png" alt="">
    </div>
</div>
<br/>

### Mida dels elements seleccionables

Cal tenir en compte que els dispositius mòbils solen interactuar a través dels dits, i per tant els elements interactius **no poden ser petits ni estar molt junts**.

Es recomana que els botons siguin com a mínim de **48x48 dp** a Android (**44x44 punts** a iOS).

Els **dp** (*density-independent pixels*) i els **punts** són unitats independents de la densitat de la pantalla: 48 dp ocupen el mateix espai físic en una pantalla normal que en una d'alta densitat (veure la lliçó d'imatges i vectors).

Això vol dir que els elements de les llistes i les graelles han de ser com a mínim de 48 dp d’alt.

<center><img src="./assets/select.png" style="max-height: 250px;" alt="">
<br/></center>
<br/> 

### Top bars, informació i accions

La barra superior de l’aplicació, [top bar](https://m3.material.io/components/top-app-bar/overview), mostra un títol amb informació sobre la secció o sub-vista actual, i accions ràpides.

Quan es tracta d’una sub-vista, és una bona pràctica incloure el botó d’anar enrere. Aquest botó pot incloure el nom de la secció anterior.

Si la barra superior inclou una imatge de fons, els textos i els icones han de ser llegibles

<div class="image-container">
    <div class="image-item">
        <img src="./assets/topbar0.png" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/topbar1.png" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/topbar2.png" alt="">
    </div>
</div>
<br/>

### Tab bars, navegació entre seccions

Algunes aplicacions fan ús de **[tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)** (també anomenades [navigation bar](https://m3.material.io/components/navigation-bar/overview)), es tracta d’un element situat a la part inferior que permet organitzar les aplicacions en diferents **seccions** (continguts).

Les **tab bars** han d’ajudar a la navegació, no han d'oferir accions, ni opcions ni eines. És a dir una tab bar **NO equival a la toolbar**.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/tabbar0.png" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/tabbar1.png" alt="">
    </div>
</div>
<br/>

### Action sheets, alerts, popovers i altres diàlegs

Els **[dialogs](https://developer.apple.com/design/human-interface-guidelines/presentation)** són petites finestres que es mostren per sobre de la finestra d’aplicació i bloquegen el contingut d’aquesta.

Poden ser alertes que demanen la confirmació d’una acció, o una llista d’opcions.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/dialogs0.gif" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/dialogs1.png" alt="">
    </div>
</div>
<br/>

### Navigation drawer

Els [panells de navegació](https://m3.material.io/components/navigation-drawer/overview), són diàlegs que poden mostrar menús, llistes d’accions, eines i fins i tot configuracions.

<center><img src="./assets/drawer.gif" style="max-height: 250px;" alt="">
<br/></center>
<br/> 

### Snackbar (toast)

Les **snackbar** són barres informatives que apareixen a la part inferior de la pantalla.
Poden tenir accions associades
Poden desaparèixer per si soles
NO trenquen la interactivitat de l’aplicació

<center><img src="./assets/snackbar.png" style="max-height: 250px;" alt="">
<br/></center>
<br/> 

**Nota:** No són diàlegs, ja que no bloquegen la interacció amb l’aplicació

## Quin element escollir?

| Necessitat                                                    | Element                                  |
|---------------------------------------------------------------|------------------------------------------|
| Moure's entre 3 i 5 seccions principals                       | Tab bar                                  |
| Més de 5 seccions, o seccions que es fan servir poc           | Navigation drawer                        |
| Veure el detall d'un element d'una llista                     | Sub-vista, amb el botó d'anar enrere     |
| Accions sobre la vista actual                                 | Botons a la top bar                      |
| Confirmar una acció important o destructiva (esborrar, pagar) | Alert                                    |
| Escollir entre diverses opcions d'una acció (compartir, …)    | Action sheet                             |
| Informar que una acció s'ha fet, sense interrompre            | Snackbar                                 |
| Molts elements visuals (fotos, productes)                     | GridView en lloc de ListView             |

## Exercicis

1. Dibuixa en paper el storyboard d'una aplicació de receptes amb aquestes vistes: llista de receptes, detall d'una recepta, receptes preferides i configuració. Marca amb fletxes com es navega entre les vistes.

2. Fent servir la taula *Quin element escollir?*, decideix quin element faries servir a l'aplicació de receptes per:
    - Esborrar una recepta
    - Avisar que una recepta s'ha afegit a preferides
    - Moure's entre *Receptes*, *Preferides* i *Configuració*
    - Compartir una recepta

3. Busca al teu mòbil un botó que costi de tocar. Per què costa? És massa petit, o està massa a prop d'un altre botó?
