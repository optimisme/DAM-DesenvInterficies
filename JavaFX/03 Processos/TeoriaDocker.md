# Docker

**Docker** permet executar aplicacions dins de **contenidors**.

Un contenidor inclou l'aplicació i les dependències que necessita, de manera que es pugui executar de forma similar en diferents ordinadors.

## Conceptes bàsics

- **Image**: plantilla que conté l'aplicació i les seves dependències.
- **Container**: instància en execució d'una imatge.
- **Dockerfile**: fitxer amb les instruccions per construir una imatge.
- **Docker Compose**: permet definir i executar diversos contenidors conjuntament.
- **Registry**: servidor on es guarden imatges, com **Docker Hub**.

```text
Dockerfile → Image → Container
```

Per exemple, podem descarregar una imatge d'Ubuntu i crear-ne un contenidor:

```bash
docker run -it ubuntu bash
```

La primera vegada Docker descarregarà la imatge si encara no la tenim.

## Contenidors i màquines virtuals

Tradicionalment, per executar un servidor MySQL separat del nostre sistema podríem crear una **màquina virtual**:

```text
Ordinador
└── Màquina virtual
    ├── Sistema operatiu complet
    └── MySQL
```

La màquina virtual necessita executar un sistema operatiu complet, reservant RAM, CPU i espai de disc.

Amb Docker podem executar directament un **contenidor MySQL**:

```text
Ordinador
└── Docker
    └── Contenidor MySQL
```

El contenidor només inclou MySQL i les dependències necessàries.

Això normalment consumeix menys recursos i arrenca molt més ràpid que mantenir una màquina virtual completa.

> Docker Desktop a Windows, macOS i Linux pot utilitzar internament una màquina virtual. La diferència és que no hem de crear i mantenir una màquina virtual completa per a cada servei.

## Exemple: servidor MySQL amb Docker

Podem crear un servidor MySQL amb:

```bash
docker run \
    --name mysql-server \
    -e MYSQL_ROOT_PASSWORD=password \
    -p 3306:3306 \
    -d mysql:8.4
```

Les opcions indiquen:

```text
--name mysql-server
```

Assigna el nom `mysql-server` al contenidor.

```text
-e MYSQL_ROOT_PASSWORD=password
```

Crea una variable d'entorn amb la contrasenya de l'usuari `root` de MySQL.

```text
-d
```

Executa el contenidor en segon pla.

```text
mysql:8.4
```

Indica la imatge que volem utilitzar.

## Redirecció de ports

Els contenidors tenen la seva pròpia xarxa.

MySQL escolta normalment al port:

```text
3306
```

Per poder accedir-hi des del nostre ordinador fem:

```bash
-p 3306:3306
```

La sintaxi és:

```text
-p PORT_ORDINADOR:PORT_CONTENIDOR
```

Per tant:

```text
localhost:3306 → contenidor:3306
```

Una aplicació del nostre ordinador es podria connectar amb:

```text
Host: localhost
Port: 3306
User: root
Password: password
```

També podríem utilitzar un port diferent al nostre ordinador:

```bash
-p 3307:3306
```

En aquest cas:

```text
localhost:3307 → contenidor:3306
```

MySQL continua utilitzant el port `3306` dins del contenidor, però nosaltres hi accedim mitjançant el port `3307`.

Això permet, per exemple, tenir dos servidors MySQL simultàniament:

```text
localhost:3306 → MySQL contenidor 1
localhost:3307 → MySQL contenidor 2
```

## Conservar les dades de MySQL

Si eliminem un contenidor, les dades guardades dins seu també es poden perdre.

Podem utilitzar un **volum** perquè les dades siguin persistents:

```bash
docker run \
    --name mysql-server \
    -e MYSQL_ROOT_PASSWORD=password \
    -p 3306:3306 \
    -v mysql-data:/var/lib/mysql \
    -d mysql:8.4
```

El volum:

```text
mysql-data
```

guarda les dades independentment del contenidor.

Així podem eliminar i tornar a crear el contenidor sense perdre la base de dades.

## Comandes bàsiques

Veure els contenidors en execució:

```bash
docker ps
```

Veure tots els contenidors:

```bash
docker ps -a
```

Veure les imatges disponibles:

```bash
docker images
```

Aturar MySQL:

```bash
docker stop mysql-server
```

Tornar-lo a iniciar:

```bash
docker start mysql-server
```

Eliminar el contenidor:

```bash
docker rm mysql-server
```

## Iniciar Docker Desktop a Linux

Docker Desktop es pot iniciar gràficament des del menú d'aplicacions o des del terminal:

```bash
systemctl --user start docker-desktop
```

Podem comprovar que està funcionant amb:

```bash
docker ps
```

Consultar els contexts disponibles:

```bash
docker context ls
```

Docker Desktop utilitza normalment el context:

```text
desktop-linux
```

Per aturar Docker Desktop:

```bash
systemctl --user stop docker-desktop
```

També es pot iniciar amb el CLI de Docker Desktop:

```bash
docker desktop start
```