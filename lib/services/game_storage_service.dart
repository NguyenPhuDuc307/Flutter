import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_mode.dart';

class GameStorageService {
  static const String _keyCurrentGame = 'current_game';

  // Lưu game hiện tại
  static Future<void> saveGame({
    required GameMode mode,
    required int raceToScore,
    required int handicap,
    required int numberOfPlayers,
    required List<String> playerNames,
    required List<int> playerScores,
    required List<List<int>> playerLostBalls,
    required List<List<int>> playerWonBalls,
    required List<Map<String, dynamic>> gameHistory,
    int? lastHighBallWinner,
    int? lastHighBallVictim,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final gameData = {
      'mode': mode.toString(),
      'raceToScore': raceToScore,
      'handicap': handicap,
      'numberOfPlayers': numberOfPlayers,
      'playerNames': playerNames,
      'playerScores': playerScores,
      'playerLostBalls': playerLostBalls,
      'playerWonBalls': playerWonBalls,
      'gameHistory': gameHistory,
      'lastHighBallWinner': lastHighBallWinner,
      'lastHighBallVictim': lastHighBallVictim,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_keyCurrentGame, jsonEncode(gameData));
  }

  // Load game đã lưu
  static Future<Map<String, dynamic>?> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final gameDataString = prefs.getString(_keyCurrentGame);

    if (gameDataString == null) return null;

    try {
      final gameData = jsonDecode(gameDataString) as Map<String, dynamic>;

      // Parse GameMode từ string
      final modeString = gameData['mode'] as String;
      GameMode? mode;
      for (var m in GameMode.values) {
        if (m.toString() == modeString) {
          mode = m;
          break;
        }
      }

      if (mode == null) return null;

      return {
        'mode': mode,
        'raceToScore': gameData['raceToScore'] as int,
        'handicap': gameData['handicap'] as int,
        'numberOfPlayers': gameData['numberOfPlayers'] as int,
        'playerNames': List<String>.from(gameData['playerNames']),
        'playerScores': List<int>.from(gameData['playerScores']),
        'playerLostBalls': (gameData['playerLostBalls'] as List)
            .map((e) => List<int>.from(e))
            .toList(),
        'playerWonBalls': (gameData['playerWonBalls'] as List)
            .map((e) => List<int>.from(e))
            .toList(),
        'gameHistory': List<Map<String, dynamic>>.from(
            (gameData['gameHistory'] as List)
                .map((e) => Map<String, dynamic>.from(e))),
        'lastHighBallWinner': gameData['lastHighBallWinner'] as int?,
        'lastHighBallVictim': gameData['lastHighBallVictim'] as int?,
        'timestamp': gameData['timestamp'] as String,
      };
    } catch (e) {
      print('Error loading game: $e');
      return null;
    }
  }

  // Xóa game đã lưu
  static Future<void> clearGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentGame);
  }

  // Kiểm tra có game đã lưu không
  static Future<bool> hasGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyCurrentGame);
  }
}
