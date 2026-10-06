package com.project;

import javafx.geometry.Point2D;
import javafx.scene.canvas.GraphicsContext;

// Base dels objectes del joc que poden participar en col·lisions.
abstract class ObjectBase {

    abstract Point2D getPosition();

    // Cada objecte decideix com es dibuixa.
    abstract void draw(GraphicsContext gc);
}
