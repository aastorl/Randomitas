# Randomitas (iOS) Deep Dive

Este documento describe la app **Randomitas** tal como está implementada en este repo: su estructura, tecnologías, arquitectura, flujos de UI, persistencia y “por qué” de decisiones visibles en el código.

Nota de honestidad: se cubre el 100% de los archivos Swift y configuraciones relevantes encontradas en el repo (`Randomitas/`, `Randomitas.xcodeproj/`, tests). Si más adelante agregás targets/paquetes/archivos nuevos, habrá que re-sincronizar esta guía.

## 1) Vista Rápida (para entrevistas)

### Pitch de 20-30 segundos
Randomitas es una app iOS hecha en **SwiftUI** donde el usuario crea “Elementos” (internamente carpetas) en una **jerarquía ilimitada** (carpetas dentro de carpetas). Permite **randomizar** el próximo elemento a elegir, **adjuntar imágenes**, **marcar favoritos**, **ocultar** elementos para que no participen en la randomización, **mover/copiar** entre carpetas y usar **selección múltiple** para acciones batch. Los datos se persisten con **Core Data**, y la navegación se resuelve con `NavigationStack` usando un “path” numérico.

### Qué tecnologías diría en voz alta
- UI: SwiftUI (`NavigationStack`, sheets, `refreshable`, `presentationDetents`, etc.).
- Arquitectura: MVVM “light” con un `RandomitasViewModel` central.
- Persistencia: Core Data (`NSPersistentContainer`) con entidades generadas por Xcode.
- Integración UIKit: `UIImagePickerController` (cámara/galería) y `UI*FeedbackGenerator` (haptics).
- Tests: Swift Testing (`import Testing`) para unit tests y XCTest para UI tests.

## 2) Estructura del Repo

En la raíz del proyecto:
- `Randomitas/`: código fuente de la app.
- `Randomitas.xcodeproj/`: configuración de Xcode (targets, build settings, Info.plist generado, etc.).
- `RandomitasTests/`: unit tests (Swift Testing).
- `RandomitasUITests/`: UI tests (XCTest).

Dentro de `Randomitas/`:
- `RandomitasApp.swift`: entrypoint SwiftUI `@main`.
- `Views/`: pantallas (principalmente `FolderDetailView` + sub-vistas list/grid/gallery).
- `ViewModels/`: `RandomitasViewModel` (estado + operaciones de negocio).
- `Models/`: structs de dominio (Folder, history, navegación, etc.).
- `Sheets/`: sheets modales (crear/editar/mover/copiar/favoritos/historial/ocultos/búsqueda/resultado).
- `CoreData/`: `CoreDataStack`.
- `Randomitas.xcdatamodeld/`: modelo de Core Data (entidades y relaciones).
- `Utils/`: permisos, haptics, extensiones de imagen.
- `Assets.xcassets/`, `AppIcon.icon/`: recursos.

## 3) Targets y Configuración (Xcode)

Targets:
- `Randomitas` (app).
- `RandomitasTests` (unit tests).
- `RandomitasUITests` (UI tests).

Info.plist:
- No hay `Info.plist` físico en el repo: el proyecto usa `GENERATE_INFOPLIST_FILE = YES`.
- Las claves de permisos se inyectan por build settings en `project.pbxproj`:
  - `INFOPLIST_KEY_NSCameraUsageDescription`: "Necesitamos acceso a la cámara para capturar fotos".
  - `INFOPLIST_KEY_NSPhotoLibraryUsageDescription`: "Necesitamos acceso a tu galería para seleccionar fotos".

Otros datos detectados:
- `SWIFT_VERSION = 5.0`.
- `IPHONEOS_DEPLOYMENT_TARGET = 26.0` (ojo: esto fuerza APIs modernas; si querés compatibilidad con iOS anterior, hay que bajar target y reemplazar APIs no disponibles).

Dependencias externas:
- No se detectaron Swift Packages / CocoaPods / Carthage. Todo es SDK Apple + código propio.

## 4) Tecnologías y “por qué”

### SwiftUI como UI principal
La navegación y presentación de UI se hace con SwiftUI:
- `NavigationStack` + `navigationDestination(for:)` usando `FolderDestination(path: [Int])`.
- `sheet(...)`, `fullScreenCover(...)`, `confirmationDialog(...)`, `.searchable`.
- `@State`, `@Binding`, `@ObservedObject`, `@StateObject`.

### Core Data como persistencia
Se persisten:
- Árbol de elementos (`FolderEntity` con relación `parent`/`subfolders`).
- Favoritos (`FolderFavoritesEntity`).
- Historial de randomización de las últimas 24 horas (`HistoryEntity`).

### UIKit donde SwiftUI no alcanza (o es más simple)
- Imagen: `UIImagePickerController` envuelto con `UIViewControllerRepresentable` (`ImagePickerView`).
- Haptics: `UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator`, `UISelectionFeedbackGenerator` (`HapticManager`).
- Imagen util: `UIImage.resized(toMaxDimension:)` para limitar tamaño antes de guardar.

## 5) Modelo de Datos

### Dominio (structs en `Models/`)
`Folder`:
- Identificable y codificable (`Identifiable`, `Codable`).
- Campos: `id`, `name`, `subfolders`, `imageData`, `createdAt`, `isHidden`.

`FolderDestination`:
- Wrapper hashable para navegación: `path: [Int]`.

`FolderReference`:
- Referencia mínima para favoritos: `id` + `name`.

`HistoryEntry`:
- Lo que se muestra en “Historial”: `itemId`, `itemName`, `path` (string), `folderPath` ([Int] para navegación), `timestamp`.

`MoveCopyOperation`:
- Describe una operación a ejecutar en `MoveCopySheet`: items seleccionados, contenedor origen y flag `isCopy`.

`ImagePickerRequest`:
- Decide si se presenta como `fullScreenCover` (cámara) o `sheet` (galería).

### Persistencia (Core Data Model)
Entidades (según `Randomitas.xcdatamodeld`):
- `FolderEntity`
  - `id: UUID?`, `name: String?`, `createdAt: Date?`, `imageData: Binary?`, `isHidden: Bool`.
  - Relación `parent` (to-one) y `subfolders` (to-many, cascade).
- `FolderFavoritesEntity`
  - `id: UUID?` (id del registro), `folderId: UUID?` (id del folder favorito), `folderName: String?`, `pathData: Binary?` (actualmente no se usa en la lógica principal).
- `HistoryEntity`
  - `id: UUID?`, `itemId: UUID?`, `itemName: String?`, `path: String?`, `folderPath: Binary?` (JSON de `[Int]`), `timestamp: Date?`.

Generación de clases:
- El modelo está con `codeGenerationType="class"`, por lo que Xcode genera `FolderEntity`, `HistoryEntity`, `FolderFavoritesEntity` en build time (no aparecen como `.swift` en el repo).

## 6) Arquitectura y Flujo General

### “Single source of truth”: `RandomitasViewModel`
La app usa un único `ObservableObject` que:
- Carga el árbol desde Core Data y lo convierte a `Folder` structs (`loadFolders` + `convertToFolder`).
- Mantiene `@Published` con:
  - `folders`: carpetas raíz.
  - `folderFavorites`: favoritos por `UUID`.
  - `history`: resultados de randomización con TTL 24h.
  - Preferencias de UI: `viewType`, alert flags.
- Expone operaciones: crear, borrar, renombrar, ocultar/mostrar, mover/copiar, búsqueda, randomize, batch ops.

### Navegación con “path numérico”
La app navega por paths `[Int]` que representan índices dentro de arrays en cada nivel:
- Root: `[]`.
- Primer nivel: `[0]`, `[1]`, ...
- Segundo nivel: `[0, 2]`, etc.

Esto se usa en:
- `FolderDetailView(folderPath: ...)`: pantalla genérica para root o subcarpeta.
- `getFolderAtPath`, `getFolderEntity(at:)`, `findFolder(at:)`.

Consecuencia importante:
- Los índices pueden cambiar si se reordenan/insertan/elimnan elementos. Para “anclas estables” se usa `UUID` y se recalcula el path cuando hace falta (ej: `findPathById` en favoritos).

### Root virtual
En `RandomitasViewModel` existe un “Root Folder” virtual:
- `rootFolder` no vive en Core Data.
- Sirve para que la UI tenga una sola pantalla “FolderDetail” reutilizable para todos los niveles, incluido el nivel raíz.

## 7) Persistencia: `CoreDataStack`

`CoreDataStack`:
- Singleton `shared`.
- `NSPersistentContainer(name: "Randomitas")`.
- `automaticallyMergesChangesFromParent = true`.
- `mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy`.
- Helpers:
  - `save()`: guarda si hay cambios.
  - `refresh()`: `viewContext.reset()` (importante: invalida objetos de Core Data, por eso el ViewModel guarda UUID antes de refrescar).

Limpieza one-shot:
- `cleanDatabaseIfNeeded()` borra entidades (`FolderEntity`, `HistoryEntity`, `FolderFavoritesEntity`) si `UserDefaults` no tiene `HasCleanedDatabaseForFoldersOnly`.
- Esto se ejecuta en el `init()` del stack.
- Implicación: es un “migration hack” manual para una reestructuración histórica.

## 8) Features (qué hace la app y dónde vive)

### 8.1 Crear Elementos (normal y batch)
- UI: `NewFolderSheet`.
- Modo normal: botón `+` abre sheet con “Crear”.
- Modo batch: long-press en `+` activa `isBatchAddMode` y el sheet muestra “Crear y Continuar” + contador.
- Previene:
  - Nombre vacío.
  - Nombre duplicado a nivel del contenedor actual.
- Imagen opcional: cámara (`fullScreenCover`) o galería (`sheet`), redimensionada a 1024 px máx.
- Persistencia:
  - Root: `addRootFolder`.
  - Subcarpeta: `addSubfolder`.
- Favorito en creación:
  - Se crea, se refresca Core Data, se recarga y luego se marca favorito usando el `UUID` guardado antes del refresh.

### 8.2 Editar Elemento (rename, imagen, ocultar, mover/copiar)
- UI: `EditElementSheet` (se abre desde context menu / acciones).
- Renombre: `renameFolder(id:newName:)`.
- Imagen: `updateFolderImage(imageData:at:)`.
- Ocultar/Mostrar:
  - Bloqueado si hay un ancestro oculto (“Elemento Protegido”).
  - `toggleFolderHidden(folder:path:)`.
- Mover/Copiar:
  - Genera `MoveCopyOperation` y deriva a `MoveCopySheet`.

### 8.3 Vistas: Lista / Cuadrícula / Galería
En `FolderDetailView`:
- Selector `currentViewType` guardado por carpeta via UserDefaults (`view_<uuid|root>`).
- `FolderDetailListView`:
  - Soporta headers alfabéticos cuando ordenás por nombre.
  - Delete con swipe + “undo toast” (delete diferido 4s).
- `FolderDetailGridView` y `FolderDetailGalleryView`:
  - Delete via confirm alert (sin undo).
- Los tres modos soportan:
  - Context menu: Favorito, Seleccionar, Editar, Ocultar/Mostrar, Eliminar.
  - Modo selección con checkmarks.

### 8.4 Ordenamiento
`SortType` en ViewModel:
- `nameAsc`, `nameDesc`, `dateNewest`, `dateOldest`.
- Persistencia por carpeta: `sort_<uuid|root>` en UserDefaults.
- Normalización para ordenar:
  - `sortName(for:)` recorta whitespaces y hace “The ”-stripping.
  - `sectionLetter(for:)` agrupa headers de secciones, no letras van a `#`.

### 8.5 Favoritos
Persistencia:
- Core Data entity `FolderFavoritesEntity` guarda `folderId` y `folderName`.

Reglas:
- No podés marcar como favorito un elemento oculto ni con ancestro oculto.
- Si ocultás una carpeta:
  - Se remueve de favoritos (y también sus hijos).

UI:
- `FavoritesSheet`:
  - Muestra solo favoritos “válidos” (usa `findPathById` para localizar su path actual).
  - Tapping navega a la ruta completa y resalta el item (`highlightedItemId`).
  - Long press muestra “breadcrumb” invertido (ej: `< Randomitas < ...`).

### 8.6 Ocultar (Hidden)
Persistencia:
- `FolderEntity.isHidden`.

Comportamiento:
- Ocultar es “jerárquico”: si ocultás un padre, no se busca en hijos para listarlos como ocultos (están implícitamente ocultos por el padre).
- Cuando se oculta un padre:
  - Se “desocultan” hijos (su flag) para evitar redundancia, pero igual quedan invisibles por contexto.
  - Se limpian favoritos del padre y descendencia.

UI:
- `HiddenFoldersSheet` lista ocultos navegables.
- `FolderDetailView` tiene un flag `showingHiddenElements` para alternar ver ocultos vs visibles dentro del nivel actual (estado en memoria por path).
- Randomize se bloquea si estás dentro de contexto oculto.

### 8.7 Randomización + Resultado
Operaciones:
- `randomizeCurrentScreen(at:)`: elige un hijo visible del nivel actual (root o carpeta actual).
- `randomizeWithChildren(at:)`: elige entre todo el subárbol (recursivo). Existe en ViewModel pero la UI principal llama `randomizeCurrentScreen()` (modo 1).
- Filtra:
  - Excluye ocultos y elementos con ancestros ocultos.

Historial:
- Cada resultado se guarda en `HistoryEntity` con TTL 24h (`historyLimit = 86400`).
- `HistorySheet` muestra solo entradas “válidas” (el item sigue existiendo y el `folderPath` navega a un folder con `id == itemId`).

UI:
- Botón central “Shuffle” en la barra inferior.
- `ResultSheet`:
  - Muestra detalle del elemento random.
  - Permite: renombrar inline, togglear favorito, setear/eliminar imagen, abrir el elemento, ocultar.
  - Ajusta `presentationDetents` según si hay imagen.

### 8.8 Búsqueda
Dos formas:
- Overlay integrado en `FolderDetailView` (modo búsqueda desde toolbar + bottom search bar).
- Sheet dedicada `SearchSheet` (existe pero el flujo principal usa overlay).

Lógica:
- `viewModel.search(query:)` hace prefix match case-insensitive y devuelve tuplas `(Folder, path, parentNameString)`.

### 8.9 Mover / Copiar (con prevención de ciclos)
UI:
- `MoveCopySheet`: muestra un árbol navegable (root + subcarpetas) y permite elegir destino.
- Recuerda “último destino” solo por 2 minutos con `@AppStorage`:
  - `lastMoveCopyTargetPath`, `lastMoveCopyWasRoot`, `lastMoveCopyTimestamp`.

Validaciones:
- No mover/copiar al mismo contenedor.
- Si move: no permite mover un elemento dentro de sí mismo o su descendencia (ciclo).
- Conflictos por nombre:
  - Si ya existe un elemento con el mismo nombre en el destino, pide confirmación para reemplazar (borra los existentes y luego ejecuta).

Implementación:
- Para robustez en batch, usa versión por ID del destino:
  - `moveFolderById(id:toFolderId:)`
  - `copyFolderById(id:toFolderId:)`
- Copy es recursivo (`copyFolderRecursive`) y resetea `isHidden = false` en el clon.

### 8.10 Selección múltiple (batch)
UI:
- Modo selección se activa desde context menu “Seleccionar”.
- Barra inferior cambia a `selectionActionBar` con acciones:
  - Mover, Copiar, Ocultar/Mostrar, Eliminar.
- Eliminar en batch pide confirmación (`confirmationDialog`).

Operaciones:
- `batchDeleteRootFolders`, `batchDeleteSubfolders`.
- `batchToggleHiddenRoot`, `batchToggleHiddenSubfolders`.

## 9) Cuadro Sinóptico (alto nivel)

### 9.1 Diagrama de arquitectura (Mermaid)
```mermaid
flowchart TD
  App[RandomitasApp @main] --> CV[ContentView]
  CV --> NS[NavigationStack]
  NS --> FDV[FolderDetailView (root o subfolder)]

  FDV -->|reads/writes| VM[RandomitasViewModel]
  VM --> CDS[CoreDataStack]
  CDS -->|NSPersistentContainer| CD[(Core Data Store)]

  FDV -->|sheet| New[NewFolderSheet]
  FDV -->|sheet| Edit[EditElementSheet]
  FDV -->|sheet| Fav[FavoritesSheet]
  FDV -->|sheet| Hist[HistorySheet]
  FDV -->|sheet| Hidden[HiddenFoldersSheet]
  FDV -->|sheet| MoveCopy[MoveCopySheet]
  FDV -->|sheet| Result[ResultSheet]
  FDV -->|overlay| Search[Search Results]

  New --> VM
  Edit --> VM
  Fav --> VM
  Hist --> VM
  Hidden --> VM
  MoveCopy --> VM
  Result --> VM
  Search --> VM

  subgraph UIKit Bridges
    Picker[ImagePickerView (UIImagePickerController)]
    Haptics[HapticManager]
    Perms[PermissionManager]
  end

  New --> Picker
  Edit --> Picker
  Result --> Picker
  Edit --> Haptics
  FDV --> Haptics
  Picker --> Perms
```

### 9.2 Mapa mental (ASCII)
```
Randomitas
|- UI (SwiftUI)
|  |- ContentView (NavigationStack)
|  |- FolderDetailView (pantalla principal)
|  |  |- List/Grid/Gallery
|  |  |- Toolbar (sort/view/history/+ batch)
|  |  |- Bottom bar (hidden/shuffle/favorites) + Search overlay
|  |- Sheets (New, Edit, Result, Favorites, History, Hidden, Move/Copy)
|
|- State/Logic (MVVM)
|  |- RandomitasViewModel
|     |- CRUD folders (root/sub)
|     |- Favorites (UUID-based)
|     |- Hidden (hierarchical)
|     |- Randomize + History (24h)
|     |- Search
|     |- Move/Copy + conflict rules
|     |- Batch selection ops
|
|- Persistence (Core Data)
|  |- CoreDataStack (container/save/refresh)
|  |- Entities: FolderEntity, FolderFavoritesEntity, HistoryEntity
|
|- UIKit helpers
   |- ImagePickerView + PermissionManager
   |- HapticManager
   |- UIImage resize
```

## 10) “Cómo la explico simple” (guion + analogía)

### Analogía rápida
Pensala como un **árbol de carpetas**. Cada carpeta puede tener subcarpetas. En cada nivel podés:
- agregar nuevas carpetas,
- ordenar y cambiar vista,
- ocultar algunas,
- marcar favoritas,
- y apretar “shuffle” para elegir una al azar entre las visibles.

### Guion de 1 minuto
1. La app arranca en `ContentView` con un `NavigationStack` y un `RandomitasViewModel`.
2. La pantalla `FolderDetailView` se reutiliza para root y subcarpetas: recibe un `folderPath` `[Int]`.
3. El ViewModel carga el árbol desde Core Data y lo expone como structs `Folder` (para que SwiftUI dibuje rápido).
4. Las acciones del usuario (crear, editar, ocultar, favorito, mover/copiar, randomizar) llaman al ViewModel, que actualiza Core Data y luego recarga el árbol.
5. Randomizar guarda un `HistoryEntry` y muestra un `ResultSheet` con acciones rápidas.

## 11) Prácticas de estudio (para dominarla)

### Orden recomendado de lectura (en 60-90 minutos)
1. `Randomitas/RandomitasApp.swift` y `Randomitas/Views/ContentView.swift` (entrada + navegación).
2. `Randomitas/Views/FolderDetail/FolderDetailView.swift` (hub de UI y flujos).
3. `Randomitas/ViewModels/RandomitasViewModel.swift` (reglas y persistencia).
4. `Randomitas/CoreData/CoreDataStack.swift` + `Randomitas/Randomitas.xcdatamodeld/.../contents` (modelo y stack).
5. `Sheets/` (cada feature como flujo aislado).
6. `FolderDetailList/Grid/Gallery` (variantes de UI).
7. Tests: `RandomitasTests/*` y `RandomitasUITests/*` (intención y regresiones).

### Ejercicios prácticos (estilo entrevista)
- Explicá por qué existe `rootFolder` virtual y qué simplifica en la UI.
- Señalá el riesgo de usar `[Int]` como path y cómo se compensa con `UUID` + `findPathById`.
- Proponé cómo agregarías “randomize with children” a la UI (ya existe en ViewModel).
- Identificá el motivo de guardar `newFolderId` antes de `refresh()` en `addRootFolder`/`addSubfolder`.
- Mostrá dónde se persisten preferencias de orden y vista por carpeta (`sort_<id>` / `view_<id>`).
- Describí el comportamiento de “ocultar” y por qué se limpian favoritos.

### Checklist para “entender de verdad”
- Podés dibujar el flujo: `Shuffle -> ViewModel -> HistoryEntity -> ResultSheet -> Navigate`.
- Podés enumerar todas las hojas modales y qué estado las dispara.
- Podés explicar las operaciones batch y su diferencia root/subfolder.
- Sabés qué se persiste en Core Data vs qué queda en memoria/UserDefaults.

## 12) Apéndice: Referencias de código (archivos clave)

- Entrada:
  - `Randomitas/RandomitasApp.swift`
  - `Randomitas/Views/ContentView.swift`
- Pantalla principal:
  - `Randomitas/Views/FolderDetail/FolderDetailView.swift`
  - `Randomitas/Views/FolderDetail/FolderDetailListView.swift`
  - `Randomitas/Views/FolderDetail/FolderDetailGridView.swift`
  - `Randomitas/Views/FolderDetail/FolderDetailGalleryView.swift`
- Estado/negocio:
  - `Randomitas/ViewModels/RandomitasViewModel.swift`
- Persistencia:
  - `Randomitas/CoreData/CoreDataStack.swift`
  - `Randomitas/Randomitas.xcdatamodeld/Randomitas.xcdatamodel/contents`
- Sheets:
  - `Randomitas/Sheets/NewFolderSheet.swift`
  - `Randomitas/Sheets/EditElementSheet.swift`
  - `Randomitas/Sheets/MoveCopySheet.swift`
  - `Randomitas/Sheets/FavoritesSheet.swift`
  - `Randomitas/Sheets/HiddenFoldersSheet.swift`
  - `Randomitas/Sheets/HistorySheet.swift`
  - `Randomitas/Sheets/ResultSheet.swift`
  - `Randomitas/Sheets/SearchSheet.swift`
- Utilidades:
  - `Randomitas/Utils/PermissionManager.swift`
  - `Randomitas/Utils/HapticManager.swift`
  - `Randomitas/Utils/UIImage+Extensions.swift`
  - `Randomitas/Views/ImagesEditor/ImagePickerView.swift`
- Tests:
  - `RandomitasTests/FavoritesAndPathTests.swift`
  - `RandomitasTests/SelectionModeTests.swift`
  - `RandomitasUITests/BatchAddModeUITests.swift`

## 13) Apéndice: Claves Persistentes (UserDefaults / AppStorage)

### UserDefaults (directo)
- `HasCleanedDatabaseForFoldersOnly`
  - Vive en `CoreDataStack.cleanDatabaseIfNeeded()`.
  - Controla la limpieza one-shot de la base de datos.
- `sort_<folderId|root>`
  - Vive en `RandomitasViewModel.getSortType/setSortType`.
  - Persistencia del orden por carpeta (o `root`).
- `view_<folderId|root>`
  - Vive en `RandomitasViewModel.getViewType/setViewType`.
  - Persistencia del tipo de vista por carpeta (o `root`).

### @AppStorage
- `lastMoveCopyTargetPath`
- `lastMoveCopyWasRoot`
- `lastMoveCopyTimestamp`
  - Viven en `MoveCopySheet`.
  - Implementan una “memoria temporal” (2 minutos) del último destino elegido.

### Estado en memoria (no persiste entre lanzamientos)
- `hiddenElementsViewState: [String: Bool]` en `RandomitasViewModel`
  - Recuerda si estás “viendo ocultos” o “viendo visibles” por path (clave = indices unidos por `_`).
