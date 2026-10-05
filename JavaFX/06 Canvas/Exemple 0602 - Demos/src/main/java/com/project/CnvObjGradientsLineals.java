package com.project;

import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.paint.Color;
import javafx.scene.paint.CycleMethod;
import javafx.scene.paint.LinearGradient;
import javafx.scene.paint.Stop;

public class CnvObjGradientsLineals implements CnvObj {

    @Override
    public void run(CnvController ctrl) {
        // Update object attributes if any
    }

    @Override
    public void draw(CnvController ctrl) {
        
        GraphicsContext gc = ctrl.gc;

        // 0
        Stop[] stops1 = new Stop[] { 
            new Stop(0.2, Color.ORANGE), 
            new Stop(0.5, Color.GREEN), 
            new Stop(0.8, Color.BLUE)};
        LinearGradient lg1 = new LinearGradient(0, 0, 1, 0, true, CycleMethod.NO_CYCLE, stops1);
        // x1, y1, x2, y2, proportional, cycleMethod, stops

        gc.setFill(lg1);
        gc.fillRect(50, 40, 80, 50);
    
        String codi = """
            Stop[] stops1 = new Stop[] { 
                new Stop(0.2, Color.ORANGE), new Stop(0.5, Color.GREEN), new Stop(0.8, Color.BLUE)};
            
            LinearGradient lg1 = new LinearGradient(0, 0, 1, 0, true, CycleMethod.NO_CYCLE, stops1);
            // x1, y1, x2, y2, proportional, cycleMethod, stops
    
            gc.setFill(lg1);
            gc.fillRect(50, 40, 80, 50);
        """;
        ctrl.drawText(codi, 125, 50);

        // 1
        Stop[] stops2 = new Stop[] { 
            new Stop(0, Color.RED), 
            new Stop(0.25, Color.ORANGE), 
            new Stop(0.8, Color.PURPLE)};
        LinearGradient lg2 = new LinearGradient(0, 0, 1, 1, true, CycleMethod.NO_CYCLE, stops2);
        // x1, y1, x2, y2, proportional, cycleMethod, stops

        gc.setFill(lg2);
        gc.fillRect(50, 210, 80, 50);
    
        codi = """
            Stop[] stops2 = new Stop[] { 
                new Stop(0, Color.ORANGE), new Stop(0.25, Color.GREEN), new Stop(0.8, Color.BLUE)};
            
            LinearGradient lg2 = new LinearGradient(0, 0, 1, 1, true, CycleMethod.NO_CYCLE, stops2);
            // x1, y1, x2, y2, proportional, cycleMethod, stops
    
            gc.setFill(lg1);
            gc.fillRect(50, 210, 80, 50);
        """;
        ctrl.drawText(codi, 125, 220);

        // 2
        Stop[] stops3 = new Stop[] { 
            new Stop(0.2, Color.BLUE), 
            new Stop(0.7, Color.GRAY), 
            new Stop(1, Color.PURPLE)};
        LinearGradient lg3 = new LinearGradient(0, 0, 0, 1, true, CycleMethod.NO_CYCLE, stops3);
        // x1, y1, x2, y2, proportional, cycleMethod, stops

        gc.setFill(lg3);
        gc.fillRect(50, 380, 80, 50);
    
        codi = """
            Stop[] stops3 = new Stop[] { 
                new Stop(0.2, Color.BLUE), new Stop(0.7, Color.NAVY), new Stop(1, Color.PURPLE)};
            
            LinearGradient lg3 = new LinearGradient(0, 0, 0, 1, true, CycleMethod.NO_CYCLE, stops3);
            // x1, y1, x2, y2, proportional, cycleMethod, stops
    
            gc.setFill(lg3);
            gc.fillRect(50, 380, 80, 50);
        """;
        ctrl.drawText(codi, 125, 390);
    }
}