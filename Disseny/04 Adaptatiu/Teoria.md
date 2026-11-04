<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2023</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="../assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

# Disseny adaptatiu

## Formats a tenir en compte

Segons orientació hi ha dos formats: 

- Portrait (Vertical)
- Landscape (Horitzontal)

<center><img src="./assets/screenOrientation.png" style="max-height: 150px;" alt="">
<br/></center>
<br/> 

Segons dispositiu hi ha almenys 4 formats: 

- TV
- Desktop
- Tablet
- Phone

<center><img src="./assets/screenFormat.png" style="max-height: 150px;" alt="">
<br/></center>
<br/> 

El format no només afecta el disseny visual, també els mètodes d’entrada:

- Mòbil i tablet l’entrada és amb els dits (o stylus)
- Desktop l’entrada és amb mouse
- TV l’entrada és amb comandament de creueta

## Paradigmes de disseny

Per tal que el disseny d’una aplicació funcioni correctament amb pantalles de mòbil, tablet, ordinador i televisors els dissenyadors han ideat tècniques per tal que una mateixa aplicació s’adapti a diferents circumstàncies.

Actualment imperen dos paradigmes per fer que les aplicacions s’adaptin:

- Responsive
- Adaptive

### Reflexions sobre els paradigmes de disseny

Tradicionalment els dissenyadors han recomanat dissenyar primer per dispositius amb pantalles molt petites (mòbils) i després adaptar aquell disseny a pantalles més grans (tablets, desktop, TV), … 

El millor de dissenyar primer per mòbil i adaptar-ho després a pantalles més grans, és que obliga a simplificar les aplicacions.

No sempre s’han d’oferir opcions per tots els formats, sovint no té sentit que les aplicacions s’adaptin en format ‘Landscape’ (per a videojocs pot ser just el contrari).

### Disseny responsive

Disseny Responsive: l’aplicació posiciona, mostra i amaga els elements segons la mida i orientació de la pantalla. 

<center><img src="./assets/responsive.gif" style="max-height: 150px;" alt="">
<br/></center>
<br/> 

Avantatges:

- Experiència consistent a totes les plataformes
- Funciona en qualsevol dispositiu actual i futur

Desavantatges:

- Poc control sobre com es posicionen els elements en cada dispositiu
- Dificil controlar absolutament totes les casuístiques, pot provocar errors visuals
- Requereix més experiència als dissenyadors i més trucs de disseny
- Pot disminuir el rendiment i la fluïdesa de l’aplicació (o pàgina web)


<center><img src="./assets/responsive1.png" style="max-height: 350px; max-width: 90%;" alt="">
<br/><div style="color: #444444;">Exemple d'aplicació responsive</div></center>
<br/> 
<br/> 

### Disseny adaptive

**Disseny Adaptive:** l’aplicació aplica diferents layouts segons la mida de la pantalla, fent ús del **model-vista-controlador** cada vegada que hi a un canvi de mida de pantalla o orientació es mostra la vista que correspon però aprofitant el controlador. Es creen diferents vistes que fins i tot poden tenir diferents funcionalitats per oferir una experiència més adaptada a l’usuari.

Avantatges:

- Crea una experiència a mida per cada plataforma (mòbil, tablet, desktop, TV)
- Alt rendiment de l’aplicació
- Fàcil de mantenir el disseny o fer modificacions per cada plataforma

Desavantatges:

- Cal afegir nous templates de vistes si apareixen noves plataformes (mòbils plegables, …)


<center><img src="./assets/mvc.png" style="max-height: 350px; max-width: 90%;" alt="">
<br/><div style="color: #444444;">Model-View-Controller</div></center>
<br/> 
<br/> 

### Disseny adaptive, capacitats del dispositiu

Adaptive no té només en compte la mida de la pantalla (o finestra), sinó també les capacitats de la plataforma. 

Així, un layout adaptive pot estar preparat per a ordinadors amb càmera o accés a dades GPS …

En multiplataforma, pot significar accedir a llibreries del sistema que no estan disponibles en altres sistemes.

<center><img src="./assets/adaptivedevice.png" style="max-height: 250px; max-width: 90%;" alt="">
<br/></center>
<br/> 

### Combinació adaptive+responsive

Els dos paradigmes no són excloents, hi ha tanta diversitat de dispositius que es complementen.

Per exemple, una App amb dos templates:

- Template vertical 
- Template horitzontal

Pot adaptar cada un dels templates anteriors segons la mida de la pantalla, per mostrar/amagar o espaiar els elements.

<center><img src="./assets/adaptiveresponsive.png" style="max-height: 250px; max-width: 90%;" alt="">
<br/></center>
<br/> 

## Exemple, calculadora de iPhone

Tenir dos layouts, pot ser una bona excusa per oferir dues experiències diferents.

La calculadora de iOS ofereix una vista científica en posició horitzontal

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
        <img src="./assets/iphonecalculator0.png" alt="">
        <div>Portrait view</div>
    </div>
    <div class="image-item">
        <img src="./assets/iphonecalculator1.png" alt="">
        <div>Landscape view</div>
    </div>
</div>
<br/>

## Exemple, Pages

Pages és un editor de text que té una aplicació adaptativa per iPhone, iPad i Desktop, les següents pàgines mostren una comparació entre els diferents layouts.

<center><img src="./assets/pageslogo.png" style="max-height: 100px; max-width: 90%;" alt="">
<br/></center>
<br/> 

Amb disseny **"adaptive"** es fan servir diferents plantilles/layouts.

- iPhone Portrait
- iPhone Landscape
- iPad Portrait
- iPad Landscape
- macOS

Els detalls, s’acaben d’ajustar amb disseny **"responsive"**

**Obrir un document a l'iPhone:**

<div class="image-container">
    <div class="image-item">
        <img src="./assets/pagesviewiphoneportait.jpeg" style="border: solid 1px lightgray;" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/pagesviewiphoneland.jpeg" style="border: solid 1px lightgray;" alt="">
    </div>
</div>
<br/>
<br/>

**Obrir un document l'iPad:**

<div class="image-container">
    <div class="image-item">
        <img src="./assets/pagesviewipadportrait.gif" style="border: solid 1px lightgray;" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/pagesviewipadland.gif" style="border: solid 1px lightgray;" alt="">
    </div>
</div>
<br/>
<br/>

**Obrir un document a macOS**, enlloc d'una vista, es fa servir el diàleg del sistema normalment

<center><img src="./assets/pagesviewmacos.png" style="max-height: 350px; max-width: 90%;" alt="">
<br/></center>
<br/> 

**Crear un document a l'iPhone**, un diàleg de selecció, demana si es vol crear un document en blanc o escollir una plantilla. Al editar, la toolbar està molt simplificada.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/pagesopeniphone0.png" style="border: solid 1px lightgray;" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/pagesopeniphone1.png" style="border: solid 1px lightgray;" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/pagesopeniphone2.png" style="border: solid 1px lightgray;" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/pagesopeniphone3.png" style="border: solid 1px lightgray;" alt="">
    </div>
</div>
<br/>
<br/>

**Crear un document a l'iPad**, excepte el diàleg d’escollir plantilla, el procés és igual  en tablet que en telèfon.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/pagesopenipad0.png" style="border: solid 1px lightgray;" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/pagesopenipad1.png" style="border: solid 1px lightgray;" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/pagesopenipad2.png" style="border: solid 1px lightgray;" alt="">
    </div>
</div>
<br/>
<br/>

**Crear un document a macOS**, al escollir plantilla a l’escriptori, la barra horitzontal amb les opcions de filtres (Recents, Basic, …) es transforma en un menú tipus sidebar.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/pagesopenmacos0.png" style="border: solid 1px lightgray;" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/pagesopenmacos1.png" style="border: solid 1px lightgray;" alt="">
    </div>
</div>
<br/>
<br/>

**Toolbar de format**, diferent vista i visualització segons la plataforma.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/pagestoolbariphone.png" style="border: solid 1px lightgray;" alt="">
        <div>iPhone, diàleg</div>
    </div>
    <div class="image-item">
        <img src="./assets/pagestoolbaripad.png" style="border: solid 1px lightgray;" alt="">
        <div>iPad, PopOver</div>
    </div>
    <div class="image-item">
        <img src="./assets/pagestoolbarmacos.png" style="border: solid 1px lightgray;" alt="">
        <div>macOS, SideBar</div>
    </div>
</div>
<br/>
<br/>

**Menú de visualització**, diferent segons la plataforma.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/pagesviewmenuipad.png" style="border: solid 1px lightgray;" alt="">
        <div>iPad</div>
    </div>
    <div class="image-item">
        <img src="./assets/pagesviewmenumacos.png" style="border: solid 1px lightgray;" alt="">
        <div>macOS</div>
    </div>
</div>
<br/>
<br/>

Al telèfon, el menú *"View"* agrupa les eines de la toolbar que hi ha a la tablet i desktop.

La opció ‘View’ és un sub-menú d’aquest menú anomenat ‘Opcions de visualització’

Al desplegar el submenú, apareixen les mateixes opcions que hi ha disponibles al menú ‘View’ de tablet i desktop.

<div class="image-container">
    <div class="image-item">
        <img src="./assets/pagesviewmenuiphone0.png" style="border: solid 1px lightgray;" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/pagesviewmenuiphone1.png" style="border: solid 1px lightgray;" alt="">
    </div>
</div>
<br/>
<br/>