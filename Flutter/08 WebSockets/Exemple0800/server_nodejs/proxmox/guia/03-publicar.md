# 03 - Publicar la pàgina web i enviar arxius

Anterior: [02 - Túnel MySQL](./02-tunel-mysql.md) | [Tornar a l'índex](../TeoriaProxmox.md)

Aquests passos es fan **cada cop que voleu actualitzar** el que hi ha al servidor remot. Abans cal haver completat [01 - Preparar el servidor remot](./01-servidor-remot.md).

Totes les comandes s'executen **des de la consola local**, a la carpeta **"proxmox"**.

## Enviar la pàgina web al Proxmox

Aquest script envia la pàgina web al Proxmox amb **rsync** (només els arxius que han canviat) i hi reinicia el servidor NodeJS:

```bash
./proxmoxDeploy.sh
```

La pàgina queda publicada a (canvieu *usuari* pel vostre usuari):

[https://usuari.ieti.site](https://usuari.ieti.site)

## Què es conserva al servidor remot en cada publicació

L'script deixa la carpeta `~/nodejs_server` del servidor remot **igual que el vostre projecte local**: copia el que ha canviat i **esborra del servidor el que ja no teniu en local**. Hi ha unes excepcions, que no s'envien ni s'esborren mai:

| Al servidor remot | Què passa en publicar |
|---|---|
| Carpeta `data/` (a l'arrel del projecte) | **Es conserva** |
| Arxiu `settings.env` (a l'arrel del projecte) | **Es conserva** |
| Carpeta `node_modules/` | **Es conserva**, i s'actualitza amb `npm install` |
| Bases de dades MySQL | **No es toquen**, no formen part de la carpeta del projecte |
| La resta (`server/`, `public/`...) | Es **substitueix** per la vostra versió local |

**Important:** si el vostre servidor guarda arxius mentre funciona (pujades d'usuaris, una base de dades SQLite, arxius JSON...), els ha de guardar dins la carpeta **`data/`** de l'arrel del projecte. Qualsevol arxiu creat al servidor remot en un altre lloc, per exemple dins de `server/` o `public/`, **es perd** a la següent publicació.

## Comprovar el servidor NodeJS remot

Si la pàgina no respon, connecteu-vos al servidor remot:

```bash
./proxmoxConnect.sh
```

Des de la consola remota, **pm2** permet veure si el servidor funciona i llegir-ne els errors:

```bash
pm2 list
pm2 logs app
```

Per aturar el servidor:

```bash
pm2 delete app
```

## Enviar arxius al Proxmox

L'script **'proxmoxSendFile.sh'** permet enviar arxius al Proxmox:

Exemple:

```bash
./proxmoxSendFile.sh $HOME/Baixades/nomArxiu.txt
```

L'arxiu queda a l'arrel del servidor.

## Problemes habituals

| Què passa | Causa més probable | Solució |
|---|---|---|
| La pàgina no carrega | El servidor NodeJS no està funcionant | Revisar `pm2 list` i `pm2 logs app` al servidor remot |
| La pàgina només carrega afegint *:3000* | Falta la redirecció del port 80 | Executar `./proxmoxSetupRedirect80.sh` |
| Error de connexió amb la base de dades | Falta crear la base de dades o l'usuari al servidor remot | Revisar [01](./01-servidor-remot.md) i clonar la base de dades amb [02](./02-tunel-mysql.md) |
