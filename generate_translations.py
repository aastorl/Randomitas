import json

translations = {
    "A → Z": "A → Z",
    "Z → A": "Z → A",
    "Abrir Elemento": "Open Item",
    "Accede a los elementos ocultos desde el menú ⋯": "Access hidden items from the ⋯ menu",
    "Agregar Imagen": "Add Image",
    "Atrás": "Back",
    "Buscar": "Search",
    "Cancelar": "Cancel",
    "Cerrar": "Close",
    "Comienza creando un Elemento": "Start by creating an Item",
    "Confirmar Edición": "Confirm Edit",
    "Copiar": "Copy",
    "Crea tu primer elemento para comenzar": "Create your first item to start",
    "Crea tu primer elemento!": "Create your first item!",
    "Crea uno nuevo": "Create a new one",
    "Cuadrícula": "Grid",
    "Edición del Elemento": "Edit Item",
    "Elemento Oculto": "Hidden Item",
    "Elementos Encontrados": "Items Found",
    "Elementos Ocultos": "Hidden Items",
    "Eliminar": "Delete",
    "Entendido": "Got it",
    "Escribe para buscar": "Type to search",
    "Esta acción no se puede deshacer.": "This action cannot be undone.",
    "Favoritos": "Favorites",
    "Galería": "Gallery",
    "Guardar": "Save",
    "Historial (24hs)": "History (24hrs)",
    "Imagen": "Image",
    "Lista": "List",
    "Listo": "Done",
    "Los elementos creados aquí no aparecerán al randomizar": "Items created here will not appear when randomizing",
    "Los elementos ocultos aparecerán aquí": "Hidden items will appear here",
    "Los elementos ocultos no participan en la randomización. Desoculta este elemento para poder randomizar.": "Hidden items do not participate in randomization. Unhide this item to randomize.",
    "Los elementos ocultos no pueden ser favoritos. Desoculta este elemento primero.": "Hidden items cannot be favorites. Unhide this item first.",
    "Los items solo pueden existir dentro de carpetas": "Items can only exist inside folders",
    "Mover": "Move",
    "Mover/Copiar": "Move/Copy",
    "Más antiguo": "Oldest",
    "Más reciente": "Newest",
    "Necesitas permitir el acceso a la cámara en Configuración": "You need to allow camera access in Settings",
    "Necesitas permitir el acceso a la galería en Configuración": "You need to allow gallery access in Settings",
    "No hay elementos disponibles para randomizar.": "No items available to randomize.",
    "No se encontraron Elementos": "No Items found",
    "Nombre": "Name",
    "Nuevo Elemento": "New Item",
    "OK": "OK",
    "Para modificar la visibilidad de este elemento, debes desocultar: %@": "To change the visibility of this item, you must unhide: %@",
    "Por favor ingresa un nombre para el elemento": "Please enter a name for the item",
    "Randomitas": "Randomitas",
    "Renombrar": "Rename",
    "Selecciona el destino": "Select destination",
    "Sin Elementos Ocultos": "No Hidden Items",
    "Sin Elementos guardados": "No saved Items",
    "Todos los elementos están ocultos": "All items are hidden",
    "Ubicación": "Location",
    "Vacío": "Empty",
    "Ya existe un elemento con el mismo nombre": "An item with the same name already exists",
    "Ya existen %lld Elementos con los mismos nombres. ¿Quieres reemplazarlos?": "%lld Items with the same names already exist. Do you want to replace them?",
    "^[%lld seleccionado](inflect: true)": "^[%lld selected](inflect: true)",
    "Se eliminará \"%@\" permanentemente.": "\"%@\" will be permanently deleted.",
    "Mostrar": "Show",
    "Ocultar": "Hide",
    "Editar": "Edit",
    "Seleccionar": "Select"
}

xcstrings = {
    "sourceLanguage": "es",
    "strings": {},
    "version": "1.0"
}

for es_key, en_val in translations.items():
    xcstrings["strings"][es_key] = {
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

with open('/Users/astorluduena/Documents/XCodeProjects/Randomitas/Randomitas/Localizable.xcstrings', 'w', encoding='utf-8') as f:
    json.dump(xcstrings, f, indent=2, ensure_ascii=False)

print("Translations generated successfully.")
