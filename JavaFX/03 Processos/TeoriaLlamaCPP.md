# llama.cpp amb Docker Compose

Els alumnes ja coneixen Docker. En aquest apartat veurem com utilitzar **llama.cpp** dins d'un contenidor per executar un model d'IA local.

## Què és llama.cpp?

**llama.cpp** és un projecte de codi obert que permet executar models d'intel·ligència artificial localment.

Està escrit principalment en **C/C++** i pot aprofitar diferents tipus de maquinari:

- CPU
- GPU NVIDIA
- GPU AMD
- Apple Silicon

També pot funcionar com un **servidor HTTP compatible amb l'API d'OpenAI**.

L'estructura serà:

```text
Aplicació
    ↓
HTTP
    ↓
llama.cpp
    ↓
Model d'IA
```

## Què és Hugging Face?

**Hugging Face** és una plataforma on es publiquen i comparteixen models d'intel·ligència artificial.

Podem pensar-hi de manera similar a GitHub, però orientat especialment a:

- models d'IA
- datasets
- demos
- fitxers de configuració

Web oficial:

https://huggingface.co/

Molts models compatibles amb llama.cpp es poden trobar directament a Hugging Face.

Cada model té el seu propi repositori.

En aquesta pràctica utilitzarem principalment:

```text
Qwen/Qwen3-VL-2B-Instruct-GGUF
```

El podem consultar aquí:

https://huggingface.co/Qwen/Qwen3-VL-2B-Instruct-GGUF

Aquest repositori inclou diferents versions quantitzades del model, entre elles:

```text
Q4_K_M
Q8_0
FP16
```

També inclou el component de visió necessari perquè el model pugui treballar amb imatges.

També disposem d'una configuració alternativa amb:

```text
ggml-org/gemma-4-E2B-it-GGUF
```

Disponible a:

https://huggingface.co/ggml-org/gemma-4-E2B-it-GGUF

## Què és GGUF?

llama.cpp treballa principalment amb models en format:

```text
GGUF
```

GGUF és un format especialment preparat per executar models eficientment amb llama.cpp.

Un mateix model pot tenir diferents **quantitzacions**.

Les quantitzacions redueixen la mida del model i la memòria necessària.

En general:

```text
FP16 → més qualitat i més memòria

Q8

Q4 → menys memòria
```

En aquesta pràctica utilitzarem principalment:

```text
Q4_K_M
```

per a Qwen3-VL.

## Qwen3-VL 2B Instruct

Utilitzarem:

```text
Qwen3-VL 2B Instruct
```

`VL` significa:

```text
Vision Language
```

És a dir, el model pot treballar amb:

- text
- imatges

`Instruct` indica que és una versió preparada per seguir instruccions i funcionar com a assistent.

El model que utilitzarem és:

```text
Qwen/Qwen3-VL-2B-Instruct-GGUF
```

llama.cpp pot descarregar directament models de Hugging Face utilitzant l'opció:

```text
-hf
```

Per exemple:

```text
-hf Qwen/Qwen3-VL-2B-Instruct-GGUF:Q4_K_M
```

## Estructura dels arxius

Disposem d'una carpeta amb diferents fitxers Docker Compose:

```text
llamacpp-compose/
├── compose-gemma4-linuxAMD.yml
├── compose-gemma4-linuxNVIDIA.yml
├── compose-gemma4.yml
├── compose-qwen3-linuxAMD.yml
├── compose-qwen3-linuxNVIDIA.yml
└── compose-qwen3.yml
```

Hi ha dos models disponibles:

```text
Qwen3-VL 2B
Gemma 4 E2B
```

I per cada model tenim tres configuracions.

### Configuració genèrica

```text
compose-qwen3.yml
compose-gemma4.yml
```

Utilitza la imatge genèrica de llama.cpp:

```text
ghcr.io/ggml-org/llama.cpp:server
```

És la configuració més portable.

Es pot utilitzar, per exemple, en:

- macOS
- Linux sense acceleració GPU
- altres sistemes on Docker pugui executar el contenidor

### Linux amb NVIDIA

```text
compose-qwen3-linuxNVIDIA.yml
compose-gemma4-linuxNVIDIA.yml
```

Utilitza:

```text
ghcr.io/ggml-org/llama.cpp:server-cuda
```

Aquesta versió permet aprofitar una GPU NVIDIA mitjançant CUDA.

### Linux amb AMD

```text
compose-qwen3-linuxAMD.yml
compose-gemma4-linuxAMD.yml
```

Utilitza:

```text
ghcr.io/ggml-org/llama.cpp:server-rocm
```

Aquesta versió permet aprofitar GPUs AMD compatibles amb ROCm.

## Fitxer compose-qwen3.yml

La configuració genèrica de Qwen és:

```yaml
services:
  llama:
    image: ghcr.io/ggml-org/llama.cpp:server
    container_name: qwen-server

    ports:
      - "8080:8080"

    volumes:
      - llama-models:/root/.cache

    command:
      - -hf
      - Qwen/Qwen3-VL-2B-Instruct-GGUF:Q4_K_M
      - --jinja
      - --host
      - 0.0.0.0
      - --port
      - "8080"

volumes:
  llama-models:
```

Aquest fitxer descriu el servidor que volem executar.

L'opció:

```text
--jinja
```

permet utilitzar correctament les plantilles de conversa del model i és especialment útil si després volem treballar amb **tool calling**.

## Escollir la configuració

Si volem utilitzar Qwen amb la configuració genèrica:

```bash
docker compose -f compose-qwen3.yml up -d
```

En un Linux amb NVIDIA:

```bash
docker compose -f compose-qwen3-linuxNVIDIA.yml up -d
```

En un Linux amb AMD:

```bash
docker compose -f compose-qwen3-linuxAMD.yml up -d
```

Per Gemma 4:

```bash
docker compose -f compose-gemma4.yml up -d
```

Linux amb NVIDIA:

```bash
docker compose -f compose-gemma4-linuxNVIDIA.yml up -d
```

Linux amb AMD:

```bash
docker compose -f compose-gemma4-linuxAMD.yml up -d
```

Per tant, només hem d'escollir:

```text
MODEL + MAQUINARI
```

Per exemple:

```text
Qwen3 + genèric
Qwen3 + NVIDIA
Qwen3 + AMD

Gemma4 + genèric
Gemma4 + NVIDIA
Gemma4 + AMD
```

## Iniciar el servidor

Per exemple, amb Qwen i la configuració genèrica:

```bash
docker compose -f compose-qwen3.yml up -d
```

Docker:

1. descarregarà la imatge de llama.cpp si no la tenim;
2. crearà el contenidor;
3. descarregarà Qwen3-VL 2B des de Hugging Face;
4. carregarà el model;
5. iniciarà `llama-server`.

Podrem accedir a la interfície web des de:

```text
http://localhost:8080
```

I l'API compatible amb OpenAI estarà disponible a:

```text
http://localhost:8080/v1
```

Per exemple:

```text
POST /v1/chat/completions
```

## Comprovar el contenidor

Podem comprovar que està funcionant amb:

```bash
docker ps
```

Amb Qwen hauríem de veure:

```text
qwen-server
```

Amb Gemma:

```text
gemma-server
```

## Veure els logs

Per veure què està fent llama.cpp:

```bash
docker compose -f compose-qwen3.yml logs
```

O seguir els logs en temps real:

```bash
docker compose -f compose-qwen3.yml logs -f
```

Si utilitzem una altra configuració, només hem de canviar el nom del fitxer:

```bash
docker compose -f compose-qwen3-linuxNVIDIA.yml logs -f
```

Durant la primera execució veurem, entre altres coses, la descàrrega i càrrega del model.

## Aturar el servidor

Hem d'utilitzar el mateix fitxer Compose que hem fet servir per iniciar-lo.

Per exemple:

```bash
docker compose -f compose-qwen3.yml down
```

O amb NVIDIA:

```bash
docker compose -f compose-qwen3-linuxNVIDIA.yml down
```

Això elimina el contenidor però conserva el volum:

```text
llama-models
```

Per tant, el model descarregat es pot reutilitzar.

Per tornar-lo a iniciar:

```bash
docker compose -f compose-qwen3.yml up -d
```

## Resum

La carpeta conté diferents configuracions però totes funcionen de la mateixa manera:

```text
Docker Compose
      ↓
llama.cpp
      ↓
Qwen3-VL o Gemma 4
      ↓
llama-server
      ↓
Web + API OpenAI compatible
```

La principal diferència entre els fitxers és el sistema d'acceleració utilitzat:

```text
*.yml                 → configuració genèrica
*-linuxNVIDIA.yml     → CUDA / NVIDIA
*-linuxAMD.yml        → ROCm / AMD
```

Això ens permet mantenir la mateixa pràctica i la mateixa API independentment del model o del maquinari utilitzat.