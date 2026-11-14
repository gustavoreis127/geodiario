import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/registro.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Future<Database>? _database;

  Future<Database> get database {
    return _database ??= _inicializarBanco();
  }

  Future<Database> _inicializarBanco() async {
    final pastaBanco = await getDatabasesPath();
    final caminhoBanco = join(pastaBanco, 'geodiario.db');

    return await openDatabase(
      caminhoBanco,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE registros (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo TEXT NOT NULL,
            caminhoImagem TEXT NOT NULL,
            dataHora TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> inserirRegistro(Registro registro) async {
    final db = await database;

    final dados = registro.toMap();

    if (registro.id == null) {
      dados.remove('id');
    }

    return await db.insert(
      'registros',
      dados,
    );
  }

  Future<List<Registro>> listarRegistros() async {
    final db = await database;

    final List<Map<String, dynamic>> mapas = await db.query(
      'registros',
      orderBy: 'id DESC',
    );

    return mapas.map((mapa) => Registro.fromMap(mapa)).toList();
  }

  Future<int> deletarRegistro(int id) async {
    final db = await database;

    return await db.delete(
      'registros',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}