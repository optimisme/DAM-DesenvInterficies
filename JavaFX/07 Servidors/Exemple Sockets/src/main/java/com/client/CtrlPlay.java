package com.client;

import java.net.URL;
import java.util.ResourceBundle;

import org.json.JSONObject;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.input.MouseEvent;
import javafx.scene.paint.Color;

import com.shared.ClientData;
import com.shared.GameObject;

public class CtrlPlay implements Initializable {

    @FXML
    public javafx.scene.control.Label title;

    @FXML
    private Canvas canvas;
    private GraphicsContext gc;
    private Boolean showFPS = false;

    private PlayTimer animationTimer;
    private PlayGrid grid;

    private Boolean mouseDragging = false;
    private double mouseOffsetX, mouseOffsetY;

    private GameObject selectedObject = null;

    @Override
    public void initialize(URL url, ResourceBundle rb) {

        // Get drawing context
        this.gc = canvas.getGraphicsContext2D();

        // Set listeners
        UtilsViews.parentContainer.heightProperty().addListener((observable, oldValue, newvalue) -> { onSizeChanged(); });
        UtilsViews.parentContainer.widthProperty().addListener((observable, oldValue, newvalue) -> { onSizeChanged(); });
        
        canvas.setOnMouseMoved(this::setOnMouseMoved);
        canvas.setOnMousePressed(this::onMousePressed);
        canvas.setOnMouseDragged(this::onMouseDragged);
        canvas.setOnMouseReleased(this::onMouseReleased);

        // Define grid
        grid = new PlayGrid(25, 25, 25, 10, 10);

        // Start run/draw timer bucle
        animationTimer = new PlayTimer(this::run, this::draw, 0);
        start();
    }

    // When window changes its size
    public void onSizeChanged() {

        double width = UtilsViews.parentContainer.getWidth();
        double height = UtilsViews.parentContainer.getHeight();
        canvas.setWidth(width);
        canvas.setHeight(height);
    }

    // Start animation timer
    public void start() {
        animationTimer.start();
    }

    // Stop animation timer
    public void stop() {
        animationTimer.stop();
    }

    private void setOnMouseMoved(MouseEvent event) {
        double mouseX = event.getX();
        double mouseY = event.getY();

        String color = Main.clients.stream()
            .filter(c -> c.name.equals(Main.clientName))
            .map(c -> c.color)
            .findFirst()
            .orElse("gray");

        ClientData cd = new ClientData(
            Main.clientName, 
            color,
            (int)mouseX, 
            (int)mouseY,  
            grid.isPositionInsideGrid(mouseX, mouseY) ? grid.getRow(mouseY) : -1,
            grid.isPositionInsideGrid(mouseX, mouseY) ? grid.getCol(mouseX) : -1
        );

        JSONObject msg = new JSONObject();
        msg.put("type", "clientMouseMoving");
        msg.put("value", cd.toJSON());

        if (Main.wsClient != null) {
            Main.wsClient.safeSend(msg.toString());
        }
    }

    private void onMousePressed(MouseEvent event) {

        double mouseX = event.getX();
        double mouseY = event.getY();

        selectedObject = null;
        mouseDragging = false;

        for (GameObject go : Main.objects) {
            if (isPositionInsideObject(mouseX, mouseY, go.x, go.y, go.col, go.row)) {
                selectedObject = new GameObject(go.id, go.x, go.y, go.col, go.row);
                mouseDragging = true;
                mouseOffsetX = event.getX() - go.x;
                mouseOffsetY = event.getY() - go.y;
                break;
            }
        }
    }

    private void onMouseDragged(MouseEvent event) {
        if (mouseDragging) {
            double objX = event.getX() - mouseOffsetX;
            double objY = event.getY() - mouseOffsetY;

            selectedObject = new GameObject(selectedObject.id, (int)objX, (int)objY, (int)selectedObject.col, (int)selectedObject.row);

            JSONObject msg = new JSONObject();
            msg.put("type", "clientObjectMoving");
            msg.put("value", selectedObject.toJSON());

            if (Main.wsClient != null) {
                Main.wsClient.safeSend(msg.toString());
            }
        }
        setOnMouseMoved(event);
    }

    private void onMouseReleased(MouseEvent event) {
        if (selectedObject != null) {
            double objX = event.getX() - mouseOffsetX; // left tip X
            double objY = event.getY() - mouseOffsetY; // left tip Y

            // build object with dragged position (size stays in col/row)
            selectedObject = new GameObject(
                selectedObject.id,
                (int) objX,
                (int) objY,
                selectedObject.col,
                selectedObject.row
            );

            // snap by left-top corner to underlying cell
            if (grid.isPositionInsideGrid(objX, objY)) {
                snapObjectLeftTop(selectedObject);
            }

            JSONObject msg = new JSONObject();
            msg.put("type", "clientObjectMoving");
            msg.put("value", selectedObject.toJSON());
            if (Main.wsClient != null) Main.wsClient.safeSend(msg.toString());

            mouseDragging = false;
            selectedObject = null;
        }
    }

    // Snap piece so its left-top corner sits exactly on the grid cell under its left tip.
    private void snapObjectLeftTop(GameObject obj) {
        int col = grid.getCol(obj.x); // left X -> column
        int row = grid.getRow(obj.y); // top Y  -> row

        // clamp inside grid
        col = (int) Math.max(0, Math.min(col, grid.getCols() - 1));
        row = (int) Math.max(0, Math.min(row, grid.getRows() - 1));

        obj.x = grid.getCellX(col);
        obj.y = grid.getCellY(row);
    }

    public Boolean isPositionInsideObject(double positionX, double positionY, int objX, int objY, int cols, int rows) {
        double cellSize = grid.getCellSize();
        double objectWidth = cols * cellSize;
        double objectHeight = rows * cellSize;

        double objectLeftX = objX;
        double objectRightX = objX + objectWidth;
        double objectTopY = objY;
        double objectBottomY = objY + objectHeight;

        return positionX >= objectLeftX && positionX < objectRightX &&
               positionY >= objectTopY && positionY < objectBottomY;
    }

    // Run game (and animations)
    private void run(double fps) {

        if (animationTimer.fps < 1) { return; }

        // Update objects and animations here
    }

    // Draw game to canvas
    public void draw() {

        if (Main.clients == null) { return; }

        // Clean drawing area
        gc.clearRect(0, 0, canvas.getWidth(), canvas.getHeight());

        // Draw colored 'over' cells
        for (ClientData clientData : Main.clients) {
            // Comprovar si està dins dels límits de la graella
            if (clientData.row >= 0 && clientData.col >= 0) {
                Color base = getColor(clientData.color);
                Color alpha = new Color(base.getRed(), base.getGreen(), base.getBlue(), 0.5);
                gc.setFill(alpha); 
                gc.fillRect(grid.getCellX(clientData.col), grid.getCellY(clientData.row), grid.getCellSize(), grid.getCellSize());
            }
        }

        // Draw grid
        drawGrid();

        // Draw mouse circles
        for (ClientData clientData : Main.clients) {
            gc.setFill(getColor(clientData.color)); 
            gc.fillOval(clientData.mouseX - 5, clientData.mouseY - 5, 10, 10);
        }

        // Draw objects
        for (GameObject go : Main.objects) {
            if (selectedObject != null && go.id.equals(selectedObject.id)) {
                drawObject(selectedObject);
            } else {
                drawObject(go);
            }
        }

        // Draw FPS if needed
        if (showFPS) { animationTimer.drawFPS(gc); }   
    }

    public void drawGrid() {
        gc.setStroke(Color.BLACK);

        for (int row = 0; row < grid.getRows(); row++) {
            for (int col = 0; col < grid.getCols(); col++) {
                double cellSize = grid.getCellSize();
                double x = grid.getStartX() + col * cellSize;
                double y = grid.getStartY() + row * cellSize;
                gc.strokeRect(x, y, cellSize, cellSize);
            }
        }
    }

    public void drawObject(GameObject obj) {
        double cellSize = grid.getCellSize();

        int x = obj.x;
        int y = obj.y;
        double width = obj.col * cellSize;
        double height = obj.row * cellSize;

        // Seleccionar un color basat en l'objectId
        Color color = Color.GRAY;

        // Dibuixar el rectangle
        gc.setFill(color);
        gc.fillRect(x, y, width, height);

        // Dibuixar el contorn
        gc.setStroke(Color.BLACK);
        gc.strokeRect(x, y, width, height);

        // Opcionalment, afegir text (per exemple, l'objectId)
        gc.setFill(Color.BLACK);
        gc.fillText(obj.id, x + 5, y + 15);
    }

    public Color getColor(String colorName) {
        switch (colorName.toLowerCase()) {
            case "red":
                return Color.RED;
            case "blue":
                return Color.BLUE;
            case "green":
                return Color.GREEN;
            case "yellow":
                return Color.YELLOW;
            case "orange":
                return Color.ORANGE;
            case "purple":
                return Color.PURPLE;
            case "pink":
                return Color.PINK;
            case "brown":
                return Color.BROWN;
            case "gray":
                return Color.GRAY;
            case "black":
                return Color.BLACK;
            default:
                return Color.LIGHTGRAY; // Default color
        }
    }
}
