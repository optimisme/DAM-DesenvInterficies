import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'animals_model.dart';

class AppData extends ChangeNotifier {
  Database? _db;
  List<AnimalsModel> _animals = [];
  AnimalsModel? _selectedAnimal;

  List<AnimalsModel> get animals => _animals;
  AnimalsModel? get selectedAnimal => _selectedAnimal;

  Future<void> initializeDatabase() async {
    try {
      String databasePath = await getDatabasesPath();
      String path = join(databasePath, 'animals.db');

      _db = await openDatabase(
        path,
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE animals(especie TEXT PRIMARY KEY, longevitat INTEGER, numeropotes INTEGER)',
          );
        },
        version: 1,
      );
      await refreshData();
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing database: $e");
      }
    }
  }

  Future<void> refreshData() async {
    if (_db != null) {
      final List<Map<String, dynamic>> maps =
          await _db!.rawQuery('SELECT * FROM animals');
      _animals = List.generate(maps.length, (i) {
        return AnimalsModel.fromMap(maps[i]);
      });
    } else {
      _animals = [];
    }
    notifyListeners();
  }

  Future<void> addAnimal(AnimalsModel animal) async {
    if (_db != null) {
      await _db!.rawInsert(
        'INSERT INTO animals (especie, longevitat, numeropotes) VALUES (?, ?, ?)',
        [animal.especie, animal.longevitat, animal.numeropotes],
      );
      _animals.add(animal);
      notifyListeners();
    }
  }

  void selectAnimal(AnimalsModel? animal) {
    _selectedAnimal = animal;
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    if (_selectedAnimal != null && _db != null) {
      await _db!.rawDelete(
        'DELETE FROM animals WHERE especie = ?',
        [_selectedAnimal!.especie],
      );
      _animals.remove(_selectedAnimal);
      _selectedAnimal = null;
      notifyListeners();
    }
  }

  Future<void> closeDatabase() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
