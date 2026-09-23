package com.project;

import javafx.application.Application;
import javafx.stage.Stage;

public class Main extends Application {

    public static String nom = "";
    public static String edat = "";

    @Override
    public void start(Stage primaryStage) {
        UtilsViews.parentStage = primaryStage;
        primaryStage.setTitle("Ejercicio Multi-vista");
        
        UtilsViews.setView("layout_desktop");
        primaryStage.show();
    }

    public static void main(String[] args) {
        launch(args);
    }
}
