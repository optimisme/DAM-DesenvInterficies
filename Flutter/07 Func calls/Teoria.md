<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2023</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="./assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

# Function calls

Les **function calls** són una funcionalitat que permet que un model d'intel·ligència artificial, conegui quines funcions hi ha definides al teu codi (noms de les funcions i paràmtres), i decideixi si s'han d'invocar a partir de les peticions (prompts) d'un usuari.

Per fer-ho possible cal:

- **Definir les funcions** que hi han disponibles, els paràmetres que reben i explicar el què fan.
- **Definir la resposta** esperada, nom de la funció que s'ha de cridar i amb quins paràmetres
- **Fer crides a la IA** amb el format de 'custom tools'
- **Processar la resposta** de la IA per cridar a la funció del nostre codi

**Important**: No tots els models de IA tenen les *function calls* disponibles.

## Intercanvi de dades amb la IA

Un cop ens podem comunicar amb la IA a través de POST, cal definir el format de les dades que intercanviem amb ella:

- Les funcions que tenim disponibles i els seus paràmetres
- La resposta de la IA que haurem d'interpretar

### JSON schema

Un **[JSON schema](https://en.wikipedia.org/wiki/JSONs)**  defineix l'estructura i tipus de dades d'un arxiu JSON.

Exemple definició de l'atribut *"parameters"*:

```json
  "parameters": {
    "type": "object",
    "properties": {
      "x": {"type": "number"},
      "y": {"type": "number"},
      "radius": {"type": "number"}
    },
    "required": ["x", "y", "radius"]
  }
```

**Recomanació**: No posar paràmetres que siguin objectes dins d'altres paràmetres, fer una llista clara i única de propietats sense anidar.

Exemple d'objecte segons la definició anterior:

```json
"arguments":{
  "radius":"5",
  "x":"15",
  "y":"25"
}
```
### Tools

Les eines **tools** són les funcions que tenim disponibles al nostre codi.

Informem a la IA que estàn disponibles, al codi d'exemple la definició de les **tools** (funcions) disponibles està a l'arxiu *constants.dart*

```dart
const tools = [
  {
    "type": "function",
    "function": {
      "name": "draw_circle",
      "description":
          "Dibuixa un cercle amb un radi determinat, si falta el radi posar-ne un de 10 per defecte, si el radi ha de ser aletori posar-ne un aleatori entre 10 i 25",
      "parameters": {
        "type": "object",
        "properties": {
          "x": {"type": "number"},
          "y": {"type": "number"},
          "radius": {"type": "number"}
        },
        "required": ["x", "y", "radius"]
      }
    }
  },
  // ...
]
```

## Crida a la IA

La crida a la IA es fa amb un POST com qualsevol altre crida, però **amb el format de function calls** que necessita la IA, en el cas de ollama:

```dart
Future<void> callWithCustomTools({required String userPrompt}) async {
    const apiUrl = 'http://localhost:11434/api/chat';

    _responseText = "";
    _isInitial = false;
    setLoading(true);

    final body = {
      "model": "llama3.2",
      "stream": false,
      "messages": [
        {"role": "user", "content": userPrompt}
      ],
      "tools": tools
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print(response.body);

        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['message'] != null &&
            jsonResponse['message']['tool_calls'] != null) {
          final toolCalls =
              jsonResponse['message']['tool_calls'] as List<dynamic>;
          for (final toolCall in toolCalls) {
            if (toolCall['function'] != null) {
              _processFunctionCall(toolCall['function']);
            }
          }
        }

        setLoading(false);
      } else {
        setLoading(false);
        throw Exception("Error: ${response.body}");
      }
    } catch (e) {
      print("Error during API call: $e");
      setLoading(false);
    }
  }
```

### Processar la resposta

Un cop la IA ha interpretat la petició i ens dóna una resposta, aquesta serà aproximada (però no igual) al format que li hem dit que volem com a resposta.

Pot canviar números per strings, noms de paràmetres, ...

Aquesta resposta l'hem d'interpretar, per cridar a la funció que ens suggereix la IA.

Exemple de resposta de la IA:

```json
flutter: {
  "model":"llama3.2",
  "created_at":"2025-01-28T18:01:25.193167Z",
  "message":{
    "role":"assistant",
    "content":"",
    "tool_calls":[
      {
        "function":{
          "name":"draw_line",
          "arguments":{
            "endX":"100",
            "endY":"25",
            "startX":"10",
            "startY":"50"
          }
        }
      }
    ]
  },
  "done_reason":"stop",
  "done":true,
  "total_duration":4030465708,
  "load_duration":41800083,
  "prompt_eval_count":428,
  "prompt_eval_duration":686000000,
  "eval_count":39,
  "eval_duration":3300000000
}
```
Necessitarem una funció **_processFunctionCall** que interpreti aquesta resposta i faci les crides al nostre codi, per complir amb el què l'usuari ha demanat a la IA:

```dart
void _processFunctionCall(Map<String, dynamic> functionCall) {
    final fixedJson = fixJsonInStrings(functionCall);
    final parameters = fixedJson['arguments'];

    switch (fixedJson['name']) {
      case 'draw_circle':
        if (parameters['x'] != null &&
            parameters['y'] != null &&
            parameters['radius'] != null) {
          final dx = parseDouble(parameters['x']);
          final dy = parseDouble(parameters['y']);
          final radius = max(0.0, parseDouble(parameters['radius']));
          addDrawable(Circle(center: Offset(dx, dy), radius: radius));
        } else {
          print("Missing circle properties: $parameters");
        }
        break;

      case 'draw_line':
      //...
  }
```

