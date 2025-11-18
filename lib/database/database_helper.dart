import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/todo.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (kIsWeb) throw UnsupportedError('sqflite is not supported on web');
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'todos.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdDate TEXT NOT NULL
      )
    ''');
  }

  // In-memory storage for web
  final List<Todo> _webTodos = [];
  int _webNextId = 1;

  Future<int> insertTodo(Todo todo) async {
    if (kIsWeb) {
      todo.id = _webNextId++;
      _webTodos.add(todo);
      return todo.id!;
    }
    Database db = await database;
    return await db.insert('todos', todo.toMap());
  }

  Future<List<Todo>> getTodos() async {
    if (kIsWeb) {
      return List.from(_webTodos);
    }
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('todos');
    return List.generate(maps.length, (i) {
      return Todo.fromMap(maps[i]);
    });
  }

  Future<int> updateTodo(Todo todo) async {
    if (kIsWeb) {
      final index = _webTodos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        _webTodos[index] = todo;
        return 1; // Indicate success
      }
      return 0; // Indicate failure (not found)
    }
    Database db = await database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<int> deleteTodo(int id) async {
    if (kIsWeb) {
      final initialLength = _webTodos.length;
      _webTodos.removeWhere((todo) => todo.id == id);
      return initialLength - _webTodos.length; // 1 if removed, 0 if not found
    }
    Database db = await database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Todo>> searchTodos(String query) async {
    if (kIsWeb) {
      return _webTodos
          .where((todo) =>
              todo.title.contains(query) || todo.content.contains(query))
          .toList();
    }
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) {
      return Todo.fromMap(maps[i]);
    });
  }

  Future<List<Todo>> getTodosSortedByDate() async {
    if (kIsWeb) {
      List<Todo> sortedTodos = List.from(_webTodos);
      sortedTodos.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      return sortedTodos;
    }
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'todos',
      orderBy: 'createdDate DESC',
    );
    return List.generate(maps.length, (i) {
      return Todo.fromMap(maps[i]);
    });
  }

  Future<List<Todo>> filterTodos() async {
    if (kIsWeb) {
      DateTime oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      return _webTodos
          .where((todo) => todo.createdDate.isAfter(oneWeekAgo))
          .toList();
    }
    Database db = await database;
    DateTime oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'createdDate >= ?',
      whereArgs: [oneWeekAgo.toIso8601String()],
    );
    return List.generate(maps.length, (i) {
      return Todo.fromMap(maps[i]);
    });
  }
}
