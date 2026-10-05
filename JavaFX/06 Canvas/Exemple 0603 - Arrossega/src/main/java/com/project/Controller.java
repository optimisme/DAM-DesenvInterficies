package com.project;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.layout.AnchorPane;
import javafx.scene.input.MouseEvent;
import javafx.scene.paint.Color;
import javafx.scene.shape.Rectangle;
import javafx.scene.shape.Ellipse;

import java.net.URL;
import java.util.ResourceBundle;

public class Controller implements Initializable {

    @FXML
    private AnchorPane anchorPane;

    @FXML
    private Canvas canvas;

    private GraphicsContext gc;
    private Rectangle greenSquare;
    private Ellipse blueCircle;
    private double offsetX, offsetY;
    private Object selectedShape;
    private Boolean dragging = false;

    @Override
    public void initialize(URL url, ResourceBundle rb) {
        gc = canvas.getGraphicsContext2D();
        greenSquare = new Rectangle(50, 50, 100, 100);
        blueCircle = new Ellipse(250, 250, 50, 50);
        selectedShape = greenSquare;

        canvas.setOnMousePressed(this::onMousePressed);
        canvas.setOnMouseDragged(this::onMouseDragged);
        canvas.setOnMouseReleased(this::onMouseReleased);

        canvas.widthProperty().addListener(evt -> drawShapes());
        canvas.heightProperty().addListener(evt -> drawShapes());

        // Ensure canvas resizes with the window
        anchorPane.widthProperty().addListener((obs, oldVal, newVal) -> {
            canvas.setWidth(newVal.doubleValue());
            adjustShapes();
            drawShapes();
        });
        anchorPane.heightProperty().addListener((obs, oldVal, newVal) -> {
            canvas.setHeight(newVal.doubleValue());
            adjustShapes();
            drawShapes();
        });

        drawShapes();
    }

    private void onMousePressed(MouseEvent event) {
        if (greenSquare.contains(event.getX(), event.getY())) {
            selectedShape = greenSquare;
            offsetX = event.getX() - greenSquare.getX();
            offsetY = event.getY() - greenSquare.getY();
            dragging = true;
        } else if (blueCircle.contains(event.getX(), event.getY())) {
            selectedShape = blueCircle;
            offsetX = event.getX() - blueCircle.getCenterX();
            offsetY = event.getY() - blueCircle.getCenterY();
            dragging = true;
        }
    }

    private void onMouseDragged(MouseEvent event) {
        if (dragging) {
            if (selectedShape == greenSquare) {
                greenSquare.setX(event.getX() - offsetX);
                greenSquare.setY(event.getY() - offsetY);
            } else if (selectedShape == blueCircle) {
                blueCircle.setCenterX(event.getX() - offsetX);
                blueCircle.setCenterY(event.getY() - offsetY);
            }
            drawShapes();
        }
    }

    private void onMouseReleased(MouseEvent event) {
        dragging = false;
    }

    private void adjustShapes() {
        // Adjust green square position if out of bounds
        if (greenSquare.getX() + greenSquare.getWidth() > canvas.getWidth()) {
            greenSquare.setX(canvas.getWidth() - greenSquare.getWidth());
        }
        if (greenSquare.getY() + greenSquare.getHeight() > canvas.getHeight()) {
            greenSquare.setY(canvas.getHeight() - greenSquare.getHeight());
        }

        // Adjust blue circle position if out of bounds
        if (blueCircle.getCenterX() + blueCircle.getRadiusX() > canvas.getWidth()) {
            blueCircle.setCenterX(canvas.getWidth() - blueCircle.getRadiusX());
        }
        if (blueCircle.getCenterY() + blueCircle.getRadiusY() > canvas.getHeight()) {
            blueCircle.setCenterY(canvas.getHeight() - blueCircle.getRadiusY());
        }
        drawShapes();
    }

    private void drawShapes() {
        gc.clearRect(0, 0, canvas.getWidth(), canvas.getHeight());

        if (selectedShape == greenSquare) {
            drawShape(blueCircle, Color.BLUE);
            drawShape(greenSquare, greenSquare.getBoundsInLocal().intersects(blueCircle.getBoundsInLocal()) ? Color.ORANGE.deriveColor(1, 1, 1, 0.5) : Color.GREEN);
        } else if (selectedShape == blueCircle) {
            drawShape(greenSquare, Color.GREEN);
            drawShape(blueCircle, blueCircle.getBoundsInLocal().intersects(greenSquare.getBoundsInLocal()) ? Color.ORANGE.deriveColor(1, 1, 1, 0.5) : Color.BLUE);
        } else {
            drawShape(greenSquare, Color.GREEN);
            drawShape(blueCircle, Color.BLUE);
        }
    }

    private void drawShape(Rectangle rectangle, Color color) {
        gc.setFill(color);
        gc.fillRect(rectangle.getX(), rectangle.getY(), rectangle.getWidth(), rectangle.getHeight());
    }

    private void drawShape(Ellipse ellipse, Color color) {
        gc.setFill(color);
        gc.fillOval(ellipse.getCenterX() - ellipse.getRadiusX(), ellipse.getCenterY() - ellipse.getRadiusY(), ellipse.getRadiusX() * 2, ellipse.getRadiusY() * 2);
    }
}
