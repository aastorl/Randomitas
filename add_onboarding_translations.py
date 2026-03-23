import json
import os

translations = {
    "Bienvenido a Randomitas!": "Welcome to Randomitas!",
    "Cómo funciona Randomitas": "How Randomitas works",
    "Tu app definitiva para randomizar lo que quieras.": "Your definitive app to randomize whatever you want.",
    "Todo lo que necesitás saber sobre la app.": "Everything you need to know about the app.",
    "Elementos": "Items",
    "Crea elementos que pueden contener otros elementos dentro, organizá todo como quieras.": "Create items that can contain other items inside, organize everything as you like.",
    "Randomización": "Randomization",
    "Presioná el botón de mezcla para elegir un elemento al azar entre todos los visibles.": "Press the shuffle button to pick a random item from all visible ones.",
    "Imágenes": "Images",
    "Adjuntá fotos a tus elementos para identificarlos visualmente. El fondo se transforma con la imagen.": "Attach photos to your items to identify them visually. The background transforms with the image.",
    "Favoritos": "Favorites",
    "Marcá tus elementos favoritos para acceder rápidamente desde cualquier nivel.": "Mark your favorite items to access them quickly from any level.",
    "Ocultar": "Hide",
    "Ocultá elementos para que no aparezcan al randomizar, sin eliminarlos.": "Hide items so they don't appear when randomizing, without deleting them.",
    "Mover y Copiar": "Move and Copy",
    "Reorganizá tus elementos moviéndolos o copiándolos entre carpetas.": "Reorganize your items by moving or copying them between folders.",
    "Selección Múltiple": "Multiple Selection",
    "Seleccioná varios elementos a la vez para moverlos, copiarlos, ocultarlos o eliminarlos.": "Select multiple items at once to move, copy, hide, or delete them.",
    "Crea tu primer elemento!": "Create your first item!",
    "Entendido": "Got it"
}

xcstrings_path = 'Randomitas/Localizable.xcstrings'

with open(xcstrings_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

for es_key, en_val in translations.items():
    if es_key in data.get('strings', {}):
        if 'localizations' not in data['strings'][es_key]:
            data['strings'][es_key]['localizations'] = {}
        data['strings'][es_key]['localizations']['en'] = {
            "stringUnit": {
                "state": "translated",
                "value": en_val
            }
        }
    else:
        # Create it anyway just in case
        data['strings'][es_key] = {
            "extractionState": "manual",
            "localizations": {
                "en": {
                    "stringUnit": {
                        "state": "translated",
                        "value": en_val
                    }
                }
            }
        }

with open(xcstrings_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Onboarding translations added successfully.")
