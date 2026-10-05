package com.project;

import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.paint.Color;
import javafx.scene.shape.StrokeLineCap;

public class CnvObjAgulles implements CnvObj {

    @Override
    public void run(CnvController ctrl) {
        // Update object attributes if any
    }

    @Override
    public void draw(CnvController ctrl) {

        GraphicsContext gc = ctrl.gc;

        int canvasHeight = (int) gc.getCanvas().getHeight();
        int canvasWidth = (int) gc.getCanvas().getWidth();
        int diameter = Math.min(canvasWidth, canvasHeight) - 25;
        int x = canvasWidth / 2;
        int y = canvasHeight / 2;
        int radius = diameter / 2;
        int radiusHalf = radius / 2;
        double sub = Math.PI / 2;
        double radians;

        // Dibuixar les hores
        radians = Math.toRadians((ctrl.hores + ctrl.minuts / 60) * 30) - sub;
        drawCircleLine(gc, Color.WHITE, 3, x, y, 0, 25, radians);
        drawCircleLine(gc, Color.WHITE, 8, x, y, 20, radiusHalf, radians);

        // Dibuixar els minuts
        radians = Math.toRadians((ctrl.minuts + ctrl.segons / 60) * 6) - sub;
        drawCircleLine(gc, Color.WHITE, 3, x, y, 0, 25, radians);
        drawCircleLine(gc, Color.WHITE, 8, x, y, 20, radius - 25, radians);

        // Dibuixar els segons
        radians = Math.toRadians(ctrl.segons * 6) + Math.toRadians(ctrl.millis * 0.006) - sub;
        drawCircleLine(gc, Color.RED, 2, x, y, -20, radius, radians);

        // Dibuixar el cercle dels segons
        int radiusCS = 6;
        gc.setFill(Color.RED);
        gc.fillOval(x - radiusCS, y - radiusCS, radiusCS * 2, radiusCS * 2);

        // Dibuixar el centre
        int radiusCT = 3;
        gc.setFill(Color.BLACK);
        gc.fillOval(x - radiusCT, y - radiusCT, radiusCT * 2, radiusCT * 2);
    }

    private void drawCircleLine(GraphicsContext gc, Color color, double size, int x, int y, int radiusMin,
                                int radiusMax, double radians) {
        gc.setStroke(color);
        gc.setLineWidth(size);
        gc.setLineCap(StrokeLineCap.ROUND);
        gc.beginPath();
        gc.moveTo(x + radiusMin * Math.cos(radians), y + radiusMin * Math.sin(radians));
        gc.lineTo(x + radiusMax * Math.cos(radians), y + radiusMax * Math.sin(radians));
        gc.stroke();
        gc.setLineCap(StrokeLineCap.SQUARE);
    }
}
