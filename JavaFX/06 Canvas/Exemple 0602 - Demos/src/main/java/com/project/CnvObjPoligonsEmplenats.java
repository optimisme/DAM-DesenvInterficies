package com.project;

import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.paint.Color;
import javafx.scene.shape.StrokeLineCap;

public class CnvObjPoligonsEmplenats implements CnvObj {

    @Override
    public void run(CnvController ctrl) {
        // Update object attributes if any
    }

    @Override
    public void draw(CnvController ctrl) {

        GraphicsContext gc = ctrl.gc;

        // 0
        gc.setStroke(Color.ORANGE);
        gc.setFill(Color.GREEN);
        gc.setLineWidth(8);
        gc.setLineCap(StrokeLineCap.ROUND);

        gc.beginPath();
        gc.moveTo(50, 60);
        gc.lineTo(100, 75);
        gc.lineTo(75, 100);
        gc.lineTo(50, 75);
        gc.fill();
        gc.stroke();
       
        String codi = """
            gc.setStroke(Color.ORANGE);
            gc.setFill(Color.GREEN);
            gc.setLineWidth(8);
            gc.setLineCap(StrokeLineCap.ROUND);
    
            gc.beginPath();
            gc.moveTo(50, 60);
            gc.lineTo(100, 75);
            gc.lineTo(75, 100);
            gc.lineTo(50, 75);
            gc.fill();
            gc.stroke();
            // El relleu (stroke) queda per sobre de l'emplenat (fill)
        """;
        ctrl.drawText(codi, 100, 50);

        // 1
        gc.setStroke(Color.GREEN);
        gc.setFill(Color.ORANGE);
        gc.setLineWidth(8);
        gc.setLineCap(StrokeLineCap.ROUND);

        gc.beginPath();
        gc.moveTo(50, 260);
        gc.lineTo(100, 275);
        gc.lineTo(100, 300);
        gc.lineTo(50, 275);
        gc.stroke();
        gc.fill();
       
        codi = """
            gc.setStroke(Color.GREEN);
            gc.setFill(Color.ORANGE);
            gc.setLineWidth(8);
            gc.setLineCap(StrokeLineCap.ROUND);
    
            gc.beginPath();
            gc.moveTo(50, 260);
            gc.lineTo(100, 275);
            gc.lineTo(100, 300);
            gc.lineTo(50, 275);
            gc.stroke();
            gc.fill();
            // L'emplenat (fill) queda per sobre del relleu (stroke)
        """;
        ctrl.drawText(codi, 100, 275);

        // 2
        gc.setFill(Color.RED);

        gc.beginPath();
        gc.moveTo(400, 60);
        gc.lineTo(440, 70);
        gc.lineTo(420, 100);
        gc.lineTo(410, 90);
        gc.fill();


       
        codi = """
            gc.setFill(Color.RED);

            gc.beginPath();
            gc.moveTo(400, 60);
            gc.lineTo(440, 70);
            gc.lineTo(420, 100);
            gc.lineTo(410, 90);
            gc.fill();
        """;
        ctrl.drawText(codi, 450, 50);

        // 3
        gc.setFill(Color.RED);
        gc.beginPath();
        gc.moveTo(400, 250);
        gc.lineTo(440, 290);
        gc.lineTo(390, 280);
        gc.fill();

        gc.setFill(new Color(0.5, 1, 0.5, 0.5));
        // Red, Green, Blue, Opacity (alpha)
        gc.beginPath();
        gc.moveTo(400, 260);
        gc.lineTo(440, 300);
        gc.lineTo(390, 290);
        gc.fill();
       
        codi = """
            gc.setFill(Color.RED);
            gc.beginPath();
            gc.moveTo(400, 250);
            gc.lineTo(440, 290);
            gc.lineTo(390, 280);
            gc.fill();
            gc.setFill(new Color(0.5, 1, 0.5, 0.5));
            // Red, Green, Blue, Opacity (alpha)

            gc.beginPath();
            gc.moveTo(400, 260);
            gc.lineTo(440, 300);
            gc.lineTo(390, 290);
            gc.fill();
            // El 'fill' queda per sota del relleu
        """;
        ctrl.drawText(codi, 450, 275);
    }
}