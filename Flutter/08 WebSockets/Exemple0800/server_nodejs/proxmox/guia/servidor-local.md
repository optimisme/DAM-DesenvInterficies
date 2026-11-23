# Servidor local amb NodeJS

[Tornar a l'índex](../TeoriaProxmox.md)

<center><img src="../assets/logo-nodejs.png" style="max-width: 90%; max-height: 200px;" alt="Logo de NodeJS"></center>

Abans de publicar la pàgina al servidor remot, cal fer-la funcionar **al vostre ordinador**. Aquest document és independent de la resta: no necessita claus SSH ni connexió amb el Proxmox.

**[NodeJS](https://nodejs.org/en)** és un executor de codi *JavaScript*.

## Instal·lar NodeJS

A Linux:

```bash
sudo apt update
sudo apt install npm rsync iptables-persistent iproute2
sudo npm cache clean -f
sudo npm install -g n
sudo n latest
sudo npm install -g pm2
```

A MacOS:

```bash
brew install node
sudo npm cache clean -f
sudo npm install -g n
sudo n latest
sudo npm install -g pm2
```

## Estructura del projecte

Les comandes d'aquest document s'executen des de la carpeta del projecte, la que conté l'arxiu `package.json`:

| Carpeta o arxiu | Contingut |
|---|---|
| `server/app.js` | El codi del servidor web |
| `public/` | La pàgina web (HTML, CSS...) que el servidor publica |
| `package.json` | Les dependències i les comandes del projecte |
| `proxmox/` | Els scripts per treballar amb el servidor remot |

El primer cop, cal instal·lar les dependències del projecte:

```bash
npm install
```

## Servidor web (local)

Per fer anar el servidor en mode **"desenvolupament"**:

```bash
node --run dev
```

Això permet que el servidor es reiniciï quan fem canvis al codi. Per aturar-lo, premeu *Ctrl+C*.

Per fer anar el servidor en mode **"producció"**:

```bash
pm2 start ./server/app.js --name "app"
```

Això permet que si el servidor es "penja" es reiniciï per seguir funcionant.

En mode producció, **pm2** té comandes per llistar o aturar el servidor:

```bash
pm2 list
pm2 delete app
```

Un cop el servidor funciona es pot accedir a la pàgina local:

[http://localhost:3000](http://localhost:3000)

## Següent pas

Quan la pàgina ja funciona en local, la podeu publicar al servidor remot seguint la [guia pas a pas](../TeoriaProxmox.md), començant per [00 - Claus SSH](./00-claus-ssh.md).
