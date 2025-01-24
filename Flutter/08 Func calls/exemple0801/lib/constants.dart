import 'dart:convert';

// Defineix les eines/funcions que hi ha disponibles a flutter
const tools = [
  {
    "type": "function",
    "function": {
      "name": "draw_line",
      "description": "Dibuixa una línia entre dos punts",
      "parameters": {
        "type": "object",
        "properties": {
          "start": {
            "type": "object",
            "properties": {
              "x": {"type": "number"},
              "y": {"type": "number"}
            },
            "required": ["x", "y"]
          },
          "end": {
            "type": "object",
            "properties": {
              "x": {"type": "number"},
              "y": {"type": "number"}
            },
            "required": ["x", "y"]
          }
        },
        "required": ["start", "end"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_circle",
      "description":
          "Dibuixa un cercle amb un radi determinat, si falta el radi o ha de ser aletori posar-ne un de 10 per defecte",
      "parameters": {
        "type": "object",
        "properties": {
          "center": {
            "type": "object",
            "properties": {
              "x": {"type": "number"},
              "y": {"type": "number"}
            },
            "required": ["x", "y"]
          },
          "radius": {"type": "number"}
        },
        "required": ["center", "radius"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_rectangle",
      "description":
          "Dibuixa un rectangle definit per les coordenades superior-esquerra i inferior-dreta",
      "parameters": {
        "type": "object",
        "properties": {
          "top_left": {
            "type": "object",
            "properties": {
              "x": {"type": "number"},
              "y": {"type": "number"}
            },
            "required": ["x", "y"]
          },
          "bottom_right": {
            "type": "object",
            "properties": {
              "x": {"type": "number"},
              "y": {"type": "number"}
            },
            "required": ["x", "y"]
          }
        },
        "required": ["top_left", "bottom_right"]
      }
    }
  }
];

// Defineix el format esperat de la resposta de la IA
final schema = jsonEncode({
  "type": "object",
  "properties": {
    "tool_calls": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "function": {
            "type": "object",
            "properties": {
              "name": {
                "type": "string",
                "enum": ["draw_line", "draw_circle", "draw_rectangle"]
              },
              "arguments": {
                "type": "object",
                "properties": {
                  "start": {
                    "type": "object",
                    "properties": {
                      "x": {"type": "number"},
                      "y": {"type": "number"}
                    },
                    "required": ["x", "y"]
                  },
                  "end": {
                    "type": "object",
                    "properties": {
                      "x": {"type": "number"},
                      "y": {"type": "number"}
                    },
                    "required": ["x", "y"]
                  },
                  "center": {
                    "type": "object",
                    "properties": {
                      "x": {"type": "number"},
                      "y": {"type": "number"}
                    },
                    "required": ["x", "y"]
                  },
                  "radius": {"type": "number"},
                  "top_left": {
                    "type": "object",
                    "properties": {
                      "x": {"type": "number"},
                      "y": {"type": "number"}
                    },
                    "required": ["x", "y"]
                  },
                  "bottom_right": {
                    "type": "object",
                    "properties": {
                      "x": {"type": "number"},
                      "y": {"type": "number"}
                    },
                    "required": ["x", "y"]
                  }
                },
                "additionalProperties": false
              }
            },
            "required": ["name", "arguments"]
          }
        },
        "required": ["function"]
      }
    }
  },
  "required": ["tool_calls"]
});
