package com.project;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.stage.Stage;

public class Main extends Application {

    @Override
    public void start(Stage primaryStage) throws Exception {
        // Carrega la vista FXML que conté els elements visuals i està enllaçada amb el controller
        FXMLLoader loader = new FXMLLoader(getClass().getResource("/assets/CalculadoraView.fxml"));
        Scene scene = new Scene(loader.load());

        primaryStage.setTitle("Calculadora JavaFX (MVC)");
        primaryStage.setScene(scene);
        primaryStage.show();
    }

    public static void main(String[] args) {
        launch(args);
    }
}