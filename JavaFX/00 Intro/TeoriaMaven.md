<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2023</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="./assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

<img src="./assets/maven.png" height="64" alt="Maven" style="max-height: 64px;">
<br/>
<br/>

# Gestió de projectes i llibreries

Maven és una eina que automatitza la compilació de projectes JAVA, i també facilita la gestió de llibreries dels projectes.

Per instal·lar Maven:

```bash
sudo apt install maven # Linux
brew install maven # macOS
```

A windows cal (adaptant el número de versió):
- [Descarregar el 'Binary zip archive' de Maven](https://maven.apache.org/download.cgi)
- Descomprimir l'arxiu tipus 'apache-maven-3.9.6-bin.zip' posar-lo a la carpeta "C:\Program Files\Maven\"
- Ha de quedar semblant a: "C:\Program Files\Maven\apache-maven-3.9.6\"
- Obrir el programa "Edit the system environment variables"
- Apretar el botó "Environment Variables"
- A les "System variables" afegir la variable: MAVEN_HOME amb el valor "C:\Program Files\Maven\apache-maven-3.9.6"
- A les "System variables" editar la variable "Path" per afegir-hi "C:\Program Files\Maven\apache-maven-3.9.6\bin"
- Reiniciar Windows
- Reafirmar els teus pensaments que Windows és més fàcil i millor

Caldrà que tingueu Maven al vostre sistema per fer anar els exemples i projectes de l'assignatura.

### Fer anar Maven

Maven instal·la la comanda 'mvn' amb la que podeu compilar els projectes.

Els projectes de l'assignatura tenen dos scripts:

```bash
run.ps1 # Per Windows
run.sh # Per Linux i macOS
```

Per 'netejar' i 'compilar' el projecte abans de compilar-lo:

```bash
mvn clean
mvn compile
```

Aleshores, per compilar el projecte, segons el sistema:

```bash
.\run.ps1 com.project.Main
```

O bé

```bash
./run.sh com.project.Main
```

Quan fem orientació a objectes, veureu que es poden cridar les classes amb funció 'main' directament:

```bash
.\run.ps1 com.project.MainDao
```

O bé

```bash
./run.sh com.project.MainDao
```

Nota: A Windows cal tenir la PowerShell en mode UTF-8, per configurar-la:

```bash
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

## Projectes JAVA/Maven

En JAVA tots els programes tenen un punt d'entrada que està a:

- Dins d'una classe principal, en aquest cas 'Main' (això ho veurem quan fem orientació a objectes)

- Dins de la funció 'main'

'main' és la funció que s'executa per defecte en una classe. 

En aquest cas, el nom de la classe podría ser diferent a 'Main' però el nom del a funció no podría ser diferent.

Per fer anar aquest exemple, cal anar amb el terminal i esciure:

```bash
cd "./JavaFX/00 Intro/Exemple 0000/"
mvn clean
mvn compile
./run.sh com.project.Main
```

**Nota:** Els usuaris de Windows crideu a '.\run.ps1' enlloc de './run.sh'

# Versió de les llibreries Maven

Les llibreries **Maven** s'actualitzen constantment, sobretot per motius de seguretat.

Si a l'arxiu **.pom** surt un avís de versió insegura, **només cap actualitzar-la a la última versió segura**.

Visual Studio Code permet fer aquesta actualització fàcilment amb la opció "Fix Issue"