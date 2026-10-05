package com.project;

import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;

interface CnvObj {
    void run(CnvController ctrl);
    void draw(CnvController ctrl);
}
