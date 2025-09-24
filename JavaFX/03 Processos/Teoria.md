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
                Thread.sleep(100); // Simulate work
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

## Exemple 0402

Per fer anar aquest exemple cal un servidor Ollama amb el model 'llama3.2':

```bash
ollama pull gemma3:1b
ollama run gemma3:1b
```

Quan estigui carregat, en un terminal diferent:

```bash
cd Exemple\ 0401
./run.sh com.project.Main
```

Molt sovint enlloc d'una tasca completa únicament necessitem fer una crida a una API externa, o a una base de dades. **També cal fer-ho amb un thread** però de manera més senzilla fent servir **"httpClient.sendAsync"**.

Si només volem fer una petició que espera una resposta completa:

```java
@FXML
private void callComplete(ActionEvent event) {
    textInfo.setText(""); // Clear the textInfo
    setButtonsRunning();
    isCancelled.set(false);

    HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create("http://localhost:11434/api/generate"))
            .header("Content-Type", "application/json")
            .POST(BodyPublishers.ofString(
                    "{\"model\": \"llama3\", \"prompt\": \"Tell me a haiku.\", \"stream\": false}"))
            .build();

    Platform.runLater(() -> textInfo.setText("Wait complete ..."));

    completeRequest = httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofString())
            .thenApply(response -> {
                JSONObject jsonResponse = new JSONObject(response.body());
                String responseText = jsonResponse.getString("response");
                Platform.runLater(() -> {
                    textInfo.setText(responseText);
                    setButtonsIdle();
                });
                return response;
            })
            .exceptionally(e -> {
                if (!isCancelled.get()) {
                    e.printStackTrace();
                }
                Platform.runLater(this::setButtonsIdle);
                return null;
            });
}
```

Si volem fer una petició tipus *stream* i processar cada un dels *blocs* de dades que rebem:

```java
@FXML
private void callStream(ActionEvent event) {
    textInfo.setText(""); // Clear the textInfo
    setButtonsRunning();
    isCancelled.set(false);

    HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create("http://localhost:11434/api/generate"))
            .header("Content-Type", "application/json")
            .POST(BodyPublishers.ofString("{\"model\": \"llama3\", \"prompt\": \"Why is the sky blue?\"}"))
            .build();

    Platform.runLater(() -> textInfo.setText("Wait stream ..."));

    isFirst = true;
    streamRequest = httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofInputStream())
            .thenApply(response -> {
                currentInputStream = response.body();
                streamReadingTask = executorService.submit(() -> {
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(currentInputStream))) {
                        String line;
                        while ((line = reader.readLine()) != null) {
                            if (isCancelled.get()) {
                                System.out.println("Stream cancelled");
                                break;
                            }
                            JSONObject jsonResponse = new JSONObject(line);
                            String responseText = jsonResponse.getString("response");
                            if (isFirst) {
                                Platform.runLater(() -> textInfo.setText(responseText));
                                isFirst = false;
                            } else {
                                Platform.runLater(() -> textInfo.setText(textInfo.getText() + responseText));
                            }
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                        Platform.runLater(() -> {
                            textInfo.setText("Error during streaming.");
                            setButtonsIdle();
                        });
                    } finally {
                        try {
                            if (currentInputStream != null) {
                                System.out.println("Cancelling InputStream in finally");
                                currentInputStream.close();
                            }
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                        Platform.runLater(this::setButtonsIdle);
                    }
                });
                return response;
            })
            .exceptionally(e -> {
                if (!isCancelled.get()) {
                    e.printStackTrace();
                }
                Platform.runLater(this::setButtonsIdle);
                return null;
            });
}
```

<br/>
<center><img src="./assets/ex0402.png" style="max-height: 400px" alt="">
<br/></center>
<br/>
<br/>