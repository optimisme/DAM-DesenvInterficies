# Settejar el path

**A macos**
```bash
export PATH="/Users/$USER/Documents/GitHub/flutter/bin:$PATH"
```

**A linux**
```bash
export PATH="/home/$USER/Documents/GitHub/flutter/bin:$PATH"
```

**A windows**
```bash
????
```

# Afegir el projecte "desktop"

## macOS

Des de l'arrel del repositori, preparar tots els exemples amb:

```bash
python3 Flutter/scripts/setup_macos.py
```

Cal tenir Flutter, Xcode, CocoaPods (`pod`) i Python 3 al `PATH`.
El repositori ignora les carpetes `macos/`: l'script crea els runners que
falten, obté les dependències i configura l'aplicació i els pods per a macOS
12.0 o superior, el mínim que admet
[Xcode 27](https://developer.apple.com/xcode/system-requirements/). També configura els permisos
de xarxa i de selecció de fitxers dels exemples que els necessiten.
Es pot tornar a executar després de regenerar aquestes carpetes.

Després, entrar a la carpeta de qualsevol projecte (la que conté
`pubspec.yaml`) i executar:

```bash
flutter run -d macos
```

Per comprovar la compilació de tots els exemples:

```bash
python3 Flutter/scripts/setup_macos.py --build
```

També es pot preparar i comprovar un únic projecte:

```bash
python3 Flutter/scripts/setup_macos.py --build "Flutter/07 Func calls/exemple0700"
```

Els exemples que utilitzen Ollama o un servidor Node.js continuen requerint
que el servei corresponent estigui en marxa segons les instruccions de cada
exemple.

## Altres plataformes

Quan un projecte encara no té carpeta de desenvolupament 'desktop':

```bash
flutter config --enable-linux-desktop
flutter create --platforms=linux .
flutter run -d linux
```

**Nota**: Canviar *"linux"* per "windows" si cal.

# Actualitzar flutter
```bash
flutter upgrade
```

# Permisos d'accés a la xarxa

Si l'exemple o programa necessita permissos d'accés a la xarxa, afegir-los:

- A *macOS* i *iOS* obrir el projecte XCode i donar-los tant pel mode debug com pel mode release
- A *Android* afegir-los al fitxer *AndroidManifest.xml*
