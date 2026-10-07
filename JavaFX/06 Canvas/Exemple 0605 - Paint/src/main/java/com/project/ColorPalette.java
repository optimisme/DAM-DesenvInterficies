package com.project;

import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.input.MouseEvent;
import javafx.scene.paint.Color;

// Predefined colors drawn as circles on their own Canvas
public class ColorPalette {

    private static final Color[] COLORS = { Color.BLUE, Color.RED };
    private static final double RADIUS = 18;
    private static final double SPACING = 60;

    private final Canvas canvas;
    private final GraphicsContext gc;
    private Color selectedColor = COLORS[0];

    public ColorPalette(Canvas canvas) {
        this.canvas = canvas;
        this.gc = canvas.getGraphicsContext2D();

        canvas.setOnMouseClicked(this::onMouseClicked);
        draw();
    }

    public Color getSelectedColor() {
        return selectedColor;
    }

    private double getCenterX(int index) {
        return SPACING / 2 + index * SPACING;
    }

    private double getCenterY() {
        return canvas.getHeight() / 2;
    }

    private void onMouseClicked(MouseEvent event) {
        for (int i = 0; i < COLORS.length; i++) {
            // Inside the circle if the distance to its center is smaller than the radius
            double dx = event.getX() - getCenterX(i);
            double dy = event.getY() - getCenterY();

            // Check if the click is inside the circle
            if (Math.sqrt(dx * dx + dy * dy) <= RADIUS) {
                selectedColor = COLORS[i];
                draw();
                return;
            }
        }
    }

    private void draw() {
        gc.clearRect(0, 0, canvas.getWidth(), canvas.getHeight());

        for (int i = 0; i < COLORS.length; i++) {
            double cx = getCenterX(i);
            double cy = getCenterY();

            gc.setFill(COLORS[i]);
            gc.fillOval(cx - RADIUS, cy - RADIUS, RADIUS * 2, RADIUS * 2);

            // Mark the selected color with a ring around it
            if (COLORS[i].equals(selectedColor)) {
                double r = RADIUS + 5;
                gc.setStroke(Color.BLACK);
                gc.setLineWidth(2);
                gc.strokeOval(cx - r, cy - r, r * 2, r * 2);
            }
        }
    }
}
