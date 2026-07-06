import 'dart:convert';
import 'dart:io';
import 'package:i_miner/models/Accesorio.dart';
import 'package:i_miner/models/DimPeriodo.dart';
import 'package:i_miner/models/DimMina.dart';
import 'package:i_miner/models/DimZona.dart';
import 'package:i_miner/models/DimArea.dart';
import 'package:i_miner/models/DimFase.dart';
import 'package:i_miner/models/DimTipoLabor.dart';
import 'package:i_miner/models/DimEstructuraMineral.dart';
import 'package:i_miner/models/DimNivel.dart';
import 'package:i_miner/models/DimAla.dart';
import 'package:i_miner/models/DimLabor.dart';
import 'package:i_miner/models/DimTurno.dart';
import 'package:i_miner/models/JefeGuardia.dart';
import 'package:i_miner/models/plan_metraje_tl.dart';
import 'package:i_miner/models/plan_avance_th.dart';
import 'package:i_miner/models/plan_produccion.dart';
import 'package:i_miner/models/zona.dart';

import 'package:bcrypt/bcrypt.dart';
import 'package:i_miner/models/guardia.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:i_miner/models/Equipo.dart';
import 'package:i_miner/models/tipo_horometro.dart';
import 'package:i_miner/models/EquipoHorometroTipo.dart';
import 'package:i_miner/models/TipoPerforacion.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;
  static String? _databasePathOverride;
  static const int _sharedCatalogDbVersion = 37;
  static Database? _sharedCatalogDatabase;
  static String? _currentUserDni;
  static bool _isInitialized = false;
  static const int _currentDbVersion = 32;

  DatabaseHelper._internal() {
    // Inicialización única para evitar múltiples llamadas
    if (!_isInitialized) {
      _initializeDatabaseFactory();
      _isInitialized = true;
    }
  }

  /// Inicializa el database factory según la plataforma
  static void _initializeDatabaseFactory() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<void> setCurrentUserDni(String dni) async {
    _currentUserDni = dni;
    await _sharedCatalogDatabase?.close();
    _sharedCatalogDatabase = null;
    _database = await _initDatabase();
  }

  Future<String?> getCurrentUserDni() async {
    return _currentUserDni;
  }

  /// Obtiene la instancia de la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    if (_currentUserDni == null) {
      throw Exception('DNI de usuario no establecido');
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> get sharedCatalogDatabase async {
    if (_sharedCatalogDatabase != null) return _sharedCatalogDatabase!;
    _sharedCatalogDatabase = await _initSharedCatalogDatabase();
    return _sharedCatalogDatabase!;
  }

  /// Inicializa la base de datos
  Future<Database> _initDatabase() async {
    Directory documentsDirectory;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        documentsDirectory = await getApplicationDocumentsDirectory();
      } else {
        // Para Windows/Linux/MacOS
        documentsDirectory = await getApplicationSupportDirectory();
        // Alternativa: Guardar en AppData
        // documentsDirectory = Directory(join(Platform.environment['APPDATA']!, 'Seminco'));
      }

      if (!await documentsDirectory.exists()) {
        await documentsDirectory.create(recursive: true);
      }

      String path = join(
        documentsDirectory.path,
        'Seminco_db_catalina_huanca_${_currentUserDni!}.db',
      );

      return await openDatabase(
        path,
        version: _currentDbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onOpen: (db) async {},
      );
    } catch (e) {
      print('Error al inicializar la base de datos: $e');
      rethrow;
    }
  }

  Future<Database> _initSharedCatalogDatabase() async {
    try {
      Directory documentsDirectory;

      if (_databasePathOverride != null) {
        final sharedPath = join(
          dirname(_databasePathOverride!),
          'Seminco_shared_catalogs.db',
        );
        return await openDatabase(
          sharedPath,
          version: _sharedCatalogDbVersion,
          onCreate: _onCreateSharedCatalogDatabase,
          onUpgrade: _onUpgradeSharedCatalogDatabase,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
        );
      }

      if (Platform.isAndroid || Platform.isIOS) {
        documentsDirectory = await getApplicationDocumentsDirectory();
      } else {
        documentsDirectory = await getApplicationSupportDirectory();
      }

      if (!await documentsDirectory.exists()) {
        await documentsDirectory.create(recursive: true);
      }

      final path = join(documentsDirectory.path, 'Seminco_shared_catalogs.db');

      return await openDatabase(
        path,
        version: _sharedCatalogDbVersion,
        onCreate: _onCreateSharedCatalogDatabase,
        onUpgrade: _onUpgradeSharedCatalogDatabase,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (e) {
      print('Error al inicializar la base de catálogos compartidos: $e');
      rethrow;
    }
  }

  Future<void> _onCreateSharedCatalogDatabase(Database db, int version) async {
    await db.execute('''
CREATE TABLE Equipo (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  proceso_id INTEGER,
  nombre TEXT,
  proceso TEXT,
  codigo TEXT,
  marca TEXT,
  modelo TEXT,
  serie TEXT,
  tipo TEXT,
  capasidad TEXT,
  anioFabricacion INTEGER,
  fechaIngreso TEXT,
  capacidadYd3 REAL,
  capacidadM3 REAL,
  ultimos_horometros TEXT
)
''');

    await db.execute('''
CREATE TABLE tipo_horometro (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE equipo_horometro_tipos (
  equipo_id INTEGER NOT NULL,
  equipo_nombre TEXT,
  tipo_horometro_id INTEGER NOT NULL,
  tipo_horometro_nombre TEXT,
  PRIMARY KEY (equipo_id, tipo_horometro_id)
)
''');

    await db.execute('''
CREATE TABLE Guardia (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  guardia TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE jefe_guardias (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombres TEXT NOT NULL,
  apellidos TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE usuario_directorio (
  codigo_dni TEXT PRIMARY KEY,
  id INTEGER,
  nombres TEXT NOT NULL,
  apellidos TEXT NOT NULL,
  rol TEXT,
  cargo TEXT,
  empresa TEXT,
  guardia TEXT,
  autorizado_equipo TEXT,
  area TEXT,
  clasificacion TEXT,
  correo TEXT,
  firma TEXT,
  cargo_id INTEGER,
  password TEXT,
  createdAt TEXT,
  updated_at TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE dim_periodo (
  periodo_id INTEGER PRIMARY KEY,
  tipo TEXT NOT NULL,
  numero INTEGER NOT NULL,
  anno INTEGER NOT NULL,
  fecha_inicio TEXT NOT NULL,
  fecha_fin TEXT NOT NULL,
  created_at TEXT
)
''');

    await db.execute('''
CREATE TABLE PlanMetrajeTL (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  planMetrajeTlId INTEGER NOT NULL UNIQUE,
  labor_id INTEGER NOT NULL,
  periodo_id INTEGER NOT NULL,
  ancho_veta_metros REAL NOT NULL,
  ancho_minado_sem_metros REAL NOT NULL,
  ancho_minado_mes_metros REAL NOT NULL,
  mina_id INTEGER NOT NULL,
  zona_id INTEGER NOT NULL,
  area_id INTEGER NOT NULL,
  fase_id INTEGER NOT NULL,
  tipo_labor_id INTEGER NOT NULL,
  estructura_mineral_id INTEGER NOT NULL,
  nivel_id INTEGER NOT NULL,
  ala_id INTEGER NOT NULL,
  labor_nombre TEXT NOT NULL,
  mina_nombre TEXT NOT NULL,
  zona_nombre TEXT NOT NULL,
  area_nombre TEXT NOT NULL,
  fase_nombre TEXT NOT NULL,
  tipo_labor_nombre TEXT NOT NULL,
  estructura_mineral_nombre TEXT NOT NULL,
  nivel_nombre TEXT NOT NULL,
  ala_nombre TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT
)
''');

    // v9 tables
    await db.execute('''
CREATE TABLE IF NOT EXISTS minas (
  mina_id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  codigo TEXT,
  ubicacion TEXT,
  estado TEXT
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS zona (
  zona_id INTEGER PRIMARY KEY,
  mina_id INTEGER,
  nombre TEXT NOT NULL,
  codigo TEXT,
  estado TEXT,
  FOREIGN KEY (mina_id) REFERENCES minas(mina_id)
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS area (
  area_id INTEGER PRIMARY KEY,
  zona_id INTEGER,
  nombre TEXT NOT NULL,
  codigo TEXT,
  estado TEXT,
  FOREIGN KEY (zona_id) REFERENCES zona(zona_id)
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS fase (
  fase_id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  codigo TEXT,
  descripcion TEXT,
  estado TEXT
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS tipo_labor (
  tipo_labor_id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  codigo TEXT,
  descripcion TEXT,
  estado TEXT
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS estructura_mineral (
  estructura_mineral_id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  codigo TEXT,
  caracteristicas TEXT,
  estado TEXT
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS nivel (
  nivel_id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  numero INTEGER,
  profundidad_promedio REAL,
  estado TEXT
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS ala (
  ala_id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  codigo TEXT,
  orden INTEGER,
  estado TEXT
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS labores (
  labor_id INTEGER PRIMARY KEY,
  mina_id INTEGER,
  zona_id INTEGER,
  area_id INTEGER,
  fase_id INTEGER,
  tipo_labor_id INTEGER,
  estructura_mineral_id INTEGER,
  nivel_id INTEGER,
  ala_id INTEGER,
  nombre_labor TEXT NOT NULL,
  estado TEXT,
  mina_nombre TEXT,
  zona_nombre TEXT,
  area_nombre TEXT,
  fase_nombre TEXT,
  tipo_labor_nombre TEXT,
  estructura_mineral_nombre TEXT,
  nivel_nombre TEXT,
  ala_nombre TEXT,
  created_at TEXT,
  updated_at TEXT,
  created_by TEXT,
  updated_by TEXT,
  FOREIGN KEY (mina_id) REFERENCES minas(mina_id),
  FOREIGN KEY (zona_id) REFERENCES zona(zona_id),
  FOREIGN KEY (area_id) REFERENCES area(area_id),
  FOREIGN KEY (fase_id) REFERENCES fase(fase_id),
  FOREIGN KEY (tipo_labor_id) REFERENCES tipo_labor(tipo_labor_id),
  FOREIGN KEY (estructura_mineral_id) REFERENCES estructura_mineral(estructura_mineral_id),
  FOREIGN KEY (nivel_id) REFERENCES nivel(nivel_id),
  FOREIGN KEY (ala_id) REFERENCES ala(ala_id)
)
''');

    // v10 table
    await db.execute('''
CREATE TABLE IF NOT EXISTS dim_turno (
  turno_id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  codigo TEXT,
  horario_inicio TEXT,
  horario_fin TEXT
)
''');

    // v11 table
    await db.execute('''
CREATE TABLE IF NOT EXISTS procesos (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  nombre_abreviado TEXT
)
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS destinos (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  proceso_id INTEGER NOT NULL
)
''');

    // v12 tables
    await db.execute('''
CREATE TABLE IF NOT EXISTS planes_metrajes_avances (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_metraje_avance_id INTEGER NOT NULL,
  labor_id INTEGER NOT NULL,
  periodo_id INTEGER NOT NULL,
  avance_metros REAL NOT NULL,
  ancho_metros REAL NOT NULL,
  alto_metros REAL NOT NULL,
  tms REAL NOT NULL,
  mina_id INTEGER NOT NULL,
  zona_id INTEGER NOT NULL,
  area_id INTEGER NOT NULL,
  fase_id INTEGER NOT NULL,
  tipo_labor_id INTEGER NOT NULL,
  estructura_mineral_id INTEGER NOT NULL,
  nivel_id INTEGER NOT NULL,
  ala_id INTEGER NOT NULL,
  labor_nombre TEXT NOT NULL,
  mina_nombre TEXT NOT NULL,
  zona_nombre TEXT NOT NULL,
  area_nombre TEXT NOT NULL,
  fase_nombre TEXT NOT NULL,
  tipo_labor_nombre TEXT NOT NULL,
  estructura_mineral_nombre TEXT NOT NULL,
  nivel_nombre TEXT NOT NULL,
  ala_nombre TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS planes_produccion (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_produccion_id INTEGER NOT NULL,
  labor_id INTEGER NOT NULL,
  periodo_id INTEGER NOT NULL,
  ancho_veta_metros REAL NOT NULL,
  ancho_minado_sem_metros REAL NOT NULL,
  ancho_minado_mes_metros REAL NOT NULL,
  ag_gr REAL NOT NULL,
  porcentaje_cu REAL NOT NULL,
  porcentaje_pb REAL NOT NULL,
  porcentaje_zn REAL NOT NULL,
  vpt_actual REAL NOT NULL,
  vpt_final REAL NOT NULL,
  cut_off_1 REAL NOT NULL,
  cut_off_2 REAL NOT NULL,
  mina_id INTEGER NOT NULL,
  zona_id INTEGER NOT NULL,
  area_id INTEGER NOT NULL,
  fase_id INTEGER NOT NULL,
  tipo_labor_id INTEGER NOT NULL,
  estructura_mineral_id INTEGER NOT NULL,
  nivel_id INTEGER NOT NULL,
  ala_id INTEGER NOT NULL,
  labor_nombre TEXT NOT NULL,
  mina_nombre TEXT NOT NULL,
  zona_nombre TEXT NOT NULL,
  area_nombre TEXT NOT NULL,
  fase_nombre TEXT NOT NULL,
  tipo_labor_nombre TEXT NOT NULL,
  estructura_mineral_nombre TEXT NOT NULL,
  nivel_nombre TEXT NOT NULL,
  ala_nombre TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT
)
''');

    // v14 table
    await db.execute('''
CREATE TABLE IF NOT EXISTS tipo_perforaciones (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  proceso TEXT NULL,
  permitido_medicion INTEGER NOT NULL DEFAULT 0,
  proceso_id INTEGER
)
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS checklist_items (
  id INTEGER PRIMARY KEY,
  proceso_id INTEGER,
  proceso TEXT NOT NULL,
  categoria_id INTEGER,
  categoria TEXT NOT NULL,
  nombre TEXT NOT NULL,
  orden INTEGER,
  categoria_orden INTEGER
)
''');

    // v17 tables
    await db.execute('''
CREATE TABLE IF NOT EXISTS usuario_procesos (
  usuarios_id INTEGER NOT NULL,
  proceso_id INTEGER NOT NULL,
  PRIMARY KEY (usuarios_id, proceso_id)
)
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS cargos (
  cargo_id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL
)
''');

    // v19: tablas movidas desde user DB
    await db.execute('''
CREATE TABLE longitud_barras (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  proceso TEXT NOT NULL,
  longitud_pies REAL NOT NULL
)
''');

    await db.execute('''
CREATE TABLE pernos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tipo_perno TEXT NOT NULL,
  longitud REAL NOT NULL
)
''');

    await db.execute('''
CREATE TABLE mallas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tipo_malla TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS estados (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  codigo TEXT NOT NULL,
  tipo_estado TEXT NOT NULL,
  categoria TEXT NOT NULL,
  proceso TEXT NOT NULL,
  proceso_id INTEGER,
  categoria_id INTEGER
)
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS categorias_estados (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  activo INTEGER NOT NULL DEFAULT 1
)
''');
  }

  Future<void> _onUpgradeSharedCatalogDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 1) {
      await _onCreateSharedCatalogDatabase(db, newVersion);
    }

    if (oldVersion < 2) {
      if (!await _tablaExiste(db, 'usuario_directorio')) {
        await db.execute('''
CREATE TABLE usuario_directorio (
  codigo_dni TEXT PRIMARY KEY,
  id INTEGER,
  nombres TEXT NOT NULL,
  apellidos TEXT NOT NULL,
  rol TEXT,
  cargo_id INTEGER,
  password TEXT,
  updated_at TEXT NOT NULL
)
''');
      }
    }

    if (oldVersion < 3) {
      if (!await _columnaExiste(db, 'Seccion', 'mina_id')) {
        await db.execute('ALTER TABLE Seccion ADD COLUMN mina_id INTEGER');
      }
      if (!await _columnaExiste(db, 'Seccion', 'codigo')) {
        await db.execute('ALTER TABLE Seccion ADD COLUMN codigo TEXT');
      }
      if (!await _columnaExiste(db, 'Seccion', 'estado')) {
        await db.execute('ALTER TABLE Seccion ADD COLUMN estado TEXT');
      }
    }

    if (oldVersion < 4) {
      if (!await _columnaExiste(db, 'Seccion', 'mina_nombre')) {
        await db.execute('ALTER TABLE Seccion ADD COLUMN mina_nombre TEXT');
      }
      if (!await _columnaExiste(db, 'Seccion', 'created_at')) {
        await db.execute('ALTER TABLE Seccion ADD COLUMN created_at TEXT');
      }
      if (!await _columnaExiste(db, 'Seccion', 'updated_at')) {
        await db.execute('ALTER TABLE Seccion ADD COLUMN updated_at TEXT');
      }
      if (!await _columnaExiste(db, 'Seccion', 'created_by')) {
        await db.execute('ALTER TABLE Seccion ADD COLUMN created_by TEXT');
      }
      if (!await _columnaExiste(db, 'Seccion', 'updated_by')) {
        await db.execute('ALTER TABLE Seccion ADD COLUMN updated_by TEXT');
      }
    }

    if (oldVersion < 5) {
      if (!await _columnaExiste(db, 'Equipo', 'proceso_id')) {
        await db.execute('ALTER TABLE Equipo ADD COLUMN proceso_id INTEGER');
      }
    }

    if (oldVersion < 6) {
      if (!await _tablaExiste(db, 'dim_periodo')) {
        await db.execute('''
CREATE TABLE dim_periodo (
  periodo_id INTEGER PRIMARY KEY,
  tipo TEXT NOT NULL,
  numero INTEGER NOT NULL,
  anno INTEGER NOT NULL,
  fecha_inicio TEXT NOT NULL,
  fecha_fin TEXT NOT NULL,
  created_at TEXT
)
''');
      }
    }

    if (oldVersion < 7) {
      if (!await _tablaExiste(db, 'PlanMetrajeTL')) {
        await db.execute('''
CREATE TABLE PlanMetrajeTL (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  planMetrajeTlId INTEGER NOT NULL UNIQUE,
  labor_id INTEGER NOT NULL,
  periodo_id INTEGER NOT NULL,
  ancho_veta_metros REAL NOT NULL,
  ancho_minado_sem_metros REAL NOT NULL,
  ancho_minado_mes_metros REAL NOT NULL,
  mina_id INTEGER NOT NULL,
  zona_id INTEGER NOT NULL,
  area_id INTEGER NOT NULL,
  fase_id INTEGER NOT NULL,
  tipo_labor_id INTEGER NOT NULL,
  estructura_mineral_id INTEGER NOT NULL,
  nivel_id INTEGER NOT NULL,
  ala_id INTEGER NOT NULL,
  labor_nombre TEXT NOT NULL,
  mina_nombre TEXT NOT NULL,
  zona_nombre TEXT NOT NULL,
  area_nombre TEXT NOT NULL,
  fase_nombre TEXT NOT NULL,
  tipo_labor_nombre TEXT NOT NULL,
  estructura_mineral_nombre TEXT NOT NULL,
  nivel_nombre TEXT NOT NULL,
  ala_nombre TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT
)
''');
      }
    }

    if (oldVersion < 8) {
      await db.execute('DROP TABLE IF EXISTS dim_periodo');
      await db.execute('''
CREATE TABLE dim_periodo (
  periodo_id INTEGER PRIMARY KEY,
  tipo TEXT NOT NULL,
  numero INTEGER NOT NULL,
  anno INTEGER NOT NULL,
  fecha_inicio TEXT NOT NULL,
  fecha_fin TEXT NOT NULL,
  created_at TEXT
)
''');
    }

    if (oldVersion < 9) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS minas (
  mina_id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  codigo TEXT,
  ubicacion TEXT,
  estado TEXT
)
''');
      await db.execute('''
CREATE TABLE IF NOT EXISTS zona (
  zona_id INTEGER PRIMARY KEY,
  mina_id INTEGER,
  nombre TEXT NOT NULL,
  codigo TEXT,
  estado TEXT,
  FOREIGN KEY (mina_id) REFERENCES minas(mina_id)
)
''');
      await db.execute('''
CREATE TABLE IF NOT EXISTS area (
  area_id INTEGER PRIMARY KEY,
  zona_id INTEGER,
  nombre TEXT NOT NULL,
  codigo TEXT,
  estado TEXT,
  FOREIGN KEY (zona_id) REFERENCES zona(zona_id)
)
''');
      await db.execute('''
CREATE TABLE IF NOT EXISTS fase (
  fase_id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  codigo TEXT,
  descripcion TEXT,
  estado TEXT
)
''');
      await db.execute('''
CREATE TABLE IF NOT EXISTS tipo_labor (
  tipo_labor_id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  codigo TEXT,
  descripcion TEXT,
  estado TEXT
)
''');
      await db.execute('''
CREATE TABLE IF NOT EXISTS estructura_mineral (
  estructura_mineral_id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  codigo TEXT,
  caracteristicas TEXT,
  estado TEXT
)
''');
      await db.execute('''
CREATE TABLE IF NOT EXISTS nivel (
  nivel_id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  numero INTEGER,
  profundidad_promedio REAL,
  estado TEXT
)
''');
      await db.execute('''
CREATE TABLE IF NOT EXISTS ala (
  ala_id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  codigo TEXT,
  orden INTEGER,
  estado TEXT
)
''');
      await db.execute('''
CREATE TABLE IF NOT EXISTS labores (
  labor_id INTEGER PRIMARY KEY,
  mina_id INTEGER,
  zona_id INTEGER,
  area_id INTEGER,
  fase_id INTEGER,
  tipo_labor_id INTEGER,
  estructura_mineral_id INTEGER,
  nivel_id INTEGER,
  ala_id INTEGER,
  nombre_labor TEXT NOT NULL,
  estado TEXT,
  mina_nombre TEXT,
  zona_nombre TEXT,
  area_nombre TEXT,
  fase_nombre TEXT,
  tipo_labor_nombre TEXT,
  estructura_mineral_nombre TEXT,
  nivel_nombre TEXT,
  ala_nombre TEXT,
  created_at TEXT,
  updated_at TEXT,
  created_by TEXT,
  updated_by TEXT,
  FOREIGN KEY (mina_id) REFERENCES minas(mina_id),
  FOREIGN KEY (zona_id) REFERENCES zona(zona_id),
  FOREIGN KEY (area_id) REFERENCES area(area_id),
  FOREIGN KEY (fase_id) REFERENCES fase(fase_id),
  FOREIGN KEY (tipo_labor_id) REFERENCES tipo_labor(tipo_labor_id),
  FOREIGN KEY (estructura_mineral_id) REFERENCES estructura_mineral(estructura_mineral_id),
  FOREIGN KEY (nivel_id) REFERENCES nivel(nivel_id),
  FOREIGN KEY (ala_id) REFERENCES ala(ala_id)
)
''');
    }

    if (oldVersion < 10) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS dim_turno (
  turno_id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  codigo TEXT,
  horario_inicio TEXT,
  horario_fin TEXT
)
''');
    }
    if (oldVersion < 11) {
      if (!await _tablaExiste(db, 'procesos')) {
        await db.execute('''
CREATE TABLE IF NOT EXISTS procesos (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  nombre_abreviado TEXT
)
''');
      }
    }

    if (oldVersion < 29) {
      if (!await _tablaExiste(db, 'destinos')) {
        await db.execute('''
CREATE TABLE IF NOT EXISTS destinos (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  proceso_id INTEGER NOT NULL
)
''');
      }
    }

    if (oldVersion < 12) {
      if (!await _tablaExiste(db, 'planes_metrajes_avances')) {
        await db.execute('''
CREATE TABLE IF NOT EXISTS planes_metrajes_avances (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_metraje_avance_id INTEGER NOT NULL,
  labor_id INTEGER NOT NULL,
  periodo_id INTEGER NOT NULL,
  avance_metros REAL NOT NULL,
  ancho_metros REAL NOT NULL,
  alto_metros REAL NOT NULL,
  tms REAL NOT NULL,
  mina_id INTEGER NOT NULL,
  zona_id INTEGER NOT NULL,
  area_id INTEGER NOT NULL,
  fase_id INTEGER NOT NULL,
  tipo_labor_id INTEGER NOT NULL,
  estructura_mineral_id INTEGER NOT NULL,
  nivel_id INTEGER NOT NULL,
  ala_id INTEGER NOT NULL,
  labor_nombre TEXT NOT NULL,
  mina_nombre TEXT NOT NULL,
  zona_nombre TEXT NOT NULL,
  area_nombre TEXT NOT NULL,
  fase_nombre TEXT NOT NULL,
  tipo_labor_nombre TEXT NOT NULL,
  estructura_mineral_nombre TEXT NOT NULL,
  nivel_nombre TEXT NOT NULL,
  ala_nombre TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT
)
''');
      }

      if (!await _tablaExiste(db, 'planes_produccion')) {
        await db.execute('''
CREATE TABLE IF NOT EXISTS planes_produccion (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_produccion_id INTEGER NOT NULL,
  labor_id INTEGER NOT NULL,
  periodo_id INTEGER NOT NULL,
  ancho_veta_metros REAL NOT NULL,
  ancho_minado_sem_metros REAL NOT NULL,
  ancho_minado_mes_metros REAL NOT NULL,
  ag_gr REAL NOT NULL,
  porcentaje_cu REAL NOT NULL,
  porcentaje_pb REAL NOT NULL,
  porcentaje_zn REAL NOT NULL,
  vpt_actual REAL NOT NULL,
  vpt_final REAL NOT NULL,
  cut_off_1 REAL NOT NULL,
  cut_off_2 REAL NOT NULL,
  mina_id INTEGER NOT NULL,
  zona_id INTEGER NOT NULL,
  area_id INTEGER NOT NULL,
  fase_id INTEGER NOT NULL,
  tipo_labor_id INTEGER NOT NULL,
  estructura_mineral_id INTEGER NOT NULL,
  nivel_id INTEGER NOT NULL,
  ala_id INTEGER NOT NULL,
  labor_nombre TEXT NOT NULL,
  mina_nombre TEXT NOT NULL,
  zona_nombre TEXT NOT NULL,
  area_nombre TEXT NOT NULL,
  fase_nombre TEXT NOT NULL,
  tipo_labor_nombre TEXT NOT NULL,
  estructura_mineral_nombre TEXT NOT NULL,
  nivel_nombre TEXT NOT NULL,
  ala_nombre TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT
)
''');
      }
    }

    if (oldVersion < 13) {
      await db.execute('DROP TABLE IF EXISTS planes_metraje_tl');
    }

    if (oldVersion < 14) {
      if (!await _tablaExiste(db, 'tipo_perforaciones')) {
        await db.execute('''
CREATE TABLE IF NOT EXISTS tipo_perforaciones (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  proceso TEXT NULL,
  permitido_medicion INTEGER NOT NULL DEFAULT 0,
  proceso_id INTEGER
)
''');
      }
    }
    if (oldVersion < 15) {
      // Rename TipoEquipo → tipo_horometro
      if (!await _tablaExiste(db, 'tipo_horometro')) {
        if (await _tablaExiste(db, 'TipoEquipo')) {
          final oldData = await db.query('TipoEquipo');
          await db.execute('''
CREATE TABLE tipo_horometro (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL
)
''');
          for (var row in oldData) {
            await db.insert('tipo_horometro', {'nombre': row['nombre']});
          }
          await db.execute('DROP TABLE IF EXISTS TipoEquipo');
        } else {
          await db.execute('''
CREATE TABLE tipo_horometro (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL
)
''');
        }
      }

      // Create equipo_horometro_tipos
      if (!await _tablaExiste(db, 'equipo_horometro_tipos')) {
        await db.execute('''
CREATE TABLE equipo_horometro_tipos (
  equipo_id INTEGER NOT NULL,
  equipo_nombre TEXT,
  tipo_horometro_id INTEGER NOT NULL,
  tipo_horometro_nombre TEXT,
  PRIMARY KEY (equipo_id, tipo_horometro_id)
)
''');
      }
    }

    if (oldVersion < 16) {
      if (!await _tablaExiste(db, 'checklist_items')) {
        await db.execute('''
CREATE TABLE IF NOT EXISTS checklist_items (
  id INTEGER PRIMARY KEY,
  proceso_id INTEGER,
  proceso TEXT NOT NULL,
  categoria_id INTEGER,
  categoria TEXT NOT NULL,
  nombre TEXT NOT NULL,
  orden INTEGER,
  categoria_orden INTEGER
)
''');
      } else {
        if (!await _columnaExiste(db, 'checklist_items', 'proceso_id')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN proceso_id INTEGER',
          );
        }
        if (!await _columnaExiste(db, 'checklist_items', 'orden')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN orden INTEGER',
          );
        }
        if (!await _columnaExiste(db, 'checklist_items', 'categoria_id')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN categoria_id INTEGER',
          );
        }
        if (!await _columnaExiste(db, 'checklist_items', 'categoria_orden')) {
          await db.execute(
            'ALTER TABLE checklist_items ADD COLUMN categoria_orden INTEGER',
          );
        }
      }
    }

    if (oldVersion < 17) {
      if (!await _tablaExiste(db, 'usuario_procesos')) {
        await db.execute('''
CREATE TABLE IF NOT EXISTS usuario_procesos (
  usuarios_id INTEGER NOT NULL,
  proceso_id INTEGER NOT NULL,
  PRIMARY KEY (usuarios_id, proceso_id)
)
''');
      }
      if (!await _tablaExiste(db, 'cargos')) {
        await db.execute('''
CREATE TABLE IF NOT EXISTS cargos (
  cargo_id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL
)
''');
      }
    }

    if (oldVersion < 18) {
      if (!await _columnaExiste(db, 'usuario_directorio', 'cargo_id')) {
        await db.execute(
          'ALTER TABLE usuario_directorio ADD COLUMN cargo_id INTEGER',
        );
      }
      if (!await _columnaExiste(db, 'usuario_directorio', 'password')) {
        await db.execute(
          'ALTER TABLE usuario_directorio ADD COLUMN password TEXT',
        );
      }
      if (!await _tablaExiste(db, 'usuario_equipos')) {
        await db.execute('''
CREATE TABLE IF NOT EXISTS usuario_equipos (
  usuarios_id INTEGER NOT NULL,
  equipo_id INTEGER NOT NULL
)
''');
      }
    }

    if (oldVersion < 19) {
      await db.execute('DROP TABLE IF EXISTS Seccion');

      if (!await _tablaExiste(db, 'longitud_barras')) {
        await db.execute('''
CREATE TABLE longitud_barras (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  proceso TEXT NOT NULL,
  longitud_pies REAL NOT NULL
)
''');
      }

      if (!await _tablaExiste(db, 'pernos')) {
        await db.execute('''
CREATE TABLE pernos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tipo_perno TEXT NOT NULL,
  longitud REAL NOT NULL
)
''');
      }

      if (!await _tablaExiste(db, 'mallas')) {
        await db.execute('''
CREATE TABLE mallas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tipo_malla TEXT NOT NULL
)
''');
      }

      // Migrar columnas faltantes en usuario_directorio
      for (final col in [
        'cargo',
        'empresa',
        'guardia',
        'autorizado_equipo',
        'area',
        'clasificacion',
        'correo',
        'firma',
        'createdAt',
      ]) {
        if (!await _columnaExiste(db, 'usuario_directorio', col)) {
          await db.execute(
            'ALTER TABLE usuario_directorio ADD COLUMN $col TEXT',
          );
        }
      }
    }

    if (oldVersion < 20) {
      if (!await _tablaExiste(db, 'estados')) {
        await db.execute('''
CREATE TABLE estados (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  codigo TEXT NOT NULL,
  tipo_estado TEXT NOT NULL,
  categoria TEXT NOT NULL,
  proceso TEXT NOT NULL
)
''');
      }
    }

    if (oldVersion < 21) {
      await db.execute('DROP TABLE IF EXISTS usuario_equipos');
      await db.execute('''
CREATE TABLE usuario_equipos (
  usuarios_id INTEGER NOT NULL,
  equipo_id INTEGER NOT NULL
)
''');
    }

    if (oldVersion < 22) {
      await db.execute('DROP TABLE IF EXISTS usuario_directorio');
      await db.execute('''
CREATE TABLE usuario_directorio (
  codigo_dni TEXT PRIMARY KEY,
  id INTEGER,
  nombres TEXT NOT NULL,
  apellidos TEXT NOT NULL,
  rol TEXT,
  cargo TEXT,
  empresa TEXT,
  guardia TEXT,
  autorizado_equipo TEXT,
  area TEXT,
  clasificacion TEXT,
  correo TEXT,
  firma TEXT,
  cargo_id INTEGER,
  password TEXT,
  createdAt TEXT,
  updated_at TEXT NOT NULL
)
''');
    }

    if (oldVersion < 23) {
      if (!await _tablaExiste(db, 'categorias_estados')) {
        await db.execute('''
CREATE TABLE IF NOT EXISTS categorias_estados (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  activo INTEGER NOT NULL DEFAULT 1
)
''');
      }
    }

    if (oldVersion < 24) {
      if (!await _columnaExiste(db, 'estados', 'proceso_id')) {
        await db.execute('ALTER TABLE estados ADD COLUMN proceso_id INTEGER');
      }
      if (!await _columnaExiste(db, 'estados', 'categoria_id')) {
        await db.execute('ALTER TABLE estados ADD COLUMN categoria_id INTEGER');
      }
    }

    if (oldVersion < 25) {
      await _resetEstadosTable(db);
    }

    if (oldVersion < 27) {
      await _resetPlanesMetrajesAvancesTable(db);
    }

    if (oldVersion < 28) {
      await _resetPlanesProduccionTable(db);
    }

    if (oldVersion < 31) {
      await _resetPlanMetrajeTLTable(db);
    }

    if (oldVersion < 32) {
      await _resetLaboresTable(db);
      await _resetPlanesMetrajesAvancesTable(db);
      await _resetPlanesProduccionTable(db);
    }

    if (oldVersion < 33) {
      await _resetChecklistItemsTable(db);
    }

    if (oldVersion < 34) {
      if (!await _columnaExiste(db, 'categorias_estados', 'activo')) {
        await db.execute(
          'ALTER TABLE categorias_estados ADD COLUMN activo INTEGER NOT NULL DEFAULT 1',
        );
      }
    }

    if (oldVersion < 35) {
      await _resetTipoPerforacionesTable(db);
    }

    if (oldVersion < 36) {
      await db.execute('DROP TABLE IF EXISTS usuario_equipos');
    }

    if (oldVersion < 37) {
      if (!await _columnaExiste(db, 'Equipo', 'ultimos_horometros')) {
        await db.execute(
          'ALTER TABLE Equipo ADD COLUMN ultimos_horometros TEXT',
        );
      }
    }
  }

  Future<void> _resetEstadosTable(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('DROP TABLE IF EXISTS estados');
      await txn.execute('''
CREATE TABLE estados (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  codigo TEXT NOT NULL,
  tipo_estado TEXT NOT NULL,
  categoria TEXT NOT NULL,
  proceso TEXT NOT NULL,
  proceso_id INTEGER,
  categoria_id INTEGER
)
''');
    });
  }

  Future<void> _resetTipoPerforacionesTable(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('DROP TABLE IF EXISTS tipo_perforaciones');
      await txn.execute('''
CREATE TABLE tipo_perforaciones (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  proceso TEXT,
  permitido_medicion INTEGER NOT NULL DEFAULT 0,
  proceso_id INTEGER
)
''');
    });
  }

  Future<void> _resetPlanMetrajeTLTable(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('DROP TABLE IF EXISTS PlanMetrajeTL');
      await txn.execute('''
CREATE TABLE PlanMetrajeTL (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  planMetrajeTlId INTEGER NOT NULL UNIQUE,
  labor_id INTEGER NOT NULL,
  periodo_id INTEGER NOT NULL,
  ancho_veta_metros REAL NOT NULL,
  ancho_minado_sem_metros REAL NOT NULL,
  ancho_minado_mes_metros REAL NOT NULL,
  mina_id INTEGER NOT NULL,
  zona_id INTEGER NOT NULL,
  area_id INTEGER NOT NULL,
  fase_id INTEGER NOT NULL,
  tipo_labor_id INTEGER NOT NULL,
  estructura_mineral_id INTEGER NOT NULL,
  nivel_id INTEGER NOT NULL,
  ala_id INTEGER NOT NULL,
  labor_nombre TEXT NOT NULL,
  mina_nombre TEXT NOT NULL,
  zona_nombre TEXT NOT NULL,
  area_nombre TEXT NOT NULL,
  fase_nombre TEXT NOT NULL,
  tipo_labor_nombre TEXT NOT NULL,
  estructura_mineral_nombre TEXT NOT NULL,
  nivel_nombre TEXT NOT NULL,
  ala_nombre TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT
)
''');
    });
  }

  Future<void> _resetPlanesMetrajesAvancesTable(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('DROP TABLE IF EXISTS planes_metrajes_avances');
      await txn.execute('''
CREATE TABLE planes_metrajes_avances (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_metraje_avance_id INTEGER NOT NULL,
  labor_id INTEGER NOT NULL,
  periodo_id INTEGER NOT NULL,
  avance_metros REAL NOT NULL,
  ancho_metros REAL NOT NULL,
  alto_metros REAL NOT NULL,
  tms REAL NOT NULL,
  mina_id INTEGER NOT NULL,
  zona_id INTEGER NOT NULL,
  area_id INTEGER NOT NULL,
  fase_id INTEGER NOT NULL,
  tipo_labor_id INTEGER NOT NULL,
  estructura_mineral_id INTEGER NOT NULL,
  nivel_id INTEGER NOT NULL,
  ala_id INTEGER NOT NULL,
  labor_nombre TEXT NOT NULL,
  mina_nombre TEXT NOT NULL,
  zona_nombre TEXT NOT NULL,
  area_nombre TEXT NOT NULL,
  fase_nombre TEXT NOT NULL,
  tipo_labor_nombre TEXT NOT NULL,
  estructura_mineral_nombre TEXT NOT NULL,
  nivel_nombre TEXT NOT NULL,
  ala_nombre TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT
)
''');
    });
  }

  Future<void> _resetPlanesProduccionTable(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('DROP TABLE IF EXISTS planes_produccion');
      await txn.execute('''
CREATE TABLE planes_produccion (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_produccion_id INTEGER NOT NULL,
  labor_id INTEGER NOT NULL,
  periodo_id INTEGER NOT NULL,
  ancho_veta_metros REAL NOT NULL,
  ancho_minado_sem_metros REAL NOT NULL,
  ancho_minado_mes_metros REAL NOT NULL,
  ag_gr REAL NOT NULL,
  porcentaje_cu REAL NOT NULL,
  porcentaje_pb REAL NOT NULL,
  porcentaje_zn REAL NOT NULL,
  vpt_actual REAL NOT NULL,
  vpt_final REAL NOT NULL,
  cut_off_1 REAL NOT NULL,
  cut_off_2 REAL NOT NULL,
  mina_id INTEGER NOT NULL,
  zona_id INTEGER NOT NULL,
  area_id INTEGER NOT NULL,
  fase_id INTEGER NOT NULL,
  tipo_labor_id INTEGER NOT NULL,
  estructura_mineral_id INTEGER NOT NULL,
  nivel_id INTEGER NOT NULL,
  ala_id INTEGER NOT NULL,
  labor_nombre TEXT NOT NULL,
  mina_nombre TEXT NOT NULL,
  zona_nombre TEXT NOT NULL,
  area_nombre TEXT NOT NULL,
  fase_nombre TEXT NOT NULL,
  tipo_labor_nombre TEXT NOT NULL,
  estructura_mineral_nombre TEXT NOT NULL,
  nivel_nombre TEXT NOT NULL,
  ala_nombre TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT
)
''');
    });
  }

  Future<void> _resetLaboresTable(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('DROP TABLE IF EXISTS labores');
      await txn.execute('''
CREATE TABLE labores (
  labor_id INTEGER PRIMARY KEY,
  mina_id INTEGER,
  zona_id INTEGER,
  area_id INTEGER,
  fase_id INTEGER,
  tipo_labor_id INTEGER,
  estructura_mineral_id INTEGER,
  nivel_id INTEGER,
  ala_id INTEGER,
  nombre_labor TEXT NOT NULL,
  estado TEXT,
  mina_nombre TEXT,
  zona_nombre TEXT,
  area_nombre TEXT,
  fase_nombre TEXT,
  tipo_labor_nombre TEXT,
  estructura_mineral_nombre TEXT,
  nivel_nombre TEXT,
  ala_nombre TEXT,
  created_at TEXT,
  updated_at TEXT,
  created_by TEXT,
  updated_by TEXT,
  FOREIGN KEY (mina_id) REFERENCES minas(mina_id),
  FOREIGN KEY (zona_id) REFERENCES zona(zona_id),
  FOREIGN KEY (area_id) REFERENCES area(area_id),
  FOREIGN KEY (fase_id) REFERENCES fase(fase_id),
  FOREIGN KEY (tipo_labor_id) REFERENCES tipo_labor(tipo_labor_id),
  FOREIGN KEY (estructura_mineral_id) REFERENCES estructura_mineral(estructura_mineral_id),
  FOREIGN KEY (nivel_id) REFERENCES nivel(nivel_id),
  FOREIGN KEY (ala_id) REFERENCES ala(ala_id)
)
''');
    });
  }

  Future<void> _resetChecklistItemsTable(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('DROP TABLE IF EXISTS checklist_items');
      await txn.execute('''
CREATE TABLE checklist_items (
  id INTEGER PRIMARY KEY,
  proceso_id INTEGER,
  proceso TEXT NOT NULL,
  categoria_id INTEGER,
  categoria TEXT NOT NULL,
  nombre TEXT NOT NULL,
  orden INTEGER,
  categoria_orden INTEGER
)
''');
    });
  }

  // Método de creación de tablas
  Future<void> _onCreate(Database db, int version) async {
    // (Usuario, PlanMensual, PlanProduccion, PlanMetraje removidas - ya no existen)

    // (Equipo, TipoEquipo, Seccion, Guardia, Secciones, checklist_items removidas - están en shared DB o ya no existen)

    // (EstadostBD, jefe_guardias, checklists_telemando, horometros_nube removidas)
    // (longitud_barras, pernos, mallas movidas a shared DB)

    await db.execute('''
CREATE TABLE origen_destino(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  proceso TEXT,
  tipo TEXT,
  nombre TEXT
)
''');

    await _createOperationTables(db);

    //EXPLOSIVOS A MEJORAR------------------------------------------
    await db.execute('''
  CREATE TABLE Datos_trabajo_exploraciones(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha TEXT,
    turno TEXT,
    taladro TEXT,
    pies_por_taladro TEXT,
    zona TEXT,
    tipo_labor TEXT,
    labor TEXT,
    ala TEXT,
    veta TEXT,
    nivel TEXT,
    tipo_perforacion TEXT,
    estado TEXT DEFAULT 'Creado',
    cerrado INTEGER DEFAULT 0,
    envio INTEGER DEFAULT 0,
    semanaDefault TEXT,
    semanaSelect TEXT,
    empresa TEXT,
    seccion TEXT,
    medicion INTEGER DEFAULT 0
  )
''');

    // (Despacho, DespachoDetalle, Devoluciones, DevolucionDetalle, DetalleDespachoExplosivos, DetalleDevolucionesExplosivos, explosivos, ExplosivosUni, toneladas, nube_*, numero_retardos removidas)

    await db.execute('''
  CREATE TABLE accesorios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo_accesorio TEXT NOT NULL,
    costo REAL NOT NULL,
    unidad_medida TEXT NOT NULL
  );
''');

    await db.execute('''
  CREATE TABLE mediciones_horizontal (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha TEXT NOT NULL,
    turno TEXT,
    empresa TEXT,
    zona TEXT,
    labor TEXT,
    veta TEXT,
    tipo_perforacion TEXT,
    kg_explosivos REAL,
    avance_programado REAL,
    ancho REAL,
    alto REAL,
    envio INTEGER DEFAULT 0,
    id_explosivo INTEGER,
    idnube INTEGER
  )
''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS mediciones_largo (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT NOT NULL,
      turno TEXT,
      empresa TEXT,
      zona TEXT,
      labor TEXT,
      veta TEXT,
      tipo_perforacion TEXT,
      kg_explosivos REAL,
      toneladas REAL,
      envio INTEGER DEFAULT 0,
      id_explosivo INTEGER,
      idnube INTEGER
    )
  ''');

  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      /// Tabla Secciones
      if (!await _tablaExiste(db, 'Secciones')) {
        await db.execute('''
        CREATE TABLE Secciones (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          proceso TEXT NULL
        )
      ''');
      }
    }

    if (oldVersion < 3) {
      if (!await _tablaExiste(db, 'Operacion_tal_horizontal')) {
        await db.execute('''
        CREATE TABLE Operacion_tal_horizontal (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fecha TEXT,
          turno TEXT,
          seccion TEXT,
          operador TEXT,
          jefe_guardia TEXT,
          n_equipo TEXT,
          modelo_equipo TEXT,
          registros TEXT,
          horometros TEXT,
          condiciones_equipo TEXT,
          check_list TEXT,
          control_llantas TEXT,
          estado TEXT DEFAULT 'activo',
          envio INTEGER DEFAULT 0
        )
      ''');

        print("✅ Tabla Operacion_tal_horizontal creada en versión 3");
      }
    }
    if (oldVersion < 4) {
      // Operacion_tal_largo
      if (!await _columnaExiste(db, 'Operacion_tal_largo', 'equipo')) {
        await db.execute(
          'ALTER TABLE Operacion_tal_largo ADD COLUMN equipo TEXT',
        );
        print("✅ Columna equipo agregada en Operacion_tal_largo");
      }

      // Operacion_tal_horizontal
      if (!await _columnaExiste(db, 'Operacion_tal_horizontal', 'equipo')) {
        await db.execute(
          'ALTER TABLE Operacion_tal_horizontal ADD COLUMN equipo TEXT',
        );
        print("✅ Columna equipo agregada en Operacion_tal_horizontal");
      }
    }
    if (oldVersion < 5) {
      /// Crear tabla Operacion_empernador
      if (!await _tablaExiste(db, 'Operacion_empernador')) {
        await db.execute('''
      CREATE TABLE Operacion_empernador (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT,
        turno TEXT,
        seccion TEXT,
        operador TEXT,
        jefe_guardia TEXT,
        equipo TEXT,
        n_equipo TEXT,
        tipo_equipo TEXT,
        registros TEXT,
        horometros TEXT,
        condiciones_equipo TEXT,
        check_list TEXT,
        control_llantas TEXT,
        estado TEXT DEFAULT 'activo',
        envio INTEGER DEFAULT 0
      )
    ''');

        print("✅ Tabla Operacion_empernador creada en versión 5");
      }

      /// Migración segura de columna tipo en tabla Equipo
      if (!await _columnaExiste(db, 'Equipo', 'tipo')) {
        await db.execute('ALTER TABLE Equipo ADD COLUMN tipo TEXT');

        print("✅ Columna tipo agregada en tabla Equipo");
      }
    }
    if (oldVersion < 6) {
      if (!await _tablaExiste(db, 'TipoEquipo')) {
        await db.execute('''
CREATE TABLE TipoEquipo (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL
)
''');
      }
    }
    if (oldVersion < 7) {
      if (!await _tablaExiste(db, 'checklists_telemando')) {
        await db.execute('''
    CREATE TABLE checklists_telemando (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL
    )
    ''');
      }

      if (!await _tablaExiste(db, 'Operacion_carguio')) {
        await db.execute('''
    CREATE TABLE Operacion_carguio (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT,
      turno TEXT,
      seccion TEXT,
      operador TEXT,
      jefe_guardia TEXT,
      equipo TEXT,
      n_equipo TEXT,
      capacidad TEXT,
      tipo_equipo TEXT,
      registros TEXT,
      horometros TEXT,
      condiciones_equipo TEXT,
      programa_trabajo TEXT,
      check_list TEXT,
      check_list_telemando TEXT,
      control_llantas TEXT,
      estado TEXT DEFAULT 'activo',
      envio INTEGER DEFAULT 0
    )
    ''');
      }
    }
    if (oldVersion < 8) {
      if (!await _tablaExiste(db, 'Operacion_rompebanco')) {
        await db.execute('''
    CREATE TABLE Operacion_rompebanco(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT,
      turno TEXT,
      operador TEXT,
      jefe_guardia TEXT,
      equipo TEXT,
      n_equipo TEXT,
      registros TEXT,
      horometros TEXT,
      condiciones_equipo TEXT,
      check_list TEXT,
      control_llantas TEXT,
      estado TEXT DEFAULT 'activo',
      envio INTEGER DEFAULT 0
    )
    ''');
      }
    }
    if (oldVersion < 9) {
      if (await _tablaExiste(db, 'Operacion_rompebanco')) {
        await db.delete('Operacion_rompebanco');
        // o también:
        // await db.execute('DELETE FROM Operacion_rompebanco');
      }
    }
    if (oldVersion < 10) {
      /// Tabla Operacion_scissor
      if (!await _tablaExiste(db, 'Operacion_scissor')) {
        await db.execute('''
    CREATE TABLE Operacion_scissor(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT,
      turno TEXT,
      operador TEXT,
      jefe_guardia TEXT,
      equipo TEXT,
      n_equipo TEXT,
      registros TEXT,
      horometros TEXT,
      condiciones_equipo TEXT,
      check_list TEXT,
      control_llantas TEXT,
      estado TEXT DEFAULT 'activo',
      envio INTEGER DEFAULT 0
    )
    ''');
      }

      /// Tabla Operacion_anfochanger
      if (!await _tablaExiste(db, 'Operacion_anfochanger')) {
        await db.execute('''
    CREATE TABLE Operacion_anfochanger(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT,
      turno TEXT,
      operador TEXT,
      jefe_guardia TEXT,
      equipo TEXT,
      n_equipo TEXT,
      registros TEXT,
      horometros TEXT,
      condiciones_equipo TEXT,
      check_list TEXT,
      control_llantas TEXT,
      estado TEXT DEFAULT 'activo',
      envio INTEGER DEFAULT 0
    )
    ''');
      }
    }
    if (oldVersion < 11) {
      /// Tabla Seccion
      if (!await _tablaExiste(db, 'Seccion')) {
        await db.execute('''
    CREATE TABLE Seccion (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      proceso TEXT,
      nombre TEXT
    )
    ''');
      }
    }
    if (oldVersion < 12) {
      /// Tabla Operacion_Dumper
      if (!await _tablaExiste(db, 'Operacion_Dumper')) {
        await db.execute('''
    CREATE TABLE Operacion_Dumper (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT,
      turno TEXT,
      seccion TEXT,
      operador TEXT,
      jefe_guardia TEXT,
      equipo TEXT,
      n_equipo TEXT,
      capacidad TEXT,
      tipo_equipo TEXT,
      registros TEXT,
      horometros TEXT,
      condiciones_equipo TEXT,
      programa_trabajo TEXT,
      check_list TEXT,
      check_list_telemando TEXT,
      control_llantas TEXT,
      estado TEXT DEFAULT 'activo',
      envio INTEGER DEFAULT 0
    )
    ''');
      }

      /// Tabla Operacion_Scalamin
      if (!await _tablaExiste(db, 'Operacion_Scalamin')) {
        await db.execute('''
    CREATE TABLE Operacion_Scalamin(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT,
      turno TEXT,
      operador TEXT,
      jefe_guardia TEXT,
      equipo TEXT,
      n_equipo TEXT,
      registros TEXT,
      horometros TEXT,
      condiciones_equipo TEXT,
      check_list TEXT,
      control_llantas TEXT,
      estado TEXT DEFAULT 'activo',
      envio INTEGER DEFAULT 0
    )
    ''');
      }
    }
    if (oldVersion < 13) {
      /// Tabla longitud_barras
      if (!await _tablaExiste(db, 'longitud_barras')) {
        await db.execute('''
    CREATE TABLE longitud_barras (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      proceso TEXT NOT NULL,
      longitud_pies REAL NOT NULL
    )
    ''');
      }

      /// Tabla pernos
      if (!await _tablaExiste(db, 'pernos')) {
        await db.execute('''
    CREATE TABLE pernos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tipo_perno TEXT NOT NULL,
      longitud REAL NOT NULL
    )
    ''');
      }

      /// Tabla mallas
      if (!await _tablaExiste(db, 'mallas')) {
        await db.execute('''
    CREATE TABLE mallas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tipo_malla TEXT NOT NULL
    )
    ''');
      }
    }
    if (oldVersion < 14) {
      /// Tabla horometros_nube
      if (!await _tablaExiste(db, 'horometros_nube')) {
        await db.execute('''
    CREATE TABLE horometros_nube (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      operacion TEXT NOT NULL,
      tipo_horometro TEXT NOT NULL, 
      inicio REAL,
      final REAL,
      op INTEGER,
      inop INTEGER
    )
    ''');
      }
    }
    if (oldVersion < 15) {
      if (!await _tablaExiste(db, 'origen_destino')) {
        await db.execute('''
    CREATE TABLE origen_destino (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      proceso TEXT,
      tipo TEXT,
      nombre TEXT
    )
    ''');
      }
    }
    if (oldVersion < 16) {
      // 🔹 Tabla principal
      if (!await _tablaExiste(db, 'Datos_trabajo_exploraciones')) {
        await db.execute('''
      CREATE TABLE Datos_trabajo_exploraciones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT,
        turno TEXT,
        taladro TEXT,
        pies_por_taladro TEXT,
        zona TEXT,
        tipo_labor TEXT,
        labor TEXT,
        ala TEXT,
        veta TEXT,
        nivel TEXT,
        tipo_perforacion TEXT,
        estado TEXT DEFAULT 'Creado',
        cerrado INTEGER DEFAULT 0,
        envio INTEGER DEFAULT 0,
        semanaDefault TEXT,
        semanaSelect TEXT,
        empresa TEXT,
        seccion TEXT,
        medicion INTEGER DEFAULT 0
      )
    ''');
      }

      // 🔹 Despacho
      if (!await _tablaExiste(db, 'Despacho')) {
        await db.execute('''
      CREATE TABLE Despacho (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        datos_trabajo_id INTEGER,
        mili_segundo REAL,
        medio_segundo REAL,
        observaciones TEXT,
        FOREIGN KEY(datos_trabajo_id) REFERENCES Datos_trabajo_exploraciones(id) ON DELETE CASCADE
      )
    ''');
      }

      // 🔹 DespachoDetalle
      if (!await _tablaExiste(db, 'DespachoDetalle')) {
        await db.execute('''
      CREATE TABLE DespachoDetalle (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        despacho_id INTEGER,
        nombre_material TEXT NOT NULL,  
        cantidad TEXT NOT NULL,
        FOREIGN KEY(despacho_id) REFERENCES Despacho(id) ON DELETE CASCADE
      )
    ''');
      }

      // 🔹 Devoluciones
      if (!await _tablaExiste(db, 'Devoluciones')) {
        await db.execute('''
      CREATE TABLE Devoluciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        datos_trabajo_id INTEGER,
        mili_segundo REAL,
        medio_segundo REAL,
        observaciones TEXT,
        FOREIGN KEY(datos_trabajo_id) REFERENCES Datos_trabajo_exploraciones(id) ON DELETE CASCADE
      )
    ''');
      }

      // 🔹 DevolucionDetalle
      if (!await _tablaExiste(db, 'DevolucionDetalle')) {
        await db.execute('''
      CREATE TABLE DevolucionDetalle (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        devolucion_id INTEGER,
        nombre_material TEXT NOT NULL,  
        cantidad TEXT NOT NULL,         
        FOREIGN KEY(devolucion_id) REFERENCES Devoluciones(id) ON DELETE CASCADE
      )
    ''');
      }

      // 🔹 Explosivos despacho
      if (!await _tablaExiste(db, 'DetalleDespachoExplosivos')) {
        await db.execute('''
      CREATE TABLE DetalleDespachoExplosivos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_despacho INTEGER,
        numero INTEGER,
        ms_cant1 TEXT,
        lp_cant1 TEXT,
        FOREIGN KEY (id_despacho) REFERENCES Despacho(id) ON DELETE CASCADE
      )
    ''');
      }

      // 🔹 Explosivos devoluciones
      if (!await _tablaExiste(db, 'DetalleDevolucionesExplosivos')) {
        await db.execute('''
      CREATE TABLE DetalleDevolucionesExplosivos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_devolucion INTEGER,
        numero INTEGER,
        ms_cant1 TEXT,
        lp_cant1 TEXT,
        FOREIGN KEY (id_devolucion) REFERENCES Devoluciones(id) ON DELETE CASCADE
      )
    ''');
      }
      // 🔹 NUEVAS TABLAS =======================

      // Accesorios
      if (!await _tablaExiste(db, 'accesorios')) {
        await db.execute('''
      CREATE TABLE accesorios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo_accesorio TEXT NOT NULL,
        costo REAL NOT NULL,
        unidad_medida TEXT NOT NULL
      )
    ''');
      }

      // Explosivos
      if (!await _tablaExiste(db, 'explosivos')) {
        await db.execute('''
      CREATE TABLE explosivos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo_explosivo TEXT NOT NULL,
        cantidad_por_caja INTEGER NOT NULL,
        peso_unitario REAL NOT NULL,
        costo_por_kg REAL NOT NULL,
        unidad_medida TEXT NOT NULL
      )
    ''');
      }

      // ExplosivosUni
      if (!await _tablaExiste(db, 'ExplosivosUni')) {
        await db.execute('''
      CREATE TABLE ExplosivosUni (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dato REAL NOT NULL,
        tipo TEXT NOT NULL
      )
    ''');
      }
    }
    if (oldVersion < 17) {
      // 🔹 TONELADAS
      if (!await _tablaExiste(db, 'toneladas')) {
        await db.execute('''
      CREATE TABLE toneladas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        turno TEXT,
        zona TEXT NOT NULL,
        tipo TEXT NOT NULL,
        labor TEXT NOT NULL,
        toneladas REAL NOT NULL
      )
    ''');
      }

      // 🔹 NUBE DATOS TRABAJO (nueva versión con idnube)
      if (!await _tablaExiste(db, 'nube_Datos_trabajo_exploraciones')) {
        await db.execute('''
      CREATE TABLE nube_Datos_trabajo_exploraciones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT,
        turno TEXT,
        taladro TEXT,
        pies_por_taladro TEXT,
        zona TEXT,
        tipo_labor TEXT,
        labor TEXT,
        ala TEXT,
        veta TEXT,
        nivel TEXT,
        tipo_perforacion TEXT,
        estado TEXT DEFAULT 'Creado',
        cerrado INTEGER DEFAULT 0,
        envio INTEGER DEFAULT 0,
        semanaDefault TEXT,
        semanaSelect TEXT,
        empresa TEXT,
        seccion TEXT,
        idnube TEXT,
        medicion INTEGER DEFAULT 0
      )
    ''');
      }

      // 🔹 NUBE DESPACHO
      if (!await _tablaExiste(db, 'nube_Despacho')) {
        await db.execute('''
      CREATE TABLE nube_Despacho (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        datos_trabajo_id INTEGER,
        mili_segundo REAL,
        medio_segundo REAL,
        observaciones TEXT,
        FOREIGN KEY(datos_trabajo_id) REFERENCES nube_Datos_trabajo_exploraciones(id) ON DELETE CASCADE
      )
    ''');
      }

      // 🔹 NUBE DESPACHO DETALLE
      if (!await _tablaExiste(db, 'nube_DespachoDetalle')) {
        await db.execute('''
      CREATE TABLE nube_DespachoDetalle (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        despacho_id INTEGER,
        nombre_material TEXT NOT NULL,
        cantidad TEXT NOT NULL,
        FOREIGN KEY(despacho_id) REFERENCES nube_Despacho(id) ON DELETE CASCADE
      )
    ''');
      }

      // 🔹 NUBE DEVOLUCIONES
      if (!await _tablaExiste(db, 'nube_Devoluciones')) {
        await db.execute('''
      CREATE TABLE nube_Devoluciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        datos_trabajo_id INTEGER,
        mili_segundo REAL,
        medio_segundo REAL,
        observaciones TEXT,
        FOREIGN KEY(datos_trabajo_id) REFERENCES nube_Datos_trabajo_exploraciones(id) ON DELETE CASCADE
      )
    ''');
      }

      // 🔹 NUBE DEVOLUCION DETALLE
      if (!await _tablaExiste(db, 'nube_DevolucionDetalle')) {
        await db.execute('''
      CREATE TABLE nube_DevolucionDetalle (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        devolucion_id INTEGER,
        nombre_material TEXT NOT NULL,
        cantidad TEXT NOT NULL,
        FOREIGN KEY(devolucion_id) REFERENCES nube_Devoluciones(id) ON DELETE CASCADE
      )
    ''');
      }

      // 🔹 DETALLE DESPACHO EXPLOSIVOS
      if (!await _tablaExiste(db, 'nube_DetalleDespachoExplosivos')) {
        await db.execute('''
      CREATE TABLE nube_DetalleDespachoExplosivos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_despacho INTEGER,
        numero INTEGER,
        ms_cant1 TEXT,
        lp_cant1 TEXT,
        FOREIGN KEY (id_despacho) REFERENCES nube_Despacho(id) ON DELETE CASCADE
      )
    ''');
      }

      // 🔹 DETALLE DEVOLUCIONES EXPLOSIVOS
      if (!await _tablaExiste(db, 'nube_DetalleDevolucionesExplosivos')) {
        await db.execute('''
      CREATE TABLE nube_DetalleDevolucionesExplosivos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_devolucion INTEGER,
        numero INTEGER,
        ms_cant1 TEXT,
        lp_cant1 TEXT,
        FOREIGN KEY (id_devolucion) REFERENCES nube_Devoluciones(id) ON DELETE CASCADE
      )
    ''');
      }

      // 🔹 MEDICIONES HORIZONTAL
      if (!await _tablaExiste(db, 'mediciones_horizontal')) {
        await db.execute('''
      CREATE TABLE mediciones_horizontal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        turno TEXT,
        empresa TEXT,
        zona TEXT,
        labor TEXT,
        veta TEXT,
        tipo_perforacion TEXT,
        kg_explosivos REAL,
        avance_programado REAL,
        ancho REAL,
        alto REAL,
        envio INTEGER DEFAULT 0,
        id_explosivo INTEGER,
        idnube INTEGER
      )
    ''');
      }

      // 🔹 MEDICIONES LARGO
      if (!await _tablaExiste(db, 'mediciones_largo')) {
        await db.execute('''
      CREATE TABLE mediciones_largo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        turno TEXT,
        empresa TEXT,
        zona TEXT,
        labor TEXT,
        veta TEXT,
        tipo_perforacion TEXT,
        kg_explosivos REAL,
        toneladas REAL,
        envio INTEGER DEFAULT 0,
        id_explosivo INTEGER,
        idnube INTEGER
      )
    ''');
      }
    }
    if (oldVersion < 19) {
      // 🔹 AGREGAR cantidad_retardos EN Despacho
      if (!await _columnaExiste(db, 'Despacho', 'cantidad_retardos')) {
        await db.execute('''
      ALTER TABLE Despacho ADD COLUMN cantidad_retardos INTEGER DEFAULT 0
    ''');
      }

      // 🔹 AGREGAR cantidad_retardos EN Devoluciones
      if (!await _columnaExiste(db, 'Devoluciones', 'cantidad_retardos')) {
        await db.execute('''
      ALTER TABLE Devoluciones ADD COLUMN cantidad_retardos INTEGER DEFAULT 0
    ''');
      }
    }
    if (oldVersion < 20) {
      // 🔹 CREAR TABLA Guardia
      if (!await _tablaExiste(db, 'Guardia')) {
        await db.execute('''
      CREATE TABLE Guardia (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        guardia TEXT NOT NULL
      )
    ''');
      }
    }
    if (oldVersion < 21) {
      for (final tbl in [
        'Operacion_Scalamin',
        'Operacion_scissor',
        'Operacion_anfochanger',
      ]) {
        if (!await _columnaExiste(db, tbl, 'actor_dni')) {
          await db.execute('ALTER TABLE $tbl ADD COLUMN actor_dni TEXT');
        }
        if (!await _columnaExiste(db, tbl, 'actor_operador_id')) {
          await db.execute(
            'ALTER TABLE $tbl ADD COLUMN actor_operador_id INTEGER',
          );
        }
        if (!await _columnaExiste(db, tbl, 'operador_id')) {
          await db.execute('ALTER TABLE $tbl ADD COLUMN operador_id INTEGER');
        }
      }
    }
    if (oldVersion < 22) {
      for (final tbl in [
        'Operacion_tal_largo',
        'Operacion_tal_horizontal',
        'Operacion_empernador',
        'Operacion_carguio',
        'Operacion_Dumper',
        'Operacion_rompebanco',
      ]) {
        if (!await _columnaExiste(db, tbl, 'actor_dni')) {
          await db.execute('ALTER TABLE $tbl ADD COLUMN actor_dni TEXT');
        }
        if (!await _columnaExiste(db, tbl, 'actor_operador_id')) {
          await db.execute(
            'ALTER TABLE $tbl ADD COLUMN actor_operador_id INTEGER',
          );
        }
        if (!await _columnaExiste(db, tbl, 'operador_id')) {
          await db.execute('ALTER TABLE $tbl ADD COLUMN operador_id INTEGER');
        }
      }
    }
    if (oldVersion < 23) {
      final cols = [
        'equipo_id',
        'zona_id',
        'jefe_guardia_id',
        'identity_version',
      ];
      for (final tbl in [
        'Operacion_tal_largo',
        'Operacion_tal_horizontal',
        'Operacion_empernador',
        'Operacion_carguio',
        'Operacion_Dumper',
        'Operacion_rompebanco',
        'Operacion_Scalamin',
        'Operacion_scissor',
        'Operacion_anfochanger',
      ]) {
        for (final col in cols) {
          if (!await _columnaExiste(db, tbl, col)) {
            await db.execute('ALTER TABLE $tbl ADD COLUMN $col INTEGER');
          }
        }
        if (!await _columnaExiste(db, tbl, 'syncable')) {
          await db.execute(
            'ALTER TABLE $tbl ADD COLUMN syncable INTEGER DEFAULT 0',
          );
        }
      }
      if (!await _tablaExiste(db, 'UsuarioEquipo')) {
        await db.execute('''
CREATE TABLE UsuarioEquipo (
  codigo_dni TEXT NOT NULL,
  proceso_id INTEGER NOT NULL,
  equipo_id INTEGER NOT NULL
)
''');
      }
    }

    if (oldVersion < 24) {
      await db.execute('DROP TABLE IF EXISTS plan_labores');
    }

    if (oldVersion < 25) {
      await db.execute('DROP TABLE IF EXISTS TipoPerforacion');
    }

    if (oldVersion < 27) {
      await db.execute('DROP TABLE IF EXISTS UsuarioProceso');
    }

    if (oldVersion < 28) {
      await db.execute('DROP TABLE IF EXISTS UsuarioEquipo');
    }

    if (oldVersion < 29) {
      // Limpieza: tablas que ya no deben existir en user DB
      for (final tbl in [
        'Usuario',
        'PlanMensual',
        'PlanProduccion',
        'PlanMetraje',
        'Equipo',
        'TipoEquipo',
        'Seccion',
        'Secciones',
        'Guardia',
        'checklist_items',
        'EstadostBD',
        'jefe_guardias',
        'checklists_telemando',
        'longitud_barras',
        'pernos',
        'mallas',
        'DespachoDetalle',
        'Despacho',
        'DetalleDespachoExplosivos',
        'DevolucionDetalle',
        'Devoluciones',
        'DetalleDevolucionesExplosivos',
        'explosivos',
        'ExplosivosUni',
        'toneladas',
        'nube_DetalleDevolucionesExplosivos',
        'nube_DetalleDespachoExplosivos',
        'nube_DevolucionDetalle',
        'nube_Devoluciones',
        'nube_DespachoDetalle',
        'nube_Despacho',
        'nube_Datos_trabajo_exploraciones',
        'numero_retardos',
        'horometros_nube',
        'ProcesoAutorizado',
      ]) {
        await db.execute('DROP TABLE IF EXISTS $tbl');
      }
    }

    if (oldVersion < 30) {
      await _recreateOperationTables(db);
    }

    if (oldVersion < 32) {
      await db.execute('DROP TABLE IF EXISTS pdfs');
    }
  }

  static const List<String> _operationTables = [
    'Operacion_tal_largo',
    'Operacion_tal_horizontal',
    'Operacion_empernador',
    'Operacion_carguio',
    'Operacion_Dumper',
    'Operacion_rompebanco',
    'Operacion_Scalamin',
    'Operacion_scissor',
    'Operacion_anfochanger',
  ];

  static const Set<String> _operationTablesWithDispatchExtras = {
    'Operacion_carguio',
    'Operacion_Dumper',
  };

  Future<void> _createOperationTables(Database db) async {
    for (final tableName in _operationTables) {
      await db.execute(_buildOperationTableSql(tableName));
    }
  }

  Future<void> _recreateOperationTables(Database db) async {
    for (final tableName in _operationTables) {
      await db.execute('DROP TABLE IF EXISTS $tableName');
    }
    await _createOperationTables(db);
  }

  String _buildOperationTableSql(String tableName) {
    final dispatchExtras =
        _operationTablesWithDispatchExtras.contains(tableName)
        ? ',\n  programa_trabajo TEXT,\n  check_list_telemando TEXT'
        : '';

    return '''
CREATE TABLE $tableName (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fecha TEXT,
  turno TEXT,
  turno_id INTEGER,
  operador TEXT,
  operador_id INTEGER,
  registrador TEXT,
  registrador_id INTEGER,
  jefe_guardia TEXT,
  jefe_guardia_id INTEGER,
  equipo TEXT,
  equipo_id INTEGER,
  registros TEXT,
  horometros TEXT,
  condiciones_equipo TEXT,
  check_list TEXT,
  control_llantas TEXT,
  cerrado INTEGER DEFAULT 0,
  enviado INTEGER DEFAULT 0,
  labor TEXT,
  labor_id INTEGER,
  frente_origen TEXT,
  ala TEXT,
  ala_id INTEGER$dispatchExtras
)
''';
  }

  Future<bool> _tablaExiste(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  Future<bool> _columnaExiste(Database db, String tabla, String columna) async {
    final result = await db.rawQuery("PRAGMA table_info($tabla)");
    return result.any((col) => col['name'] == columna);
  }

  void _appendHybridOperationMetadata(
    Map<String, dynamic> insertData, {
    int? turnoId,
    String? frenteOrigen,
    int? registradorId,
    int? registradorUsuarioId,
    String? registrador,
    String? registradorNombre,
    int? laborId,
    String? labor,
    String? ala,
    int? alaId,
  }) {
    final resolvedRegistradorId = registradorId ?? registradorUsuarioId;
    final resolvedRegistrador = registrador ?? registradorNombre;

    if (turnoId != null) insertData['turno_id'] = turnoId;
    if (frenteOrigen != null && frenteOrigen.trim().isNotEmpty) {
      insertData['frente_origen'] = frenteOrigen.trim();
    }
    if (resolvedRegistradorId != null) {
      insertData['registrador_id'] = resolvedRegistradorId;
    }
    if (laborId != null) insertData['labor_id'] = laborId;
    if (labor != null && labor.trim().isNotEmpty) {
      insertData['labor'] = labor.trim();
    }
    if (resolvedRegistrador != null && resolvedRegistrador.trim().isNotEmpty) {
      insertData['registrador'] = resolvedRegistrador.trim();
    }
    if (ala != null && ala.trim().isNotEmpty) {
      insertData['ala'] = ala.trim();
    }
    if (alaId != null) {
      insertData['ala_id'] = alaId;
    }
  }

  Future<List<Map<String, dynamic>>> _queryAndHydrateOperations(
    String tableName,
    int turnoId,
    String fecha, {
    int? operadorId,
    bool onlyActive = false,
  }) async {
    final db = await database;

    late final String where;
    late final List<dynamic> whereArgs;
    if (onlyActive) {
      where = operadorId != null
          ? 'turno_id = ? AND fecha = ? AND operador_id = ? AND cerrado = ?'
          : 'turno_id = ? AND fecha = ? AND cerrado = ?';
      whereArgs = operadorId != null
          ? [turnoId, fecha, operadorId, 0]
          : [turnoId, fecha, 0];
    } else {
      where = operadorId != null
          ? 'turno_id = ? AND fecha = ? AND operador_id = ?'
          : 'turno_id = ? AND fecha = ?';
      whereArgs = operadorId != null
          ? [turnoId, fecha, operadorId]
          : [turnoId, fecha];
    }

    final rows = await db.query(tableName, where: where, whereArgs: whereArgs);
    return _normalizeOperationRows(rows);
  }

  List<Map<String, dynamic>> _normalizeOperationRows(
    List<Map<String, dynamic>> rows,
  ) {
    if (rows.isEmpty) return rows;

    return rows.map((row) {
      final normalized = Map<String, dynamic>.from(row);
      final cerrado = _asInt(row['cerrado']) ?? 0;
      final enviado = _asInt(row['enviado']) ?? 0;

      normalized['estado'] = cerrado == 1 ? 'cerrado' : 'activo';
      normalized['envio'] = enviado;
      normalized['registrador_usuario_id'] = row['registrador_id'];
      normalized['registrador_nombre'] = row['registrador'];
      normalized['jefeGuardia'] = row['jefe_guardia'];
      return normalized;
    }).toList();
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<int?> _resolveAlaId(dynamic rawAlaId, dynamic rawAla) async {
    final alaId = _asInt(rawAlaId);
    if (alaId != null) return alaId;

    final ala = rawAla?.toString().trim() ?? '';
    if (ala.isEmpty) return null;

    final db = await sharedCatalogDatabase;
    final rows = await db.query(
      'ala',
      columns: ['ala_id'],
      where: 'LOWER(nombre) = ?',
      whereArgs: [ala.toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _asInt(rows.first['ala_id']);
  }

  Future<Map<String, dynamic>> _buildOperationHeaderUpdateData(
    Map<String, dynamic>? operacionData,
  ) async {
    if (operacionData == null || operacionData.isEmpty) {
      return <String, dynamic>{};
    }

    final updateData = <String, dynamic>{};
    final laborId = _asInt(operacionData['labor_id']);
    if (laborId != null) {
      updateData['labor_id'] = laborId;
    }

    final frenteOrigen =
        operacionData['frente_origen']?.toString().trim() ?? '';
    if (frenteOrigen.isNotEmpty) {
      updateData['frente_origen'] = frenteOrigen;
    }

    final labor = operacionData['labor']?.toString().trim() ?? '';
    if (labor.isNotEmpty) {
      updateData['labor'] = labor;
    }

    final ala = operacionData['ala']?.toString().trim() ?? '';
    if (ala.isNotEmpty) {
      updateData['ala'] = ala;
    }

    final alaId = await _resolveAlaId(
      operacionData['ala_id'],
      operacionData['ala'],
    );
    if (alaId != null) {
      updateData['ala_id'] = alaId;
    }

    return updateData;
  }

  Future<List<Map<String, dynamic>>> _getNormalizedOperationRows(
    String tableName, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    final rows = await db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );
    return _normalizeOperationRows(rows);
  }

  static const _sharedTables = {
    'Equipo',
    'tipo_horometro',
    'equipo_horometro_tipos',
    'checklist_items',
    'Guardia',
    'jefe_guardias',
    'usuario_directorio',
    'dim_periodo',
    'PlanMetrajeTL',
    'minas',
    'zona',
    'area',
    'fase',
    'tipo_labor',
    'estructura_mineral',
    'nivel',
    'ala',
    'labores',
    'dim_turno',
    'planes_metrajes_avances',
    'planes_produccion',
    'destinos',
    'tipo_perforaciones',
    'longitud_barras',
    'pernos',
    'mallas',
  };

  Future<Database> _getDbForTable(String table) async {
    return _sharedTables.contains(table)
        ? await sharedCatalogDatabase
        : await database;
  }

  // Insertar datos en cualquier tabla
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await _getDbForTable(table);
    return await db.insert(table, data);
  }

  // Obtener todos los registros de cualquier tabla
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await _getDbForTable(table);
    return await db.query(table);
  }

  // Eliminar un registro de cualquier tabla
  Future<int> delete(String table, int id) async {
    final db = await _getDbForTable(table);
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // Método para eliminar todos los registros de una tabla
  Future<int> deleteAll(String table) async {
    final db = await _getDbForTable(table);
    return await db.delete(table);
  }

  // Actualizar un registro en cualquier tabla
  Future<int> update(String table, Map<String, dynamic> data, int id) async {
    final db = await _getDbForTable(table);
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  static void setDatabasePathOverride(String? path) {
    _databasePathOverride = path;
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    if (_sharedCatalogDatabase != null) {
      await _sharedCatalogDatabase!.close();
      _sharedCatalogDatabase = null;
    }
  }

  Future<bool> userExistsLocally(String dni) async {
    try {
      final sharedDb = await sharedCatalogDatabase;
      final count = Sqflite.firstIntValue(
        await sharedDb.rawQuery(
          'SELECT COUNT(*) FROM usuario_directorio WHERE codigo_dni = ?',
          [dni],
        ),
      );
      if (count != null && count > 0) return true;
    } catch (_) {}

    return false;
  }

  Future<bool> loginOffline(String dni, String password) async {
    try {
      final sharedDb = await sharedCatalogDatabase;
      final rows = await sharedDb.query(
        'usuario_directorio',
        columns: ['password', 'nombres', 'apellidos', 'rol', 'id'],
        where: 'codigo_dni = ?',
        whereArgs: [dni],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final hash = rows.first['password'] as String?;
        if (hash != null && hash.isNotEmpty) {
          if (BCrypt.checkpw(password, hash)) {
            await setCurrentUserDni(dni);
            return true;
          }
        }
        return false;
      }
    } catch (_) {}

    return false;
  }

  Future<Map<String, dynamic>?> getUserByDni(String dni) async {
    final db = await sharedCatalogDatabase;
    final List<Map<String, dynamic>> result = await db.query(
      'usuario_directorio',
      where: 'codigo_dni = ?',
      whereArgs: [dni],
    );

    if (result.isNotEmpty) {
      final user = Map<String, dynamic>.from(result.first);
      user['id'] = user['id'] ?? user['codigo_dni'];
      user['createdAt'] = user['createdAt'] ?? user['updated_at'];
      user['updatedAt'] = user['updated_at'];
      user['password'] = user['password'] ?? '';
      return user;
    }
    return null;
  }

  Future<bool> userHasCargo(String dni, List<String> cargosPermitidos) async {
    final user = await getUserByDni(dni);
    if (user == null) return false;
    final cargoId = user['cargo_id'];
    if (cargoId == null) return false;
    final db = await sharedCatalogDatabase;
    final result = await db.query(
      'cargos',
      columns: ['nombre'],
      where: 'cargo_id = ?',
      whereArgs: [cargoId],
      limit: 1,
    );
    if (result.isEmpty) return false;
    final nombre =
        (result.first['nombre'] as String?)?.trim().toUpperCase() ?? '';
    return cargosPermitidos.any((c) => c.toUpperCase() == nombre);
  }

  Future<List<Map<String, dynamic>>> getKnownOperators() async {
    final db = await sharedCatalogDatabase;
    final users = await db.query('usuario_directorio');
    return users.asMap().entries.map((entry) {
      final u = Map<String, dynamic>.from(entry.value);
      u['id'] = u['id'] ?? entry.key + 1;
      u['nombre_completo'] = '${u['nombres']} ${u['apellidos']}';
      return u;
    }).toList();
  }

  //ESTADOS
  Future<List<Map<String, dynamic>>> getOrigenDestino(
    String proceso,
    String tipo,
  ) async {
    final db = await database;

    return await db.query(
      'origen_destino',
      where: 'proceso = ? AND tipo = ?',
      whereArgs: [proceso, tipo],
    );
  }

  Map<String, dynamic> _defaultControlLlantas() {
    return {'numero1': true, 'numero2': true, 'numero3': true, 'numero4': true};
  }

  Future<Map<String, dynamic>> _getControlLlantasFromTable(
    String tableName,
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      tableName,
      columns: ['control_llantas'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      return _defaultControlLlantas();
    }

    final controlJson = result.first['control_llantas'] as String? ?? '{}';

    try {
      final control = jsonDecode(controlJson);
      if (control is Map<String, dynamic>) {
        return {..._defaultControlLlantas(), ...control};
      }
      if (control is Map) {
        return {
          ..._defaultControlLlantas(),
          ...control.map((key, value) => MapEntry(key.toString(), value)),
        };
      }
      return _defaultControlLlantas();
    } catch (e) {
      print('Error decodificando control de llantas: $e');
      return _defaultControlLlantas();
    }
  }

  //CHECKLIST
  Future<List<Map<String, dynamic>>> getCheckListByProceso(
    String proceso,
  ) async {
    final db = await sharedCatalogDatabase;
    final processNames = _buildChecklistProcessNames(proceso);
    final result = await db.query(
      'checklist_items',
      where: 'proceso IN (${List.filled(processNames.length, '?').join(', ')})',
      whereArgs: processNames,
      orderBy: 'categoria_orden ASC, orden ASC, id ASC',
    );
    return result;
  }

  List<String> _buildChecklistProcessNames(String proceso) {
    final trimmed = proceso.trim();
    final normalized = _normalizeChecklistProcessName(trimmed);
    final names = <String>{trimmed};

    if (normalized.isNotEmpty) {
      names.add(normalized);
    }

    // Legacy/current API variants may differ only by accents.
    if (normalized == 'PERFORACION HORIZONTAL') {
      names.add('PERFORACIÓN HORIZONTAL');
    }
    if (normalized == 'PERFORACION TALADROS LARGOS') {
      names.add('PERFORACIÓN TALADROS LARGOS');
    }
    if (normalized == 'SOSTENIMIENTO') {
      names.add('EMPERNADOR');
    }

    return names.toList();
  }

  String _normalizeChecklistProcessName(String value) {
    const replacements = {
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ü': 'U',
      'á': 'A',
      'é': 'E',
      'í': 'I',
      'ó': 'O',
      'ú': 'U',
      'ü': 'U',
    };

    final buffer = StringBuffer();
    for (final rune in value.runes) {
      buffer.write(
        replacements[String.fromCharCode(rune)] ?? String.fromCharCode(rune),
      );
    }

    return buffer.toString().trim().toUpperCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
  }

  Future<List<TipoHorometro>> getTiposHorometro() async {
    final db = await sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query('tipo_horometro');

    return List.generate(maps.length, (i) => TipoHorometro.fromJson(maps[i]));
  }

  Future<List<EquipoHorometroTipo>> getEquipoHorometroTipos() async {
    final db = await sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'equipo_horometro_tipos',
    );

    return List.generate(
      maps.length,
      (i) => EquipoHorometroTipo.fromJson(maps[i]),
    );
  }

  Future<List<Map<String, dynamic>>> getEquipoHorometroTiposByEquipoId(
    int equipoId,
  ) async {
    final db = await sharedCatalogDatabase;
    return await db.query(
      'equipo_horometro_tipos',
      where: 'equipo_id = ?',
      whereArgs: [equipoId],
    );
  }

  //PARA TODOS LAS OPERACIONES------------------------------------------------------------

  Future<List<String>> getJefesGuardiaNombres() async {
    final db = await sharedCatalogDatabase;

    try {
      final result = await db.query(
        'jefe_guardias',
        columns: ['nombres', 'apellidos'],
        orderBy: 'apellidos ASC, nombres ASC',
      );

      final nombresCompletos = result.map((row) {
        final nombres = row['nombres'] as String? ?? '';
        final apellidos = row['apellidos'] as String? ?? '';
        return '$nombres $apellidos'.trim();
      }).toList();

      return nombresCompletos;
    } catch (e) {
      print("Error al obtener nombres de jefes de guardia: $e");
      return [];
    }
  }

  Future<List<Equipo>> getEquipos() async {
    final db = await sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query('Equipo');
    return List.generate(maps.length, (i) => Equipo.fromJson(maps[i]));
  }

  Future<Map<String, dynamic>?> getEquipoUltimosHorometros(
    int equipoId,
  ) async {
    final db = await sharedCatalogDatabase;
    final maps = await db.query(
      'Equipo',
      columns: ['ultimos_horometros'],
      where: 'id = ?',
      whereArgs: [equipoId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final raw = maps.first['ultimos_horometros'];
    if (raw == null) return null;
    try {
      if (raw is Map) return Map<String, dynamic>.from(raw);
      final decoded = jsonDecode(raw.toString());
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  Future<void> updateEquipoUltimosHorometros(
    int equipoId,
    Map<String, dynamic> horometros,
  ) async {
    final db = await sharedCatalogDatabase;
    final now = jsonEncode(horometros);
    await db.update(
      'Equipo',
      {'ultimos_horometros': now},
      where: 'id = ?',
      whereArgs: [equipoId],
    );
  }

  Future<List<Guardia>> getGuardias() async {
    final db = await sharedCatalogDatabase;

    final List<Map<String, dynamic>> maps = await db.query('Guardia');

    return List.generate(maps.length, (i) => Guardia.fromJson(maps[i]));
  }

  Future<List<Zona>> getZonasByProceso(String proceso) async {
    final db = await sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'zona',
      orderBy: 'nombre ASC',
    );
    return List.generate(maps.length, (i) => Zona.fromJson(maps[i]));
  }

  Future<List<Zona>> getZonas() async {
    final db = await sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query('zona');
    return List.generate(maps.length, (i) => Zona.fromJson(maps[i]));
  }

  Future<List<JefeGuardia>> getJefesGuardia() async {
    final db = await sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'jefe_guardias',
      orderBy: 'apellidos ASC, nombres ASC',
    );
    return List.generate(maps.length, (i) => JefeGuardia.fromJson(maps[i]));
  }

  Future<List<DimPeriodo>> getPeriodos() async {
    final db = await sharedCatalogDatabase;
    final maps = await db.query(
      'dim_periodo',
      orderBy: 'anno DESC, numero DESC',
    );
    return List.generate(maps.length, (i) => DimPeriodo.fromJson(maps[i]));
  }

  Future<DimPeriodo?> getPeriodoVigente({
    DateTime? forDate,
    String? tipo,
  }) async {
    final db = await sharedCatalogDatabase;
    final targetDate = (forDate ?? DateTime.now())
        .toIso8601String()
        .split('T')
        .first;
    final whereClause = StringBuffer('fecha_inicio <= ? AND fecha_fin >= ?');
    final whereArgs = <Object>[targetDate, targetDate];

    if (tipo != null && tipo.isNotEmpty) {
      whereClause.write(' AND tipo = ?');
      whereArgs.add(tipo);
    }

    final maps = await db.query(
      'dim_periodo',
      where: whereClause.toString(),
      whereArgs: whereArgs,
      orderBy: 'anno DESC, numero DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DimPeriodo.fromJson(maps.first);
  }

  Future<List<DimMina>> getMinas() async {
    final db = await sharedCatalogDatabase;
    final maps = await db.query('minas', orderBy: 'nombre ASC');
    return List.generate(maps.length, (i) => DimMina.fromJson(maps[i]));
  }

  Future<List<DimZona>> getDimZonas() async {
    final db = await sharedCatalogDatabase;
    final maps = await db.query('zona', orderBy: 'nombre ASC');
    return List.generate(maps.length, (i) => DimZona.fromJson(maps[i]));
  }

  Future<List<DimArea>> getAreas() async {
    final db = await sharedCatalogDatabase;
    final maps = await db.query('area', orderBy: 'nombre ASC');
    return List.generate(maps.length, (i) => DimArea.fromJson(maps[i]));
  }

  Future<List<DimFase>> getFases() async {
    final db = await sharedCatalogDatabase;
    final maps = await db.query('fase', orderBy: 'nombre ASC');
    return List.generate(maps.length, (i) => DimFase.fromJson(maps[i]));
  }

  Future<List<DimTipoLabor>> getTiposLabor() async {
    final db = await sharedCatalogDatabase;
    final maps = await db.query('tipo_labor', orderBy: 'nombre ASC');
    return List.generate(maps.length, (i) => DimTipoLabor.fromJson(maps[i]));
  }

  Future<List<DimEstructuraMineral>> getEstructurasMinerales() async {
    final db = await sharedCatalogDatabase;
    final maps = await db.query('estructura_mineral', orderBy: 'nombre ASC');
    return List.generate(
      maps.length,
      (i) => DimEstructuraMineral.fromJson(maps[i]),
    );
  }

  Future<List<DimNivel>> getNiveles() async {
    final db = await sharedCatalogDatabase;
    final maps = await db.query('nivel', orderBy: 'nombre ASC');
    return List.generate(maps.length, (i) => DimNivel.fromJson(maps[i]));
  }

  Future<List<DimAla>> getAlas() async {
    final db = await sharedCatalogDatabase;
    final maps = await db.query('ala', orderBy: 'orden ASC, nombre ASC');
    return List.generate(maps.length, (i) => DimAla.fromJson(maps[i]));
  }

  Future<List<DimLabor>> getLabores() async {
    final db = await sharedCatalogDatabase;
    final maps = await db.query('labores', orderBy: 'nombre_labor ASC');
    return List.generate(maps.length, (i) => DimLabor.fromJson(maps[i]));
  }

  Future<List<DimTurno>> getDimTurnos() async {
    final db = await sharedCatalogDatabase;
    final maps = await db.query('dim_turno', orderBy: 'nombre ASC');
    return List.generate(maps.length, (i) => DimTurno.fromJson(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getEstadosByProcesoAndCategoria(
    int procesoId,
    int categoriaId,
  ) async {
    final db = await sharedCatalogDatabase;
    return await db.query(
      'estados',
      where: 'proceso_id = ? AND categoria_id = ?',
      whereArgs: [procesoId, categoriaId],
      orderBy: 'codigo ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getCategoriasEstados() async {
    final db = await sharedCatalogDatabase;
    return await db.query(
      'categorias_estados',
      where: 'activo = 1',
      orderBy: 'nombre ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getProcesos() async {
    final db = await sharedCatalogDatabase;
    return await db.query('procesos', orderBy: 'nombre ASC');
  }

  Future<Map<String, dynamic>?> getProcesoById(int id) async {
    final db = await sharedCatalogDatabase;
    final rows = await db.query(
      'procesos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<List<Map<String, dynamic>>> getDestinosByProcesoId(
    int procesoId,
  ) async {
    final db = await sharedCatalogDatabase;
    return await db.query(
      'destinos',
      where: 'proceso_id = ?',
      whereArgs: [procesoId],
      orderBy: 'nombre ASC',
    );
  }

  Future<List<TipoPerforacion>> getTiposPerforacionByProcesoId(
    int procesoId,
  ) async {
    final db = await sharedCatalogDatabase;

    final List<Map<String, dynamic>> maps = await db.query(
      'tipo_perforaciones',
      where: 'proceso_id = ?',
      whereArgs: [procesoId],
    );

    return List.generate(maps.length, (i) => TipoPerforacion.fromJson(maps[i]));
  }

  Future<List<PlanMetrajeTL>> getPlanesMetrajeTL() async {
    final db = await sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query('PlanMetrajeTL');
    return List.generate(maps.length, (i) => PlanMetrajeTL.fromJson(maps[i]));
  }

  Future<List<PlanAvanceTH>> getPlanesAvanceTH() async {
    final db = await sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'planes_metrajes_avances',
    );
    return List.generate(maps.length, (i) => PlanAvanceTH.fromJson(maps[i]));
  }

  Future<List<PlanProduccion>> getPlanesProduccion() async {
    final db = await sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query('planes_produccion');
    return List.generate(maps.length, (i) => PlanProduccion.fromJson(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getLongitudBarrasPorProceso(
    String proceso,
  ) async {
    final db = await sharedCatalogDatabase;

    return await db.query(
      'longitud_barras',
      where: 'proceso = ?',
      whereArgs: [proceso],
    );
  }

  Future<List<Map<String, dynamic>>> getPernos() async {
    final db = await sharedCatalogDatabase;

    return await db.query('pernos');
  }

  Future<List<Map<String, dynamic>>> getMallas() async {
    final db = await sharedCatalogDatabase;

    return await db.query('mallas');
  }

  //OPERACION TALADRO LARGO  INICIO --------------------------------------------------------------------------------------------------------------
  Future<int> insertOperacionTalLargo(
    String fecha, {
    String? turno,
    String? operador,
    String? jefeGuardia,
    String? equipo,
    String? registradorNombre,
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? horometrosBase,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    int? registradorUsuarioId,
    int? laborId,
    String? labor,
  }) async {
    final db = await database;

    Map<String, dynamic> horometrosJson = {
      'diesel': {'inicio': 0, 'final': 0, 'op': true},
      'electrico': {'inicio': 0, 'final': 0, 'op': true},
      'percusion': {'inicio': 0, 'final': 0, 'op': true},
    };

    if (horometrosBase != null && horometrosBase.isNotEmpty) {
      for (var item in horometrosBase) {
        final tipo = item['tipo_horometro'];
        final finalValor = (item['final'] ?? 0).toDouble();
        if (horometrosJson.containsKey(tipo)) {
          horometrosJson[tipo]['inicio'] = finalValor;
        }
      }
    }

    Map<String, dynamic> condicionesEquipoJson = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '',
    };

    final controlLlantasJson = _defaultControlLlantas();

    String checkListStr = jsonEncode(checkListJson ?? []);

    final insertData = <String, dynamic>{
      'fecha': fecha,
      'turno': turno,
      'operador': operador,
      'jefe_guardia': jefeGuardia,
      'equipo': equipo,
      'horometros': jsonEncode(horometrosJson),
      'condiciones_equipo': jsonEncode(condicionesEquipoJson),
      'check_list': checkListStr,
      'control_llantas': jsonEncode(controlLlantasJson),
    };
    if (operadorId != null) insertData['operador_id'] = operadorId;
    if (equipoId != null) insertData['equipo_id'] = equipoId;
    if (jefeGuardiaId != null) insertData['jefe_guardia_id'] = jefeGuardiaId;
    _appendHybridOperationMetadata(
      insertData,
      turnoId: turnoId,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_tal_largo', insertData);
  }

  Future<int> eliminarOperacionTalLargoFisico(int id) async {
    final db = await database;

    final result = await db.delete(
      'Operacion_tal_largo',
      where: 'id = ?',
      whereArgs: [id],
    );

    return result; // devuelve el número de filas eliminadas
  }

  Future<List<Map<String, dynamic>>> getOperacionTalLargoByTurnoAndFechaMaster(
    int turnoId,
    String fecha,
  ) async {
    return _queryAndHydrateOperations(
      'Operacion_tal_largo',
      turnoId,
      fecha,
      onlyActive: true,
    );
  }

  Future<List<Map<String, dynamic>>> getOperacionTalLargoByTurnoAndFecha(
    int turnoId,
    String fecha, {
    int? operadorId,
  }) async {
    return _queryAndHydrateOperations(
      'Operacion_tal_largo',
      turnoId,
      fecha,
      operadorId: operadorId,
    );
  }

  Future<bool> existeOperacionEnTurno({
    required String tableName,
    required int turnoId,
    required String fecha,
    required int operadorId,
  }) async {
    final db = await database;
    final result = await db.query(
      tableName,
      columns: ['id'],
      where: 'turno_id = ? AND fecha = ? AND operador_id = ? AND cerrado = ?',
      whereArgs: [turnoId, fecha, operadorId, 0],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Función para cerrar un estado (actualizar hora_final de un estado específico)
  Future<bool> updateHoraFinal(
    int operacionId,
    int estadoId,
    String horaFinal, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await database;

    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      return false;
    }

    String registrosJson = result.first['registros'] as String? ?? '[]';
    List<dynamic> registros = jsonDecode(registrosJson);

    bool encontrado = false;
    String tipoEstado = "";

    for (var i = 0; i < registros.length; i++) {
      if (registros[i]['id'].toString() == estadoId.toString()) {
        tipoEstado = registros[i]['estado']; // Guardar el tipo para log
        registros[i]['hora_final'] = horaFinal;
        encontrado = true;
        break;
      }
    }

    if (!encontrado) {
      print("⚠ Estado no encontrado en JSON");
      return false;
    }

    int updated = await db.update(
      tableName,
      {'registros': jsonEncode(registros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    print("✔ Hora final actualizada para estado $tipoEstado: $horaFinal");
    return updated > 0;
  }

  Future<Map<String, dynamic>?> createEstado(
    int operacionId,
    String estado,
    String codigo,
    String horaInicio, {
    String? horaFinal,
    Map<String, dynamic>? operacion,
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await database;

    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      return null;
    }

    String registrosJson = result.first['registros'] as String? ?? '[]';
    List<dynamic> registros = jsonDecode(registrosJson);

    int nuevoNumero = 1;
    if (registros.isNotEmpty) {
      int ultimoNumero = registros.last['numero'] ?? 0;
      nuevoNumero = ultimoNumero + 1;
    }

    int nuevoId = DateTime.now().millisecondsSinceEpoch + registros.length;

    Map<String, dynamic> nuevoEstado = {
      'id': nuevoId,
      'numero': nuevoNumero,
      'estado': estado,
      'codigo': codigo,
      'hora_inicio': horaInicio,
      'hora_final': horaFinal,
      'operacion': {...?operacion},
    };

    registros.add(nuevoEstado);
    final updateData = <String, dynamic>{'registros': jsonEncode(registros)};
    updateData.addAll(
      await _buildOperationHeaderUpdateData(
        operacion == null ? null : Map<String, dynamic>.from(operacion),
      ),
    );
    await db.update(
      tableName,
      updateData,
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return nuevoEstado;
  }

  // Función para actualizar un estado completo
  Future<bool> updateEstado(
    int operacionId,
    int estadoId, {
    int? numero,
    String? estado,
    String? codigo,
    String? horaInicio,
    String? horaFinal,
    Map<String, dynamic>? operacion,
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await database;

    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      return false;
    }

    // 2. Parsear el JSON de registros
    String registrosJson = result.first['registros'] as String? ?? '[]';
    List<dynamic> registros = jsonDecode(registrosJson);

    // 3. Buscar y actualizar el estado específico
    bool encontrado = false;
    for (var i = 0; i < registros.length; i++) {
      if (registros[i]['id'] == estadoId) {
        // Actualizar solo los campos proporcionados
        if (numero != null) registros[i]['numero'] = numero;
        if (estado != null) registros[i]['estado'] = estado;
        if (codigo != null) registros[i]['codigo'] = codigo;
        if (horaInicio != null) registros[i]['hora_inicio'] = horaInicio;
        if (horaFinal != null) registros[i]['hora_final'] = horaFinal;
        if (operacion != null) {
          registros[i]['operacion'] = {
            ...registros[i]['operacion'] as Map,
            ...operacion,
          };
        }
        encontrado = true;
        break;
      }
    }

    if (!encontrado) {
      return false;
    }

    final updateData = <String, dynamic>{'registros': jsonEncode(registros)};
    if (operacion != null) {
      updateData.addAll(
        await _buildOperationHeaderUpdateData(
          Map<String, dynamic>.from(operacion),
        ),
      );
    }

    int updated = await db.update(
      tableName,
      updateData,
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  // Función para obtener todos los estados de una operación
  Future<List<Map<String, dynamic>>> getEstadosByOperacionId(
    int operacionId, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await database;

    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      return [];
    }

    String registrosJson = result.first['registros'] as String? ?? '[]';
    List<dynamic> registros = jsonDecode(registrosJson);

    return registros.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<bool> deleteEstado(
    int operacionId,
    int estadoId, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await database;

    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) return false;

    // 2. Parsear JSON
    String registrosJson = result.first['registros'] as String? ?? '[]';
    List<dynamic> registros = jsonDecode(registrosJson);

    if (registros.isEmpty) return false;

    // 3. Convertir todo a Map seguro
    List<Map<String, dynamic>> lista = registros
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // 4. Ordenar por numero (orden real)
    lista.sort((a, b) {
      return (a['numero'] ?? 0).compareTo(b['numero'] ?? 0);
    });

    // 5. Buscar el estado a eliminar
    Map<String, dynamic>? estadoAEliminar;
    for (var e in lista) {
      if (e['id'] == estadoId) {
        estadoAEliminar = e;
        break;
      }
    }

    if (estadoAEliminar == null) return false;

    int numeroEliminar = estadoAEliminar['numero'] ?? 0;

    // 6. Filtrar (eliminar en cascada desde ese numero)
    List<Map<String, dynamic>> nuevosRegistros = [];
    List<Map<String, dynamic>> eliminados = [];

    for (var e in lista) {
      int numero = e['numero'] ?? 0;

      if (numero < numeroEliminar) {
        nuevosRegistros.add(e);
      } else {
        eliminados.add({
          'id': e['id'],
          'estado': e['estado'],
          'numero': numero,
          'hora_inicio': e['hora_inicio'],
        });
      }
    }

    // Debug
    print("🗑️ Eliminados: ${eliminados.length}");
    for (var e in eliminados) {
      print("   - ${e['estado']} #${e['numero']} (${e['hora_inicio']})");
    }

    // 7. Renumerar secuencialmente
    for (int i = 0; i < nuevosRegistros.length; i++) {
      nuevosRegistros[i]['numero'] = i + 1;
    }

    // 8. Reconstruir horas finales (solo encadenar)
    for (int i = 0; i < nuevosRegistros.length; i++) {
      if (i < nuevosRegistros.length - 1) {
        nuevosRegistros[i]['hora_final'] =
            nuevosRegistros[i + 1]['hora_inicio'] ?? '';
      } else {
        nuevosRegistros[i]['hora_final'] = "";
      }
    }

    int updated = await db.update(
      tableName,
      {'registros': jsonEncode(nuevosRegistros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    print("📊 Final: ${nuevosRegistros.length} registros");

    return updated > 0;
  }

  //horometros -taladro largo
  // Función para obtener los horómetros de una operación
  Future<Map<String, dynamic>> getHorometrosByOperacionId(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_tal_largo',
      columns: ['horometros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      // Si no hay datos, devolver estructura por defecto
      return {
        'diesel': {'inicio': 0, 'final': 0, 'op': true},
        'electrico': {'inicio': 0, 'final': 0, 'op': true},
        'percusion': {'inicio': 0, 'final': 0, 'op': true},
      };
    }

    String horometrosJson = result.first['horometros'] as String? ?? '{}';

    try {
      Map<String, dynamic> horometros = jsonDecode(horometrosJson);
      return horometros;
    } catch (e) {
      print('Error decodificando horómetros: $e');
      // Si hay error, devolver estructura por defecto
      return {
        'diesel': {'inicio': 0, 'final': 0, 'op': true},
        'electrico': {'inicio': 0, 'final': 0, 'op': true},
        'percusion': {'inicio': 0, 'final': 0, 'op': true},
      };
    }
  }

  // Función para actualizar los horómetros de una operación
  Future<bool> updateHorometros(
    int operacionId,
    Map<String, dynamic> horometros,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_tal_largo',
      {'horometros': jsonEncode(horometros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  // Obtener condiciones de equipo por operacionId
  Future<Map<String, dynamic>> getCondicionesEquipoByOperacionId(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_tal_largo',
      columns: ['condiciones_equipo'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    Map<String, dynamic> defaultData = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '', // ✅ nuevo campo
    };

    if (result.isEmpty) {
      return defaultData;
    }

    String condicionesJson =
        result.first['condiciones_equipo'] as String? ?? '{}';

    try {
      Map<String, dynamic> condiciones = jsonDecode(condicionesJson);

      // 🔥 asegurar que el nuevo campo exista
      condiciones.putIfAbsent('horaLlenado', () => '');

      return condiciones;
    } catch (e) {
      print('Error decodificando condiciones de equipo: $e');
      return defaultData;
    }
  }

  // Actualizar condiciones de equipo de una operación
  Future<bool> updateCondicionesEquipo(
    int operacionId,
    Map<String, dynamic> condiciones,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_tal_largo',
      {'condiciones_equipo': jsonEncode(condiciones)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  // Obtener checklist por operacionId
  Future<List<Map<String, dynamic>>> getCheckListByOperacionId(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_tal_largo',
      columns: ['check_list'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      // Si no hay datos, devolver lista vacía
      return [];
    }

    String checkListJson = result.first['check_list'] as String? ?? '[]';

    try {
      List<dynamic> lista = jsonDecode(checkListJson);
      // Asegurarse de que cada item sea Map<String, dynamic>
      return lista.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error decodificando checklist: $e');
      return [];
    }
  }

  // Actualizar checklist de una operación
  Future<bool> updateCheckList(
    int operacionId,
    List<Map<String, dynamic>> checkList,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_tal_largo',
      {'check_list': jsonEncode(checkList)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  // Obtener control de llantas por operacionId
  Future<Map<String, dynamic>> getControlLlantasByOperacionId(
    int operacionId,
  ) async {
    return _getControlLlantasFromTable('Operacion_tal_largo', operacionId);
  }

  // Actualizar control de llantas de una operación
  Future<bool> updateControlLlantasTLargos(
    int operacionId,
    Map<String, dynamic> controlLlantas,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_tal_largo',
      {'control_llantas': jsonEncode(controlLlantas)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<Map<String, dynamic>> getOperacionByEstadoId(
    int operacionId,
    int estadoId, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await database;

    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      // Si no hay datos, devolver estructura por defecto
      return {
        'nivel': '',
        'tipo_labor': '',
        'labor': '',
        'ala': '',
        // ✅ Nuevos campos para taladros
        'n_taladros_produccion': '',
        'metros_perforados_produccion': '',
        'n_taladros_rimados': '',
        'metros_perforados_rimados': '',
        'n_taladros_alivio': '',
        'metros_perforados_alivio': '',
        'n_taladros_repaso': '',
        'metros_perforados_repaso': '',
        // Campos que se mantienen
        'long_barras': '',
        'num_barras': '',
        'tipo_perforacion': '',
        'observaciones': '',
      };
    }

    String registrosJson = result.first['registros'] as String? ?? '[]';

    try {
      List<dynamic> registros = jsonDecode(registrosJson);

      // Buscar el estado específico por su ID
      var estadoEncontrado = registros.firstWhere(
        (estado) => estado['id'] == estadoId,
        orElse: () => null,
      );

      if (estadoEncontrado != null &&
          estadoEncontrado.containsKey('operacion')) {
        return estadoEncontrado['operacion'] as Map<String, dynamic>;
      } else {
        // Si no se encuentra o no tiene operacion, devolver estructura por defecto
        return {
          'nivel': '',
          'tipo_labor': '',
          'labor': '',
          'ala': '',
          // ✅ Nuevos campos para taladros
          'n_taladros_produccion': '',
          'metros_perforados_produccion': '',
          'n_taladros_rimados': '',
          'metros_perforados_rimados': '',
          'n_taladros_alivio': '',
          'metros_perforados_alivio': '',
          'n_taladros_repaso': '',
          'metros_perforados_repaso': '',
          // Campos que se mantienen
          'long_barras': '',
          'num_barras': '',
          'tipo_perforacion': '',
          'observaciones': '',
        };
      }
    } catch (e) {
      print('Error decodificando registros: $e');
      return {
        'nivel': '',
        'tipo_labor': '',
        'labor': '',
        'ala': '',
        // ✅ Nuevos campos para taladros
        'n_taladros_produccion': '',
        'metros_perforados_produccion': '',
        'n_taladros_rimados': '',
        'metros_perforados_rimados': '',
        'n_taladros_alivio': '',
        'metros_perforados_alivio': '',
        'n_taladros_repaso': '',
        'metros_perforados_repaso': '',
        // Campos que se mantienen
        'long_barras': '',
        'num_barras': '',
        'tipo_perforacion': '',
        'observaciones': '',
      };
    }
  }

  // Actualizar los datos de perforación de un estado específico
  Future<bool> updateOperacionByEstadoId(
    int operacionId,
    int estadoId,
    Map<String, dynamic> operacionData, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await database;

    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      return false;
    }

    String registrosJson = result.first['registros'] as String? ?? '[]';

    try {
      List<dynamic> registros = jsonDecode(registrosJson);
      bool encontrado = false;

      // Buscar y actualizar el estado específico
      for (var i = 0; i < registros.length; i++) {
        if (registros[i]['id'] == estadoId) {
          // Mantener todos los datos del estado, solo actualizar el campo 'operacion'
          registros[i]['operacion'] = operacionData;
          encontrado = true;
          break;
        }
      }

      if (!encontrado) {
        print('⚠ Estado no encontrado en JSON');
        return false;
      }

      final updateData = <String, dynamic>{'registros': jsonEncode(registros)};
      updateData.addAll(await _buildOperationHeaderUpdateData(operacionData));

      int updated = await db.update(
        tableName,
        updateData,
        where: 'id = ?',
        whereArgs: [operacionId],
      );

      print('✔ Datos de perforación actualizados para estado $estadoId');
      return updated > 0;
    } catch (e) {
      print('Error actualizando datos de perforación: $e');
      return false;
    }
  }

  Future<void> cerrarOperacion(
    int operacionId, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final Database db = await DatabaseHelper().database;

    await db.update(
      tableName,
      {'cerrado': 1},
      where: 'id = ?',
      whereArgs: [operacionId],
    );
  }

  Future<Map<String, dynamic>?> createReservaEstado(
    int operacionId,
    int numero,
    String horaInicio,
    String horaFinal, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await database;

    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) return null;

    String registrosJson = result.first['registros'] as String? ?? '[]';
    List<dynamic> registros = jsonDecode(registrosJson);

    int nuevoId = DateTime.now().millisecondsSinceEpoch + registros.length;

    Map<String, dynamic> nuevoEstado = {
      'id': nuevoId,
      'numero': numero,
      'estado': 'RESERVA',
      'codigo': '401',
      'hora_inicio': horaInicio,
      'hora_final': horaFinal,
      'operacion': <String, dynamic>{},
    };

    registros.add(nuevoEstado);

    await db.update(
      tableName,
      {'registros': jsonEncode(registros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return nuevoEstado;
  }

  Future<Map<String, dynamic>?> getUltimoEstadoByOperacionId(
    int operacionId, {
    String tableName = 'Operacion_tal_largo',
  }) async {
    final db = await database;

    final result = await db.query(
      tableName,
      columns: ['registros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) return null;

    String registrosJson = result.first['registros'] as String? ?? '[]';

    try {
      List<dynamic> registros = jsonDecode(registrosJson);

      if (registros.isEmpty) return null;

      // ✅ SIMPLE: el último insertado es el último real
      return Map<String, dynamic>.from(registros.last);
    } catch (e) {
      print('Error obteniendo último estado: $e');
      return null;
    }
  }

  //TALADRO HORIZONTAL--------------------------------------------------------------------------------------------------------------
  Future<int> insertOperacionTalHorizontal(
    String fecha,
    String turno,
    String seccion,
    String operador,
    String jefeGuardia,
    String equipo,
    String nEquipo,
    String modeloEquipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? horometrosBase,
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
  }) async {
    final db = await database;

    // 🔥 estructura base segura
    Map<String, dynamic> horometrosJson = {
      'diesel': {'inicio': 0, 'final': 0, 'op': true},
      'electrico': {'inicio': 0, 'final': 0, 'op': true},
      'percusion': {'inicio': 0, 'final': 0, 'op': true},
    };

    // 🔥 aplicar valores de nube si existen
    if (horometrosBase != null && horometrosBase.isNotEmpty) {
      for (var item in horometrosBase) {
        final tipo = item['tipo_horometro'];
        final finalValor = (item['final'] ?? 0).toDouble();

        if (horometrosJson.containsKey(tipo)) {
          horometrosJson[tipo]['inicio'] = finalValor;
        }
      }
    }

    // 🔹 resto igual
    Map<String, dynamic> condicionesEquipoJson = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '',
    };

    final controlLlantasJson = _defaultControlLlantas();

    String checkListStr = jsonEncode(checkListJson ?? []);

    final insertData = <String, dynamic>{
      'fecha': fecha,
      'turno': turno,
      'operador': operador,
      'jefe_guardia': jefeGuardia,
      'equipo': equipo,
      'horometros': jsonEncode(horometrosJson),
      'condiciones_equipo': jsonEncode(condicionesEquipoJson),
      'check_list': checkListStr,
      'control_llantas': jsonEncode(controlLlantasJson),
    };
    if (operadorId != null) insertData['operador_id'] = operadorId;
    if (equipoId != null) insertData['equipo_id'] = equipoId;
    if (jefeGuardiaId != null) insertData['jefe_guardia_id'] = jefeGuardiaId;
    _appendHybridOperationMetadata(
      insertData,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_tal_horizontal', insertData);
  }

  Future<List<Map<String, dynamic>>>
  getOperacionTalHorizontalByTurnoAndFechaMaster(
    int turnoId,
    String fecha,
  ) async {
    return _queryAndHydrateOperations(
      'Operacion_tal_horizontal',
      turnoId,
      fecha,
      onlyActive: true,
    );
  }

  Future<List<Map<String, dynamic>>> getOperacionTalHorizontalByTurnoAndFecha(
    int turnoId,
    String fecha, {
    int? operadorId,
  }) async {
    return _queryAndHydrateOperations(
      'Operacion_tal_horizontal',
      turnoId,
      fecha,
      operadorId: operadorId,
    );
  }

  // Función para obtener todos los estados de una operación
  Future<List<Map<String, dynamic>>> getEstadosByOperacionIdHorizontal(
    int operacionId,
  ) async {
    return getEstadosByOperacionId(
      operacionId,
      tableName: 'Operacion_tal_horizontal',
    );
  }

  Future<int> eliminarOperacionTalHorizontalFisico(int id) async {
    final db = await database;

    final result = await db.delete(
      'Operacion_tal_horizontal',
      where: 'id = ?',
      whereArgs: [id],
    );

    return result; // devuelve el número de filas eliminadas
  }

  Future<bool> updateHoraFinalHorizontal(
    int operacionId,
    int estadoId,
    String horaFinal,
  ) async {
    return updateHoraFinal(
      operacionId,
      estadoId,
      horaFinal,
      tableName: 'Operacion_tal_horizontal',
    );
  }

  Future<Map<String, dynamic>?> createEstadoHorizontal(
    int operacionId,
    String estado,
    String codigo,
    String horaInicio, {
    String? horaFinal,
    Map<String, dynamic>?
    operacion, // Ahora acepta todos los campos de perforación
  }) async {
    return createEstado(
      operacionId,
      estado,
      codigo,
      horaInicio,
      horaFinal: horaFinal,
      operacion: operacion,
      tableName: 'Operacion_tal_horizontal',
    );
  }

  Future<bool> updateEstadoHorizontal(
    int operacionId,
    int estadoId, {
    int? numero,
    String? estado,
    String? codigo,
    String? horaInicio,
    String? horaFinal,
    Map<String, String>? operacion,
  }) async {
    return updateEstado(
      operacionId,
      estadoId,
      numero: numero,
      estado: estado,
      codigo: codigo,
      horaInicio: horaInicio,
      horaFinal: horaFinal,
      operacion: operacion?.map((k, v) => MapEntry(k, v.toString())),
      tableName: 'Operacion_tal_horizontal',
    );
  }

  Future<Map<String, dynamic>> getOperacionByEstadoIdHorizontal(
    int operacionId,
    int estadoId,
  ) async {
    return getOperacionByEstadoId(
      operacionId,
      estadoId,
      tableName: 'Operacion_tal_horizontal',
    );
  }

  Future<bool> updateOperacionByEstadoIdHorizontal(
    int operacionId,
    int estadoId,
    Map<String, dynamic> operacionData,
  ) async {
    return updateOperacionByEstadoId(
      operacionId,
      estadoId,
      operacionData,
      tableName: 'Operacion_tal_horizontal',
    );
  }

  Future<List<Map<String, dynamic>>> getCheckListByOperacionIdHorizontal(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_tal_horizontal',
      columns: ['check_list'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      // Si no hay datos, devolver lista vacía
      return [];
    }

    String checkListJson = result.first['check_list'] as String? ?? '[]';

    try {
      List<dynamic> lista = jsonDecode(checkListJson);
      // Asegurarse de que cada item sea Map<String, dynamic>
      return lista.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error decodificando checklist: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getHorometrosByOperacionIdHorizontal(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_tal_horizontal',
      columns: ['horometros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      // Si no hay datos, devolver estructura por defecto
      return {
        'diesel': {'inicio': 0, 'final': 0, 'op': true},
        'electrico': {'inicio': 0, 'final': 0, 'op': true},
        'percusion': {'inicio': 0, 'final': 0, 'op': true},
      };
    }

    String horometrosJson = result.first['horometros'] as String? ?? '{}';

    try {
      Map<String, dynamic> horometros = jsonDecode(horometrosJson);
      return horometros;
    } catch (e) {
      print('Error decodificando horómetros: $e');
      // Si hay error, devolver estructura por defecto
      return {
        'diesel': {'inicio': 0, 'final': 0, 'op': true},
        'electrico': {'inicio': 0, 'final': 0, 'op': true},
        'percusion': {'inicio': 0, 'final': 0, 'op': true},
      };
    }
  }

  Future<Map<String, dynamic>?> getUltimoEstadoByOperacionIdHorizontal(
    int operacionId,
  ) async {
    return getUltimoEstadoByOperacionId(
      operacionId,
      tableName: 'Operacion_tal_horizontal',
    );
  }

  Future<Map<String, dynamic>?> createReservaEstadoHorizontal(
    int operacionId,
    int numero,
    String horaInicio,
    String horaFinal,
  ) async {
    return createReservaEstado(
      operacionId,
      numero,
      horaInicio,
      horaFinal,
      tableName: 'Operacion_tal_horizontal',
    );
  }

  Future<void> cerrarOperacionHorizontal(int operacionId) async {
    return cerrarOperacion(operacionId, tableName: 'Operacion_tal_horizontal');
  }

  Future<Map<String, dynamic>> getCondicionesEquipoByOperacionIdHorizontal(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_tal_horizontal',
      columns: ['condiciones_equipo'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    Map<String, dynamic> defaultData = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '', // ✅ nuevo campo
    };

    if (result.isEmpty) {
      return defaultData;
    }

    String condicionesJson =
        result.first['condiciones_equipo'] as String? ?? '{}';

    try {
      Map<String, dynamic> condiciones = jsonDecode(condicionesJson);

      // 🔥 asegurar que el nuevo campo exista
      condiciones.putIfAbsent('horaLlenado', () => '');

      return condiciones;
    } catch (e) {
      print('Error decodificando condiciones de equipo: $e');
      return defaultData;
    }
  }

  Future<Map<String, dynamic>> getControlLlantasByOperacionIdHorizontal(
    int operacionId,
  ) async {
    return _getControlLlantasFromTable('Operacion_tal_horizontal', operacionId);
  }

  Future<bool> deleteEstadoHorizontal(int operacionId, int estadoId) async {
    return deleteEstado(
      operacionId,
      estadoId,
      tableName: 'Operacion_tal_horizontal',
    );
  }

  Future<bool> updateControlLlantasHorizontal(
    int operacionId,
    Map<String, dynamic> controlLlantas,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_tal_horizontal',
      {'control_llantas': jsonEncode(controlLlantas)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCheckListHorizontal(
    int operacionId,
    List<Map<String, dynamic>> checkList,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_tal_horizontal',
      {'check_list': jsonEncode(checkList)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCondicionesEquipoHorizontal(
    int operacionId,
    Map<String, dynamic> condiciones,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_tal_horizontal',
      {'condiciones_equipo': jsonEncode(condiciones)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateHorometrosHorizontal(
    int operacionId,
    Map<String, dynamic> horometros,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_tal_horizontal',
      {'horometros': jsonEncode(horometros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  //SOSTENIMIENTO INICIO---------------------------------------------------------------------------------------------------------------------------------------------
  Future<int> insertOperacionEmpernador(
    String fecha,
    String turno,
    String seccion,
    String operador,
    String jefeGuardia,
    String equipo,
    String nEquipo,
    String tipoEquipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? horometrosBase,
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
  }) async {
    final db = await database;

    // 🔥 estructura base (incluye "empernador")
    Map<String, dynamic> horometrosJson = {
      'diesel': {'inicio': 0, 'final': 0, 'op': true},
      'electrico': {'inicio': 0, 'final': 0, 'op': true},
      'percusion': {'inicio': 0, 'final': 0, 'op': true},
      'empernador': {'inicio': 0, 'final': 0, 'op': true},
    };

    // 🔥 aplicar valores de nube
    if (horometrosBase != null && horometrosBase.isNotEmpty) {
      for (var item in horometrosBase) {
        final tipo = item['tipo_horometro'];
        final finalValor = (item['final'] ?? 0).toDouble();

        // 🔥 importante: validar que exista en el JSON base
        if (horometrosJson.containsKey(tipo)) {
          horometrosJson[tipo]['inicio'] = finalValor;
        }
      }
    }

    // 🔹 resto igual
    Map<String, dynamic> condicionesEquipoJson = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '',
    };

    final controlLlantasJson = _defaultControlLlantas();

    String checkListStr = jsonEncode(checkListJson ?? []);

    final insertData = <String, dynamic>{
      'fecha': fecha,
      'turno': turno,
      'operador': operador,
      'jefe_guardia': jefeGuardia,
      'equipo': equipo,
      'horometros': jsonEncode(horometrosJson),
      'condiciones_equipo': jsonEncode(condicionesEquipoJson),
      'check_list': checkListStr,
      'control_llantas': jsonEncode(controlLlantasJson),
    };
    if (operadorId != null) insertData['operador_id'] = operadorId;
    if (equipoId != null) insertData['equipo_id'] = equipoId;
    if (jefeGuardiaId != null) insertData['jefe_guardia_id'] = jefeGuardiaId;
    _appendHybridOperationMetadata(
      insertData,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_empernador', insertData);
  }

  Future<List<Map<String, dynamic>>>
  getOperacionEmpernadorByTurnoAndFechaMaster(int turnoId, String fecha) async {
    return _queryAndHydrateOperations(
      'Operacion_empernador',
      turnoId,
      fecha,
      onlyActive: true,
    );
  }

  Future<List<Map<String, dynamic>>> getOperacionEmpernadorByTurnoAndFecha(
    int turnoId,
    String fecha, {
    int? operadorId,
  }) async {
    return _queryAndHydrateOperations(
      'Operacion_empernador',
      turnoId,
      fecha,
      operadorId: operadorId,
    );
  }

  // Función para obtener todos los estados de una operación
  Future<List<Map<String, dynamic>>> getEstadosByOperacionIdEmpernador(
    int operacionId,
  ) async {
    return getEstadosByOperacionId(
      operacionId,
      tableName: 'Operacion_empernador',
    );
  }

  Future<int> eliminarOperacionTalEmpernadorFisico(int id) async {
    final db = await database;

    final result = await db.delete(
      'Operacion_empernador',
      where: 'id = ?',
      whereArgs: [id],
    );

    return result; // devuelve el número de filas eliminadas
  }

  Future<bool> updateHoraFinalEmpernador(
    int operacionId,
    int estadoId,
    String horaFinal,
  ) async {
    return updateHoraFinal(
      operacionId,
      estadoId,
      horaFinal,
      tableName: 'Operacion_empernador',
    );
  }

  Future<Map<String, dynamic>?> createEstadoEmpernador(
    int operacionId,
    String estado,
    String codigo,
    String horaInicio, {
    String? horaFinal,
    Map<String, dynamic>?
    operacion, // Ahora acepta todos los campos de perforación
  }) async {
    return createEstado(
      operacionId,
      estado,
      codigo,
      horaInicio,
      horaFinal: horaFinal,
      operacion: operacion,
      tableName: 'Operacion_empernador',
    );
  }

  Future<bool> updateEstadoEmpernador(
    int operacionId,
    int estadoId, {
    int? numero,
    String? estado,
    String? codigo,
    String? horaInicio,
    String? horaFinal,
    Map<String, String>? operacion,
  }) async {
    return updateEstado(
      operacionId,
      estadoId,
      numero: numero,
      estado: estado,
      codigo: codigo,
      horaInicio: horaInicio,
      horaFinal: horaFinal,
      operacion: operacion?.map((k, v) => MapEntry(k, v.toString())),
      tableName: 'Operacion_empernador',
    );
  }

  Future<Map<String, dynamic>> getOperacionByEstadoIdEmpernador(
    int operacionId,
    int estadoId,
  ) async {
    return getOperacionByEstadoId(
      operacionId,
      estadoId,
      tableName: 'Operacion_empernador',
    );
  }

  Future<bool> updateOperacionByEstadoIdEmpernador(
    int operacionId,
    int estadoId,
    Map<String, dynamic> operacionData,
  ) async {
    return updateOperacionByEstadoId(
      operacionId,
      estadoId,
      operacionData,
      tableName: 'Operacion_empernador',
    );
  }

  Future<List<Map<String, dynamic>>> getCheckListByOperacionIdEmpernador(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_empernador',
      columns: ['check_list'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      // Si no hay datos, devolver lista vacía
      return [];
    }

    String checkListJson = result.first['check_list'] as String? ?? '[]';

    try {
      List<dynamic> lista = jsonDecode(checkListJson);
      // Asegurarse de que cada item sea Map<String, dynamic>
      return lista.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error decodificando checklist: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getHorometrosByOperacionIdEmpernador(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_empernador',
      columns: ['horometros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      // Si no hay datos, devolver estructura por defecto
      return {
        'diesel': {'inicio': 0, 'final': 0, 'op': true},
        'electrico': {'inicio': 0, 'final': 0, 'op': true},
        'percusion': {'inicio': 0, 'final': 0, 'op': true},
        'empernador': {'inicio': 0, 'final': 0, 'op': true},
      };
    }

    String horometrosJson = result.first['horometros'] as String? ?? '{}';

    try {
      Map<String, dynamic> horometros = jsonDecode(horometrosJson);
      return horometros;
    } catch (e) {
      print('Error decodificando horómetros: $e');
      // Si hay error, devolver estructura por defecto
      return {
        'diesel': {'inicio': 0, 'final': 0, 'op': true},
        'electrico': {'inicio': 0, 'final': 0, 'op': true},
        'percusion': {'inicio': 0, 'final': 0, 'op': true},
        'empernador': {'inicio': 0, 'final': 0, 'op': true},
      };
    }
  }

  Future<Map<String, dynamic>?> getUltimoEstadoByOperacionIdEmpernador(
    int operacionId,
  ) async {
    return getUltimoEstadoByOperacionId(
      operacionId,
      tableName: 'Operacion_empernador',
    );
  }

  Future<Map<String, dynamic>?> createReservaEstadoEmpernador(
    int operacionId,
    int numero,
    String horaInicio,
    String horaFinal,
  ) async {
    return createReservaEstado(
      operacionId,
      numero,
      horaInicio,
      horaFinal,
      tableName: 'Operacion_empernador',
    );
  }

  Future<void> cerrarOperacionEmpernador(int operacionId) async {
    return cerrarOperacion(operacionId, tableName: 'Operacion_empernador');
  }

  Future<Map<String, dynamic>> getCondicionesEquipoByOperacionIdEmpernador(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_empernador',
      columns: ['condiciones_equipo'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    Map<String, dynamic> defaultData = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '', // ✅ nuevo campo
    };

    if (result.isEmpty) {
      return defaultData;
    }

    String condicionesJson =
        result.first['condiciones_equipo'] as String? ?? '{}';

    try {
      Map<String, dynamic> condiciones = jsonDecode(condicionesJson);

      // 🔥 asegurar que el nuevo campo exista
      condiciones.putIfAbsent('horaLlenado', () => '');

      return condiciones;
    } catch (e) {
      print('Error decodificando condiciones de equipo: $e');
      return defaultData;
    }
  }

  Future<Map<String, dynamic>> getControlLlantasByOperacionIdEmpernador(
    int operacionId,
  ) async {
    return _getControlLlantasFromTable('Operacion_empernador', operacionId);
  }

  Future<bool> deleteEstadoEmpernador(int operacionId, int estadoId) async {
    return deleteEstado(
      operacionId,
      estadoId,
      tableName: 'Operacion_empernador',
    );
  }

  Future<bool> updateControlLlantasEmpernador(
    int operacionId,
    Map<String, dynamic> controlLlantas,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_empernador',
      {'control_llantas': jsonEncode(controlLlantas)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCheckListEmpernador(
    int operacionId,
    List<Map<String, dynamic>> checkList,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_empernador',
      {'check_list': jsonEncode(checkList)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCondicionesEquipoEmpernador(
    int operacionId,
    Map<String, dynamic> condiciones,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_empernador',
      {'condiciones_equipo': jsonEncode(condiciones)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateHorometrosEmpernador(
    int operacionId,
    Map<String, dynamic> horometros,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_empernador',
      {'horometros': jsonEncode(horometros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  //CARGUIO INICIO SCOOPS---------------------------------------------------------------------------------------------------------------------------------------------
  Future<int> insertOperacionCarguio(
    String fecha,
    String turno,
    String seccion,
    String operador,
    String jefeGuardia,
    String equipo,
    String nEquipo,
    String capacidad,
    String tipoEquipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? checkListTelemandoJson,
    List<Map<String, dynamic>>? horometrosBase,
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
  }) async {
    final db = await database;

    /// 🔥 estructura base (solo uno)
    Map<String, dynamic> horometrosJson = {
      'horometro': {'inicio': 0, 'final': 0, 'op': true},
    };

    /// 🔥 aplicar valor de nube (solo uno)
    if (horometrosBase != null && horometrosBase.isNotEmpty) {
      final item = horometrosBase.first;
      final finalValor = (item['final'] ?? 0).toDouble();

      horometrosJson['horometro']['inicio'] = finalValor;
    }

    /// Condiciones equipo
    Map<String, dynamic> condicionesEquipoJson = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '',
    };

    /// Control llantas
    final controlLlantasJson = _defaultControlLlantas();

    /// Programa de trabajo
    Map<String, dynamic> programaTrabajoJson = {
      'n_cucharas_programado': 0,
      'n_cucharas_realizado': 0,
    };

    /// Checklist
    String checkListStr = jsonEncode(checkListJson ?? []);

    /// Checklist telemando
    String checkListTelemandoStr = jsonEncode(checkListTelemandoJson ?? []);

    final insertData = <String, dynamic>{
      'fecha': fecha,
      'turno': turno,
      'operador': operador,
      'jefe_guardia': jefeGuardia,
      'equipo': equipo,
      'horometros': jsonEncode(horometrosJson),
      'condiciones_equipo': jsonEncode(condicionesEquipoJson),
      'programa_trabajo': jsonEncode(programaTrabajoJson),
      'check_list': checkListStr,
      'check_list_telemando': checkListTelemandoStr,
      'control_llantas': jsonEncode(controlLlantasJson),
    };
    if (operadorId != null) insertData['operador_id'] = operadorId;
    if (equipoId != null) insertData['equipo_id'] = equipoId;
    if (jefeGuardiaId != null) insertData['jefe_guardia_id'] = jefeGuardiaId;
    _appendHybridOperationMetadata(
      insertData,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_carguio', insertData);
  }

  Future<List<Map<String, dynamic>>> getOperacionCarguioByTurnoAndFechaMaster(
    int turnoId,
    String fecha,
  ) async {
    return _queryAndHydrateOperations(
      'Operacion_carguio',
      turnoId,
      fecha,
      onlyActive: true,
    );
  }

  Future<List<Map<String, dynamic>>> getOperacionCarguioByTurnoAndFecha(
    int turnoId,
    String fecha, {
    int? operadorId,
  }) async {
    return _queryAndHydrateOperations(
      'Operacion_carguio',
      turnoId,
      fecha,
      operadorId: operadorId,
    );
  }

  // Función para obtener todos los estados de una operación
  Future<List<Map<String, dynamic>>> getEstadosByOperacionIdCarguio(
    int operacionId,
  ) async {
    return getEstadosByOperacionId(operacionId, tableName: 'Operacion_carguio');
  }

  Future<int> eliminarOperacionTalCarguioFisico(int id) async {
    final db = await database;

    final result = await db.delete(
      'Operacion_carguio',
      where: 'id = ?',
      whereArgs: [id],
    );

    return result; // devuelve el número de filas eliminadas
  }

  Future<bool> updateHoraFinalCarguio(
    int operacionId,
    int estadoId,
    String horaFinal,
  ) async {
    return updateHoraFinal(
      operacionId,
      estadoId,
      horaFinal,
      tableName: 'Operacion_carguio',
    );
  }

  Future<Map<String, dynamic>?> createEstadoCarguio(
    int operacionId,
    String estado,
    String codigo,
    String horaInicio, {
    String? horaFinal,
    Map<String, dynamic>? operacion,
  }) async {
    return createEstado(
      operacionId,
      estado,
      codigo,
      horaInicio,
      horaFinal: horaFinal,
      operacion: operacion,
      tableName: 'Operacion_carguio',
    );
  }

  Future<bool> updateEstadoCarguio(
    int operacionId,
    int estadoId, {
    int? numero,
    String? estado,
    String? codigo,
    String? horaInicio,
    String? horaFinal,
    Map<String, String>? operacion,
  }) async {
    return updateEstado(
      operacionId,
      estadoId,
      numero: numero,
      estado: estado,
      codigo: codigo,
      horaInicio: horaInicio,
      horaFinal: horaFinal,
      operacion: operacion?.map((k, v) => MapEntry(k, v.toString())),
      tableName: 'Operacion_carguio',
    );
  }

  Future<Map<String, dynamic>> getOperacionByEstadoIdCarguio(
    int operacionId,
    int estadoId,
  ) async {
    return getOperacionByEstadoId(
      operacionId,
      estadoId,
      tableName: 'Operacion_carguio',
    );
  }

  Future<bool> updateOperacionByEstadoIdCarguio(
    int operacionId,
    int estadoId,
    Map<String, dynamic> operacionData,
  ) async {
    return updateOperacionByEstadoId(
      operacionId,
      estadoId,
      operacionData,
      tableName: 'Operacion_carguio',
    );
  }

  Future<List<Map<String, dynamic>>> getCheckListByOperacionIdCarguio(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_carguio',
      columns: ['check_list'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      // Si no hay datos, devolver lista vacía
      return [];
    }

    String checkListJson = result.first['check_list'] as String? ?? '[]';

    try {
      List<dynamic> lista = jsonDecode(checkListJson);
      // Asegurarse de que cada item sea Map<String, dynamic>
      return lista.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error decodificando checklist: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getHorometrosByOperacionIdCarguio(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_carguio',
      columns: ['horometros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      return {
        'horometro': {'inicio': 0, 'final': 0, 'op': true},
      };
    }

    String horometrosJson = result.first['horometros'] as String? ?? '{}';

    try {
      Map<String, dynamic> horometros = jsonDecode(horometrosJson);

      // Si el JSON está vacío
      if (horometros.isEmpty) {
        return {
          'horometro': {'inicio': 0, 'final': 0, 'op': true},
        };
      }

      return horometros;
    } catch (e) {
      print('Error decodificando horómetros: $e');

      return {
        'horometro': {'inicio': 0, 'final': 0, 'op': true},
      };
    }
  }

  Future<Map<String, dynamic>?> getUltimoEstadoByOperacionIdCarguio(
    int operacionId,
  ) async {
    return getUltimoEstadoByOperacionId(
      operacionId,
      tableName: 'Operacion_carguio',
    );
  }

  Future<Map<String, dynamic>?> createReservaEstadoCarguio(
    int operacionId,
    int numero,
    String horaInicio,
    String horaFinal,
  ) async {
    return createReservaEstado(
      operacionId,
      numero,
      horaInicio,
      horaFinal,
      tableName: 'Operacion_carguio',
    );
  }

  Future<void> cerrarOperacionCarguio(int operacionId) async {
    return cerrarOperacion(operacionId, tableName: 'Operacion_carguio');
  }

  Future<Map<String, dynamic>> getCondicionesEquipoByOperacionIdCarguio(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_carguio',
      columns: ['condiciones_equipo'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    Map<String, dynamic> defaultData = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '', // ✅ nuevo campo
    };

    if (result.isEmpty) {
      return defaultData;
    }

    String condicionesJson =
        result.first['condiciones_equipo'] as String? ?? '{}';

    try {
      Map<String, dynamic> condiciones = jsonDecode(condicionesJson);

      // 🔥 asegurar que el nuevo campo exista
      condiciones.putIfAbsent('horaLlenado', () => '');

      return condiciones;
    } catch (e) {
      print('Error decodificando condiciones de equipo: $e');
      return defaultData;
    }
  }

  Future<Map<String, dynamic>> getControlLlantasByOperacionIdCarguio(
    int operacionId,
  ) async {
    return _getControlLlantasFromTable('Operacion_carguio', operacionId);
  }

  Future<bool> deleteEstadoCarguio(int operacionId, int estadoId) async {
    return deleteEstado(operacionId, estadoId, tableName: 'Operacion_carguio');
  }

  Future<bool> updateControlLlantasCarguio(
    int operacionId,
    Map<String, dynamic> controlLlantas,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_carguio',
      {'control_llantas': jsonEncode(controlLlantas)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCheckListCarguio(
    int operacionId,
    List<Map<String, dynamic>> checkList,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_carguio',
      {'check_list': jsonEncode(checkList)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCondicionesEquipoCarguio(
    int operacionId,
    Map<String, dynamic> condiciones,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_carguio',
      {'condiciones_equipo': jsonEncode(condiciones)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateHorometrosCarguio(
    int operacionId,
    Map<String, dynamic> horometros,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_carguio',
      {'horometros': jsonEncode(horometros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCheckListTelemando(
    int operacionId,
    List<Map<String, dynamic>> checkListTelemando,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_carguio',
      {'check_list_telemando': jsonEncode(checkListTelemando)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<List<Map<String, dynamic>>> getCheckListTelemandoByOperacionIdCarguio(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_carguio',
      columns: ['check_list_telemando'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      return [];
    }

    String checkListJson =
        result.first['check_list_telemando'] as String? ?? '[]';

    try {
      List<dynamic> lista = jsonDecode(checkListJson);

      return lista.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error decodificando checklist telemando: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getProgramaTrabajoByOperacionIdCarguio(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_carguio',
      columns: ['programa_trabajo'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      return {'n_cucharas_programado': 0, 'n_cucharas_realizado': 0};
    }

    String programaTrabajoJson =
        result.first['programa_trabajo'] as String? ?? '{}';

    try {
      Map<String, dynamic> programaTrabajo = jsonDecode(programaTrabajoJson);

      if (programaTrabajo.isEmpty) {
        return {'n_cucharas_programado': 0, 'n_cucharas_realizado': 0};
      }

      return programaTrabajo;
    } catch (e) {
      print('Error decodificando programa_trabajo: $e');

      return {'n_cucharas_programado': 0, 'n_cucharas_realizado': 0};
    }
  }

  Future<bool> updateProgramaTrabajoCarguio(
    int operacionId,
    Map<String, dynamic> programaTrabajo,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_carguio',
      {'programa_trabajo': jsonEncode(programaTrabajo)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  //CARGUIO DUMPER INICIO---------------------------------------------------------------------------------------------------------------------------------------------
  Future<int> insertOperacionDumper(
    String fecha,
    String turno,
    String seccion,
    String operador,
    String jefeGuardia,
    String equipo,
    String nEquipo,
    String capacidad,
    String tipoEquipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? checkListTelemandoJson,
    List<Map<String, dynamic>>? horometrosBase,
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
  }) async {
    final db = await database;

    /// 🔥 estructura base
    Map<String, dynamic> horometrosJson = {
      'horometro': {'inicio': 0, 'final': 0, 'op': true},
    };

    /// 🔥 aplicar valor de nube
    if (horometrosBase != null && horometrosBase.isNotEmpty) {
      final item = horometrosBase.first;
      final finalValor = (item['final'] ?? 0).toDouble();

      horometrosJson['horometro']['inicio'] = finalValor;
    }

    /// Condiciones equipo
    Map<String, dynamic> condicionesEquipoJson = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '',
    };

    /// Control llantas
    final controlLlantasJson = _defaultControlLlantas();

    /// Programa de trabajo
    Map<String, dynamic> programaTrabajoJson = {
      'n_viaje_mineral': 0.0,
      'n_viaje_desmonte': 0.0,
      'programado': 0.0,
      'realizado': 0.0,
      'total': 0.0,
    };

    /// Checklist
    String checkListStr = jsonEncode(checkListJson ?? []);

    /// Checklist telemando
    String checkListTelemandoStr = jsonEncode(checkListTelemandoJson ?? []);

    final insertData = <String, dynamic>{
      'fecha': fecha,
      'turno': turno,
      'operador': operador,
      'jefe_guardia': jefeGuardia,
      'equipo': equipo,
      'horometros': jsonEncode(horometrosJson),
      'condiciones_equipo': jsonEncode(condicionesEquipoJson),
      'programa_trabajo': jsonEncode(programaTrabajoJson),
      'check_list': checkListStr,
      'check_list_telemando': checkListTelemandoStr,
      'control_llantas': jsonEncode(controlLlantasJson),
    };
    if (operadorId != null) insertData['operador_id'] = operadorId;
    if (equipoId != null) insertData['equipo_id'] = equipoId;
    if (jefeGuardiaId != null) insertData['jefe_guardia_id'] = jefeGuardiaId;
    _appendHybridOperationMetadata(
      insertData,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_Dumper', insertData);
  }

  Future<List<Map<String, dynamic>>> getOperacionDumperByTurnoAndFechaMaster(
    int turnoId,
    String fecha,
  ) async {
    return _queryAndHydrateOperations(
      'Operacion_Dumper',
      turnoId,
      fecha,
      onlyActive: true,
    );
  }

  Future<List<Map<String, dynamic>>> getOperacionDumperByTurnoAndFecha(
    int turnoId,
    String fecha, {
    int? operadorId,
  }) async {
    return _queryAndHydrateOperations(
      'Operacion_Dumper',
      turnoId,
      fecha,
      operadorId: operadorId,
    );
  }

  // Función para obtener todos los estados de una operación
  Future<List<Map<String, dynamic>>> getEstadosByOperacionIdDumper(
    int operacionId,
  ) async {
    return getEstadosByOperacionId(operacionId, tableName: 'Operacion_dumper');
  }

  Future<int> eliminarOperacionTalDumperFisico(int id) async {
    final db = await database;

    final result = await db.delete(
      'Operacion_Dumper',
      where: 'id = ?',
      whereArgs: [id],
    );

    return result; // devuelve el número de filas eliminadas
  }

  Future<bool> updateHoraFinalDumper(
    int operacionId,
    int estadoId,
    String horaFinal,
  ) async {
    return updateHoraFinal(
      operacionId,
      estadoId,
      horaFinal,
      tableName: 'Operacion_dumper',
    );
  }

  Future<Map<String, dynamic>?> createEstadoDumper(
    int operacionId,
    String estado,
    String codigo,
    String horaInicio, {
    String? horaFinal,
    Map<String, dynamic>? operacion,
  }) async {
    return createEstado(
      operacionId,
      estado,
      codigo,
      horaInicio,
      horaFinal: horaFinal,
      operacion: operacion,
      tableName: 'Operacion_dumper',
    );
  }

  Future<bool> updateEstadoDumper(
    int operacionId,
    int estadoId, {
    int? numero,
    String? estado,
    String? codigo,
    String? horaInicio,
    String? horaFinal,
    Map<String, String>? operacion,
  }) async {
    return updateEstado(
      operacionId,
      estadoId,
      numero: numero,
      estado: estado,
      codigo: codigo,
      horaInicio: horaInicio,
      horaFinal: horaFinal,
      operacion: operacion?.map((k, v) => MapEntry(k, v.toString())),
      tableName: 'Operacion_dumper',
    );
  }

  Future<Map<String, dynamic>> getOperacionByEstadoIdDumper(
    int operacionId,
    int estadoId,
  ) async {
    return getOperacionByEstadoId(
      operacionId,
      estadoId,
      tableName: 'Operacion_dumper',
    );
  }

  Future<bool> updateOperacionByEstadoIdDumper(
    int operacionId,
    int estadoId,
    Map<String, dynamic> operacionData,
  ) async {
    return updateOperacionByEstadoId(
      operacionId,
      estadoId,
      operacionData,
      tableName: 'Operacion_dumper',
    );
  }

  Future<List<Map<String, dynamic>>> getCheckListByOperacionIdDumper(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_Dumper',
      columns: ['check_list'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      // Si no hay datos, devolver lista vacía
      return [];
    }

    String checkListJson = result.first['check_list'] as String? ?? '[]';

    try {
      List<dynamic> lista = jsonDecode(checkListJson);
      // Asegurarse de que cada item sea Map<String, dynamic>
      return lista.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error decodificando checklist: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getHorometrosByOperacionIdDumper(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_Dumper',
      columns: ['horometros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      return {
        'horometro': {'inicio': 0, 'final': 0, 'op': true},
      };
    }

    String horometrosJson = result.first['horometros'] as String? ?? '{}';

    try {
      Map<String, dynamic> horometros = jsonDecode(horometrosJson);

      // Si el JSON está vacío
      if (horometros.isEmpty) {
        return {
          'horometro': {'inicio': 0, 'final': 0, 'op': true},
        };
      }

      return horometros;
    } catch (e) {
      print('Error decodificando horómetros: $e');

      return {
        'horometro': {'inicio': 0, 'final': 0, 'op': true},
      };
    }
  }

  Future<Map<String, dynamic>?> getUltimoEstadoByOperacionIdDumper(
    int operacionId,
  ) async {
    return getUltimoEstadoByOperacionId(
      operacionId,
      tableName: 'Operacion_dumper',
    );
  }

  Future<Map<String, dynamic>?> createReservaEstadoDumper(
    int operacionId,
    int numero,
    String horaInicio,
    String horaFinal,
  ) async {
    return createReservaEstado(
      operacionId,
      numero,
      horaInicio,
      horaFinal,
      tableName: 'Operacion_dumper',
    );
  }

  Future<void> cerrarOperacionDumper(int operacionId) async {
    return cerrarOperacion(operacionId, tableName: 'Operacion_dumper');
  }

  Future<Map<String, dynamic>> getCondicionesEquipoByOperacionIdDumper(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_Dumper',
      columns: ['condiciones_equipo'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    Map<String, dynamic> defaultData = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '', // ✅ nuevo campo
    };

    if (result.isEmpty) {
      return defaultData;
    }

    String condicionesJson =
        result.first['condiciones_equipo'] as String? ?? '{}';

    try {
      Map<String, dynamic> condiciones = jsonDecode(condicionesJson);

      // 🔥 asegurar que el nuevo campo exista
      condiciones.putIfAbsent('horaLlenado', () => '');

      return condiciones;
    } catch (e) {
      print('Error decodificando condiciones de equipo: $e');
      return defaultData;
    }
  }

  Future<Map<String, dynamic>> getControlLlantasByOperacionIdDumper(
    int operacionId,
  ) async {
    return _getControlLlantasFromTable('Operacion_Dumper', operacionId);
  }

  Future<bool> deleteEstadoDumper(int operacionId, int estadoId) async {
    return deleteEstado(operacionId, estadoId, tableName: 'Operacion_dumper');
  }

  Future<bool> updateControlLlantasDumper(
    int operacionId,
    Map<String, dynamic> controlLlantas,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_Dumper',
      {'control_llantas': jsonEncode(controlLlantas)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCheckListDumper(
    int operacionId,
    List<Map<String, dynamic>> checkList,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_Dumper',
      {'check_list': jsonEncode(checkList)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCondicionesEquipoDumper(
    int operacionId,
    Map<String, dynamic> condiciones,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_Dumper',
      {'condiciones_equipo': jsonEncode(condiciones)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateHorometrosDumper(
    int operacionId,
    Map<String, dynamic> horometros,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_Dumper',
      {'horometros': jsonEncode(horometros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCheckListTelemandoDumper(
    int operacionId,
    List<Map<String, dynamic>> checkListTelemando,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_Dumper',
      {'check_list_telemando': jsonEncode(checkListTelemando)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<List<Map<String, dynamic>>> getCheckListTelemandoByOperacionIdDumper(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_Dumper',
      columns: ['check_list_telemando'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      return [];
    }

    String checkListJson =
        result.first['check_list_telemando'] as String? ?? '[]';

    try {
      List<dynamic> lista = jsonDecode(checkListJson);

      return lista.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error decodificando checklist telemando: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getProgramaTrabajoByOperacionIdDumper(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_Dumper',
      columns: ['programa_trabajo'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    // 🔥 estructura nueva base
    Map<String, dynamic> estructuraNueva() {
      return {
        'n_viaje_mineral': 0.0,
        'n_viaje_desmonte': 0.0,
        'programado': 0.0,
        'realizado': 0.0,
        'total': 0.0,
      };
    }

    if (result.isEmpty) {
      return estructuraNueva();
    }

    String programaTrabajoJson =
        result.first['programa_trabajo'] as String? ?? '{}';

    try {
      Map<String, dynamic> programaTrabajo = jsonDecode(programaTrabajoJson);

      if (programaTrabajo.isEmpty) {
        return estructuraNueva();
      }

      // ✅ SIEMPRE formato nuevo
      return {
        'n_viaje_mineral': (programaTrabajo['n_viaje_mineral'] ?? 0).toDouble(),
        'n_viaje_desmonte': (programaTrabajo['n_viaje_desmonte'] ?? 0)
            .toDouble(),
        'programado': (programaTrabajo['programado'] ?? 0).toDouble(),
        'realizado': (programaTrabajo['realizado'] ?? 0).toDouble(),
        'total': (programaTrabajo['total'] ?? 0).toDouble(),
      };
    } catch (e) {
      print('Error decodificando programa_trabajo: $e');
      return estructuraNueva();
    }
  }

  Future<bool> updateProgramaTrabajoDumper(
    int operacionId,
    Map<String, dynamic> programaTrabajo,
  ) async {
    final db = await database;

    // 🔥 Normalizar estructura
    Map<String, dynamic> data = {
      'n_viaje_mineral': (programaTrabajo['n_viaje_mineral'] ?? 0).toDouble(),
      'n_viaje_desmonte': (programaTrabajo['n_viaje_desmonte'] ?? 0).toDouble(),
      'programado': (programaTrabajo['programado'] ?? 0).toDouble(),
      'realizado': (programaTrabajo['realizado'] ?? 0).toDouble(),
      'total': (programaTrabajo['total'] ?? 0).toDouble(),
    };

    int updated = await db.update(
      'Operacion_Dumper',
      {'programa_trabajo': jsonEncode(data)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  //ROMPE BANCOS INICIO---------------------------------------------------------------------------------------------------------------------------------------------

  Future<int> insertOperacionRompeBaco(
    String fecha,
    String turno,
    String operador,
    String jefeGuardia,
    String equipo,
    String nEquipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? horometrosBase,
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
  }) async {
    final db = await database;

    /// 🔥 estructura base
    Map<String, dynamic> horometrosJson = {
      'diesel': {'inicio': 0, 'final': 0, 'op': true},
      'percusion': {'inicio': 0, 'final': 0, 'op': true},
    };

    /// 🔥 aplicar valores de nube
    if (horometrosBase != null && horometrosBase.isNotEmpty) {
      for (var item in horometrosBase) {
        final tipo = item['tipo_horometro'];
        final finalValor = (item['final'] ?? 0).toDouble();

        if (horometrosJson.containsKey(tipo)) {
          horometrosJson[tipo]['inicio'] = finalValor;
        }
      }
    }

    /// Condiciones equipo
    Map<String, dynamic> condicionesEquipoJson = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '',
    };

    /// Control llantas
    final controlLlantasJson = _defaultControlLlantas();

    /// Checklist
    String checkListStr = jsonEncode(checkListJson ?? []);

    final insertData = <String, dynamic>{
      'fecha': fecha,
      'turno': turno,
      'operador': operador,
      'jefe_guardia': jefeGuardia,
      'equipo': equipo,
      'horometros': jsonEncode(horometrosJson),
      'condiciones_equipo': jsonEncode(condicionesEquipoJson),
      'check_list': checkListStr,
      'control_llantas': jsonEncode(controlLlantasJson),
    };
    if (operadorId != null) insertData['operador_id'] = operadorId;
    if (equipoId != null) insertData['equipo_id'] = equipoId;
    if (jefeGuardiaId != null) insertData['jefe_guardia_id'] = jefeGuardiaId;
    _appendHybridOperationMetadata(
      insertData,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_rompebanco', insertData);
  }

  Future<List<Map<String, dynamic>>> getOperacionRompeBacoByTurnoAndFechaMaster(
    int turnoId,
    String fecha,
  ) async {
    return _queryAndHydrateOperations(
      'Operacion_rompebanco',
      turnoId,
      fecha,
      onlyActive: true,
    );
  }

  Future<List<Map<String, dynamic>>> getOperacionRompeBacoByTurnoAndFecha(
    int turnoId,
    String fecha, {
    int? operadorId,
  }) async {
    return _queryAndHydrateOperations(
      'Operacion_rompebanco',
      turnoId,
      fecha,
      operadorId: operadorId,
    );
  }

  // Función para obtener todos los estados de una operación
  Future<List<Map<String, dynamic>>> getEstadosByOperacionIdRompeBaco(
    int operacionId,
  ) async {
    return getEstadosByOperacionId(
      operacionId,
      tableName: 'Operacion_rompe_baco',
    );
  }

  Future<int> eliminarOperacionTalRompeBacoFisico(int id) async {
    final db = await database;

    final result = await db.delete(
      'Operacion_rompebanco',
      where: 'id = ?',
      whereArgs: [id],
    );

    return result; // devuelve el número de filas eliminadas
  }

  Future<bool> updateHoraFinalRompeBaco(
    int operacionId,
    int estadoId,
    String horaFinal,
  ) async {
    return updateHoraFinal(
      operacionId,
      estadoId,
      horaFinal,
      tableName: 'Operacion_rompe_baco',
    );
  }

  Future<Map<String, dynamic>?> createEstadoRompeBaco(
    int operacionId,
    String estado,
    String codigo,
    String horaInicio, {
    String? horaFinal,
    Map<String, dynamic>? operacion,
  }) async {
    return createEstado(
      operacionId,
      estado,
      codigo,
      horaInicio,
      horaFinal: horaFinal,
      operacion: operacion,
      tableName: 'Operacion_rompe_baco',
    );
  }

  Future<bool> updateEstadoRompeBaco(
    int operacionId,
    int estadoId, {
    int? numero,
    String? estado,
    String? codigo,
    String? horaInicio,
    String? horaFinal,
    Map<String, String>? operacion,
  }) async {
    return updateEstado(
      operacionId,
      estadoId,
      numero: numero,
      estado: estado,
      codigo: codigo,
      horaInicio: horaInicio,
      horaFinal: horaFinal,
      operacion: operacion?.map((k, v) => MapEntry(k, v.toString())),
      tableName: 'Operacion_rompe_baco',
    );
  }

  Future<Map<String, dynamic>> getOperacionByEstadoIdRompeBaco(
    int operacionId,
    int estadoId,
  ) async {
    return getOperacionByEstadoId(
      operacionId,
      estadoId,
      tableName: 'Operacion_rompe_baco',
    );
  }

  Future<bool> updateOperacionByEstadoIdRompeBaco(
    int operacionId,
    int estadoId,
    Map<String, dynamic> operacionData,
  ) async {
    return updateOperacionByEstadoId(
      operacionId,
      estadoId,
      operacionData,
      tableName: 'Operacion_rompe_baco',
    );
  }

  Future<List<Map<String, dynamic>>> getCheckListByOperacionIdRompeBaco(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_rompebanco',
      columns: ['check_list'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      // Si no hay datos, devolver lista vacía
      return [];
    }

    String checkListJson = result.first['check_list'] as String? ?? '[]';

    try {
      List<dynamic> lista = jsonDecode(checkListJson);
      // Asegurarse de que cada item sea Map<String, dynamic>
      return lista.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error decodificando checklist: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getHorometrosByOperacionIdRompeBaco(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_rompebanco',
      columns: ['horometros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      return {
        'diesel': {'inicio': 0, 'final': 0, 'op': true},
        'percusion': {'inicio': 0, 'final': 0, 'op': true},
      };
    }

    String horometrosJson = result.first['horometros'] as String? ?? '{}';

    try {
      Map<String, dynamic> horometros = jsonDecode(horometrosJson);

      if (horometros.isEmpty) {
        return {
          'diesel': {'inicio': 0, 'final': 0, 'op': true},
          'percusion': {'inicio': 0, 'final': 0, 'op': true},
        };
      }

      return Map<String, dynamic>.from(horometros);
    } catch (e) {
      print('Error decodificando horómetros: $e');

      return {
        'diesel': {'inicio': 0, 'final': 0, 'op': true},
        'percusion': {'inicio': 0, 'final': 0, 'op': true},
      };
    }
  }

  Future<Map<String, dynamic>?> getUltimoEstadoByOperacionIdRompeBaco(
    int operacionId,
  ) async {
    return getUltimoEstadoByOperacionId(
      operacionId,
      tableName: 'Operacion_rompe_baco',
    );
  }

  Future<Map<String, dynamic>?> createReservaEstadoRompeBaco(
    int operacionId,
    int numero,
    String horaInicio,
    String horaFinal,
  ) async {
    return createReservaEstado(
      operacionId,
      numero,
      horaInicio,
      horaFinal,
      tableName: 'Operacion_rompe_baco',
    );
  }

  Future<void> cerrarOperacionRompeBaco(int operacionId) async {
    return cerrarOperacion(operacionId, tableName: 'Operacion_rompe_baco');
  }

  Future<Map<String, dynamic>> getCondicionesEquipoByOperacionIdRompeBaco(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_rompebanco',
      columns: ['condiciones_equipo'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    Map<String, dynamic> defaultData = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '', // ✅ nuevo campo
    };

    if (result.isEmpty) {
      return defaultData;
    }

    String condicionesJson =
        result.first['condiciones_equipo'] as String? ?? '{}';

    try {
      Map<String, dynamic> condiciones = jsonDecode(condicionesJson);

      // 🔥 asegurar que el nuevo campo exista
      condiciones.putIfAbsent('horaLlenado', () => '');

      return condiciones;
    } catch (e) {
      print('Error decodificando condiciones de equipo: $e');
      return defaultData;
    }
  }

  Future<Map<String, dynamic>> getControlLlantasByOperacionIdRompeBaco(
    int operacionId,
  ) async {
    return _getControlLlantasFromTable('Operacion_rompebanco', operacionId);
  }

  Future<bool> deleteEstadoRompeBaco(int operacionId, int estadoId) async {
    return deleteEstado(
      operacionId,
      estadoId,
      tableName: 'Operacion_rompe_baco',
    );
  }

  Future<bool> updateControlLlantasRompeBaco(
    int operacionId,
    Map<String, dynamic> controlLlantas,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_rompebanco',
      {'control_llantas': jsonEncode(controlLlantas)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCheckListRompeBaco(
    int operacionId,
    List<Map<String, dynamic>> checkList,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_rompebanco',
      {'check_list': jsonEncode(checkList)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCondicionesEquipoRompeBaco(
    int operacionId,
    Map<String, dynamic> condiciones,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_rompebanco',
      {'condiciones_equipo': jsonEncode(condiciones)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateHorometrosRompeBaco(
    int operacionId,
    Map<String, dynamic> horometros,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_rompebanco',
      {'horometros': jsonEncode(horometros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  //SCALAMIN INICIO---------------------------------------------------------------------------------------------------------------------------------------------

  Future<int> insertOperacionScalamin(
    String fecha,
    String turno,
    String operador,
    String jefeGuardia,
    String equipo,
    String nEquipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? horometrosBase,
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
  }) async {
    final db = await database;

    Map<String, dynamic> horometrosJson = {
      'diesel': {'inicio': 0, 'final': 0, 'op': true},
      'percusion': {'inicio': 0, 'final': 0, 'op': true},
    };

    if (horometrosBase != null && horometrosBase.isNotEmpty) {
      for (var item in horometrosBase) {
        final tipo = item['tipo_horometro'];
        final finalValor = (item['final'] ?? 0).toDouble();

        if (horometrosJson.containsKey(tipo)) {
          horometrosJson[tipo]['inicio'] = finalValor;
        }
      }
    }

    Map<String, dynamic> condicionesEquipoJson = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '',
    };

    final controlLlantasJson = _defaultControlLlantas();

    String checkListStr = jsonEncode(checkListJson ?? []);

    final insertData = <String, dynamic>{
      'fecha': fecha,
      'turno': turno,
      'operador': operador,
      'jefe_guardia': jefeGuardia,
      'equipo': equipo,
      'horometros': jsonEncode(horometrosJson),
      'condiciones_equipo': jsonEncode(condicionesEquipoJson),
      'check_list': checkListStr,
      'control_llantas': jsonEncode(controlLlantasJson),
    };
    if (operadorId != null) insertData['operador_id'] = operadorId;
    if (equipoId != null) insertData['equipo_id'] = equipoId;
    if (jefeGuardiaId != null) insertData['jefe_guardia_id'] = jefeGuardiaId;
    _appendHybridOperationMetadata(
      insertData,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_Scalamin', insertData);
  }

  Future<List<Map<String, dynamic>>> getOperacionScalaminByTurnoAndFechaMaster(
    int turnoId,
    String fecha,
  ) async {
    return _queryAndHydrateOperations(
      'Operacion_Scalamin',
      turnoId,
      fecha,
      onlyActive: true,
    );
  }

  Future<List<Map<String, dynamic>>> getOperacionScalaminByTurnoAndFecha(
    int turnoId,
    String fecha, {
    int? operadorId,
  }) async {
    return _queryAndHydrateOperations(
      'Operacion_Scalamin',
      turnoId,
      fecha,
      operadorId: operadorId,
    );
  }

  // Función para obtener todos los estados de una operación
  Future<List<Map<String, dynamic>>> getEstadosByOperacionIdScalamin(
    int operacionId,
  ) async {
    return getEstadosByOperacionId(
      operacionId,
      tableName: 'Operacion_scalamin',
    );
  }

  Future<int> eliminarOperacionTalScalaminFisico(int id) async {
    final db = await database;

    final result = await db.delete(
      'Operacion_Scalamin',
      where: 'id = ?',
      whereArgs: [id],
    );

    return result; // devuelve el número de filas eliminadas
  }

  Future<bool> updateHoraFinalScalamin(
    int operacionId,
    int estadoId,
    String horaFinal,
  ) async {
    return updateHoraFinal(
      operacionId,
      estadoId,
      horaFinal,
      tableName: 'Operacion_scalamin',
    );
  }

  Future<Map<String, dynamic>?> createEstadoScalamin(
    int operacionId,
    String estado,
    String codigo,
    String horaInicio, {
    String? horaFinal,
    Map<String, dynamic>? operacion,
  }) async {
    return createEstado(
      operacionId,
      estado,
      codigo,
      horaInicio,
      horaFinal: horaFinal,
      operacion: operacion,
      tableName: 'Operacion_scalamin',
    );
  }

  Future<bool> updateEstadoScalamin(
    int operacionId,
    int estadoId, {
    int? numero,
    String? estado,
    String? codigo,
    String? horaInicio,
    String? horaFinal,
    Map<String, String>? operacion,
  }) async {
    return updateEstado(
      operacionId,
      estadoId,
      numero: numero,
      estado: estado,
      codigo: codigo,
      horaInicio: horaInicio,
      horaFinal: horaFinal,
      operacion: operacion?.map((k, v) => MapEntry(k, v.toString())),
      tableName: 'Operacion_scalamin',
    );
  }

  Future<Map<String, dynamic>> getOperacionByEstadoIdScalamin(
    int operacionId,
    int estadoId,
  ) async {
    return getOperacionByEstadoId(
      operacionId,
      estadoId,
      tableName: 'Operacion_scalamin',
    );
  }

  Future<bool> updateOperacionByEstadoIdScalamin(
    int operacionId,
    int estadoId,
    Map<String, dynamic> operacionData,
  ) async {
    return updateOperacionByEstadoId(
      operacionId,
      estadoId,
      operacionData,
      tableName: 'Operacion_scalamin',
    );
  }

  Future<List<Map<String, dynamic>>> getCheckListByOperacionIdScalamin(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_Scalamin',
      columns: ['check_list'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      // Si no hay datos, devolver lista vacía
      return [];
    }

    String checkListJson = result.first['check_list'] as String? ?? '[]';

    try {
      List<dynamic> lista = jsonDecode(checkListJson);
      // Asegurarse de que cada item sea Map<String, dynamic>
      return lista.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error decodificando checklist: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getHorometrosByOperacionIdScalamin(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_Scalamin',
      columns: ['horometros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      return {
        'diesel': {'inicio': 0, 'final': 0, 'op': true},
        'percusion': {'inicio': 0, 'final': 0, 'op': true},
      };
    }

    String horometrosJson = result.first['horometros'] as String? ?? '{}';

    try {
      Map<String, dynamic> horometros = jsonDecode(horometrosJson);

      if (horometros.isEmpty) {
        return {
          'diesel': {'inicio': 0, 'final': 0, 'op': true},
          'percusion': {'inicio': 0, 'final': 0, 'op': true},
        };
      }

      return Map<String, dynamic>.from(horometros);
    } catch (e) {
      print('Error decodificando horómetros: $e');

      return {
        'diesel': {'inicio': 0, 'final': 0, 'op': true},
        'percusion': {'inicio': 0, 'final': 0, 'op': true},
      };
    }
  }

  Future<Map<String, dynamic>?> getUltimoEstadoByOperacionIdScalamin(
    int operacionId,
  ) async {
    return getUltimoEstadoByOperacionId(
      operacionId,
      tableName: 'Operacion_scalamin',
    );
  }

  Future<Map<String, dynamic>?> createReservaEstadoScalamin(
    int operacionId,
    int numero,
    String horaInicio,
    String horaFinal,
  ) async {
    return createReservaEstado(
      operacionId,
      numero,
      horaInicio,
      horaFinal,
      tableName: 'Operacion_scalamin',
    );
  }

  Future<void> cerrarOperacionScalamin(int operacionId) async {
    return cerrarOperacion(operacionId, tableName: 'Operacion_scalamin');
  }

  Future<Map<String, dynamic>> getCondicionesEquipoByOperacionIdScalamin(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_Scalamin',
      columns: ['condiciones_equipo'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    Map<String, dynamic> defaultData = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '', // ✅ nuevo campo
    };

    if (result.isEmpty) {
      return defaultData;
    }

    String condicionesJson =
        result.first['condiciones_equipo'] as String? ?? '{}';

    try {
      Map<String, dynamic> condiciones = jsonDecode(condicionesJson);

      // 🔥 asegurar que el nuevo campo exista
      condiciones.putIfAbsent('horaLlenado', () => '');

      return condiciones;
    } catch (e) {
      print('Error decodificando condiciones de equipo: $e');
      return defaultData;
    }
  }

  Future<Map<String, dynamic>> getControlLlantasByOperacionIdScalamin(
    int operacionId,
  ) async {
    return _getControlLlantasFromTable('Operacion_Scalamin', operacionId);
  }

  Future<bool> deleteEstadoScalamin(int operacionId, int estadoId) async {
    return deleteEstado(operacionId, estadoId, tableName: 'Operacion_scalamin');
  }

  Future<bool> updateControlLlantasScalamin(
    int operacionId,
    Map<String, dynamic> controlLlantas,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_Scalamin',
      {'control_llantas': jsonEncode(controlLlantas)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCheckListScalamin(
    int operacionId,
    List<Map<String, dynamic>> checkList,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_Scalamin',
      {'check_list': jsonEncode(checkList)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCondicionesEquipoScalamin(
    int operacionId,
    Map<String, dynamic> condiciones,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_Scalamin',
      {'condiciones_equipo': jsonEncode(condiciones)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateHorometrosScalamin(
    int operacionId,
    Map<String, dynamic> horometros,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_Scalamin',
      {'horometros': jsonEncode(horometros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  // SCISSOR INICIO----------------------------------------------------------------------------------------------------------------------------------------------------------
  Future<int> insertOperacionScissor(
    String fecha,
    String turno,
    String operador,
    String jefeGuardia,
    String equipo,
    String nEquipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? horometrosBase,
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
  }) async {
    final db = await database;

    Map<String, dynamic> horometrosJson = {
      'diesel': {'inicio': 0, 'final': 0, 'op': true},
    };

    if (horometrosBase != null && horometrosBase.isNotEmpty) {
      for (var item in horometrosBase) {
        final tipo = item['tipo_horometro'];
        final finalValor = (item['final'] ?? 0).toDouble();
        if (horometrosJson.containsKey(tipo)) {
          horometrosJson[tipo]['inicio'] = finalValor;
        }
      }
    }

    Map<String, dynamic> condicionesEquipoJson = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '',
    };

    final controlLlantasJson = _defaultControlLlantas();

    String checkListStr = jsonEncode(checkListJson ?? []);

    final insertData = <String, dynamic>{
      'fecha': fecha,
      'turno': turno,
      'operador': operador,
      'jefe_guardia': jefeGuardia,
      'equipo': equipo,
      'horometros': jsonEncode(horometrosJson),
      'condiciones_equipo': jsonEncode(condicionesEquipoJson),
      'check_list': checkListStr,
      'control_llantas': jsonEncode(controlLlantasJson),
    };
    if (operadorId != null) insertData['operador_id'] = operadorId;
    if (equipoId != null) insertData['equipo_id'] = equipoId;
    if (jefeGuardiaId != null) insertData['jefe_guardia_id'] = jefeGuardiaId;
    _appendHybridOperationMetadata(
      insertData,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );
    return await db.insert('Operacion_scissor', insertData);
  }

  Future<List<Map<String, dynamic>>> getOperacionScissorByTurnoAndFechaMaster(
    int turnoId,
    String fecha,
  ) async {
    return _queryAndHydrateOperations(
      'Operacion_scissor',
      turnoId,
      fecha,
      onlyActive: true,
    );
  }

  Future<List<Map<String, dynamic>>> getOperacionScissorByTurnoAndFecha(
    int turnoId,
    String fecha, {
    int? operadorId,
  }) async {
    return _queryAndHydrateOperations(
      'Operacion_scissor',
      turnoId,
      fecha,
      operadorId: operadorId,
    );
  }

  // Función para obtener todos los estados de una operación
  Future<List<Map<String, dynamic>>> getEstadosByOperacionIdScissor(
    int operacionId,
  ) async {
    return getEstadosByOperacionId(operacionId, tableName: 'Operacion_scissor');
  }

  Future<int> eliminarOperacionTalScissorFisico(int id) async {
    final db = await database;

    final result = await db.delete(
      'Operacion_scissor',
      where: 'id = ?',
      whereArgs: [id],
    );

    return result; // devuelve el número de filas eliminadas
  }

  Future<bool> updateHoraFinalScissor(
    int operacionId,
    int estadoId,
    String horaFinal,
  ) async {
    return updateHoraFinal(
      operacionId,
      estadoId,
      horaFinal,
      tableName: 'Operacion_scissor',
    );
  }

  Future<Map<String, dynamic>?> createEstadoScissor(
    int operacionId,
    String estado,
    String codigo,
    String horaInicio, {
    String? horaFinal,
    Map<String, dynamic>? operacion,
  }) async {
    return createEstado(
      operacionId,
      estado,
      codigo,
      horaInicio,
      horaFinal: horaFinal,
      operacion: operacion,
      tableName: 'Operacion_scissor',
    );
  }

  Future<bool> updateEstadoScissor(
    int operacionId,
    int estadoId, {
    int? numero,
    String? estado,
    String? codigo,
    String? horaInicio,
    String? horaFinal,
    Map<String, String>? operacion,
  }) async {
    return updateEstado(
      operacionId,
      estadoId,
      numero: numero,
      estado: estado,
      codigo: codigo,
      horaInicio: horaInicio,
      horaFinal: horaFinal,
      operacion: operacion?.map((k, v) => MapEntry(k, v.toString())),
      tableName: 'Operacion_scissor',
    );
  }

  Future<Map<String, dynamic>> getOperacionByEstadoIdScissor(
    int operacionId,
    int estadoId,
  ) async {
    return getOperacionByEstadoId(
      operacionId,
      estadoId,
      tableName: 'Operacion_scissor',
    );
  }

  Future<bool> updateOperacionByEstadoIdScissor(
    int operacionId,
    int estadoId,
    Map<String, dynamic> operacionData,
  ) async {
    return updateOperacionByEstadoId(
      operacionId,
      estadoId,
      operacionData,
      tableName: 'Operacion_scissor',
    );
  }

  Future<List<Map<String, dynamic>>> getCheckListByOperacionIdScissor(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_scissor',
      columns: ['check_list'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      // Si no hay datos, devolver lista vacía
      return [];
    }

    String checkListJson = result.first['check_list'] as String? ?? '[]';

    try {
      List<dynamic> lista = jsonDecode(checkListJson);
      // Asegurarse de que cada item sea Map<String, dynamic>
      return lista.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error decodificando checklist: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getHorometrosByOperacionIdScissor(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_scissor',
      columns: ['horometros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    Map<String, dynamic> defaultHorometros = {
      'horometro_principal': {
        'inicio': 0,
        'final': 0,
        'op': true,
      },
      'diesel': {'inicio': 0, 'final': 0, 'op': true},
    };

    if (result.isEmpty) {
      return defaultHorometros;
    }

    String horometrosJson = result.first['horometros'] as String? ?? '{}';

    try {
      Map<String, dynamic> horometros = jsonDecode(horometrosJson);

      if (horometros.isEmpty) {
        return defaultHorometros;
      }

      return Map<String, dynamic>.from(horometros);
    } catch (e) {
      print('Error decodificando horómetros: $e');
      return defaultHorometros;
    }
  }

  Future<Map<String, dynamic>?> getUltimoEstadoByOperacionIdScissor(
    int operacionId,
  ) async {
    return getUltimoEstadoByOperacionId(
      operacionId,
      tableName: 'Operacion_scissor',
    );
  }

  Future<Map<String, dynamic>?> createReservaEstadoScissor(
    int operacionId,
    int numero,
    String horaInicio,
    String horaFinal,
  ) async {
    return createReservaEstado(
      operacionId,
      numero,
      horaInicio,
      horaFinal,
      tableName: 'Operacion_scissor',
    );
  }

  Future<void> cerrarOperacionScissor(int operacionId) async {
    return cerrarOperacion(operacionId, tableName: 'Operacion_scissor');
  }

  Future<Map<String, dynamic>> getCondicionesEquipoByOperacionIdScissor(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_scissor',
      columns: ['condiciones_equipo'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    Map<String, dynamic> defaultData = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '', // ✅ nuevo campo
    };

    if (result.isEmpty) {
      return defaultData;
    }

    String condicionesJson =
        result.first['condiciones_equipo'] as String? ?? '{}';

    try {
      Map<String, dynamic> condiciones = jsonDecode(condicionesJson);

      // 🔥 asegurar que el nuevo campo exista
      condiciones.putIfAbsent('horaLlenado', () => '');

      return condiciones;
    } catch (e) {
      print('Error decodificando condiciones de equipo: $e');
      return defaultData;
    }
  }

  Future<Map<String, dynamic>> getControlLlantasByOperacionIdScissor(
    int operacionId,
  ) async {
    return _getControlLlantasFromTable('Operacion_scissor', operacionId);
  }

  Future<bool> deleteEstadoScissor(int operacionId, int estadoId) async {
    return deleteEstado(operacionId, estadoId, tableName: 'Operacion_scissor');
  }

  Future<bool> updateControlLlantasScissor(
    int operacionId,
    Map<String, dynamic> controlLlantas,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_scissor',
      {'control_llantas': jsonEncode(controlLlantas)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCheckListScissor(
    int operacionId,
    List<Map<String, dynamic>> checkList,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_scissor',
      {'check_list': jsonEncode(checkList)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCondicionesEquipoScissor(
    int operacionId,
    Map<String, dynamic> condiciones,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_scissor',
      {'condiciones_equipo': jsonEncode(condiciones)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateHorometrosScissor(
    int operacionId,
    Map<String, dynamic> horometros,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_scissor',
      {'horometros': jsonEncode(horometros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  // ANFOCHANGER INICIO----------------------------------------------------------------------------------------------------------------------------------------------------------
  Future<int> insertOperacionAnfochanger(
    String fecha,
    String turno,
    String operador,
    String jefeGuardia,
    String equipo,
    String nEquipo, {
    List<Map<String, dynamic>>? checkListJson,
    List<Map<String, dynamic>>? horometrosBase, // 🔥 NUEVO
    String? actorDni,
    int? actorOperadorId,
    int? operadorId,
    int? equipoId,
    int? zonaId,
    int? jefeGuardiaId,
    int? identityVersion,
    int? syncable,
    int? turnoId,
    String? frenteOrigen,
    int? registradorUsuarioId,
    String? registradorNombre,
    int? laborId,
    String? labor,
  }) async {
    final db = await database;

    /// 🔥 estructura base
    Map<String, dynamic> horometrosJson = {
      'horometro_principal': {
        'inicio': 0,
        'final': 0,
        'op': true,
      },
      'electrico': {'inicio': 0, 'final': 0, 'op': true},
      'diesel': {'inicio': 0, 'final': 0, 'op': true},
    };

    /// 🔥 aplicar valores de nube
    if (horometrosBase != null && horometrosBase.isNotEmpty) {
      for (var item in horometrosBase) {
        final tipo = item['tipo_horometro'];
        final finalValor = (item['final'] ?? 0).toDouble();

        if (horometrosJson.containsKey(tipo)) {
          horometrosJson[tipo]['inicio'] = finalValor;
        }
      }
    }

    /// Condiciones equipo
    Map<String, dynamic> condicionesEquipoJson = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '',
    };

    /// Control llantas
    final controlLlantasJson = _defaultControlLlantas();

    /// Checklist
    String checkListStr = jsonEncode(checkListJson ?? []);

    final insertData = <String, dynamic>{
      'fecha': fecha,
      'turno': turno,
      'operador': operador,
      'jefe_guardia': jefeGuardia,
      'equipo': equipo,
      'horometros': jsonEncode(horometrosJson),
      'condiciones_equipo': jsonEncode(condicionesEquipoJson),
      'check_list': checkListStr,
      'control_llantas': jsonEncode(controlLlantasJson),
    };
    if (operadorId != null) insertData['operador_id'] = operadorId;
    if (equipoId != null) insertData['equipo_id'] = equipoId;
    if (jefeGuardiaId != null) insertData['jefe_guardia_id'] = jefeGuardiaId;

    _appendHybridOperationMetadata(
      insertData,
      turnoId: turnoId,
      frenteOrigen: frenteOrigen,
      registradorUsuarioId: registradorUsuarioId,
      registradorNombre: registradorNombre,
      laborId: laborId,
      labor: labor,
    );

    return await db.insert('Operacion_anfochanger', insertData);
  }

  Future<List<Map<String, dynamic>>>
  getOperacionAnfochangerByTurnoAndFechaMaster(
    int turnoId,
    String fecha,
  ) async {
    return _queryAndHydrateOperations(
      'Operacion_anfochanger',
      turnoId,
      fecha,
      onlyActive: true,
    );
  }

  Future<List<Map<String, dynamic>>> getOperacionAnfochangerByTurnoAndFecha(
    int turnoId,
    String fecha, {
    int? operadorId,
  }) async {
    return _queryAndHydrateOperations(
      'Operacion_anfochanger',
      turnoId,
      fecha,
      operadorId: operadorId,
    );
  }

  // Función para obtener todos los estados de una operación
  Future<List<Map<String, dynamic>>> getEstadosByOperacionIdAnfochanger(
    int operacionId,
  ) async {
    return getEstadosByOperacionId(
      operacionId,
      tableName: 'Operacion_anfochanger',
    );
  }

  Future<int> eliminarOperacionTalAnfochangerFisico(int id) async {
    final db = await database;

    final result = await db.delete(
      'Operacion_anfochanger',
      where: 'id = ?',
      whereArgs: [id],
    );

    return result; // devuelve el número de filas eliminadas
  }

  Future<bool> updateHoraFinalAnfochanger(
    int operacionId,
    int estadoId,
    String horaFinal,
  ) async {
    return updateHoraFinal(
      operacionId,
      estadoId,
      horaFinal,
      tableName: 'Operacion_anfochanger',
    );
  }

  Future<Map<String, dynamic>?> createEstadoAnfochanger(
    int operacionId,
    String estado,
    String codigo,
    String horaInicio, {
    String? horaFinal,
    Map<String, dynamic>? operacion,
  }) async {
    return createEstado(
      operacionId,
      estado,
      codigo,
      horaInicio,
      horaFinal: horaFinal,
      operacion: operacion,
      tableName: 'Operacion_anfochanger',
    );
  }

  Future<bool> updateEstadoAnfochanger(
    int operacionId,
    int estadoId, {
    int? numero,
    String? estado,
    String? codigo,
    String? horaInicio,
    String? horaFinal,
    Map<String, String>? operacion,
  }) async {
    return updateEstado(
      operacionId,
      estadoId,
      numero: numero,
      estado: estado,
      codigo: codigo,
      horaInicio: horaInicio,
      horaFinal: horaFinal,
      operacion: operacion?.map((k, v) => MapEntry(k, v.toString())),
      tableName: 'Operacion_anfochanger',
    );
  }

  Future<Map<String, dynamic>> getOperacionByEstadoIdAnfochanger(
    int operacionId,
    int estadoId,
  ) async {
    return getOperacionByEstadoId(
      operacionId,
      estadoId,
      tableName: 'Operacion_anfochanger',
    );
  }

  Future<bool> updateOperacionByEstadoIdAnfochanger(
    int operacionId,
    int estadoId,
    Map<String, dynamic> operacionData,
  ) async {
    return updateOperacionByEstadoId(
      operacionId,
      estadoId,
      operacionData,
      tableName: 'Operacion_anfochanger',
    );
  }

  Future<List<Map<String, dynamic>>> getCheckListByOperacionIdAnfochanger(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_anfochanger',
      columns: ['check_list'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    if (result.isEmpty) {
      // Si no hay datos, devolver lista vacía
      return [];
    }

    String checkListJson = result.first['check_list'] as String? ?? '[]';

    try {
      List<dynamic> lista = jsonDecode(checkListJson);
      // Asegurarse de que cada item sea Map<String, dynamic>
      return lista.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error decodificando checklist: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getHorometrosByOperacionIdAnfochanger(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_anfochanger',
      columns: ['horometros'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    Map<String, dynamic> defaultHorometros = {
      'horometro_principal': {
        'inicio': 0,
        'final': 0,
        'op': true,
      },
      'electrico': {'inicio': 0, 'final': 0, 'op': true},
      'diesel': {'inicio': 0, 'final': 0, 'op': true},
    };

    if (result.isEmpty) {
      return defaultHorometros;
    }

    String horometrosJson = result.first['horometros'] as String? ?? '{}';

    try {
      Map<String, dynamic> horometros = jsonDecode(horometrosJson);

      if (horometros.isEmpty) {
        return defaultHorometros;
      }

      /// Asegurar que los 3 horómetros existan (por migraciones)
      defaultHorometros.forEach((key, value) {
        horometros.putIfAbsent(key, () => value);
      });

      return Map<String, dynamic>.from(horometros);
    } catch (e) {
      print('Error decodificando horómetros: $e');
      return defaultHorometros;
    }
  }

  Future<Map<String, dynamic>?> getUltimoEstadoByOperacionIdAnfochanger(
    int operacionId,
  ) async {
    return getUltimoEstadoByOperacionId(
      operacionId,
      tableName: 'Operacion_anfochanger',
    );
  }

  Future<Map<String, dynamic>?> createReservaEstadoAnfochanger(
    int operacionId,
    int numero,
    String horaInicio,
    String horaFinal,
  ) async {
    return createReservaEstado(
      operacionId,
      numero,
      horaInicio,
      horaFinal,
      tableName: 'Operacion_anfochanger',
    );
  }

  Future<void> cerrarOperacionAnfochanger(int operacionId) async {
    return cerrarOperacion(operacionId, tableName: 'Operacion_anfochanger');
  }

  Future<Map<String, dynamic>> getCondicionesEquipoByOperacionIdAnfochanger(
    int operacionId,
  ) async {
    final db = await database;

    final result = await db.query(
      'Operacion_anfochanger',
      columns: ['condiciones_equipo'],
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    Map<String, dynamic> defaultData = {
      'op': false,
      'noOp': false,
      'lugar': '',
      'descripcion': '',
      'aceiteMotor': false,
      'aceiteHidraulico': false,
      'aceiteTransmision': false,
      'combustible': '',
      'horaLlenado': '', // ✅ nuevo campo
    };

    if (result.isEmpty) {
      return defaultData;
    }

    String condicionesJson =
        result.first['condiciones_equipo'] as String? ?? '{}';

    try {
      Map<String, dynamic> condiciones = jsonDecode(condicionesJson);

      // 🔥 asegurar que el nuevo campo exista
      condiciones.putIfAbsent('horaLlenado', () => '');

      return condiciones;
    } catch (e) {
      print('Error decodificando condiciones de equipo: $e');
      return defaultData;
    }
  }

  Future<Map<String, dynamic>> getControlLlantasByOperacionIdAnfochanger(
    int operacionId,
  ) async {
    return _getControlLlantasFromTable('Operacion_anfochanger', operacionId);
  }

  Future<bool> deleteEstadoAnfochanger(int operacionId, int estadoId) async {
    return deleteEstado(
      operacionId,
      estadoId,
      tableName: 'Operacion_anfochanger',
    );
  }

  Future<bool> updateControlLlantasAnfochanger(
    int operacionId,
    Map<String, dynamic> controlLlantas,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_anfochanger',
      {'control_llantas': jsonEncode(controlLlantas)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCheckListAnfochanger(
    int operacionId,
    List<Map<String, dynamic>> checkList,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_anfochanger',
      {'check_list': jsonEncode(checkList)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateCondicionesEquipoAnfochanger(
    int operacionId,
    Map<String, dynamic> condiciones,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_anfochanger',
      {'condiciones_equipo': jsonEncode(condiciones)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  Future<bool> updateHorometrosAnfochanger(
    int operacionId,
    Map<String, dynamic> horometros,
  ) async {
    final db = await database;

    int updated = await db.update(
      'Operacion_anfochanger',
      {'horometros': jsonEncode(horometros)},
      where: 'id = ?',
      whereArgs: [operacionId],
    );

    return updated > 0;
  }

  //ENVIOS A LA NUBE---------------------------------------------------------------------
  //TAL-LARGO
  Future<int> actualizarEnvio(int id) async {
    final db = await database;
    return await db.update(
      'Operacion_tal_largo',
      {'enviado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> actualizarIdNubeOpseracion(int idOperacion, int idNube) async {
    final db = await database;
    return await db.update(
      'Operacion_tal_largo',
      {'idNube': idNube},
      where: 'id = ?',
      whereArgs: [idOperacion],
    );
  }

  Future<List<Map<String, dynamic>>> getOperacionesTaladroLargo() async {
    return _getNormalizedOperationRows('Operacion_tal_largo');
  }

  Future<List<Map<String, dynamic>>> getOperacionesNoEnviadasLargo() async {
    return _getNormalizedOperationRows(
      'Operacion_tal_largo',
      where: 'enviado = ? AND cerrado = ?',
      whereArgs: [0, 1],
    );
  }

  //TAL-HORIZONTAL
  Future<List<Map<String, dynamic>>> getOperacionesTaladroHorizontal() async {
    return _getNormalizedOperationRows('Operacion_tal_horizontal');
  }

  Future<List<Map<String, dynamic>>>
  getOperacionesTaladroHorizontalNoEnviadas() async {
    return _getNormalizedOperationRows(
      'Operacion_tal_horizontal',
      where: 'enviado = ? AND cerrado = ?',
      whereArgs: [0, 1],
    );
  }

  Future<int> actualizarEnvioHorizontal(int id) async {
    final db = await database;

    return await db.update(
      'Operacion_tal_horizontal',
      {'enviado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //EMPERNADOR
  Future<List<Map<String, dynamic>>> getOperacionesTaladroEmpernador() async {
    return _getNormalizedOperationRows('Operacion_empernador');
  }

  Future<List<Map<String, dynamic>>>
  getOperacionesEmpernadorNoEnviadas() async {
    return _getNormalizedOperationRows(
      'Operacion_empernador',
      where: 'enviado = ? AND cerrado = ?',
      whereArgs: [0, 1],
    );
  }

  Future<int> actualizarEnvioEmpernador(int id) async {
    final db = await database;

    return await db.update(
      'Operacion_empernador',
      {'enviado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //CARGUIO
  Future<List<Map<String, dynamic>>> getOperacionesTaladroCarguio() async {
    return _getNormalizedOperationRows('Operacion_carguio');
  }

  Future<List<Map<String, dynamic>>> getOperacionesCarguioNoEnviadas() async {
    return _getNormalizedOperationRows(
      'Operacion_carguio',
      where: 'enviado = ? AND cerrado = ?',
      whereArgs: [0, 1],
    );
  }

  Future<int> actualizarEnvioCarguio(int id) async {
    final db = await database;

    return await db.update(
      'Operacion_carguio',
      {'enviado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //Dumper-------------------------------------------------

  Future<List<Map<String, dynamic>>> getOperacionesTaladroDumper() async {
    return _getNormalizedOperationRows('Operacion_Dumper');
  }

  Future<List<Map<String, dynamic>>> getOperacionesDumperNoEnviadas() async {
    return _getNormalizedOperationRows(
      'Operacion_Dumper',
      where: 'enviado = ? AND cerrado = ?',
      whereArgs: [0, 1],
    );
  }

  Future<int> actualizarEnvioDumper(int id) async {
    final db = await database;

    return await db.update(
      'Operacion_Dumper',
      {'enviado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //ROMPE BANCOS
  Future<List<Map<String, dynamic>>> getOperacionesTaladroRompeBaco() async {
    return _getNormalizedOperationRows('Operacion_rompebanco');
  }

  Future<List<Map<String, dynamic>>>
  getOperacionesRompeBancosNoEnviadas() async {
    return _getNormalizedOperationRows(
      'Operacion_rompebanco',
      where: 'enviado = ? AND cerrado = ?',
      whereArgs: [0, 1],
    );
  }

  Future<int> actualizarEnvioRompeBancos(int id) async {
    final db = await database;

    return await db.update(
      'Operacion_rompebanco',
      {'enviado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //SCALAMIN
  Future<List<Map<String, dynamic>>> getOperacionesTaladroScalamin() async {
    return _getNormalizedOperationRows('Operacion_Scalamin');
  }

  Future<List<Map<String, dynamic>>> getOperacionesScalaminNoEnviadas() async {
    return _getNormalizedOperationRows(
      'Operacion_Scalamin',
      where: 'enviado = ? AND cerrado = ?',
      whereArgs: [0, 1],
    );
  }

  Future<int> actualizarEnvioScalamin(int id) async {
    final db = await database;

    return await db.update(
      'Operacion_Scalamin',
      {'enviado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //ANFOCHANGER
  Future<List<Map<String, dynamic>>> getOperacionesTaladroAnfoChanger() async {
    return _getNormalizedOperationRows('Operacion_anfochanger');
  }

  Future<List<Map<String, dynamic>>>
  getOperacionesAnfoChangerNoEnviadas() async {
    return _getNormalizedOperationRows(
      'Operacion_anfochanger',
      where: 'enviado = ? AND cerrado = ?',
      whereArgs: [0, 1],
    );
  }

  Future<int> actualizarEnvioRAnfoChanger(int id) async {
    final db = await database;

    return await db.update(
      'Operacion_anfochanger',
      {'enviado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //scissor
  Future<List<Map<String, dynamic>>> getOperacionesTaladroscissor() async {
    return _getNormalizedOperationRows('Operacion_scissor');
  }

  Future<List<Map<String, dynamic>>> getOperacionesScissorNoEnviadas() async {
    return _getNormalizedOperationRows(
      'Operacion_scissor',
      where: 'enviado = ? AND cerrado = ?',
      whereArgs: [0, 1],
    );
  }

  Future<int> actualizarEnvioscissor(int id) async {
    final db = await database;

    return await db.update(
      'Operacion_scissor',
      {'enviado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //EXPLOSIVOS ----------------------------------------------------------

  Future<bool> estaRegistroCerrado(int idExploracion) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'Datos_trabajo_exploraciones',
      columns: ['cerrado'],
      where: 'id = ?',
      whereArgs: [idExploracion],
    );

    if (result.isNotEmpty) {
      return result.first['cerrado'] == 1;
    }
    return false; // Si no encuentra el registro, asumimos que no está cerrado
  }

  Future<int> updateEstadoExploracion(int id, String nuevoEstado) async {
    final db = await database;

    return await db.update(
      'Datos_trabajo_exploraciones',
      {'estado': nuevoEstado}, // Nuevo estado
      where: 'id = ?',
      whereArgs: [id], // Filtro por ID
    );
  }

  Future<List<TipoPerforacion>> getTiposPerforacion() async {
    final db = await sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'tipo_perforaciones',
    );
    return List.generate(maps.length, (i) => TipoPerforacion.fromJson(maps[i]));
  }

  Future<Map<String, dynamic>?> getExploracionById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'Datos_trabajo_exploraciones',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> updateExploracion(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update(
      'Datos_trabajo_exploraciones',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertExploracionFull(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('Datos_trabajo_exploraciones', row);
  }

  Future<List<Map<String, String>>> getAccesoriosunidad() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accesorios',
      columns: ['tipo_accesorio', 'unidad_medida'],
    );

    return maps
        .map(
          (map) => {
            'tipo': map['tipo_accesorio'] as String,
            'unidad_medida': map['unidad_medida'] as String,
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> obtenerEstructuraCompleta(
    int idPadre,
  ) async {
    final Database db = await database;

    List<Map<String, dynamic>> datosTrabajo = await db.query(
      'Datos_trabajo_exploraciones',
      where: 'id = ?',
      whereArgs: [idPadre],
    );

    if (datosTrabajo.isEmpty) return [];

    return datosTrabajo;
  }

  Future<void> cerrarRegistro(int idExploracion) async {
    final db = await database;
    await db.update(
      'Datos_trabajo_exploraciones',
      {'cerrado': 1}, // Marcar como cerrado
      where: 'id = ?',
      whereArgs: [idExploracion],
    );
  }

  Future<int> insertExploracion(
    String fecha,
    String turno,
    String semanaDefault,
  ) async {
    final db = await database;

    int idExploracion = await db.insert('Datos_trabajo_exploraciones', {
      'fecha': fecha,
      'turno': turno,
      'semanaDefault': semanaDefault,
      'estado': 'Creado',
    });

    return idExploracion;
  }

  Future<List<Map<String, dynamic>>> getExploraciones() async {
    final db = await database;
    return await db.query('Datos_trabajo_exploraciones', orderBy: 'id DESC');
  }

  Future<List<Accesorio>> getAccesorios() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accesorios');

    return List.generate(maps.length, (i) => Accesorio.fromJson(maps[i]));
  }

  Future<bool> eliminarEstructuraCompletaManual(int idExploracion) async {
    final db = await database;

    List<Map<String, dynamic>> resultado = await db.query(
      'Datos_trabajo_exploraciones',
      columns: ['cerrado'],
      where: 'id = ?',
      whereArgs: [idExploracion],
    );

    if (resultado.isNotEmpty && resultado.first['cerrado'] == 1) {
      print("El registro ya está cerrado y no se puede eliminar.");
      return false;
    }

    await db.delete(
      'Datos_trabajo_exploraciones',
      where: 'id = ?',
      whereArgs: [idExploracion],
    );

    return true;
  }

  Future<List<TipoPerforacion>> getTiposPerforacionhorizontalfil() async {
    final db = await sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'tipo_perforaciones',
      where: 'proceso = ? AND permitido_medicion = ?',
      whereArgs: ['PERFORACIÓN HORIZONTAL', 1],
    );
    return List.generate(maps.length, (i) => TipoPerforacion.fromJson(maps[i]));
  }

  Future<int> insertarMedicionHorizontal(Map<String, dynamic> datos) async {
    final db = await database;
    return await db.insert(
      'mediciones_horizontal',
      datos,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> obtenerTodasMedicionesHorizontal() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'mediciones_horizontal',
      orderBy: 'fecha DESC', // Ordenar por fecha descendente
    );
    return result;
  }

  Future<int> eliminarMultiplesMedicionesLargo(List<int> ids) async {
    if (ids.isEmpty) return 0;

    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');

    return await db.delete(
      'mediciones_largo',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  //TONELADASSSS----------------------------------------------------------------------
  Future<List<TipoPerforacion>> getTiposPerforacionLargofil() async {
    final db = await sharedCatalogDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'tipo_perforaciones',
      where: 'proceso = ? AND permitido_medicion = ?',
      whereArgs: ['PERFORACIÓN TALADROS LARGOS', 1],
    );
    return List.generate(maps.length, (i) => TipoPerforacion.fromJson(maps[i]));
  }

  Future<int> insertarMedicionLargo(Map<String, dynamic> datos) async {
    final db = await database;
    return await db.insert(
      'mediciones_largo',
      datos,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> obtenerTodasMedicionesLargo() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'mediciones_largo',
      orderBy: 'fecha DESC', // Ordenar por fecha descendente
    );
    return result;
  }

  Future<int> deleteDatosTrabajo(int id) async {
    final db = await database;
    return await db.delete(
      'Datos_trabajo_exploraciones',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> actualizarEnvioDatos_trabajo_exploraciones(int id) async {
    final db = await database;

    // Mapa de los datos que quieres actualizar
    Map<String, dynamic> data = {
      'envio': 1, // Actualiza el campo envio a 1
    };

    // Llamada a la función update
    return await db.update(
      'Datos_trabajo_exploraciones', // El nombre de la tabla
      data, // Los datos a actualizar
      where: 'id = ?', // Condición para seleccionar la fila
      whereArgs: [id], // El valor de id para seleccionar la fila específica
    );
  }

  //NUBE
  Future<Map<String, dynamic>?> obtenerMedicionHorizontalPorId(int id) async {
    final Database db = await database;

    // Obtener el registro de mediciones_horizontal con el ID especificado
    List<Map<String, dynamic>> mediciones = await db.query(
      'mediciones_horizontal',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (mediciones.isEmpty) return null;

    // Retornar el primer registro como Map<String, dynamic>
    return mediciones.first;
  }

  Future<int> eliminarMultiplesMedicionesHorizontal(List<int> ids) async {
    if (ids.isEmpty) return 0;

    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');

    return await db.delete(
      'mediciones_horizontal',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<int> actualizarEnvioMedicionesHorizontal(List<int> ids) async {
    final db = await database;
    final idPlaceholders = List.filled(ids.length, '?').join(', ');

    return await db.update(
      'mediciones_horizontal',
      {'envio': 1},
      where: 'id IN ($idPlaceholders)',
      whereArgs: ids,
    );
  }

}
