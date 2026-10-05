package com.project;

import javafx.animation.AnimationTimer;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.input.KeyCode;
import javafx.scene.input.KeyEvent;
import javafx.scene.layout.AnchorPane;

import java.net.URL;
import java.util.ArrayList;
import java.util.ResourceBundle;

public class Controller implements Initializable {

    @FXML
    private AnchorPane anchor;

    @FXML
    public Canvas canvas;

    private static CnvController cnvController;

    @Override
    public void initialize(URL url, ResourceBundle rb) {

        // Initialize canvas responsive size
        UtilsViews.parentContainer.heightProperty().addListener((observable, oldValue, newvalue) -> { actionSetSize(); });
        UtilsViews.parentContainer.widthProperty().addListener((observable, oldValue, newvalue) -> { actionSetSize(); });

        // Initalize game controller
        cnvController = new CnvController(canvas);
    }

    // Define Canvas size
    public void actionSetSize() {

        double width = UtilsViews.parentContainer.getWidth();
        double height = UtilsViews.parentContainer.getHeight();
        canvas.setWidth(width);
        canvas.setHeight(height);
    }
}
