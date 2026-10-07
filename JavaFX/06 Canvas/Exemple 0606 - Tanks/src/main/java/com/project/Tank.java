package com.project;

import javafx.geometry.Point2D;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.paint.Color;

// Un tanc
class Tank extends ObjectDynamic {

    // ObjectDynamic aporta posició, angle i velocitat

    static final double RADIUS = 25;

    private double turretAngle; // Graus del canó respecte de l'eix horitzontal
    private final Color color;
    private boolean alive;

    Tank(Point2D position, double angle, double turretAngle, Color color) {
        super(position, angle, 0);
        this.color = color;
        reset(position, angle, turretAngle);
    }

    @Override
    double getRadius() {
        return RADIUS;
    }

    Color getColor() {
        return color;
    }

    double getTurretAngle() {
        return turretAngle;
    }

    boolean isAlive() {
        return alive;
    }

    void destroy() {
        alive = false;
        setSpeed(0);
    }

    // Reiniciar el tanc
    void reset(Point2D position, double angle, double turretAngle) {
        setPosition(position);
        setAngle(angle);
        setSpeed(0);
        this.turretAngle = turretAngle;
        alive = true;
    }

    // Actualitza l'angle i la velocitat a partir de la direcció demanada.
    // El cos del tanc s'orienta cap on es mou; sense direcció, s'atura.
    void updateMovement(Point2D direction, double speed) {
        if (!alive || direction.equals(Point2D.ZERO)) {
            setSpeed(0);
            return;
        }
        setAngle(HelperMath.angleForMovement(direction));
        setSpeed(speed);
    }

    // Apuntar el canó cap a l'objectiu (target)
    void pointAt(Point2D target) {
        turretAngle = HelperMath.angleToTarget(getPosition(), target);
    }

    // Dibuixar el tanc
    @Override
    void draw(GraphicsContext gc) {

        if (!alive) return;

        // Dibuixar el cos del tanc
        gc.save();
        gc.translate(position.getX(), position.getY());
        gc.rotate(angle);
        gc.setFill(Color.DARKSLATEGRAY);
        gc.fillRect(-18, -17, 36, 6);
        gc.fillRect(-18, 11, 36, 6);
        gc.setFill(color);
        gc.fillRect(-16, -11, 32, 22);
        gc.restore();

        // Dibuixar el canó
        gc.save();
        gc.translate(position.getX(), position.getY());
        gc.rotate(turretAngle);
        gc.setFill(color.darker());
        gc.fillRect(0, -3, 32, 6);
        gc.fillOval(-9, -9, 18, 18);
        gc.restore();
    }
}
