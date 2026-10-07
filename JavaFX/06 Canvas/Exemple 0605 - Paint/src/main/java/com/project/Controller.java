package com.project;

import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.ResourceBundle;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.control.RadioButton;
import javafx.scene.input.MouseButton;
import javafx.scene.input.MouseEvent;
import javafx.scene.paint.Color;
import javafx.scene.shape.StrokeLineCap;
import javafx.scene.shape.StrokeLineJoin;

public class Controller implements Initializable {

    @FXML private Canvas canvas;
    @FXML private Canvas colorsCanvas;
    @FXML private RadioButton thickRadio;

    private GraphicsContext gc;
    private ColorPalette colorPalette;

    private static final double THIN_WIDTH = 2;
    private static final double THICK_WIDTH = 8;

    // Drawing state
    private final List<Stroke> strokes = new ArrayList<>();
    private Stroke currentStroke = null;

    @Override
    public void initialize(URL url, ResourceBundle rb) {
        gc = canvas.getGraphicsContext2D();
        gc.setLineCap(StrokeLineCap.ROUND);
        gc.setLineJoin(StrokeLineJoin.ROUND);

        // The palette handles its own drawing and clicks
        colorPalette = new ColorPalette(colorsCanvas);

        // Drawing canvas events
        canvas.setOnMousePressed(this::onMousePressed);
        canvas.setOnMouseDragged(this::onMouseDragged);
        canvas.setOnMouseReleased(this::onMouseReleased);

        redraw();
    }

    private double getSelectedWidth() {
        return thickRadio.isSelected() ? THICK_WIDTH : THIN_WIDTH;
    }

    // Drawing canvas

    private void onMousePressed(MouseEvent event) {
        if (event.getButton() != MouseButton.PRIMARY) return;

        // Start a new stroke with the current style
        currentStroke = new Stroke(colorPalette.getSelectedColor(), getSelectedWidth());
        currentStroke.addPoint(event.getX(), event.getY());
        redraw();
    }

    private void onMouseDragged(MouseEvent event) {
        if (currentStroke == null) return;

        currentStroke.addPoint(event.getX(), event.getY());
        redraw();
    }

    private void onMouseReleased(MouseEvent event) {
        if (currentStroke == null) return;

        // The stroke is finished: keep it in memory
        currentStroke.addPoint(event.getX(), event.getY());
        strokes.add(currentStroke);
        currentStroke = null;
        redraw();
    }

    private void redraw() {
        gc.setFill(Color.WHITE);
        gc.fillRect(0, 0, canvas.getWidth(), canvas.getHeight());

        // Saved strokes, in creation order
        for (Stroke s : strokes) {
            s.draw(gc);
        }

        // Stroke being drawn right now (preview)
        if (currentStroke != null) {
            currentStroke.draw(gc);
        }
    }
}
