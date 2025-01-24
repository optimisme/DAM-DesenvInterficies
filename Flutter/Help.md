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

Quan un projecte encara no té carpeta de desenvolupament 'desktop'

```bash
flutter config --enable-macos-desktop
flutter create .
flutter run -d macos
```

**Nota**: Canviar *"macos"* per "linux" o "windows" si cal

# Actualitzar flutter
```bash
flutter upgrade
```