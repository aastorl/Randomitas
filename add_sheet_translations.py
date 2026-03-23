import json

translations = {
    # FavoritesSheet Empty State
    "Sin Favoritos": "No Favorites",
    "Los elementos marcados como favoritos aparecerán aquí": "Items marked as favorites will appear here",
    
    # HistorySheet Empty State
    "Sin Historial": "No History",
    "Los resultados aleatorios de las últimas 24 horas aparecerán aquí": "Random results from the last 24 hours will appear here",
    
    # HiddenFoldersSheet Empty State
    "Sin Elementos Ocultos": "No Hidden Items",
    "Los elementos que ocultes aparecerán aquí": "Items you hide will appear here",
    
    # MoveCopySheet Alerts
    "No puedes copiar a la misma ubicación.": "You cannot copy to the same location.",
    "No puedes mover a la misma ubicación.": "You cannot move to the same location.",
    "No puedes mover un Elemento dentro de sí mismo.": "You cannot move an Item inside itself.",
    
    # Ensure this is covered
    "Acción no permitida": "Action not allowed"
}

xcstrings_path = '/Users/astorluduena/Documents/XCodeProjects/Randomitas/Randomitas/Localizable.xcstrings'

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

print("Empty states and alerts translations added successfully.")
