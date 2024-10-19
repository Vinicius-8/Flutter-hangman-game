import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hangman/utilities/user_coins.dart';
import 'package:flutter_hangman/utilities/user_scores.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<Database> openDB() async {  
  final database = openDatabase(
    join(await getDatabasesPath(), 'scores_database.db'),
    onCreate: (db, version) async {
      
      await db.execute(
        "CREATE TABLE scores(id INTEGER PRIMARY KEY AUTOINCREMENT, scoreDate TEXT, userScore INTEGER)",
      );
      
      await db.execute(
        "CREATE TABLE coins(id INTEGER PRIMARY KEY AUTOINCREMENT, coinDate TEXT, userCoins INTEGER)",
      );      
    },
    version: 1,
  );
  return database;
}

Future<void> insertScore(Score score, final database) async {
  final Database db = await database;

  await db.insert(
    'scores',
    score.toMap(),
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
}
Future<void> insertCoins(Score score, final database) async {
  final Database db = await database;

  await db.insert(
    'coins',
    score.toMap(),
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
}

Future<List<Score>> scores(final database) async {
  // Get a reference to the database.
  final Database db = await database;

  // Query the table for all The Dogs.
  final List<Map<String, dynamic>> maps = await db.query('scores');

  // Convert the List<Map<String, dynamic> into a List<Dog>.
  return List.generate(maps.length, (i) {
    return Score(
      id: maps[i]['id'],
      scoreDate: maps[i]['scoreDate'],
      userScore: maps[i]['userScore'],
    );
  });
}

Future<List<Coin>> getCoins(final database) async {
  // Get a reference to the database.
  final Database db = await database;

  // Query the table for all The Dogs.
  final List<Map<String, dynamic>> maps = await db.query('coins');

  // Convert the List<Map<String, dynamic> into a List<Dog>.
  return List.generate(maps.length, (i) {
    return Coin(
      id: maps[i]['id'],
      coinDate: maps[i]['coinDate'],
      userCoins: maps[i]['userCoins'],
    );
  });
}

Future<void> updateScore(Score score, final database) async {
  // Get a reference to the database.
  final db = await database;

  // Update the given Dog.
  await db.update(
    'scores',
    score.toMap(),
    // Ensure that the Dog has a matching id.
    where: "id = ?",
    // Pass the Dog's id as a whereArg to prevent SQL injection.
    whereArgs: [score.id],
  );
}

Future<void> updateCoin(Coin coin, final database) async {
  // Get a reference to the database.
  final db = await database;

  // Update the given Dog.
  await db.update(
    'coins',
    coin.toMap(),
    // Ensure that the Dog has a matching id.
    where: "id = ?",
    // Pass the Dog's id as a whereArg to prevent SQL injection.
    whereArgs: [coin.id],
  );
}

Future<void> deleteScore(int id, final database) async {
  // Get a reference to the database.
  final db = await database;

  // Remove the Dog from the database.
  await db.delete(
    'scores',
    // Use a `where` clause to delete a specific dog.
    where: "id = ?",
    // Pass the Dog's id as a whereArg to prevent SQL injection.
    whereArgs: [id],
  );
}

Future<void> deleteCoin(int id, final database) async {
  // Get a reference to the database.
  final db = await database;

  // Remove the Dog from the database.
  await db.delete(
    'coins',
    // Use a `where` clause to delete a specific dog.
    where: "id = ?",
    // Pass the Dog's id as a whereArg to prevent SQL injection.
    whereArgs: [id],
  );
}

void manipulateDatabase(Score scoreObject, final database) async {
  await insertScore(scoreObject, database);
  List<Score> data = await scores(database);
  debugPrint(data.toString());
}

Future<void> upsertCoins(Coin coins, final database) async {
  final Database db = await database;

  List<Coin> existingCoins = await getCoins(db);
  
  if (existingCoins.isEmpty) {
    // Se não existir, insere um novo registro
    await db.insert(
      'coins',
      coins.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  } else {
    // Se existir, atualiza o registro existente
    final existingId = existingCoins.first.id;
    
    await db.update(
      'coins',
      coins.toMap()..['id'] = existingId,
      where: "id = ?",
      whereArgs: [existingId],
    );
  }
}
