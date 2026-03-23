import json

translations = {
    "¿Eliminar este Elemento?": "Delete this Item?",
    "¿Estás seguro?": "Are you sure?",
    "¿Reemplazar elementos existentes?": "Replace existing items?",
    "%lld": "%lld",
    "%lld elemento%@": "%lld item%@",
    "%lld elemento%@ creado%@": "%lld item%@ created%@",
    "< %@": "< %@",
    "< %@\\n\\n%@": "< %@\\n\\n%@",
    "A - Z": "A - Z",
    "Acción no permitida": "Action not allowed",
    "Agregar": "Add",
    "Agregar a Favoritos": "Add to Favorites",
    "Bienvenido a Randomitas!": "Welcome to Randomitas!",
    "Buscar Elementos": "Search Items",
    "Buscar Elementos...": "Search Items...",
    "Cómo funciona Randomitas": "How Randomitas works",
    "Copiar a...": "Copy to...",
    "Crear": "Create",
    "Crear y Continuar": "Create and Continue",
    "Deseleccionar Todo": "Deselect All",
    "Elemento Protegido": "Protected Item",
    "Elementos Creados": "Created Items",
    "Eliminar %lld elementos": "Delete %lld items",
    "Eliminar imagen": "Delete image",
    "Error": "Error",
    "Favorito": "Favorite",
    "Fecha": "Date",
    "Info": "Info",
    "Mover a...": "Move to...",
    "Nombre del Elemento": "Item Name",
    "Nombre duplicado": "Duplicate name",
    "Nombre inválido": "Invalid name",
    "Nombre requerido": "Name required",
    "Nuevo nombre": "New name",
    "Ok": "Ok",
    "Ordenar por fecha": "Sort by date",
    "Ordenar por nombre": "Sort by name",
    "Permiso denegado": "Permission denied",
    "Reemplazar": "Replace",
    "Seleccionar de galería": "Select from gallery",
    "Seleccionar Todo": "Select All",
    "Sin Elementos": "No Items",
    "Todo lo que necesitás saber sobre la app.": "Everything you need to know about the app.",
    "Tomar foto": "Take photo",
    "Tu app definitiva para randomizar lo que quieras.": "Your definitive app to randomize whatever you want.",
    "Vista": "View",
    "Volver a Elementos": "Back to Items",
    "Ya existe un Elemento llamado \"%@\". ¿Quieres reemplazarlo?": "An Item named \"%@\" already exists. Do you want to replace it?",
    "Z - A": "Z - A"
}

file_path = '/Users/astorluduena/Documents/XCodeProjects/Randomitas/Randomitas/Localizable.xcstrings'

with open(file_path, 'r', encoding='utf-8') as f:
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
        data['strings'][es_key]['extractionState'] = 'manual'
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

with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Translations updated successfully.")
