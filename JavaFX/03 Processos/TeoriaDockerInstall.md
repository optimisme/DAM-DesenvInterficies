A **Windows** i **macOS** descarregar:

[https://docs.docker.com/desktop/]([https://docs.docker.com/desktop/)


---

Per tenir **Docker Desktop** instal·lat a Ubuntu i configurat correctament per utilitzar-lo des de la línia de comandes (amb el context adequat), pots seguir aquest recull de passos complets:

### 1. Desinstal·lar versions anteriors (si n'hi havia)

Si abans havies provat d'instal·lar el Docker natiu de terminal, assegura't de netejar-ho per evitar conflictes:

```bash
sudo apt remove docker docker-engine docker.io containerd runc

```

### 2. Descarregar i instal·lar Docker Desktop

Baixa l'últim paquet `.deb` oficial des de la terminal amb `wget` i instal·la'l:

```bash
wget https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb
sudo apt update
sudo apt install ./docker-desktop-amd64.deb

```

*(Si durant la instal·lació veus algun avís de dependències insatisfetes, executa `sudo apt --fix-broken install` i torna-ho a provar).*

### 3. Iniciar el servei i l'aplicació

Obre Docker Desktop cercant-lo al menú d'aplicacions del teu Ubuntu, o bé arrenca el servei d'usuari directament des del terminal:

```bash
systemctl --user start docker-desktop

```

### 4. Configurar el context de Docker

Per assegurar-te que la línia de comandes apunta correctament a Docker Desktop (i no al motor natiu de Linux), defineix el context permanent:

```bash
sudo usermod -aG kvm $USER
docker context use desktop-linux
```

Tancar la sessió i tornar a entrar

---

> **Comprovació:**
> Pots verificar que tot funciona correctament i que estàs utilitzant el context adequat executant:
> ```bash
> docker ps
> 
> ```
> 
> 
> Si respon correctament (mostrant una llista buida de contenidors en lloc d'un error de permisos), ja ho tens a punt per utilitzar Docker Desktop completament des de la terminal i sense `sudo`.