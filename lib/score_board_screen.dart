import 'package:flutter/material.dart';

class ScoreBoardScreen extends StatefulWidget {
  const ScoreBoardScreen({super.key});

  @override
  State<ScoreBoardScreen> createState() => _ScoreBoardScreenState();
}

class _ScoreBoardScreenState extends State<ScoreBoardScreen> {
  int teamAScore = 0;
  int teamBScore = 0;

  void _incrementScore(bool isTeamA) {
    setState(() {
      if (isTeamA) {
        teamAScore++;
      } else {
        teamBScore++;
      }
    });
  }

  void _decrementScore(bool isTeamA) {
    setState(() {
      if (isTeamA && teamAScore > 0) {
        teamAScore--;
      } else if (!isTeamA && teamBScore > 0) {
        teamBScore--;
      }
    });
  }

  void _resetScores() {
    setState(() {
      teamAScore = 0;
      teamBScore = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 4),
                ),
                child: const Text(
                  'TỶ SỐ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 12),

              // Score Display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Team A
                    _buildTeamSection(
                      teamName: 'ĐỘI A',
                      score: teamAScore,
                      color: Colors.yellow,
                      isTeamA: true,
                    ),

                    const SizedBox(height: 12),

                    // VS Divider
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Team B
                    _buildTeamSection(
                      teamName: 'ĐỘI B',
                      score: teamBScore,
                      color: Colors.cyan,
                      isTeamA: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Reset Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildBrutalButton(
                  label: 'RESET',
                  color: Colors.red,
                  onPressed: _resetScores,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSection({
    required String teamName,
    required int score,
    required Color color,
    required bool isTeamA,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Team Name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 4),
              ),
            ),
            child: Text(
              teamName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Score Display
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              score.toString(),
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 1,
              ),
            ),
          ),

          // Control Buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _buildBrutalButton(
                    label: '-',
                    color: Colors.white,
                    onPressed: () => _decrementScore(isTeamA),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBrutalButton(
                    label: '+',
                    color: Colors.white,
                    onPressed: () => _incrementScore(isTeamA),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrutalButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
