package com.project;

import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.paint.Color;
import javafx.scene.shape.StrokeLineCap;
import javafx.scene.text.Font;
import javafx.scene.text.FontWeight;
import javafx.scene.text.TextAlignment;

public class CnvObjNumeros implements CnvObj {

    @Override
    public void run(CnvController ctrl) {
        // Update object attributes if any
    }

    @Override
    public void draw(CnvController ctrl) {

        GraphicsContext gc = ctrl.gc;

        gc.save(); // Guardar el context de gràfics

        int canvasHeight = (int) gc.getCanvas().getHeight();
        int canvasWidth = (int) gc.getCanvas().getWidth();
        int diameter = Math.min(canvasWidth, canvasHeight) - 25;
        int x = canvasWidth / 2;
        int y = canvasHeight / 2;
        int radius = diameter / 2;
        double sub = Math.PI / 2;
        double radians;

        // Segons (i subdivisions)
        for (int cnt = 0; cnt < 240; cnt++) {
            radians = Math.toRadians(cnt * 1.5) - sub;
            Color color = Color.GREY;
            int radiusMin = 5;
            double size = 1;

            if (cnt % 4 == 0) {
                radiusMin = 10;
                size = 1.5;
            }
            if (cnt % 20 == 0) {
                color = Color.WHITE;
                radiusMin = 10;
                size = 2;
            }
            drawCircleLine(gc, color, size, x, y, radius - radiusMin, radius, radians);
        }

        // Hores numèriques
        int radiusMin = radius - 25;
        gc.setFill(Color.WHITE);
        gc.setFont(Font.font("Arial", FontWeight.BOLD, 20));
        gc.setTextAlign(TextAlignment.CENTER);

        for (int cnt = 1; cnt <= 12; cnt++) {
            radians = Math.toRadians(cnt * 30) - sub;
            int numX = x + (int) (radiusMin * Math.cos(radians));
            int numY = y + (int) (radiusMin * Math.sin(radians)) + 8;
            gc.fillText(String.valueOf(cnt), numX, numY);
        }

        gc.restore(); // Restaurar el context de gràfics
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
