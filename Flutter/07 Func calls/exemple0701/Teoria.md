# Arquitectura de l’exemple (Flutter + Node.js + Ollama + SQLite)

Aquest exemple permet fer preguntes en llenguatge natural sobre una base de dades privada (planetes) utilitzant un servidor Node.js i models LLM via Ollama.

L’arquitectura està pensada per:
- Reduir errors de resposta
- Millorar la qualitat amb **dos models en paral·lel**
- Validar les respostes amb un **model jutge**
- Fer servir **tools (dbQuery)** per accedir a SQLite

## Models petits i càrrega de feina

Amb poca VRAM, un model gran és lent, difícil de carregar i poc flexible.

Diversos models petits permeten comparar respostes i reduir errors.

- Si un falla, l’altre pot encertar.
- El jutge selecciona la millor resposta.
- Consumeixen menys memòria i responen més ràpid.
- És més fàcil canviar o millorar models individuals.

Distribució de models escollida:

> Maria14 (16 GB VRAM)
- primaryModelA = granite4:3b → solver ràpid
- judgeModel = granite3.3:8b → jutge fort 

> Maria24 (24 GB VRAM)
- primaryModelB = qwen3:8b → solver principal de qualitat
- tiebreaker = granite4:3b → lleuger, diferent família
- jsonRepair = granite4:3b → ideal per JSON repair

**Nota**: Pel projecte us donarem una configuració diferent amb un model de visió a *Maria24*

---

## Visió general del flux

1. **Flutter (client)** envia una pregunta al servidor (`POST`).
2. **Node.js** construeix el prompt, les tools i el context.
3. **Dos models LLM (A i B)** processen la pregunta en paral·lel.
4. **Un model jutge** compara les dues respostes:
   - Si són equivalents → tria la millor.
   - Si discrepen → es crida un **tercer model (tiebreaker)**.
5. El servidor retorna **una única resposta final** al client.

## Limitacions IAs locals

Amb poca VRAM, un model gran és lent, difícil de carregar i poc flexible.

Diversos models petits permeten comparar respostes i reduir errors.

- Si un falla, l’altre pot encertar.
- El jutge selecciona la millor resposta.
- Consumeixen menys memòria i responen més ràpid.
- És més fàcil canviar o millorar models individuals.

---

## Components principals

### 1) Client Flutter
- Envia el text de l’usuari al servidor.
- Rep una resposta ja redactada i la mostra.

### 2) Servidor Node.js (Express)
Fa d’orquestrador de tot el sistema:

- Gestiona sessions (memòria curta).
- Defineix la tool `dbQuery`.
- Controla la seguretat SQL:
  - Només permet `SELECT`.
  - Evita múltiples sentències.
- Executa consultes SQLite.
- Coordina:
  - Dos models candidats
  - Un model jutge
  - Un model de desempat (si cal)

Variables típiques de configuració:
- `OLLAMA_MODEL_A` → model principal A
- `OLLAMA_MODEL_B` → model principal B
- `OLLAMA_JUDGE_MODEL` → model que avalua respostes
- `OLLAMA_TIEBREAKER_MODEL` → model extra si hi ha desacord

### 3) Ollama (LLM)
Els models poden fer dues coses:
- Respondre directament (si no calen dades)
- O bé cridar la tool `dbQuery` per obtenir dades reals
- Si la pregunta ho requereix, el model pot fer més d’una crida a dbQuery en rondes successives per resoldre passos intermedis.

Després de rebre el resultat de la tool, generen una resposta final en llenguatge natural.

### 4) SQLite (base de dades)
- Conté la taula `planets` amb les dades.
- Només s’utilitza en mode lectura.

---

## Com funciona el sistema amb diversos models

Per cada pregunta de l’usuari:

1. Node.js envia la mateixa petició a:
   - Model A
   - Model B

2. Cada model pot:
   - Cridar `dbQuery`
   - Fer diverses passes (tools loop)
   - O donar resposta directa

3. El servidor recull les dues respostes com a **candidates**.

4. El **model jutge** rep:
   - La pregunta original
   - Les dues respostes
   I decideix:
   - Si són equivalents
   - Quina és millor

5. Si el jutge diu que **no són equivalents**:
   - Es crida un **tercer model (tiebreaker)**
   - El jutge torna a triar entre les tres

Això permet:
- Menys al·lucinacions
- Millor qualitat mitjana
- Respostes més completes

---

## Tool calling: dbQuery

La tool disponible és:

- Nom: `dbQuery`
- Argument únic:
```json
{ "query": "SELECT ..." }
```

El model **ha d’usar obligatòriament la tool** si necessita dades de la base de dades.

Exemple de tool_call generat pel model:
```json
{
  "tool_calls": [
    {
      "function": {
        "name": "dbQuery",
        "arguments": {
          "query": "SELECT name, diameter_km FROM planets ORDER BY diameter_km DESC"
        }
      }
    }
  ]
}
```

El servidor:
- Executa la consulta
- Retorna les files al model
- El model genera la resposta final

---

## Memòria de conversa (sessions)

El servidor manté una petita memòria per sessió:
- Últimes preguntes
- Últimes respostes validades

Això permet preguntes com:
> Quin és el planeta següent a Pressureworld respecte la distància al sol?

Sense haver de repetir tota la informació.

---

# Connexió a MarIA a través del proxmox:

Els servidors IA de l'institut (MarIA) són accessibles només des del proxmox. N'hi ha dos:

- **192.168.1.14** amb **16GB** de VRAM el farem servir per fer consultes normals o amb 'tools'

- **192.168.1.24** amb **24GB** de VRAM el farem servir per fer consultes de visió 

## Cridar els models

### Executant el codi al Proxmox

Si el codi funciona al proxmos es poden cridar directament els servidors amb crides POST.

```text
http://192.168.1.14:11434/api/chat
http://192.168.1.24:11434/api/chat
```

### Des de l'ordinador personal

Per fer crides a la MarIA des de l'ordinador personal cal crear un **"Túnel"** fins al *Proxmox*, habilitant l'accés a la MariIA.

- 1: Fer el túnel a la consola del vostre ordinador:

```bash
ssh -i $HOME/.ssh/id_rsa -p 20127 -L 11414:192.168.1.14:11434 apalaci8@ieticloudpro.ieti.cat
ssh -i $HOME/.ssh/id_rsa -p 20127 -L 11424:192.168.1.24:11434 apalaci8@ieticloudpro.ieti.cat
```

**Nota**: Aquests dos túnels habiliten la MarIA als ports (11414 i 11424)

- 2: Fer crides als ports de cada servidor IA:

```text
http://localhost:11414/api/chat
http://localhost:11424/api/chat
```

---

## Exemples de crides

Aquestes preguntes funcionen directament amb el sistema:

- Quants planetes coneixes?
- Quins són els tres planetes més llunyans?
- Quin planeta té 14 llunes?
- Dona'm la llista de planetes ordenats de més llunes a menys llunes en una taula amb el nom i el numero de llunes
- Quins planetes tenen més de 3 llunes? digues el nom i la quantitat de llunes
- Quins planetes tenen més llunes que Bluehome?
- Fes una taula amb les dades dels planetes que queden més lluny de 'Redfriend' respecte el sol, inclou el nom i la distància
- Fes una taula amb totes les dades dels planetes que tenen una gravetat inferior a la de Bluehome
- Fes una llista ordenant els planetes segons l'eix d'inclinació de més petit a més gran i mostrant el nom del planeta, l'eix i el diametre
- Quins planetes tenen orbital_period_days per sota de la mitjana i alhora average_distance_to_sun_AU per sota de la mitjana? Mostra name, orbital_period_days i average_distance_to_sun_AU

### Crides amb memòria

- Quin és el planeta següent a Pressureworld respecte la distància al sol? digues el nom i la distància
- Fes una taula amb tots els planetes que tenen gravity_ms2 més gran que el 50% de la gravetat del planeta que has trobat abans. Mostra name i gravity_ms2, ordenat descendent.
