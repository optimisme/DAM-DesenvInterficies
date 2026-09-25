package com.project;

import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;
import java.util.HashMap;

public class UtilsViews {

    public static Stage parentStage;
    private static HashMap<String, FXMLLoader> loaders = new HashMap<>();

    public static Object getController(String fxmlName) {
        try {
            FXMLLoader loader = new FXMLLoader(UtilsViews.class.getResource("/assets/" + fxmlName + ".fxml"));
            Parent root = loader.load();
            
            loaders.put(fxmlName, loader);
            return loader.getController();
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    public static void setView(String fxmlName) {
        try {
            FXMLLoader loader = loaders.get(fxmlName);
            Parent root;
            
            if (loader == null) {
                loader = new FXMLLoader(UtilsViews.class.getResource("/assets/" + fxmlName + ".fxml"));
                root = loader.load();
                loaders.put(fxmlName, loader);
            } else {
                root = loader.getRoot();
            }

            Scene scene = new Scene(root);
            parentStage.setScene(scene);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}