import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message.dart';
import '../models/telemetry_data.dart';
import '../models/app_config.dart';

class DatabaseService {
  static Database? _database;
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'telemetry.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }
  
  static Future<void> _createTables(Database db, int version) async {
    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender TEXT NOT NULL,
        content TEXT NOT NULL,
        isEncrypted INTEGER NOT NULL,
        isFromMe INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        type INTEGER NOT NULL
      )
    ''');
    
    // Telemetry data table
    await db.execute('''
      CREATE TABLE telemetry_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL,
        longitude REAL,
        timestamp INTEGER NOT NULL,
        additionalData TEXT
      )
    ''');
    
    // App config table
    await db.execute('''
      CREATE TABLE app_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pairedNumber TEXT,
        pairedAlias TEXT,
        passkey TEXT,
        autoDeleteSms INTEGER NOT NULL DEFAULT 0,
        showDataContentInChat INTEGER NOT NULL DEFAULT 1
      )
    ''');
    
    // Insert default config
    await db.insert('app_config', {
      'pairedNumber': null,
      'pairedAlias' : null,
      'passkey': null,
      'autoDeleteSms': 0,
      'showDataContentInChat' : 1
    });
  }
  
  // Message operations
  static Future<int> insertMessage(Message message) async {
    final db = await database;
    return await db.insert('messages', message.toMap());
  }
  
  static Future<List<Message>> getMessages() async {
    final db = await database;
    final maps = await db.query('messages', orderBy: 'timestamp ASC');
    return maps.map((map) => Message.fromMap(map)).toList();
  }
  
  static Future<void> deleteMessage(int id) async {
    final db = await database;
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }
  
  // Telemetry data operations
  static Future<int> insertTelemetryData(TelemetryData data) async {
    final db = await database;
    return await db.insert('telemetry_data', data.toMap());
  }
  
  static Future<List<TelemetryData>> getTelemetryData() async {
    final db = await database;
    final maps = await db.query('telemetry_data', orderBy: 'timestamp DESC');
    return maps.map((map) => TelemetryData.fromMap(map)).toList();
  }
  
  static Future<TelemetryData?> getLatestTelemetryData() async {
    final db = await database;
    final maps = await db.query(
      'telemetry_data',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return TelemetryData.fromMap(maps.first);
  }
  
  // App config operations
  static Future<AppConfig> getAppConfig() async {
    final db = await database;
    final maps = await db.query('app_config', limit: 1);
    
    if (maps.isEmpty) {
      return AppConfig();
    }

    print("LAAALALALALJDSAJFKKSJFO:SIJFOIDSFJDSIOFJNEIUDFhneiuem");
    print(maps.first);
    return AppConfig.fromMap(maps.first);
  }
  
  static Future<void> updateAppConfig(AppConfig config) async {
    final db = await database;
    final pnt = await db.update(
      'app_config',
      config.toMap(),
      where: 'id = 1',
    );
  }
} 