import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_history_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('scanner_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE scan_history ADD COLUMN isFavorite INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE scan_history ADD COLUMN category TEXT DEFAULT "Other"');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scan_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        resultType TEXT NOT NULL,
        scannedAt TEXT NOT NULL,
        isGenerated INTEGER NOT NULL,
        isFavorite INTEGER NOT NULL,
        category TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertScan(ScanHistory scan) async {
    final db = await instance.database;
    return await db.insert('scan_history', scan.toMap());
  }

  Future<int> updateScan(ScanHistory scan) async {
    final db = await instance.database;
    return await db.update(
      'scan_history',
      scan.toMap(),
      where: 'id = ?',
      whereArgs: [scan.id],
    );
  }

  Future<List<ScanHistory>> getAllScans() async {
    final db = await instance.database;
    final result = await db.query('scan_history', orderBy: 'scannedAt DESC');
    return result.map((json) => ScanHistory.fromMap(json)).toList();
  }

  Future<int> deleteScan(int id) async {
    final db = await instance.database;
    return await db.delete(
      'scan_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllScans() async {
    final db = await instance.database;
    return await db.delete('scan_history');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
