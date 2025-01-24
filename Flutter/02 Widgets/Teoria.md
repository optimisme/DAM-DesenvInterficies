<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2023</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="./assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

<br/>
<center><img src="./assets/dartlogo.png" style="max-height: 75px" alt="">
<br/></center>
<br/>
<br/>

# Widgets

A Flutter tot el codi s’organitza en ‘widgets’ o ‘components’, es tracta d’objectes Dart que permeten definir la interfície i el codi al mateix temps.

[**Vídeo:** Widget of the week](https://youtu.be/b_sQ9bMltGU?si=wiXBiHsV3wY5vycc)

Com que Flutter és molt flexible, es poden fer aplicacions amb estètica Material (Android) o bé Cupertino (iOS), però són dos conjunts de widgets diferents.

La [documentació](https://api.flutter.dev/) té molts exemples de com fer servir els objectes, i un munt de mini tutorials al seu canal de [YouTube](https://www.youtube.com/@flutterdev)

Els catàlegs de widgets i la seva documentació es pot trobar a:

- Material, [catàleg](https://docs.flutter.dev/ui/widgets/material) i [documentació](https://api.flutter.dev/flutter/material/MaterialApp-class.html)

- Cupertino, [catàleg](https://docs.flutter.dev/ui/widgets/cupertino) i [documentació](https://api.flutter.dev/flutter/cupertino/CupertinoApp-class.html)

**Nota:** La documentació de ‘Cupertino’ no és tan complerta com la de Material

Els Widgets s’organitzen en una estructura d’arbre, és a dir hi ha un widget principal que té un o més widgets fills, i cada un d’aquests widgets també poden tenir un o més fills.

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
        <img src="./assets/widgetstree0.png" alt="">
    </div>
    <div class="image-item">
        <img src="./assets/widgetstree1.png" alt="">
    </div>
</div>
<br/>

## key identificadora dels Widgets

Per identificar els Widgets a l'aplicació, cada un té una referència **"key"**. Aquesta clau es posa automàticament amb el constructor al fer *{super.key}*:

```dart
class MainAnimationScreen extends StatefulWidget {
  const MainAnimationScreen({super.key});

  @override
  MainAnimationScreenState createState() => MainAnimationScreenState();
}
```

## Codi Flutter, ‘childs’ i ‘children’

Molts widgets de Flutter necessiten que es defineixen altres elements dins. La notació sol ser:

- L’atribut **"child"** si en aquella posició hi va un altre widget.
- L’atribut **"children"** si en aquella posició i va una llista de widgets.

```dart
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text('Nintendo DB'),
    ),
    body: Row(
      children: <Widget>[
        _sideBar(),
        ChangeNotifierProvider(
          create: (context) => AppData(),
          child: const FineWidget(),
        )
      ],
    )
  );
}
```

**Nota:** Es recomana que els atributs *child* o *children* siguin els últims que es defineixen de la llista d'atributs.

Gairebé tots els elements de les aplicacions s’organitzen amb **"Rows"** o **"Columns"**.

<br/>
<center><img src="./assets/widgetstree2.png" style="max-height: 400px" alt="">
<br/></center>
<br/>

**Exemple0200:**

En aquest exemple s'organitza una aplicació en una columna que conté dues files, la primera amb números i la segona amb botons:

```dart
@override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('$_firstNumber'),
                const SizedBox(width: 20),
                Text('$_secondNumber'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CupertinoButton.filled(
                  onPressed: _incrementFirstNumber,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Text('Increment First Number'),
                ),
                const SizedBox(width: 10),
                CupertinoButton.filled(
                  onPressed: _decrementSecondNumber,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Text('Decrement Second'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CupertinoButton(
              onPressed: _resetNumbers,
              child: const Text('Reset Numbers'),
            ),
          ],
        ),
      ),
    );
  }
```

<br/>
<center><img src="./assets/ex0200.png" style="max-height: 400px" alt="">
<br/></center>
<br/>

**Nota:** El widget *"SizedBox"* permet espaiar elements entre ells de manera ràpida.

Per facilitar encara més la construcció de layouts, hi ha altres elements com: 

- [ListView](https://api.flutter.dev/flutter/widgets/ListView-class.html) per definir una llista amb scroll
- [GridView](https://api.flutter.dev/flutter/widgets/GridView-class.html) per fer graelles d’elements també amb scroll

## Codi Flutter, maquetació i codi

Com es pot veure, flutter permet organitzar el codi de manera que coincideixi amb la presentació visual de l'aplicació. Això ho fa definirnt els nous objectes com atributs dels anteriors.

També es podria fer a la manera *tradicional*, aquests dos codis són equivalents:

```dart
body: Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '$_firstNumber',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(width: 20),
          Text(
            '$_secondNumber',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ElevatedButton(
            onPressed: _incrementFirstNumber,
            child: const Text('Increment First Number'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _decrementSecondNumber,
            child: const Text('Decrement Second Number'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _resetNumbers,
            child: const Text('Reset Numbers'),
          ),
        ],
      ),
    ],
  ),
)
```

```dart
@override
  Widget build(BuildContext context) {

    final firstRowSizedBox = const SizedBox(height: 20);
    final secondRowSizedBox0 = const SizedBox(height: 20);
    final secondRowSizedBox1 = const SizedBox(height: 20);
    final columnSizedBox = const SizedBox(height: 20);

    final firstNumberText = Text(
      '$_firstNumber',
      style: Theme.of(context).textTheme.headlineMedium,
    );

    final secondNumberText = Text(
      '$_secondNumber',
      style: Theme.of(context).textTheme.headlineMedium,
    );

    final incrementFirstNumberButton = ElevatedButton(
      onPressed: _incrementFirstNumber,
      child: const Text('Increment First Number'),
    );

    final decrementSecondNumberButton = ElevatedButton(
      onPressed: _decrementSecondNumber,
      child: const Text('Decrement Second Number'),
    );

    final resetNumbersButton = ElevatedButton(
      onPressed: _resetNumbers,
      child: const Text('Reset Numbers'),
    );

    final firstRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[firstNumberText, firstRowSizedBox, secondNumberText,],
    );

    final secondRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[incrementFirstNumberButton, secondRowSizedBox0,
        decrementSecondNumberButton, secondRowSizedBox1, resetNumbersButton],
    );

    final children = <Widget>[firstRow, columnSizedBox,secondRow];

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Number Manipulation'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
```

Es pot veure com és més difícil relacionar el codi amb la presentació visual en aquest segon cas.

## Tipus de widgets

Segons la seva funció, la [documentació](https://docs.flutter.dev/ui/widgets) de Flutter organitza els Widgets en diferents tipus. Les principals:

- [Animation and motion](https://docs.flutter.dev/ui/widgets/animation): per fer animacions i transicions
- [Assets, images and icons](https://docs.flutter.dev/ui/widgets/assets): per adjuntar imatges i arxius amb les aplicacions
- [Basics](https://docs.flutter.dev/ui/widgets/basics): els widgets imprescindibles en qualsevol aplicació
- [Input](https://docs.flutter.dev/ui/widgets/input): per fer formularis
- [Interaction](https://docs.flutter.dev/ui/widgets/interaction): per capturar events (clicks, taps, …)
- [Layout](https://docs.flutter.dev/ui/widgets/layout): per organitzar els widgets (maquetació i disposició)
- [Scrolling](https://docs.flutter.dev/ui/widgets/scrolling): per afegir scrolls quan els widgets sobrepasen la mida disponible
- [Styling](https://docs.flutter.dev/ui/widgets/styling): per canviar l'aspecte visual dels widgets

## Codi dels widgets, estructura d’arbre

Imaginem que volem apilar una imatge a sobre d’un text (al damunt visualment, no sobreposada), aleshores haurem de fer servir un widget columna.

**"Column"** permet definir els fills a través del paràmetre *"children"*, que ha de ser un array  de Widgets.

- La funció *"asset"* de l’objecte imatge té l’arxiu a mostrar com a paràmetre

- El text es defineix amb un String i opcionalment amb un estil.

```dart
Column(
    children: [
        Image.asset('images/lake.jpg'),
        Text('Hello World'),
    ],
);
```

**Exemple 0201:**

Codi:

```dart
body: Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 150,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/cat.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 150,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/dog.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    ],
  ),
),
```

En aquest codi es mostren dues imatges, els widgets *ClipRRect* s'encarregen de centrar la imatge dins d'un relleu arrodonit.

<br/>
<center><img src="./assets/ex0201.png" style="max-height: 400px" alt="">
<br/></center>
<br/>

El codi flutter aprofita el fet que amb Dart els paràmetres dels constructors poden ser opcionals, per oferir centenars d’objectes amb desenes de configuracions depenent dels paràmetres que poses al constructor.

Per exemple, el widget **"MaterialApp"** defineix el widget principal d’una aplicació amb estètica *Material*:

```dart
return MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Aplicació Flutter',
    theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
    ),
    home: _setLayout(context),
)
```

## Codi dels widgets, atributs

[Scaffold](https://api.flutter.dev/flutter/material/Scaffold-class.html) accepta dos atributs, una barra de títol superior [AppBar](https://api.flutter.dev/flutter/material/AppBar-class.html) i un cos *"body"*.

En aquest exemple el cos és una fila hortizontal [Row](https://api.flutter.dev/flutter/widgets/Row-class.html) amb dos elements, una ‘_sideBar’ generada per la funció ‘_sideBar() i [Expanded](https://api.flutter.dev/flutter/widgets/Expanded-class.html) ocupa la resta d’espai amb el què genera la funció ‘_content()’.

```dart
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text('Nintendo DB'),
    ),
    body: Row(
      children: <Widget>[
        _sideBar(),
        Expanded(child: _content())
      ],
    )
  );
}
```

## Widget Container

El widget container és un widget genèric al que se li pot donar estil.

```dart
Container(
    decoration: const BoxDecoration(
        color: Colors.black26,
    ),
    child: Column(
        children: [
            _buildImageRow(1),
            _buildImageRow(3),
        ],
    ),
)
```

<br/>
<center><img src="./assets/container.png" style="max-height: 200px" alt="">
<br/></center>
<br/>

Quan un Widget sobrepassa la mida disponible, Flutter mostra una barra d’error amb la zona en conflicte.

<br/>
<center><img src="./assets/overflow.png" style="max-height: 200px" alt="">
<br/></center>
<br/>

Els widgets han d’estar ben dimensionats, o posats a dins d’altres widgets que gestionin aquesta situació:

- [Scrolls](https://docs.flutter.dev/ui/layout/scrolling) ([widgets amb scroll integrat](https://docs.flutter.dev/ui/widgets/scrolling))
- [Transformacions](https://api.flutter.dev/flutter/widgets/Transform-class.html)
- …

## Widget ListView

El widget ListView permet definir diversos widgets fills i s’encarrega de gestionar l’scroll automàticament. (També horitzontal)

<br/>
<center><img src="./assets/list.png" style="max-height: 300px" alt="">
<br/></center>
<br/>

## Construir a partir de Widgets (builder)

A vegades la llista de widgets que s’han de mostrar, depenen de la informació que hi ha en un array o llista.

En aquest cas es fa servir un **builder** per tal que els elements es formin automàticament a partir d’un únic exemple que s'aplica a tots els ítems de la llista

En aquest l’exemple de llista es diu ‘data’ i es formen elements amb un text ‘nom’ i una imatge.

```dart
return ListView.builder(
  itemCount: data.length,
  itemBuilder: (BuildContext context, int index) {
    return ListTile(
      title: Text(
        data[index]['nom'],
        style: const TextStyle(fontSize: 12),
      ),
      leading: Image.asset(
        'assets/images/${data[index]["imatge"]}',
        height: 35.0,
        width: 35.0,
        fit: BoxFit.contain,
      ),
      onTap: () => {
        setState(() => item = index)
      }
    );
  }
);
```

## Widgets amb estat i sense estat

Per motius d’optimització i rendiment, hi ha dos tipus de widgets els que tenen informació del seu estat (poden canviar valors que fan el dibuix diferent) i els que no (no canvien els valors).

### Widgets sense estat (StatelessWidget)

Els widgets **"stateless"** no tenen estat, i per tant no poden tenir informació que canvia durant l’execució de l’aplicació.

Poden rebre paràmetres al constructor i tenir funcions, però no canvien l’estat.

```dart
class LayoutPersonatge extends StatelessWidget {
    final dynamic itemData;

    // Constructor
    LayoutPersonatge({Key? key, required this.itemData}) : super(key: key);

    // Retornar un 'Color' a partir del text, fent servir el mapa de colors anterior
    Color getColorFromString(String colorString) {
        return colorMap[colorString.toLowerCase()] ?? Colors.black;
    }

    @override
    Widget build(BuildContext context) {
        return Text(“Hola”);
    }
}
```

### Widgets amb estat (StatefulWidget)

Els widgets **"stateful"** tenen estat, és a dir variables que poden canviar de valor i haver de redibuixar el widget.

L’estat es defineix en una clase apart, on també es defineix el mètode *"build"*

Els paràmetres que es reben són final (constants) i es poden accedir des de l’estat amb *"widget.parametre"*, en l’exemple anterior *"widget.seccio"*

```dart
class LayoutMobileScreen0 extends StatefulWidget {

    final String seccio;
    const LayoutMobileScreen1({Key? key, required this.seccio}) : super(key: key);

    @override
    State<LayoutMobileScreen0> createState() => _StateLayoutMobileScreen0();
}

class _StateLayoutMobileScreen0 extends State<LayoutMobileScreen0> {

    _StateLayoutMobileScreen0();

    @override
    Widget build(BuildContext context) {
        return Text(“Hola”);
    }
}
```
### Widgets, "accions" i "setState"

A vegades els widgets permeten definir una acció, per exemple ‘onTap’ és si l’usuari toca el widget.

En aquest cas, l’atribut ‘onTap’ accepta una funció, que és l’acció a realitzar si l’usuari toca el widget.

Quan fem canvis que canvien els continguts del widget, els posem dins de ‘setState’ per avisar a Flutter que ha de redibuixar la pantalla.

```dart
return ListView.builder(
  itemCount: data.length,
  itemBuilder: (BuildContext context, int index) {
    return ListTile(
      title: Text(
        data[index]['nom'],
        style: const TextStyle(fontSize: 12),
      ),
      leading: Image.asset(
        'assets/images/${data[index]["imatge"]}',
        height: 35.0,
        width: 35.0,
        fit: BoxFit.contain,
      ),
      onTap: () => {
        setState(() => item = index)
      }
    );
  }
);
```

## Animacions

Flutter permet animar fàcilment propietats matemàtiques dels atributs.

[**Vídeo:** Animations](https://youtu.be/HHzAJdlEj1c?si=VqwJi7RreLQYmtQo)

Per fer animacions cal:

- Un **AnimationController**, que permet iniciar/pausar l'animació i defineix el tipus d'animació
- La propietat **Animation<tipus>** que es vol animar

Cal sobreescriure el mètode *initState* per configurar adequadament l'animació:

```dart
@override
void initState() {
  super.initState();
  _controller = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
    lowerBound: 0.15, // Valor mínim de l'animació
  );
  // Tipus d'animació
  _animation = CurvedAnimation(parent: _controller, curve: Curves.ease)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _wasGrowing = false;
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _wasGrowing = true;
        _controller.forward();
      }
    });
}
```

Cal sobreescriure el mètode *dispose* per lliberar la memòria correctament quan el widget ja no està disponible:

```dart
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

**Exemple 0202:**

En aquest exemple es veu com fer una animació que modifica l'escalat d'un widget, fent-lo més gran o més petit. Té dos botons per iniciar i pausar l'animació.

```bash
cd exemple0202
flutter run -d macos
```

<br/>
<center><img src="./assets/ex0202.png" style="max-height: 400px" alt="">
<br/></center>
<br/>
<br/>






