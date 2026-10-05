package com.project;

import java.net.URL;
import java.util.ResourceBundle;

import javafx.animation.AnimationTimer;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.input.KeyCode;
import javafx.scene.input.KeyEvent;
import javafx.scene.layout.AnchorPane;
import javafx.scene.control.ChoiceBox;
import javafx.scene.layout.HBox;

public class Controller implements Initializable {

    @FXML
    private AnchorPane anchor;

    @FXML
    public Canvas canvas;

    @FXML
    public HBox hbox;

    @FXML
    private ChoiceBox<String> choiceBox = new ChoiceBox<>();
    
    private static CnvController cnvController;
    private String choiceBoxValues[] = { "Linies", "Poligons", "Poligons emplenats",
        "Quadrats i cercles", "Imatges", "Gradients lineals", "Gradients radials",
        "Transformacions", "Texts", "Text multilinia" };

    @Override
    public void initialize(URL url, ResourceBundle rb) {

        // Initialize canvas responsive size
        UtilsViews.parentContainer.heightProperty().addListener((observable, oldValue, newvalue) -> { actionSetSize(); });
        UtilsViews.parentContainer.widthProperty().addListener((observable, oldValue, newvalue) -> { actionSetSize(); });

        // Initalize game controller
        cnvController = new CnvController(canvas);

        // Initialize choiceBox
        choiceBox.getItems().addAll(choiceBoxValues);
        choiceBox.setValue("Linies");
        choiceBox.setOnAction((event) -> { cnvController.actionSetSelection(choiceBox.getSelectionModel().getSelectedItem()); });
    }

    public void actionSetSize() {
        // Start Canvas size
        double width = UtilsViews.parentContainer.getWidth();
        double height = UtilsViews.parentContainer.getHeight() - hbox.getHeight();
        canvas.setWidth(width);
        canvas.setHeight(height);
    }
}
