import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/models/DimAla.dart';
import 'package:i_miner/models/DimArea.dart';
import 'package:i_miner/models/DimEstructuraMineral.dart';
import 'package:i_miner/models/DimFase.dart';
import 'package:i_miner/models/DimLabor.dart';
import 'package:i_miner/models/DimMina.dart';
import 'package:i_miner/models/DimNivel.dart';
import 'package:i_miner/models/DimTipoLabor.dart';
import 'package:i_miner/models/DimZona.dart';
import 'package:i_miner/models/malla.dart';
import 'package:i_miner/models/perno.dart';

class SharedCatalogRepository {
  SharedCatalogRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  Future<List<Perno>> getPernos() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query(
      'pernos',
      orderBy: 'tipo_perno ASC, longitud ASC',
    );

    return maps.map(Perno.fromJson).toList();
  }

  Future<List<Malla>> getMallas() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('mallas', orderBy: 'tipo_malla ASC');

    return maps.map(Malla.fromJson).toList();
  }

  Future<List<DimLabor>> getLabores() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('labores', orderBy: 'nombre_labor ASC');

    return maps.map(DimLabor.fromJson).toList();
  }

  Future<List<DimMina>> getMinas() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('minas', orderBy: 'nombre ASC');

    return maps.map(DimMina.fromJson).toList();
  }

  Future<List<DimZona>> getZonas() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('zona', orderBy: 'nombre ASC');

    return maps.map(DimZona.fromJson).toList();
  }

  Future<List<DimArea>> getAreas() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('area', orderBy: 'nombre ASC');

    return maps.map(DimArea.fromJson).toList();
  }

  Future<List<DimFase>> getFases() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('fase', orderBy: 'nombre ASC');

    return maps.map(DimFase.fromJson).toList();
  }

  Future<List<DimTipoLabor>> getTiposLabor() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('tipo_labor', orderBy: 'nombre ASC');

    return maps.map(DimTipoLabor.fromJson).toList();
  }

  Future<List<DimEstructuraMineral>> getEstructurasMinerales() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('estructura_mineral', orderBy: 'nombre ASC');

    return maps.map(DimEstructuraMineral.fromJson).toList();
  }

  Future<List<DimNivel>> getNiveles() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('nivel', orderBy: 'nombre ASC');

    return maps.map(DimNivel.fromJson).toList();
  }

  Future<List<DimAla>> getAlas() async {
    final db = await _databaseHelper.sharedCatalogDatabase;
    final maps = await db.query('ala', orderBy: 'orden ASC, nombre ASC');

    return maps.map(DimAla.fromJson).toList();
  }
}
