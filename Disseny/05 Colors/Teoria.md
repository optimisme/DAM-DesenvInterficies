<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2023</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="../assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

# Colors

## Teoria del color

La [teoría del color](https://ca.wikipedia.org/wiki/Teoria_del_color), és un grup de regles bàsiques en la mescla i combinació de colors, per aconseguir efectes visuals que poden fins i tot evocar emocions.

En condicions normals, l’ull humà té cèl·lules sensibles a tres longituds d’ona: la vermella, verda i blava. A partir dels quals veiem la resta de tonalitats. 

<center><img src="./assets/spectrum.png" style="max-height: 350px; max-width: 90%;" alt="">
<br/></center>
<br/> 
<br/> 

### Model RGB

Tradicionalment en pantalles, es fa servir el model RGB, és a dir els colors es formen a partir dels components Red, Green i Blue.

<center><img src="./assets/boxrgb.png" style="max-height: 250px; max-width: 90%;" alt="">
<br/></center>
<br/> 

Depenent de la tecnologia, o el llenguatge de programació, els colors RGB es defineixen amb valors:

- Entre 0.0 i 1.0 (decimals)
- Entre 0 i 255 (enters)
- Entre 00 i FF (hexadecimal)
- Quan es parla de RGBA, la ‘A’ (alpha) fa referència a la transparència.

### Cercle cromàtic

El [cercle cromàtic](https://ca.wikipedia.org/wiki/Cercle_crom%C3%A0tic) mostra els colors visibles distribuïts en un cercle.

- Els colors en posicions oposades del cercle s’anomenen “Complementaris”

- Els colors dos colors del costat a un color del cercle s’anomenen “Anàlegs”

<center><img src="./assets/colorcircle.png" style="max-height: 275px; max-width: 90%;" alt="">
<br/></center>
<br/> 

Algunes guies de disseny ([material](https://m2.material.io/design/color/the-color-system.html#color-usage-and-palettes)) expliquen com fer servir el cercle cromàtic per definir els colors primari i secundari de les aplicacions.

### Colors i emocions

**Colors càlids:** es relacionen amb emocions fortes com la passió o l’amor.  Es consideren colors intensos i es fan servir quan es vol afegir joventut o emoció als dissenys.

<center><img src="./assets/colorfeel0.png" style="max-height: 25px; max-width: 90%;" alt="">
<br/></center>
<br/> 

**Colors freds:** es relacionen amb calma, relaxació, lleialtat. Es consideren colors de confiança i es fan servir en la imatge de marques (especialment el blau per bancs i el verd per ecologisme)

<center><img src="./assets/colorfeel1.png" style="max-height: 25px; max-width: 90%;" alt="">
<br/></center>
<br/> 

**Colors neutrals:** es relacionen amb elegancia i neutralitat. Es consideren colors subtils que i es fan servir com a fons, o per fer resaltar colors d’accent.

<center><img src="./assets/colorfeel2.png" style="max-height: 25px; max-width: 90%;" alt="">
<br/></center>
<br/> 

### Paleta de colors

Una paleta de colors és una combinació de colors, que combinen entre ells, i defineixen la imatge de la marca del producte.

<center><img src="./assets/colorpalette.png" style="max-height: 75px; max-width: 90%;" alt="">
<br/></center>
<br/> 

La paleta de colors ha de definir almenys:

- **Color principal** que es fa servir més a l’aplicació i els seus components (imatge de la marca)
- **Color secundari** és opcional i serveix per complementar al principal i fer que el color principal “no cansi”
- **Colors de superfície o fons**, solen ser neutres i complementen al principal i secundari
- **Colors d’atenció**, són colors de la paleta relacionats amb missatges d’error i alerta

### Contrast dels colors

Els icones i textos s’han de llegir amb claredat, això s’aconsegueix fent que hi hagi molt contrast entre la informació i el seu fons.

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
    max-height: 150px;
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
        <img src="./assets/colorcontrast0.png" alt="">
        <div>Lectura fàcil</div>
    </div>
    <div class="image-item">
        <img src="./assets/colorcontrast1.png" alt="">
        <div>Dificultat per llegir</div>
    </div>
</div>
<br/>

Comparació entre el nou "Liquid Glass" amb l'antic "Frozen Glass" de Apple. S'ha perdut claredat:

<center>
<img src="./assets/liquidvsfrozen.png" style="max-width: 400px" alt="">
</center>

Cal tenir en compte, que hi ha [persones amb dificultats visuals](https://blog.iamsuleiman.com/techniques-to-display-text-overlay-background-images/), no poden llegir bé els textos si no hi ha prou contrast amb el fons.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/colorcontrast2.png" alt="">
        <div>Lectura fàcil</div>
    </div>
    <div class="image-item">
        <img src="./assets/colorcontrast3.png" alt="">
        <div>Dificultat per llegir</div>
    </div>
</div>
<br/>

El contrast, pot fer resaltar un element o botó i induir a l’usuari a fer accions més fàcilment.

<center><img src="./assets/colorcontrast4.png" style="max-height: 450px; max-width: 90%;" alt="">
<br/></center>
<br/> 
<br/> 

### Modes clar i fosc

Avantatges del mode fosc:

- Menys fatiga visual, al rebre menys llum de la pantalla

- Més bateria ja que la pantalla no emet tanta energia (llum)

- Millor visualització de colors i contrastos en aplicacions de disseny

<div class="image-container">
    <div class="image-item image-item-big">
        <img src="./assets/themelight.png" alt="">
    </div>
    <div class="image-item image-item-big">
        <img src="./assets/themedark.png" alt="">
    </div>
</div>
<br/>
<br/>

Actualment, les pròpies llibreries del sistema deixen escollir si les aplicacions fan servir els mòdes clar i/o fosc.

Tradicionalment:

- Les aplicacions de disseny (fotos, vídeo, 3D) han fet servir GUIs fosques
- Les aplicacions d’oficina han fet servir GUIs clares
- Les aplicacions de desenvolupament i programació solen deixar escollir a l’usuari

<div class="image-container">
    <div class="image-item image-item-big">
        <img src="./assets/themephotoshop1985.png" alt="">
        <div>Photoshop 1985</div>
    </div>
    <div class="image-item image-item-big">
        <img src="./assets/themephotoshop2023.png" alt="">
        <div>Photoshop 2023</div>
    </div>
</div>
<br/>
