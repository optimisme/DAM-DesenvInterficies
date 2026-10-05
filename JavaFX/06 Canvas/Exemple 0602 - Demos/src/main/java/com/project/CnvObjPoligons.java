package com.project;

import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.paint.Color;
import javafx.scene.shape.StrokeLineCap;
import javafx.scene.shape.StrokeLineJoin;

public class CnvObjPoligons implements CnvObj {

    @Override
    public void run(CnvController ctrl) {
        // Update object attributes if any
    }

    @Override
    public void draw(CnvController ctrl) {

        GraphicsContext gc = ctrl.gc;

        // 0
        gc.setStroke(Color.BLUE);
        gc.setLineWidth(2);
        gc.setLineCap(StrokeLineCap.ROUND);
        gc.setLineJoin(StrokeLineJoin.ROUND);

        gc.beginPath();
        gc.moveTo(50, 60);
        gc.lineTo(100, 75);
        gc.lineTo(50, 100);
        gc.stroke();
       
        String codi = """
            gc.setStroke(Color.BLUE);
            gc.setLineWidth(2);
            gc.setLineCap(StrokeLineCap.ROUND);
            gc.setLineJoin(StrokeLineJoin.ROUND);
    
            gc.beginPath();
            gc.moveTo(50, 60);
            gc.lineTo(100, 75);
            gc.lineTo(50, 100);
            gc.stroke();
        """;
        ctrl.drawText(codi, 125, 50);

        // 1
        gc.setStroke(Color.GREEN);
        gc.setLineWidth(2);
        gc.setLineCap(StrokeLineCap.ROUND);

        gc.beginPath();
        gc.moveTo(50, 260);
        gc.lineTo(100, 275);
        gc.lineTo(125, 300);
        gc.moveTo(75, 300);
        gc.lineTo(100, 325);
        gc.stroke();
       
        codi = """
            gc.setStroke(Color.GREEN);
            gc.setLineWidth(2);
            gc.setLineCap(StrokeLineCap.ROUND); 

            gc.beginPath();
            gc.moveTo(50, 260);
            gc.lineTo(100, 275);
            gc.lineTo(125, 300);
            gc.moveTo(75, 300);
            gc.lineTo(100, 325);
            gc.stroke();
        """;
        ctrl.drawText(codi, 125, 260);

        // 2
        gc.setStroke(Color.RED);
        gc.setLineWidth(10);
        gc.setLineCap(StrokeLineCap.SQUARE);
        gc.setLineJoin(StrokeLineJoin.ROUND);

        gc.beginPath();
        gc.moveTo(400, 50);
        gc.lineTo(430, 80);
        gc.lineTo(400, 110);
        gc.stroke();
       
        codi = """
            gc.setStroke(Color.RED);
            gc.setLineWidth(10);
            gc.setLineCap(StrokeLineCap.SQUARE);
            gc.setLineJoin(StrokeLineJoin.ROUND);
            // Limits quadrades, juntes arrodonides
    
            gc.beginPath();
            gc.moveTo(400, 50);
            gc.lineTo(430, 80);
            gc.lineTo(400, 110);
            gc.stroke();
        """;
        ctrl.drawText(codi, 450, 50);

        // 3
        gc.setStroke(Color.PURPLE);
        gc.setLineWidth(10);
        gc.setLineCap(StrokeLineCap.ROUND);
        gc.setLineJoin(StrokeLineJoin.MITER);

        gc.beginPath();
        gc.moveTo(400, 250);
        gc.lineTo(430, 280);
        gc.lineTo(400, 310);
        gc.stroke();
       
        codi = """
            gc.setStroke(Color.PURPLE);
            gc.setLineWidth(10);
            gc.setLineCap(StrokeLineCap.ROUND);
            gc.setLineJoin(StrokeLineJoin.MITER);
            // Limits arrodonits, juntes angulars
    
            gc.beginPath();
            gc.moveTo(400, 250);
            gc.lineTo(430, 280);
            gc.lineTo(400, 310);
            gc.stroke();
        """;
        ctrl.drawText(codi, 450, 260);
    }
}
