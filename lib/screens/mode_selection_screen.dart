import 'package:flutter/material.dart';
import '../models/game_mode.dart';
import '../services/game_storage_service.dart';
import 'setup_screen.dart';
import 'game_screen.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  bool hasSavedGame = false;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();
  }

  Future<void> _checkSavedGame() async {
    final hasGame = await GameStorageService.hasGame();
    setState(() {
      hasSavedGame = hasGame;
    });
  }

  Future<void> _continueGame() async {
    final gameData = await GameStorageService.loadGame();
    if (gameData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          mode: gameData['mode'],
          raceToScore: gameData['raceToScore'],
          handicap: gameData['handicap'],
          numberOfPlayers: gameData['numberOfPlayers'],
          playerNames: gameData['playerNames'],
          savedScores: gameData['playerScores'],
          savedLostBalls: gameData['playerLostBalls'],
          savedWonBalls: gameData['playerWonBalls'],
          savedGameHistory: gameData['gameHistory'],
          savedLastHighBallWinner: gameData['lastHighBallWinner'],
          savedLastHighBallVictim: gameData['lastHighBallVictim'],
        ),
      ),
    ).then((_) => _checkSavedGame());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Logo/Title Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.yellow,
                border: Border.all(color: Colors.white, width: 6),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(8, 8),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Text(
                    '🎱',
                    style: TextStyle(fontSize: 48),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'BIDA SCORE',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: Colors.black,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Mode Selection Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Text(
                  'CHỌN LUẬT CHƠI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (hasSavedGame)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: _continueGame,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      border: Border.all(color: Colors.white, width: 5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.white,
                          offset: Offset(6, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow,
                          color: Colors.black,
                          size: 28,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'TIẾP TỤC',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (hasSavedGame) const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ListView(
                  children: [
                    _buildModeButton(
                      context,
                      mode: GameMode.solo,
                      color: Colors.yellow,
                    ),
                    const SizedBox(height: 16),
                    _buildModeButton(
                      context,
                      mode: GameMode.den9Bi59,
                      color: Colors.cyan,
                    ),
                    const SizedBox(height: 16),
                    _buildModeButton(
                      context,
                      mode: GameMode.den9Bi369,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    _buildModeButton(
                      context,
                      mode: GameMode.den10Bi4710,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required GameMode mode,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetupScreen(mode: mode),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.white, width: 5),
          boxShadow: const [
            BoxShadow(
              color: Colors.white,
              offset: Offset(6, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                mode.displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward,
              color: Colors.black,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
