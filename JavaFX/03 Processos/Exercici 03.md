## Exercici 03

Fent servir Ollama, i els models:

- Model de text i visió: gemma3:1b

**Nota**: Recorda, per instal·lar models
```bash
ollama run gemma3:1b
ollama run llava-phi3
```

Fes una versió de ChatGPT amb JavaFX

L'aplicació ha d'acceptar textos i imatges

- Els textos es processen amb el model de text
- Les imatges es processen amb el model de visió

Les condicions són:

- En el cas d'una petició de text, la resposta s'ha de mostrar a mida que es va rebent (stream)
- En el cas d'una petició d'imatge, la resposta s'ha de mostrar un cop completada i mentresant l'usuari veu un 'thinking...'
- L'usuari **ha de poder aturar la última petició** en qualsevol moment.

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
