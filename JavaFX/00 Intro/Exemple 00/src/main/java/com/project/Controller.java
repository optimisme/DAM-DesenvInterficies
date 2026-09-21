package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.ComboBox;
import javafx.scene.control.Label;
import javafx.scene.control.TextField;

public class Controller {

    @FXML
    private TextField inputNum1;

    @FXML
    private TextField inputNum2;

    @FXML
    private ComboBox<String> comboOperacio;

    @FXML
    private Label lblResultat;

    @FXML
    public void initialize() {
        comboOperacio.getItems().addAll("+", "-", "*", "/");
        comboOperacio.setValue("+");
    }

    @FXML
    private void onCalcularClick() {
        try {
            double num1 = Double.parseDouble(inputNum1.getText());
            double num2 = Double.parseDouble(inputNum2.getText());
            String operacio = comboOperacio.getValue();
            double resultat = 0;

            switch (operacio) {
                case "+":
                    resultat = num1 + num2;
                    break;
                case "-":
                    resultat = num1 - num2;
                    break;
                case "*":
                    resultat = num1 * num2;
                    break;
                case "/":
                    if (num2 == 0) {
                        lblResultat.setText("Error: Divisió per zero");
                        return;
                    }
                    resultat = num1 / num2;
                    break;
            }

            lblResultat.setText("Resultat: " + resultat);

        } catch (NumberFormatException ex) {
            lblResultat.setText("Error: Introdueix números vàlids");
        }
    }
}
