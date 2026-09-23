package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.control.TextField;

public class ControllerDesktop {

    @FXML private TextField txtNom;
    @FXML private TextField txtEdat;
    @FXML private Label lblError;

    @FXML
    public void enviarDades() {
        String nomIntroduit = txtNom.getText().trim();
        String edatIntroduida = txtEdat.getText().trim();

        if (nomIntroduit.isEmpty() || edatIntroduida.isEmpty()) {
            lblError.setText("Si us plau, omple tots els camps.");
        } else {
            lblError.setText("");
            
            // Guardamos los datos en las variables estáticas de Main
            Main.nom = nomIntroduit;
            Main.edat = edatIntroduida;
            
            // Siguiendo el ejemplo exacto de tu enunciado:
            // 1. Obtenemos el controlador de la segunda vista (esto fuerza la carga del FXML)
            ControllerMobile ctrlMobile = (ControllerMobile) UtilsViews.getController("layout_mobile");
            
            // 2. Llamamos a su método para pintar los datos que acabamos de guardar
            if (ctrlMobile != null) {
                ctrlMobile.actualitzarText();
            }
            
            // 3. Cambiamos visualmente a la segunda vista
            UtilsViews.setView("layout_mobile");
        }
    }
}
