# Offline-First Authorization — Plan de Implementación

## Objetivo

Habilitar login offline sin necesidad de haber iniciado sesión online antes. Para eso: (1) migrar tablas de permisos de user DB → shared DB, (2) precargar usuarios completos (con password hash) vía descarga admin, (3) login offline consulta shared DB.

---

## Convenciones de edición

- Código nuevo sin comentarios (salvo casos excepcionales documentados aquí).
- Usar `operador_id` donde shared DB usa FK a `operadores`.
- Usar `codigo_dni` donde la tabla referencia al DNI del usuario.
- `flutter analyze` debe quedar limpio (0 errors) al final de cada fase.

---

## Fase 1: Schema — Shared DB v18

**Archivo:** `lib/config/data/database_helper.dart`

### 1.1 Bump version

```dart
// Línea actual ~65
static const int _sharedCatalogDbVersion = 17;
// → Cambiar a:
static const int _sharedCatalogDbVersion = 18;
```

### 1.2 `_onCreateSharedCatalogDatabase` — incluir `usuario_equipos`

Buscar el bloque de CREATE TABLE `usuario_directorio` (~línea 550 aprox) y **agregar `cargo_id` + `password`** a las columnas:

```dart
await db.execute('''
CREATE TABLE usuario_directorio (
  codigo_dni TEXT PRIMARY KEY,
  operador_id INTEGER,
  nombres TEXT NOT NULL,
  apellidos TEXT NOT NULL,
  rol TEXT,
  cargo_id INTEGER,
  password TEXT,
  updated_at TEXT NOT NULL
)
''');
```

Luego, **después** de `usuario_directorio` (y antes de `cargos` si `cargos` ya existe), agregar:

```dart
await db.execute('''
CREATE TABLE usuario_equipos (
  usuarios_id INTEGER NOT NULL,
  proceso_id INTEGER NOT NULL,
  equipo_id INTEGER NOT NULL
)
''');
```

### 1.3 `_onUpgradeSharedCatalogDatabase` — agregar v17→v18

Buscar el `_onUpgradeSharedCatalogDatabase` y agregar un case `17` (o un if/switch):

```dart
if (oldVersion < 18) {
  await db.execute('ALTER TABLE usuario_directorio ADD COLUMN cargo_id INTEGER');
  await db.execute('ALTER TABLE usuario_directorio ADD COLUMN password TEXT');
  await db.execute('''
    CREATE TABLE usuario_equipos (
      usuarios_id INTEGER NOT NULL,
      proceso_id INTEGER NOT NULL,
      equipo_id INTEGER NOT NULL
    )
  ''');
}
```

---

## Fase 2: Schema — User DB v28

**Archivo:** `lib/config/data/database_helper.dart`

### 2.1 Bump version

```dart
// Línea actual ~62
static const int _currentDbVersion = 27;
// → Cambiar a:
static const int _currentDbVersion = 28;
```

### 2.2 `_onUpgrade` — agregar v27→v28

Buscar el `_onUpgrade` del user DB y agregar:

```dart
if (oldVersion < 28) {
  await db.execute('DROP TABLE IF EXISTS UsuarioEquipo');
}
```

### 2.3 `_onCreate` — remover `UsuarioEquipo`

En el `_onCreate` del user DB, buscar y eliminar:

```dart
await db.execute('''
CREATE TABLE UsuarioEquipo (
  codigo_dni TEXT NOT NULL,
  proceso_id INTEGER NOT NULL,
  equipo_id INTEGER NOT NULL,
  FOREIGN KEY (codigo_dni) REFERENCES Usuario (codigo_dni)
)
''');
```

### 2.4 `_onUpgrade` — limpiar migraciones antiguas

Buscar en `_onUpgrade` del user DB la línea:

```dart
if (oldVersion < 27) {
  await db.execute('DROP TABLE IF EXISTS UsuarioProceso');
}
```

y removerla (ya no es necesaria porque `UsuarioProceso` se eliminó en v27, y v27 ya está en producción). Si se quiere mantener por compatibilidad, se puede dejar pero no es necesario — la tabla ya no existe.

---

## Fase 3: Renombrar `saveUserProfileSnapshot` → `syncAuthorizationData`

**Archivo:** `lib/config/data/database_helper.dart`

### 3.1 Renombrar método

Buscar:

```dart
Future<void> saveUserProfileSnapshot({
```

y cambiar a:

```dart
Future<void> syncAuthorizationData({
```

Cambiar también el comentario/docblock si existe.

### 3.2 Actualizar callers

1. **`lib/screens/login/login_screen.dart`** — buscar `saveUserProfileSnapshot` y cambiar a `syncAuthorizationData`.

2. **`lib/services/user_service.dart`** — buscar `saveUserProfileSnapshot` y cambiar a `syncAuthorizationData`.

3. **`test/...`** — si hay tests que llaman al método, actualizar.

### 3.3 Actualizar `syncOfflineProfileSnapshot` en `user_service.dart`

Buscar:

```dart
await _dbHelper.saveUserProfileSnapshot(
```

y cambiar a:

```dart
await _dbHelper.syncAuthorizationData(
```

---

## Fase 4: `syncAuthorizationData` — escribir `usuario_equipos` a shared DB

**Archivo:** `lib/config/data/database_helper.dart`

### 4.1 Reemplazar escritura de `UsuarioEquipo`

Dentro de `syncAuthorizationData`, buscar el bloque que escribe en `UsuarioEquipo`. Se ve similar a:

```dart
// Limpiar y reinsertar UsuarioEquipo
await db.delete('UsuarioEquipo', where: 'codigo_dni = ?', whereArgs: [dni]);
for (final equipo in equipoIds) {
  await db.insert('UsuarioEquipo', {
    'codigo_dni': dni,
    'proceso_id': equipo['proceso_id'],
    'equipo_id': equipo['equipo_id'],
  });
}
```

Eliminar ese bloque y reemplazarlo con escritura a shared DB usando `usuarios_id`:

```dart
// Limpiar y reinsertar usuario_equipos en shared DB
final sharedDb = await sharedCatalogDatabase;
await sharedDb.delete('usuario_equipos', where: 'usuarios_id = ?', whereArgs: [operadorId]);
for (final equipo in equipoIds) {
  await sharedDb.insert('usuario_equipos', {
    'usuarios_id': operadorId,
    'proceso_id': equipo['proceso_id'],
    'equipo_id': equipo['equipo_id'],
  });
}
```

**Nota:** Necesitas `operadorId`. Este método ya recibe `operador_id` como parámetro. Si no está disponible dentro del scope, pasar el valor desde el caller.

### 4.2 Verificar que `operador_id` se pase correctamente

En el caller (`user_service.dart` o `login_screen.dart`), asegurar que `syncAuthorizationData` reciba `operador_id`:

```dart
await _dbHelper.syncAuthorizationData(
  dni: dni,
  operadorId: userData.operadorId,  // o como se llame
  ...
);
```

---

## Fase 5: `OfflineAuthorizationRepository.getAuthorizedEquipoIds` → shared DB

**Archivo:** `lib/config/data/offline_authorization_repository.dart`

### 5.1 Actualizar método

Buscar `getAuthorizedEquipoIds`. Debe verse similar a:

```dart
Future<List<Map<String, dynamic>>> getAuthorizedEquipoIds(String dni) async {
  final db = await _dbHelper.database;
  final result = await db.query(
    'UsuarioEquipo',
    where: 'codigo_dni = ?',
    whereArgs: [dni],
  );
  return result;
}
```

Reemplazar con consulta a shared DB usando `_getOperadorId(dni)`:

```dart
Future<List<Map<String, dynamic>>> getAuthorizedEquipoIds(String dni) async {
  final operadorId = await _getOperadorId(dni);
  final db = await _dbHelper.sharedCatalogDatabase;
  final result = await db.query(
    'usuario_equipos',
    where: 'usuarios_id = ?',
    whereArgs: [operadorId],
  );
  return result;
}
```

---

## Fase 6: `loginOffline` — consultar shared DB primero

**Archivo:** `lib/config/data/database_helper.dart`

### 6.1 Reemplazar implementación

Buscar:

```dart
Future<bool> loginOffline(String dni, String password) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> result = await db.query(
      'Usuario',
      where: 'codigo_dni = ?',
      whereArgs: [dni],
    );

    if (result.isNotEmpty) {
      final storedPassword = result.first['password'];
      return Crypt(storedPassword).match(password);
    }

    return false;
  }
```

Reemplazar con:

```dart
Future<bool> loginOffline(String dni, String password) async {
    // 1. Shared DB: usuario_directorio (admin pre-cargó usuarios)
    try {
      final sharedDb = await sharedCatalogDatabase;
      final rows = await sharedDb.query(
        'usuario_directorio',
        columns: ['password'],
        where: 'codigo_dni = ?',
        whereArgs: [dni],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final hash = rows.first['password'] as String?;
        if (hash != null && hash.isNotEmpty) {
          if (Crypt(hash).match(password)) {
            // Asegurar que existe user DB con Usuario row
            await setCurrentUserDni(dni);
            final db = await database;
            final existing = await db.query(
              'Usuario',
              where: 'codigo_dni = ?',
              whereArgs: [dni],
              limit: 1,
            );
            if (existing.isEmpty) {
              await db.insert('Usuario', {
                'codigo_dni': dni,
                'password': hash,
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              });
            }
            return true;
          }
        }
        return false;
      }
    } catch (_) {
      // shared DB no disponible — seguir con fallback
    }

    // 2. Fallback: user DB (legacy, primer inicio sin descarga admin)
    try {
      final db = await DatabaseHelper().database;
      final result = await db.query(
        'Usuario',
        where: 'codigo_dni = ?',
        whereArgs: [dni],
      );
      if (result.isNotEmpty) {
        final storedPassword = result.first['password'];
        return Crypt(storedPassword).match(password);
      }
    } catch (_) {}

    return false;
  }
```

---

## Fase 7: API Services

### 7.1 Crear `lib/services/get nube/llamadas/api_service_usuario_directorio.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/database_helper.dart';

class ApiServiceUsuarioDirectorio {
  final _apiConfig = ApiConfig();
  final _dbHelper = DatabaseHelper();

  Future<List<Map<String, dynamic>>> fetchAll() async {
    final url = '${_apiConfig.baseUrl()}${_apiConfig.usuarioDirectorioEndpoint}';
    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer ${_apiConfig.getToken()}',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Error fetching usuarios: ${response.statusCode}');
  }

  Future<void> saveToSharedDb(List<Map<String, dynamic>> usuarios) async {
    final db = await _dbHelper.sharedCatalogDatabase;
    final batch = db.batch();

    // Limpiar y reinsertar
    batch.delete('usuario_directorio');
    for (final u in usuarios) {
      batch.insert('usuario_directorio', {
        'codigo_dni': u['codigo_dni']?.toString() ?? '',
        'operador_id': u['operador_id'],
        'nombres': u['nombres'] ?? '',
        'apellidos': u['apellidos'] ?? '',
        'rol': u['rol'],
        'cargo_id': u['cargo_id'],
        'password': u['password'],
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit(noResult: true);
  }
}
```

**Registrar endpoint en `lib/config/api/api_config.dart`:**

```dart
String get usuarioDirectorioEndpoint => '/usuarios';
```

### 7.2 Crear `lib/services/get nube/llamadas/api_service_usuario_equipos.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:i_miner/config/api/api_config.dart';
import 'package:i_miner/config/data/database_helper.dart';

class ApiServiceUsuarioEquipos {
  final _apiConfig = ApiConfig();
  final _dbHelper = DatabaseHelper();

  Future<List<Map<String, dynamic>>> fetchAll() async {
    final url = '${_apiConfig.baseUrl()}${_apiConfig.usuarioEquiposEndpoint}';
    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer ${_apiConfig.getToken()}',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Error fetching usuario_equipos: ${response.statusCode}');
  }

  Future<void> saveToSharedDb(List<Map<String, dynamic>> equipos) async {
    final db = await _dbHelper.sharedCatalogDatabase;
    final batch = db.batch();

    batch.delete('usuario_equipos');
    for (final e in equipos) {
      batch.insert('usuario_equipos', {
        'usuarios_id': e['usuarios_id'],
        'proceso_id': e['proceso_id'],
        'equipo_id': e['equipo_id'],
      });
    }

    await batch.commit(noResult: true);
  }
}
```

**Registrar endpoint en `lib/config/api/api_config.dart`:**

```dart
String get usuarioEquiposEndpoint => '/usuarios-equipos';
```

---

## Fase 8: `HorizontalCatalogRepository` — nuevos métodos

**Archivo:** `lib/config/data/horizontal_catalog_repository.dart`

Agregar imports:

```dart
import 'package:i_miner/services/get%20nube/llamadas/api_service_usuario_directorio.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_usuario_equipos.dart';
```

Agregar métodos:

```dart
Future<ActualizacionResult> refreshUsuarios() async {
  return _ejecutarActualizacion(
    'Usuarios',
    () async {
      final api = ApiServiceUsuarioDirectorio();
      final data = await api.fetchAll();
      await api.saveToSharedDb(data);
    },
  );
}

Future<ActualizacionResult> refreshUsuarioEquipos() async {
  return _ejecutarActualizacion(
    'Equipos por usuario',
    () async {
      final api = ApiServiceUsuarioEquipos();
      final data = await api.fetchAll();
      await api.saveToSharedDb(data);
    },
  );
}
```

---

## Fase 9: `ActualizacionService` — registrar nuevos requests

**Archivo:** `lib/services/get nube/actualizacion_service.dart`

### 9.1 Registrar en `_requests`

Buscar donde se agregan `_requests['Cargos']` y `_requests['Autorizaciones']`. Agregar:

```dart
_requests['Usuarios'] = _crearRequest(
  nombre: 'Usuarios',
  descripcion: 'Directorio de usuarios con cargos y contraseñas',
  funcion: (_, __) => _horizontalCatalogRepository.refreshUsuarios(),
  requiereDni: false,
);

_requests['Equipos por usuario'] = _crearRequest(
  nombre: 'Equipos por usuario',
  descripcion: 'Permisos de equipos por usuario',
  funcion: (_, __) => _horizontalCatalogRepository.refreshUsuarioEquipos(),
  requiereDni: false,
);
```

---

## Fase 10: `reporte_sreen.dart` — nuevas opciones

**Archivo:** `lib/screens/Dash/reporte_sreen.dart`

### 10.1 Agregar a `opcionesDisponibles`

Buscar el mapa `opcionesDisponibles` (es un `Map<String, bool>` que define qué opciones se muestran en la UI). Agregar:

```dart
'Usuarios': true,
'Equipos por usuario': true,
```

### 10.2 (Opcional) Ajustar orden

Si el orden importa en la UI, poner estas opciones después de `Cargos` o al final de la sección de catálogos.

---

## Fase 11: Tests

### 11.1 Actualizar test de `database_helper.dart`

Agregar tests para:
- Shared DB v18 migration (columnas nuevas, tabla nueva)
- User DB v28 migration (DROP UsuarioEquipo)
- `loginOffline` con shared DB
- `syncAuthorizationData` con shared DB + usuario_equipos

### 11.2 Actualizar test de `OfflineAuthorizationRepository`

- `getAuthorizedEquipoIds` con shared DB

---

## Fase 12: Verificación final

```bash
flutter analyze
flutter test
```

Si `flutter analyze` marca warnings de imports con espacios, esos son preexistentes y aceptables.

---

## Resumen de archivos modificados

| Archivo | Cambio |
|---------|--------|
| `lib/config/data/database_helper.dart` | Shared v18, user v28, rename method, loginOffline shared-first |
| `lib/config/data/offline_authorization_repository.dart` | getAuthorizedEquipoIds → shared DB |
| `lib/config/data/horizontal_catalog_repository.dart` | refreshUsuarios, refreshUsuarioEquipos |
| `lib/config/api/api_config.dart` | +usuarioDirectorioEndpoint, +usuarioEquiposEndpoint |
| `lib/services/user_service.dart` | Rename caller |
| `lib/services/get nube/actualizacion_service.dart` | +Usuarios, +Equipos por usuario |
| `lib/services/get nube/llamadas/api_service_usuario_directorio.dart` | **NUEVO** |
| `lib/services/get nube/llamadas/api_service_usuario_equipos.dart` | **NUEVO** |
| `lib/screens/Dash/reporte_sreen.dart` | +opciones |
| `lib/screens/login/login_screen.dart` | Rename caller |
| `test/...` | Actualizar |

---

## Notas de implementación

- **`Crypt`** del paquete `crypt` — `Crypt(hash).match(password)` retorna `bool`. El hash debe estar en formato compatible (ej: `\$2y\$...` para bcrypt). La API devuelve passwords ya en ese formato.
- **`batch.insert` vs `batch.insertAll`**: Usar `batch.insert` en loop porque los datos vienen como `List<Map>`.
- **`_ejecutarActualizacion`** en `HorizontalCatalogRepository` ya maneja try/catch y retorna `ActualizacionResult`. Solo implementar el callback.
- Los imports con `%20` (espacios) en los paths son preexistentes — mantenerlos.
