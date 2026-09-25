<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2024</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="./assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

# Exercici 0

Fes una versió del programa **"Paint"** multiusuari amb JavaFX, Canvas i WebSockets.

El programa ha de tenir dues vistes:

- La primera vista configura la connexió del servidor amb el nom del jugador
- La segona vista permet dibuixar a tots els usuaris connectats sobre del canvas

## Segona vista

Ha de tenir una part d'opcions i una part de dibuix

Ha de permetre escollir les opcions:

- Gruix de la traç
- Color del traç
- Color secundari
- Botó per esborrar l'area de dibuix

Ha de permetre fer dibuix lliure amb el botó del mouse apretat, segons el gruix i color escollits.

Ha de permetre afegir formes predefinides (oval i rectangle):

- Primer click defineix la posició top/left de la forma
- Arrossegar defineix la posició final bottom/right de la forma
- Alliberar el mouse defineix la forma

Segons les opcions escollides:

- El relleu de la forma serà del gruix del traç escollit
- El color del relleu serà del color del traç
- L'emplenat de la forma serà del color secundari