# 01 - Preparar el servidor remot

Anterior: [00 - Claus SSH](./00-claus-ssh.md) | [Tornar a l'índex](../TeoriaProxmox.md) | Següent: [02 - Túnel MySQL](./02-tunel-mysql.md)

Aquest pas **només es fa un cop per servidor**. Deixa el servidor remot amb tot el que necessita per fer funcionar un servidor Java.

Abans cal haver completat [00 - Claus SSH](./00-claus-ssh.md).

## Què instal·larem

```mermaid
flowchart LR
    client["Client<br/>wss://usuari.ieti.site"]
    subgraph remot["Servidor remot (Proxmox)"]
        port80(["Port 80"])
        java["Servidor Java<br/>server-package.jar<br/>port 3000"]
        mysql[("MySQL (opcional)<br/>127.0.0.1:3306")]
    end
    client -- "port 443" --> port80
    port80 -- "redirecció 80 > 3000" --> java
    java -.-> mysql
```

| Pas | Què s'instal·la | Per a què serveix |
|---|---|---|
| 1 | **Java** (JRE) | Executar l'arxiu *.jar* del servidor |
| 2 | **Redirecció** del port 80 al 3000 | Que el servidor respongui sense haver d'escriure el port |
| 3 | **MySQL** i l'usuari *super* (opcional) | Guardar les dades, només si el vostre servidor fa servir una base de dades |

El client es connecta pel port segur **443** a l'entrada del Proxmox, el Proxmox ho passa al port **80** de la vostra màquina remota, i la redirecció ho entrega al port **3000** del servidor Java.

Les comandes d'instal·lació poden anar lentes. **No talleu la connexió** i llegiu bé els missatges d'error en cas que n'hi hagin.

## Pas 1 - Java

Des de la consola local, a la carpeta **"proxmox"**, connectar amb el servidor:

```bash
./proxmoxConnect.sh
```

Un cop connectats, des de la consola remota:

```bash
sudo apt update
sudo apt install openjdk-21-jre-headless iproute2 iptables-persistent
```

Comprovar que ha funcionat:

```bash
java -version
```

Ja podeu sortir del servidor remot:

```bash
exit
```

**Nota:** al servidor remot només cal el *JRE* (per executar). La compilació amb Maven es fa al vostre ordinador.

## Pas 2 - Redirecció del port 80

Cal que el servidor remot redireccioni les peticions del port 80 al port 3000 (el del servidor Java).

Aquest pas es fa **des de la consola local**, a la carpeta **"proxmox"**:

```bash
./proxmoxSetupRedirect80.sh
```

Si mai cal desfer la redirecció:

```bash
./proxmoxSetupRedirectUndo.sh
```

## Pas 3 - MySQL (opcional)

Només cal si el vostre servidor Java fa servir una base de dades MySQL.

Des de la consola remota (`./proxmoxConnect.sh`), instal·lar MySQL:

```bash
sudo apt update
sudo apt install mysql-server
sudo systemctl status mysql --no-pager
```

L'última comanda ha de mostrar **"active (running)"**.

Connectar a la base de dades des del propi servidor remot:

```bash
sudo mysql
```

Des de la consola 'MySQL' remota, crear l'usuari 'super':

```sql
CREATE USER 'super'@'localhost' IDENTIFIED WITH caching_sha2_password BY '1234';
GRANT ALL PRIVILEGES ON *.* TO 'super'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
quit
```

**Nota:** un codi tan senzill com *1234* només és acceptable perquè aquest MySQL **no és accessible des de fora** del servidor. Per connectar-s'hi des del vostre ordinador cal un túnel SSH, explicat a [02 - Túnel MySQL](./02-tunel-mysql.md).

## Resultat

El servidor remot ja està preparat. A partir d'ara, el dia a dia és:

- [03 - Publicar](./03-publicar.md), per enviar el servidor Java al servidor remot
- [02 - Túnel MySQL](./02-tunel-mysql.md), per treballar amb la base de dades remota (si en feu servir)
