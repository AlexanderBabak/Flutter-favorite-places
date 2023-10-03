import 'dart:io';

import 'package:favorite_places/models/place.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path; // это для пути картинки
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:sqflite/sqflite.dart' as sql; // два импорта
import 'package:sqflite/sqlite_api.dart'; // два импорта

// сделали доступ к базе переиспользуемым за счет функции
Future<Database> _getDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  final db = await sql.openDatabase(
    path.join(dbPath, 'places.db'),
    onCreate: (db, version) {
      return db.execute(
          'CREATE TABLE user_places(id TEXT PRIMARY KEY, title TEXT, image TEXT, lat REAL, lng REAL, address TEXT)');
    },
    version: 1,
  );
  return db;
}

class UserPlacesNotifier extends StateNotifier<List<Place>> {
  UserPlacesNotifier() : super(const []);

// получаем данные из хранилища и записываем в стэйт
  Future<void> loadPlaces() async {
    final db = await _getDatabase();
    final data = await db.query('user_places'); // название базы
    // конвертируем в нужную нам структуру
    final places = data
        .map(
          (row) => Place(
            id: row['id'] as String,
            title: row['title'] as String,
            image: File(row['image'] as String),
            location: PlaceLocation(
              address: row['address'] as String,
              latitude: row['lat'] as double,
              longitude: row['lng'] as double,
            ),
          ),
        )
        .toList();

    state = places;
  }

  Future<void> addPlace(
      String title, File image, PlaceLocation location) async {
    final appDir = await syspaths.getApplicationDocumentsDirectory();
    final filename = path.basename(image.path);
    final copiedImage = await image.copy('${appDir.path}/$filename');

    final newPlase =
        Place(title: title, image: copiedImage, location: location);

    final db = await _getDatabase();

    db.insert('user_places', {
      'id': newPlase.id,
      'title': newPlase.title,
      'image': newPlase.image.path,
      'lat': newPlase.location.latitude,
      'lng': newPlase.location.longitude,
      'address': newPlase.location.address,
    });

    state = [newPlase, ...state];
  }

  void deletePlace(String id) {
    state = state.where((element) => element.id != id).toList();
  }
}

final userPlacesProvider =
    StateNotifierProvider<UserPlacesNotifier, List<Place>>((ref) {
  return UserPlacesNotifier();
});
