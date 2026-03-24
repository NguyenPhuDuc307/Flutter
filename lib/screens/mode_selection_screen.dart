import 'package:flutter/material.dart';
import '../models/game_mode.dart';
import 'setup_screen.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

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
              child: Column(
                children: [
                  const Text(
                    '🎱',
                    style: TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  const Text(
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
