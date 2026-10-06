package com.project;

import javafx.geometry.Point2D;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.paint.Color;

// Efecte que representa una explosió
class Explosion {

    private final Point2D position;
    private final double radius;
    private final double duration;
    private double remaining;

    Explosion(double x, double y, double radius, double duration) {
        position = new Point2D(x, y);
        this.radius = radius;
        this.duration = duration;
        remaining = duration;
    }

    // Actualitzar l'estat de l'explosió (run)
    // segons el temps transcorregut "dt"
    void update(double dt) {
        remaining -= dt;
    }

    // Comprovar si l'explosió ha finalitzat
    boolean isFinished() {
        return remaining <= 0;
    }

    // Dibuixar l'explosió al canvas
    void draw(GraphicsContext gc) {

        if (isFinished()) return;

        // Calcular radi i posició de l'explosió
        double progress = 1 - remaining / duration;
        double currentRadius = radius * (0.3 + 0.7 * progress);
        double x = position.getX() - currentRadius;
        double y = position.getY() - currentRadius;

        // Dibuixar l'explosió
        gc.save();
        gc.setGlobalAlpha(1 - progress);
        gc.setFill(Color.ORANGE);
        gc.fillOval(x, y, currentRadius * 2, currentRadius * 2);
        gc.setStroke(Color.ORANGERED);
        gc.strokeOval(x, y, currentRadius * 2, currentRadius * 2);
        gc.restore();
    }
}
