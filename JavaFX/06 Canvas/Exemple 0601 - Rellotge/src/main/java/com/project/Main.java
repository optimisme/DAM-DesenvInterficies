package com.project;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.image.Image;
import javafx.stage.Stage;

public class Main extends Application {

    final int WINDOW_WIDTH = 600;
    final int WINDOW_HEIGHT = 400;

    @Override
    public void start(Stage stage) throws Exception {

        // Carrega la vista inicial des del fitxer FXML
        UtilsViews.parentContainer.setStyle("-fx-font: 14 arial;");
        UtilsViews.addView(getClass(), "Desktop", "/assets/layout.fxml");

        Scene scene = new Scene(UtilsViews.parentContainer);

        stage.setScene(scene);
        stage.setTitle("JavaFX App");
        stage.setWidth(WINDOW_WIDTH);
        stage.setHeight(WINDOW_HEIGHT);
        stage.show();

        // Afegeix una icona només si no és un Mac
        if (!System.getProperty("os.name").contains("Mac")) {
            Image icon = new Image("file:icons/icon.png");
            stage.getIcons().add(icon);
        }
    }

    public static void main(String[] args) {
        launch(args);
    }
}
