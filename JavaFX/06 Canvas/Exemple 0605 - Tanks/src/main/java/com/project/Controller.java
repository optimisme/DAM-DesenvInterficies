package com.project;

import java.net.URL;
import java.util.ArrayList;
import java.util.Collections;
import java.util.EnumSet;
import java.util.List;
import java.util.ResourceBundle;
import java.util.Set;

import javafx.application.Platform;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.geometry.Point2D;
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
    private static final double TANK_SPEED = 140; // píxels/segon
    private static final double BULLET_SPEED = 360;
    private static final int MAX_BULLETS = 4;
    private static final double EXPLOSION_DURATION = 0.6; // segons

    // Escollim dos obstacles d'aquesta llista; les posicions no se solapen.
    private final List<ObjectStatic> obstacleOptions = List.of(
        new ObjectStatic(260, 100, 60, 100, Color.LIGHTGRAY),
        new ObjectStatic(260, 300, 60, 100, Color.LIGHTGRAY),
        new ObjectStatic(370, 170, 60, 160, Color.LIGHTGRAY),
        new ObjectStatic(480, 100, 60, 100, Color.LIGHTGRAY),
        new ObjectStatic(480, 300, 60, 100, Color.LIGHTGRAY)
    );
    private final List<ObjectStatic> staticObjects = new ArrayList<>();
    private final List<Bullet> bullets = new ArrayList<>();
    private final List<Explosion> explosions = new ArrayList<>();
    private final Set<KeyCode> pressedKeys = EnumSet.noneOf(KeyCode.class);

    private final Tank tank = new Tank(new Point2D(90, 250), 0, 0, Color.DODGERBLUE);
    private final Tank enemy = new Tank(new Point2D(710, 250), 180, 180, Color.DARKGOLDENROD);
    private final Target target = new Target();

    @Override
    public void initialize(URL url, ResourceBundle rb) {

        // Iniciar el context de dibuix
        gc = canvas.getGraphicsContext2D();

        // Iniciar tauler de joc i objectes
        resetBoard();

        // Iniciar events
        // (amb Platform.runLater() per assegurar que ja hi ha escena)
        Platform.runLater(() -> { configureInput(); });

        // Iniciar el temporitzador de dibuix i actualització de l'estat del joc
        timer = new CnvTimer(fps -> update(), this::redraw, 60);
        timer.start();
        redraw();
    }

    private void configureInput() {

        // Iniciar events de ratolí
        canvas.setOnMouseMoved(this::updateTarget);
        canvas.setOnMouseDragged(this::updateTarget);
        canvas.setOnMousePressed(event -> {
            updateTarget(event);
            if (event.getButton() == MouseButton.PRIMARY) fireBullet();
        });

        // Iniciar events de teclat
        canvas.getScene().setOnKeyPressed(event -> {
            if (event.getCode() == KeyCode.R) resetBoard();
            else pressedKeys.add(event.getCode());
        });
        canvas.getScene().setOnKeyReleased(event -> pressedKeys.remove(event.getCode()));
        canvas.getScene().getWindow().focusedProperty().addListener((obs, old, focused) -> {
            if (!focused) pressedKeys.clear();
        });
    }

    // Iniciar partida
    private void resetBoard() {

        // Iniciar el temporitzador i les tecles premudes
        if (timer != null) timer.stop();
        lastRunNanos = 0;
        pressedKeys.clear();

        // Iniciar parets
        double w = canvas.getWidth(), h = canvas.getHeight();
        staticObjects.clear();
        staticObjects.add(new ObjectStatic(0, 0, w, WALL, Color.DIMGRAY));
        staticObjects.add(new ObjectStatic(0, h - WALL, w, WALL, Color.DIMGRAY));
        staticObjects.add(new ObjectStatic(0, 0, WALL, h, Color.DIMGRAY));
        staticObjects.add(new ObjectStatic(w - WALL, 0, WALL, h, Color.DIMGRAY));

        // Iniciar obstacles escollint-ne dos aleatòriament de la llista d'opcions
        List<ObjectStatic> options = new ArrayList<>(obstacleOptions);
        Collections.shuffle(options);
        staticObjects.addAll(options.subList(0, 2));

        // Iniciar bales i explosions
        bullets.clear();
        explosions.clear();

        // Iniciar tancs
        tank.reset(new Point2D(90, 250), 0, 0);
        enemy.reset(new Point2D(710, 250), 180, 180);

        // Iniciar punt de mira
        target.setPosition(enemy.getPosition().getX(), enemy.getPosition().getY());
        tank.pointAt(target.getPosition());

        // Reprendre el joc després de reiniciar-lo amb R
        if (timer != null) timer.start();
    }

    // Actualitzar la posició del punt de mira
    private void updateTarget(MouseEvent event) {
        target.setPosition(event.getX(), event.getY());
    }

    // Disparar una bala
    private void fireBullet() {

        // Per disparar una bala:
        // - el tanc ha d'estar viu
        // - no hi pot haver més de MAX_BULLETS bales disparades al mateix temps
        if (!tank.isAlive() || bullets.size() >= MAX_BULLETS) return;

        // Apuntar des de la posició actual del tanc abans de disparar
        tank.pointAt(target.getPosition());

        // Afegir la bala a la llista de bales
        Point2D position = tank.getPosition();
        bullets.add(new Bullet(position, tank.getTurretAngle(), BULLET_SPEED));
    }

    // Actualitzar la lògica del joc (run)
    private void update() {
        double dt = calculateDt();
        if (dt <= 0) return;

        updateTank(dt);
        updateBullets(dt);
        updateExplosions(dt);

        // Apuntar des de la posició final del tanc.
        tank.pointAt(target.getPosition());
    }

    // Calcular el temps transcorregut, en segons, des de l'última actualització.
    // Aquest "dt" permet actualitzar els moviments sense dependre dels FPS.
    private double calculateDt() {
        long now = System.nanoTime();
        double dt = lastRunNanos == 0 ? 0 : (now - lastRunNanos) / 1_000_000_000.0;
        lastRunNanos = now;
        dt = Math.min(dt, 0.05); // evita salts grans després d'una pausa
        return dt;
    }

    // Llegir les tecles i moure el tanc si la nova posició és lliure.
    private void updateTank(double dt) {
        double dx = 0, dy = 0;

        // Les fletxes i WASD comparteixen les mateixes direccions.
        if (pressedKeys.contains(KeyCode.LEFT) || pressedKeys.contains(KeyCode.A)) dx -= 1;
        if (pressedKeys.contains(KeyCode.RIGHT) || pressedKeys.contains(KeyCode.D)) dx += 1;
        if (pressedKeys.contains(KeyCode.UP) || pressedKeys.contains(KeyCode.W)) dy -= 1;
        if (pressedKeys.contains(KeyCode.DOWN) || pressedKeys.contains(KeyCode.S)) dy += 1;

        tank.updateMovement(new Point2D(dx, dy), TANK_SPEED);

        Point2D current = tank.getPosition();
        Point2D next = tank.nextPosition(dt);

        // Si el moviment complet xoca, provem de moure només en X o només en Y.
        // Així el tanc llisca al llarg de la paret en lloc de quedar-s'hi enganxat.
        Point2D onlyX = new Point2D(next.getX(), current.getY());
        Point2D onlyY = new Point2D(current.getX(), next.getY());

        if (!isTankBlocked(next)) tank.setPosition(next);
        else if (!isTankBlocked(onlyX)) tank.setPosition(onlyX);
        else if (!isTankBlocked(onlyY)) tank.setPosition(onlyY);
        // Si tot està bloquejat, el tanc es queda on és.
    }

    // El tanc no pot entrar a les parets, als obstacles ni a l'altre tanc.
    private boolean isTankBlocked(Point2D position) {
        if (touchesStatic(position, Tank.RADIUS)) return true;
        return enemy.isAlive()
            && HelperCollisions.circlesOverlap(position, Tank.RADIUS, enemy.getPosition(), Tank.RADIUS);
    }

    // Indica si un cercle a "position" toca alguna paret o obstacle.
    private boolean touchesStatic(Point2D position, double radius) {
        for (ObjectStatic rectangle : staticObjects) {
            if (rectangle.touches(position, radius)) return true;
        }
        return false;
    }

    // Moure les bales i aplicar les regles del joc quan xoquen.
    private void updateBullets(double dt) {
        List<Bullet> bulletsToRemove = new ArrayList<>();

        for (Bullet bullet : bullets) {
            Point2D current = bullet.getPosition();
            Point2D next = bullet.nextPosition(dt);

            // 1. Paret o obstacle: el primer cop rebota, el segon desapareix.
            if (touchesStatic(next, Bullet.RADIUS)) {
                if (bullet.hasBounced()) {
                    bulletsToRemove.add(bullet);
                    addExplosion(current, 20);
                } else {
                    // Si movent-nos només en X ja xoquem, la paret és vertical: invertim X.
                    // Si movent-nos només en Y ja xoquem, la paret és horitzontal: invertim Y.
                    boolean invertX = touchesStatic(new Point2D(next.getX(), current.getY()), Bullet.RADIUS);
                    boolean invertY = touchesStatic(new Point2D(current.getX(), next.getY()), Bullet.RADIUS);
                    if (!invertX && !invertY) {
                        // Ha tocat just una cantonada: torna enrere.
                        invertX = true;
                        invertY = true;
                    }
                    bullet.bounce(invertX, invertY);
                }
                continue; // La bala no avança aquest cop: es queda fora de la paret.
            }
            bullet.setPosition(next);

            // 2. Tancs: l'enemic sempre; el nostre només si la bala ja ha rebotat.
            if (enemy.isAlive() && bullet.touches(enemy)) {
                destroyTank(enemy);
                bulletsToRemove.add(bullet);
            } else if (tank.isAlive() && bullet.hasBounced() && bullet.touches(tank)) {
                destroyTank(tank);
                bulletsToRemove.add(bullet);
            }
        }

        // 3. Dues bales que es toquen desapareixen totes dues.
        for (int i = 0; i < bullets.size(); i++) {
            for (int j = i + 1; j < bullets.size(); j++) {
                Bullet a = bullets.get(i);
                Bullet b = bullets.get(j);
                if (a.touches(b)) {
                    bulletsToRemove.add(a);
                    bulletsToRemove.add(b);
                    addExplosion(a.getPosition().midpoint(b.getPosition()), 20);
                }
            }
        }

        // Retirar les bales al final, per no modificar la llista mentre la recorrem.
        bullets.removeAll(bulletsToRemove);
    }

    // Destruir un tanc i mostrar una explosió gran.
    private void destroyTank(Tank hitTank) {
        hitTank.destroy();
        addExplosion(hitTank.getPosition(), 60);
    }

    // Actualitzar la durada dels efectes visuals i eliminar les explosions acabades.
    private void updateExplosions(double dt) {
        for (Explosion explosion : explosions) {
            explosion.update(dt);
        }
        explosions.removeIf(Explosion::isFinished);
    }

    // Afegeix una explosió visual a la llista d'explosions
    private void addExplosion(Point2D point, double radius) {
        explosions.add(new Explosion(point.getX(), point.getY(), radius, EXPLOSION_DURATION));
    }

    // Dibuix del joc
    private void redraw() {

        // Dibuix del fons
        double w = canvas.getWidth(), h = canvas.getHeight();
        gc.setFill(Color.WHITESMOKE);
        gc.fillRect(0, 0, w, h);

        // Dibuix de tots els rectangles estàtics: parets i obstacles.
        for (ObjectStatic rectangle : staticObjects) rectangle.draw(gc);

        // Dibuix de les bales
        for (Bullet bullet : bullets) bullet.draw(gc);

        // Dibuix dels tancs
        tank.draw(gc);
        enemy.draw(gc);

        // Dibuix explosions
        for (Explosion explosion : explosions) explosion.draw(gc);

        // Dibuix del canó i del punt de mira
        if (tank.isAlive()) {
            target.drawGuide(gc, tank, staticObjects);
            target.draw(gc, tank);
        }
    }
}
