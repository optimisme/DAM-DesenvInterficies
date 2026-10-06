package com.project;

import javafx.geometry.Point2D;
import javafx.geometry.Rectangle2D;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.paint.Color;

// Rectangle immòbil: representa tant una paret com un obstacle interior.
class ObjectStatic extends ObjectBase {

    private final Rectangle2D bounds;
    private final Color color;

    ObjectStatic(double x, double y, double width, double height, Color color) {
        this.bounds = new Rectangle2D(x, y, width, height);
        this.color = color;
    }

    Rectangle2D getBounds() {
        return bounds;
    }

    // La posició del rectangle és la cantonada superior esquerra.
    @Override
    Point2D getPosition() {
        return new Point2D(bounds.getMinX(), bounds.getMinY());
    }

    // Indica si un cercle situat a "center" toca aquest rectangle.
    boolean touches(Point2D center, double radius) {
        return HelperCollisions.circleOverlapsRectangle(center, radius, bounds);
    }

    @Override
    void draw(GraphicsContext gc) {
        gc.save();
        gc.setFill(color);
        gc.fillRect(bounds.getMinX(), bounds.getMinY(), bounds.getWidth(), bounds.getHeight());
        gc.restore();
    }
}
