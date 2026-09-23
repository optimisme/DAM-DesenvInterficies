package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.Label;

public class ControllerMobile {

    @FXML private Label lblResultat;

    public void actualitzarText() {
        lblResultat.setText("Hola " + Main.nom + ", tens " + Main.edat + " anys!");
    }

    @FXML
    public void tornarEnrere() {
        UtilsViews.setView("layout_desktop");
    }
}
