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

# Publicació Web

NodeJS permet exportar a format 'Web', això combinat amb el servidor NodeJS permet crear aplicacions web interactives de manera senzilla.

## Exportar a Web

Per exportar un projecte flutter a web hi ha les comandes:

```bash
cd "Flutter/08 Publicació Web/Exemple Web/client_flutter/"

# Opció A: Executar l'aplicació en mode desenvolupament (amb el servidor funcionant)
flutter run -d chrome --wasm

# Opció B: Exportar l'aplicació per publicar-la a producció 
# (després cal copiar la web a la carpeta 'public' del servidor)
flutter build web --release --wasm

# Copiar la web de producció a la carpeta 'public' del servidor NodeJS
rm -rf ../server_nodejs/public/*
cp -r ./build/web/* ../server_nodejs/public/
```

Posar en funcionament el servidor NodeJS:

```bash
cd "Flutter/08 Publicació Web/Exemple Web/server_nodejs"

# Opció A: Fer anar el servidor en mode de desenvoluapment
npm run dev

# Opció B: Fer anar el servidor a producció
npm run pm2start

# Aturar el servidor a producció
npm run pm2stop
```

Per accedir a la web amb l'aplicació flutter només cal anar a l'arrel del servidor:

```text
http://localhost:8888
```

