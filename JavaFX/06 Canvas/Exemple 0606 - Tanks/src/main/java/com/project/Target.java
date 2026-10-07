package com.project;

import java.util.List;

import javafx.geometry.Point2D;
import javafx.scene.canvas.GraphicsContext;

// Punt de mira (posició del ratolí)
class Target {
    
    static final double DOT_RADIUS = 3;
    private static final double CROSSHAIR_GAP = 4;
    private static final double CROSSHAIR_SIZE = 12;

    private Point2D position = Point2D.ZERO;

    Point2D getPosition() {
        return position;
    }

    void setPosition(double x, double y) {
        position = new Point2D(x, y);
    }

    // La guia es dibuixa des del tanc fins al ratolí, i s'atura al primer obstacle.
    void drawGuide(GraphicsContext gc, Tank tank, List<ObjectStatic> obstacles) {
        if (!tank.isAlive()) return;
        Point2D start = tank.getPosition();
        double angle = HelperMath.angleToTarget(start, position);
        double distance = start.distance(position);

        gc.save();
        gc.setFill(tank.getColor());
        for (double d = 44; d < distance; d += 18) {
            Point2D dot = HelperMath.positionAtDistance(start, angle, d);
            if (touchesAny(dot, obstacles)) break;
            gc.fillOval(dot.getX() - DOT_RADIUS, dot.getY() - DOT_RADIUS,
                DOT_RADIUS * 2, DOT_RADIUS * 2);
        }
        gc.restore();
    }

    private boolean touchesAny(Point2D dot, List<ObjectStatic> obstacles) {
        for (ObjectStatic obstacle : obstacles) {
            if (obstacle.touches(dot, DOT_RADIUS)) return true;
        }
        return false;
    }

    // Quatre segments deixen un petit espai buit al centre del punt de mira.
    void draw(GraphicsContext gc, Tank tank) {
        double x = position.getX(), y = position.getY();
        gc.save();
        gc.setStroke(tank.getColor());
        gc.setLineWidth(2);
        gc.setLineDashes();
        gc.strokeLine(x - CROSSHAIR_SIZE, y, x - CROSSHAIR_GAP, y);
        gc.strokeLine(x + CROSSHAIR_GAP, y, x + CROSSHAIR_SIZE, y);
        gc.strokeLine(x, y - CROSSHAIR_SIZE, x, y - CROSSHAIR_GAP);
        gc.strokeLine(x, y + CROSSHAIR_GAP, x, y + CROSSHAIR_SIZE);
        gc.restore();
    }
}
