package com.project;

import javafx.geometry.Point2D;

// Objecte comú per tancs i bales,
// definint posició, direcció i velocitat
abstract class ObjectDynamic extends ObjectBase {

    // Posició de l'objecte al canvas 
    // (centre del tanc, centre de la bala, ...)
    protected Point2D position;

    protected double angle; // Cap on es mou i apunta l'objecte, en graus

    protected double speed; // Velocitat en píxels per segon; 0 significa aturat

    ObjectDynamic(Point2D position, double angle, double speed) {
        this.position = position;
        this.angle = angle;
        this.speed = speed;
    }

    @Override
    Point2D getPosition() {
        return position;
    }

    void setPosition(Point2D position) {
        this.position = position;
    }

    // Tancs i bales es comparen com a cercles
    abstract double getRadius();

    // Indica si aquest objecte toca un altre objecte dinàmic.
    boolean touches(ObjectDynamic other) {
        return HelperCollisions.circlesOverlap(position, getRadius(), other.getPosition(), other.getRadius());
    }

    double getAngle() {
        return angle;
    }

    void setAngle(double angle) {
        this.angle = angle;
    }

    double getSpeed() {
        return speed;
    }

    void setSpeed(double speed) {
        this.speed = speed;
    }

    // Calcula on serà l'objecte després de dt segons, sense moure'l encara.
    // La distància recorreguda és la velocitat multiplicada pel temps.
    Point2D nextPosition(double dt) {
        return HelperMath.positionAtDistance(position, angle, speed * dt);
    }
}
