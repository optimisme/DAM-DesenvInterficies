package com.project;

import javafx.scene.canvas.GraphicsContext;
import javafx.scene.paint.Color;
import javafx.scene.text.Font;
import javafx.scene.text.Text;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

public class CnvSyntaxHighlighter {

    private GraphicsContext gc;
    
    private static final Font FONT = new Font("Arial", 14);
    private static final Color DEFAULT_COLOR = Color.BLACK;
    private static final Color COMMENT_COLOR = Color.rgb(50, 113, 52);

    private static final Set<String> keywordsTypes = new HashSet<>();
    private static final Set<String> keywordsAttributes = new HashSet<>();
    private static final Set<String> keywordsMethods = new HashSet<>();
    private static final Set<String> keywordsObjects = new HashSet<>();
    private static final Map<String, Color> colorMap = new HashMap<>();

    static {
        keywordsTypes.add("new");
        keywordsTypes.add("void");

        keywordsAttributes.add("ROUND");
        keywordsAttributes.add("SQUARE");
        keywordsAttributes.add("NO_CYCLE");

        keywordsMethods.add("setStroke");
        keywordsMethods.add("setLineWidth");
        keywordsMethods.add("setLineCap");
        keywordsMethods.add("setStrokeLine");
        keywordsMethods.add("setLineJoin");
        keywordsMethods.add("beginPath");
        keywordsMethods.add("moveTo");
        keywordsMethods.add("lineTo");
        keywordsMethods.add("stroke");
        keywordsMethods.add("fill");
        keywordsMethods.add("save");
        keywordsMethods.add("restore");
        keywordsMethods.add("strokeLine");
        keywordsMethods.add("fillRect");
        keywordsMethods.add("fillRoundRect");
        keywordsMethods.add("fillArc");
        keywordsMethods.add("fillStrokeArc");
        keywordsMethods.add("fillOval");
        keywordsMethods.add("fillStrokeOval");
        keywordsMethods.add("fillText");
        keywordsMethods.add("drawImage");
        keywordsMethods.add("getWidth");
        keywordsMethods.add("getHeight");
        keywordsMethods.add("setFill");
        keywordsMethods.add("setTextAlign");
        keywordsMethods.add("setTextBaseline");
        keywordsMethods.add("setTextAlignment");
        keywordsMethods.add("setWrappingWidth");
        keywordsMethods.add("setTextOrigin");
        keywordsMethods.add("setFont");
        keywordsMethods.add("translate");
        keywordsMethods.add("rotate");
        keywordsMethods.add("scale");

        keywordsObjects.add("Canvas");
        keywordsObjects.add("Stop");
        keywordsObjects.add("String");
        keywordsObjects.add("Color");
        keywordsObjects.add("Text");
        keywordsObjects.add("Group");
        keywordsObjects.add("Scene");
        keywordsObjects.add("StrokeLineCap");
        keywordsObjects.add("StrokeLineJoin");
        keywordsObjects.add("LinearGradient");
        keywordsObjects.add("CycleMethod");
        keywordsObjects.add("VPos");
        keywordsObjects.add("TextAlignment");


        colorMap.put("ORANGE", Color.ORANGE);
        colorMap.put("GREEN", Color.GREEN);
        colorMap.put("BLUE", Color.BLUE);
        colorMap.put("PURPLE", Color.PURPLE);
        colorMap.put("RED", Color.RED);
        colorMap.put("GRAY", Color.GRAY);
        colorMap.put("NAVY", Color.NAVY);
    }

    public CnvSyntaxHighlighter(GraphicsContext gc) {
        this.gc = gc;
    }

    public void drawText(String code, double x, double y) {
        gc.setFont(FONT);
        String[] lines = code.split("\n");
        double lineHeight = FONT.getSize() * 1.2; // Reduït l'espaiat entre línies

        for (String line : lines) {
            drawLine(line, x, y);
            y += lineHeight;
        }
    }

    private void drawLine(String line, double x, double y) {
        String word = "";
        String lastWord = "";
        boolean isComment = false;
        boolean lastCharWasDot = false;

        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);

            if (!isComment && line.startsWith("//", i)) {
                drawWord(word, x, y, getColorForWord(word, lastWord, lastCharWasDot));
                x += computeTextWidth(word);
                word = "";
                drawWord(line.substring(i), x, y, COMMENT_COLOR);
                return;
            }

            if (Character.isLetterOrDigit(c) || c == '_') {
                word += c;
            } else {
                if (!word.isEmpty()) {
                    Color color = getColorForWord(word, lastWord, lastCharWasDot);
                    drawWord(word, x, y, color);
                    x += computeTextWidth(word);
                    lastWord = word;
                    word = "";
                }
                drawWord(String.valueOf(c), x, y, DEFAULT_COLOR);
                x += computeTextWidth(String.valueOf(c));
                lastCharWasDot = (c == '.');
                if (!lastCharWasDot) {
                    lastWord = "";
                }
            }
        }

        if (!word.isEmpty()) {
            Color color = getColorForWord(word, lastWord, lastCharWasDot);
            drawWord(word, x, y, color);
        }
    }

    private void drawWord(String word, double x, double y, Color color) {
        gc.setFill(color);
        gc.fillText(word, x, y);
    }

    private Color getColorForWord(String word, String lastWord, boolean lastCharWasDot) {
        if (lastWord.equals("Color") && colorMap.containsKey(word)) {
            return colorMap.get(word);
        } else if (keywordsTypes.contains(word)) {
            return Color.rgb(6, 80, 126);
        } else if (lastCharWasDot && keywordsAttributes.contains(word)) {
            return Color.rgb(33, 140, 161);
        } else if (lastCharWasDot && keywordsMethods.contains(word)) {
            return Color.rgb(118, 13, 159);
        } else if (keywordsObjects.contains(word)) {
            return Color.rgb(3, 84, 171);
        } else {
            return DEFAULT_COLOR;
        }
    }

    private double computeTextWidth(String text) {
        Text tempText = new Text(text);
        tempText.setFont(FONT);
        return tempText.getLayoutBounds().getWidth();
    }
}