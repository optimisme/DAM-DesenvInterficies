package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.TextArea;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.event.ActionEvent;
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
        // Choose image file (default dir = current working dir)
        FileChooser fc = new FileChooser();
        fc.setTitle("Choose an image");
        File initialDir = new File(System.getProperty("user.dir"));
        if (initialDir.exists() && initialDir.isDirectory()) {
            fc.setInitialDirectory(initialDir);
        }
        fc.getExtensionFilters().addAll(
            new FileChooser.ExtensionFilter("Images", "*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.gif")
        );

        File file = fc.showOpenDialog(buttonLoad.getScene().getWindow());
        if (file == null) return;

        try {
            // Read bytes and encode to Base64
            byte[] bytes = Files.readAllBytes(file.toPath());
            String base64 = Base64.getEncoder().encodeToString(bytes);

            // Preview image
            imageView.setImage(new Image(file.toURI().toString()));

            // Output base64 to textarea
            textBase64.setText(base64);
        } catch (Exception e) {
            e.printStackTrace(); // log error
            textBase64.setText("Error reading image: " + e.getMessage());
        }
    }
}
