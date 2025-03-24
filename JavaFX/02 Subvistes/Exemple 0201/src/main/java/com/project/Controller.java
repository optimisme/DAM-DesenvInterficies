package com.project;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.ResourceBundle;

import org.json.JSONArray;
import org.json.JSONObject;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import java.util.ArrayList;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.Parent;
import javafx.scene.control.Button;
import javafx.scene.text.Text;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.control.TextField;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.event.ActionEvent;
import javafx.scene.control.Label;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.VBox;

public class Controller implements Initializable {

    @FXML
    private Button buttonSeasons, buttonBrands, buttonFXML;
    @FXML
    private AnchorPane container;
    @FXML
    private VBox yPane = new VBox();

    private String seasons[] = { "Summer", "Autumn", "Winter", "Spring" };
    private String brands[] = { "Audi", "BMW", "Citroen", "Fiat", "Ford", "Honda", "Hyundai", "Kia", "Mazda", "Mercedes",
            "Nissan", "Opel", "Peugeot", "Renault", "Seat", "Skoda", "Suzuki", "Toyota", "Volkswagen", "Volvo" };

    private JSONArray jsonInfo;

    // Called when the FXML file is loaded
    @Override
    public void initialize(URL url, ResourceBundle rb) {
        try {
            // Obtenir el recurs del template .fxml
            URL resource = this.getClass().getResource("/assets/listItem.fxml");

            // Obtenir la llista
            URL jsonFileURL = getClass().getResource("/assets/animals.json");
            Path path = Paths.get(jsonFileURL.toURI());
            String content = new String(Files.readAllBytes(path), StandardCharsets.UTF_8);
            jsonInfo = new JSONArray(content);

            // Actualitza la UI amb els valors inicials de les estacions
            setSeasons(null);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @FXML
    private void setSeasons(ActionEvent event) {
        // Esborrar la llista anterior
        yPane.getChildren().clear();

        // Generar la nova llista
        for (String name : seasons) {
            Label label = new Label(name);
            label.setStyle("-fx-border-color: red;");
            yPane.getChildren().add(label);
        }
    }

    @FXML
    private void setBrands(ActionEvent event) {
        // Esborrar la llista anterior
        yPane.getChildren().clear();

        // Generar la nova llista
        for (String name : brands) {
            Label label = new Label(name);
            label.setStyle("-fx-border-color: black;");
            yPane.getChildren().add(label);
        }
    }

    @FXML
    private void setFXML(ActionEvent event) throws Exception {

        // Obtenir el recurs del template .fxml
        URL resource = this.getClass().getResource("/assets/listItem.fxml");

        // Esborrar la llista anterior
        yPane.getChildren().clear();

        // Generar la nova llista a partir de 'jsonInfo'
        for (int i = 0; i < jsonInfo.length(); i++) {
            // Obtenir l'objecte JSON individual (animal)
            JSONObject animal = jsonInfo.getJSONObject(i);

            // Extreure la informació necessària del JSON
            String category = animal.getString("category");
            String name = animal.getString("animal");
            String color = animal.getString("color");

            // Carregar el template de 'listItem.fxml'
            FXMLLoader loader = new FXMLLoader(resource);
            Parent itemTemplate = loader.load();
            ControllerListItem itemController = loader.getController();

            // Assignar els valors als controls del template
            itemController.setTitle(name);
            itemController.setSubtitle(category);
            itemController.setImatge("/assets/images/" + name.toLowerCase() + ".png");
            itemController.setCircleColor(color);

            // Afegir el nou element a 'yPane'
            yPane.getChildren().add(itemTemplate);
        }
    }

}