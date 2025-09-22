## Exercici 01

Fes un programa amb dues vistes:

- La primera vista:

    * Ha de ser un formulari que demani el nom i l'edat d'un usuari.
    * Ha de tenir un botó que canvii a la segona vista, que s'activa quan s'ha introduit un nom i una edat.

- La segona vista:

    * Ha de ser un text que mostri "Hola NOM, tens EDAT anys!"
    * Ha de tenir un botó "Tornar" que torna a la vista anterior

Els pas d'informació entre les dues vistes, s'ha de fer a través de **Variables estàtiques al Main**

Exemple: 


```java
public class Main extends Application {

    static String edat = "20";
    ...
}
```

S'accedeix des dels controladors com **"Main.edat"**:

```java
    public void escriuEdat() {
        System.out.println("Edat des de Desktop: " + Main.edat);
    }
```

Recordeu que podeu obtenir el controlador de la vista on voleu anar, abans de canviar de vista, per cridar les funcions del controlador.

```java
    ControllerVistaB ctrlB = (ControllerVistaB)UtilsView.getController("VistaB");
    ctrlB.setData("Toni", 25);
    UtilsViews.setView("VistaB");
```