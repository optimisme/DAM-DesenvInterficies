package com.project;

import java.net.URL;
import java.util.Calendar;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.ResourceBundle;

import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;

public class CnvController {

    public double hores = 0;
    public double minuts = 0;
    public double segons = 0;
    public double millis = 0;

    public ArrayList<CnvObj> objects = new ArrayList<>(Arrays.asList(
        new CnvObjNumeros(),
        new CnvObjAgulles(),
        new CnvObjWatch()
    ));

    public Canvas canvas;
    public GraphicsContext gc;
    public CnvTimer animationTimer;
    public boolean showFps = true; 

    public CnvController(Canvas canvas) {

        this.canvas = canvas;
        this.gc = canvas.getGraphicsContext2D();

        animationTimer = new CnvTimer(this::run, this::draw, 0);
        start();
    }

    // Start animation timer
    public void start() {
        animationTimer.start();
    }

    // Stop animation timer
    public void stop() {
        animationTimer.stop();
    }

    // Run game (and animations)
    private void run(double fps) {

        if (animationTimer.fps < 1) { return; }

        // Compute global attributes
        Calendar cal = Calendar.getInstance();
        this.hores = cal.get(Calendar.HOUR_OF_DAY);
        this.minuts = cal.get(Calendar.MINUTE);
        this.segons = cal.get(Calendar.SECOND);
        this.millis = cal.get(Calendar.MILLISECOND);

        // Run per object logic
        for (CnvObj obj : objects) { obj.run(this); }
    }

    public void draw() {

        // Clean drawing area
        gc.clearRect(0, 0, canvas.getWidth(), canvas.getHeight());

        // Draw objects
        for (CnvObj obj : objects) { obj.draw(this); }

        // Draw FPS if needed
        if (showFps) { animationTimer.draw(gc); }   
    }
}