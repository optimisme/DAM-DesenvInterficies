package com.project;

import javafx.application.Platform;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.control.Button;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.Region;
import javafx.scene.paint.Color;
import javafx.event.ActionEvent;

import java.net.URL;
import java.util.ResourceBundle;

public class Controller implements Initializable {

    // --- FXML
    @FXML private Canvas canvas;
    @FXML private Button buttonAdd;   // opcional (ara deixa caure una fitxa en una columna aleatòria)
    @FXML private Button buttonClear; // reset

    // --- Dibuix i mida
    private GraphicsContext gc;

    // Config de la graella Connecta 4
    private static final int COLS = 7;
    private static final int ROWS = 6;

    // Mides calculades a partir del canvas
    private double margin = 20;       // marge exterior
    private double boardX, boardY;    // origen del tauler
    private double cell;              // mida de cel·la (quadrada)
    private double boardW, boardH;    // mida tauler

    // Zona clicable de capçalera (sobre el tauler)
    private double headerH;           // alçada de la franja superior clicable

    // Estat del tauler: 0 = buit, 1 = vermell (per ara només un color)
    private final int[][] board = new int[ROWS][COLS];

    // Animació de caiguda
    private boolean animating = false;
    private int animCol = -1, animRow = -1; // destí
    private double animY;                    // posició Y actual del centre de la fitxa que cau
    private double targetY;                  // posició Y final del centre de la fitxa
    private double fallSpeed = 1200;         // velocitat de caiguda (px/s). Ajusta al teu gust.

    // Timer (fa servir la teva classe)
    private CnvTimer timer;
    private long lastRunNanos = 0; // per calcular dt

    @Override
    public void initialize(URL url, ResourceBundle rb) {
        gc = canvas.getGraphicsContext2D();

        // Timer abans del primer redraw
        timer = new CnvTimer(
                fps -> update(),
                this::redraw,
                60
        );
        timer.start();

        // Enllaça mides del Canvas al BorderPane (opció B)
        bindCanvasSizeToParent();

        // Si vols un primer dibuix immediat (encara que les mides siguin petites):
        computeLayout();
        redraw();

        // Clics de columna
        canvas.addEventHandler(MouseEvent.MOUSE_CLICKED, this::handleClickOnCanvas);
    }


    // Recalcula mides en funció del canvas
    private void computeLayout() {
        double w = canvas.getWidth();
        double h = canvas.getHeight();

        // Deixem una capçalera clicable a dalt
        headerH = 0.9 * Math.min(w, h) / 12.0; // una franja raonable; la pots ajustar

        // L’àrea disponible per al tauler
        double availableW = w - 2 * margin;
        double availableH = h - 2 * margin - headerH;

        // Cel·la quadrada que càpiga 7x6
        cell = Math.min(availableW / COLS, availableH / ROWS);

        boardW = cell * COLS;
        boardH = cell * ROWS;

        // Centrem horitzontalment; verticalment deixem header a dalt
        boardX = (w - boardW) / 2.0;
        boardY = margin + headerH;
    }

    // --- Controls de la UI
    @FXML
    private void actionAdd(ActionEvent event) {
        // Opcional: deixa caure una fitxa en una columna aleatòria (si no hi ha animació en curs)
        if (animating) return;
        int col = (int) Math.floor(Math.random() * COLS);
        tryDropInColumn(col);
    }

    @FXML
    private void actionClear(ActionEvent event) {
        resetBoard();
        redraw();
    }

    private void resetBoard() {
        for (int r = 0; r < ROWS; r++) {
            for (int c = 0; c < COLS; c++) {
                board[r][c] = 0;
            }
        }
        animating = false;
        animCol = animRow = -1;
    }

    // --- Interacció amb el canvas
    private void handleClickOnCanvas(MouseEvent e) {
        if (animating) return;

        double x = e.getX();
        double y = e.getY();

        // Només acceptem click a la franja superior (header) i dins de l’ample del tauler
        if (y < boardY && x >= boardX && x < boardX + boardW) {
            int col = (int) ((x - boardX) / cell);
            tryDropInColumn(col);
        }
    }

    private void tryDropInColumn(int col) {
        // Troba la fila lliure més baixa en aquesta columna
        int row = findLowestEmptyRow(col);
        if (row < 0) return; // columna plena

        // Prepara animació: comencem per sobre del tauler
        double cellCenterYTop = boardY + cell * 0.5;
        double startY = boardY - cell * 0.5; // lleugerament per sobre
        double endY = cellCenterYTop + row * cell;

        animCol = col;
        animRow = row;
        animY = startY;
        targetY = endY;
        animating = true;
        lastRunNanos = 0; // perquè el primer dt es calculi bé
    }

    private int findLowestEmptyRow(int col) {
        for (int r = ROWS - 1; r >= 0; r--) {
            if (board[r][col] == 0) return r;
        }
        return -1;
    }

    // --- Bucle lògic (cridat per CnvTimer.runFunction)
    private void update() {
        // Calculem dt (segons) dins del controlador
        long now = System.nanoTime();
        double dt;
        if (lastRunNanos == 0) {
            dt = 0; // primer frame
        } else {
            dt = (now - lastRunNanos) / 1_000_000_000.0;
        }
        lastRunNanos = now;

        if (animating && dt > 0) {
            animY += fallSpeed * dt;
            if (animY >= targetY) {
                animY = targetY;
                animating = false;
                // Col·loca la fitxa al tauler
                if (animRow >= 0 && animCol >= 0) {
                    board[animRow][animCol] = 1; // vermell
                }
            }
        }
    }

    // --- Dibuix (cridat per CnvTimer.drawFunction)
    private void redraw() {
        // Fons
        gc.setFill(Color.rgb(245, 245, 245));
        gc.fillRect(0, 0, canvas.getWidth(), canvas.getHeight());

        // Franja superior clicable (amb marques de columna)
        drawHeader();

        // Tauler (pla blau amb "forats" suggerits)
        drawBoardBackground();

        // Fitxes existents
        drawDiscsFromBoard();

        // Fitxa en caiguda (si n’hi ha)
        if (animating) drawFallingDisc();

        // Mostrar FPS del teu CnvTimer
        if (timer != null) {
        //    timer.draw(gc);
        }
    }

    private void drawHeader() {
        // Fons header
        gc.setFill(Color.rgb(230, 230, 230));
        gc.fillRect(0, margin, canvas.getWidth(), headerH);

        // Delimita l'àrea sobre el tauler
        gc.setStroke(Color.GRAY);
        gc.strokeRect(boardX, margin, boardW, headerH);

        // Marques de columna
        gc.setStroke(Color.rgb(180, 180, 180));
        for (int c = 1; c < COLS; c++) {
            double x = boardX + c * cell;
            gc.strokeLine(x, margin, x, margin + headerH);
        }
    }

    private void drawBoardBackground() {
        // Tauler blau
        gc.setFill(Color.rgb(30, 96, 199)); // blau Connecta 4
        gc.fillRect(boardX, boardY, boardW, boardH);

        // “Forats”: dibuixem cercles clars per suggerir els sockets
        double r = cell * 0.42; // radi dels forats
        for (int rIdx = 0; rIdx < ROWS; rIdx++) {
            for (int c = 0; c < COLS; c++) {
                double cx = boardX + c * cell + cell * 0.5;
                double cy = boardY + rIdx * cell + cell * 0.5;

                gc.setFill(Color.rgb(235, 235, 235));
                gc.fillOval(cx - r, cy - r, r * 2, r * 2);
            }
        }
    }

    private void drawDiscsFromBoard() {
        double r = cell * 0.42;
        for (int rIdx = 0; rIdx < ROWS; rIdx++) {
            for (int c = 0; c < COLS; c++) {
                int v = board[rIdx][c];
                if (v == 0) continue;

                double cx = boardX + c * cell + cell * 0.5;
                double cy = boardY + rIdx * cell + cell * 0.5;

                if (v == 1) {
                    gc.setFill(Color.RED);
                } else {
                    gc.setFill(Color.BLACK); // (per si més endavant afegeixes altres colors/jugadors)
                }
                gc.fillOval(cx - r, cy - r, r * 2, r * 2);
            }
        }
    }

    private void drawFallingDisc() {
        if (animCol < 0) return;

        double r = cell * 0.42;
        double cx = boardX + animCol * cell + cell * 0.5;
        double cy = animY;

        gc.setFill(Color.RED);
        gc.fillOval(cx - r, cy - r, r * 2, r * 2);
    }

    // Lliga la mida del Canvas a l'espai disponible del pare (BorderPane center).
    private void bindCanvasSizeToParent() {
        // Quan canviï el pare, fem els binds
        canvas.parentProperty().addListener((o, oldP, newP) -> {
            if (newP instanceof Region region) {
                canvas.widthProperty().unbind();
                canvas.heightProperty().unbind();
                // Reserva ~120 px per la banda dreta (botons). Ajusta si cal.
                canvas.widthProperty().bind(region.widthProperty().subtract(120));
                canvas.heightProperty().bind(region.heightProperty());
            }
        });

        // També fem un bind “tardà” quan ja hi ha layout
        Platform.runLater(() -> {
            if (canvas.getParent() instanceof Region region) {
                canvas.widthProperty().unbind();
                canvas.heightProperty().unbind();
                canvas.widthProperty().bind(region.widthProperty().subtract(120));
                canvas.heightProperty().bind(region.heightProperty());
            }
            // Primer càlcul i repintat quan ja tenim mides > 0
            computeLayout();
            redraw();
        });

        // Recalcular quan canviïn les mides
        canvas.widthProperty().addListener((obs, ov, nv) -> { computeLayout(); redraw(); });
        canvas.heightProperty().addListener((obs, ov, nv) -> { computeLayout(); redraw(); });
    }

}
