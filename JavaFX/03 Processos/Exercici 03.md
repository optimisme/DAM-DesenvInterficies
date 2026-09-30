## Exercici 03

Fes una versió de ChatGPT amb JavaFX i un servidor compatible amb el protocol **"OpenAI"**

Les condicions són:

- L'aplicació ha d'acceptar textos i imatges
- En el cas d'una petició de text, la resposta s'ha de mostrar a mida que es va rebent (stream)
- En el cas d'una petició d'imatge, la resposta s'ha de mostrar un cop completada i mentresant l'usuari veu un 'thinking...'
- L'usuari **ha de poder aturar la última petició** en qualsevol moment.
- Les imatges han de mostrar una miniatura a la conversa.

Quan es processa una imatge has de poder fer preguntes tipus: 

- *"Describe this image"*
- *"How many cats are there in this image"*
...

Les imatges s'han d'escollir amb la eina de gestió d'arxius de JavaFX i enviar-se a Ollama amb format **base64**

Exemple:

<br/>
<center><img src="./assets/xatIeti.png" style="max-height: 400px" alt="">
<br/></center>
<br/>
<br/>
