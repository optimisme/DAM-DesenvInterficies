package com.client;

public class PlayGrid {

    private final double startX;
    private final double startY;
    private final double cellSize;
    private final int cols;
    private final int rows;

    public PlayGrid(double startX, double startY, double cellSize, int rows, int cols) {
        this.startX = startX;
        this.startY = startY;
        this.cellSize = cellSize;
        this.cols = cols;
        this.rows = rows;
    }

    public boolean isPositionInsideGrid(double x, double y) {
        return x >= startX && x < startX + cols * cellSize &&
               y >= startY && y < startY + rows * cellSize;
    }  

    public double getStartX() {
        return startX;
    }

    public double getStartY() {
        return startY;
    }

    public double getCellSize() {
        return cellSize;
    }

    public double getCols() {
        return cols;
    }

    public double getRows() {
        return rows;
    }

    public int getCol(double x) {
        if (x < startX || x >= startX + cols * cellSize) {
            return -1; // Fora de la graella
        }
        return (int) ((x - startX) / cellSize);
    }

    public int getRow(double y) {
        if (y < startY || y >= startY + rows * cellSize) {
            return -1; // Fora de la graella
        }
        return (int) ((y - startY) / cellSize);
    }

    public int getCellX(int col) {
        return (int) (getStartX() + col * getCellSize());
    }

    public int getCellY(int row) {
        return (int) (getStartY() + row * getCellSize());
    }
}
