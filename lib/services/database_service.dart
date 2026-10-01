import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/wish_item.dart';

class DatabaseService {
  DatabaseService._();

  static final instance = DatabaseService._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory(join(documents.path, 'wishbox'));
    await folder.create(recursive: true);
    final databasePath = join(folder.path, 'wishbox.db');
    _database = await openDatabase(
      databasePath,
      version: 4,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE wishes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          category TEXT NOT NULL DEFAULT '',
          note TEXT NOT NULL DEFAULT '',
          source_url TEXT NOT NULL DEFAULT '',
          image_path TEXT,
          created_at TEXT NOT NULL,
          status TEXT NOT NULL,
          is_inbox INTEGER NOT NULL DEFAULT 0,
          raw_input TEXT NOT NULL DEFAULT '',
          ai_organized INTEGER NOT NULL DEFAULT 0,
          ai_confidence REAL,
          ai_suggested_category TEXT NOT NULL DEFAULT '',
          ai_pending INTEGER NOT NULL DEFAULT 0
        )
      '''),
      onUpgrade: (db, oldVersion, newVersion) async {
        final columns = await db.rawQuery('PRAGMA table_info(wishes)');
        final names = columns.map((column) => column['name']).toSet();
        if (oldVersion < 2 && !names.contains('is_inbox')) {
          await db.execute(
              'ALTER TABLE wishes ADD COLUMN is_inbox INTEGER NOT NULL DEFAULT 0');
        }
        if (oldVersion < 3) {
          if (!names.contains('raw_input')) {
            await db.execute(
                "ALTER TABLE wishes ADD COLUMN raw_input TEXT NOT NULL DEFAULT ''");
          }
          if (!names.contains('ai_organized')) {
            await db.execute(
                'ALTER TABLE wishes ADD COLUMN ai_organized INTEGER NOT NULL DEFAULT 0');
          }
          if (!names.contains('ai_confidence')) {
            await db
                .execute('ALTER TABLE wishes ADD COLUMN ai_confidence REAL');
          }
          if (!names.contains('ai_suggested_category')) {
            await db.execute(
              "ALTER TABLE wishes ADD COLUMN ai_suggested_category TEXT NOT NULL DEFAULT ''",
            );
          }
        }
        if (oldVersion < 4 && !names.contains('ai_pending')) {
          await db.execute(
              'ALTER TABLE wishes ADD COLUMN ai_pending INTEGER NOT NULL DEFAULT 0');
        }
      },
    );
    return _database!;
  }

  Future<List<WishItem>> getItems({
    String query = '',
    String? category,
    String? status,
    bool inboxOnly = false,
  }) async {
    final clauses = <String>[];
    final arguments = <Object?>[];
    if (query.trim().isNotEmpty) {
      clauses.add('(LOWER(title) LIKE ? OR LOWER(note) LIKE ?)');
      final search = '%${query.trim().toLowerCase()}%';
      arguments.addAll([search, search]);
    }
    if (category != null) {
      clauses.add('category = ?');
      arguments.add(category);
    }
    if (status != null) {
      clauses.add('status = ?');
      arguments.add(status);
    }
    if (inboxOnly) {
      clauses.add('is_inbox = 1');
    }
    final rows = await (await database).query(
      'wishes',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: arguments,
      orderBy: 'created_at DESC',
    );
    return rows.map((row) => WishItem.fromMap(row)).toList();
  }

  Future<int> getInboxCount() async =>
      Sqflite.firstIntValue(
        await (await database)
            .rawQuery('SELECT COUNT(*) FROM wishes WHERE is_inbox = 1'),
      ) ??
      0;

  Future<int> insert(WishItem item) async {
    final data = item.toMap()..remove('id');
    return (await database).insert('wishes', data);
  }

  Future<void> update(WishItem item) async {
    await (await database).update(
      'wishes',
      item.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<bool> finishPendingAi(WishItem item) async {
    final data = item.toMap()..remove('id');
    final updated = await (await database).update(
      'wishes',
      data,
      where: 'id = ? AND ai_pending = 1',
      whereArgs: [item.id],
    );
    return updated == 1;
  }

  Future<void> delete(int id) async {
    await (await database).delete('wishes', where: 'id = ?', whereArgs: [id]);
  }
}
