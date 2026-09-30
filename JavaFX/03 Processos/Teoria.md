<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2023</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="./assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

# Processos

A **JavaFX**, el fil principal, també conegut com el fil d'Aplicació o JavaFX Application Thread, és responsable de gestionar la interfície d'usuari (UI), incloent el dibuix dels elements i la resposta als esdeveniments d'interacció de l'usuari. Bloquejar aquest fil amb tasques llargues o intensives en termes de CPU pot causar que la interfície d'usuari es congeli o es faci poc responsiva.

## Per què és important evitar bloquejar el fil principal?

- **Interactivitat**: Si el fil principal està bloquejat, la UI no podrà respondre als esdeveniments d'usuari com clics de botons o moviments de ratolí. Això fa que l'aplicació es senti lenta o que no respongui.

- **Dibuix**: JavaFX necessita refrescar contínuament la pantalla per mostrar canvis en la UI, animacions, etc. Si el fil principal està ocupat fent altres tasques, el dibuix de la UI es pot veure afectat, resultant en una experiència visual poc fluida.

Per evitar aquests problemes, **cal executar tasques intensives en fils paral·lels**, deixant el fil principal lliure per gestionar la UI. JavaFX proporciona classes com Task i Service per facilitar la creació i gestió de fils paral·lels.

## Platform.runLater

**Platform.runLater** és propi de JavaFX. La seva funció és assegurar-se que el codi proporcionat es corri en el fil d'Aplicació JavaFX, també conegut com el "JavaFX Application Thread". Això és necessari perquè totes les modificacions a la interfície gràfica d'usuari (GUI) han de ser realitzades en aquest fil per evitar problemes de concurrència i assegurar-se que la GUI es comporti de manera correcta i responsiva.

```java
Platform.runLater(() -> {
    textInfo.setText("Some text to display");
});
```

## Exemple 0400

El més senzill és fer un thread i que aquest s'encarregui de fer les tasques pesades. En el següent exemple només es pausa momentàniament el fil amb un 'Thread.sleep'

```java
private void createTask() {
    currentTask = new Task<>() {
        @Override
        protected Void call() throws Exception {
            for (int i = progress; i < 100; i++) {
                if (isCancelled()) {
                    break;
                }
                synchronized (this) {
                    while (isPaused) {
                        wait();
                    }
                }
                
                // ThreadLocalRandom subtitutes Math.random() 
                // for better performance in multithreaded environments
                int waitTime = ThreadLocalRandom.current().nextInt(100, 501);
                Thread.sleep(waitTime);

                updateMessage("Progress: " + i + "%");
                progress = i + 1;
            }
            updateMessage("The End");
            return null;
        }

        @Override
        protected void succeeded() {
            super.succeeded();
            resetButtons();
            progress = 0;
        }

        @Override
        protected void cancelled() {
            super.cancelled();
            resetButtons();
        }

        @Override
        protected void failed() {
            super.failed();
            resetButtons();
        }
    };

    currentTask.messageProperty().addListener((obs, oldMessage, newMessage) -> {
        textCounter.setText(newMessage);
    });
}
```

Per iniciar, pausar o aturar la tasca anterior:

```java
private void startBackgroundTask() {
    taskThread = new Thread(currentTask);
    taskThread.setDaemon(true);
    taskThread.start();

    setButtonsRunning();
}

private void pauseBackgroundTask() {
    if (currentTask != null && currentTask.isRunning()) {
        isPaused = true;
        buttonStart.setDisable(false);
        buttonPause.setDisable(true);
    }
}

private void stopBackgroundTask() {
    if (currentTask != null && currentTask.isRunning()) {
        currentTask.cancel();
        taskThread = null; // Reset the thread
        progress = 0; // Reset the progress
        textCounter.setText("Stopped");
        setButtonsWait();
    }
}
```

<br/>
<center><img src="./assets/ex0400.png" style="max-height: 400px" alt="">
<br/></center>
<br/>
<br/>

## Exemple 0401

En aquest exemple podeu veure com es carrega una imatge des del navegador d'arxius, i es transforma a format **base64**

<br/>
<center><img src="./assets/ex0401.png" style="max-height: 400px" alt="">
<br/></center>
<br/>
<br/>

Els arxius d'imatge poden ser molt grans, per evitar que la seva lectura i transformació a **base64** aturi el fil principal, ho executem en una taca:

```java
Task<String> task = new Task<>() {
    @Override
    protected String call() throws Exception {
        byte[] bytes = Files.readAllBytes(file.toPath());
        return Base64.getEncoder().encodeToString(bytes);
    }
};
// ...
Thread thread = new Thread(task);
thread.setDaemon(true); // Si es tanca la finestra s'atura la tasca
thread.start();
```


## Exemple 0402

L'exemple 0402 fa peticions tipus POST amb un servidor IA compatible amb el protocol "OpenAI", en aquest cas el de l'institut:

```java
private static final String MODEL_NAME = "Qwen36";
private static final String MODEL_URL = "https://agents.ieti.site/v1/chat/completions";
private static final String MODEL_KEY = "SERVER_API_KEY";
```

Les peticions tipus POST les fa el client cap el servidor, el servidor només pot enviar respostes al client (no s'hi pot posar en contacte directament).

En un terminal:

```bash
cd Exemple\ 0402
./run.sh com.project.Main
```

Les crides POST són les més habituals, perquè permeten fer una crides a una API externa, o a una base de dades. 

A JavaFX les crides POST **també cal fer-les amb un thread** però de manera més senzilla fent servir **"httpClient.sendAsync"**.

Hi ha dos tipus de peticions POST:

- **Normals**, rebem la resposta completa un cop disponible
- **Stream**, rebem parts de la resposta a mida que estàn disponibles

```java
private void executeTextRequest(String prompt, boolean stream) {
    JSONArray messages = new JSONArray().put(
        new JSONObject()
            .put("role", "user")
            .put("content", prompt)
    );

    JSONObject body = new JSONObject()
        .put("model", MODEL_NAME)
        .put("messages", messages)
        .put("stream", stream)
        .put("reasoning_effort", "none");

    HttpRequest request = HttpRequest.newBuilder()
        .uri(URI.create(MODEL_URL))
        .header("Content-Type", "application/json")
        .header("Authorization", "Bearer " + MODEL_KEY)
        .POST(BodyPublishers.ofString(body.toString()))
        .build();

    if (stream) {
        Platform.runLater(() -> textInfo.setText("Wait stream ... " + prompt));
        isFirst = true;

        streamRequest = httpClient.sendAsync(
            request,
            HttpResponse.BodyHandlers.ofInputStream()
        ).thenApply(response -> {
            currentInputStream = response.body();
            streamReadingTask = executorService.submit(this::handleStreamResponse);
            return response;
        }).exceptionally(e -> {
            if (!isCancelled.get()) e.printStackTrace();
            Platform.runLater(this::setButtonsIdle);
            return null;
        });

    } else {
        Platform.runLater(() -> textInfo.setText("Wait complete ..."));

        completeRequest = httpClient.sendAsync(
            request,
            HttpResponse.BodyHandlers.ofString()
        ).thenApply(response -> {
            String responseText = extractOpenAIResponse(response.body());

            Platform.runLater(() -> {
                textInfo.setText(responseText);
                setButtonsIdle();
            });

            return response;
        }).exceptionally(e -> {
            if (!isCancelled.get()) e.printStackTrace();

            Platform.runLater(() -> {
                textInfo.setText("Request failed.");
                setButtonsIdle();
            });

            return null;
        });
    }
}
```

En aquest exemple, per tal que el servidor IA descrigui una imatge, li hem d'enviar en format 'base64' dins la mateixa petició:

```java
JSONArray content = new JSONArray()
    .put(
        new JSONObject()
            .put("type", "text")
            .put("text", prompt)
    )
    .put(
        new JSONObject()
            .put("type", "image_url")
            .put("image_url", new JSONObject()
                .put("url", "data:" + mimeType + ";base64," + base64Image))
    );
```

<br/>
<center><img src="./assets/ex0402.png" style="max-height: 400px" alt="">
<br/></center>
<br/>
<br/>