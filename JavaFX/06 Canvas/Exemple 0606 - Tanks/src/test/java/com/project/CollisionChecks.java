package com.project;

import javafx.geometry.Point2D;
import javafx.geometry.Rectangle2D;

/** Comprovacions bàsiques executables sense dependències de tests ni obrir la finestra. */
public class CollisionChecks {

    public static void main(String[] args) {
        Rectangle2D wall = new Rectangle2D(100, 100, 50, 50);

        // Cercle-cercle
        check(HelperCollisions.circlesOverlap(new Point2D(0, 0), 5, new Point2D(8, 0), 5), "cercles que se solapen");
        check(!HelperCollisions.circlesOverlap(new Point2D(0, 0), 5, new Point2D(20, 0), 5), "cercles separats");

        // Cercle-rectangle: costat, cantonada i lluny
        check(HelperCollisions.circleOverlapsRectangle(new Point2D(97, 120), 5, wall), "toca el costat esquerre");
        check(HelperCollisions.circleOverlapsRectangle(new Point2D(125, 125), 5, wall), "centre dins del rectangle");
        check(!HelperCollisions.circleOverlapsRectangle(new Point2D(96, 96), 5, wall), "a prop de la cantonada sense tocar-la");
        check(!HelperCollisions.circleOverlapsRectangle(new Point2D(50, 50), 5, wall), "lluny del rectangle");

        // Rebot: contra una paret vertical, una bala que va a 45° passa a anar a 135°
        Bullet bullet = new Bullet(Point2D.ZERO, 45, 100);
        bullet.bounce(true, false);
        close(bullet.getAngle(), 135, "rebot en paret vertical");
        check(bullet.hasBounced(), "la bala recorda que ha rebotat");

        // Rebot: contra una paret horitzontal, de 45° passa a -45°
        Bullet other = new Bullet(Point2D.ZERO, 45, 100);
        other.bounce(false, true);
        close(other.getAngle(), -45, "rebot en paret horitzontal");

        // Moviment: a 100 px/s cap a la dreta, en mig segon avança 50 px
        Point2D next = new Bullet(new Point2D(10, 10), 0, 100).nextPosition(0.5);
        close(next.getX(), 60, "posició X després de moure");
        close(next.getY(), 10, "posició Y després de moure");

        System.out.println("CollisionChecks: totes les comprovacions són correctes.");
    }

    private static void check(boolean condition, String description) {
        if (!condition) throw new AssertionError(description);
    }

    private static void close(double actual, double expected, String description) {
        check(Math.abs(actual - expected) < 0.000001, description + ": " + actual + " != " + expected);
    }
}
