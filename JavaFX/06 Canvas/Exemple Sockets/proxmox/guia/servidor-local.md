# Servidor local amb Java

[Tornar a l'índex](../TeoriaProxmox.md)

Abans de publicar el servidor al Proxmox, cal fer-lo funcionar **al vostre ordinador**. Aquest document és independent de la resta: no necessita claus SSH ni connexió amb el Proxmox.

## Què cal tenir instal·lat

| Eina | Per a què serveix |
|---|---|
| **Java JDK** (versió 21 o superior) | Compilar i executar el codi |
| **Maven** | Descarregar les llibreries i generar l'arxiu *.jar* |

A Linux (o WSL):

```bash
sudo apt update
sudo apt install openjdk-21-jdk maven
```

A MacOS:

```bash
brew install openjdk maven
```

Comprovar que funcionen:

```bash
java -version
mvn -version
```

## Estructura del projecte

Les comandes d'aquest document s'executen des de la carpeta del projecte, la que conté l'arxiu `pom.xml`:

| Carpeta o arxiu | Contingut |
|---|---|
| `src/main/java/` | El codi Java, amb el servidor a `com/server/Main.java` |
| `pom.xml` | Les dependències i la configuració de Maven |
| `run.sh` / `run.ps1` | Scripts per executar el projecte en local |
| `target/` | Arxius generats per Maven, inclòs el *.jar* |
| `proxmox/` | Els scripts per treballar amb el servidor remot |

## Fer anar el servidor en local

```bash
./run.sh com.server.Main
```

El servidor queda escoltant al port **3000** del vostre ordinador. Per aturar-lo, premeu *Ctrl+C*.

Els clients s'executen igual, indicant la seva classe principal, i s'han de connectar a:

```text
ws://localhost:3000
```

## Generar l'arxiu .jar

L'script de publicació ja ho fa automàticament, però també es pot fer a mà:

```bash
./run.sh com.server.Main build
```

Ha de crear l'arxiu `target/server-package.jar`, que es pot provar amb:

```bash
java -jar target/server-package.jar
```

## Següent pas

Quan el servidor ja funciona en local, el podeu publicar al servidor remot seguint la [guia pas a pas](../TeoriaProxmox.md), començant per [00 - Claus SSH](./00-claus-ssh.md).
