package com.project;

import javafx.application.Application;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.scene.Scene;
import javafx.scene.image.Image;
import javafx.stage.Stage;

public class Main extends Application {

    final int WINDOW_WIDTH = 600;
    final int WINDOW_HEIGHT = 400;
    final int MIN_WIDTH = 300;
    final int MIN_HEIGHT = 600;

    public static void main(String[] args) {
        launch(args);
    }

    @Override
    public void start(Stage stage) throws Exception {

        UtilsViews.parentContainer.setStyle("-fx-font: 14 arial;");
        UtilsViews.addView(getClass(), "Desktop", "/assets/layout_desktop.fxml");
        UtilsViews.addView(getClass(), "Mobile", "/assets/layout_mobile.fxml");

        Scene scene = new Scene(UtilsViews.parentContainer);

        // Listen to window width changes
        scene.widthProperty().addListener((ChangeListener<? super Number>) new ChangeListener<Number>() {
            @Override
            public void changed(ObservableValue<? extends Number> observable, Number oldWidth, Number newWidth) {
                _setLayout(newWidth.intValue());
            }
        });

        stage.setScene(scene);
        stage.setTitle("JavaFX App");
        stage.setMinWidth(MIN_WIDTH);
        stage.setWidth(WINDOW_WIDTH);
        stage.setMinHeight(MIN_HEIGHT);
        stage.setHeight(WINDOW_HEIGHT);
        stage.show();

        // Afegeix un listener per detectar canvis en les dimensions de la finestra
        stage.widthProperty().addListener((obs, oldVal, newVal) -> {
            System.out.println("Width changed: " + newVal);
        });

        stage.heightProperty().addListener((obs, oldVal, newVal) -> {
            System.out.println("Height changed: " + newVal);
        });

        // Add icon only if not Mac
        if (!System.getProperty("os.name").contains("Mac")) {
            Image icon = new Image("file:/icons/icon.png");
            stage.getIcons().add(icon);
        }
    }

    private void _setLayout(int width) {
        if (width < 600) {
            UtilsViews.setView("Mobile");
        } else {
            UtilsViews.setView("Desktop");
        }
    }
}