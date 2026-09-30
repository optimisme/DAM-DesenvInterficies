package com.project;

import javafx.concurrent.Task;
import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.TextArea;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.stage.FileChooser;

import java.io.File;
import java.nio.file.Files;
import java.util.Base64;

public class Controller {

    @FXML private ImageView imageView;
    @FXML private TextArea textBase64;
    @FXML private Button buttonLoad;

    @FXML
    private void callLoadImage(ActionEvent event) {
        FileChooser fc = new FileChooser();
        fc.setTitle("Choose an image");

        File initialDir = new File(System.getProperty("user.dir"));
        if (initialDir.exists() && initialDir.isDirectory()) {
            fc.setInitialDirectory(initialDir);
        }

        fc.getExtensionFilters().add(
            new FileChooser.ExtensionFilter(
                "Images",
                "*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.gif"
            )
        );

        File file = fc.showOpenDialog(buttonLoad.getScene().getWindow());
        if (file == null) return;

        Task<String> task = new Task<>() {
            @Override
            protected String call() throws Exception {
                byte[] bytes = Files.readAllBytes(file.toPath());
                return Base64.getEncoder().encodeToString(bytes);
            }
        };

        task.setOnSucceeded(e -> {
            String base64 = task.getValue();

            imageView.setImage(new Image(file.toURI().toString()));
            textBase64.setText(base64);
        });

        task.setOnFailed(e -> {
            Throwable error = task.getException();
            error.printStackTrace();

            textBase64.setText(
                "Error reading image: " + error.getMessage()
            );
        });

        Thread thread = new Thread(task);
        thread.setDaemon(true);
        thread.start();
    }
}