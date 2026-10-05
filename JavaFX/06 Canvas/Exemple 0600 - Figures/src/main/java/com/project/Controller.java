package com.project;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.control.Button;
import javafx.scene.input.MouseEvent;
import javafx.scene.paint.Color;
import javafx.event.ActionEvent;

import java.net.URL;
import java.util.Random;
import java.util.ResourceBundle;

public class Controller implements Initializable {

    @FXML
    private Canvas canvas;
    @FXML
    private Button buttonAdd;
    @FXML
    private Button buttonClear;

    private GraphicsContext gc;
    private Random random;

    @Override
    public void initialize(URL url, ResourceBundle rb) {
        gc = canvas.getGraphicsContext2D();
        random = new Random();

        firstDrawing();

        canvas.addEventHandler(MouseEvent.MOUSE_CLICKED, event -> {
            drawPolygon(event.getX(), event.getY());
        });
    }

    @FXML
    private void actionAdd(ActionEvent event) {
        // Generar una posició aleatòria per a la forma
        double x = random.nextDouble() * (canvas.getWidth() - 50);
        double y = random.nextDouble() * (canvas.getHeight() - 50);

        drawPolygon(x, y);
    }

    @FXML
    private void actionClear(ActionEvent event) {
        // Netejar tot el Canvas
        gc.clearRect(0, 0, canvas.getWidth(), canvas.getHeight());
        firstDrawing();
    }

    private Color getRandomColor() {
        Color[] colors = { Color.RED, Color.CYAN, Color.MAGENTA, Color.YELLOW, Color.ORANGE, Color.BLACK };
        return colors[random.nextInt(colors.length)];
    }

    private void firstDrawing() {
        // Dibuixar sobre el Canvas
        gc.setFill(Color.BLUE);
        gc.fillRect(75, 75, 250, 250);

        gc.setStroke(Color.RED);
        gc.strokeLine(50, 50, 350, 350);

        gc.setFill(Color.GREEN);
        gc.fillOval(100, 100, 200, 200);
    }

    private void drawPolygon(double x, double y) {
        gc.setFill(getRandomColor());

        Color color = getRandomColor();
        double size = 15 + random.nextInt(36);
        double half = size / 2;

        // Decidir aleatòriament si dibuixar un quadrat o un cercle
        if (random.nextBoolean()) {
            // Dibuixar un quadrat
            gc.setFill(color);
            gc.fillRect(x - half, y - half, size, size);
        } else {
            // Dibuixar un cercle
            gc.setFill(color);
            gc.fillOval(x - half, y - half, size, size);
        }
    }
}
