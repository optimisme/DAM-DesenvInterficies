package com.project;

import javafx.geometry.Point2D;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.paint.Color;

// Bala
class Bullet extends ObjectDynamic {

    // ObjectDynamic aporta posició, angle i velocitat

    static final double RADIUS = 5;

    private boolean bounced; 

    Bullet(Point2D position, double angleDegrees, double speed) {
        super(position, angleDegrees, speed);
    }

    @Override
    double getRadius() {
        return RADIUS;
    }

    // Si la bala ja ha rebotat (només pot rebotar un cop)
    boolean hasBounced() {
        return bounced;
    }

    // Rebotar la bala contra una paret:
    // - paret vertical (esquerra/dreta): s'inverteix la part horitzontal de la direcció
    // - paret horitzontal (dalt/baix): s'inverteix la part vertical
    void bounce(boolean invertX, boolean invertY) {
        Point2D direction = HelperMath.directionForAngle(angle);
        double dx = invertX ? -direction.getX() : direction.getX();
        double dy = invertY ? -direction.getY() : direction.getY();
        setAngle(HelperMath.angleForMovement(new Point2D(dx, dy)));
        bounced = true;
    }

    // Dibuixar una bala
    @Override
    void draw(GraphicsContext gc) {
        
        gc.save();
        gc.translate(position.getX(), position.getY());
        gc.rotate(angle);

        gc.setFill(Color.RED);
        gc.fillRect(-4, -2, 7, 4);
        gc.fillOval(1, -2, 4, 4);
        gc.restore();
    }
}
