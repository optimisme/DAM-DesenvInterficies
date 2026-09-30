package com.project;

import java.net.URL;
import java.util.concurrent.ThreadLocalRandom;
import java.util.ResourceBundle;
import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.text.Text;
import javafx.event.ActionEvent;
import javafx.concurrent.Task;
import javafx.fxml.Initializable;

public class Controller implements Initializable {

    @FXML
    private Button buttonStart, buttonPause, buttonStop;

    @FXML
    private Text textCounter;

    private Task<Void> currentTask;
    private Thread taskThread;
    private boolean isPaused = false;
    private int progress = 0;

    @Override
    public void initialize(URL url, ResourceBundle rb) {
        setButtonsIdle();
    }

    @FXML
    private void actionStart(ActionEvent event) {
        if (taskThread == null || !taskThread.isAlive()) {
            createTask();
            startBackgroundTask();
        } else if (isPaused) {
            isPaused = false;
            synchronized (currentTask) {
                currentTask.notify();
            }
            setButtonsRunning();
        }
    }

    @FXML
    private void actionPause(ActionEvent event) {
        pauseBackgroundTask();
    }

    @FXML
    private void actionStop(ActionEvent event) {
        stopBackgroundTask();
    }

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
            isPaused = false;
            currentTask.cancel();
            taskThread = null; // Reset the thread
            progress = 0; // Reset the progress
            textCounter.setText("Stopped");
            setButtonsIdle();
        }
    }

    private void resetButtons() {
        setButtonsIdle();
    }

    private void setButtonsRunning() {
        buttonStart.setDisable(true);
        buttonPause.setDisable(false);
        buttonStop.setDisable(false);
    }

    private void setButtonsIdle() {
        buttonStart.setDisable(false);
        buttonPause.setDisable(true);
        buttonStop.setDisable(true);
    }
}
