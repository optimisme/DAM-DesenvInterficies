<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2023</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="../assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

# Imatges i vectors

## Imatges Raster (píxels)

Computacionalment, les imatges es defineixen a partir de quadres de colors anomenats píxels.

Quan una imatge es defineix a partir d’una matriu de píxels, es diu que és "[raster](https://en.wikipedia.org/wiki/Raster_graphics)"

<center><img src="./assets/raster.png" style="max-width: 90%; max-height: 250px;" alt="">
<br/></center>
<br/>

## Pantalles i píxels

A la pantalla, les imatges també es formen a partir de píxels, però cada tecnología de pantalla pot formar els píxels de manera diferent. 

En general totes ho fan a partir de punts de llum:

- Red (vermell)
- Green (verd)
- Blue (blau)

<center><img src="./assets/screenpixels.png" style="max-width: 90%; max-height: 250px;" alt="">
<br/></center>
<br/>

## Imatges amb transparències, RGBA

Alguns formats d’imatge (png), estàn pensats per poder sobreposar la imatge sobre altres imatges.

Per fer-ho, a part de definir els píxels com a valors RGB, afegeixen el valor de transparència [Alpha](https://en.wikipedia.org/wiki/RGBA_color_model) que defineix quan de transparent és aquell píxel.

<center><img src="./assets/rgba.png" style="max-height: 350px; max-width: 90%;" alt=""> 
<br/></center>
<br/>

**Nota:** Històricament, els programes de fotografia posen una quadricula de fons, per mostrar les parts transparents d’una imatge.

## Anti-aliasing

Anti-aliasing és una tècnica de processament d’imatges, que es fa servir per reduir “les dents de serra” en imatges digitals.

Hi ha diverses maneres de fer anti-aliasing, les més senzilles només mesclen els píxels adjacents i les més complicades intenten tenir en compte les formes geomètriques de les imatges.

<center><img src="./assets/aliasing.png" style="max-height: 350px; max-width: 90%;" alt=""> 
<br/></center>
<br/> 
<br/> 

## Dots per inch, DPI

Quan s’ha d’imprimir una imatge, es parla de DPI que són els punts per cada Inch (2.54 cm) que hi ha en una imatge.

Una imatge a 600DPI tindrà molta més definició que una a 72DPI, ocupant el mateix espai un cop impresses.

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
        <img src="./assets/dpi72.png" alt="">
        <div>DPI 72</div>
    </div>
    <div class="image-item">
        <img src="./assets/dpi600.png" alt="">
        <div>DPI 600</div>
    </div>
</div>
<br/>
<br/>

## Pixels per inch, PPI

Agafant el concepte de DPI per a impressions, les pantalles tenen un valor PPI.

La [densitat de la pantalla](https://m2.material.io/design/layout/pixel-density.html#pixel-density) es defineix en Pixels Per Inch (o PPI). És a dir, quants píxels hi ha en 1 Inch (2.54cm)

<div class="image-container">
    <div class="image-item">
        <img src="./assets/ppilow.png" alt="">
        <div>Low-density display</div>
    </div>
    <div class="image-item">
        <img src="./assets/ppihigh.png" alt="">
        <div>High-density display</div>
    </div>
</div>
<br/>
<br/>

## Pantalles d'alta densitat (retina display)

Retina display és el nom comercial que ha posat Apple als dispositius que tenen les pantalles amb alta densitat de pixels (PPI).

<div class="image-container">
    <div class="image-item">
        <img src="./assets/screeniphone3.png" alt="">
        <div>Pantalla "normal", iPhone 3GS</div>
    </div>
    <div class="image-item">
        <img src="./assets/screeniphone4.png" alt="">
        <div>Pantalla retina, iPhone 4</div>
    </div>
</div>
<br/>
<br/>

**Important:** La idea no és posar més contingut en pantalla, sinó que el mateix contingut estigui més definit.

### Qualitat de les imatges en pantalles d'alta densitat

Els dispositius amb pantalles “no retina”, solen ser més antics i tenir menys capacitat de memòria, per aquests dispositius es fan servir imatges amb menys definició.

Per dispositius amb pantalla retina, solen ser més moderns i tenir més capacitat de memòria, habitualment es fan servir imatges amb el doble de definició.

**Nota:** Per convenció, els arxius amb més definició s’anomenen amb el mateix nom seguit de “@2x”.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/retinavs0.png" alt="">
        <div>iPhone 3GS</div>
    </div>
    <div class="image-item">
        <img src="./assets/retinavs1.png" alt="">
        <div>iPhone 4</div>
    </div>
</div>
<br/>
<br/>

### Aliasing en pantalles d'alta densitat

Quan no oferim una alternativa “@2x” al sistema, en pantalles retina el sistema ha d’agrandar les imatges inventant-se uns píxels que la imatge no té.

Habitualment, al fer més gran una imatge, es dupliquen els píxels, però això produeix “aliasing”, aleshores s’apliquen tècniques d’anti-aliasing que fan la imatge més borrosa.

Idealment oferirem dues imatges, una amb poca definició i una altra “@2x” amb el doble de definició per tal que el sistema no hagi de fer l’escalat.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/imgaliasing.png" alt="">
        <div>Original</div>
    </div>
    <div class="image-item">
        <img src="./assets/imgaliasingresized.png" alt="">
        <div>Escalada</div>
    </div>
    <div class="image-item">
        <img src="./assets/imgaliasing@2x.png" alt="">
        <div>Original@2x</div>
    </div>
</div>
<br/>
<br/>

**Important:** El motiu de no oferir només una imatge amb el doble de definició i que el sistema l’escali a petita, és que habitualment els dispositius sense pantalles retina, no són massa potents.

## Textos en pantalles d'alta densitat

Com que els textos no es formen a partir d’imatges, sinó a partir de la definició de la seva geometria, automàticament es veuen perfectes en pantalles retina.

La llibreria encarregada de dibuixar el text, segons la font escollida, perfila els contorns segons correspongui.

<center><img src="./assets/densitytext.png" style="max-height: 150px; max-width: 90%;" alt=""> 
<br/></center>
<br/> 
<br/> 

## Gràfics vectorials

Els [gràfics vectorials](https://www.digitional.com/a-simple-explanation-of-vector-graphics-illustrations/) ([Vector Graphics](https://www.coreldraw.com/en/learn/guide-to-vector-design/how-do-vector-graphics-work/)) es defineixen a partir de formes geomètriques i coordenades enlloc de matrius de píxels (semblant als textos)

Avantatges:

- Si tenen pocs elements, ocupen molt menys espai que els seu equivalent en imatge.
- Es poden escalar (agrandar) sense perdre definició.
- Es poden animar sense augmentar massa l’espai que ocupen
- El principal inconvenient és que no són adequats per guardar informació fotogràfica.

<center><img src="./assets/inkscape.png" style="max-height: 350px; max-width: 90%;" alt=""> 
<br/><div style="color: #444444;">Inkscape</div></center>
<br/> 
<br/> 

Al igual que els textos, els gràfics vectorials es veuen automàticament bé en pantalles retina.

El motiu és simple, al igual que les tipografies, els gràfics vectorials es defineixen a partir de formes geomètriques i coordenades, per tant el sistema sap com “inventar-se” els píxels per donar més definició. A més, afegeix l’aliasing amb coherència per evitar les "dents de serra"

<center><img src="./assets/retinawatch.png" style="max-height: 150px; max-width: 90%;" alt=""> 
<br/></center>
<br/> 
<br/> 

### Vectoritzar imatges

Del procés de transformar una imatge ‘raster’ en un dibuix vectorial, se’n diu "vectoritzar". Tot i que algunes eines permeten vectoritzar automàticament, tradicionalment s’ha fet "a mà"

<div class="image-container">
    <div class="image-item">
        <img src="./assets/rastertovector0.png" alt="">
        <div>Original, raster</div>
    </div>
    <div class="image-item">
        <img src="./assets/rastertovector1.png" alt="">
        <div>Vectoritzada</div>
    </div>
</div>
<br/>

**Important:** Idealment, els logotips de les empreses tenen una versió vectorial. A més, a les aplicacions s’ha d’intentar fer servir la versió vectorial enlloc de la versió “raster”

## Exemple, mapes!

Al principi de Google Maps, els servidors de Google generaven les imatges dels mapes al servidor i enviaven aquestes imatges als clients.

**Apple va demanar a Google** que canviés la tecnologia de l'aplicació Maps per tal que fós amb dibuixos vectorials enlloc d'imatges descarregades del navegador.

Les avantatges de fer el dibuix amb gràfics vectorials enlloc d'imatges:

- Menys intercanvi de dades, més ràpid de carregar a telèfons mòbils ([fins a un 80% menys](https://bgr.com/general/apple-maps-data-consumption-80-percent-less-than-google-maps/))
- Dibuixios més nítids, adaptats a la densitat de pantalla de cada dispositiu

Google no ho volia, perquè no volia publicar les coordenades de les localitzacions dels seus mapes. I s'hi va negar.

Al final, [Apple va fer]((https://appleinsider.com/articles/12/08/03/inside_apples_new_vector_based_maps_in_ios_6)) la seva pròpia "Apple Maps".

<div class="image-container">
    <div class="image-item">
        <img src="./assets/mapGoogle.png" alt="">
        <div>Google Maps</div>
    </div>
    <div class="image-item">
        <img src="./assets/mapApple.png" alt="">
        <div>Apple Maps</div>
    </div>
</div>
<br/>
<br/>


I ara, Google Maps també és vectorial:

<center><img src="./assets/mapCanvas.png" style="max-height: 500px; max-width: 90%;" alt=""> 
<br/></center>
<br/> 
<br/> 

