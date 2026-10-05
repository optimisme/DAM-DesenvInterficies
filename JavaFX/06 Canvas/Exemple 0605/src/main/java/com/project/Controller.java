package com.project;

import java.net.URL;
import java.util.ArrayList;
import java.util.Collections;
import java.util.EnumSet;
import java.util.Iterator;
import java.util.List;
import java.util.ResourceBundle;
import java.util.Set;

import javafx.application.Platform;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.geometry.Rectangle2D;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.input.KeyCode;
import javafx.scene.input.MouseButton;
import javafx.scene.input.MouseEvent;
import javafx.scene.paint.Color;

public class Controller implements Initializable {

    @FXML private Canvas canvas;
    private GraphicsContext gc;
    private CnvTimer timer;
    private long lastRunNanos;

    // Mides fixes per treballar directament amb les coordenades del Canvas.
    private static final double WALL = 20;
    private static final double TANK_RADIUS = 25;
    private static final double TANK_SPEED = 140; // píxels/segon
    private static final double BULLET_RADIUS = 5;
    private static final double BULLET_SPEED = 360;
    private static final int MAX_BULLETS = 4;
    private static final double EXPLOSION_DURATION = 0.6; // segons

    // Escollim dos obstacles d'aquesta llista; les posicions no se solapen.
    private final List<Rectangle2D> obstacleOptions = List.of(
        new Rectangle2D(260, 100, 60, 100),
        new Rectangle2D(260, 300, 60, 100),
        new Rectangle2D(370, 170, 60, 160),
        new Rectangle2D(480, 100, 60, 100),
        new Rectangle2D(480, 300, 60, 100)
    );
    private final List<Rectangle2D> obstacles = new ArrayList<>();
    private final List<Bullet> bullets = new ArrayList<>();
    private final List<Explosion> explosions = new ArrayList<>();
    private final Set<KeyCode> keys = EnumSet.noneOf(KeyCode.class);

    // La posició és el centre del tanc. El cos i la torreta tenen angles diferents.
    private double tankX, tankY, bodyAngle;
    private double mouseX, mouseY;
    private final double enemyX = 710, enemyY = 250;
    private boolean tankAlive, enemyAlive;

    // Cada bala conserva la seva direcció encara que després moguem el ratolí.
    private static class Bullet {
        double x, y, vx, vy;
        boolean bounced;

        Bullet(double x, double y, double angle) {
            this.x = x;
            this.y = y;
            vx = Math.cos(angle) * BULLET_SPEED;
            vy = Math.sin(angle) * BULLET_SPEED;
        }
    }

    // El mateix efecte serveix per als impactes petits i per destruir el tanc.
    private static class Explosion {
        double x, y, radius;
        double time = EXPLOSION_DURATION;

        Explosion(double x, double y, double radius) {
            this.x = x;
            this.y = y;
            this.radius = radius;
        }
    }

    @Override
    public void initialize(URL url, ResourceBundle rb) {
        gc = canvas.getGraphicsContext2D();
        resetBoard();

        canvas.setOnMouseMoved(this::aim);
        canvas.setOnMouseDragged(this::aim);
        canvas.setOnMousePressed(event -> {
            aim(event);
            if (event.getButton() == MouseButton.PRIMARY) fire();
        });

        // L'escena i la finestra ja existeixen quan s'executa aquest bloc.
        Platform.runLater(() -> {
            canvas.getScene().setOnKeyPressed(event -> {
                if (event.getCode() == KeyCode.R) resetBoard();
                else keys.add(event.getCode());
            });
            canvas.getScene().setOnKeyReleased(event -> keys.remove(event.getCode()));
            canvas.getScene().getWindow().focusedProperty().addListener((obs, old, focused) -> {
                if (!focused) keys.clear();
            });
        });

        timer = new CnvTimer(fps -> update(), this::redraw, 60);
        timer.start();
        redraw();
    }

    private void resetBoard() {
        tankX = 90;
        tankY = 250;
        bodyAngle = 0;
        mouseX = enemyX;
        mouseY = enemyY;
        tankAlive = true;
        enemyAlive = true;
        lastRunNanos = 0;
        bullets.clear();
        explosions.clear();
        keys.clear();

        List<Rectangle2D> options = new ArrayList<>(obstacleOptions);
        Collections.shuffle(options);
        obstacles.clear();
        obstacles.addAll(options.subList(0, 2));
    }

    private void aim(MouseEvent event) {
        mouseX = event.getX();
        mouseY = event.getY();
    }

    private double turretAngle() {
        return Math.atan2(mouseY - tankY, mouseX - tankX);
    }

    private void fire() {
        if (!tankAlive || bullets.size() >= MAX_BULLETS) return;
        // Neix al centre per no saltar una paret que toqui la boca del canó.
        // El dibuix del tanc la tapa fins que surt; només ens pot tocar després de rebotar.
        bullets.add(new Bullet(tankX, tankY, turretAngle()));
    }

    // --- Lògica: el temps transcorregut fa que la velocitat no depengui dels FPS.
    private void update() {
        long now = System.nanoTime();
        double dt = lastRunNanos == 0 ? 0 : (now - lastRunNanos) / 1_000_000_000.0;
        lastRunNanos = now;
        dt = Math.min(dt, 0.05); // evita salts grans després d'una pausa
        if (dt <= 0) return;

        double dx = 0, dy = 0;
        if (keys.contains(KeyCode.LEFT)) dx -= 1;
        if (keys.contains(KeyCode.RIGHT)) dx += 1;
        if (keys.contains(KeyCode.UP)) dy -= 1;
        if (keys.contains(KeyCode.DOWN)) dy += 1;
        double length = Math.hypot(dx, dy);
        if (tankAlive && length > 0) {
            bodyAngle = Math.atan2(dy, dx);
            // Normalitzem perquè el moviment diagonal tingui la mateixa velocitat.
            double nextX = tankX + dx / length * TANK_SPEED * dt;
            double nextY = tankY + dy / length * TANK_SPEED * dt;
            // Comprovem cada eix per poder lliscar al costat d'un obstacle.
            if (canMove(nextX, tankY)) tankX = nextX;
            if (canMove(tankX, nextY)) tankY = nextY;
        }

        for (Explosion explosion : explosions) explosion.time -= dt;
        explosions.removeIf(explosion -> explosion.time <= 0);
        updateBullets(dt);
    }

    private boolean canMove(double x, double y) {
        if (blocked(x, y, TANK_RADIUS)) return false;
        return !enemyAlive || Math.hypot(x - enemyX, y - enemyY) >= TANK_RADIUS * 2;
    }

    private void updateBullets(double dt) {
        // Passos petits perquè una bala ràpida no salti per sobre d'un obstacle.
        int steps = (int) Math.ceil(BULLET_SPEED * dt / BULLET_RADIUS);
        double stepTime = dt / steps;
        Iterator<Bullet> iterator = bullets.iterator();
        while (iterator.hasNext()) {
            Bullet bullet = iterator.next();
            boolean remove = false;
            for (int i = 0; i < steps; i++) {
                double nextX = bullet.x + bullet.vx * stepTime;
                double nextY = bullet.y + bullet.vy * stepTime;
                boolean hitX = blocked(nextX, bullet.y, BULLET_RADIUS);
                boolean hitY = blocked(bullet.x, nextY, BULLET_RADIUS);
                // Una cantonada pot bloquejar només el moviment combinat dels dos eixos.
                if (!hitX && !hitY && blocked(nextX, nextY, BULLET_RADIUS)) {
                    hitX = hitY = true;
                }
                if (hitX || hitY) {
                    if (bullet.bounced) {
                        explosions.add(new Explosion(nextX, nextY, 20));
                        remove = true;
                        break;
                    }
                    // Paret vertical: invertim X. Paret horitzontal: invertim Y.
                    // L'altra component es conserva, així l'angle de rebot és el correcte.
                    if (hitX) bullet.vx = -bullet.vx;
                    if (hitY) bullet.vy = -bullet.vy;
                    bullet.bounced = true;
                    // Conservem la posició anterior, fora de la paret.
                } else {
                    bullet.x = nextX;
                    bullet.y = nextY;
                }
                if (enemyAlive && Math.hypot(bullet.x - enemyX, bullet.y - enemyY)
                        <= TANK_RADIUS + BULLET_RADIUS) {
                    enemyAlive = false;
                    explosions.add(new Explosion(enemyX, enemyY, 60));
                    remove = true;
                    break;
                }
                if (tankAlive && bullet.bounced && Math.hypot(bullet.x - tankX, bullet.y - tankY)
                        <= TANK_RADIUS + BULLET_RADIUS) {
                    tankAlive = false;
                    explosions.add(new Explosion(tankX, tankY, 60));
                    remove = true;
                    break;
                }
            }
            if (remove) iterator.remove();
        }
    }

    // Col·lisió d'un cercle amb els límits interiors i els rectangles dels obstacles.
    private boolean blocked(double x, double y, double radius) {
        if (x - radius < WALL || y - radius < WALL
                || x + radius > canvas.getWidth() - WALL
                || y + radius > canvas.getHeight() - WALL) return true;

        for (Rectangle2D obstacle : obstacles) {
            double nearestX = Math.max(obstacle.getMinX(), Math.min(x, obstacle.getMaxX()));
            double nearestY = Math.max(obstacle.getMinY(), Math.min(y, obstacle.getMaxY()));
            if (Math.hypot(x - nearestX, y - nearestY) <= radius) return true;
        }
        return false;
    }

    // --- Dibuix: només rectangles, línies i cercles.
    private void redraw() {
        double w = canvas.getWidth(), h = canvas.getHeight();
        gc.setFill(Color.WHITESMOKE);
        gc.fillRect(0, 0, w, h);

        gc.setFill(Color.DIMGRAY);
        gc.fillRect(0, 0, w, WALL);
        gc.fillRect(0, h - WALL, w, WALL);
        gc.fillRect(0, 0, WALL, h);
        gc.fillRect(w - WALL, 0, WALL, h);
        gc.setFill(Color.LIGHTGRAY);
        for (Rectangle2D obstacle : obstacles) {
            gc.fillRect(obstacle.getMinX(), obstacle.getMinY(),
                obstacle.getWidth(), obstacle.getHeight());
        }

        if (tankAlive) drawAim();
        gc.setFill(Color.RED);
        for (Bullet bullet : bullets) {
            gc.fillOval(bullet.x - BULLET_RADIUS, bullet.y - BULLET_RADIUS,
                BULLET_RADIUS * 2, BULLET_RADIUS * 2);
        }
        if (tankAlive) {
            drawTank(tankX, tankY, bodyAngle, turretAngle(), Color.DODGERBLUE);
        }
        if (enemyAlive) drawTank(enemyX, enemyY, Math.PI, Math.PI, Color.DARKGOLDENROD);
        for (Explosion explosion : explosions) drawExplosion(explosion);
    }

    private void drawAim() {
        double angle = turretAngle();
        double distance = Math.hypot(mouseX - tankX, mouseY - tankY);
        gc.setFill(Color.DODGERBLUE);
        for (double d = 44; d < distance; d += 18) {
            double x = tankX + Math.cos(angle) * d;
            double y = tankY + Math.sin(angle) * d;
            if (blocked(x, y, 3)) break;
            gc.fillOval(x - 3, y - 3, 6, 6);
        }
    }

    private void drawTank(double x, double y, double body, double turret, Color color) {
        // save/restore separa la rotació del cos de la rotació de la torreta.
        gc.save();
        gc.translate(x, y);
        gc.rotate(Math.toDegrees(body));
        gc.setFill(Color.DARKSLATEGRAY);
        gc.fillRect(-18, -17, 36, 6);
        gc.fillRect(-18, 11, 36, 6);
        gc.setFill(color);
        gc.fillRect(-16, -11, 32, 22);
        gc.restore();

        gc.save();
        gc.translate(x, y);
        gc.rotate(Math.toDegrees(turret));
        gc.setFill(color.darker());
        gc.fillRect(0, -3, 32, 6);
        gc.fillOval(-9, -9, 18, 18);
        gc.restore();
    }

    private void drawExplosion(Explosion explosion) {
        double progress = 1 - explosion.time / EXPLOSION_DURATION;
        double radius = explosion.radius * (0.3 + 0.7 * progress);
        gc.save();
        gc.setGlobalAlpha(1 - progress);
        gc.setFill(Color.ORANGE);
        gc.fillOval(explosion.x - radius, explosion.y - radius, radius * 2, radius * 2);
        gc.setStroke(Color.ORANGERED);
        gc.strokeOval(explosion.x - radius, explosion.y - radius, radius * 2, radius * 2);
        gc.restore();
    }
}
