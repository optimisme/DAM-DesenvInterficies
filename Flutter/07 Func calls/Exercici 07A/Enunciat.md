<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2023</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="../assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

# Eina de dibuix vectorial (amb IA)

Fent servir **function calls** fes una eina de dibuix assistida per IA, en la que els usuaris fan preguntes a la IA per fer dibuixos i escriure textos a l'aplicació.

Fes servir l'exemple 0700 com a base inicial, veuràs que l'exemple manté una llista de polígons que cal dibuixar i les seves propietats.

## Fase 1

S'ha de poder:

- Fer linies, cercles i quadres
- Decidir el gruix de les linies i contorns
- Decidir el color de les línies i contorns
- Decidir el color dels emplenats dels polígons
- Decidir els colors i tipus de gradient d'emplenat dels polígons
- Dibuixar textos amb diferents tipografies, mides i estils (normal, negreta, ...)

## Fase 2

S'ha de poder:

- Seleccionar polígons
- Esborrar polígons
- Canviar les propietats d'un polígon (color, mida del contorn, emplenat, posició ...)
- Fer consultes a partir dels % de la mida de dibuix disponibles o amb paraules tipus "a la meitat del dibuix", "la diagonal del quadre", ...
