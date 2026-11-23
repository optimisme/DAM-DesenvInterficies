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

# Dart (per programadors Java)

[Dart](https://dart.dev/overview) és el llenguatge de programació de *Flutter*

És un llenguatge desenvolupat per Google i de codi lliure que serveix per programar aplicacions i també servidors.

Pots trobar la [guia completa](https://dart.dev/language) de programació en Dart a la documentació oficial.

La comanda **"dart"** que permet compilar codi Dart, s’instal·la automàticament amb Flutter.

## Dart i JavaScript

Originalment es volia fer un llenguatge per substituir JavaScript, però que oferís rendiment i velocitat. Això no va passar, i sembla que Dart està aconseguint posicionar-se gràcies a Flutter.

Dart pot **transpilar** el codi a JavaScript amb aquesta instrucció:

```bash
dart compile js test.dart
```

**Nota:** Això genera una sortida *"out.js"* amb el codi transformat a JavaScript, el codi generat està optimitzat, i si és molt complexe pot funcionar millor que escriure el codi directament amb JavaScript.

## Cos del programa

Dart serveix per fer tot tipus de programes, també de línia de comandes.

Els arxius de programació Dart tenen l’extensió **".dart"**, i una funció *main* que és el punt d'entrada/inici:

```dart
void main() {
    print('Hello, World!');
}
```

**Exemple0100:**

Per compilar i executar codi Dart simplement es pot fer:

```bash
cd exemple0100
dart arxiu.dart
```

## Comentaris

Els comentaris 'inline' (d'una linia) començen a partir de les dues barres //

Els comentaris 'multiline' (múltiples línies) es posen entre /* (per començar el comentari) i */ (per tancar el comentari)

```dart
// Comentari d'una sola línia
/*
    Comentari de
    múltiples línies
*/
```

## Variables

La paraula clau *"var"* fa que automàticament s’asigni un tipus a la variable, també es pot definir el tipus al declarar la variable

```dart
    var nameA = 'Bob'; // Automàticament és String
    String nameB = 'Bob'; // String
    Object nameC = 'Bob'; // Object
```

Els principals tipus són:

```text
	int, double, String, bool, List, Set, Map,
	Symbol, Object, Enum, Future, Iterable
```

**Exemple0101:**

```bash
cd exemple0101
dart arxiu.dart
```

Codi:

```dart
void main() {
  // Crear una llista amb exemples de diferents tipus de dades
  var dades = [
    {"tipus": "int", "valor": 123},
    {"tipus": "double", "valor": 3.14},
    {"tipus": "string", "valor": "Hola, món!"},
    {"tipus": "bool", "valor": true},
    {
      "tipus": "list",
      "valor": [1, 2, 3]
    },
    {
      "tipus": "tuple",
      "valor": [1, 2, 3]
    }, // Dart no té tuples natius, usar llistes
    {
      "tipus": "set",
      "valor": {1, 2, 3}
    },
    {
      "tipus": "map",
      "valor": {"clau": "abc"}
    }
  ];

  // Iterar a través de la llista i imprimir cada tipus de dada amb el seu valor
  for (var item in dades) {
    print("Tipus: ${item['tipus']}, Valor: ${item['valor']}");
  }
}
```

Sortida:

```text
Tipus: int, Valor: 123
Tipus: double, Valor: 3.14
Tipus: string, Valor: Hola, món!
Tipus: bool, Valor: true
Tipus: list, Valor: [1, 2, 3]
Tipus: tuple, Valor: [1, 2, 3]
Tipus: set, Valor: {1, 2, 3}
Tipus: map, Valor: {clau: abc}
```

### Variables, exemples de números

```dart
    var x = 1; // int
    var hex = 0xDEADBEEF; // int
    var y = 1.1; // double
    var exponents = 1.42e5; // double
    num x = 1; // double
    double z = 1; // igual que double 'z = 1.0' o var 'z = 1.0'
    var one = int.parse('1'); // String -> int
    var onePointOne = double.parse('1.1'); // String -> double
    String oneAsString = 1.toString(); // int -> String
    String piAsString = 3.14159.toStringAsFixed(2); // double -> String
```

### Variables, exemples de Strings

```dart
    // Cadenes de text amb ' o bé amb "
    var a1 = 'Single quotes work well for string literals.';
    var a2 = "Double quotes work just as well.";
    var a3 = 'It\'s easy to escape the string delimiter.';
    var a4 = "It's even easier to use the other delimiter.";

    // Concatenació de cadenes
    var b1 = 'String '
        'concatenation'
        " works even over line breaks.";
    var b2 = 'The + operator ' + 'works, as well.';

    // Cadenes de múltiples línies
    var c1 = '''
        You can create
        multi-line strings like this one.
        ''';

    var c2 = """This is also a
     multi-line string.""";
```

### Variables, exemples de Strings amb informació de variables

```dart
    String name = "🇩🇰Tom";
    int times = 3;
    String sentence = "$name is going to walk the dogs $times times per day";
    print(sentence);
```
Produeix la sortida:

    🇩🇰 Tom is going to walk the dogs 3 times per day

### Null safety

Dart és un llenguatge **"Null safety"**, això vol dir que preveu errors produits per variables assignades a *'null'*

- Per poder assignar ‘null’ a una variable, aquesta s’ha d’haver definit amb un ?
- S’entén que assignar ‘null’ a variables és una pràctica perillosa i no es recomana fer-ho
- Si una variable no s’ha iniciat amb cap valor, el compilador dóna un error quan es volen fer servir
- Les variables que s’inicien amb ? sense valor, automàticament són ‘null’

```dart
String? nameA; 
// nameA automàticament s’assigna ‘null’, 
// més tard pot contenir una cadena de text

String nameB; 
// nameB no pot ser ‘null’, 
// si es fa servir sense iniciar-la el compilador falla
```

### Null safety i late

A vegades, Dart interpreta que una variable no s’ha iniciat quan si que ho farem abans de fer-la servir. 

Per indicar-li al compilador que no hi ha cap problema amb aquella variable, es pot fer servir la paraula clau **"late"**

```dart
late String description; // Això donaría error sense el 'late'

void main() {
    description = 'Feijoada!';
    print(description);
}
```

## Operacions matemàtiques

Les operacions matemàtiques són semblants a Java:

```dart
void main() {
  int sum = 2 + 3;
  print('sum = $sum');

  int a = 3;
  a += 5; // Ara el valor de 'a' serà 8
  a -= 2; // Ara el valor de 'a' serà 6
  print('a = $a');

  int b = (2 + 3) * 4;
  print('b = $b');

  double c = (2 * 2) + (4 * 4);
  print('c = $c');

  int d = 10 * 2 ~/ 5; // En Dart, usa ~/ per a divisió sencera
  print('d = $d');

  int e = 10 % 3 % 2;
  print('e = $e');

  int f = 10 + 2 - 5;
  print('f = $f');
}

```

### Metadades

Les metadades permeten posar anotacions al codi:

- **@override**: Quan es sobreescriu la funció d’una clase heredada
- **@Todo(‘Missatge’)**: Quan es vol anotar que fata codi per programmar
- **@Deprecated(‘Missatge’)**: Quan un codi està en desús

```dart
class Television extends ScreenView {

    @Deprecated('Use turnOn instead')

    void activate() {
        turnOn();
    }

    @override
    void turnOn() {
        @Todo("Program this function")
    }
}
```

## Operacions de text

Dart té moltes funcions i objectes per manipular cadenes de text.

```dart
void main() {
  // Cadena inicial
  String text = "Hola Món, Món és un lloc bonic.";
  
  // Longitud
  int longitud = text.length;
  print("Longitud: $longitud");
  
  // Concatenació
  String salutacio = "$text Des de Dart!";
  print("Concatenació: $salutacio");
  
  // Indexació
  String lletra = text[0];
  print("Caràcter en índex 0: $lletra");
  
  // Subcadena
  String subcadena = text.substring(0, 4);
  print("Subcadena: $subcadena");
  
  // Repetició
  String repetit = "ha" * 3;
  print("Repetició: $repetit");
  
  // Conversió
  String majuscules = text.toUpperCase();
  print("A majúscules: $majuscules");
  
  // Ordenar
  List<String> lletres = text.split('');
  lletres.sort();
  String ordenat = lletres.join();
  print("Ordenat: $ordenat");
  
  // Substitució
  String substituit = text.replaceAll("Món", "Dart");
  print("Substitució: $substituit");
  
  // Cerca
  int index = text.indexOf("Món");
  print("Índex de 'Món': $index");
  
  // Invertir
  String invertit = text.split('').reversed.join('');
  print("Invertit: $invertit");
  
  // Canviar totes les aparicions d'una paraula
  String canviParaula = text.replaceAll("Món", "Terra");
  print("Canvi de paraules: $canviParaula");
}
```

## Random, números aleatòris

Per generar nombres aleatoris, s'utilitza la classe **Random** del paquet *dart:math*. Aquí tens una explicació i un exemple de com fer-ho en Dart:

```dart
import 'dart:math';

void main() {
  // Crear una instància de Random
  Random random = Random();

  // Generació de nombres aleatoris
  double aleatori = random.nextDouble(); // Genera un número aleatori entre 0.0 i 1.0 (no inclòs)

  // Genera un número aleatori entre 0 i 100 tots dos inclosos
  int aleatoriEntre0i100 = random.nextInt(101); // nextInt(101) genera un número entre 0 i 100

  // Imprimir resultats
  print("Número aleatori entre 0.0 i 1.0: $aleatori");
  print("Número aleatori entre 0 i 100: $aleatoriEntre0i100");
}
```

## Funcions

Per definir una funció, cal el valor de retorn i el tipus dels paràmetres.

```dart
bool esParell(int valor) {
    return valor % 2 == 0;
}

void main() {
    print('Són parells?');
    print('4: ${esParell(4)}');
    print('5: ${esParell(5)}');
    print('6: ${esParell(6)}');
}
```

Aquest codi escriu:

```text
Són parells?
4: true
5: false
6: true
```

### Funcions amb paràmetres opcionals

Dart permet posar paràmetres opcionals a les funcions.

Els paràmetres opcionals s’han de posar tots dins de { } separats en comes. 

```dart
void escriuParell(int valor, {String nom = "num", int? extra }) {
    bool esParell = valor % 2 == 0;
    if (nom == "num") {
        print('El valor ${valor} és parell: ${esParell}');
    } else {
        print('El valor ${nom} és parell: ${esParell}');
    }
}

void main() {
    escriuParell(4);
    escriuParell(5, nom: 'cinc');
}
```

Aquest codi escriu: El valor 4 és parell: true \\n El valor cinc és parell: false

**Important:** Es recomana iniciar els paràmetres opcionals amb un valor, si no es vol definir un valor per defecte es pot posar ? i s’inicien a null (com el paràmetre "extra")

### Funcions asíncrones

Les funcions **"async"** són aquelles que no sabem quan trigaràn a executar-se, perquè depenen d’un servei extern (llegir arxius, connectar amb un servidor, un procés paral·lel, …)

Les hem de definir com **"async"** i cridar-les amb **"await"**

```dart
String getDades (String url) async {
	var dades = “”;
    @Todo("Obtenir les dades")
    return dades;
}

void main() {
    var dades = await getDades("http://dades.com")
}
```

## Control de fluxe, if/else i switch

Pel funcionament de 'if' i 'else' cal tenir en compte que:

- Si hi ha multiples línies afectades per la condició, es posen totes entre { i }

- Si només hi ha una linia implicada a la condició opcionalment es pot posar al costat de la condició sense claus

**Nota:** Per netedat, us recomano fer servir claus, també per si en un futur cal afegir línies de codi a la condició

```dart
void main() {
    if (isRaining()) {
        you.bringRainCoat();
    } else if (isSnowing()) {
        you.wearJacket();
    } else {
        car.putTopDown();
    }
}
```

```dart
void main() {
    var command = 'OPEN';
    switch (command) {
        case 'CLOSED':
            executeClosed();
        case 'PENDING':
            executePending();
        case 'APPROVED':
            executeApproved();
        case 'DENIED':
            executeDenied();
        case 'OPEN':
            executeOpen();
        default:
            executeUnknown();
    }
}
```

## Control de fluxe, loops while i for

El bucle 'for' té 3 paràmetres:

- El comptador inicial de la variable que compte en quina posició del bucle ens trobem

- La condició de sortida, és a dir la condició que mentre es compleix executem el codi del bucle

- La operació que apliquem al contador, a cada iteració del bucle (a l'exemple sumem un 1 a i a cada iteració)

```dart
void main() {
var message = 'Dart is fun';
    for (var i = 0; i < 4; i++) {
        print('${message[i]}');
    }
}
```

La sortida és

```text
D
a
r
t
```

També es poden recórrer tots els elements d’un array amb **"in"**:

```dart
void main() {
    var arr = ['AB', 'CD', 'EF'];
    for (final x in arr) {
        print('${x}');
    }
}
```

La sortida és

```text
AB
CD
EF
```

Es poden recórrer tots els elements d’un array amb **"forEach"**, la sortida és:

```dart
void main() {
    var arr = [1, 4, 8];
    arr.forEach(print);
}
```

La sortida és

```text
1
4
8
```

O bé definint el cos de la funció:

```dart
void main() {
    var arr = [1, 4, 8];
    arr.forEach((int value) {
        print(value * 2);
    });
}
```

La sortida és

```text
1
4
8
```

Exemple de *while*:

```dart
void main() {
  int count = 0;

  // Bucle while
  while (count < 5) {
    print('El valor de count és: $count');
    count++;
  }
}
```

Exemple de *do while*:

```dart
void main() {
  int count = 0;

  // Bucle do-while
  do {
    print('El valor de count és: $count');
    count++;
  } while (count < 5);
}
```

## Collections (llistes)

Les col·leccions actuen com els arrays, però accepten tipus heterogenis.

```dart
void main () {
    var listA = [1, 2, 3];
    var listB = [1, "Hi", 3, "Bye"];

    print(listA);
    print(listB);
    print('${listA[1]} : ${listB[3]}');
    print('Llargada de listA: ${listA.length}');
}
```

Aquest exemple escriu:

```text
[1, 2, 3]
[1, Hi, 3, Bye]
2 : Bye
Llargada de listA: 3
```

## Records (semblant a mapes)

Els *"Records"* són tuples que contenen elements, si es vol que continguin altres objectes s’ha de definir el tipus com *<String, dynamic>*. 

```dart
void main() {
    var recordA = <String, dynamic> {
        'first': 'first',
        'a': 2,
        'b': true,
        'last': {
        'name': 'Patri',
        'age': 24
        },
    };
    recordA['last']['age'] = 25;

    print('Element: ${recordA['first']},'
        ' b: ${recordA['b']},'
        ' age: ${recordA['last']['age']}');
}
```

La sortida és:

```text
Element: first, b: true, age: 25
```

### Records amb 'as'

Aquests codis són equivalents, quan no s’ha definit el tipus del ‘Record’, es pot definir al final amb un ‘as’ o bé deixar que el sistema l’infereixi automàticament

```dart
void main() {
    var recordA = <String, dynamic> {
        'first': 'first',
        'a': 2,
        'b': true,
        'last': {
            'name': 'Patri',
            'age': 24
        },
    };
}

```

```dart
void main() {
    var recordA = {
        'first': 'first',
        'a': 2,
        'b': true,
        'last': {
            'name': 'Patri',
            'age': 24
        },
    } as Map<String, dynamic>;
}
```

### Records, posició amb $X

Els elements d’un ‘Record’ poden no tenir etiqueta, i bé tant si la tenen com si no, podem accedir-hi amb $X on X és el número que correspon a la posició.

```dart
    void main() {
    var pair = (42, 'a', b: true, 'last');

    print('Number: ${pair.$1}, String: ${pair.$2}, Boolean: ${pair.$3}');
}
```

Aquest codi escriu:

```text
Number: 42, String: a, Boolean: last
```

## Llibreries (aka import)

Per carregar llibreries es fa servir ‘import’

Si dues llibreries coincideixen amb nom, es poden evitar conflictes amb la paraula reservada **"as"**:

```dart
import 'package:lib1/lib1.dart';
import 'package:lib2/lib2.dart' as lib2;

// Uses Element from lib1.
Element element1 = Element();

// Uses Element from lib2.
lib2.Element element2 = lib2.Element();
```

Per importar altres arxius *".dart"* que estàn a la carpeta *lib*:

```dart
import 'altrecodi.dart';
```

## Excepcions (try/on/catch/finally)

```dart
void main() {
  try {
    // Codi que pot llençar una excepció
    int result = 10 ~/ 0; // Això llençarà una excepció de divisió per zero
    print('El resultat és: $result');
  } on IntegerDivisionByZeroException catch (e) {
    // Aquest bloc s'executa si es llença una excepció de divisió per zero
    print('S\'ha produït una excepció de divisió per zero: $e');
  } catch (e) {
    // Aquest bloc s'executa per qualsevol altra excepció
    print('S\'ha produït una excepció: $e');
  } finally {
    // Aquest bloc s'executa sempre, independentment de si s'ha llençat una excepció o no
    print('Això s\'executa sempre');
  }
}
```

### Llançar excepcions amb throw

Per llançar excepcions es fa servir **throw**:

```dart
void main() {
  try {
    // Llençar una excepció
    validarEdat(-5);
  } on FormatException catch (e) {
    // Capturar una excepció específica
    print('S\'ha produït una FormatException: $e');
  } catch (e) {
    // Capturar qualsevol altra excepció
    print('S\'ha produït una excepció: $e');
  } finally {
    // Aquest bloc s'executa sempre
    print('Això s\'executa sempre');
  }
}

void validarEdat(int edat) {
  if (edat < 0) {
    // Llençar una excepció personalitzada
    throw FormatException('L\'edat no pot ser negativa: $edat');
  } else {
    print('L\'edat és vàlida: $edat');
  }
}
```

## Entrada de dades per consola

Per llegir dades del teclat a través de la consola cal importar *dart:io*:

**Exemple 0102:**

```bash
cd exemple0102
dart arxiu.dart
```

```dart
import 'dart:io';

void main() {
  double suma = 0.0;
  print("Introdueix un número (decimals amb .) o escriu 'sortir' per acabar:");

  while (true) {
    stdout.write("La suma actual és $suma\nIntrodueix un número o 'sortir': ");
    String? input = stdin.readLineSync();

    if (input == null) {
      continue;
    }

    if (input.toLowerCase() == 'sortir') {
      print("Finalitzant l'aplicació. La suma final és $suma");
      break;
    }

    try {
      double numero = double.parse(input);
      suma += numero;
    } catch (e) {
      print("Error, cal escriure un número o 'sortir'");
    }
  }
}
```

La sortida és:

```text
La suma actual és 0.0
Introdueix un número o 'sortir': 5
La suma actual és 5.0
Introdueix un número o 'sortir': 3
La suma actual és 8.0
Introdueix un número o 'sortir': 9
La suma actual és 17.0
Introdueix un número o 'sortir': sortir
Finalitzant l'aplicació. La suma final és 17.0
```

## Classes

Les classes són molt flexibles, hi ha diferents maneres de definir els constructors:

- **Tradicional**: Amb el nom de la classe i els paràmetres
- **Automàtica**: Amb el nom de la classe, però els paràmetres ja *setegen* els atributs
- **Valors per defecte**: Defineix valors per defecte

Aleshores cada un dels mètodes anterios dóna flexibilitat amb la manera de cridar els constructors, per exemple:

```dart
class PointA {
    double x = 0;
    double y = 0;

    // Constructor tradicional
    PointA(double x, double y) {
        this.x = x;
        this.y = y;
    }
}
class PointB {
    double x = 0;
    double y = 0;

    // Constructor setteja automàticament x i y
    PointB(this.x, this.y);
}
class PointC {
    double x = 0;
    double y = 0;

    // Constructor usant noms de paràmetres
    PointC({this.x = 0, this.y = 0});
}
void main () {

    // Crear una instància (no cal new)
    var p0 = PointA(2, 5);
    print('p0: ${p0.x} és x i ${p0.y} és y');

    // Equival al constructor tradicional
    var p1 = PointB(2, 5);
    print('p1: ${p1.x} és x i ${p1.y} és y');

    // Els constructors amb noms de paràmetres
    var p2 = PointC(y: 2, x: 5);
    print('p2: ${p2.x} és x i ${p2.y} és y');
}
```

La sortida és:

```text
p0: 2.0 és x i 5.0 és y
p1: 2.0 és x i 5.0 és y
p2: 5.0 és x i 2.0 és y
```

### Funcions de les classes

Els mètodes de les classes han de definir un valor de retorn (o *void*):

```dart
import 'dart:math';

class Point {
    final double x;
    final double y;

    Point(this.x, this.y);

    double distanceTo(Point other) {
        var dx = x - other.x;
        var dy = y - other.y;
        return sqrt(dx * dx + dy * dy);
    }
}

void main () {

    var p0 = Point(4, 10);
    var p1 = Point(2, 8);
    var distance = p0.distanceTo(p1);

    print('Distància entre p0 i p1: ${distance}');
}
```

Sortida:

```text
Distància entre p0 i p1: 2.8284271247461903
```

## Atributs i mètodes privats

**Important!**, a Dart les definicions d’atributs que començen per _ són considerades privades a aquella classe.

En aquest exemple, *_counter* i *_incrementCounter* són un atribut i un mètode privats!

```dart
mixin logicScreen0<T extends StatefulWidget> on State<T> {
    int _counter = 0;

    void _incrementCounter() {
        setState(() {
            _counter++;
        });
    }
}
```

## Sobreescriure mètodes amb @override

**@override** permet sobreescriure funcions heretades (en aquest cas al no ser objecte fill no és estrictament necessari)

```dart
class Point extends SinglePoing {

    final double x;
    final double y;

    Point(this.x, this.y);

    @override
    String toString() {
        return '${this.x}x${this.y}';
    }
}
```

Sortida:

```text
Punts: 4.0x10.0, 2.0x8.0
```

## Getters i Setters

Hi ha flexibilitat a la hora de definir els Getters i Setters:

- *"inline"* amb *"=>"* si només és una linia
- Múltiples linies amb mètodes normals entre claus *{*, *}*

```dart
class Rectangle {
    double left, top, width, height;

    Rectangle(this.left, this.top, this.width, this.height);

    // Define calculated properties: right and bottom.
    double get right => left + width;
    set right(double value) => left = value - width;

    double get bottom {
        return top + height;
    }
    set bottom(double value) {
        top = value - height;
    }

    // Define how to print this class
    @override
    String toString() {
        return 'Left: ${left}, '
            ' Top: ${top}, Width: ${width}, '
            'Height: ${height} - '
            'Right: ${right}, Bottom: ${bottom}';
    }
}

void main() {
    var rect0 = Rectangle(0, 2, 10, 11);
    rect0.right = 8; // Canviarà el valor de 'left'

    var rect1 = Rectangle(0, 2, 10, 11);
    rect1.bottom = 9; // Canviarà el valor de 'top'

    print('rect0: ${rect0}');
    print('rect1: ${rect1}');
}
```

Sortida:

```text
rect0: Left: -2.0, Top: 2.0, Width: 10.0, Height: 11.0 - Right: 8.0, Bottom: 13.0

rect1: Left: 0.0, Top: -2.0, Width: 10.0, Height: 11.0 - Right: 10.0, Bottom: 9.0
```

## Classes abstractes

```dart
abstract class Vehicle {
    int passengers = 0;
    double position = 0.0;

    // abstract method
    void moveForward(int meters); }

    class Car extends Vehicle {

    @override
    moveForward(int meters) {
        position += meters;
    }
}

class Moto extends Vehicle {
    int passengers = 2;

    @override
    moveForward(int meters) {
        position += meters / this.passengers;
    }
}

void main() {

    var car = Car();
    car.moveForward(2);

    var motoA = Moto();
    motoA.passengers = 1;
    motoA.moveForward(2);

    var motoB = Moto();
    motoB.moveForward(2);

    print('car: ${car.position}, '
        'motoA: ${motoA.position}, '
        'motoB: ${motoB.position}');
}
```

```text
car: 2.0, motoA: 2.0, motoB: 1.0
```
