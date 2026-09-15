import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/crash_report.dart';

/// Singleton SQLite service for persisting crash reports locally.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  static const String _tableName = 'crash_reports';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'crashlens.db');
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        exception_type TEXT NOT NULL,
        stack_trace_raw TEXT NOT NULL,
        root_cause_summary TEXT NOT NULL,
        confidence_score INTEGER NOT NULL,
        suggested_patch TEXT NOT NULL,
        explanation_text TEXT NOT NULL,
        source_file_reference TEXT NOT NULL,
        analysis_mode TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  /// Insert a new crash report. Returns the inserted row id.
  Future<int> insertCrashReport(CrashReport report) async {
    final db = await database;
    return db.insert(
      _tableName,
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch all crash reports, ordered newest first.
  Future<List<CrashReport>> getAllReports() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: 'timestamp DESC',
    );
    return maps.map(CrashReport.fromMap).toList();
  }

  /// Fetch a single report by its UUID.
  Future<CrashReport?> getReportById(String id) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CrashReport.fromMap(maps.first);
  }

  /// Delete a crash report by ID.
  Future<int> deleteReport(String id) async {
    final db = await database;
    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all reports (for testing / "clear history").
  Future<int> clearAll() async {
    final db = await database;
    return db.delete(_tableName);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
    _database = null;
  }
}
